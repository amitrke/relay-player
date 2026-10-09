import 'dart:convert';

import 'package:hive_ce_flutter/hive_flutter.dart';

import '../../domain/models/catalog_item.dart';

/// What one source last said about one tab, kept between launches.
///
/// Per source, not per tab, so a refresh can replace what a source returned and
/// leave the rest alone: a source that times out costs the user nothing, because
/// its last answer is still here.
class CachedSource {
  const CachedSource({
    required this.items,
    required this.signature,
    required this.at,
  });

  final List<CatalogItem> items;

  /// What the answer depended on (the library sections or categories chosen).
  /// An answer made for different choices is not a stand-in for the current one.
  final String signature;
  final DateTime at;
}

/// How long a kept answer is trusted, and how long it is kept at all.
///
/// A source that has been down for a month is not worth showing the old titles
/// of, and an entry nothing has refreshed in that long belongs to a source that
/// is gone. Both are decided by this one number, so the cache cannot hold things
/// nobody will use.
const libraryCacheMaxAge = Duration(days: 30);

abstract class LibraryCache {
  Future<CachedSource?> read(String key);
  Future<void> write(String key, CachedSource value);
  Future<void> clear();

  /// Deletes every entry whose key starts with [prefix].
  Future<void> deletePrefix(String prefix);

  /// Deletes entries last refreshed more than [age] ago.
  Future<void> prune(Duration age, {DateTime? now});
}

class MemoryLibraryCache implements LibraryCache {
  final map = <String, CachedSource>{};

  @override
  Future<CachedSource?> read(String key) async => map[key];

  @override
  Future<void> write(String key, CachedSource value) async => map[key] = value;

  @override
  Future<void> clear() async => map.clear();

  @override
  Future<void> deletePrefix(String prefix) async =>
      map.removeWhere((k, _) => k.startsWith(prefix));

  @override
  Future<void> prune(Duration age, {DateTime? now}) async {
    final cutoff = (now ?? DateTime.now()).subtract(age);
    map.removeWhere((_, v) => v.at.isBefore(cutoff));
  }
}

/// In its own Hive box: tens of thousands of titles do not belong in the
/// settings box, and the box can be cleared without touching a setting.
///
/// **Nothing secret is written.** A Plex poster is stored as its unsigned
/// server path and signed again on read, because the signed image URL carries
/// `X-Plex-Token` (section 3). [catalogItemToJson] enforces it both ways.
class HiveLibraryCache implements LibraryCache {
  HiveLibraryCache._(this._box);

  final Box<dynamic> _box;

  /// Opens the box, drops entries over [libraryCacheMaxAge], and compacts.
  ///
  /// Hive appends rather than overwrites, so every refresh leaves the previous
  /// copy of a source in the file until a compaction. Compacting here, once a
  /// launch, keeps the file at the size of what is actually kept.
  static Future<HiveLibraryCache> open() async {
    final cache = HiveLibraryCache._(
      await Hive.openBox<dynamic>('library_cache'),
    );
    try {
      await cache.prune(libraryCacheMaxAge);
      await cache._box.compact();
    } catch (_) {
      // Tidying is best effort; a cache that opens is a cache that works.
    }
    return cache;
  }

  @override
  Future<CachedSource?> read(String key) async {
    final raw = _box.get(key);
    if (raw is! String) return null;
    try {
      final m = jsonDecode(raw);
      if (m is! Map) return null;
      final at = DateTime.tryParse('${m['at']}');
      final items = m['items'];
      if (at == null || m['sig'] is! String || items is! List) return null;
      return CachedSource(
        signature: m['sig'] as String,
        at: at,
        items: [for (final i in items) ?catalogItemFromJson(i)],
      );
    } catch (_) {
      // A damaged entry is a miss. The library refetches and rewrites it.
      return null;
    }
  }

  @override
  Future<void> write(String key, CachedSource value) => _box.put(
    key,
    jsonEncode({
      'at': value.at.toIso8601String(),
      'sig': value.signature,
      'items': [for (final i in value.items) catalogItemToJson(i)],
    }),
  );

  @override
  Future<void> clear() async {
    await _box.clear();
    await _box.compact();
  }

  @override
  Future<void> deletePrefix(String prefix) => _box.deleteAll(
    _box.keys.where((k) => k is String && k.startsWith(prefix)).toList(),
  );

  @override
  Future<void> prune(Duration age, {DateTime? now}) async {
    final cutoff = (now ?? DateTime.now()).subtract(age);
    final stale = <dynamic>[];
    for (final key in _box.keys) {
      final raw = _box.get(key);
      // `at` is the first field written, so it can be read without decoding
      // the whole entry, which is hundreds of kilobytes.
      final at = raw is String
          ? DateTime.tryParse(
              RegExp(r'^\{"at":"([^"]+)"').firstMatch(raw)?.group(1) ?? '',
            )
          : null;
      // An entry that cannot be read is as good as old.
      if (at == null || at.isBefore(cutoff)) stale.add(key);
    }
    if (stale.isNotEmpty) await _box.deleteAll(stale);
  }
}

/// A catalogue item as it is written to disk.
///
/// Artwork: a Plex item stores [CatalogItem.posterPath] and never its signed
/// URL; a panel item stores its URL, which carries no credential. A URL that
/// does carry `X-Plex-Token` is dropped whatever its source, the same rule the
/// history store applies, so a future caller cannot reintroduce the leak.
Map<String, dynamic> catalogItemToJson(CatalogItem i) {
  final plex = i.source == CatalogSource.plex;
  final url = plex ? null : i.posterUrl;
  return {
    's': i.source.name,
    'sid': i.sourceId,
    'k': i.kind.name,
    'id': i.id,
    't': i.title,
    if (i.year != null) 'y': i.year,
    if (plex && i.posterPath != null) 'pp': i.posterPath,
    if (url != null && !url.toLowerCase().contains('x-plex-token')) 'pu': url,
    if (i.addedAt != null) 'a': i.addedAt!.millisecondsSinceEpoch,
    if (i.viewCount != null) 'vc': i.viewCount,
    if (i.viewOffset != null) 'vo': i.viewOffset!.inMilliseconds,
    if (i.duration != null) 'd': i.duration!.inMilliseconds,
    if (i.lastViewedAt != null) 'lv': i.lastViewedAt!.millisecondsSinceEpoch,
    if (i.language != null) 'l': i.language,
  };
}

/// The inverse. A Plex item comes back with no [CatalogItem.posterUrl]: the
/// caller signs [CatalogItem.posterPath] with the live connection, or leaves it
/// null when the server is not reachable yet.
CatalogItem? catalogItemFromJson(Object? json) {
  if (json is! Map) return null;
  final source = CatalogSource.values
      .where((v) => v.name == json['s'])
      .firstOrNull;
  final kind = CatalogKind.values.where((v) => v.name == json['k']).firstOrNull;
  final sid = json['sid'];
  final id = json['id'];
  final title = json['t'];
  if (source == null ||
      kind == null ||
      sid is! String ||
      id is! String ||
      title is! String) {
    return null;
  }

  DateTime? date(Object? ms) =>
      ms is int ? DateTime.fromMillisecondsSinceEpoch(ms) : null;
  Duration? span(Object? ms) => ms is int ? Duration(milliseconds: ms) : null;

  return CatalogItem(
    source: source,
    sourceId: sid,
    kind: kind,
    id: id,
    title: title,
    year: json['y'] as int?,
    posterUrl: json['pu'] as String?,
    posterPath: json['pp'] as String?,
    addedAt: date(json['a']),
    viewCount: json['vc'] as int?,
    viewOffset: span(json['vo']),
    duration: span(json['d']),
    lastViewedAt: date(json['lv']),
    language: json['l'] as String?,
  );
}
