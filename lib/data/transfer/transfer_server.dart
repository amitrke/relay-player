import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

import 'pairing.dart';
import 'transfer_bundle.dart';

/// A bundle that arrived, opened and understood, and is waiting on the person
/// at this device. Nothing has been written anywhere yet.
class IncomingTransfer {
  IncomingTransfer._(this.bundle);

  final TransferBundle bundle;
  final _decision = Completer<bool>();

  /// Tells the sender it went through. The caller applies [bundle] first, so a
  /// sender never sees success for something that did not stick.
  void accept() {
    if (!_decision.isCompleted) _decision.complete(true);
  }

  /// Tells the sender it was refused. Also what happens if nobody answers.
  void decline() {
    if (!_decision.isCompleted) _decision.complete(false);
  }
}

/// The receiving end of a transfer (§17): a short-lived HTTP listener on the
/// local network that accepts exactly one bundle.
///
/// **It is open only while the Receive screen is.** Credentials never leave the
/// two devices and nothing here talks to the internet, but a port that stays
/// open is still a port, so this lives for [lifetime] at most, takes one
/// bundle, and closes. [maxFailures] wrong tries close it early: a person typing
/// the code wrongly twice is normal, a program guessing is not.
///
/// Every request is sealed with a key made from the pairing secret
/// ([TransferCipher]), so the port being reachable by anyone on the Wi-Fi gives
/// them nothing to read and nothing to push.
class TransferServer {
  TransferServer({
    this.lifetime = const Duration(minutes: 5),
    this.decisionTimeout = const Duration(minutes: 3),
    this.maxFailures = 5,
    this.maxBodyBytes = 2 * 1024 * 1024,
  });

  final Duration lifetime;

  /// How long a sender is kept waiting for the person to answer.
  final Duration decisionTimeout;
  final int maxFailures;
  final int maxBodyBytes;

  HttpServer? _server;
  TransferCipher? _cipher;
  Timer? _expiry;
  int _failures = 0;
  bool _taken = false;
  IncomingTransfer? _pending;
  final _incoming = Completer<IncomingTransfer?>();

  bool get isRunning => _server != null;

  /// Starts listening and returns what a sender needs. [host] is this device's
  /// LAN address; the listener itself accepts on every interface, since the
  /// address that reaches a phone is not always the one the OS lists first.
  Future<PairingInfo> start({required String host}) async {
    if (_server != null) throw StateError('Already listening.');
    final server = await shelf_io.serve(_handle, InternetAddress.anyIPv4, 0);
    _server = server;
    final info = PairingInfo.generate(host: host, port: server.port);
    _cipher = TransferCipher(info.secret);
    _expiry = Timer(lifetime, close);
    return info;
  }

  /// Completes with the bundle that arrived, or null if the listener closed
  /// first: it timed out, was cancelled, or was shut by too many wrong tries.
  Future<IncomingTransfer?> get incoming => _incoming.future;

  Future<void> close() async {
    _expiry?.cancel();
    final server = _server;
    _server = null;
    _cipher = null;
    if (!_incoming.isCompleted) _incoming.complete(null);
    // A sender still waiting on an answer gets "no" now, instead of holding
    // the close open until the decision times out.
    _pending?.decline();
    // Not forced: a sender who has just been told "done" is still reading it.
    await server?.close();
  }

  Future<Response> _handle(Request request) async {
    final cipher = _cipher;
    if (cipher == null ||
        request.method != 'POST' ||
        request.url.path != 'transfer') {
      return Response.notFound('');
    }

    final sealed = await _readLimited(request);
    if (sealed == null) return Response(HttpStatus.requestEntityTooLarge);

    final Uint8List plain;
    try {
      plain = await cipher.open(sealed);
    } on TransferAuthException {
      // No hint which part was wrong. Counted so a guessing program runs out
      // of tries long before it runs out of codes.
      if (++_failures >= maxFailures) unawaited(close());
      return Response.forbidden('');
    }

    final TransferBundle bundle;
    try {
      bundle = TransferBundle.decode(plain);
    } on TransferFormatException catch (e) {
      return Response(HttpStatus.badRequest, body: e.message);
    }

    // One bundle per listener. A second sender, or the same one retrying, is
    // told to ask for a fresh code rather than queued.
    if (_taken) return Response(HttpStatus.conflict, body: 'busy');
    _taken = true;

    final incoming = IncomingTransfer._(bundle);
    _pending = incoming;
    _incoming.complete(incoming);
    _expiry?.cancel();

    final accepted = await incoming._decision.future.timeout(
      decisionTimeout,
      onTimeout: () => false,
    );
    // After the response has been handed back, not before it.
    scheduleMicrotask(() => unawaited(close()));
    return accepted
        ? Response.ok('ok')
        : Response(HttpStatus.conflict, body: 'declined');
  }

  /// The body, or null if it runs past [maxBodyBytes]. Checked as it streams in
  /// rather than from `Content-Length`, which a sender is free to understate.
  Future<Uint8List?> _readLimited(Request request) async {
    final declared = request.contentLength;
    if (declared != null && declared > maxBodyBytes) return null;
    final out = BytesBuilder(copy: false);
    await for (final chunk in request.read()) {
      out.add(chunk);
      if (out.length > maxBodyBytes) return null;
    }
    return out.takeBytes();
  }
}
