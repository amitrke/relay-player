import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relay_player/core/platform/device_kind.dart';
import 'package:relay_player/core/theme/relay_theme.dart';
import 'package:relay_player/core/theme/relay_tokens.dart';
import 'package:relay_player/core/theme/relay_widgets.dart';

/// Rules every screen must keep with a D-pad, checked by driving it.
///
/// Written 2026-09-28 after a Chromecast session found, one at a time, that
/// focus could not reach *Verify and add*: Done left nothing focused, Up and
/// Down could not leave a text field, and the button drew no ring when it
/// did have focus. None of that needed a device to find. Each was a rule a
/// test could state once for every screen, so this states them:
///
/// - **Something is focused after the first press.** A screen that opens
///   with nothing focused is fine only if one press lands somewhere.
/// - **Every stop is reachable.** Walking the arrow keys from wherever focus
///   starts reaches every focusable control on screen. A control only a finger
///   can reach is unusable from the sofa.
/// - **Focus is visible.** Whatever is focused shows it: inside a
///   [RelayFocusRing] that is lit, or a text field, which draws its own
///   focused border. Material's focus overlay does not count; the theme sets
///   no `focusColor`, so it draws nothing a viewer can see (architecture.md
///   §11).
/// - **Text fields can be left.** Up or Down from a field moves focus out of
///   it once the keyboard is closed (flutter/flutter#49335).
///
/// What this cannot see, and MANUAL_TESTING.md still covers: the on-screen
/// keyboard (absent in widget tests, where keys reach Flutter directly), the
/// Chromecast's own quirks, real network timing, and whether a ring is
/// legible at two metres rather than merely present.
///
/// Keys go straight into Flutter here, which is how a remote's keys arrive
/// once Android has passed them on. The Android side of that trip is what the
/// emulator runs recorded in architecture.md §11 cover.
class DpadAudit {
  DpadAudit(this.tester);

  final WidgetTester tester;

  static const arrows = [
    LogicalKeyboardKey.arrowUp,
    LogicalKeyboardKey.arrowDown,
    LogicalKeyboardKey.arrowLeft,
    LogicalKeyboardKey.arrowRight,
  ];

  /// Puts [screen] on a 1080p TV: 960x540 logical, as a real panel reports,
  /// with the platform saying it is a television (§11).
  static Future<void> pumpTv(
    WidgetTester tester,
    Widget screen, {
    List overrides = const [],
  }) async {
    DeviceKind.debugSetTelevision(true);
    addTearDown(() => DeviceKind.debugSetTelevision(false));
    tester.view.physicalSize = const Size(960, 540);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(ProviderScope(
      overrides: [...overrides],
      child: MaterialApp(
        home: RelayTheme(
          tokens: RelayPalettes.midnight,
          palette: RelayPalette.midnight,
          // Tabs such as Live TV normally sit inside the shell's Scaffold;
          // this stands in for it. A screen with its own Scaffold is unaffected.
          child: Material(type: MaterialType.transparency, child: screen),
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  FocusNode? get _primary => FocusManager.instance.primaryFocus;

  /// Focusable controls a viewer could be expected to reach: on screen, in the
  /// current route, and not scopes, which are containers rather than stops.
  List<FocusNode> stops() {
    final view = tester.view.physicalSize / tester.view.devicePixelRatio;
    final screen = Offset.zero & view;
    return [
      for (final node in FocusManager.instance.rootScope.traversalDescendants)
        if (node is! FocusScopeNode &&
            node.canRequestFocus &&
            !node.skipTraversal &&
            node.context != null &&
            _onScreen(node, screen))
          node,
    ];
  }

  bool _onScreen(FocusNode node, Rect screen) {
    final ctx = node.context!;
    if (!(ModalRoute.of(ctx)?.isCurrent ?? true)) return false;
    final box = ctx.findRenderObject();
    if (box is! RenderBox || !box.hasSize || !box.attached) return false;
    final rect = box.localToGlobal(Offset.zero) & box.size;
    return rect.overlaps(screen) && !rect.isEmpty;
  }

  bool _isStop(FocusNode? node) => node != null && stops().contains(node);

  // Each rule comes in two forms: one that returns what it found, which the
  // audit's own controls (dpad_audit_test.dart) assert on, and an expect
  // wrapper for screen tests. A failing expect inside the tester's async guard
  // cannot be caught as a value, which is why the finding is the primitive.

  /// Whether something is focused after at most one press.
  Future<bool> firstPressFocuses() async {
    if (_isStop(_primary)) return true;
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    return _isStop(_primary);
  }

  Future<void> expectFirstPressFocuses() async {
    expect(await firstPressFocuses(), isTrue,
        reason: 'nothing is focused after the first D-pad press, so the '
            'remote appears dead on this screen');
  }

  /// Walks every arrow from every stop reached, and returns what was reached.
  ///
  /// A breadth-first walk of the directional graph, not a single path: it
  /// focuses each stop found and tries all four arrows from it. [maxStops]
  /// bounds long lists; the rules are about kinds of control, and the
  /// hundredth channel row behaves like the first.
  Future<Set<FocusNode>> walk({int maxStops = 60}) async {
    if (!await firstPressFocuses()) return {};
    final seen = <FocusNode>{_primary!};
    final queue = <FocusNode>[_primary!];
    while (queue.isNotEmpty && seen.length < maxStops) {
      final from = queue.removeAt(0);
      for (final key in arrows) {
        if (from.context == null) break;
        from.requestFocus();
        // The directional policy remembers recent moves so that Down after Up
        // returns to where Up came from. Jumping focus with requestFocus, as
        // this walk does and a remote cannot, leaves that memory pointing at
        // the wrong place, so it is cleared before each probe.
        _forgetDirectionalHistory(from);
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(key);
        await tester.pumpAndSettle();
        final to = _primary;
        if (to != null && _isStop(to) && seen.add(to)) queue.add(to);
      }
    }
    return seen;
  }

  static void _forgetDirectionalHistory(FocusNode node) {
    final ctx = node.context;
    final scope = node.nearestScope;
    if (ctx == null || scope == null) return;
    FocusTraversalGroup.maybeOf(ctx)?.invalidateScopeData(scope);
  }

  /// Stops on screen that [walk] never reaches.
  Future<List<String>> unreachable({Set<String> exempt = const {}}) async {
    final reached = await walk();
    return [
      for (final node in stops())
        if (!reached.contains(node) && !exempt.contains(describe(node)))
          describe(node),
    ];
  }

  Future<void> expectAllReachable({Set<String> exempt = const {}}) async {
    expect(await unreachable(exempt: exempt), isEmpty,
        reason: 'on screen and focusable, but no arrow key reaches them');
  }

  /// Every stop, once focused, shows it.
  ///
  /// [exempt] names controls known to fail, each of which should say why at
  /// the call site. An exemption is a recorded defect, not a pass.
  Future<List<String>> invisibleFocus({Set<String> exempt = const {}}) async {
    final invisible = <String>[];
    for (final node in stops()) {
      node.requestFocus();
      await tester.pumpAndSettle();
      final name = describe(node);
      if (!showsFocus(node) && !exempt.contains(name)) invisible.add(name);
    }
    return invisible;
  }

  Future<void> expectFocusVisible({Set<String> exempt = const {}}) async {
    expect(await invisibleFocus(exempt: exempt), isEmpty,
        reason: 'focused, but nothing on screen says so; wrap them in '
            'RelayFocusRing or use RelayTappable / RelayButton');
  }

  /// Text fields that Up and Down cannot leave.
  Future<List<String>> trappingFields() async {
    final trapped = <String>[];
    final fields = [
      for (final node in stops())
        if (_isTextField(node)) node,
    ];
    for (final field in fields) {
      var escaped = false;
      for (final key in [
        LogicalKeyboardKey.arrowDown,
        LogicalKeyboardKey.arrowUp,
      ]) {
        field.requestFocus();
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(key);
        await tester.pumpAndSettle();
        if (_primary != field) escaped = true;
      }
      if (!escaped) trapped.add(describe(field));
    }
    return trapped;
  }

  Future<void> expectFieldsEscapable() async {
    expect(await trappingFields(), isEmpty,
        reason: 'Up and Down stay inside these fields; wrap them in '
            'RelayFieldTraversal');
  }

  /// Whether [node] draws its focus: a lit ring above it, or a text field.
  static bool showsFocus(FocusNode node) {
    if (_isTextField(node)) return true;
    var lit = false;
    node.context!.visitAncestorElements((e) {
      final w = e.widget;
      if (w is RelayFocusRing) {
        lit = w.focused;
        return false;
      }
      return true;
    });
    if (lit) return true;
    // A ring can also sit below the focus node, as RelayTappable's does.
    void visit(Element e) {
      if (lit) return;
      final w = e.widget;
      if (w is RelayFocusRing && w.focused) {
        lit = true;
        return;
      }
      e.visitChildren(visit);
    }

    (node.context! as Element).visitChildren(visit);
    return lit;
  }

  static bool _isTextField(FocusNode node) {
    var found = false;
    void visit(Element e) {
      if (found) return;
      if (e.widget is EditableText &&
          (e.widget as EditableText).focusNode == node) {
        found = true;
        return;
      }
      e.visitChildren(visit);
    }

    visit(node.context! as Element);
    if (found) return true;
    node.context!.visitAncestorElements((e) {
      if (e.widget is EditableText &&
          (e.widget as EditableText).focusNode == node) {
        found = true;
      }
      return !found;
    });
    return found;
  }

  /// A readable name for a stop: its first text, tooltip, or semantics label.
  static String describe(FocusNode node) {
    String? label;
    void visit(Element e) {
      if (label != null) return;
      final w = e.widget;
      if (w is Text && (w.data ?? '').trim().isNotEmpty) {
        label = w.data!.trim();
      } else if (w is Tooltip && (w.message ?? '').isNotEmpty) {
        label = w.message;
      } else if (w is EditableText && w.controller.text.isNotEmpty) {
        label = 'field "${w.controller.text}"';
      } else if (w is InputDecorator &&
          (w.decoration.hintText ?? '').isNotEmpty) {
        label = 'field "${w.decoration.hintText}"';
      }
      e.visitChildren(visit);
    }

    final ctx = node.context;
    if (ctx == null) return node.toString();
    visit(ctx as Element);
    if (label == null) {
      // A field's hint, or an IconButton's tooltip, sits above the focus node
      // rather than inside it: some 20 levels up for a Material 3 IconButton.
      var depth = 0;
      ctx.visitAncestorElements((e) {
        if (e.widget is Tooltip && (e.widget as Tooltip).message != null) {
          label = (e.widget as Tooltip).message;
          return false;
        }
        if (e.widget is TextField) {
          final d = (e.widget as TextField).decoration;
          label = 'field "${d?.hintText ?? d?.labelText ?? '?'}"';
          return false;
        }
        return ++depth < 30;
      });
    }
    return label ?? node.toStringShort();
  }
}
