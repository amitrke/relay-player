import 'dart:convert';

import 'package:saf_util/saf_util.dart';

import '../local/app_settings_store.dart';

/// A folder the user granted access to through the Storage Access Framework.
class SafFolder {
  const SafFolder({required this.uri, required this.name});

  /// A `content://` tree URI. Opaque — it is not a path and must not be treated
  /// as one.
  final String uri;
  final String name;

  Map<String, dynamic> toJson() => {'uri': uri, 'name': name};

  static SafFolder? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final uri = raw['uri'];
    final name = raw['name'];
    if (uri is! String) return null;
    return SafFolder(uri: uri, name: name is String ? name : uri);
  }
}

/// A video inside a SAF folder.
class SafVideo {
  const SafVideo({
    required this.uri,
    required this.name,
    required this.sizeBytes,
  });

  final String uri;
  final String name;
  final int sizeBytes;
}

/// User-picked folders, via the Storage Access Framework (§7.1).
///
/// The other half of §7.1. MediaStore covers what Android already indexes;
/// this covers a folder the user points at explicitly — an SD card, a Downloads
/// subfolder, anywhere MediaStore does not look.
///
/// **The permission is the whole point.** SAF grants are persistable, and §15
/// singles out surviving a *reboot* as the case that fails in practice — not a
/// restart, a reboot. So [pickFolder] always asks for a persistable grant, and
/// [isStillAccessible] exists so the UI can tell a revoked folder from an empty
/// one rather than showing "no videos" for a permission problem.
class SafFolderSource {
  SafFolderSource(this._settings);

  final AppSettingsStore _settings;
  final SafUtil _saf = SafUtil();

  static const _key = 'saf.folders';

  static const _videoExtensions = {
    'mp4', 'mkv', 'avi', 'mov', 'm4v', 'webm', 'ts', 'm2ts', 'mpg', 'mpeg',
    'wmv', 'flv', '3gp',
  };

  List<SafFolder> folders() {
    final raw = _settings.getString(_key);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return [for (final entry in decoded) ?SafFolder.fromJson(entry)];
    } on FormatException {
      return const [];
    }
  }

  Future<void> _write(List<SafFolder> folders) => _settings.setString(
        _key,
        jsonEncode([for (final f in folders) f.toJson()]),
      );

  /// Opens the system folder picker and remembers what came back.
  ///
  /// Read-only: this app plays files, it never writes to the user's folders, and
  /// asking for write access we do not use is the kind of over-request §7.1 is
  /// trying to avoid.
  Future<SafFolder?> pickFolder() async {
    final picked = await _saf.pickDirectory(
      writePermission: false,
      persistablePermission: true,
    );
    if (picked == null) return null;

    final folder = SafFolder(uri: picked.uri, name: picked.name);
    final existing = folders().where((f) => f.uri != folder.uri);
    await _write([...existing, folder]);
    return folder;
  }

  Future<void> forget(String uri) async {
    await _write([for (final f in folders()) if (f.uri != uri) f]);
  }

  /// Whether the stored grant still works — the Q5 reboot question, asked at
  /// runtime.
  Future<bool> isStillAccessible(String uri) async {
    try {
      await _saf.list(uri);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Videos directly inside [uri]. Not recursive: §12 screen 4 describes a
  /// breadcrumb folder browser, so descending is the user's choice.
  Future<List<SafVideo>> videosIn(String uri) async {
    final entries = await _saf.list(uri);
    return [
      for (final entry in entries)
        if (!entry.isDir && _looksLikeVideo(entry.name))
          SafVideo(
            uri: entry.uri,
            name: entry.name,
            sizeBytes: entry.length,
          ),
    ];
  }

  Future<List<SafFolder>> subfoldersIn(String uri) async {
    final entries = await _saf.list(uri);
    return [
      for (final entry in entries)
        if (entry.isDir) SafFolder(uri: entry.uri, name: entry.name),
    ];
  }

  /// SAF reports MIME types inconsistently across providers, so the extension
  /// is the more reliable signal here.
  static bool _looksLikeVideo(String name) {
    final dot = name.lastIndexOf('.');
    if (dot == -1) return false;
    return _videoExtensions.contains(name.substring(dot + 1).toLowerCase());
  }
}
