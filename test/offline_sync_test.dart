import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:relay_player/data/downloads/download_record.dart';
import 'package:relay_player/data/downloads/episode_rules.dart';
import 'package:relay_player/data/downloads/offline_watch_queue.dart';
import 'package:relay_player/data/local/app_settings_store.dart';
import 'package:relay_player/features/downloads/downloads_controller.dart';
import 'package:relay_player/features/downloads/offline_sync.dart';
import 'package:relay_player/features/settings/settings_controller.dart';

/// Offline watch replay (architecture.md §18.6) and episode rules (§18.7).
/// Against a fake server: whether a real Plex counts a late `stopped` report
/// and a late scrobble the way these assume is a check on real hardware
/// (MANUAL_TESTING.md).
class _Server implements SyncServer {
  final calls = <String>[];
  final lastViewed = <String, DateTime?>{};
  final missing = <String>{};
  var episodes = <RuleEpisode>[];
  var failing = false;

  @override
  Future<({bool exists, DateTime? lastViewedAt})> viewState(
    String ratingKey,
  ) async {
    if (failing) throw const SocketException('unreachable');
    return (exists: !missing.contains(ratingKey), lastViewedAt: lastViewed[ratingKey]);
  }

  @override
  Future<void> markWatched(String ratingKey) async =>
      calls.add('watched $ratingKey');

  @override
  Future<void> reportStopped(
    String ratingKey, {
    required Duration position,
    required Duration duration,
  }) async => calls.add('stopped $ratingKey at ${position.inMinutes}m');

  @override
  Future<List<RuleEpisode>> episodesOf(String showRatingKey) async => episodes;
}

/// Records what a rule asks of downloads, without fetching anything.
class _Downloads extends DownloadsController {
  _Downloads(this.records);
  final List<DownloadRecord> records;
  final calls = <String>[];

  @override
  List<DownloadRecord> build() => records;

  @override
  Future<void> enqueue({
    required String serverId,
    required String ratingKey,
    required String title,
    bool isEpisode = false,
    String? rule,
  }) async => calls.add('get $ratingKey rule=$rule');

  @override
  Future<void> remove(String serverId, String ratingKey) async =>
      calls.add('remove $ratingKey');
}

RuleEpisode _ep(int season, int index, {bool watched = false}) => RuleEpisode(
  ratingKey: 's${season}e$index',
  title: 'Episode $index',
  season: season,
  index: index,
  watched: watched,
);

DownloadRecord _dl(
  String key, {
  DownloadState state = DownloadState.complete,
  String? rule,
}) => DownloadRecord(
  serverId: 'srv',
  ratingKey: key,
  title: key,
  addedAt: DateTime.utc(2026, 10, 15),
  state: state,
  rule: rule,
);

const _rule = EpisodeRule(
  serverId: 'srv',
  showRatingKey: 'show',
  showTitle: 'Show',
  keep: 3,
);

void main() {
  final t0 = DateTime.utc(2026, 10, 15, 12);

  group('what to send', () {
    test('past 90% is a watch, before it is a position', () {
      PendingWatch at(int minutes) => pendingFrom(
        serverId: 'srv',
        ratingKey: '1',
        position: Duration(minutes: minutes),
        duration: const Duration(minutes: 100),
        at: t0,
      );
      expect(at(89).watched, isFalse);
      expect(at(90).watched, isTrue);
      expect(
        pendingFrom(
          serverId: 'srv',
          ratingKey: '1',
          position: Duration.zero,
          duration: Duration.zero,
          at: t0,
        ).watched,
        isFalse,
        reason: 'an unknown length is never "finished"',
      );
    });

    test('newer on the server wins', () {
      final p = PendingWatch(
        serverId: 'srv',
        ratingKey: '1',
        position: const Duration(minutes: 30),
        duration: const Duration(hours: 1),
        at: t0,
      );
      expect(replayActionFor(p, serverLastViewedAt: null),
          ReplayAction.reportPosition);
      expect(
        replayActionFor(p, serverLastViewedAt: t0.subtract(const Duration(days: 1))),
        ReplayAction.reportPosition,
      );
      expect(
        replayActionFor(p, serverLastViewedAt: t0.add(const Duration(minutes: 1))),
        ReplayAction.drop,
      );
    });

    test('the stored form has no token and no URL', () {
      final json = PendingWatch(
        serverId: 'srv',
        ratingKey: '1',
        position: const Duration(minutes: 3),
        duration: const Duration(hours: 1),
        at: t0,
      ).toJson().toString();
      expect(json, isNot(contains('http')));
      expect(json, isNot(contains('Token')));
      final back = PendingWatch.fromJson(PendingWatch(
        serverId: 'srv',
        ratingKey: '1',
        position: const Duration(minutes: 3),
        duration: const Duration(hours: 1),
        at: t0,
        watched: true,
      ).toJson())!;
      expect(back.position, const Duration(minutes: 3));
      expect(back.watched, isTrue);
      expect(back.at, t0);
    });
  });

  group('planning a rule', () {
    test('the next N unwatched, in order, with specials left out', () {
      final plan = planTopUp(_rule, [
        _ep(2, 1),
        _ep(0, 1),
        _ep(1, 2, watched: true),
        _ep(1, 3),
        _ep(1, 1, watched: true),
        _ep(2, 2),
        _ep(2, 3),
      ], const []);
      expect(plan.download.map((e) => e.ratingKey), ['s1e3', 's2e1', 's2e2']);
      expect(plan.remove, isEmpty);
    });

    test('an episode already on the device counts, a failed one is retried',
        () {
      final plan = planTopUp(_rule, [_ep(1, 1), _ep(1, 2), _ep(1, 3)], [
        _dl('s1e1'), // downloaded by hand
        _dl('s1e2', state: DownloadState.failed, rule: 'show'),
      ]);
      expect(plan.download.map((e) => e.ratingKey), ['s1e2', 's1e3']);
    });

    test("only the rule's own finished, watched downloads are removed", () {
      final plan = planTopUp(_rule, [
        _ep(1, 1, watched: true),
        _ep(1, 2, watched: true),
        _ep(1, 3, watched: true),
        _ep(1, 4),
      ], [
        _dl('s1e1', rule: 'show'),
        _dl('s1e2'), // by hand: theirs
        _dl('s1e3', rule: 'show', state: DownloadState.downloading),
        _dl('s1e4', rule: 'show'),
        _dl('other', rule: 'another show'),
      ]);
      expect(plan.remove, ['s1e1']);
      expect(plan.download, isEmpty, reason: 's1e4 is already there');
    });

    test('a rule with a size it does not offer is not loaded', () {
      expect(
        EpisodeRule.fromJson({
          'serverId': 'srv',
          'show': 'x',
          'title': 'X',
          'keep': 500,
        }),
        isNull,
      );
    });
  });

  group('with a container', () {
    late Directory dir;
    late AppSettingsStore store;
    late _Server server;
    var connected = true;
    var boxes = 0;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('offline_sync');
      Hive.init(dir.path);
      store = AppSettingsStore.withBox(
        await Hive.openBox<dynamic>('o${boxes++}'),
      );
      server = _Server();
      connected = true;
      addTearDown(() async {
        await Hive.close();
        await dir.delete(recursive: true);
      });
    });

    ProviderContainer container({List<DownloadRecord> downloads = const []}) {
      final c = ProviderContainer(
        overrides: [
          appSettingsStoreProvider.overrideWithValue(store),
          syncServerLookupProvider.overrideWithValue(
            (id) => connected && id == 'srv' ? server : null,
          ),
          downloadsProvider.overrideWith(() => _Downloads(downloads)),
        ],
      );
      addTearDown(c.dispose);
      return c;
    }

    PendingWatch pending(String key, {int minutes = 10, bool watched = false}) =>
        PendingWatch(
          serverId: 'srv',
          ratingKey: key,
          position: Duration(minutes: minutes),
          duration: const Duration(hours: 1),
          at: t0,
          watched: watched,
        );

    test('one entry per title, and a finish is not undone by a later report',
        () async {
      final c = container();
      final q = c.read(offlineWatchProvider.notifier);
      await q.add(pending('1', minutes: 5));
      await q.add(pending('1', minutes: 20));
      expect(c.read(offlineWatchProvider).single.position.inMinutes, 20);

      await q.add(pending('1', minutes: 58, watched: true));
      await q.add(pending('1', minutes: 59));
      expect(c.read(offlineWatchProvider).single.watched, isTrue);
    });

    test('survives a restart', () async {
      await container().read(offlineWatchProvider.notifier).add(pending('1'));
      expect(container().read(offlineWatchProvider), hasLength(1));
    });

    test('flush sends watches and positions, and drops what is stale',
        () async {
      final c = container();
      final q = c.read(offlineWatchProvider.notifier);
      await q.add(pending('watched', watched: true));
      await q.add(pending('partway', minutes: 25));
      await q.add(pending('stale'));
      await q.add(pending('gone'));
      server.lastViewed['stale'] = t0.add(const Duration(hours: 1));
      server.missing.add('gone');

      expect(await q.flush(), 2);
      expect(server.calls, ['watched watched', 'stopped partway at 25m']);
      expect(c.read(offlineWatchProvider), isEmpty);
      expect(store.getString('downloads.pendingWatch'), '[]');
    });

    test('nothing is lost while the server cannot be reached', () async {
      final c = container();
      final q = c.read(offlineWatchProvider.notifier);
      await q.add(pending('1'));

      connected = false;
      expect(await q.flush(), 0);
      connected = true;
      server.failing = true;
      expect(await q.flush(), 0);
      expect(c.read(offlineWatchProvider), hasLength(1));

      server.failing = false;
      expect(await q.flush(), 1);
      expect(c.read(offlineWatchProvider), isEmpty);
    });

    test('a rule counts watched-but-unsent episodes as watched', () async {
      server.episodes = [_ep(1, 1), _ep(1, 2), _ep(1, 3), _ep(1, 4)];
      final c = container(downloads: [_dl('s1e1', rule: 'show')]);
      // Finished on the plane; Plex does not know yet.
      await c
          .read(offlineWatchProvider.notifier)
          .add(pending('s1e1', watched: true));

      await c.read(episodeRulesProvider.notifier).set(_rule);
      final downloads = c.read(downloadsProvider.notifier) as _Downloads;
      expect(downloads.calls, [
        'remove s1e1',
        'get s1e2 rule=show',
        'get s1e3 rule=show',
        'get s1e4 rule=show',
      ]);
      expect(EpisodeRuleStore(store).load().single.keep, 3);
    });

    test('a rule does nothing without its server', () async {
      server.episodes = [_ep(1, 1)];
      connected = false;
      final c = container();
      await c.read(episodeRulesProvider.notifier).set(_rule);
      final downloads = c.read(downloadsProvider.notifier) as _Downloads;
      expect(downloads.calls, isEmpty);
    });
  });
}
