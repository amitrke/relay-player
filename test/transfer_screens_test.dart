import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:relay_player/core/theme/relay_theme.dart';
import 'package:relay_player/core/theme/relay_tokens.dart';
import 'package:relay_player/data/transfer/pairing.dart';
import 'package:relay_player/data/transfer/transfer_bundle.dart';
import 'package:relay_player/data/transfer/transfer_client.dart';
import 'package:relay_player/data/transfer/transfer_server.dart';
import 'package:relay_player/data/xtream/xtream_account_store.dart';
import 'package:relay_player/features/transfer/receive_screen.dart';
import 'package:relay_player/features/transfer/send_screen.dart';
import 'package:relay_player/features/transfer/transfer_service.dart';

/// Placeholder hosts and credentials only, per the no-provider rule in
/// CLAUDE.md.
const _host = 'http://panel-host.example.invalid:8080';

TransferBundle _bundle() => TransferBundle(
  createdAt: DateTime.utc(2026, 10, 9),
  xtream: const [
    TransferredXtream(
      XtreamAccount(id: 'a1', name: 'Line', host: _host, username: 'user'),
      'hunter2',
    ),
  ],
  tmdbKey: 'tmdb-key',
);

class _Service extends TransferService {
  _Service(super.ref, {this.collected, this.failApply = false});

  final CollectedSettings? collected;
  final bool failApply;
  TransferBundle? applied;

  @override
  Future<CollectedSettings> collect() async => collected!;

  @override
  Future<ApplyResult> apply(TransferBundle bundle) async {
    if (failApply) throw const TransferApplyException('Could not save: nope.');
    applied = bundle;
    return const ApplyResult(['A note for the person.']);
  }
}

class _Client extends TransferClient {
  _Client({this.error});

  final TransferException? error;
  PairingInfo? pairing;
  TransferBundle? sent;

  @override
  Future<void> send(PairingInfo pairing, TransferBundle bundle) async {
    this.pairing = pairing;
    sent = bundle;
    if (error != null) throw error!;
  }
}

/// How a send that is running in the background turned out.
class _Sending {
  bool done = false;
  Object? error;
}

/// Starts a real send on the real event loop and returns without waiting for
/// it. Awaiting inside `runAsync` would hold that zone open while the receiver
/// waits for a tap, and the tap needs the same zone to settle.
Future<_Sending> _startSend(
  WidgetTester tester,
  PairingInfo pairing,
) async {
  final result = _Sending();
  await tester.runAsync(() async {
    unawaited(
      const TransferClient()
          .send(pairing, _bundle())
          .then(
            (_) => result.done = true,
            onError: (Object e) {
              result.error = e;
              result.done = true;
            },
          ),
    );
  });
  return result;
}

Widget _app(Widget screen, {List<Override> overrides = const []}) =>
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        home: RelayTheme(
          tokens: RelayPalettes.midnight,
          palette: RelayPalette.midnight,
          child: screen,
        ),
      ),
    );

void main() {
  setUp(() {
    // The test binding swaps in a client that answers every request with 400.
    HttpOverrides.global = null;
  });

  group('receive', () {
    // Made when the provider is first read, which is on the first save.
    _Service? service;

    Future<void> pump(
      WidgetTester tester,
      TransferServer server, {
      bool failApply = false,
    }) async {
      tester.view.physicalSize = const Size(390, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _app(
          ReceiveScreen(server: server, findAddress: () async => '127.0.0.1'),
          overrides: [
            transferServiceProvider.overrideWith(
              (ref) => service = _Service(ref, failApply: failApply),
            ),
          ],
        ),
      );
      await tester.pump();
      await tester.pump();
    }

    /// What a person reads off the screen to type on the other device.
    PairingInfo shown(WidgetTester tester) {
      String text(Finder f) => tester.widget<Text>(f.first).data!;
      final address = text(find.textContaining('127.0.0.1:'));
      final code = text(find.textContaining(RegExp(r'^[0-9A-Z]{4}(-[0-9A-Z]{4}){3}$')));
      return PairingInfo.tryParse('$address $code')!;
    }

    /// Lets real socket work happen inside a widget test.
    Future<void> settle(WidgetTester tester) async {
      for (var i = 0; i < 10; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 30)),
        );
        await tester.pump();
      }
    }

    testWidgets('shows the code and the address, and waits', (tester) async {
      final server = TransferServer();
      await tester.runAsync(() async => pump(tester, server));
      await settle(tester);

      expect(find.text('Waiting for the other device…'), findsOneWidget);
      final p = shown(tester);
      expect(p.host, '127.0.0.1');
      expect(p.port, greaterThan(0));
      // Nothing to approve until something arrives.
      expect(find.text('Save these'), findsNothing);
      await tester.runAsync(server.close);
    });

    testWidgets('writes nothing until the person says yes, then tells the sender',
        (tester) async {
      final server = TransferServer();
      await tester.runAsync(() async => pump(tester, server));
      await settle(tester);
      final pairing = shown(tester);

      final sent = await _startSend(tester, pairing);
      await settle(tester);

      // What arrived is shown by name and count, never by its secrets.
      expect(find.textContaining('IPTV accounts · 1 account'), findsOneWidget);
      expect(find.textContaining('TMDB key'), findsOneWidget);
      for (final secret in ['hunter2', 'user', 'panel-host', 'tmdb-key']) {
        expect(find.textContaining(secret), findsNothing, reason: secret);
      }
      expect(service?.applied, isNull, reason: 'applied before the person agreed');
      // And the sender is still waiting, not told it went through.
      expect(sent.done, isFalse);

      await tester.tap(find.text('Save these'));
      await settle(tester);

      expect(sent.done, isTrue);
      expect(sent.error, isNull);

      expect(service!.applied!.xtream.single.password, 'hunter2');
      expect(find.textContaining('Your settings are on this device'), findsOneWidget);
      expect(find.text('A note for the person.'), findsOneWidget);
    });

    testWidgets('unticking a row keeps it out of what is saved', (tester) async {
      final server = TransferServer();
      await tester.runAsync(() async => pump(tester, server));
      await settle(tester);
      final sent = await _startSend(tester, shown(tester));
      await settle(tester);

      await tester.tap(find.textContaining('TMDB key'));
      await tester.pump();
      await tester.tap(find.text('Save these'));
      await settle(tester);

      expect(sent.error, isNull);

      expect(service!.applied!.tmdbKey, isNull);
      expect(service!.applied!.xtream, hasLength(1));
    });

    testWidgets('with everything unticked there is nothing to save', (tester) async {
      final server = TransferServer();
      await tester.runAsync(() async => pump(tester, server));
      await settle(tester);
      final sent = await _startSend(tester, shown(tester));
      await settle(tester);

      await tester.tap(find.textContaining('IPTV accounts'));
      await tester.tap(find.textContaining('TMDB key'));
      await tester.pump();

      final save = tester.widget<FilledButton>(
        find.ancestor(
          of: find.text('Save these'),
          matching: find.byType(FilledButton),
        ),
      );
      expect(save.onPressed, isNull);

      // Leaving without answering is a refusal as far as the sender knows.
      await tester.runAsync(server.close);
      await settle(tester);
      expect(sent.error, isA<TransferDeclined>());
    });

    testWidgets('a failed save is reported, and the sender is not told it worked',
        (tester) async {
      final server = TransferServer();
      await tester.runAsync(() async => pump(tester, server, failApply: true));
      await settle(tester);
      final pairing = shown(tester);

      final sent = await _startSend(tester, pairing);
      await settle(tester);

      await tester.tap(find.text('Save these'));
      await settle(tester);

      expect(find.text('Could not save: nope.'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
      expect(sent.error, isA<TransferDeclined>());
    });

    testWidgets('says so when the code runs out', (tester) async {
      final server = TransferServer(lifetime: const Duration(milliseconds: 100));
      await tester.runAsync(() async => pump(tester, server));
      await settle(tester);

      expect(find.textContaining('has expired'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });

    testWidgets('says so when there is no network to listen on', (tester) async {
      tester.view.physicalSize = const Size(390, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _app(ReceiveScreen(findAddress: () async => null)),
      );
      await tester.pump();
      await tester.pump();

      expect(find.textContaining('not on a Wi-Fi or Ethernet network'), findsOneWidget);
    });
  });

  group('send', () {
    Future<_Client> pump(
      WidgetTester tester, {
      TransferException? error,
      CollectedSettings? collected,
    }) async {
      tester.view.physicalSize = const Size(390, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final client = _Client(error: error);
      await tester.pumpWidget(
        _app(
          SendScreen(client: client, canScan: false),
          overrides: [
            transferServiceProvider.overrideWith(
              (ref) => _Service(
                ref,
                collected: collected ?? CollectedSettings(_bundle(), const []),
              ),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();
      return client;
    }

    Future<void> enter(WidgetTester tester, PairingInfo p) async {
      await tester.enterText(find.widgetWithText(TextField, 'Address'), p.address);
      await tester.enterText(find.widgetWithText(TextField, 'Code'), p.displayCode);
    }

    final pairing = PairingInfo.generate(host: '192.168.1.20', port: 41234);

    testWidgets('lists what there is, then sends only what is ticked', (tester) async {
      final client = await pump(tester);
      expect(find.textContaining('IPTV accounts · 1 account'), findsOneWidget);
      expect(find.textContaining('TMDB key'), findsOneWidget);

      await tester.tap(find.textContaining('TMDB key'));
      await tester.pump();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      await enter(tester, pairing);
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();

      expect(client.pairing!.address, '192.168.1.20:41234');
      expect(client.pairing!.secret, pairing.secret);
      expect(client.sent!.items, {TransferItem.xtream});
      expect(find.textContaining('Sent.'), findsOneWidget);
    });

    testWidgets('a mistyped code is explained and nothing is sent', (tester) async {
      final client = await pump(tester);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'Address'),
        '192.168.1.20:41234',
      );
      await tester.enterText(find.widgetWithText(TextField, 'Code'), 'ABCD-EFGH');
      await tester.tap(find.text('Send'));
      await tester.pump();

      expect(find.textContaining('Check the address'), findsOneWidget);
      expect(client.sent, isNull);
    });

    testWidgets('a refusal is shown and the code step can be tried again', (tester) async {
      await pump(tester, error: const TransferDeclined());
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await enter(tester, pairing);
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();

      expect(find.textContaining('did not accept'), findsOneWidget);
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextField, 'Code'), findsOneWidget);
    });

    testWidgets('with nothing set up it says so and offers no way on', (tester) async {
      await pump(
        tester,
        collected: CollectedSettings(
          TransferBundle(createdAt: DateTime.utc(2026, 10, 9)),
          const [],
        ),
      );
      expect(find.textContaining('nothing set up'), findsOneWidget);
      final next = tester.widget<FilledButton>(
        find.ancestor(of: find.text('Continue'), matching: find.byType(FilledButton)),
      );
      expect(next.onPressed, isNull);
    });

    testWidgets('explains what was left behind', (tester) async {
      await pump(
        tester,
        collected: CollectedSettings(_bundle(), const ['Your AI provider runs on this device.']),
      );
      expect(find.textContaining('AI provider runs on this device'), findsOneWidget);
    });
  });
}
