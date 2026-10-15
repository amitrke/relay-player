import 'dart:convert';

import '../local/app_settings_store.dart';

/// Watching a saved copy with no network, written down so Plex can be told
/// later (architecture.md §18.6).
///
/// Before this, §18.4's progress reports simply failed offline: a film
/// finished on a flight was still unwatched on the server, and Continue
/// watching on every other device disagreed. One entry per title, holding only
/// the latest word: if the same episode is watched twice offline, the second
/// replaces the first, because only where it ended up matters to Plex.
///
/// **No token, no URL** (§3), like [DownloadRecord]: ids, a position and a
/// time. The request that delivers it is built from the live connection.
class PendingWatch {
  const PendingWatch({
    required this.serverId,
    required this.ratingKey,
    required this.position,
    required this.duration,
    required this.at,
    this.watched = false,
  });

  final String serverId;
  final String ratingKey;
  final Duration position;
  final Duration duration;

  /// When this happened on the device. Compared with the server's
  /// `lastViewedAt` on replay, so a newer watch elsewhere wins.
  final DateTime at;

  /// A finished watch, or an explicit "mark as watched", rather than a
  /// position. Sent as a scrobble, which is unambiguous, instead of a
  /// timeline report that Plex would have to interpret.
  final bool watched;

  String get key => 'plex:$serverId:$ratingKey';

  Map<String, Object?> toJson() => {
    'serverId': serverId,
    'ratingKey': ratingKey,
    'positionMs': position.inMilliseconds,
    'durationMs': duration.inMilliseconds,
    'at': at.toUtc().toIso8601String(),
    'watched': watched,
  };

  static PendingWatch? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final serverId = raw['serverId'];
    final ratingKey = raw['ratingKey'];
    final at = DateTime.tryParse('${raw['at']}');
    if (serverId is! String || ratingKey is! String || at == null) return null;
    int ms(Object? v) => v is int ? v : 0;
    return PendingWatch(
      serverId: serverId,
      ratingKey: ratingKey,
      position: Duration(milliseconds: ms(raw['positionMs'])),
      duration: Duration(milliseconds: ms(raw['durationMs'])),
      at: at,
      watched: raw['watched'] == true,
    );
  }
}

/// Plex's default "watched" threshold: past 90% counts as finished. A server
/// can be set differently; this is the default the server ships with, and it
/// only decides whether the replay is a scrobble or a position.
const watchedThreshold = 0.9;

/// A position report, made into a [PendingWatch] that says "watched" when it
/// is past [watchedThreshold].
PendingWatch pendingFrom({
  required String serverId,
  required String ratingKey,
  required Duration position,
  required Duration duration,
  required DateTime at,
}) {
  final finished =
      duration > Duration.zero &&
      position.inMilliseconds >= duration.inMilliseconds * watchedThreshold;
  return PendingWatch(
    serverId: serverId,
    ratingKey: ratingKey,
    position: position,
    duration: duration,
    at: at,
    watched: finished,
  );
}

/// What to do with one queued entry, given what the server says now.
enum ReplayAction {
  /// `/:/scrobble`.
  markWatched,

  /// A `stopped` timeline report at the queued position.
  reportPosition,

  /// The server already knows something newer; sending ours would overwrite
  /// it. The entry is dropped.
  drop,
}

/// Newer wins. If the server saw this title viewed after the device did,
/// another client watched on and its word stands, whatever ours says.
/// Otherwise a finished watch is a scrobble (a rewatch rightly adds a play)
/// and anything else a position.
///
/// Clock skew between the device and the server can tilt this either way by
/// however far apart they are. That is accepted: both are usually set by the
/// network, and the cost of a wrong call is one stale position.
ReplayAction replayActionFor(
  PendingWatch pending, {
  required DateTime? serverLastViewedAt,
}) {
  if (serverLastViewedAt != null && serverLastViewedAt.isAfter(pending.at)) {
    return ReplayAction.drop;
  }
  return pending.watched
      ? ReplayAction.markWatched
      : ReplayAction.reportPosition;
}

/// The queue, in the settings box. Not secret (see [PendingWatch]).
class OfflineWatchStore {
  OfflineWatchStore(this._settings);

  final AppSettingsStore _settings;

  static const _key = 'downloads.pendingWatch';

  List<PendingWatch> load() {
    final raw = _settings.getString(_key);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return [for (final e in decoded) ?PendingWatch.fromJson(e)];
    } on FormatException {
      return const [];
    }
  }

  Future<void> save(List<PendingWatch> items) => _settings.setString(
    _key,
    jsonEncode([for (final p in items) p.toJson()]),
  );
}
