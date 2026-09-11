import 'dart:convert';

import 'app_settings_store.dart';

/// What kind of thing was favourited.
///
/// Stored as the wire string rather than the enum index, so reordering this
/// enum can never silently reinterpret someone's saved favourites.
enum FavoriteKind {
  movie('movie'),
  show('show'),
  channel('channel');

  const FavoriteKind(this.wire);

  final String wire;

  static FavoriteKind? fromWire(String? value) {
    for (final k in values) {
      if (k.wire == value) return k;
    }
    return null;
  }
}

/// §3's `FavoriteItem`.
///
/// [sourceId] is what makes this work across sources: a Plex `ratingKey` and an
/// Xtream `stream_id` are both small ids that collide freely between servers and
/// panels, so an item is only identified by the triple.
class FavoriteItem {
  const FavoriteItem({
    required this.kind,
    required this.sourceId,
    required this.itemId,
  });

  final FavoriteKind kind;
  final String sourceId;
  final String itemId;

  String get key => '${kind.wire}:$sourceId:$itemId';

  Map<String, dynamic> toJson() =>
      {'type': kind.wire, 'source': sourceId, 'id': itemId};

  static FavoriteItem? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final kind = FavoriteKind.fromWire(raw['type'] as String?);
    final source = raw['source'];
    final id = raw['id'];
    if (kind == null || source is! String || id is! String) return null;
    return FavoriteItem(kind: kind, sourceId: source, itemId: id);
  }
}

/// Favourites, in the Hive box.
///
/// §3 puts these in the non-secret store deliberately — a favourite is not a
/// credential, and nothing here identifies anything beyond ids the user's own
/// sources already gave us.
class FavoritesStore {
  const FavoritesStore(this._settings);

  final AppSettingsStore _settings;

  static const _key = 'favorites';

  List<FavoriteItem> all() {
    final raw = _settings.getString(_key);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return [for (final entry in decoded) ?FavoriteItem.fromJson(entry)];
    } on FormatException {
      return const [];
    }
  }

  Future<void> write(List<FavoriteItem> items) => _settings.setString(
        _key,
        jsonEncode([for (final i in items) i.toJson()]),
      );
}
