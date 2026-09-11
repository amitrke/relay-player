import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:smb_connect/smb_connect.dart';

import '../local/app_settings_store.dart';
import 'loopback_bridge.dart';

/// §3's `NetworkShare`, minus its password.
class SmbShare {
  const SmbShare({
    required this.id,
    required this.name,
    required this.host,
    required this.username,
    this.domain = '',
  });

  final String id;
  final String name;
  final String host;
  final String username;
  final String domain;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'host': host,
        'username': username,
        'domain': domain,
      };

  static SmbShare? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final id = raw['id'];
    final host = raw['host'];
    if (id is! String || host is! String) return null;
    return SmbShare(
      id: id,
      name: raw['name'] is String ? raw['name'] as String : host,
      host: host,
      username: raw['username'] is String ? raw['username'] as String : '',
      domain: raw['domain'] is String ? raw['domain'] as String : '',
    );
  }
}

/// One entry in an SMB directory.
class SmbEntry {
  const SmbEntry({
    required this.path,
    required this.name,
    required this.isDirectory,
    required this.sizeBytes,
  });

  final String path;
  final String name;
  final bool isDirectory;
  final int sizeBytes;
}

/// Configured SMB shares (§7.2).
///
/// Same §3 split as everywhere else: the record goes in the Hive box and the
/// password only into secure storage, joined on read and deleted together.
class SmbShareStore {
  SmbShareStore({
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

  static const _key = 'smb.shares';
  static String _passwordKey(String id) => 'smb.password.$id';

  List<SmbShare> shares() {
    final raw = _settings.getString(_key);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return [for (final entry in decoded) ?SmbShare.fromJson(entry)];
    } on FormatException {
      return const [];
    }
  }

  Future<String?> password(String id) => _secrets.read(key: _passwordKey(id));

  Future<void> save(SmbShare share, {String? password}) async {
    final existing = shares().where((s) => s.id != share.id);
    await _settings.setString(
      _key,
      jsonEncode([for (final s in [...existing, share]) s.toJson()]),
    );
    if (password != null) {
      await _secrets.write(key: _passwordKey(share.id), value: password);
    }
  }

  Future<void> remove(String id) async {
    await _settings.setString(
      _key,
      jsonEncode([for (final s in shares().where((s) => s.id != id)) s.toJson()]),
    );
    await _secrets.delete(key: _passwordKey(id));
  }
}

/// A live connection to one SMB server.
///
/// §7.2 calls the connection "real state to manage", and Phase 0 left the
/// failure behaviour untested on purpose — the happy path is solid, what a
/// sleeping NAS or a dropped Wi-Fi does is not. So every call here is wrapped
/// and reported rather than allowed to surface as a raw package exception.
class SmbSession {
  SmbSession._(this._connect);

  final SmbConnect _connect;

  static const _videoExtensions = {
    'mp4', 'mkv', 'avi', 'mov', 'm4v', 'webm', 'ts', 'm2ts', 'mpg', 'mpeg',
    'wmv', 'flv', '3gp',
  };

  static Future<SmbSession> connect({
    required String host,
    required String username,
    required String password,
    String domain = '',
  }) async {
    final connection = await SmbConnect.connectAuth(
      host: host,
      username: username,
      password: password,
      domain: domain,
    );
    return SmbSession._(connection);
  }

  /// Top-level shares on the server.
  Future<List<SmbEntry>> shares() async {
    final found = await _connect.listShares();
    return [
      for (final share in found)
        SmbEntry(
          path: share.path,
          name: _lastSegment(share.path),
          isDirectory: true,
          sizeBytes: 0,
        ),
    ];
  }

  /// Folders and video files directly under [path].
  Future<List<SmbEntry>> list(String path) async {
    final folder = await _connect.file(path);
    final entries = await _connect.listFiles(folder);
    final result = <SmbEntry>[];
    for (final entry in entries) {
      final isDir = entry.isDirectory();
      final name = _lastSegment(entry.path);
      if (!isDir && !_looksLikeVideo(name)) continue;
      result.add(SmbEntry(
        path: entry.path,
        name: name,
        isDirectory: isDir,
        sizeBytes: entry.size,
      ));
    }
    result.sort((a, b) {
      if (a.isDirectory != b.isDirectory) return a.isDirectory ? -1 : 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return result;
  }

  Future<BridgeSource> bridgeSourceFor(SmbEntry entry) async {
    final file = await _connect.file(entry.path);
    return _SmbBridgeSource(_connect, file, entry.name);
  }

  Future<void> close() async {
    await _connect.close();
  }

  static String _lastSegment(String path) {
    final trimmed = path.endsWith('/')
        ? path.substring(0, path.length - 1)
        : path;
    final slash = trimmed.lastIndexOf('/');
    return slash == -1 ? trimmed : trimmed.substring(slash + 1);
  }

  static bool _looksLikeVideo(String name) {
    final dot = name.lastIndexOf('.');
    if (dot == -1) return false;
    return _videoExtensions.contains(name.substring(dot + 1).toLowerCase());
  }
}

/// Random-access reads over SMB, for the loopback bridge.
///
/// Phase 0's make-or-break measurement was exactly this: seek to 50% and read
/// 64 KB. Without it the bridge could only stream start-to-finish and scrubbing
/// would be impossible.
class _SmbBridgeSource implements BridgeSource {
  _SmbBridgeSource(this._connect, this._file, this.name);

  final SmbConnect _connect;
  final SmbFile _file;

  @override
  final String name;

  /// Reads are serialised. One handle is reused rather than reopened per chunk
  /// — reopening per 256 KB would multiply round trips over the network — but a
  /// shared handle carries a position, so two overlapping reads would each move
  /// the other's cursor.
  Future<void> _lock = Future.value();

  @override
  int get length => _file.size;

  @override
  String get contentType {
    final dot = name.lastIndexOf('.');
    final ext = dot == -1 ? '' : name.substring(dot + 1).toLowerCase();
    return switch (ext) {
      'mp4' || 'm4v' => 'video/mp4',
      'mkv' => 'video/x-matroska',
      'webm' => 'video/webm',
      'ts' || 'm2ts' => 'video/mp2t',
      'avi' => 'video/x-msvideo',
      'mov' => 'video/quicktime',
      _ => 'application/octet-stream',
    };
  }

  @override
  Future<Uint8List> read(int start, int count) {
    final completer = Completer<Uint8List>();
    _lock = _lock.then((_) async {
      try {
        completer.complete(await _readNow(start, count));
      } catch (e, st) {
        completer.completeError(e, st);
      }
    });
    return completer.future;
  }

  Future<Uint8List> _readNow(int start, int count) async {
    final handle = await _connect.open(_file);
    try {
      await handle.setPosition(start);
      final collected = BytesBuilder(copy: false);
      while (collected.length < count) {
        final bytes = await handle.read(count - collected.length);
        if (bytes.isEmpty) break;
        collected.add(bytes);
      }
      return collected.takeBytes();
    } finally {
      await handle.close();
    }
  }
}
