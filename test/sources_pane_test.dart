import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:relay_player/core/theme/relay_theme.dart';
import 'package:relay_player/core/theme/relay_tokens.dart';
import 'package:relay_player/features/accounts/media_servers.dart';
import 'package:relay_player/features/accounts/plex_session.dart';
import 'package:relay_player/features/settings/settings_controller.dart';
import 'package:relay_player/features/settings/sources_pane.dart';

/// Until 2026-10-16 Add source was reachable only from first run and from an
/// empty library tab, so a library Plex had filled offered no way to add
/// Jellyfin, Emby, a share or a panel. Settings, Sources is the way in now.
void main() {
  testWidgets('Settings, Sources opens Add source', (tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) =>
              const Scaffold(body: SingleChildScrollView(child: SourcesPane())),
        ),
        GoRoute(
          path: '/add-source',
          builder: (_, _) => const Text('add source screen'),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          plexSessionProvider.overrideWith(_SignedOut.new),
          connectedServersProvider.overrideWithValue(const []),
          localNetworkTabProvider.overrideWith(_LocalTab.new),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          builder: (_, child) => RelayTheme(
            tokens: RelayPalettes.midnight,
            palette: RelayPalette.midnight,
            child: child!,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add a source'));
    await tester.pumpAndSettle();
    expect(find.text('add source screen'), findsOneWidget);
  });
}

class _SignedOut extends PlexSessionController {
  @override
  PlexState build() => const PlexState(stage: PlexStage.signedOut);
}

class _LocalTab extends LocalNetworkTabController {
  @override
  bool build() => false;
}
