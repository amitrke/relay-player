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
import '../../features/onboarding/onboarding_route.dart';
import '../../features/settings/settings_controller.dart';
import '../../features/local_network/local_network_tab.dart';
import '../../features/local_network/saf_folder_screen.dart';
import '../../features/local_network/smb_screens.dart';
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
      final location = state.matchedLocation;

      // Hold on the splash until stored credentials have been read, so a
      // returning user never sees a flash of first-run.
      if (stage == PlexStage.restoring) return '/splash';

      // First run goes to onboarding (§12 screen 1) — **not** to Plex.
      // Plex is one source among several, and gating the whole app on it means
      // device video and a panel are both unreachable until you link a server
      // you may not even have.
      if (!ref.read(onboardingSeenProvider)) {
        return location == '/onboarding' || location == '/add-source'
            ? null
            : '/onboarding';
      }

      // Past first run, nothing is compulsory. Linking Plex returns to the
      // library; everything else is reachable with no sources at all.
      if (location == '/splash' || location == '/onboarding') return '/library';
      // Only covers `go('/link')` — a deep link, or a restored session that
      // lands here. It does **not** fire on the path users actually take:
      // `/link` is reached with `push` from `/add-source`, and go_router does
      // not re-run this redirect for a pushed route when `refreshListenable`
      // notifies (test/router_refresh_push_test.dart). PlexLinkScreen handles
      // `PlexStage.ready` itself for that reason — do not delete one believing
      // the other covers it.
      if (location == '/link' && stage == PlexStage.ready) return '/library';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (_, _) => const _Splash(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (_, _) => const OnboardingRoute(),
      ),
      GoRoute(
        path: '/add-source',
        builder: (_, _) => const AddSourceRoute(),
      ),
      GoRoute(
        path: '/link',
        builder: (_, _) => const PlexLinkScreen(),
      ),
      StatefulShellRoute(
        builder: (_, _, shell) => HomeShell(navigationShell: shell),
        // Not `.indexedStack` — its container keeps every branch's Focus
        // nodes alive under `Offstage`, which hides a branch from the eye but
        // not from the focus tree. A remote press after visiting Settings can
        // land back on a Sources chip nobody can see, and it reads as the
        // remote going dead rather than as misrouted (§11). The container
        // below is otherwise identical to the default.
        navigatorContainerBuilder: _tvSafeIndexedStack,
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
        path: '/local/:folderId',
        builder: (_, state) => LocalFolderScreen(
          folderId: state.pathParameters['folderId']!,
        ),
      ),
      GoRoute(
        path: '/smb/new',
        builder: (_, _) => const AddSmbScreen(),
      ),
      GoRoute(
        // Path travels as a query parameter rather than a path segment: an SMB
        // path contains slashes, and encoding them into a segment is the same
        // double-decode trap the SAF URIs fell into.
        path: '/smb/:shareId',
        builder: (_, state) => SmbBrowseScreen(
          shareId: state.pathParameters['shareId']!,
          path: state.uri.queryParameters['path'] ?? '',
        ),
      ),
      GoRoute(
        path: '/smbplay/:shareId',
        builder: (_, state) => PlayerScreen.smb(
          smbShareId: state.pathParameters['shareId']!,
          smbPath: state.uri.queryParameters['path'] ?? '',
        ),
      ),
      GoRoute(
        path: '/saf/:uri',
        // Not decoded again: go_router has already decoded the path parameter,
        // and a second pass collapses the %2F inside a SAF document id into a
        // real slash — which silently turns the file's URI into its parent
        // directory's. That surfaces as EISDIR when the bytes are read.
        builder: (_, state) => SafFolderScreen(
          uri: state.pathParameters['uri']!,
          title: state.extra as String?,
        ),
      ),
      GoRoute(
        path: '/safplay/:uri',
        builder: (_, state) {
          final extra = state.extra as (String, int)?;
          return PlayerScreen.saf(
            safUri: state.pathParameters['uri']!,
            name: extra?.$1,
            size: extra?.$2 ?? 0,
          );
        },
      ),
      GoRoute(
        path: '/localplay/:assetId',
        builder: (_, state) => PlayerScreen.device(
          assetId: state.pathParameters['assetId']!,
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

/// Same layout as `StatefulShellRoute.indexedStack`'s default container, plus
/// an explicit [ExcludeFocus] on every branch but the active one.
///
/// Measured cause of "go to Settings → Sources, then try to get back to a
/// Library poster" reading as a dead remote (§11): switching branches left
/// `_contentScope.focusedChild` (`relay_widgets.dart`) still pointing at
/// whatever was focused in Settings, and restoring that on the next hand-off
/// from the rail either lands on a control nobody can see or, once it can no
/// longer take focus, silently does nothing.
///
/// Flutter's own `IndexedStack` started wrapping non-selected children in
/// `ExcludeFocus` itself (framework commit 3955e2b1535, April 2026), which
/// would cover this on a current-enough SDK — but this package only pins
/// `sdk: ^3.13.0`, so a contributor's older-but-still-valid Flutter has no
/// such guarantee. Applying it explicitly here means the fix doesn't depend
/// on which Flutter release happens to be installed.
///
/// This alone is not sufficient — see the `canRequestFocus` guard in
/// `RelayFocusBoundary._enter`, which is what actually stops the hand-off
/// from silently failing once a node here is excluded.
Widget _tvSafeIndexedStack(
  BuildContext context,
  StatefulNavigationShell navigationShell,
  List<Widget> children,
) {
  final current = navigationShell.currentIndex;
  return IndexedStack(
    index: current,
    children: [
      for (final (i, child) in children.indexed)
        Offstage(
          offstage: i != current,
          child: TickerMode(
            enabled: i == current,
            child: ExcludeFocus(excluding: i != current, child: child),
          ),
        ),
    ],
  );
}

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
