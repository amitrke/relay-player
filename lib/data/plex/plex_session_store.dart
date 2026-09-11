import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// One Plex server the user has connected.
class StoredPlexServer {
  const StoredPlexServer({
    required this.id,
    required this.name,
    required this.baseUrl,
    required this.token,
  });

  /// The server's `clientIdentifier` — stable across renames and address
  /// changes, which is why it keys the library mapping rather than the name.
  final String id;
  final String name;
  final String baseUrl;

  /// The per-server access token. For an owned server this usually equals the
  /// account token; for a shared one it does not.
  final String token;

  Map<String, dynamic> toJson() =>
      {'id': id, 'name': name, 'baseUrl': baseUrl, 'token': token};

  static StoredPlexServer? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final id = raw['id'];
    final name = raw['name'];
    final baseUrl = raw['baseUrl'];
    final token = raw['token'];
    if (id is! String || name is! String || baseUrl is! String ||
        token is! String) {
      return null;
    }
    return StoredPlexServer(
      id: id,
      name: name,
      baseUrl: baseUrl,
      token: token,
    );
  }
}

/// Persists the Plex link across launches.
///
/// §3's credential rule is the reason this is not a Hive box: auth tokens are
/// secret material, and neither Hive nor Isar is encrypted at rest. Everything
/// here is secret or travels with something secret, so the whole record lives in
/// `flutter_secure_storage` — Keystore on Android, Keychain on iOS.
///
/// [clientId] is not a credential, but it must be **stable**: Plex binds an auth
/// token to the `X-Plex-Client-Identifier` that requested it, so regenerating it
/// per launch silently invalidates a token that is otherwise perfectly good.
class PlexSessionStore {
  PlexSessionStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _kClientId = 'plex.clientId';
  static const _kAccountToken = 'plex.accountToken';
  static const _kServers = 'plex.servers';

  /// The stable per-install client identifier, minted on first call.
  Future<String> clientId() async {
    final existing = await _storage.read(key: _kClientId);
    if (existing != null && existing.isNotEmpty) return existing;

    final bytes = List<int>.generate(16, (_) => Random.secure().nextInt(256));
    final id = 'relay-player-${base64Url.encode(bytes).replaceAll('=', '')}';
    await _storage.write(key: _kClientId, value: id);
    return id;
  }

  /// The plex.tv account token.
  ///
  /// Kept separate from the per-server tokens because discovering *more*
  /// servers later needs account-level access — without it, "Add another
  /// server" would require re-running the whole PIN flow.
  Future<String?> accountToken() => _storage.read(key: _kAccountToken);

  Future<void> setAccountToken(String token) =>
      _storage.write(key: _kAccountToken, value: token);

  Future<List<StoredPlexServer>> servers() async {
    final raw = await _storage.read(key: _kServers);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return [for (final entry in decoded) ?StoredPlexServer.fromJson(entry)];
    } on FormatException {
      // A corrupt record should cost the user a re-link, not a crash loop on
      // every launch.
      return const [];
    }
  }

  Future<void> setServers(List<StoredPlexServer> servers) => _storage.write(
        key: _kServers,
        value: jsonEncode([for (final s in servers) s.toJson()]),
      );

  /// Forgets every link. Leaves [clientId] alone — it identifies the install,
  /// not the account, and Plex shows a re-link as a new device if it changes.
  Future<void> clear() async {
    await _storage.delete(key: _kAccountToken);
    await _storage.delete(key: _kServers);
  }
}
