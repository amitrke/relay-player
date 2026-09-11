import 'package:flutter/material.dart';

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
    final media = MediaQuery.of(context);
    final width = media.size.width;
    // A TV reports a large logical width with a coarse pointer and no touch.
    final coarse = media.navigationMode == NavigationMode.directional;
    if (coarse || width >= 1800) return RelayFormFactor.tv;
    if (width >= 1100) return RelayFormFactor.desktop;
    if (width >= 700) return RelayFormFactor.tablet;
    return RelayFormFactor.phone;
  }

  /// Outer page padding per form factor. The 10-foot UI needs a real overscan
  /// margin, not a scaled-up phone gutter.
  static EdgeInsets pagePadding(RelayFormFactor f) => switch (f) {
        RelayFormFactor.phone => const EdgeInsets.symmetric(horizontal: 20),
        RelayFormFactor.tablet => const EdgeInsets.symmetric(horizontal: 48),
        RelayFormFactor.desktop => const EdgeInsets.symmetric(horizontal: 64),
        RelayFormFactor.tv => const EdgeInsets.symmetric(horizontal: 96, vertical: 48),
      };

  static double titleSize(RelayFormFactor f) => switch (f) {
        RelayFormFactor.phone => 28,
        RelayFormFactor.tablet => 34,
        RelayFormFactor.desktop => 34,
        RelayFormFactor.tv => 52,
      };

  static double bodySize(RelayFormFactor f) => switch (f) {
        RelayFormFactor.phone => 14,
        RelayFormFactor.tablet => 15,
        RelayFormFactor.desktop => 15,
        RelayFormFactor.tv => 22,
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
