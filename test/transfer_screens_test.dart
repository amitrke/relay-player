import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:relay_player/core/theme/relay_theme.dart';
import 'package:relay_player/core/theme/relay_tokens.dart';
import 'package:relay_player/data/transfer/pairing.dart';
import 'package:relay_player/data/transfer/transfer_bundle.dart';
import 'package:relay_player/data/transfer/transfer_client.dart';
import 'package:relay_player/data/transfer/transfer_offer.dart';
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

/// Stands in for the offer listener, so the Send screen's show-a-code mode can
/// be driven without a socket: [arrive] is a device scanning the code.
class _FakeOffer implements TransferOfferServer {
  _FakeOffer()
    : pairing = PairingInfo.generate(host: '192.168.1.5', port: 43210);

  final PairingInfo pairing;
  final _request = Completer<PushRequest?>();
  bool closed = false;

  void arrive(PushRequest? request) {
    if (!_request.isCompleted) _request.complete(request);
  }

  @override
  Future<PairingInfo> start({required String host}) async => pairing;

  @override
  Future<PushRequest?> get request => _request.future;

  @override
  Future<void> close() async {
    closed = true;
    if (!_request.isCompleted) _request.complete(null);
  }

  @override
  bool get isRunning => !closed;

  @override
  Duration get lifetime => const Duration(minutes: 5);

  @override
  Duration get decisionTimeout => const Duration(minutes: 3);

  @override
  int get maxFailures => 5;
}

/// Records the request to be sent to, as the receiver makes it when it has
/// scanned or typed the other device's code.
class _RefusingClient extends TransferClient {
  @override
  Future<void> requestPush(PairingInfo offer, int listenPort) async =>
      throw const TransferDeclined(
        'The other device did not agree to send its settings.',
      );
}

class _JoinClient extends TransferClient {
  PairingInfo? asked;
  int? listenPort;

  @override
  Future<void> requestPush(PairingInfo offer, int listenPort) async {
    asked = offer;
    this.listenPort = listenPort;
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
Future<_Sending> _startSend(WidgetTester tester, PairingInfo pairing) async {
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
        // In `builder`, as the app installs it: a dialog is built under the
        // Navigator, which a `home:` wrapper would not cover.
        builder: (context, child) => RelayTheme(
          tokens: RelayPalettes.midnight,
          palette: RelayPalette.midnight,
          child: child!,
        ),
        home: screen,
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
      TransferClient client = const TransferClient(),
      bool canScan = false,
    }) async {
      tester.view.physicalSize = const Size(390, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _app(
          ReceiveScreen(
            server: server,
            client: client,
            canScan: canScan,
            findAddress: () async => '127.0.0.1',
          ),
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
      final code = text(
        find.textContaining(RegExp(r'^[0-9A-Z]{4}(-[0-9A-Z]{4}){3}$')),
      );
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

    testWidgets(
      'writes nothing until the person says yes, then tells the sender',
      (tester) async {
        final server = TransferServer();
        await tester.runAsync(() async => pump(tester, server));
        await settle(tester);
        final pairing = shown(tester);

        final sent = await _startSend(tester, pairing);
        await settle(tester);

        // What arrived is shown by name and count, never by its secrets.
        expect(
          find.textContaining('IPTV accounts · 1 account'),
          findsOneWidget,
        );
        expect(find.textContaining('TMDB key'), findsOneWidget);
        for (final secret in ['hunter2', 'user', 'panel-host', 'tmdb-key']) {
          expect(find.textContaining(secret), findsNothing, reason: secret);
        }
        expect(
          service?.applied,
          isNull,
          reason: 'applied before the person agreed',
        );
        // And the sender is still waiting, not told it went through.
        expect(sent.done, isFalse);

        await tester.tap(find.text('Save these'));
        await settle(tester);

        expect(sent.done, isTrue);
        expect(sent.error, isNull);

        expect(service!.applied!.xtream.single.password, 'hunter2');
        expect(
          find.textContaining('Your settings are on this device'),
          findsOneWidget,
        );
        expect(find.text('A note for the person.'), findsOneWidget);
      },
    );

    testWidgets('unticking a row keeps it out of what is saved', (
      tester,
    ) async {
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

    testWidgets('with everything unticked there is nothing to save', (
      tester,
    ) async {
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

    testWidgets(
      'a failed save is reported, and the sender is not told it worked',
      (tester) async {
        final server = TransferServer();
        await tester.runAsync(
          () async => pump(tester, server, failApply: true),
        );
        await settle(tester);
        final pairing = shown(tester);

        final sent = await _startSend(tester, pairing);
        await settle(tester);

        await tester.tap(find.text('Save these'));
        await settle(tester);

        expect(find.text('Could not save: nope.'), findsOneWidget);
        expect(find.text('Try again'), findsOneWidget);
        expect(sent.error, isA<TransferDeclined>());
      },
    );

    testWidgets('says so when the code runs out', (tester) async {
      final server = TransferServer(
        lifetime: const Duration(milliseconds: 100),
      );
      await tester.runAsync(() async => pump(tester, server));
      await settle(tester);

      expect(find.textContaining('has expired'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });

    testWidgets('says so when there is no network to listen on', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _app(ReceiveScreen(findAddress: () async => null)),
      );
      await tester.pump();
      await tester.pump();

      expect(
        find.textContaining('not on a Wi-Fi or Ethernet network'),
        findsOneWidget,
      );
    });

    testWidgets('offers to scan the other device only when there is a camera', (
      tester,
    ) async {
      final a = TransferServer();
      await tester.runAsync(() async => pump(tester, a, canScan: true));
      await settle(tester);
      expect(find.text('Scan its code instead'), findsOneWidget);
      expect(find.text('Type its code instead'), findsOneWidget);
      await tester.runAsync(a.close);
    });

    testWidgets('with no camera it still offers typing the other code', (
      tester,
    ) async {
      final a = TransferServer();
      await tester.runAsync(() async => pump(tester, a));
      await settle(tester);
      expect(find.text('Scan its code instead'), findsNothing);
      expect(find.text('Type its code instead'), findsOneWidget);
      await tester.runAsync(a.close);
    });

    testWidgets(
      'joining the code the other device shows: listens under its secret, asks '
      'it to send, then reviews what arrives',
      (tester) async {
        final client = _JoinClient();
        final first = TransferServer();
        await tester.runAsync(() async => pump(tester, first, client: client));
        await settle(tester);

        await tester.tap(find.text('Type its code instead'));
        await settle(tester);
        // Its own code is gone, and nothing is listening for it.
        expect(first.isRunning, isFalse);

        final offer = PairingInfo.generate(host: '192.168.1.5', port: 43210);
        await tester.enterText(
          find.widgetWithText(TextField, 'Address'),
          offer.address,
        );
        await tester.enterText(
          find.widgetWithText(TextField, 'Code'),
          offer.displayCode,
        );
        await tester.tap(find.text('Connect'));
        await settle(tester);

        expect(client.asked!.secret, offer.secret);
        expect(client.listenPort, greaterThan(0));
        expect(
          find.textContaining('Waiting for the other device to send'),
          findsOneWidget,
        );

        // Someone without the code cannot push into the listener.
        final stranger = await _startSend(
          tester,
          PairingInfo(
            host: '127.0.0.1',
            port: client.listenPort!,
            secret: PairingInfo.generate(host: '1.1.1.1', port: 1).secret,
          ),
        );
        await settle(tester);
        expect(stranger.error, isA<TransferException>());
        expect(find.text('Save these'), findsNothing);

        // The device that was scanned pushes, sealed with the shared secret.
        final sent = await _startSend(
          tester,
          PairingInfo(
            host: '127.0.0.1',
            port: client.listenPort!,
            secret: offer.secret,
          ),
        );
        await settle(tester);
        expect(
          find.textContaining('IPTV accounts · 1 account'),
          findsOneWidget,
        );
        expect(sent.done, isFalse, reason: 'not yet said yes');

        await tester.tap(find.text('Save these'));
        await settle(tester);
        expect(sent.error, isNull);
        expect(sent.done, isTrue);
        expect(service!.applied!.xtream.single.password, 'hunter2');
      },
    );

    testWidgets('a refusal from the other device is explained', (tester) async {
      final client = _RefusingClient();
      final first = TransferServer();
      await tester.runAsync(() async => pump(tester, first, client: client));
      await settle(tester);
      await tester.tap(find.text('Type its code instead'));
      await settle(tester);

      final offer = PairingInfo.generate(host: '192.168.1.5', port: 43210);
      await tester.enterText(
        find.widgetWithText(TextField, 'Address'),
        offer.address,
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Code'),
        offer.displayCode,
      );
      await tester.tap(find.text('Connect'));
      await settle(tester);

      expect(find.textContaining('did not agree to send'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });

    testWidgets('Show my code instead brings its own code back', (
      tester,
    ) async {
      final first = TransferServer();
      await tester.runAsync(() async => pump(tester, first));
      await settle(tester);
      final before = shown(tester);

      await tester.tap(find.text('Type its code instead'));
      await settle(tester);
      await tester.tap(find.text('Show my code instead'));
      await settle(tester);

      // A fresh code, not the old one: that listener was closed.
      expect(find.text('Waiting for the other device…'), findsOneWidget);
      expect(shown(tester).secret, isNot(before.secret));
    });
  });

  group('send', () {
    /// Every offer listener the screen has started, in order.
    final offers = <_FakeOffer>[];

    setUp(offers.clear);

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
          SendScreen(
            client: client,
            canScan: false,
            findAddress: () async => '192.168.1.5',
            makeOfferServer: () {
              final offer = _FakeOffer();
              offers.add(offer);
              return offer;
            },
          ),
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

    /// Past the checklist and on to typing. A device with no camera starts by
    /// showing a code, so this switches. The show step has a spinner that never
    /// settles, hence pumps and not pumpAndSettle until the typing step.
    Future<void> toTyping(WidgetTester tester) async {
      await tester.tap(find.text('Continue'));
      await tester.pump();
      await tester.pump();
      await tester.tap(find.text('Type the code instead'));
      await tester.pumpAndSettle();
    }

    Future<void> toShowing(WidgetTester tester) async {
      await tester.tap(find.text('Continue'));
      await tester.pump();
      await tester.pump();
    }

    Future<void> enter(WidgetTester tester, PairingInfo p) async {
      await tester.enterText(
        find.widgetWithText(TextField, 'Address'),
        p.address,
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Code'),
        p.displayCode,
      );
    }

    final pairing = PairingInfo.generate(host: '192.168.1.20', port: 41234);

    testWidgets('lists what there is, then sends only what is ticked', (
      tester,
    ) async {
      final client = await pump(tester);
      expect(find.textContaining('IPTV accounts · 1 account'), findsOneWidget);
      expect(find.textContaining('TMDB key'), findsOneWidget);

      await tester.tap(find.textContaining('TMDB key'));
      await tester.pump();
      await toTyping(tester);

      await enter(tester, pairing);
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();

      expect(client.pairing!.address, '192.168.1.20:41234');
      expect(client.pairing!.secret, pairing.secret);
      expect(client.sent!.items, {TransferItem.xtream});
      expect(find.textContaining('Sent.'), findsOneWidget);
    });

    testWidgets('a remote can walk Address, Code and Send with Up and Down', (
      tester,
    ) async {
      await pump(tester);
      await toTyping(tester);

      FocusNode? focused() => FocusManager.instance.primaryFocus;
      bool inField(String label) {
        final field = find.widgetWithText(TextField, label);
        return field.evaluate().isNotEmpty &&
            focused()?.context?.findAncestorWidgetOfExactType<TextField>() ==
                tester.widget<TextField>(field);
      }

      // Arriving on this step, focus is already in Address: the button that held
      // it is gone, and with nothing focused a remote does nothing.
      await tester.pump();
      expect(inField('Address'), isTrue, reason: 'focus on arrival');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(inField('Code'), isTrue, reason: 'Down from Address');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(
        inField('Code'),
        isFalse,
        reason: 'Down from Code leaves the field',
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(inField('Code'), isTrue, reason: 'Up returns to Code');
    });

    testWidgets('the keyboard action key sends from the last field', (
      tester,
    ) async {
      final client = await pump(tester);
      await toTyping(tester);

      final address = tester.widget<TextField>(
        find.widgetWithText(TextField, 'Address'),
      );
      final code = tester.widget<TextField>(
        find.widgetWithText(TextField, 'Code'),
      );
      expect(address.textInputAction, TextInputAction.next);
      expect(code.textInputAction, TextInputAction.done);

      await enter(tester, pairing);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(client.pairing!.address, '192.168.1.20:41234');
    });

    testWidgets('a mistyped code is explained and nothing is sent', (
      tester,
    ) async {
      final client = await pump(tester);
      await toTyping(tester);

      await tester.enterText(
        find.widgetWithText(TextField, 'Address'),
        '192.168.1.20:41234',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Code'),
        'ABCD-EFGH',
      );
      await tester.tap(find.text('Send'));
      await tester.pump();

      expect(find.textContaining('Check the address'), findsOneWidget);
      expect(client.sent, isNull);
    });

    testWidgets('a refusal is shown and the code step can be tried again', (
      tester,
    ) async {
      await pump(tester, error: const TransferDeclined());
      await toTyping(tester);
      await enter(tester, pairing);
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();

      expect(find.textContaining('did not accept'), findsOneWidget);
      // Try again goes back to where a device with no camera starts: its own code.
      await tester.tap(find.text('Try again'));
      await tester.pump();
      await tester.pump();
      expect(find.text('Waiting for the other device…'), findsOneWidget);
    });

    testWidgets('with nothing set up it says so and offers no way on', (
      tester,
    ) async {
      await pump(
        tester,
        collected: CollectedSettings(
          TransferBundle(createdAt: DateTime.utc(2026, 10, 9)),
          const [],
        ),
      );
      expect(find.textContaining('nothing set up'), findsOneWidget);
      final next = tester.widget<FilledButton>(
        find.ancestor(
          of: find.text('Continue'),
          matching: find.byType(FilledButton),
        ),
      );
      expect(next.onPressed, isNull);
    });

    testWidgets('explains what was left behind', (tester) async {
      await pump(
        tester,
        collected: CollectedSettings(_bundle(), const [
          'Your AI provider runs on this device.',
        ]),
      );
      expect(
        find.textContaining('AI provider runs on this device'),
        findsOneWidget,
      );
    });

    group('showing a code, for a device with no camera', () {
      testWidgets('starts by showing a code, not asking for one to be typed', (
        tester,
      ) async {
        await pump(tester);
        await toShowing(tester);

        expect(offers, hasLength(1));
        expect(find.text(offers.single.pairing.displayCode), findsOneWidget);
        expect(find.text('192.168.1.5:43210'), findsOneWidget);
        expect(find.text('Waiting for the other device…'), findsOneWidget);
        expect(find.byType(TextField), findsNothing);
      });

      testWidgets(
        'asks before sending, then sends where the request came from',
        (tester) async {
          final client = await pump(tester);
          await toShowing(tester);

          final request = PushRequest.forTesting('192.168.1.50', 40555);
          offers.single.arrive(request);
          await tester.pump();
          await tester.pump();

          // Who is asking and what would go; nothing yet.
          expect(find.text('Send to 192.168.1.50?'), findsOneWidget);
          expect(
            find.textContaining('IPTV accounts, 1 account'),
            findsOneWidget,
          );
          expect(find.textContaining('TMDB key'), findsWidgets);
          expect(client.sent, isNull);

          // The safe answer holds focus, so a stray press on a remote refuses.
          final notNow = tester.widget<TextButton>(
            find.widgetWithText(TextButton, 'Not now'),
          );
          expect(notNow.autofocus, isTrue);

          await tester.tap(find.widgetWithText(FilledButton, 'Send'));
          await tester.pumpAndSettle();

          expect(await request.answer, isTrue);
          // Pushed to the address the request came from, under the code shown.
          expect(client.pairing!.host, '192.168.1.50');
          expect(client.pairing!.port, 40555);
          expect(client.pairing!.secret, offers.single.pairing.secret);
          expect(find.textContaining('Sent.'), findsOneWidget);
        },
      );

      testWidgets('only what was ticked is offered and sent', (tester) async {
        final client = await pump(tester);
        await tester.tap(find.textContaining('TMDB key'));
        await tester.pump();
        await toShowing(tester);

        offers.single.arrive(PushRequest.forTesting('192.168.1.50', 40555));
        await tester.pump();
        await tester.pump();
        expect(find.textContaining('TMDB key'), findsNothing);

        await tester.tap(find.widgetWithText(FilledButton, 'Send'));
        await tester.pumpAndSettle();
        expect(client.sent!.items, {TransferItem.xtream});
      });

      testWidgets('Not now refuses, sends nothing, and shows a fresh code', (
        tester,
      ) async {
        final client = await pump(tester);
        await toShowing(tester);
        final request = PushRequest.forTesting('192.168.1.50', 40555);
        offers.single.arrive(request);
        await tester.pump();
        await tester.pump();

        await tester.tap(find.text('Not now'));
        await tester.pump();
        await tester.pump();

        expect(await request.answer, isFalse);
        expect(client.sent, isNull);
        // The old code answered once and is spent: a new listener, a new code.
        expect(offers, hasLength(2));
        expect(offers.first.closed, isTrue);
        expect(find.text(offers.last.pairing.displayCode), findsOneWidget);
        expect(offers.last.pairing.secret, isNot(offers.first.pairing.secret));
      });

      testWidgets('a code that runs out says so', (tester) async {
        await pump(tester);
        await toShowing(tester);
        offers.single.arrive(null);
        await tester.pump();
        await tester.pump();

        expect(find.textContaining('has expired'), findsOneWidget);
        expect(find.text('Try again'), findsOneWidget);
      });

      testWidgets('switching to typing withdraws the code', (tester) async {
        await pump(tester);
        await toShowing(tester);
        expect(offers.single.closed, isFalse);

        await tester.tap(find.text('Type the code instead'));
        await tester.pumpAndSettle();

        expect(offers.single.closed, isTrue);
        expect(find.widgetWithText(TextField, 'Address'), findsOneWidget);
      });

      testWidgets('leaving the screen withdraws the code', (tester) async {
        await pump(tester);
        await toShowing(tester);

        await tester.pumpWidget(const SizedBox());
        expect(offers.single.closed, isTrue);
      });

      testWidgets('no network says so instead of showing a dead code', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(390, 1400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          _app(
            SendScreen(
              canScan: false,
              findAddress: () async => null,
              makeOfferServer: () => _FakeOffer(),
            ),
            overrides: [
              transferServiceProvider.overrideWith(
                (ref) => _Service(
                  ref,
                  collected: CollectedSettings(_bundle(), const []),
                ),
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Continue'));
        await tester.pump();
        await tester.pump();

        expect(
          find.textContaining('not on a Wi-Fi or Ethernet'),
          findsOneWidget,
        );
      });
    });
  });
}
