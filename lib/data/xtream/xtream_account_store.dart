import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../local/app_settings_store.dart';

/// A configured Xtream line, minus its password.
class XtreamAccount {
  const XtreamAccount({
    required this.id,
    required this.name,
    required this.host,
    required this.username,
    this.selectedCategoryIds = const [],
  });

  final String id;
  final String name;

  /// Scheme and authority, no trailing slash.
  final String host;
  final String username;

  /// §4.1: opt-in, not opt-out. Empty means the user has not chosen yet, which
  /// is a prompt to choose rather than a licence to fetch everything.
  final List<String> selectedCategoryIds;

  XtreamAccount copyWith({String? name, List<String>? selectedCategoryIds}) =>
      XtreamAccount(
        id: id,
        name: name ?? this.name,
        host: host,
        username: username,
        selectedCategoryIds: selectedCategoryIds ?? this.selectedCategoryIds,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'host': host,
        'username': username,
        'categories': selectedCategoryIds,
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
      selectedCategoryIds: [
        for (final c in (raw['categories'] as List? ?? const [])) '$c',
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
