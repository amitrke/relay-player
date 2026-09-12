import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Pins down a go_router behaviour the app has to work around: a
/// `refreshListenable` notification does **not** re-run the top-level
/// `redirect` for a route reached with `push`.
///
/// This matters because `app_router.dart` redirects away from `/link` once Plex
/// reports a connected server, and `/link` is only ever reached by `push` from
/// `/add-source`. That redirect therefore never fires on the path users
/// actually take, which is why a successful link left the user staring at a
/// second "Connect to Plex" button (issue #3) and why `PlexLinkScreen` handles
/// `PlexStage.ready` itself instead of trusting the router.
///
/// It asserts the current behaviour rather than the desired one. If a future
/// go_router starts redirecting pushed routes, this fails — which is the point:
/// the workaround can then be reconsidered rather than quietly kept forever.
void main() {
  testWidgets('a refresh does not redirect a pushed route', (tester) async {
    final refresh = ChangeNotifier();
    var connected = false;

    final router = GoRouter(
      initialLocation: '/home',
      refreshListenable: refresh,
      redirect: (context, state) {
        if (state.matchedLocation == '/link' && connected) return '/home';
        return null;
      },
      routes: [
        GoRoute(path: '/home', builder: (_, _) => const Text('home')),
        GoRoute(path: '/link', builder: (_, _) => const Text('link')),
      ],
    );
    addTearDown(router.dispose);
    addTearDown(refresh.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    expect(find.text('home'), findsOneWidget);

    // Exactly how the app gets to the Plex link screen.
    router.push('/link');
    await tester.pumpAndSettle();
    expect(find.text('link'), findsOneWidget);

    // The stage change the app's _SessionRefresh reports.
    connected = true;
    refresh.notifyListeners();
    await tester.pumpAndSettle();

    expect(
      router.state.matchedLocation,
      '/link',
      reason: 'go_router leaves a pushed route in place across a refresh',
    );
    expect(find.text('link'), findsOneWidget);
  });
}
