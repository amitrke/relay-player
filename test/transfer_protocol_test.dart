import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:relay_player/data/filesystem/smb_source.dart';
import 'package:relay_player/data/transfer/lan_address.dart';
import 'package:relay_player/data/transfer/pairing.dart';
import 'package:relay_player/data/transfer/transfer_bundle.dart';
import 'package:relay_player/data/transfer/transfer_client.dart';
import 'package:relay_player/data/transfer/transfer_offer.dart';
import 'package:relay_player/data/transfer/transfer_server.dart';
import 'package:relay_player/data/xtream/xtream_account_store.dart';

/// Placeholder hosts and credentials only, per the no-provider rule in
/// CLAUDE.md.
TransferBundle _bundle() => TransferBundle(
  createdAt: DateTime.utc(2026, 10, 9),
  preferences: const {
    'playback.skipSeconds': '30',
    'subtitles.on': true,
    'plex.libraryMapping': {'server|1': 'movies'},
  },
  xtream: const [
    TransferredXtream(
      XtreamAccount(
        id: 'a1',
        name: 'Line',
        host: 'http://panel-host.example.invalid:8080',
        username: 'user',
        liveCategoryIds: ['1', '2'],
      ),
      'hunter2',
    ),
  ],
  smb: const [
    TransferredSmb(
      SmbShare(id: 's1', name: 'NAS', host: '<lan-ip>', username: 'me'),
      'pw',
    ),
  ],
  tmdbKey: 'tmdb-key',
  ai: const TransferredAi({'preset': 'openAi'}, 'sk-test'),
);

void main() {
  group('pairing code', () {
    final secret = Uint8List.fromList([for (var i = 1; i <= 10; i++) i * 17]);
    final info = PairingInfo(host: '192.168.1.20', port: 41234, secret: secret);

    test('is sixteen characters in four groups', () {
      expect(
        info.displayCode,
        matches(RegExp(r'^([0-9A-Z]{4}-){3}[0-9A-Z]{4}$')),
      );
    });

    test('survives the QR round trip', () {
      final back = PairingInfo.tryParse(info.uri)!;
      expect(back.host, '192.168.1.20');
      expect(back.port, 41234);
      expect(back.secret, secret);
    });

    test('reads what a person types, however they type it', () {
      for (final typed in [
        '192.168.1.20:41234 ${info.displayCode}',
        '192.168.1.20:41234  ${info.displayCode.toLowerCase()}',
        '${info.displayCode} 192.168.1.20:41234',
        '192.168.1.20 : 41234\n${info.displayCode.replaceAll('-', '')}',
      ]) {
        final back = PairingInfo.tryParse(typed);
        expect(back, isNotNull, reason: typed);
        expect(back!.secret, secret, reason: typed);
        expect(back.port, 41234, reason: typed);
      }
    });

    test('reads the look-alikes of a character as that character', () {
      // 0/O and 1/I/L are the three people mistype off a TV.
      final zeros = PairingInfo(
        host: '10.0.0.5',
        port: 9,
        secret: Uint8List(10),
      );
      expect(zeros.displayCode, '0000-0000-0000-0000');
      final back = PairingInfo.tryParse('10.0.0.5:9 OOOO-oooo-OOOO-0000')!;
      expect(back.secret, Uint8List(10));
    });

    test('is not fooled into trusting a name or a bad port', () {
      final code = info.displayCode;
      expect(PairingInfo.tryParse('evil.example.invalid:80 $code'), isNull);
      expect(PairingInfo.tryParse('192.168.1.20:0 $code'), isNull);
      expect(PairingInfo.tryParse('192.168.1.20:70000 $code'), isNull);
      expect(PairingInfo.tryParse('300.1.1.1:80 $code'), isNull);
      expect(
        PairingInfo.tryParse(
          'subnext://pair?h=evil.example.invalid&p=80&k=${code.replaceAll('-', '')}',
        ),
        isNull,
      );
    });

    test('rejects a code of the wrong length or alphabet', () {
      expect(PairingInfo.tryParse('192.168.1.20:41234 ABCD-EFGH'), isNull);
      expect(
        PairingInfo.tryParse('192.168.1.20:41234 ABCD-EFGH-JKMN-PQRSU'),
        isNull,
      );
      expect(
        PairingInfo.tryParse('192.168.1.20:41234 ABCD-EFGH-JKMN-PQR!'),
        isNull,
      );
      expect(PairingInfo.tryParse(''), isNull);
      expect(PairingInfo.tryParse('https://example.invalid'), isNull);
    });

    test('a generated secret is 80 random bits', () {
      final a = PairingInfo.generate(host: '10.0.0.1', port: 1);
      final b = PairingInfo.generate(host: '10.0.0.1', port: 1);
      expect(a.secret.length, 10);
      expect(a.secret, isNot(b.secret));
      expect(
        PairingInfo.generate(
          host: '10.0.0.1',
          port: 1,
          random: Random(1),
        ).secret,
        PairingInfo.generate(
          host: '10.0.0.1',
          port: 1,
          random: Random(1),
        ).secret,
      );
    });
  });

  group('cipher', () {
    final secret = List<int>.generate(10, (i) => i + 1);

    test('opens what it sealed', () async {
      final cipher = TransferCipher(secret);
      final sealed = await cipher.seal(utf8.encode('hello'));
      expect(utf8.decode(await cipher.open(sealed)), 'hello');
    });

    test('does not leave the plaintext readable', () async {
      final sealed = await TransferCipher(secret)
          .seal(utf8.encode('a very recognisable password'));
      expect(
        utf8.decode(sealed, allowMalformed: true),
        isNot(contains('password')),
      );
    });

    test('seals the same message differently each time', () async {
      final cipher = TransferCipher(secret);
      final a = await cipher.seal(utf8.encode('same'));
      final b = await cipher.seal(utf8.encode('same'));
      expect(a, isNot(b));
    });

    test('a different secret cannot open it', () async {
      final sealed = await TransferCipher(secret).seal(utf8.encode('x'));
      await expectLater(
        TransferCipher([...secret]..[0] ^= 1).open(sealed),
        throwsA(isA<TransferAuthException>()),
      );
    });

    test('an altered message is refused', () async {
      final cipher = TransferCipher(secret);
      final sealed = await cipher.seal(utf8.encode('payload'));
      for (final i in [0, 13, sealed.length - 1]) {
        final tampered = Uint8List.fromList(sealed)..[i] ^= 1;
        await expectLater(
          cipher.open(tampered),
          throwsA(isA<TransferAuthException>()),
          reason: 'byte $i',
        );
      }
    });

    test('a truncated message is refused rather than crashing', () async {
      await expectLater(
        TransferCipher(secret).open([1, 2, 3]),
        throwsA(isA<TransferAuthException>()),
      );
    });
  });

  group('bundle', () {
    test('round trips everything, passwords included', () {
      final back = TransferBundle.decode(_bundle().encode());
      expect(back.items, TransferItem.values.toSet());
      expect(back.xtream.single.account.host, contains('panel-host'));
      expect(back.xtream.single.account.liveCategoryIds, ['1', '2']);
      expect(back.xtream.single.password, 'hunter2');
      expect(back.smb.single.password, 'pw');
      expect(back.tmdbKey, 'tmdb-key');
      expect(back.ai!.key, 'sk-test');
      expect(back.preferences['plex.libraryMapping'], {'server|1': 'movies'});
      expect(back.preferences['subtitles.on'], true);
    });

    test('only the keys on the allowlist are accepted', () {
      final raw = utf8.encode(
        jsonEncode({
          'format': 'subnext-transfer',
          'version': 1,
          'preferences': {
            'playback.skipSeconds': '30',
            // Each of these would bypass something the receiver must decide.
            'advancedSourcesEnabled': true,
            'onboardingSeen': true,
            'ai.consent': {'x': 'y'},
            'xtream.accounts': '[]',
            'ai.key': 'leak',
            // The right key with the wrong type.
            'subtitles.on': 'yes',
          },
        }),
      );
      final back = TransferBundle.decode(raw);
      expect(back.preferences.keys, ['playback.skipSeconds']);
    });

    test('refuses something that is not a bundle', () {
      for (final bad in ['not json', '[]', '{"format":"other","version":1}']) {
        expect(
          () => TransferBundle.decode(utf8.encode(bad)),
          throwsA(isA<TransferFormatException>()),
          reason: bad,
        );
      }
    });

    test('refuses a bundle from a newer app, and says to update', () {
      expect(
        () => TransferBundle.decode(
          utf8.encode('{"format":"subnext-transfer","version":99}'),
        ),
        throwsA(
          isA<TransferFormatException>().having(
            (e) => e.message,
            'message',
            contains('Update'),
          ),
        ),
      );
    });

    test('skips an entry it cannot read instead of failing the lot', () {
      final back = TransferBundle.decode(
        utf8.encode(
          jsonEncode({
            'format': 'subnext-transfer',
            'version': 1,
            'xtream': [
              {'account': 'junk'},
              {
                'account': {'id': 'ok', 'host': 'http://h', 'username': 'u'},
              },
            ],
          }),
        ),
      );
      expect(back.xtream.map((x) => x.account.id), ['ok']);
    });

    test('what the confirmation screen says never includes a secret', () {
      final b = _bundle();
      final text = [for (final i in b.items) b.describe(i)].join(' | ');
      for (final secret in [
        'hunter2',
        'user',
        'panel-host',
        'tmdb-key',
        'sk-test',
      ]) {
        expect(text, isNot(contains(secret)));
      }
      expect(b.describe(TransferItem.xtream), '1 account');
    });

    test('only() keeps what was ticked and nothing else', () {
      final cut = _bundle().only({TransferItem.smb, TransferItem.tmdb});
      expect(cut.items, {TransferItem.smb, TransferItem.tmdb});
      expect(cut.xtream, isEmpty);
      expect(cut.ai, isNull);
    });
  });

  group('LAN address', () {
    test('prefers Wi-Fi over a VPN that has a private address too', () {
      expect(
        pickLanAddress([
          (name: 'tun0', addresses: ['10.8.0.2']),
          (name: 'wlan0', addresses: ['192.168.1.20']),
        ]),
        '192.168.1.20',
      );
    });

    test('ignores cellular, bridges and public addresses', () {
      expect(
        pickLanAddress([
          (name: 'rmnet_data0', addresses: ['10.55.1.1']),
          (name: 'docker0', addresses: ['172.17.0.1']),
          (name: 'wlan0', addresses: ['203.0.113.7']),
        ]),
        isNull,
      );
    });

    test('does not mistake a Windows "Local Area Connection" for loopback', () {
      expect(
        pickLanAddress([
          (name: 'Local Area Connection', addresses: ['192.168.0.9']),
        ]),
        '192.168.0.9',
      );
    });

    test('takes a private address on an unfamiliar interface if it is all there is', () {
      expect(
        pickLanAddress([
          (name: 'usb0', addresses: ['192.168.42.129']),
        ]),
        '192.168.42.129',
      );
    });
  });

  group('server and client over a real socket', () {
    late TransferServer server;
    late PairingInfo pairing;

    Future<void> startServer([TransferServer? custom]) async {
      server = custom ?? TransferServer();
      pairing = await server.start(host: '127.0.0.1');
    }

    tearDown(() async => server.close());

    const client = TransferClient(
      connectTimeout: Duration(seconds: 3),
      decisionTimeout: Duration(seconds: 5),
    );

    test(
      'delivers a bundle, and the sender hears yes only after accept',
      () async {
        await startServer();

        var sendReturned = false;
        final sent = client.send(pairing, _bundle()).then((_) {
          sendReturned = true;
        });

        final incoming = (await server.incoming)!;
        expect(incoming.bundle.xtream.single.password, 'hunter2');

        // Received and understood, not yet agreed to: the sender is still waiting.
        await Future<void>.delayed(const Duration(milliseconds: 150));
        expect(sendReturned, isFalse);

        incoming.accept();
        await sent;
        expect(sendReturned, isTrue);
      },
    );

    test('a refusal reaches the sender as a refusal', () async {
      await startServer();
      final sent = client.send(pairing, _bundle());
      final expectation = expectLater(sent, throwsA(isA<TransferDeclined>()));
      (await server.incoming)!.decline();
      await expectation;
    });

    test(
      'a wrong code is refused and nothing is surfaced to the user',
      () async {
        await startServer();
        final wrong = PairingInfo(
          host: pairing.host,
          port: pairing.port,
          secret: Uint8List.fromList([...pairing.secret]..[0] ^= 1),
        );
        await expectLater(
          client.send(wrong, _bundle()),
          throwsA(
            isA<TransferException>().having(
              (e) => e.message,
              'message',
              contains('code was not right'),
            ),
          ),
        );
        var surfaced = false;
        unawaited(server.incoming.then((i) => surfaced = i != null));
        await Future<void>.delayed(const Duration(milliseconds: 100));
        expect(surfaced, isFalse);
      },
    );

    test('too many wrong codes close the listener', () async {
      await startServer(TransferServer(maxFailures: 3));
      final wrong = PairingInfo(
        host: pairing.host,
        port: pairing.port,
        secret: Uint8List(10),
      );
      for (var i = 0; i < 3; i++) {
        await expectLater(
          client.send(wrong, _bundle()),
          throwsA(isA<TransferException>()),
        );
      }
      expect(await server.incoming, isNull);
      // And the right code no longer gets in.
      await expectLater(
        client.send(pairing, _bundle()),
        throwsA(isA<TransferException>()),
      );
    });

    test('takes one bundle: a second sender is told it is busy', () async {
      await startServer();
      final first = client.send(pairing, _bundle());
      final incoming = (await server.incoming)!;

      await expectLater(
        client.send(pairing, _bundle()),
        throwsA(
          isA<TransferException>().having(
            (e) => e.message,
            'message',
            contains('already received'),
          ),
        ),
      );
      incoming.accept();
      await first;
    });

    test('closing while a sender waits gives it a no, not a hang', () async {
      await startServer();
      final sent = client.send(pairing, _bundle());
      final expectation = expectLater(sent, throwsA(isA<TransferDeclined>()));
      await server.incoming;
      await server.close();
      await expectation;
    });

    test('an oversized body is refused', () async {
      await startServer(TransferServer(maxBodyBytes: 1024));
      final big = TransferBundle(
        createdAt: DateTime.now(),
        tmdbKey: 'x' * 4096,
      );
      await expectLater(
        client.send(pairing, big),
        throwsA(
          isA<TransferException>().having(
            (e) => e.message,
            'message',
            contains('too much'),
          ),
        ),
      );
    });

    test('anything but POST /transfer is not found', () async {
      await startServer();
      final http = HttpClient();
      addTearDown(() => http.close(force: true));
      final get = await (await http.getUrl(
        Uri.parse('http://127.0.0.1:${pairing.port}/transfer'),
      )).close();
      expect(get.statusCode, 404);
      await get.drain<void>();
      final other = await (await http.postUrl(
        Uri.parse('http://127.0.0.1:${pairing.port}/elsewhere'),
      )).close();
      expect(other.statusCode, 404);
      await other.drain<void>();
    });

    test('a listener that nobody uses closes itself', () async {
      await startServer(
        TransferServer(lifetime: const Duration(milliseconds: 200)),
      );
      expect(await server.incoming, isNull);
      expect(server.isRunning, isFalse);
    });

    test('says where it could not reach', () async {
      await startServer();
      final port = pairing.port;
      await server.close();
      await expectLater(
        client.send(
          PairingInfo(host: '127.0.0.1', port: port, secret: pairing.secret),
          _bundle(),
        ),
        throwsA(
          isA<TransferException>().having(
            (e) => e.message,
            'message',
            contains('127.0.0.1:$port'),
          ),
        ),
      );
    });
  });

  group('the sender shows the code', () {
    late TransferOfferServer offer;
    late PairingInfo pairing;

    Future<void> startOffer([TransferOfferServer? custom]) async {
      offer = custom ?? TransferOfferServer();
      pairing = await offer.start(host: '127.0.0.1');
    }

    tearDown(() async => offer.close());

    const client = TransferClient(
      connectTimeout: Duration(seconds: 3),
      decisionTimeout: Duration(seconds: 5),
    );

    test('an approved request names where to push, taken from the connection', () async {
      await startOffer();
      final asked = client.requestPush(pairing, 40123);

      final request = (await offer.request)!;
      // The address is the one the request came from, not anything it claimed.
      expect(request.host, '127.0.0.1');
      expect(request.port, 40123);

      request.approve();
      await asked;
    });

    test('a refusal reaches the requester as a refusal', () async {
      await startOffer();
      final asked = client.requestPush(pairing, 40123);
      final expectation = expectLater(
        asked,
        throwsA(
          isA<TransferDeclined>().having(
            (e) => e.message,
            'message',
            contains('did not agree'),
          ),
        ),
      );
      (await offer.request)!.deny();
      await expectation;
    });

    test('a wrong code is refused and never reaches the person', () async {
      await startOffer();
      final wrong = PairingInfo(
        host: pairing.host,
        port: pairing.port,
        secret: Uint8List.fromList([...pairing.secret]..[3] ^= 1),
      );
      await expectLater(
        client.requestPush(wrong, 40123),
        throwsA(
          isA<TransferException>().having(
            (e) => e.message,
            'message',
            contains('code was not right'),
          ),
        ),
      );
      var surfaced = false;
      unawaited(offer.request.then((r) => surfaced = r != null));
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(surfaced, isFalse);
    });

    test('too many wrong codes close it', () async {
      await startOffer(TransferOfferServer(maxFailures: 3));
      final wrong = PairingInfo(
        host: pairing.host,
        port: pairing.port,
        secret: Uint8List(10),
      );
      for (var i = 0; i < 3; i++) {
        await expectLater(
          client.requestPush(wrong, 1),
          throwsA(isA<TransferException>()),
        );
      }
      expect(await offer.request, isNull);
      await expectLater(
        client.requestPush(pairing, 1),
        throwsA(isA<TransferException>()),
      );
    });

    test('answers one request; a second is told it is busy', () async {
      await startOffer();
      final first = client.requestPush(pairing, 40123);
      final request = (await offer.request)!;
      await expectLater(
        client.requestPush(pairing, 40124),
        throwsA(
          isA<TransferException>().having(
            (e) => e.message,
            'message',
            contains('already answering'),
          ),
        ),
      );
      request.approve();
      await first;
    });

    test('a port that is not a port is refused', () async {
      await startOffer();
      for (final bad in [0, 70000, -5]) {
        await expectLater(
          client.requestPush(pairing, bad),
          throwsA(
            isA<TransferException>().having(
              (e) => e.message,
              'message',
              contains('400'),
            ),
          ),
          reason: '$bad',
        );
      }
    });

    test(
      'closing while the person is deciding gives the requester a no',
      () async {
        await startOffer();
        final asked = client.requestPush(pairing, 40123);
        final expectation = expectLater(
          asked,
          throwsA(isA<TransferDeclined>()),
        );
        await offer.request;
        await offer.close();
        await expectation;
      },
    );

    test('an unused code closes itself', () async {
      await startOffer(
        TransferOfferServer(lifetime: const Duration(milliseconds: 200)),
      );
      expect(await offer.request, isNull);
      expect(offer.isRunning, isFalse);
    });

    test('only POST /callback is answered', () async {
      await startOffer();
      final http = HttpClient();
      addTearDown(() => http.close(force: true));
      final get = await (await http.getUrl(
        Uri.parse('http://127.0.0.1:${pairing.port}/callback'),
      )).close();
      expect(get.statusCode, 404);
      await get.drain<void>();
      // And not the receiving side's path: this is not a listener for bundles.
      final other = await (await http.postUrl(
        Uri.parse('http://127.0.0.1:${pairing.port}/transfer'),
      )).close();
      expect(other.statusCode, 404);
      await other.drain<void>();
    });

    test('a receiver can listen under the scanned secret', () async {
      await startOffer();
      final receiving = TransferServer();
      addTearDown(receiving.close);
      final listening = await receiving.start(
        host: '127.0.0.1',
        secret: pairing.secret,
      );
      expect(listening.secret, pairing.secret);
      expect(listening.port, isNot(pairing.port));
    });

    test('end to end: request, approval, push, review, saved', () async {
      await startOffer();

      // The phone scanned the TV's code: it listens under that secret...
      final receiving = TransferServer();
      addTearDown(receiving.close);
      final listening = await receiving.start(
        host: '127.0.0.1',
        secret: pairing.secret,
      );

      // ...and asks the TV to send.
      final asked = client.requestPush(pairing, listening.port);
      final request = (await offer.request)!;
      request.approve();
      await asked;

      // The TV pushes the way any sender does, to where the request came from.
      var delivered = false;
      final pushed = client
          .send(
            PairingInfo(
              host: request.host,
              port: request.port,
              secret: pairing.secret,
            ),
            _bundle(),
          )
          .then((_) => delivered = true);

      final incoming = (await receiving.incoming)!;
      expect(incoming.bundle.xtream.single.password, 'hunter2');
      // Still waiting on the person at the receiving end.
      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(delivered, isFalse);

      incoming.accept();
      await pushed;
      expect(delivered, isTrue);
    });
  });
}
