import 'package:hive_ce_flutter/hive_flutter.dart';

/// The non-secret settings box (§3).
///
/// §3 splits storage deliberately: secrets live only in `flutter_secure_storage`
/// (see `PlexSessionStore`), and everything else — feature-flag state, theme
/// choice, the Plex library mapping — lives here. Hive is **not encrypted at
/// rest**, so nothing secret may ever be written to this box.
///
/// Values are stored as primitives and JSON-ish maps rather than typed adapters:
/// the shapes here are small and change often while Phase 1 settles, and a
/// generated adapter per shape would be churn for no benefit.
///
/// **A Hive box is an append-only log.** Overwriting a key appends the new
/// value and leaves the old bytes in the file until the box is compacted. That
/// makes [compact] part of the §3 contract rather than a housekeeping nicety:
/// on 2026-09-22 a value carrying a live `X-Plex-Token` was rewritten without
/// it, the unit test agreed the new value was clean, and the token was still
/// sitting in `settings.hive` because the superseded record had never gone
/// away. Anything that removes secret material from this box has to compact.
class AppSettingsStore {
  AppSettingsStore._(this._box);

  static const _boxName = 'settings';

  final Box<dynamic> _box;

  static Future<AppSettingsStore> open() async {
    await Hive.initFlutter();
    return AppSettingsStore._(await Hive.openBox<dynamic>(_boxName));
  }

  bool getBool(String key, {required bool fallback}) {
    final value = _box.get(key);
    return value is bool ? value : fallback;
  }

  Future<void> setBool(String key, bool value) => _box.put(key, value);

  String? getString(String key) {
    final value = _box.get(key);
    return value is String ? value : null;
  }

  Future<void> setString(String key, String value) => _box.put(key, value);

  /// Reads a `String -> String` map, tolerating whatever Hive hands back.
  ///
  /// Hive returns `Map<dynamic, dynamic>` for nested maps even when only
  /// strings were written, so this re-types rather than casting — a blind
  /// `as Map<String, String>` throws on read-back.
  Map<String, String> getStringMap(String key) {
    final value = _box.get(key);
    if (value is! Map) return const {};
    return {
      for (final entry in value.entries)
        if (entry.key is String && entry.value is String)
          entry.key as String: entry.value as String,
    };
  }

  Future<void> setStringMap(String key, Map<String, String> value) =>
      _box.put(key, value);

  /// Rewrites the box file, dropping superseded records.
  ///
  /// The only way to make an overwritten value actually leave the disk; see
  /// the append-only note on this class.
  Future<void> compact() => _box.compact();
}
