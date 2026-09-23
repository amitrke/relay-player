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

  Future<_FakeSession> pump(WidgetTester tester, PlexState state) async {
    tester.view.physicalSize = const Size(960, 540);
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
          ConnectedServer(
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
