import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../local/app_settings_store.dart';
import 'tracker.dart';

/// Tracker sign-ins, in secure storage (§3): tokens are secrets.
class TrackerTokenStore {
  TrackerTokenStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  static const _key = 'trackers.tokens';

  Future<Map<TrackerKind, TrackerToken>> load() async {
    final raw = await _storage.read(key: _key);
    if (raw == null || raw.isEmpty) return const {};
    try {
      final map = jsonDecode(raw);
      if (map is! Map) return const {};
      return {
        for (final e in map.entries)
          ?TrackerKind.fromName('${e.key}'): ?TrackerToken.fromJson(e.value),
      };
    } on FormatException {
      return const {};
    }
  }

  Future<void> save(Map<TrackerKind, TrackerToken> tokens) => _storage.write(
    key: _key,
    value: jsonEncode({
      for (final e in tokens.entries) e.key.name: e.value.toJson(),
    }),
  );
}

/// A finished watch waiting to reach the trackers (§19.4).
///
/// Holds where it was watched and when, not what: the title and its ids are
/// read from the server when it is sent, so a saved copy watched offline
/// (§18.6) is matched exactly as a stream would be. No token, no URL.
class PendingTrack {
  const PendingTrack({
    required this.serverId,
    required this.itemId,
    required this.at,
    this.done = const {},
    this.attempts = 0,
  });

  final String serverId;
  final String itemId;
  final DateTime at;

  /// Trackers that already have it, so a retry does not send it twice.
  final Set<TrackerKind> done;
  final int attempts;

  String get key => '$serverId|$itemId';

  PendingTrack copyWith({Set<TrackerKind>? done, int? attempts}) =>
      PendingTrack(
        serverId: serverId,
        itemId: itemId,
        at: at,
        done: done ?? this.done,
        attempts: attempts ?? this.attempts,
      );

  Map<String, Object?> toJson() => {
    's': serverId,
    'i': itemId,
    'at': at.toUtc().toIso8601String(),
    'done': [for (final k in done) k.name],
    'n': attempts,
  };

  static PendingTrack? fromJson(Object? raw) {
    if (raw is! Map || raw['s'] is! String || raw['i'] is! String) return null;
    final at = DateTime.tryParse('${raw['at']}');
    if (at == null) return null;
    return PendingTrack(
      serverId: raw['s'] as String,
      itemId: raw['i'] as String,
      at: at,
      done: {
        for (final d in (raw['done'] as List?) ?? const [])
          ?TrackerKind.fromName('$d'),
      },
      attempts: raw['n'] is int ? raw['n'] as int : 0,
    );
  }
}

/// The queue and each tracker's consent, in the settings box. Not secret.
class TrackerQueueStore {
  TrackerQueueStore(this._settings);

  final AppSettingsStore _settings;
  static const _kQueue = 'trackers.queue';
  static const _kConsent = 'trackers.consent';

  List<PendingTrack> load() {
    final raw = _settings.getString(_kQueue);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw);
      return list is List
          ? [for (final e in list) ?PendingTrack.fromJson(e)]
          : const [];
    } on FormatException {
      return const [];
    }
  }

  Future<void> save(List<PendingTrack> queue) => _settings.setString(
    _kQueue,
    jsonEncode([for (final p in queue) p.toJson()]),
  );

  /// When the person agreed to send their watches to each tracker (§19.1).
  Map<TrackerKind, DateTime> consents() {
    final raw = _settings.getStringMap(_kConsent);
    return {
      for (final e in raw.entries)
        ?TrackerKind.fromName(e.key): ?DateTime.tryParse(e.value),
    };
  }

  Future<void> setConsents(Map<TrackerKind, DateTime> c) =>
      _settings.setStringMap(_kConsent, {
        for (final e in c.entries) e.key.name: e.value.toUtc().toIso8601String(),
      });
}
