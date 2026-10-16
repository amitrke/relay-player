import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/downloads/episode_rules.dart';
import '../../data/downloads/offline_watch_queue.dart';
import '../../domain/models/media_server.dart';
import '../settings/settings_controller.dart';
import 'downloads_controller.dart';
import '../accounts/media_servers.dart';

/// The four things offline sync asks of a server. Narrower than
/// [PlexService] so the queue and the rules can be tested against a fake.
abstract class SyncServer {
  /// Whether the title still exists, and when the server last saw it viewed.
  Future<({bool exists, DateTime? lastViewedAt})> viewState(String ratingKey);
  Future<void> markWatched(String ratingKey);
  Future<void> reportStopped(
    String ratingKey, {
    required Duration position,
    required Duration duration,
  });
  Future<List<RuleEpisode>> episodesOf(String showRatingKey);
}

class MediaSyncServer implements SyncServer {
  MediaSyncServer(this._plex);

  final MediaServer _plex;

  @override
  Future<({bool exists, DateTime? lastViewedAt})> viewState(
    String ratingKey,
  ) async {
    final item = await _plex.item(ratingKey);
    return (exists: item != null, lastViewedAt: item?.lastViewedAt);
  }

  @override
  Future<void> markWatched(String ratingKey) =>
      _plex.setWatched(ratingKey, watched: true);

  @override
  Future<void> reportStopped(
    String ratingKey, {
    required Duration position,
    required Duration duration,
  }) => _plex.reportProgress(
    id: ratingKey,
    state: 'stopped',
    position: position,
    duration: duration,
  );

  @override
  Future<List<RuleEpisode>> episodesOf(String showRatingKey) async => [
    for (final m in await _plex.episodesOf(showRatingKey))
      if (m.type == MediaItemType.episode)
        RuleEpisode(
          ratingKey: m.id,
          title: m.title,
          season: m.parentIndex ?? 1,
          index: m.index ?? 0,
          watched: (m.viewCount ?? 0) > 0,
        ),
  ];
}

/// Finds the server for an id, or null when it is not connected.
typedef SyncServerLookup = SyncServer? Function(String serverId);

final syncServerLookupProvider = Provider<SyncServerLookup>((ref) {
  return (serverId) {
    final service = ref
        .read(connectedServersProvider)
        .where((s) => s.id == serverId)
        .firstOrNull
        ?.service;
    return service == null ? null : MediaSyncServer(service);
  };
});

final offlineWatchStoreProvider = Provider<OfflineWatchStore>(
  (ref) => OfflineWatchStore(ref.watch(appSettingsStoreProvider)),
);

/// Watches of saved copies that Plex has not heard about yet (§18.6).
final offlineWatchProvider =
    NotifierProvider<OfflineWatchQueue, List<PendingWatch>>(
      OfflineWatchQueue.new,
    );

class OfflineWatchQueue extends Notifier<List<PendingWatch>> {
  OfflineWatchStore get _store => ref.read(offlineWatchStoreProvider);
  bool _flushing = false;

  @override
  List<PendingWatch> build() => _store.load();

  /// Keeps [entry] in place of anything queued for the same title. A
  /// watched mark is not downgraded by a later position report for the same
  /// title, so a credits-roll report after "finished" cannot undo it.
  Future<void> add(PendingWatch entry) async {
    final previous = state.where((p) => p.key == entry.key).firstOrNull;
    final kept = previous != null && previous.watched && !entry.watched
        ? PendingWatch(
            serverId: entry.serverId,
            ratingKey: entry.ratingKey,
            position: entry.position,
            duration: entry.duration,
            at: entry.at,
            watched: true,
          )
        : entry;
    state = [
      for (final p in state)
        if (p.key != entry.key) p,
      kept,
    ];
    await _store.save(state);
  }

  /// Forgets anything queued for this title, once Plex has been told directly.
  Future<void> discard(String serverId, String ratingKey) async {
    final key = 'plex:$serverId:$ratingKey';
    if (!state.any((p) => p.key == key)) return;
    state = [
      for (final p in state)
        if (p.key != key) p,
    ];
    await _store.save(state);
  }

  /// Delivers what it can. Entries for a server that is not connected, or
  /// that fail to send, stay for next time; entries the server has newer
  /// information about are dropped (see [replayActionFor]).
  ///
  /// Returns how many reached the server, for the caller's logs.
  Future<int> flush() async {
    if (_flushing || state.isEmpty) return 0;
    _flushing = true;
    var sent = 0;
    try {
      final lookup = ref.read(syncServerLookupProvider);
      for (final pending in [...state]) {
        final server = lookup(pending.serverId);
        if (server == null) continue;
        try {
          final view = await server
              .viewState(pending.ratingKey)
              .timeout(const Duration(seconds: 10));
          // A title gone from the server is dropped: there is nobody left to
          // tell.
          final action = view.exists
              ? replayActionFor(pending, serverLastViewedAt: view.lastViewedAt)
              : ReplayAction.drop;
          switch (action) {
            case ReplayAction.markWatched:
              await server.markWatched(pending.ratingKey);
              sent++;
            case ReplayAction.reportPosition:
              await server.reportStopped(
                pending.ratingKey,
                position: pending.position,
                duration: pending.duration,
              );
              sent++;
            case ReplayAction.drop:
              break;
          }
          state = [
            for (final p in state)
              if (p.key != pending.key) p,
          ];
          await _store.save(state);
        } catch (e) {
          // Unreachable after all, or refused. Kept, and tried on the next
          // connect.
          debugPrint('OfflineWatchQueue: kept ${pending.key}: $e');
        }
      }
    } finally {
      _flushing = false;
    }
    return sent;
  }
}

final episodeRuleStoreProvider = Provider<EpisodeRuleStore>(
  (ref) => EpisodeRuleStore(ref.watch(appSettingsStoreProvider)),
);

/// "Keep the next N episodes" rules (§18.7).
final episodeRulesProvider =
    NotifierProvider<EpisodeRules, List<EpisodeRule>>(EpisodeRules.new);

class EpisodeRules extends Notifier<List<EpisodeRule>> {
  EpisodeRuleStore get _store => ref.read(episodeRuleStoreProvider);
  final _running = <String>{};

  @override
  List<EpisodeRule> build() => _store.load();

  EpisodeRule? find(String serverId, String showRatingKey) {
    final key = 'plex:$serverId:$showRatingKey';
    return state.where((r) => r.key == key).firstOrNull;
  }

  /// Adds or changes a rule and tops it up straight away.
  Future<void> set(EpisodeRule rule) async {
    state = [
      for (final r in state)
        if (r.key != rule.key) r,
      rule,
    ];
    await _store.save(state);
    await topUp(rule);
  }

  /// Removes the rule. Its downloads stay: deleting files the person may be
  /// about to watch, as a side effect of changing a setting, would surprise
  /// them. They delete them from Downloads like any other.
  Future<void> remove(EpisodeRule rule) async {
    state = [
      for (final r in state)
        if (r.key != rule.key) r,
    ];
    await _store.save(state);
  }

  Future<void> topUpAll() async {
    for (final rule in [...state]) {
      await topUp(rule);
    }
  }

  /// Plans against the server's current watched state and acts on it.
  /// Without a connection there is nothing to plan from, and nothing happens.
  Future<void> topUp(EpisodeRule rule) async {
    if (!_running.add(rule.key)) return;
    try {
      final server = ref.read(syncServerLookupProvider)(rule.serverId);
      if (server == null) return;
      final List<RuleEpisode> fromServer;
      try {
        fromServer = await server
            .episodesOf(rule.showRatingKey)
            .timeout(const Duration(seconds: 20));
      } catch (e) {
        debugPrint('EpisodeRules: ${rule.showTitle} not refreshed: $e');
        return;
      }
      // Watched offline but not yet told to Plex still counts as watched
      // here, so a finished episode is not fetched again before the queue
      // has been delivered.
      final pendingWatched = {
        for (final p in ref.read(offlineWatchProvider))
          if (p.watched && p.serverId == rule.serverId) p.ratingKey,
      };
      final episodes = [
        for (final e in fromServer)
          pendingWatched.contains(e.ratingKey)
              ? RuleEpisode(
                  ratingKey: e.ratingKey,
                  title: e.title,
                  season: e.season,
                  index: e.index,
                  watched: true,
                )
              : e,
      ];
      final downloads = ref.read(downloadsProvider.notifier);
      final plan = planTopUp(rule, episodes, ref.read(downloadsProvider));
      for (final key in plan.remove) {
        await downloads.remove(rule.serverId, key);
      }
      for (final e in plan.download) {
        await downloads.enqueue(
          serverId: rule.serverId,
          ratingKey: e.ratingKey,
          title: '${rule.showTitle}: ${e.title}',
          isEpisode: true,
          rule: rule.showRatingKey,
        );
      }
    } finally {
      _running.remove(rule.key);
    }
  }
}

/// Runs the offline work whenever the set of connected servers changes, which
/// is the moment a server may have become reachable again: deliver queued
/// watches first, so rules plan against up-to-date watched state, then top up
/// rules, then fetch any posters that are missing.
///
/// Watched from the app root, like the release-dates job. Foreground only,
/// like downloads themselves (§18.3): it runs at launch once Plex has
/// reconnected, and whenever a server is added.
final offlineSyncJobProvider = Provider<void>((ref) {
  final servers = ref.watch(
    connectedServersProvider.select((s) => [for (final x in s) x.id].join(',')),
  );
  if (servers.isEmpty) return;
  unawaited(() async {
    await ref.read(offlineWatchProvider.notifier).flush();
    await ref.read(episodeRulesProvider.notifier).topUpAll();
    await ref.read(downloadsProvider.notifier).saveMissingArtwork();
  }());
});
