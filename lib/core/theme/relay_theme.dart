import 'package:flutter/material.dart';

import '../platform/device_kind.dart';
import 'relay_tokens.dart';

/// Makes [RelayTokens] available to the widget tree.
///
/// Screens read colours through `RelayTheme.of(context)` and never name a
/// literal colour — that is the rule `design/theme.js` encodes and the reason
/// the Appearance picker (§12.2) can work at all.
class RelayTheme extends InheritedWidget {
  const RelayTheme({
    super.key,
    required this.tokens,
    required this.palette,
    required super.child,
  });

  final RelayTokens tokens;
  final RelayPalette palette;

  static RelayTokens of(BuildContext context) {
    final inherited =
        context.dependOnInheritedWidgetOfExactType<RelayTheme>();
    assert(inherited != null, 'No RelayTheme in the widget tree.');
    return inherited!.tokens;
  }

  static RelayPalette paletteOf(BuildContext context) {
    final inherited =
        context.dependOnInheritedWidgetOfExactType<RelayTheme>();
    assert(inherited != null, 'No RelayTheme in the widget tree.');
    return inherited!.palette;
  }

  @override
  bool updateShouldNotify(RelayTheme oldWidget) =>
      oldWidget.tokens != tokens || oldWidget.palette != palette;
}

/// Form factors the design canvas draws artboards for.
///
/// §11 is explicit that TV "is not a resize of the phone UI" — [tv] therefore
/// selects a different layout tree, not just larger padding. The others do
/// share a tree and differ by spacing and column count.
enum RelayFormFactor { phone, tablet, desktop, tv }

class RelayLayout {
  const RelayLayout._();

  /// Artboard widths: phone 390, tablet 834, desktop 1440, TV 1920.
  static RelayFormFactor of(BuildContext context) {
    // Asked of the platform, not inferred from the window. This used to test
    // `width >= 1800` or `navigationMode == directional`, and neither can ever
    // be true on a TV: a 1080p panel reports 960 dp wide, and Flutter leaves
    // navigationMode at `traditional` unless the app changes it. The tv branch
    // was therefore unreachable and every 10-foot size below was dead code.
    if (DeviceKind.isTelevision) return RelayFormFactor.tv;

    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1100) return RelayFormFactor.desktop;
    if (width >= 700) return RelayFormFactor.tablet;
    return RelayFormFactor.phone;
  }

  /// Outer page padding per form factor. The 10-foot UI needs a real overscan
  /// margin, not a scaled-up phone gutter.
  ///
  /// The TV margin is 5% of each axis, which is the conventional overscan
  /// allowance — 48 × 27 against 960 × 540. It used to be 96 × 48, taken from a
  /// 1920 × 1080 artboard as though those were logical pixels. They are not:
  /// see [titleSize].
  static EdgeInsets pagePadding(RelayFormFactor f) => switch (f) {
        RelayFormFactor.phone => const EdgeInsets.symmetric(horizontal: 20),
        RelayFormFactor.tablet => const EdgeInsets.symmetric(horizontal: 48),
        RelayFormFactor.desktop => const EdgeInsets.symmetric(horizontal: 64),
        RelayFormFactor.tv =>
          const EdgeInsets.symmetric(horizontal: 48, vertical: 27),
      };

  /// Type sizes.
  ///
  /// **The TV sizes are smaller than they look.** A TV is not a big canvas in
  /// layout terms: a 1080p panel reports **960 × 540 dp**, so it has twice a
  /// phone's width and *half* its height. Android reports 320 dpi for it
  /// precisely so that a dp is physically large — about 0.05 inch on a 55"
  /// screen against 0.006 inch on a phone. Density has therefore already
  /// compensated for the three-metre viewing distance, by roughly 8×.
  ///
  /// The earlier numbers (52 title, 22 body) were drawn against a 1920 × 1080
  /// artboard read as logical pixels, and multiplied on top of a compensation
  /// that had already happened: ~12× the physical size of the phone text for
  /// ~8× the distance. The result did not fit in 540 dp — the onboarding screen
  /// pushed its only focusable control off the bottom of the screen.
  static double titleSize(RelayFormFactor f) => switch (f) {
        RelayFormFactor.phone => 28,
        RelayFormFactor.tablet => 34,
        RelayFormFactor.desktop => 34,
        RelayFormFactor.tv => 36,
      };

  static double bodySize(RelayFormFactor f) => switch (f) {
        RelayFormFactor.phone => 14,
        RelayFormFactor.tablet => 15,
        RelayFormFactor.desktop => 15,
        RelayFormFactor.tv => 18,
      };
}

/// Builds a Material [ThemeData] from [tokens].
///
/// Most of the UI is drawn directly from tokens; this exists so Material
/// primitives (dialogs, ripples, text selection) don't fall back to Flutter's
/// default indigo.
ThemeData relayThemeData(RelayTokens t, {required bool isDark}) {
  final scheme =
      (isDark ? const ColorScheme.dark() : const ColorScheme.light()).copyWith(
    primary: t.accent,
    onPrimary: t.accentInk,
    surface: t.surface,
    onSurface: t.ink,
    outline: t.line,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: isDark ? Brightness.dark : Brightness.light,
    colorScheme: scheme,
    scaffoldBackgroundColor: t.bg,
    canvasColor: t.bg,
    dividerColor: t.line,
    // Material's default focus overlay is a faint tint, which is invisible
    // across a room. Anything drawn by Material rather than by RelayFocusRing
    // — NavigationBar destinations, TextButton, ListTile — gets a focus state
    // that can actually be seen from a sofa.
    focusColor: t.accent.withValues(alpha: 0.35),
    fontFamily: 'IBM Plex Sans',
    // The design canvas uses IBM Plex; fall back gracefully until the font is
    // bundled, rather than shipping a hard dependency on an absent asset.
    fontFamilyFallback: const ['Segoe UI', 'Roboto', 'sans-serif'],
    textTheme: TextTheme(
      bodyMedium: TextStyle(color: t.ink),
      bodySmall: TextStyle(color: t.inkDim),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: t.surface,
      surfaceTintColor: Colors.transparent,
    ),
  );
}
