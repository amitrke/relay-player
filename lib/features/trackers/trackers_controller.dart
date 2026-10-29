import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/trackers/anilist.dart';
import '../../data/trackers/mal.dart';
import '../../data/trackers/simkl.dart';
import '../../data/trackers/tracker.dart';
import '../../data/trackers/tracker_store.dart';
import '../../data/trackers/trakt.dart';
import '../../domain/models/media_server.dart';
import '../accounts/media_servers.dart';
import '../settings/settings_controller.dart';

/// The app credentials compiled into this build (§19.2). Overridden in tests.
final trackerCredentialsProvider = Provider<TrackerCredentials>(
  (ref) => const TrackerCredentials(),
);

/// A client for [TrackerKind], or null when this build has no credentials
/// for it (the tracker is then not offered at all).
typedef TrackerFactory = Tracker? Function(TrackerKind kind);

final trackerFactoryProvider = Provider<TrackerFactory>((ref) {
  final c = ref.watch(trackerCredentialsProvider);
  return (kind) {
    if (!c.has(kind)) return null;
    return switch (kind) {
      TrackerKind.trakt => TraktTracker(
        clientId: c.traktId,
        clientSecret: c.traktSecret,
      ),
      TrackerKind.simkl => SimklTracker(clientId: c.simklId),
      TrackerKind.anilist => AniListTracker(clientId: c.anilistId),
      TrackerKind.mal => MalTracker(clientId: c.malId),
    };
  };
});

/// Trackers this build can offer, in display order.
final availableTrackersProvider = Provider<List<TrackerKind>>((ref) {
  final make = ref.watch(trackerFactoryProvider);
  return [
    for (final k in TrackerKind.values)
      if (make(k) != null) k,
  ];
});

final trackerTokenStoreProvider = Provider<TrackerTokenStore>(
  (ref) => TrackerTokenStore(),
);

final trackerQueueStoreProvider = Provider<TrackerQueueStore>(
  (ref) => TrackerQueueStore(ref.watch(appSettingsStoreProvider)),
);

/// Reads the item a pending watch refers to, and its show for an episode.
/// A seam for tests, which have no server.
typedef WatchResolver =
    Future<WatchedItem?> Function(String serverId, String itemId, DateTime at);

final watchResolverProvider = Provider<WatchResolver>((ref) {
  return (serverId, itemId, at) async {
    final server = ref
        .read(connectedServersProvider)
        .where((s) => s.id == serverId)
        .firstOrNull
        ?.service;
    if (server == null) throw const TrackerUnavailable('server offline');
    final item = await server
        .item(itemId)
        .timeout(const Duration(seconds: 10));
    if (item == null) return null;
    MediaItem? show;
    final showId = item.showId;
    if (item.type == MediaItemType.episode && showId != null) {
      show = await server
          .item(showId)
          .timeout(const Duration(seconds: 10))
          .catchError((_) => null);
    }
    return WatchedItem.from(item, show: show, at: at);
  };
});

@immutable
class TrackersState {
  const TrackersState({
    this.tokens = const {},
    this.pending = 0,
    this.loaded = false,
  });

  final Map<TrackerKind, TrackerToken> tokens;

  /// Watches waiting to be sent.
  final int pending;
  final bool loaded;

  bool signedIn(TrackerKind kind) => tokens.containsKey(kind);

  TrackersState copyWith({
    Map<TrackerKind, TrackerToken>? tokens,
    int? pending,
    bool? loaded,
  }) => TrackersState(
    tokens: tokens ?? this.tokens,
    pending: pending ?? this.pending,
    loaded: loaded ?? this.loaded,
  );
}

final trackersProvider = NotifierProvider<TrackersController, TrackersState>(
  TrackersController.new,
);

/// Watch trackers (architecture.md §19): who is signed in, and delivering
/// finished watches to them.
///
/// **What is sent, and when.** When a film or episode from the person's own
/// server is finished (90% played, or marked watched by hand), its server
/// and item ids and the time go into a queue. Sending reads the title and its
/// IMDb, TMDB and TVDB ids from the server and gives each signed-in tracker
/// that much and nothing else. IPTV panels are never sent (§19.1): they are
/// not the person's own library, and §1 depends on this app not looking like
/// it catalogues them.
///
/// A tracker that is down keeps the watch for later; one that cannot find
/// the title drops it (retrying will not help); one whose sign-in has lapsed
/// is refreshed once and otherwise signed out here, with its watches kept
/// until the person signs in again or 30 days pass.
class TrackersController extends Notifier<TrackersState> {
  TrackerTokenStore get _tokens => ref.read(trackerTokenStoreProvider);
  TrackerQueueStore get _queue => ref.read(trackerQueueStoreProvider);
  bool _flushing = false;

  /// When each title was last reported, for [finished]'s duplicate check.
  /// In memory: a duplicate across an app restart is rare, and a tracker
  /// given the same watch twice records a second play, not an error.
  final _recent = <String, DateTime>{};
  static const _sameWatch = Duration(hours: 3);

  /// How long an undeliverable watch is kept.
  static const keepFor = Duration(days: 30);

  /// Retries before a watch is given up on, so a title that keeps failing
  /// for a reason not recognised as permanent does not stay forever.
  static const maxAttempts = 20;

  @override
  TrackersState build() {
    unawaited(_load());
    return TrackersState(pending: _queue.load().length);
  }

  Future<void> _load() async {
    final tokens = await _tokens.load();
    if (!ref.mounted) return;
    state = state.copyWith(tokens: tokens, loaded: true);
    unawaited(flush());
  }

  // --- Signing in ------------------------------------------------------

  Tracker _tracker(TrackerKind kind) {
    final t = ref.read(trackerFactoryProvider)(kind);
    if (t == null) throw StateError('No credentials for ${kind.name}');
    return t;
  }

  Future<SignInStart> startSignIn(TrackerKind kind) =>
      _tracker(kind).startSignIn();

  /// Throws [SignInPending] while a device code waits, [SignInFailed] when it
  /// cannot finish. Records consent with the sign-in: the person has just
  /// read what will be sent and agreed to it (§19.1).
  Future<void> finishSignIn(
    TrackerKind kind,
    SignInStart start, {
    String? pasted,
  }) async {
    final token = await _tracker(kind).finishSignIn(start, pasted: pasted);
    await _setToken(kind, token);
    await _queue.setConsents({..._queue.consents(), kind: DateTime.now()});
    unawaited(flush());
  }

  /// Signs out here. The service keeps the app authorised until the person
  /// revokes it in their account there; the app has no call that does both.
  Future<void> signOut(TrackerKind kind) async {
    final tokens = {...state.tokens}..remove(kind);
    await _tokens.save(tokens);
    final consents = {..._queue.consents()}..remove(kind);
    await _queue.setConsents(consents);
    state = state.copyWith(tokens: tokens);
  }

  Future<void> _setToken(TrackerKind kind, TrackerToken token) async {
    final tokens = {...state.tokens, kind: token};
    await _tokens.save(tokens);
    if (ref.mounted) state = state.copyWith(tokens: tokens);
  }

  /// For Move to another device (§17): stores sign-ins carried over from
  /// another device, as if signed in here.
  Future<void> importTokens(Map<TrackerKind, TrackerToken> incoming) async {
    final tokens = {...state.tokens, ...incoming};
    await _tokens.save(tokens);
    await _queue.setConsents({
      ..._queue.consents(),
      for (final k in incoming.keys) k: DateTime.now(),
    });
    state = state.copyWith(tokens: tokens);
  }

  // --- Sending ---------------------------------------------------------

  /// A film or episode from [serverId] was finished at [at] (now, unless an
  /// offline watch is being delivered). Does nothing when no tracker is
  /// signed in.
  Future<void> finished(String serverId, String itemId, {DateTime? at}) async {
    if (state.tokens.isEmpty) return;
    final entry = PendingTrack(
      serverId: serverId,
      itemId: itemId,
      at: at ?? DateTime.now(),
    );
    // The same title finished twice within a few hours is one watch: the
    // player reports it, and the person may then also mark it watched. The
    // queue alone cannot tell, because a sent watch has already left it.
    final last = _recent[entry.key];
    if (last != null && entry.at.difference(last).abs() < _sameWatch) return;
    _recent[entry.key] = entry.at;
    await _save([..._queue.load(), entry]);
    await flush();
  }

  Future<void> _save(List<PendingTrack> queue) async {
    await _queue.save(queue);
    if (ref.mounted) state = state.copyWith(pending: queue.length);
  }

  /// Sends what it can. Safe to call often.
  Future<void> flush() async {
    if (_flushing || !ref.mounted) return;
    _flushing = true;
    try {
      final resolve = ref.read(watchResolverProvider);
      final cutoff = DateTime.now().subtract(keepFor);
      final next = <PendingTrack>[];
      for (final p in _queue.load()) {
        if (p.at.isBefore(cutoff) || p.attempts >= maxAttempts) continue;
        final wanted = {
          for (final k in state.tokens.keys)
            if (!p.done.contains(k)) k,
        };
        if (wanted.isEmpty) {
          // Nobody signed in still wants it; keep it only if someone might
          // sign back in to a tracker that has not had it.
          if (state.tokens.isEmpty) next.add(p);
          continue;
        }
        WatchedItem? item;
        try {
          item = await resolve(p.serverId, p.itemId, p.at);
        } catch (_) {
          next.add(p.copyWith(attempts: p.attempts + 1));
          continue;
        }
        if (item == null) continue; // Gone from the server.
        final done = {...p.done};
        var retry = false;
        for (final kind in wanted) {
          if (kind.animeOnly && !item.isAnime) {
            done.add(kind);
            continue;
          }
          switch (await _send(kind, item)) {
            case _Outcome.sent || _Outcome.notFound:
              done.add(kind);
            case _Outcome.later:
              retry = true;
          }
        }
        if (retry) next.add(p.copyWith(done: done, attempts: p.attempts + 1));
      }
      if (ref.mounted) await _save(next);
    } finally {
      _flushing = false;
    }
  }

  Future<_Outcome> _send(TrackerKind kind, WatchedItem item) async {
    final tracker = _tracker(kind);
    var token = state.tokens[kind];
    if (token == null) return _Outcome.later;
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        if (token!.isExpired) throw const TrackerSignedOut();
        final ok = await tracker.markWatched(item, token);
        return ok ? _Outcome.sent : _Outcome.notFound;
      } on TrackerSignedOut {
        if (attempt == 1) break;
        try {
          token = await tracker.refresh(token!);
          await _setToken(kind, token);
        } on TrackerSignedOut {
          break;
        } on TrackerUnavailable {
          return _Outcome.later;
        }
      } on TrackerUnavailable {
        return _Outcome.later;
      } catch (e) {
        debugPrint('Tracker ${kind.name}: $e');
        return _Outcome.later;
      }
    }
    // The sign-in is no good any more. Signed out here so Settings says so;
    // the watch stays queued for when the person signs back in.
    if (ref.mounted) await signOut(kind);
    return _Outcome.later;
  }
}

enum _Outcome { sent, notFound, later }
