import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/_debug/debug_menu_screen.dart';
import '../../features/_gallery/design_gallery.dart';
import '../../features/_spike/spike_app.dart';
import '../../features/accounts/plex_link_screen.dart';
import '../../features/advanced_sources/add_xtream_screen.dart';
import '../../features/advanced_sources/category_picker_screen.dart';
import '../../features/advanced_sources/xtream_series_screen.dart';
import '../../data/xtream/xtream_account_store.dart';
import '../../features/accounts/plex_session.dart';
import '../../features/home/home_shell.dart';
import '../../features/library/library_screen.dart';
import '../../features/player/player_screen.dart';
import '../../features/search/search_screen.dart';
import '../../features/series/show_detail_screen.dart';
import '../../features/settings/settings_route.dart';
import '../theme/theme_controller.dart';

/// Routes, with sign-in state as the only gate for now.
///
/// §2 picks go_router partly so gated routes can be kept out of the tree
/// entirely rather than hidden — the Advanced Sources gate (§8.2) will hang off
/// the same redirect once Phase 3 lands.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/library',
    refreshListenable: _SessionRefresh(ref),
    redirect: (context, state) {
      // Developer tools are reachable without a Plex link — they exist partly
      // to debug the link itself.
      if (kDebugMode && state.matchedLocation.startsWith('/debug')) return null;

      final stage = ref.read(plexSessionProvider).stage;
      final atLink = state.matchedLocation == '/link';

      return switch (stage) {
        // Hold on the splash until the stored token has been checked, so a
        // returning user never sees a flash of the sign-in screen.
        PlexStage.restoring => '/splash',
        PlexStage.ready => atLink || state.matchedLocation == '/splash'
            ? '/library'
            : null,
        _ => atLink ? null : '/link',
      };
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (_, _) => const _Splash(),
      ),
      GoRoute(
        path: '/link',
        builder: (_, _) => const PlexLinkScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => HomeShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/library',
              builder: (_, _) => const LibraryScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/search',
              builder: (_, _) => const SearchScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/settings',
              builder: (_, _) => const SettingsRoute(),
            ),
          ]),
        ],
      ),
      GoRoute(
        path: '/advanced/xtream/new',
        builder: (_, _) => const AddXtreamScreen(),
      ),
      GoRoute(
        path: '/advanced/xtream/:accountId/categories/:catalogue',
        builder: (_, state) => CategoryPickerScreen(
          accountId: state.pathParameters['accountId']!,
          catalogue: XtreamCatalogue.values.firstWhere(
            (c) => c.name == state.pathParameters['catalogue'],
            orElse: () => XtreamCatalogue.live,
          ),
        ),
      ),
      GoRoute(
        path: '/advanced/xtream/:accountId/series/:seriesId',
        builder: (_, state) => XtreamSeriesScreen(
          accountId: state.pathParameters['accountId']!,
          seriesId: state.pathParameters['seriesId']!,
        ),
      ),
      GoRoute(
        // The id carries the container extension, which is part of the URL §4
        // builds and is not recoverable from the panel afterwards.
        path: '/vod/:accountId/:streamId',
        builder: (_, state) => PlayerScreen.vod(
          accountId: state.pathParameters['accountId']!,
          streamId: state.pathParameters['streamId']!,
        ),
      ),
      GoRoute(
        path: '/episode/:accountId/:episodeId',
        builder: (_, state) => PlayerScreen.episode(
          accountId: state.pathParameters['accountId']!,
          streamId: state.pathParameters['episodeId']!,
        ),
      ),
      GoRoute(
        path: '/live/:accountId/:streamId',
        builder: (_, state) => PlayerScreen.live(
          accountId: state.pathParameters['accountId']!,
          streamId: state.pathParameters['streamId']!,
        ),
      ),
      GoRoute(
        path: '/show/:serverId/:ratingKey',
        builder: (_, state) => ShowDetailScreen(
          serverId: state.pathParameters['serverId']!,
          ratingKey: state.pathParameters['ratingKey']!,
        ),
      ),
      GoRoute(
        path: '/play/:serverId/:ratingKey',
        builder: (_, state) => PlayerScreen.plex(
          serverId: state.pathParameters['serverId']!,
          ratingKey: state.pathParameters['ratingKey']!,
        ),
      ),
      // Never registered in a release build, so neither screen can be reached
      // even by typing the route. `kDebugMode` is a compile-time constant, so
      // the branch and its widgets are tree-shaken out of the release binary.
      if (kDebugMode) ...[
        GoRoute(
          path: '/debug',
          builder: (_, _) => const DebugMenuScreen(),
        ),
        GoRoute(
          path: '/debug/spike',
          builder: (_, _) => const SpikeHome(),
        ),
        GoRoute(
          path: '/debug/gallery',
          builder: (_, _) => DesignGallery(
            controller: ref.read(themeControllerProvider),
          ),
        ),
      ],
    ],
  );
});

/// Bridges the Riverpod session into go_router's [Listenable] redirect trigger.
class _SessionRefresh extends ChangeNotifier {
  _SessionRefresh(Ref ref) {
    ref.listen(plexSessionProvider, (previous, next) {
      if (previous?.stage != next.stage) notifyListeners();
    });
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
