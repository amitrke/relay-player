import 'package:hive_ce_flutter/hive_flutter.dart';

import 'tmdb_client.dart';

/// What a past lookup found. [info] null with an [at] means "looked, nothing
/// convincing", which is worth remembering: without it a title with no match
/// would be searched again on every screen that shows it.
class TmdbLookup {
  const TmdbLookup(this.info, this.at);

  final TmdbInfo? info;
  final DateTime at;
}

/// Misses are retried eventually, since TMDB gains titles and a panel's naming
/// may differ next time. Hits do not expire: ratings drift, but not enough to
/// matter for a filter.
const tmdbMissLifetime = Duration(days: 14);

/// How long any record is kept at all, hit or miss. A title looked up once and
/// never seen again would otherwise sit on disk for good; looking one up again
/// after this is two cheap requests. Hits still never go stale within it.
const tmdbCacheMaxAge = Duration(days: 90);

abstract class TmdbCache {
  Future<TmdbLookup?> get(String key);
  Future<void> put(String key, TmdbLookup lookup);
  Future<void> clear();

  /// Deletes records older than [age].
  Future<void> prune(Duration age, {DateTime? now});
}

class MemoryTmdbCache implements TmdbCache {
  final _map = <String, TmdbLookup>{};

  @override
  Future<TmdbLookup?> get(String key) async => _map[key];

  @override
  Future<void> put(String key, TmdbLookup lookup) async => _map[key] = lookup;

  @override
  Future<void> clear() async => _map.clear();

  @override
  Future<void> prune(Duration age, {DateTime? now}) async {
    final cutoff = (now ?? DateTime.now()).subtract(age);
    _map.removeWhere((_, v) => v.at.isBefore(cutoff));
  }
}

/// Its own Hive box rather than the settings box: one small record per title,
/// written one key at a time, and thousands of them. Nothing in it is secret
/// (§3), and it can be cleared without touching a setting.
class HiveTmdbCache implements TmdbCache {
  HiveTmdbCache._(this._box);

  final Box<dynamic> _box;

  /// Opens the box, drops records over [tmdbCacheMaxAge], and compacts, so the
  /// file stays the size of what is kept (Hive appends, so overwritten records
  /// would otherwise linger in it).
  static Future<HiveTmdbCache> open() async {
    final cache = HiveTmdbCache._(await Hive.openBox<dynamic>('tmdb_cache'));
    try {
      await cache.prune(tmdbCacheMaxAge);
      await cache._box.compact();
    } catch (_) {}
    return cache;
  }

  @override
  Future<TmdbLookup?> get(String key) async {
    final raw = _box.get(key);
    if (raw is! Map) return null;
    final at = DateTime.tryParse('${raw['at']}');
    if (at == null) return null;
    return TmdbLookup(TmdbInfo.fromJson(raw['info']), at);
  }

  @override
  Future<void> put(String key, TmdbLookup lookup) => _box.put(key, {
    'at': lookup.at.toIso8601String(),
    'info': lookup.info?.toJson(),
  });

  @override
  Future<void> clear() async {
    await _box.clear();
    await _box.compact();
  }

  @override
  Future<void> prune(Duration age, {DateTime? now}) async {
    final cutoff = (now ?? DateTime.now()).subtract(age);
    final stale = <dynamic>[];
    for (final key in _box.keys) {
      final raw = _box.get(key);
      final at = raw is Map ? DateTime.tryParse('${raw['at']}') : null;
      // A record that cannot be read is as good as old.
      if (at == null || at.isBefore(cutoff)) stale.add(key);
    }
    if (stale.isNotEmpty) await _box.deleteAll(stale);
  }
}
