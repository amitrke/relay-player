import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

/// What a sending device needs to find and talk to a receiving one (§17).
///
/// The receiver shows this as a QR code, and as text for a phone that cannot
/// scan. The **secret is never sent over the network**: it is shown on one
/// screen and read off it by a person or a camera, which is the whole of the
/// authentication. Everything the sender transmits is sealed with a key derived
/// from it ([TransferCipher]), so someone else on the network who finds the
/// port can neither read what arrives nor push something of their own.
class PairingInfo {
  PairingInfo({required this.host, required this.port, required this.secret}) {
    if (secret.length != secretBytes) {
      throw ArgumentError('A pairing secret is $secretBytes bytes.');
    }
  }

  /// A fresh secret for [host]:[port].
  factory PairingInfo.generate({
    required String host,
    required int port,
    Random? random,
  }) {
    final rng = random ?? Random.secure();
    return PairingInfo(
      host: host,
      port: port,
      secret: Uint8List.fromList([
        for (var i = 0; i < secretBytes; i++) rng.nextInt(256),
      ]),
    );
  }

  /// 80 bits. Long enough that sniffing one sealed message off the Wi-Fi and
  /// guessing the key offline is not a plan, and short enough (16 characters)
  /// to type from a TV across the room when the camera is not an option.
  static const secretBytes = 10;

  final String host;
  final int port;
  final Uint8List secret;

  /// The secret as the receiver shows it: `ABCD-EFGH-JKMN-PQRS`.
  String get displayCode => _group(_encode(secret));

  /// `192.168.1.20:41234`, shown next to [displayCode].
  String get address => '$host:$port';

  /// What the QR code carries.
  String get uri => Uri(
    scheme: 'subnext',
    host: 'pair',
    queryParameters: {'h': host, 'p': '$port', 'k': _encode(secret)},
  ).toString();

  /// Reads what a person typed or a camera scanned.
  ///
  /// Accepts the [uri], or an address and a code in either order separated by
  /// anything at all (`192.168.1.20:41234 ABCD-EFGH-JKMN-PQRS`), because what
  /// gets typed off a TV is never exactly what was displayed. Returns null when
  /// it cannot find both.
  static PairingInfo? tryParse(String input) {
    final text = input.trim();
    if (text.isEmpty) return null;

    if (text.toLowerCase().startsWith('subnext://')) {
      final uri = Uri.tryParse(text);
      if (uri == null || uri.host != 'pair') return null;
      final host = uri.queryParameters['h'];
      final port = int.tryParse(uri.queryParameters['p'] ?? '');
      final secret = _decode(uri.queryParameters['k'] ?? '');
      if (host == null || !_validHost(host) || port == null || secret == null) {
        return null;
      }
      if (port < 1 || port > 65535) return null;
      return PairingInfo(host: host, port: port, secret: secret);
    }

    final address = RegExp(r'(\d{1,3}(?:\.\d{1,3}){3})\s*:\s*(\d{1,5})')
        .firstMatch(text);
    if (address == null) return null;
    final host = address.group(1)!;
    final port = int.parse(address.group(2)!);
    if (!_validHost(host) || port < 1 || port > 65535) return null;

    final rest = text.replaceRange(address.start, address.end, ' ');
    final secret = _decode(rest);
    if (secret == null) return null;
    return PairingInfo(host: host, port: port, secret: secret);
  }

  /// Dotted-quad IPv4 only. The receiver advertises its LAN address, and
  /// accepting a name here would let a QR code point the sender, and the
  /// sealed credentials with it, anywhere on the internet.
  static bool _validHost(String host) {
    final parts = host.split('.');
    if (parts.length != 4) return false;
    return parts.every((p) {
      final n = int.tryParse(p);
      return n != null && n >= 0 && n <= 255;
    });
  }

  // Crockford's base32: no I, L, O or U, so a code read aloud or off a TV
  // cannot be mistaken for another one.
  static const _alphabet = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';

  static String _encode(Uint8List bytes) {
    var bits = 0;
    var acc = 0;
    final out = StringBuffer();
    for (final b in bytes) {
      // Masked: at most 12 bits are ever live, and an unmasked accumulator
      // would overflow after eight bytes.
      acc = ((acc << 8) | b) & 0xFFFF;
      bits += 8;
      while (bits >= 5) {
        out.write(_alphabet[(acc >> (bits - 5)) & 31]);
        bits -= 5;
      }
    }
    if (bits > 0) out.write(_alphabet[(acc << (5 - bits)) & 31]);
    return out.toString();
  }

  /// The exact inverse of [_encode] for a [secretBytes]-byte secret, ignoring
  /// case and separators and reading the usual look-alikes (O as 0, I and L as
  /// 1). Null unless exactly one secret's worth of characters is left.
  static Uint8List? _decode(String text) {
    final chars = <int>[];
    for (final unit in text.toUpperCase().split('')) {
      if (unit == '-' || unit == '_' || unit.trim().isEmpty) continue;
      final c = switch (unit) {
        'O' => '0',
        'I' || 'L' => '1',
        _ => unit,
      };
      final v = _alphabet.indexOf(c);
      if (v < 0) return null;
      chars.add(v);
    }
    if (chars.length != (secretBytes * 8 / 5).ceil()) return null;

    var acc = 0;
    var bits = 0;
    final out = <int>[];
    for (final v in chars) {
      acc = ((acc << 5) | v) & 0xFFFFFF;
      bits += 5;
      if (bits >= 8) {
        out.add((acc >> (bits - 8)) & 0xFF);
        bits -= 8;
      }
    }
    return out.length == secretBytes ? Uint8List.fromList(out) : null;
  }

  static String _group(String code) => [
    for (var i = 0; i < code.length; i += 4)
      code.substring(i, min(i + 4, code.length)),
  ].join('-');
}

/// Thrown when a message does not open with the pairing secret.
class TransferAuthException implements Exception {
  const TransferAuthException();

  @override
  String toString() => 'That message was not sealed with this pairing code.';
}

/// Seals and opens what travels between two paired devices.
///
/// AES-256-GCM under a key derived from the pairing secret with HKDF-SHA256.
/// GCM is both the confidentiality and the authentication: a message that does
/// not open was not made by someone holding the secret, so the receiver can
/// tell the sender from anything else that finds its port.
///
/// There is deliberately no key exchange. The secret already crossed a channel
/// an attacker cannot reach, which is the screen and the camera, and a
/// Diffie-Hellman round on top would protect nothing the secret does not.
class TransferCipher {
  TransferCipher(this._secret);

  final List<int> _secret;

  static final _algorithm = AesGcm.with256bits();
  static const _nonceLength = 12;
  static const _macLength = 16;

  // Versioned, so a later format cannot be confused with this one.
  static final _info = utf8.encode('subnext-transfer-v1/key');
  static final _aad = utf8.encode('subnext-transfer-v1/message');

  Future<SecretKey> _key() => Hkdf(
    hmac: Hmac.sha256(),
    outputLength: 32,
  ).deriveKey(secretKey: SecretKey(_secret), nonce: const [], info: _info);

  /// `nonce || ciphertext || tag`. A fresh random nonce per message.
  Future<Uint8List> seal(List<int> plain) async {
    final box = await _algorithm.encrypt(
      plain,
      secretKey: await _key(),
      aad: _aad,
    );
    return Uint8List.fromList(box.concatenation());
  }

  /// Throws [TransferAuthException] unless [sealed] was made with this secret
  /// and has not been altered.
  Future<Uint8List> open(List<int> sealed) async {
    if (sealed.length < _nonceLength + _macLength) {
      throw const TransferAuthException();
    }
    try {
      final box = SecretBox.fromConcatenation(
        sealed,
        nonceLength: _nonceLength,
        macLength: _macLength,
      );
      return Uint8List.fromList(
        await _algorithm.decrypt(box, secretKey: await _key(), aad: _aad),
      );
    } on SecretBoxAuthenticationError {
      throw const TransferAuthException();
    }
  }
}
