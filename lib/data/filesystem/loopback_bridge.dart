import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

/// Something the bridge can serve: a known length plus random access.
///
/// Random access is the requirement, not a nicety. Phase 0 watched libmpv jump
/// to the last 16 KB of a file to read the container index and then seek back
/// to the start — a source that could only stream forwards would look fine on
/// the first request and fail exactly there.
abstract class BridgeSource {
  String get name;
  int get length;
  String get contentType;

  Future<Uint8List> read(int start, int count);
}

/// A loopback HTTP server that makes a non-file source playable (§7.2).
///
/// libmpv can only open things it knows how to read. It cannot open a
/// `content://` URI, and it refuses `smb://` outright, so §7.2's answer is to
/// put an HTTP server in front and hand the player a `http://127.0.0.1` URL
/// instead. Phase 0 validated this shape for SMB and predicted it would be
/// reused; SAF is the second case.
///
/// **Byte ranges are mandatory**, not an optimisation — without them seeking
/// breaks and most containers will not even open.
class LoopbackBridge {
  HttpServer? _server;
  BridgeSource? _source;
  String? _token;

  bool get isRunning => _server != null;

  /// Starts serving [source] and returns the URL to hand the player.
  Future<String> serve(BridgeSource source) async {
    await stop();

    // Bound to loopback so nothing off-device can reach it, and behind an
    // unguessable path because every *other app on this device* can reach
    // 127.0.0.1 too. The token is what stops this being a way to read the
    // user's files.
    final token = _randomToken();
    _source = source;
    _token = token;

    _server = await shelf_io.serve(
      _handle,
      InternetAddress.loopbackIPv4,
      0,
    );

    return 'http://127.0.0.1:${_server!.port}/$token';
  }

  Future<void> stop() async {
    final server = _server;
    _server = null;
    _source = null;
    _token = null;
    await server?.close(force: true);
  }

  Future<Response> _handle(Request request) async {
    final source = _source;
    final token = _token;
    if (source == null || token == null) return Response.notFound('');
    if (request.url.path != token) return Response.forbidden('');

    final total = source.length;
    final range = _parseRange(request.headers['range'], total);

    // HEAD is how some players probe for length and range support before they
    // commit to reading anything.
    if (request.method == 'HEAD') {
      return Response.ok(
        null,
        headers: {
          'content-length': '$total',
          'content-type': source.contentType,
          'accept-ranges': 'bytes',
        },
      );
    }

    if (range == null) {
      return Response.ok(
        _stream(source, 0, total),
        headers: {
          'content-length': '$total',
          'content-type': source.contentType,
          'accept-ranges': 'bytes',
        },
      );
    }

    final (start, end) = range;
    if (start >= total) {
      return Response(
        HttpStatus.requestedRangeNotSatisfiable,
        headers: {'content-range': 'bytes */$total'},
      );
    }

    final count = end - start + 1;
    return Response(
      HttpStatus.partialContent,
      body: _stream(source, start, count),
      headers: {
        'content-length': '$count',
        'content-type': source.contentType,
        'accept-ranges': 'bytes',
        'content-range': 'bytes $start-$end/$total',
      },
    );
  }

  /// Reads in chunks rather than materialising the whole range.
  ///
  /// An open-ended `bytes=0-` on a 4 GB film is a perfectly ordinary request,
  /// and answering it with one allocation would be an immediate out-of-memory
  /// on the Fire TV stick §11 cares about.
  static Stream<List<int>> _stream(
    BridgeSource source,
    int start,
    int count,
  ) async* {
    const chunkSize = 256 * 1024;
    var offset = start;
    var remaining = count;

    while (remaining > 0) {
      final size = remaining < chunkSize ? remaining : chunkSize;
      Uint8List bytes;
      try {
        bytes = await source.read(offset, size);
      } catch (e) {
        // ignore: avoid_print
        rethrow;
      }
      if (bytes.isEmpty) return;
      yield bytes;
      offset += bytes.length;
      remaining -= bytes.length;
    }
  }

  /// `bytes=start-end`, `bytes=start-`, or `bytes=-suffix`.
  ///
  /// The open-ended form is the common one: Phase 0 saw libmpv send `bytes=0-`,
  /// then a tail range, then `bytes=5963-`.
  static (int, int)? _parseRange(String? header, int total) {
    if (header == null || !header.startsWith('bytes=')) return null;
    final spec = header.substring(6).split(',').first.trim();
    final dash = spec.indexOf('-');
    if (dash == -1) return null;

    final rawStart = spec.substring(0, dash);
    final rawEnd = spec.substring(dash + 1);

    if (rawStart.isEmpty) {
      final suffix = int.tryParse(rawEnd);
      if (suffix == null || suffix <= 0) return null;
      final start = suffix >= total ? 0 : total - suffix;
      return (start, total - 1);
    }

    final start = int.tryParse(rawStart);
    if (start == null) return null;
    final end = rawEnd.isEmpty ? total - 1 : int.tryParse(rawEnd);
    if (end == null) return null;
    return (start, end >= total ? total - 1 : end);
  }

  static String _randomToken() {
    final bytes = List<int>.generate(18, (_) => Random.secure().nextInt(256));
    return base64Url.encode(bytes).replaceAll('=', '');
  }
}
