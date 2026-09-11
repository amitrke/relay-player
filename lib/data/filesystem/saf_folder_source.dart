import 'dart:convert';

import 'dart:typed_data';

import 'package:saf_stream/saf_stream.dart';
import 'package:saf_util/saf_util.dart';

import '../local/app_settings_store.dart';
import 'loopback_bridge.dart';

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

  /// A SAF file, as something the loopback bridge can serve.
  Future<BridgeSource> bridgeSourceFor(SafVideo video) async =>
      _SafBridgeSource(video);

  /// SAF reports MIME types inconsistently across providers, so the extension
  /// is the more reliable signal here.
  static bool _looksLikeVideo(String name) {
    final dot = name.lastIndexOf('.');
    if (dot == -1) return false;
    return _videoExtensions.contains(name.substring(dot + 1).toLowerCase());
  }
}

/// Random-access reads from a `content://` URI.
///
/// `readFileBytes(start:, count:)` is the whole reason this works: SAF can be
/// read at an offset, so the bridge can answer a range rather than only
/// streaming forwards from zero.
class _SafBridgeSource implements BridgeSource {
  _SafBridgeSource(this._video);

  final SafVideo _video;
  final SafStream _stream = SafStream();

  @override
  String get name => _video.name;

  @override
  int get length => _video.sizeBytes;

  @override
  String get contentType {
    final dot = _video.name.lastIndexOf('.');
    final ext = dot == -1 ? '' : _video.name.substring(dot + 1).toLowerCase();
    return switch (ext) {
      'mp4' || 'm4v' => 'video/mp4',
      'mkv' => 'video/x-matroska',
      'webm' => 'video/webm',
      'ts' || 'm2ts' => 'video/mp2t',
      'avi' => 'video/x-msvideo',
      'mov' => 'video/quicktime',
      // libmpv sniffs the container itself, so an unknown type is not fatal —
      // it just stops the type being a useful hint.
      _ => 'application/octet-stream',
    };
  }

  @override
  Future<Uint8List> read(int start, int count) =>
      _stream.readFileBytes(_video.uri, start: start, count: count);
}
