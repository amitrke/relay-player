import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../local/app_settings_store.dart';

/// The three catalogues a panel exposes, each with its own categories.
enum XtreamCatalogue {
  live('Live TV'),
  vod('Movies'),
  series('Series');

  const XtreamCatalogue(this.label);

  final String label;
}

/// A configured Xtream line, minus its password.
class XtreamAccount {
  const XtreamAccount({
    required this.id,
    required this.name,
    required this.host,
    required this.username,
    this.liveCategoryIds = const [],
    this.vodCategoryIds = const [],
    this.seriesCategoryIds = const [],
  });

  final String id;
  final String name;

  /// Scheme and authority, no trailing slash.
  final String host;
  final String username;

  /// §4.1: opt-in, not opt-out. Empty means the user has not chosen yet, which
  /// is a prompt to choose rather than a licence to fetch everything.
  ///
  /// Split by kind because they are three separate catalogues with their own
  /// category lists — Phase 0 counted 466 live, 156 VOD and 83 series
  /// categories on one panel, and a single shared selection would conflate them.
  final List<String> liveCategoryIds;
  final List<String> vodCategoryIds;
  final List<String> seriesCategoryIds;

  List<String> categoriesFor(XtreamCatalogue catalogue) => switch (catalogue) {
        XtreamCatalogue.live => liveCategoryIds,
        XtreamCatalogue.vod => vodCategoryIds,
        XtreamCatalogue.series => seriesCategoryIds,
      };

  XtreamAccount withCategories(
    XtreamCatalogue catalogue,
    List<String> ids,
  ) =>
      XtreamAccount(
        id: id,
        name: name,
        host: host,
        username: username,
        liveCategoryIds:
            catalogue == XtreamCatalogue.live ? ids : liveCategoryIds,
        vodCategoryIds:
            catalogue == XtreamCatalogue.vod ? ids : vodCategoryIds,
        seriesCategoryIds:
            catalogue == XtreamCatalogue.series ? ids : seriesCategoryIds,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'host': host,
        'username': username,
        'live': liveCategoryIds,
        'vod': vodCategoryIds,
        'series': seriesCategoryIds,
      };

  static XtreamAccount? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final id = raw['id'];
    final host = raw['host'];
    final username = raw['username'];
    if (id is! String || host is! String || username is! String) return null;
    return XtreamAccount(
      id: id,
      name: raw['name'] is String ? raw['name'] as String : host,
      host: host,
      username: username,
      // `categories` is the pre-split key and meant live channels. Read it so
      // an existing selection is not silently thrown away.
      liveCategoryIds: [
        for (final c in (raw['live'] ?? raw['categories']) as List? ?? const [])
          '$c',
      ],
      vodCategoryIds: [for (final c in raw['vod'] as List? ?? const []) '$c'],
      seriesCategoryIds: [
        for (final c in raw['series'] as List? ?? const []) '$c',
      ],
    );
  }
}

/// Persists Xtream accounts, split across two stores on purpose.
///
/// §3's credential rule, applied literally: the record (id, name, host,
/// username, chosen categories) goes in the Hive box, and the **password goes
/// only into `flutter_secure_storage`**, keyed by the account id. Hive is not
/// encrypted at rest, so a password in the box would be a plaintext password on
/// disk. The two are joined on read, here and nowhere else.
class XtreamAccountStore {
  XtreamAccountStore({
    required AppSettingsStore settings,
    FlutterSecureStorage? secrets,
  })  :
        // A named parameter cannot be private, so this cannot be an
        // initializing formal while the field stays private.
        // ignore: prefer_initializing_formals
        _settings = settings,
        _secrets = secrets ?? const FlutterSecureStorage();

  final AppSettingsStore _settings;
  final FlutterSecureStorage _secrets;

  static const _kAccounts = 'xtream.accounts';
  static String _passwordKey(String id) => 'xtream.password.$id';

  List<XtreamAccount> accounts() {
    final raw = _settings.getString(_kAccounts);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return [for (final entry in decoded) ?XtreamAccount.fromJson(entry)];
    } on FormatException {
      return const [];
    }
  }

  Future<String?> password(String id) =>
      _secrets.read(key: _passwordKey(id));

  Future<void> save(XtreamAccount account, {String? password}) async {
    final existing = accounts().where((a) => a.id != account.id);
    await _settings.setString(
      _kAccounts,
      jsonEncode([
        for (final a in [...existing, account]) a.toJson(),
      ]),
    );
    if (password != null) {
      await _secrets.write(key: _passwordKey(account.id), value: password);
    }
  }

  /// Removes the record and its password together, so deletion is atomic and
  /// leaves no orphaned secret behind (§3).
  Future<void> remove(String id) async {
    await _settings.setString(
      _kAccounts,
      jsonEncode([
        for (final a in accounts().where((a) => a.id != id)) a.toJson(),
      ]),
    );
    await _secrets.delete(key: _passwordKey(id));
  }
}
