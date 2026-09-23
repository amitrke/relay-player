import 'dart:convert';

import 'app_settings_store.dart';

/// How to get back to something that was playing.
///
/// Stored as a wire string and turned into a route on read, rather than storing
/// the route itself — a stored URL would rot the moment routing changed, and
/// history is meant to outlive refactors.
enum PlaybackKind {
  plex('plex'),
  xtreamVod('xtream_vod'),
  xtreamEpisode('xtream_episode');

  const PlaybackKind(this.wire);

  final String wire;

  static PlaybackKind? fromWire(String? value) {
    for (final k in values) {
      if (k.wire == value) return k;
    }
    return null;
  }
}

/// §3's `HistoryItem`.
///
/// Live TV is deliberately absent: a channel has no position to resume to, so
/// putting one in a continue-watching row would offer to resume something that
/// cannot be resumed.
class HistoryItem {
  const HistoryItem({
    required this.kind,
    required this.sourceId,
    required this.itemId,
    required this.title,
    required this.position,
    required this.duration,
    required this.lastWatchedAt,
    this.poster,
  });

  final PlaybackKind kind;
  final String sourceId;
  final String itemId;

  /// Cached so the continue-watching row renders without refetching every
  /// item from its source — which on a panel would be one request per tile.
  final String title;

  /// Artwork reference, in whichever form is safe to write down.
  ///
  /// For Plex this is the **unsigned** server-relative path, re-signed at
  /// render time by `PlexService.posterUrlForPath`. For a panel it is the
  /// absolute image URL the panel gave us, which carries no credential.
  ///
  /// §3: this used to hold Plex's signed transcode URL, which put a live
  /// `X-Plex-Token` in the unencrypted box once per continue-watching row.
  /// [_withoutSecrets] enforces the rule in both directions so a future
  /// caller cannot reintroduce it, and so boxes written by the old code are
  /// cleaned the first time they are read.
  final String? poster;

  final Duration position;
  final Duration duration;
  final DateTime lastWatchedAt;

  String get key => '${kind.wire}:$sourceId:$itemId';

  String get route => switch (kind) {
        PlaybackKind.plex => '/play/$sourceId/$itemId',
        PlaybackKind.xtreamVod => '/vod/$sourceId/$itemId',
        PlaybackKind.xtreamEpisode => '/episode/$sourceId/$itemId',
      };

  double get progress => duration.inSeconds <= 0
      ? 0
      : (position.inSeconds / duration.inSeconds).clamp(0.0, 1.0);

  /// Whether this still belongs in a continue-watching row.
  ///
  /// Both ends are excluded on purpose: the first 60 seconds is usually a
  /// glance rather than a watch, and past 95% the thing is finished — offering
  /// to resume the closing credits is worse than not offering at all.
  bool get isResumable => progress > 0.01 && progress < 0.95 &&
      position > const Duration(seconds: 60);

  HistoryItem copyWith({Duration? position, DateTime? lastWatchedAt}) =>
      HistoryItem(
        kind: kind,
        sourceId: sourceId,
        itemId: itemId,
        title: title,
        poster: poster,
        position: position ?? this.position,
        duration: duration,
        lastWatchedAt: lastWatchedAt ?? this.lastWatchedAt,
      );

  Map<String, dynamic> toJson() => {
        'kind': kind.wire,
        'source': sourceId,
        'id': itemId,
        'title': title,
        'poster': _withoutSecrets(poster),
        'position': position.inSeconds,
        'duration': duration.inSeconds,
        'at': lastWatchedAt.millisecondsSinceEpoch,
      };

  /// Drops any artwork reference that carries credential material.
  ///
  /// Returns null rather than stripping the query parameter: a token-less
  /// transcode URL would render as a broken image, and a broken poster is a
  /// better outcome than a silently useless one. The row falls back to its
  /// placeholder icon, and the next play re-records the entry with a path.
  static String? _withoutSecrets(String? value) {
    if (value == null) return null;
    return value.toLowerCase().contains('x-plex-token') ? null : value;
  }

  static HistoryItem? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final kind = PlaybackKind.fromWire(raw['kind'] as String?);
    final source = raw['source'];
    final id = raw['id'];
    if (kind == null || source is! String || id is! String) return null;
    return HistoryItem(
      kind: kind,
      sourceId: source,
      itemId: id,
      title: raw['title'] is String ? raw['title'] as String : id,
      poster: _withoutSecrets(
        raw['poster'] is String ? raw['poster'] as String : null,
      ),
      position: Duration(seconds: (raw['position'] as num?)?.toInt() ?? 0),
      duration: Duration(seconds: (raw['duration'] as num?)?.toInt() ?? 0),
      lastWatchedAt: DateTime.fromMillisecondsSinceEpoch(
        (raw['at'] as num?)?.toInt() ?? 0,
      ),
    );
  }
}

/// Watch history, in the Hive box (§3 — not a credential).
class HistoryStore {
  const HistoryStore(this._settings);

  final AppSettingsStore _settings;

  static const _key = 'history';

  /// Capped because this is a convenience list, not an archive. Without a cap
  /// it grows forever in a box that is read whole on every launch.
  static const _limit = 60;

  List<HistoryItem> all() {
    final raw = _settings.getString(_key);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return [for (final entry in decoded) ?HistoryItem.fromJson(entry)]
        ..sort((a, b) => b.lastWatchedAt.compareTo(a.lastWatchedAt));
    } on FormatException {
      return const [];
    }
  }

  /// Marker for the one-time purge below. Versioned so a future leak of a
  /// different shape can force a fresh pass rather than reusing this one.
  static const _purgeMarker = 'history.credentialPurge.v1';

  /// Removes pre-2026-09-22 credential material from the box, once.
  ///
  /// [all] sanitises on read, but that only cleans memory: the token stays on
  /// disk until something writes, and "until the user next plays something" is
  /// not an acceptable lifetime for a live credential.
  ///
  /// **Why this is driven by a marker and not by inspecting the value.** The
  /// first version of this method ran only when the *current* value still
  /// contained a token, which looked obviously correct and was wrong in a way
  /// that took a file-level check to see. Hive appends: the first run rewrote
  /// the value clean, so the second run read a clean value, concluded there
  /// was nothing to do, and returned before compacting — leaving the
  /// superseded record, token intact, in `settings.hive` permanently. The
  /// migration disarmed itself after doing half the job. The marker makes the
  /// pass depend on whether it has *run*, not on what the value happens to
  /// look like afterwards.
  ///
  /// The value check is kept as a second trigger so that a future regression
  /// that writes a token again is still cleaned on the next launch.
  Future<bool> purgeLeakedCredentials() async {
    final done = _settings.getBool(_purgeMarker, fallback: false);
    final raw = _settings.getString(_key) ?? '';
    if (done && !raw.toLowerCase().contains('x-plex-token')) return false;

    await write(all());
    // Set before compacting, so the marker is in the rewritten file.
    await _settings.setBool(_purgeMarker, true);
    // Mandatory, not tidiness: without this the superseded record — token and
    // all — stays in settings.hive. See AppSettingsStore's append-only note.
    await _settings.compact();
    return true;
  }

  Future<void> write(List<HistoryItem> items) async {
    final sorted = [...items]
      ..sort((a, b) => b.lastWatchedAt.compareTo(a.lastWatchedAt));
    await _settings.setString(
      _key,
      jsonEncode([for (final i in sorted.take(_limit)) i.toJson()]),
    );
  }
}
