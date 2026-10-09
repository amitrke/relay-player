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

abstract class TmdbCache {
  Future<TmdbLookup?> get(String key);
  Future<void> put(String key, TmdbLookup lookup);
  Future<void> clear();
}

class MemoryTmdbCache implements TmdbCache {
  final _map = <String, TmdbLookup>{};

  @override
  Future<TmdbLookup?> get(String key) async => _map[key];

  @override
  Future<void> put(String key, TmdbLookup lookup) async => _map[key] = lookup;

  @override
  Future<void> clear() async => _map.clear();
}

/// Its own Hive box rather than the settings box: one small record per title,
/// written one key at a time, and thousands of them. Nothing in it is secret
/// (§3), and it can be cleared without touching a setting.
class HiveTmdbCache implements TmdbCache {
  HiveTmdbCache._(this._box);

  final Box<dynamic> _box;

  static Future<HiveTmdbCache> open() async =>
      HiveTmdbCache._(await Hive.openBox<dynamic>('tmdb_cache'));

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
  Future<void> clear() => _box.clear();
}
