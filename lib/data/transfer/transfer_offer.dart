import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

import 'pairing.dart';

/// A device that scanned this device's code and is asking to be sent the
/// settings, waiting on the person here to say yes.
class PushRequest {
  PushRequest._(this.host, this.port);

  /// A request made up for a test of the screen that shows it; the real ones
  /// only come from a connection to [TransferOfferServer].
  PushRequest.forTesting(this.host, this.port);

  /// Where to send it. [host] is the address the request **came from**, not
  /// one the requester named, so a code cannot be used to make this device
  /// push credentials somewhere else.
  final String host;
  final int port;

  final _decision = Completer<bool>();

  /// The person's answer: true for yes, false for no (or none in time).
  Future<bool> get answer => _decision.future;

  void approve() {
    if (!_decision.isCompleted) _decision.complete(true);
  }

  void deny() {
    if (!_decision.isCompleted) _decision.complete(false);
  }
}

/// The sending end when **the sender shows the code** (§17.7).
///
/// For a device that cannot scan, a TV above all: it displays the QR code, a
/// phone scans it, and the phone opens an ordinary receiving listener and tells
/// this device which port. Nothing is sent here. This only answers "may I have
/// your settings?" and hands the question to the person, and the push that
/// follows is the same sealed push as any other.
///
/// **The approval is the whole point.** When the receiver shows the code, a
/// stranger who photographs it can only push things at a screen that reviews
/// them. When the sender shows it, the same stranger would be *given* the
/// credentials, so each request waits for a person here to see who is asking
/// and say yes. Lives for [lifetime], takes one request, and closes after
/// [maxFailures] wrong tries, as [TransferServer] does.
class TransferOfferServer {
  TransferOfferServer({
    this.lifetime = const Duration(minutes: 5),
    this.decisionTimeout = const Duration(minutes: 3),
    this.maxFailures = 5,
  });

  final Duration lifetime;
  final Duration decisionTimeout;
  final int maxFailures;

  static const _maxBody = 4096;

  HttpServer? _server;
  TransferCipher? _cipher;
  Timer? _expiry;
  int _failures = 0;
  bool _taken = false;
  PushRequest? _pending;
  final _request = Completer<PushRequest?>();

  bool get isRunning => _server != null;

  Future<PairingInfo> start({required String host}) async {
    if (_server != null) throw StateError('Already listening.');
    final server = await shelf_io.serve(_handle, InternetAddress.anyIPv4, 0);
    _server = server;
    final info = PairingInfo.generate(host: host, port: server.port);
    _cipher = TransferCipher(info.secret);
    _expiry = Timer(lifetime, close);
    return info;
  }

  /// The request that arrived, or null if the listener closed first.
  Future<PushRequest?> get request => _request.future;

  Future<void> close() async {
    _expiry?.cancel();
    final server = _server;
    _server = null;
    _cipher = null;
    if (!_request.isCompleted) _request.complete(null);
    _pending?.deny();
    await server?.close();
  }

  Future<Response> _handle(Request request) async {
    final cipher = _cipher;
    if (cipher == null ||
        request.method != 'POST' ||
        request.url.path != 'callback') {
      return Response.notFound('');
    }

    final declared = request.contentLength;
    if (declared != null && declared > _maxBody) {
      return Response(HttpStatus.requestEntityTooLarge);
    }
    final body = BytesBuilder(copy: false);
    await for (final chunk in request.read()) {
      body.add(chunk);
      if (body.length > _maxBody) {
        return Response(HttpStatus.requestEntityTooLarge);
      }
    }

    final Uint8List plain;
    try {
      plain = await cipher.open(body.takeBytes());
    } on TransferAuthException {
      if (++_failures >= maxFailures) unawaited(close());
      return Response.forbidden('');
    }

    final port = _portOf(plain);
    final remote =
        (request.context['shelf.io.connection_info'] as HttpConnectionInfo?)
            ?.remoteAddress;
    if (port == null ||
        remote == null ||
        remote.type != InternetAddressType.IPv4) {
      return Response(HttpStatus.badRequest);
    }

    if (_taken) return Response(HttpStatus.conflict, body: 'busy');
    _taken = true;

    final pending = PushRequest._(remote.address, port);
    _pending = pending;
    _request.complete(pending);
    _expiry?.cancel();

    final approved = await pending._decision.future.timeout(
      decisionTimeout,
      onTimeout: () => false,
    );
    // The answer goes back first; the push is the sender's next move and does
    // not need this listener, so it closes either way.
    scheduleMicrotask(() => unawaited(close()));
    return approved
        ? Response.ok('ok')
        : Response(HttpStatus.conflict, body: 'declined');
  }

  static int? _portOf(Uint8List plain) {
    try {
      final json = jsonDecode(utf8.decode(plain));
      final port = json is Map ? json['port'] : null;
      return port is int && port >= 1 && port <= 65535 ? port : null;
    } catch (_) {
      return null;
    }
  }
}
