import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'pairing.dart';
import 'transfer_bundle.dart';
import '../../i18n/strings.g.dart';

/// A transfer that did not go through, with a message fit to show.
class TransferException implements Exception {
  const TransferException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// The person at the other device said no (or never answered).
class TransferDeclined extends TransferException {
  TransferDeclined([String? message])
    : super(message ?? tr.transfer.client.declined);
}

/// The sending end of a transfer (§17).
class TransferClient {
  const TransferClient({
    this.connectTimeout = const Duration(seconds: 8),
    this.decisionTimeout = const Duration(minutes: 4),
  });

  final Duration connectTimeout;

  /// How long to wait for the person at the other device. A little longer than
  /// the receiver's own limit, so the receiver's answer is the one that wins.
  final Duration decisionTimeout;

  /// Seals [bundle] with [pairing]'s secret and delivers it. Completes when the
  /// receiver has applied it; throws [TransferException] otherwise.
  Future<void> send(PairingInfo pairing, TransferBundle bundle) async {
    final sealed = await TransferCipher(pairing.secret).seal(bundle.encode());
    final (status, body) = await _post(pairing, 'transfer', sealed);

    switch (status) {
      case HttpStatus.ok:
        return;
      case HttpStatus.forbidden:
        throw TransferException(tr.transfer.client.wrongCode);
      case HttpStatus.conflict:
        if (body == 'declined') throw TransferDeclined();
        throw TransferException(tr.transfer.client.used);
      case HttpStatus.requestEntityTooLarge:
        throw TransferException(tr.transfer.client.tooBig);
      case HttpStatus.badRequest:
        throw TransferException(
          body.isEmpty ? tr.transfer.client.unreadable : body,
        );
      default:
        throw TransferException(
          tr.transfer.client.unexpected(status: status),
        );
    }
  }

  /// For when the other device is showing the code (§17.7): tells it which port
  /// this device is listening on, and waits for its person to agree. When this
  /// completes, the bundle is on its way to the listener at [listenPort], so the
  /// caller should already be waiting there.
  Future<void> requestPush(PairingInfo offer, int listenPort) async {
    final sealed = await TransferCipher(offer.secret)
        .seal(utf8.encode(jsonEncode({'port': listenPort})));
    final (status, body) = await _post(offer, 'callback', sealed);

    switch (status) {
      case HttpStatus.ok:
        return;
      case HttpStatus.forbidden:
        throw TransferException(tr.transfer.client.wrongCode);
      case HttpStatus.conflict:
        if (body == 'declined') {
          throw TransferDeclined(tr.transfer.client.refusedToSend);
        }
        throw TransferException(tr.transfer.client.busy);
      default:
        throw TransferException(
          tr.transfer.client.unexpected(status: status),
        );
    }
  }

  /// One sealed POST, with every way it can fail already put into words.
  Future<(int, String)> _post(
    PairingInfo to,
    String path,
    List<int> sealed,
  ) async {
    final client = HttpClient()..connectionTimeout = connectTimeout;
    try {
      final request = await client.postUrl(
        Uri(scheme: 'http', host: to.host, port: to.port, path: '/$path'),
      );
      request.headers.contentType = ContentType.binary;
      request.contentLength = sealed.length;
      request.add(sealed);

      final response = await request.close().timeout(decisionTimeout);
      final body = await response.transform(utf8.decoder).join();
      return (response.statusCode, body);
    } on SocketException {
      throw TransferException(
        tr.transfer.client.unreachable(address: to.address),
      );
    } on HttpException {
      throw TransferException(tr.transfer.client.dropped);
    } on TimeoutException {
      throw TransferException(
        tr.transfer.client.noAnswer(address: to.address),
      );
    } finally {
      client.close(force: true);
    }
  }
}
