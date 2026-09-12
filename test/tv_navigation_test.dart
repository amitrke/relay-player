import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relay_player/core/platform/device_kind.dart';
import 'package:relay_player/core/theme/relay_theme.dart';
import 'package:relay_player/core/theme/relay_tokens.dart';
import 'package:relay_player/core/theme/relay_widgets.dart';

/// Guards the two defects that made the app unusable with a TV remote.
///
/// Both were invisible from the code reading correctly — the tv layout branch
/// existed and looked fine, and every tap target worked under a finger. They
/// only showed up on real hardware, so they are worth pinning.
void main() {
  Widget wrap(Widget child, {Size size = const Size(960, 540)}) {
    return MediaQuery(
      data: MediaQueryData(size: size),
      child: RelayTheme(
        tokens: RelayPalettes.midnight,
        palette: RelayPalette.midnight,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: child,
        ),
      ),
    );
  }

  group('form factor', () {
    tearDown(() => DeviceKind.debugSetTelevision(false));

    testWidgets('a television gets the tv layout at a TV\'s real size',
        (tester) async {
      DeviceKind.debugSetTelevision(true);

      late RelayFormFactor seen;
      // 960x540 dp is what a 1080p panel actually reports: 1920 px at 320 dpi.
      await tester.pumpWidget(wrap(Builder(builder: (context) {
        seen = RelayLayout.of(context);
        return const SizedBox();
      })));

      expect(seen, RelayFormFactor.tv);
    });

    testWidgets('the same size without the platform signal is a tablet',
        (tester) async {
      DeviceKind.debugSetTelevision(false);

      late RelayFormFactor seen;
      await tester.pumpWidget(wrap(Builder(builder: (context) {
        seen = RelayLayout.of(context);
        return const SizedBox();
      })));

      // The point of the test above: size cannot distinguish a TV from a
      // tablet, which is why the old `width >= 1800` check could never fire.
      expect(seen, RelayFormFactor.tablet);
    });
  });

  group('remote reachability', () {
    testWidgets('RelayTappable can take focus and activate from a key',
        (tester) async {
      var taps = 0;
      final node = FocusNode();
      addTearDown(node.dispose);

      await tester.pumpWidget(wrap(RelayTappable(
        focusNode: node,
        onTap: () => taps++,
        child: const Text('poster'),
      )));

      node.requestFocus();
      await tester.pump();
      expect(node.hasFocus, isTrue,
          reason: 'a D-pad cannot reach anything that cannot hold focus');

      // The centre button on a remote, which is what "select" is.
      await tester.sendKeyEvent(LogicalKeyboardKey.select);
      await tester.pump();
      expect(taps, 1);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(taps, 2);
    });

    testWidgets('a GestureDetector cannot — the bug this replaced',
        (tester) async {
      // Pinned so the difference is on the record: swapping RelayTappable back
      // for a GestureDetector does not fail a build or a lint, it silently
      // removes the widget from D-pad traversal.
      await tester.pumpWidget(wrap(
        GestureDetector(onTap: () {}, child: const Text('poster')),
      ));

      expect(
        find.descendant(
          of: find.byType(GestureDetector),
          matching: find.byType(Focus),
        ),
        findsNothing,
      );
    });
  });

  group('rail boundary', () {
    // The rail sits outside the branch Navigator, exactly as it does in
    // HomeShell. That nesting is the whole point: it is what makes the rail
    // unreachable, and a flat test tree would not reproduce it.
    Widget shell({
      required FocusScopeNode railScope,
      required FocusScopeNode contentScope,
      required FocusNode rail,
      required FocusNode content,
      required bool withBoundary,
    }) {
      final row = Row(
        children: [
          SizedBox(
            width: 120,
            child: FocusScope(
              node: railScope,
              child: RelayTappable(
                focusNode: rail,
                onTap: () {},
                child: const Text('Settings'),
              ),
            ),
          ),
          Expanded(
            child: FocusScope(
              node: contentScope,
              // A nested Navigator, which is what a go_router shell branch is.
              // Every route it builds installs a FocusScope of its own, and
              // that scope's edge is where directional traversal gives up.
              child: Navigator(
                onGenerateRoute: (_) => PageRouteBuilder<void>(
                  pageBuilder: (_, _, _) => Align(
                    alignment: Alignment.centerLeft,
                    child: RelayTappable(
                      focusNode: content,
                      onTap: () {},
                      child: const Text('poster'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );

      // MaterialApp for its default Shortcuts: without them an arrow key is
      // not a DirectionalFocusIntent at all, and the control below would pass
      // for the wrong reason.
      return MaterialApp(
        home: RelayTheme(
          tokens: RelayPalettes.midnight,
          palette: RelayPalette.midnight,
          child: withBoundary
              ? RelayFocusBoundary(
                  leading: railScope,
                  main: contentScope,
                  child: row,
                )
              : row,
        ),
      );
    }

    testWidgets('left from the page reaches the rail', (tester) async {
      final railScope = FocusScopeNode();
      final contentScope = FocusScopeNode();
      final rail = FocusNode();
      final content = FocusNode();
      addTearDown(() {
        railScope.dispose();
        contentScope.dispose();
        rail.dispose();
        content.dispose();
      });

      await tester.pumpWidget(shell(
        railScope: railScope,
        contentScope: contentScope,
        rail: rail,
        content: content,
        withBoundary: true,
      ));

      content.requestFocus();
      await tester.pump();
      expect(content.hasFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();

      expect(rail.hasFocus, isTrue,
          reason: 'Settings has to be reachable from the page by remote');
    });

    testWidgets('right from the rail returns to the page', (tester) async {
      final railScope = FocusScopeNode();
      final contentScope = FocusScopeNode();
      final rail = FocusNode();
      final content = FocusNode();
      addTearDown(() {
        railScope.dispose();
        contentScope.dispose();
        rail.dispose();
        content.dispose();
      });

      await tester.pumpWidget(shell(
        railScope: railScope,
        contentScope: contentScope,
        rail: rail,
        content: content,
        withBoundary: true,
      ));

      rail.requestFocus();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();

      expect(content.hasFocus, isTrue,
          reason: 'a viewer who opens the rail must be able to get back');
    });

    testWidgets('without the boundary it cannot — the bug this fixes',
        (tester) async {
      // Pinned because nothing about the plain tree looks wrong. Traversal
      // stops at the route scope's edge and the key falls through to the
      // scrollable, so the remote reads as dead rather than as misrouted.
      final railScope = FocusScopeNode();
      final contentScope = FocusScopeNode();
      final rail = FocusNode();
      final content = FocusNode();
      addTearDown(() {
        railScope.dispose();
        contentScope.dispose();
        rail.dispose();
        content.dispose();
      });

      await tester.pumpWidget(shell(
        railScope: railScope,
        contentScope: contentScope,
        rail: rail,
        content: content,
        withBoundary: false,
      ));

      content.requestFocus();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();

      expect(rail.hasFocus, isFalse);
      expect(content.hasFocus, isTrue, reason: 'focus did not move at all');
    });
  });

  group('branch focus leak', () {
    // `StatefulShellRoute.indexedStack` keeps every branch's Navigator
    // mounted so each tab remembers its own state — that part is correct and
    // wanted. Its default container only wraps an inactive branch in
    // `Offstage` + `TickerMode`, neither of which touches the focus tree, so
    // a focused node in a branch that just went offscreen keeps primary
    // focus. A remote press then either lands on nothing visible or silently
    // drives a control in the hidden branch — on real hardware this is what
    // "go to Settings → Sources, then try to get back to a Library poster"
    // showed: the D-pad reads as stuck (§11).
    //
    // Switching branches has to happen via `setState` on an already-mounted
    // widget, exactly as `HomeShell` does when `goBranch` changes
    // `navigationShell.currentIndex` — re-pumping a brand new `MaterialApp`
    // root for the "after" frame resets the route's own focus scope for
    // unrelated reasons and would pass or fail regardless of the fix.
    //
    // The container below is a plain `Stack`, not Flutter's `IndexedStack` —
    // as of framework commit 3955e2b1535 (April 2026) `IndexedStack` wraps its
    // own non-selected children in `ExcludeFocus`, which would make the
    // "without" case below pass for a reason that has nothing to do with
    // `_tvSafeIndexedStack` in `app_router.dart`. `Stack` has no such built-in
    // behaviour, so the comparison actually isolates what our code adds.
    Widget branch(int i, FocusNode node, {required bool excludeInactive, required int current}) {
      final child = RelayTappable(
          focusNode: node, onTap: () {}, child: Text('branch $i'));
      return Offstage(
        offstage: i != current,
        child: TickerMode(
          enabled: i == current,
          child: excludeInactive
              ? ExcludeFocus(excluding: i != current, child: child)
              : child,
        ),
      );
    }

    testWidgets(
        'without ExcludeFocus, switching branches leaves focus on the '
        'hidden one — the bug this replaced', (tester) async {
      final node0 = FocusNode();
      final node1 = FocusNode();
      final current = ValueNotifier(0);
      addTearDown(() {
        node0.dispose();
        node1.dispose();
        current.dispose();
      });

      await tester.pumpWidget(MaterialApp(
        home: RelayTheme(
          tokens: RelayPalettes.midnight,
          palette: RelayPalette.midnight,
          child: ValueListenableBuilder<int>(
            valueListenable: current,
            builder: (context, value, _) => Stack(children: [
              branch(0, node0, excludeInactive: false, current: value),
              branch(1, node1, excludeInactive: false, current: value),
            ]),
          ),
        ),
      ));
      node0.requestFocus();
      await tester.pump();
      expect(node0.hasFocus, isTrue);

      // The rail switching branches, not a key press: `goBranch` swaps which
      // child IndexedStack paints, same as picking Library from the app rail.
      current.value = 1;
      await tester.pump();

      expect(node0.hasFocus, isTrue,
          reason: 'Offstage does not release focus on its own');
    });

    testWidgets(
        'with ExcludeFocus, switching branches releases the hidden one',
        (tester) async {
      final node0 = FocusNode();
      final node1 = FocusNode();
      final current = ValueNotifier(0);
      addTearDown(() {
        node0.dispose();
        node1.dispose();
        current.dispose();
      });

      await tester.pumpWidget(MaterialApp(
        home: RelayTheme(
          tokens: RelayPalettes.midnight,
          palette: RelayPalette.midnight,
          child: ValueListenableBuilder<int>(
            valueListenable: current,
            builder: (context, value, _) => Stack(children: [
              branch(0, node0, excludeInactive: true, current: value),
              branch(1, node1, excludeInactive: true, current: value),
            ]),
          ),
        ),
      ));
      node0.requestFocus();
      await tester.pump();
      expect(node0.hasFocus, isTrue);

      current.value = 1;
      await tester.pump();

      expect(node0.hasFocus, isFalse,
          reason:
              'a hand-off from the rail must not land back on a branch that '
              'is no longer on screen');
    });

    testWidgets(
        'RelayFocusBoundary skips a remembered node that can no longer take '
        'focus, rather than silently doing nothing', (tester) async {
      // Reproduces the fuller chain: the boundary's `_enter` remembers
      // whichever branch child last held focus, and blindly calling
      // `requestFocus()` on it is a silent no-op once `ExcludeFocus` has
      // turned `canRequestFocus` off — which is exactly what going to
      // Settings → Sources and back to Library did on a real remote.
      final railScope = FocusScopeNode();
      final contentScope = FocusScopeNode();
      final rail = FocusNode();
      final node0 = FocusNode();
      final node1 = FocusNode();
      final current = ValueNotifier(0);
      addTearDown(() {
        railScope.dispose();
        contentScope.dispose();
        rail.dispose();
        node0.dispose();
        node1.dispose();
        current.dispose();
      });

      final row = Row(
        children: [
          SizedBox(
            width: 120,
            child: FocusScope(
              node: railScope,
              child: RelayTappable(
                  focusNode: rail, onTap: () {}, child: const Text('rail')),
            ),
          ),
          Expanded(
            child: FocusScope(
              node: contentScope,
              child: ValueListenableBuilder<int>(
                valueListenable: current,
                builder: (context, value, _) => Stack(children: [
                  branch(0, node0, excludeInactive: true, current: value),
                  branch(1, node1, excludeInactive: true, current: value),
                ]),
              ),
            ),
          ),
        ],
      );
      await tester.pumpWidget(MaterialApp(
        home: RelayTheme(
          tokens: RelayPalettes.midnight,
          palette: RelayPalette.midnight,
          child: RelayFocusBoundary(
              leading: railScope, main: contentScope, child: row),
        ),
      ));

      // Branch 0 focused, then the rail switches the shell to branch 1 —
      // exactly the sequence of picking Settings, focusing something there,
      // then picking Library again from the rail.
      node0.requestFocus();
      await tester.pump();
      current.value = 1;
      await tester.pump();

      rail.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();

      expect(node1.hasFocus, isTrue,
          reason: 'the rail must hand focus to the branch now on screen');
      expect(rail.hasFocus, isFalse,
          reason:
              'a no-op requestFocus on the stale node must not leave the '
              'remote stuck on the rail');
    });
  });
}
