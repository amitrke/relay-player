import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:relay_player/data/local/app_settings_store.dart';
import 'package:relay_player/data/trackers/anime_match.dart';
import 'package:relay_player/data/trackers/mal.dart';
import 'package:relay_player/data/trackers/simkl.dart';
import 'package:relay_player/data/trackers/tracker.dart';
import 'package:relay_player/data/trackers/tracker_store.dart';
import 'package:relay_player/data/trackers/trakt.dart';
import 'package:relay_player/domain/models/media_server.dart';
import 'package:relay_player/features/settings/settings_controller.dart';
import 'package:relay_player/features/trackers/trackers_controller.dart';

/// Watch trackers (architecture.md §19), against fakes. Whether the real
/// services accept these requests, with this app's registered credentials,
/// is a manual check (MANUAL_TESTING.md).
final _at = DateTime.utc(2026, 10, 16, 20);

WatchedItem _episode({bool anime = false, ExternalIds? showIds, int season = 1}) =>
    WatchedItem(
      isEpisode: true,
      title: 'Pilot',
      showTitle: 'The Show',
      showYear: 2010,
      showIds: showIds ?? const ExternalIds(tvdb: '81189'),
      season: season,
      episode: 3,
      watchedAt: _at,
      isAnime: anime,
    );

void main() {
  group('what is sent', () {
    test('an episode takes its show\'s ids, year and genres', () {
      const ep = MediaItem(
        id: 'e1',
        type: MediaItemType.episode,
        title: 'Pilot',
        index: 3,
        parentIndex: 1,
        showTitle: 'The Show',
      );
      const show = MediaItem(
        id: 's1',
        type: MediaItemType.show,
        title: 'The Show',
        year: 2010,
        genres: ['Animation', 'Anime'],
        ids: ExternalIds(tvdb: '81189'),
      );
      final w = WatchedItem.from(ep, show: show, at: _at)!;
      expect(w.isEpisode, isTrue);
      expect(w.showIds.tvdb, '81189');
      expect(w.showYear, 2010);
      expect(w.season, 1);
      expect(w.episode, 3);
      expect(w.isAnime, isTrue);
      expect(
        WatchedItem.from(
          const MediaItem(id: 's', type: MediaItemType.show, title: 'x'),
        ),
        isNull,
        reason: 'a whole show is not a watch',
      );
    });

    test('Trakt: a film by its ids, an episode by its show and number', () {
      final film = TraktTracker.historyBody(
        WatchedItem(
          isEpisode: false,
          title: 'The Film',
          year: 1994,
          ids: const ExternalIds(imdb: 'tt0111161', tmdb: '278'),
          watchedAt: _at,
        ),
      )!;
      final m = (film['movies']! as List).single as Map;
      expect(m['ids'], {'imdb': 'tt0111161', 'tmdb': 278});
      expect(m['watched_at'], '2026-10-16T20:00:00.000Z');

      final ep = TraktTracker.historyBody(_episode())!;
      final show = (ep['shows']! as List).single as Map;
      expect(show['ids'], {'tvdb': 81189});
      final season = (show['seasons'] as List).single as Map;
      expect(season['number'], 1);
      expect(((season['episodes'] as List).single as Map)['number'], 3);

      expect(
        TraktTracker.historyBody(
          WatchedItem(isEpisode: false, title: 'x', watchedAt: _at),
        ),
        isNull,
        reason: 'nothing to match a film by',
      );
    });

    test('Simkl: the same shape, ids as strings', () {
      final ep = SimklTracker.historyBody(_episode())!;
      final show = (ep['shows']! as List).single as Map;
      expect(show['ids'], {'tvdb': '81189'});
      expect(
        SimklTracker.historyBody(_episode(showIds: ExternalIds.none)),
        isNull,
      );
    });
  });

  group('anime', () {
    test('only anime, by the show\'s name, with the season after the first',
        () {
      expect(animeTarget(_episode()), isNull);
      expect(animeTarget(_episode(anime: true))?.query, 'The Show');
      expect(animeTarget(_episode(anime: true))?.progress, 3);
      expect(
        animeTarget(_episode(anime: true, season: 2))?.query,
        'The Show Season 2',
      );
    });

    test('an exact title wins over the service\'s first result', () {
      final hit = bestAnimeMatch<String>(
        'Show: The Movie',
        ['Show 2', 'show the movie'],
        (s) => [s],
      );
      expect(hit, 'show the movie');
      expect(bestAnimeMatch<String>('x', ['a', 'b'], (s) => [s]), 'a');
    });

    test('MAL: the code from a pasted address, refused for another sign-in',
        () {
      expect(
        MalTracker.codeFrom(
          'http://localhost:41235/mal?code=abcdefghijklmnopqrstuvwxyz&state=s1',
          's1',
        ),
        'abcdefghijklmnopqrstuvwxyz',
      );
      expect(
        MalTracker.codeFrom(
          'http://localhost:41235/mal?code=abcdefghijklmnopqrstuvwxyz&state=other',
          's1',
        ),
        isNull,
      );
      expect(MalTracker.codeFrom('short', 's1'), isNull);
    });
  });

  group('Trakt against a fake', () {
    late HttpServer server;
    var tokenStatus = 400;
    var historyStatus = 201;
    final requests = <String, Object?>{};

    setUp(() async {
      tokenStatus = 400;
      historyStatus = 201;
      requests.clear();
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((req) async {
        final body = await utf8.decoder.bind(req).join();
        requests[req.uri.path] = body.isEmpty ? null : jsonDecode(body);
        requests['${req.uri.path} key'] = req.headers.value('trakt-api-key');
        final (status, Object? reply) = switch (req.uri.path) {
          '/oauth/device/code' => (
            200,
            {
              'device_code': 'dev',
              'user_code': 'ABCD1234',
              'verification_url': 'https://trakt.tv/activate',
              'expires_in': 600,
              'interval': 5,
            },
          ),
          '/oauth/device/token' when tokenStatus == 200 => (
            200,
            {
              'access_token': 'acc',
              'refresh_token': 'ref',
              'expires_in': 86400,
              'created_at': 1760000000,
            },
          ),
          '/oauth/device/token' => (tokenStatus, null),
          '/users/settings' => (
            200,
            {
              'user': {'username': 'me'},
            },
          ),
          '/sync/history' => (
            historyStatus,
            {
              'added': {'movies': 1, 'episodes': 0},
            },
          ),
          _ => (404, null),
        };
        req.response.statusCode = status;
        req.response.headers.contentType = ContentType.json;
        if (reply != null) req.response.write(jsonEncode(reply));
        await req.response.close();
      });
    });
    tearDown(() => server.close(force: true));

    TraktTracker trakt() => TraktTracker(
      clientId: 'cid',
      clientSecret: 'sec',
      apiBase: 'http://127.0.0.1:${server.port}',
    );

    test('a device code, pending until approved, then a token and a name',
        () async {
      final t = trakt();
      final start = await t.startSignIn() as DeviceCodeSignIn;
      expect(start.userCode, 'ABCD1234');
      await expectLater(t.finishSignIn(start), throwsA(isA<SignInPending>()));
      tokenStatus = 200;
      final token = await t.finishSignIn(start);
      expect(token.access, 'acc');
      expect(token.userName, 'me');
      expect(requests['/oauth/device/token'], {
        'code': 'dev',
        'client_id': 'cid',
        'client_secret': 'sec',
      });
    });

    test('a refused code says so', () async {
      final t = trakt();
      final start = await t.startSignIn();
      tokenStatus = 418;
      await expectLater(t.finishSignIn(start), throwsA(isA<SignInFailed>()));
    });

    test('a watch goes to /sync/history with the app key', () async {
      final ok = await trakt().markWatched(
        WatchedItem(
          isEpisode: false,
          title: 'The Film',
          ids: const ExternalIds(imdb: 'tt0111161'),
          watchedAt: _at,
        ),
        const TrackerToken(access: 'acc'),
      );
      expect(ok, isTrue);
      expect(requests['/sync/history key'], 'cid');
      historyStatus = 401;
      await expectLater(
        trakt().markWatched(
          WatchedItem(
            isEpisode: false,
            title: 'x',
            ids: const ExternalIds(imdb: 'tt1'),
            watchedAt: _at,
          ),
          const TrackerToken(access: 'acc'),
        ),
        throwsA(isA<TrackerSignedOut>()),
      );
    });
  });

  group('the queue', () {
    late Directory dir;
    late AppSettingsStore store;
    var boxes = 0;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('trackers');
      Hive.init(dir.path);
      store = AppSettingsStore.withBox(
        await Hive.openBox<dynamic>('t${boxes++}'),
      );
      addTearDown(() async {
        await Hive.close();
        await dir.delete(recursive: true);
      });
    });

    ({ProviderContainer c, Map<TrackerKind, _FakeTracker> trackers}) setUpContainer({
      Map<TrackerKind, TrackerToken> tokens = const {},
      WatchedItem? Function(String id)? resolve,
    }) {
      final trackers = {
        for (final k in TrackerKind.values) k: _FakeTracker(k),
      };
      final c = ProviderContainer(
        overrides: [
          appSettingsStoreProvider.overrideWithValue(store),
          trackerTokenStoreProvider.overrideWithValue(_MemoryTokens(tokens)),
          trackerFactoryProvider.overrideWithValue((k) => trackers[k]),
          watchResolverProvider.overrideWithValue(
            (serverId, itemId, at) async =>
                resolve == null ? _episode() : resolve(itemId),
          ),
        ],
      );
      addTearDown(c.dispose);
      c.listen(trackersProvider, (_, _) {});
      return (c: c, trackers: trackers);
    }

    Future<void> settle(ProviderContainer c) async {
      for (var i = 0; i < 20; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
    }

    test('a finished watch reaches every signed-in tracker, once', () async {
      final (:c, :trackers) = setUpContainer(tokens: {
        TrackerKind.trakt: const TrackerToken(access: 'a'),
        TrackerKind.simkl: const TrackerToken(access: 'b'),
      });
      await settle(c);
      final ctl = c.read(trackersProvider.notifier);
      await ctl.finished('srv', 'e1');
      await ctl.finished('srv', 'e1');
      await settle(c);
      expect(trackers[TrackerKind.trakt]!.sent, ['Pilot']);
      expect(trackers[TrackerKind.simkl]!.sent, ['Pilot']);
      expect(c.read(trackersProvider).pending, 0);
    });

    test('anime-only trackers are skipped for anything else', () async {
      final (:c, :trackers) = setUpContainer(tokens: {
        TrackerKind.anilist: const TrackerToken(access: 'a'),
      });
      await settle(c);
      await c.read(trackersProvider.notifier).finished('srv', 'e1');
      await settle(c);
      expect(trackers[TrackerKind.anilist]!.sent, isEmpty);
      expect(c.read(trackersProvider).pending, 0);
    });

    test('a tracker that is down keeps the watch for later', () async {
      final (:c, :trackers) = setUpContainer(tokens: {
        TrackerKind.trakt: const TrackerToken(access: 'a'),
      });
      await settle(c);
      trackers[TrackerKind.trakt]!.down = true;
      await c.read(trackersProvider.notifier).finished('srv', 'e1');
      await settle(c);
      expect(c.read(trackersProvider).pending, 1);
      expect(TrackerQueueStore(store).load().single.attempts, 1);

      trackers[TrackerKind.trakt]!.down = false;
      await c.read(trackersProvider.notifier).flush();
      expect(trackers[TrackerKind.trakt]!.sent, ['Pilot']);
      expect(c.read(trackersProvider).pending, 0);
    });

    test('a lapsed sign-in is refreshed once, then signed out here', () async {
      final (:c, :trackers) = setUpContainer(tokens: {
        TrackerKind.trakt: const TrackerToken(access: 'old', refresh: 'r'),
      });
      await settle(c);
      trackers[TrackerKind.trakt]!.acceptOnly = 'new';
      await c.read(trackersProvider.notifier).finished('srv', 'e1');
      await settle(c);
      expect(trackers[TrackerKind.trakt]!.sent, ['Pilot']);
      expect(c.read(trackersProvider).tokens[TrackerKind.trakt]?.access, 'new');

      trackers[TrackerKind.trakt]!
        ..acceptOnly = 'never'
        ..canRefresh = false;
      await c.read(trackersProvider.notifier).finished('srv', 'e2');
      await settle(c);
      expect(c.read(trackersProvider).signedIn(TrackerKind.trakt), isFalse);
      expect(c.read(trackersProvider).pending, 1,
          reason: 'kept for when the person signs back in');
    });

    test('nothing is queued with no tracker signed in', () async {
      final (:c, trackers: _) = setUpContainer();
      await settle(c);
      await c.read(trackersProvider.notifier).finished('srv', 'e1');
      expect(c.read(trackersProvider).pending, 0);
    });
  });

  test('a build without credentials offers no tracker', () {
    const none = TrackerCredentials(
      traktId: '',
      traktSecret: '',
      simklId: '',
      anilistId: '',
      malId: '',
    );
    expect([for (final k in TrackerKind.values) none.has(k)], everyElement(isFalse));
    const traktIdOnly = TrackerCredentials(
      traktId: 'x',
      traktSecret: '',
      simklId: '',
      anilistId: '',
      malId: '',
    );
    expect(traktIdOnly.has(TrackerKind.trakt), isFalse,
        reason: 'Trakt needs the secret too');
  });
}

class _MemoryTokens extends TrackerTokenStore {
  _MemoryTokens(Map<TrackerKind, TrackerToken> initial)
    : _tokens = {...initial};
  Map<TrackerKind, TrackerToken> _tokens;

  @override
  Future<Map<TrackerKind, TrackerToken>> load() async => {..._tokens};

  @override
  Future<void> save(Map<TrackerKind, TrackerToken> tokens) async =>
      _tokens = {...tokens};
}

class _FakeTracker implements Tracker {
  _FakeTracker(this.kind);

  @override
  final TrackerKind kind;
  final sent = <String>[];
  var down = false;
  String? acceptOnly;
  var canRefresh = true;

  @override
  Future<SignInStart> startSignIn() async => throw UnimplementedError();

  @override
  Future<TrackerToken> finishSignIn(SignInStart s, {String? pasted}) async =>
      throw UnimplementedError();

  @override
  Future<TrackerToken> refresh(TrackerToken token) async {
    if (!canRefresh) throw const TrackerSignedOut();
    return const TrackerToken(access: 'new', refresh: 'r2');
  }

  @override
  Future<bool> markWatched(WatchedItem item, TrackerToken token) async {
    if (down) throw const TrackerUnavailable('down');
    if (acceptOnly != null && token.access != acceptOnly) {
      throw const TrackerSignedOut();
    }
    sent.add(item.title);
    return true;
  }
}
