import 'package:dart_plex/dart_plex.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:relay_player/core/platform/device_kind.dart';
import 'package:relay_player/core/theme/relay_theme.dart';
import 'package:relay_player/core/theme/relay_tokens.dart';
import 'package:relay_player/data/plex/plex_service.dart';
import 'package:relay_player/data/plex/plex_session_store.dart';
import 'package:relay_player/features/accounts/plex_link_screen.dart';
import 'package:relay_player/features/accounts/plex_session.dart';

/// Guards the #5 link-screen fixes that a widget test can actually see.
///
/// What it cannot see is fit: `flutter test`'s fixed-width font wraps prose to
/// about twice its real height (§11), so whether the code, the waiting state
/// and a focusable control share one 960 × 540 screen is still a TV check.
/// This pins focus, grouping and ordering, which do not depend on the font.
class _FakeSession extends PlexSessionController {
  _FakeSession(this.initial);

  final PlexState initial;
  bool cancelled = false;

  @override
  PlexState build() => initial;

  @override
  void cancelLink() => cancelled = true;

  int codeStarts = 0;
  int browserStarts = 0;

  @override
  Future<void> startLink() async {
    codeStarts++;
    state = PlexState(
      stage: PlexStage.awaitingApproval,
      linkCode: PlexLinkCode(
        pinId: 2,
        code: 'WXYZ',
        expiresAt: DateTime.now().add(const Duration(minutes: 10)),
      ),
    );
  }

  @override
  Future<PlexLinkCode?> startBrowserLink() async {
    browserStarts++;
    final code = PlexLinkCode(
      pinId: 3,
      code: 'a-long-strong-pin-code-here',
      expiresAt: DateTime.now().add(const Duration(minutes: 10)),
      authUrl: PlexService.authPageFor(clientId: 'cid', code: 'long'),
    );
    state = PlexState(stage: PlexStage.awaitingApproval, linkCode: code);
    return code;
  }
}

PlexResource _server(String name, {bool owned = true, bool online = true}) =>
    PlexResource(
      name: name,
      clientIdentifier: 'id-$name',
      product: 'Plex Media Server',
      productVersion: '1',
      platform: 'Linux',
      owned: owned,
      home: false,
      synced: false,
      relay: false,
      presence: online,
      httpsRequired: false,
      accessToken: '<redacted>',
      provides: const ['server'],
      connections: const [],
    );

void main() {
  setUp(() => DeviceKind.debugSetTelevision(true));
  tearDown(() => DeviceKind.debugSetTelevision(false));

  Future<_FakeSession> pump(
    WidgetTester tester,
    PlexState state, {
    Size size = const Size(960, 540),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final fake = _FakeSession(state);
    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (_, _) => const PlexLinkScreen()),
    ]);
    await tester.pumpWidget(ProviderScope(
      overrides: [plexSessionProvider.overrideWith(() => fake)],
      child: RelayTheme(
        tokens: RelayPalettes.midnight,
        palette: RelayPalette.midnight,
        child: MaterialApp.router(routerConfig: router),
      ),
    ));
    await tester.pump();
    return fake;
  }

  testWidgets('waiting for approval puts focus on Cancel',
      (tester) async {
    final fake = await pump(
      tester,
      PlexState(
        stage: PlexStage.awaitingApproval,
        linkCode: PlexLinkCode(
          pinId: 1,
          code: 'ABCD',
          expiresAt: DateTime.now().add(const Duration(minutes: 10)),
        ),
      ),
    );

    expect(find.text('Waiting for approval…'), findsOneWidget);
    // A clipboard on a TV goes nowhere; the button is phone-only.
    expect(find.text('Copy code'), findsNothing);

    final focused = FocusManager.instance.primaryFocus;
    expect(
      focused?.context?.findAncestorWidgetOfExactType<TextButton>(),
      isNotNull,
      reason: 'focus must land on a control, not a widget that is gone',
    );
    await tester.tap(find.text('Cancel'));
    expect(fake.cancelled, isTrue);
  });

  PlexState awaiting() => PlexState(
    stage: PlexStage.awaitingApproval,
    linkCode: PlexLinkCode(
      pinId: 1,
      code: 'ABCD',
      expiresAt: DateTime.now().add(const Duration(minutes: 10)),
    ),
  );

  // User feedback 2026-11-12: plex.tv/link was hard to read on a phone.
  testWidgets('on a phone the link is bold and opens; failing that, says so',
      (tester) async {
    DeviceKind.debugSetTelevision(false);
    await pump(tester, awaiting(), size: const Size(390, 844));

    final link = tester.widget<Text>(find.text('plex.tv/link'));
    expect(link.style?.fontWeight, FontWeight.w700);
    expect(link.style?.decoration, TextDecoration.underline);
    // The sentence still reads around it.
    expect(find.textContaining('On any device, open', findRichText: true),
        findsOneWidget);

    // No browser in a test: the launch fails, and the person is told rather
    // than left tapping a link that does nothing.
    await tester.tap(find.text('plex.tv/link'));
    // The launch is a real platform call that fails here; let it finish.
    // Not pumpAndSettle: the waiting spinner never settles.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(
      find.text('Nothing on this device can open plex.tv/link. '
          'Open it on another device.'),
      findsOneWidget,
    );
  });

  testWidgets('on a TV the link is bold but not a control', (tester) async {
    await pump(tester, awaiting());
    final link = find.text('plex.tv/link');
    expect(tester.widget<Text>(link).style?.fontWeight, FontWeight.w700);
    expect(
      find.ancestor(of: link, matching: find.byType(GestureDetector)),
      findsNothing,
    );
  });

  // User feedback 2026-11-12: on a phone, reading plex.tv/link and typing
  // the code on the same small screen was the hard part of first run.
  test('the auth page carries the PIN in its fragment, spaces as %20', () {
    final url = PlexService.authPageFor(clientId: 'my id', code: 'abc123');
    expect(url.scheme, 'https');
    expect(url.host, 'app.plex.tv');
    expect(url.path, '/auth');
    expect(url.query, isEmpty, reason: 'nothing sent to a server as a query');
    expect(url.fragment, startsWith('?'));
    expect(url.fragment, contains('clientID=my%20id'));
    expect(url.fragment, contains('code=abc123'));
    expect(
      url.fragment,
      contains('context%5Bdevice%5D%5Bproduct%5D=Subnext%20Player'),
    );
  });

  testWidgets('a phone offers the browser sign-in first, a code second',
      (tester) async {
    DeviceKind.debugSetTelevision(false);
    final fake = await pump(
      tester,
      const PlexState(stage: PlexStage.signedOut),
      size: const Size(390, 844),
    );
    expect(find.text('Sign in with Plex'), findsOneWidget);
    await tester.tap(find.text('Use a code instead'));
    await tester.pump();
    expect(fake.codeStarts, 1);
    expect(find.text('WXYZ'), findsOneWidget);
  });

  testWidgets('with no browser, the sign-in falls back to a code and says so',
      (tester) async {
    DeviceKind.debugSetTelevision(false);
    final fake = await pump(
      tester,
      const PlexState(stage: PlexStage.signedOut),
      size: const Size(390, 844),
    );
    await tester.tap(find.text('Sign in with Plex'));
    // The launch is a real platform call that fails in a test.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(fake.browserStarts, 1);
    expect(fake.codeStarts, 1);
    expect(find.text('WXYZ'), findsOneWidget);
    expect(find.textContaining('Plex sign-in page'), findsOneWidget);
  });

  testWidgets('waiting on the browser shows how to finish, not the long PIN',
      (tester) async {
    DeviceKind.debugSetTelevision(false);
    final fake = await pump(
      tester,
      PlexState(
        stage: PlexStage.awaitingApproval,
        linkCode: PlexLinkCode(
          pinId: 3,
          code: 'a-long-strong-pin-code-here',
          expiresAt: DateTime.now().add(const Duration(minutes: 10)),
          authUrl: PlexService.authPageFor(clientId: 'cid', code: 'x'),
        ),
      ),
      size: const Size(390, 844),
    );
    expect(find.textContaining('come back to this app'), findsOneWidget);
    expect(find.text('a-long-strong-pin-code-here'), findsNothing);
    expect(find.text('Open Plex again'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    expect(fake.cancelled, isTrue);
  });

  testWidgets('a TV keeps the code: one Connect button, no browser option',
      (tester) async {
    await pump(tester, const PlexState(stage: PlexStage.signedOut));
    expect(find.text('Sign in with Plex'), findsNothing);
    expect(find.text('Use a code instead'), findsNothing);
    // The screen's title and the button.
    expect(find.text('Connect to Plex'), findsNWidgets(2));
  });

  testWidgets('the server picker groups, sorts, and skips connected servers',
      (tester) async {
    final connected = _server('delta');
    await pump(
      tester,
      PlexState(
        stage: PlexStage.choosingServer,
        available: [
          _server('charlie', owned: false),
          _server('bravo', online: false),
          connected,
          _server('alpha'),
        ],
        servers: [
          PlexConnection(
            stored: StoredPlexServer(
              id: connected.clientIdentifier,
              name: connected.name,
              baseUrl: 'http://<lan-ip>:32400',
              token: '<redacted>',
            ),
            service: PlexService(clientId: 'test'),
          ),
        ],
      ),
    );

    double y(String text) => tester.getTopLeft(find.text(text)).dy;

    expect(find.text('delta'), findsNothing,
        reason: 'already connected, so not a candidate');
    expect(y('YOUR SERVERS'), lessThan(y('alpha')));
    expect(y('alpha'), lessThan(y('bravo')),
        reason: 'online before offline within a group');
    expect(y('bravo'), lessThan(y('SHARED WITH YOU')));
    expect(y('SHARED WITH YOU'), lessThan(y('charlie')));
    expect(find.text('Offline'), findsOneWidget);
  });
}
