import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'pairing.dart';
import 'transfer_bundle.dart';

/// A transfer that did not go through, with a message fit to show.
class TransferException implements Exception {
  const TransferException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// The person at the other device said no (or never answered).
class TransferDeclined extends TransferException {
  const TransferDeclined()
    : super('The other device did not accept the settings.');
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

    final client = HttpClient()..connectionTimeout = connectTimeout;
    try {
      final request = await client.postUrl(
        Uri(
          scheme: 'http',
          host: pairing.host,
          port: pairing.port,
          path: '/transfer',
        ),
      );
      request.headers.contentType = ContentType.binary;
      request.contentLength = sealed.length;
      request.add(sealed);

      final response = await request.close().timeout(decisionTimeout);
      final body = await response.transform(utf8.decoder).join();

      switch (response.statusCode) {
        case HttpStatus.ok:
          return;
        case HttpStatus.forbidden:
          throw const TransferException(
            'The code was not right. Check it against the other screen.',
          );
        case HttpStatus.conflict:
          if (body == 'declined') throw const TransferDeclined();
          throw const TransferException(
            'The other device already received something. Open Receive again '
            'there for a fresh code.',
          );
        case HttpStatus.requestEntityTooLarge:
          throw const TransferException('That was too much to send.');
        case HttpStatus.badRequest:
          throw TransferException(
            body.isEmpty ? 'The other device could not read that.' : body,
          );
        default:
          throw TransferException(
            'The other device answered unexpectedly (${response.statusCode}).',
          );
      }
    } on SocketException {
      throw TransferException(
        'Could not reach ${pairing.address}. Both devices need to be on the '
        'same Wi-Fi, and the other one has to still be showing its code.',
      );
    } on HttpException {
      throw const TransferException('The connection dropped part-way.');
    } on TimeoutException {
      throw TransferException(
        'No answer from ${pairing.address}. Check the other screen.',
      );
    } finally {
      client.close(force: true);
    }
  }
}
