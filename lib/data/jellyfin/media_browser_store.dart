import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../domain/models/media_server.dart';
import 'media_browser_service.dart';

/// One Jellyfin or Emby server the user signed in to.
class StoredMediaBrowserServer {
  const StoredMediaBrowserServer({required this.info, required this.auth});

  final MediaBrowserServerInfo info;
  final MediaBrowserAuth auth;

  Map<String, dynamic> toJson() => {
    'id': info.id,
    'name': info.name,
    'kind': info.kind.name,
    'version': info.version,
    'apiBase': info.apiBase,
    'userId': auth.userId,
    'userName': auth.userName,
    'token': auth.token,
  };

  static StoredMediaBrowserServer? fromJson(Object? raw) {
    if (raw is! Map) return null;
    String? s(String k) => raw[k] is String ? raw[k] as String : null;
    final id = s('id'), apiBase = s('apiBase'), token = s('token');
    final kind = ServerKind.fromName(s('kind'));
    if (id == null || apiBase == null || token == null || kind == null) {
      return null;
    }
    return StoredMediaBrowserServer(
      info: MediaBrowserServerInfo(
        id: id,
        name: s('name') ?? apiBase,
        kind: kind,
        version: s('version') ?? '',
        apiBase: apiBase,
      ),
      auth: MediaBrowserAuth(
        userId: s('userId') ?? '',
        userName: s('userName') ?? '',
        token: token,
      ),
    );
  }
}

/// Jellyfin and Emby sign-ins, in secure storage (§3): the record carries an
/// access token, so none of it goes in the settings box.
class MediaBrowserStore {
  MediaBrowserStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _kDeviceId = 'mediabrowser.deviceId';
  static const _kServers = 'mediabrowser.servers';

  /// Stable per install, minted on first use: both servers list a device by
  /// it, and a new one per launch would add a device every time.
  Future<String> deviceId() async {
    final existing = await _storage.read(key: _kDeviceId);
    if (existing != null && existing.isNotEmpty) return existing;
    final bytes = List<int>.generate(16, (_) => Random.secure().nextInt(256));
    final id = base64Url.encode(bytes).replaceAll('=', '');
    await _storage.write(key: _kDeviceId, value: id);
    return id;
  }

  Future<List<StoredMediaBrowserServer>> servers() async {
    final raw = await _storage.read(key: _kServers);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw);
      if (list is! List) return const [];
      return [for (final e in list) ?StoredMediaBrowserServer.fromJson(e)];
    } on FormatException {
      return const [];
    }
  }

  Future<void> setServers(List<StoredMediaBrowserServer> servers) =>
      _storage.write(
        key: _kServers,
        value: jsonEncode([for (final s in servers) s.toJson()]),
      );
}
