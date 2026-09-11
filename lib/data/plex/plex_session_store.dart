import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// A Plex link that survived a restart.
class StoredPlexSession {
  const StoredPlexSession({
    required this.token,
    required this.baseUrl,
    required this.serverName,
  });

  final String token;
  final String baseUrl;
  final String serverName;
}

/// Persists the Plex link across launches.
///
/// §3's credential rule is the reason this is not a Hive box: the auth token is
/// secret material, and neither Hive nor Isar is encrypted at rest. Secrets live
/// only in `flutter_secure_storage` — Keystore/EncryptedSharedPreferences on
/// Android, Keychain on iOS. The non-secret half (server name, base URL) rides
/// along here for now and moves to the accounts box when that lands.
///
/// [clientId] is not a credential, but it must be **stable**: Plex binds an auth
/// token to the `X-Plex-Client-Identifier` that requested it, so regenerating it
/// per launch silently invalidates a token that is otherwise perfectly good.
class PlexSessionStore {
  PlexSessionStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _kToken = 'plex.token';
  static const _kBaseUrl = 'plex.baseUrl';
  static const _kServerName = 'plex.serverName';
  static const _kClientId = 'plex.clientId';

  /// The stable per-install client identifier, minted on first call.
  Future<String> clientId() async {
    final existing = await _storage.read(key: _kClientId);
    if (existing != null && existing.isNotEmpty) return existing;

    final bytes = List<int>.generate(16, (_) => Random.secure().nextInt(256));
    final id = 'relay-player-${base64Url.encode(bytes).replaceAll('=', '')}';
    await _storage.write(key: _kClientId, value: id);
    return id;
  }

  Future<StoredPlexSession?> read() async {
    final token = await _storage.read(key: _kToken);
    final baseUrl = await _storage.read(key: _kBaseUrl);
    if (token == null || token.isEmpty || baseUrl == null || baseUrl.isEmpty) {
      return null;
    }
    return StoredPlexSession(
      token: token,
      baseUrl: baseUrl,
      serverName: await _storage.read(key: _kServerName) ?? 'Plex',
    );
  }

  Future<void> write(StoredPlexSession session) async {
    await _storage.write(key: _kToken, value: session.token);
    await _storage.write(key: _kBaseUrl, value: session.baseUrl);
    await _storage.write(key: _kServerName, value: session.serverName);
  }

  /// Forgets the link. Leaves [clientId] alone — it identifies the install, not
  /// the account, and Plex shows a re-link as a new device if it changes.
  Future<void> clear() async {
    await _storage.delete(key: _kToken);
    await _storage.delete(key: _kBaseUrl);
    await _storage.delete(key: _kServerName);
  }
}
