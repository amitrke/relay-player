import 'dart:math' as math;
import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';

/// The Relay Player design tokens.
///
/// Ported from `design/theme.js`, which is the source of truth for the values.
/// The design canvas states the rule this file implements: *theme is a runtime
/// setting, not a hard-coded palette* — every colour in every screen reads from
/// a token, so Settings can offer an Appearance picker (§12.2) and the TV
/// layout tree (§11) inherits the same palette without duplicating it.
///
/// There are deliberately only eight tokens. Resist adding a ninth without a
/// matching change in `design/theme.js`; a colour that exists only in Dart is a
/// colour the design canvas cannot show.
@immutable
class RelayTokens {
  const RelayTokens({
    required this.stage,
    required this.bg,
    required this.surface,
    required this.line,
    required this.ink,
    required this.inkDim,
    required this.accent,
    required this.accentInk,
  });

  /// Behind the app frame — the canvas colour around a phone/TV artboard, and
  /// the letterbox behind video.
  final Color stage;

  /// The app background.
  final Color bg;

  /// Cards, sheets, rows — anything raised off [bg].
  final Color surface;

  /// Hairline borders and dividers.
  final Color line;

  /// Primary text and icons.
  final Color ink;

  /// Secondary text: metadata, captions, disabled states.
  final Color inkDim;

  /// The user-chosen accent.
  final Color accent;

  /// Text/icon colour that sits *on* [accent]. Never chosen by hand — see
  /// [inkOn].
  final Color accentInk;

  RelayTokens copyWith({Color? accent}) {
    if (accent == null) return this;
    return RelayTokens(
      stage: stage,
      bg: bg,
      surface: surface,
      line: line,
      ink: ink,
      inkDim: inkDim,
      accent: accent,
      accentInk: inkOn(accent),
    );
  }

  /// Linear interpolation, so a theme change can animate rather than snap.
  static RelayTokens lerp(RelayTokens a, RelayTokens b, double t) {
    Color c(Color x, Color y) => Color.lerp(x, y, t)!;
    return RelayTokens(
      stage: c(a.stage, b.stage),
      bg: c(a.bg, b.bg),
      surface: c(a.surface, b.surface),
      line: c(a.line, b.line),
      ink: c(a.ink, b.ink),
      inkDim: c(a.inkDim, b.inkDim),
      accent: c(a.accent, b.accent),
      accentInk: c(a.accentInk, b.accentInk),
    );
  }

  // --- Contrast ---------------------------------------------------------

  /// The dark candidate for [inkOn]. Matches `theme.js`.
  static const Color _darkInk = Color(0xFF121216);

  /// WCAG 2.x relative luminance.
  ///
  /// `.r`/`.g`/`.b` are already normalised to 0.0–1.0, which is the same value
  /// `theme.js` computes as `parseInt(hex, 16) / 255`.
  static double _luminance(Color c) {
    double channel(double s) =>
        s <= 0.03928 ? s / 12.92 : math.pow((s + 0.055) / 1.055, 2.4).toDouble();

    return 0.2126 * channel(c.r) +
        0.7152 * channel(c.g) +
        0.0722 * channel(c.b);
  }

  /// WCAG contrast ratio between two opaque colours (1.0 – 21.0).
  static double contrastRatio(Color a, Color b) {
    final la = _luminance(a);
    final lb = _luminance(b);
    final hi = math.max(la, lb);
    final lo = math.min(la, lb);
    return (hi + 0.05) / (lo + 0.05);
  }

  /// Picks white or near-black to sit on [accent], whichever has more contrast.
  ///
  /// `design/theme.js`: "Accent ink is derived, never hard-coded." This matters
  /// because the accent is user-chosen (Settings offers a swatch row and, in
  /// principle, any colour) — a hardcoded foreground would fail contrast the
  /// moment someone picks a light accent.
  static Color inkOn(Color accent) =>
      contrastRatio(const Color(0xFFFFFFFF), accent) >=
              contrastRatio(_darkInk, accent)
          ? const Color(0xFFFFFFFF)
          : _darkInk;

  /// True when [accentInk] clears the WCAG AA threshold for normal text.
  /// Used by the Settings accent picker to warn on a poor custom colour.
  bool get accentMeetsAA => contrastRatio(accentInk, accent) >= 4.5;
}

/// The selectable Appearance options (§12.2).
///
/// [system] is not a palette — it resolves to [RelayPalette.midnight] or
/// [RelayPalette.daylight] from the platform brightness, and must keep
/// following the OS while the app is running.
enum RelayPalette {
  system('System'),
  midnight('Midnight'),
  slate('Slate'),
  daylight('Daylight'),
  amber('Amber');

  const RelayPalette(this.label);

  /// Exactly the labels shown in the Settings theme chips.
  final String label;

  bool get isDarkPalette => this != daylight;

  static RelayPalette fromLabel(String label) => RelayPalette.values.firstWhere(
        (p) => p.label == label,
        orElse: () => RelayPalette.system,
      );
}

/// The default accent and the swatches Settings offers, from the design canvas.
class RelayAccents {
  const RelayAccents._();

  static const Color defaultAccent = Color(0xFF8B7FE0);

  static const List<Color> swatches = [
    Color(0xFF8B7FE0), // violet (default)
    Color(0xFFC9863F), // amber
    Color(0xFF4F9D8A), // teal
    Color(0xFFB8574E), // clay
  ];
}

/// The four palettes, verbatim from `design/theme.js`.
class RelayPalettes {
  const RelayPalettes._();

  static const RelayTokens midnight = RelayTokens(
    stage: Color(0xFF06060A),
    bg: Color(0xFF0A0A0C),
    surface: Color(0xFF121215),
    line: Color(0xFF24242A),
    ink: Color(0xFFF2F2F4),
    inkDim: Color(0xFF9A9AA4),
    accent: RelayAccents.defaultAccent,
    // Derived for [RelayAccents.defaultAccent], not chosen: white scores only
    // 3.38:1 on this violet while near-black scores 5.53:1. Any code path that
    // changes the accent must re-derive via [RelayTokens.inkOn] —
    // [RelayPalettes.resolve] does.
    accentInk: Color(0xFF121216),
  );

  static const RelayTokens slate = RelayTokens(
    stage: Color(0xFF0D1014),
    bg: Color(0xFF14171C),
    surface: Color(0xFF1C2027),
    line: Color(0xFF2C323B),
    ink: Color(0xFFEEF1F5),
    inkDim: Color(0xFF939BA7),
    accent: RelayAccents.defaultAccent,
    // Derived for [RelayAccents.defaultAccent], not chosen: white scores only
    // 3.38:1 on this violet while near-black scores 5.53:1. Any code path that
    // changes the accent must re-derive via [RelayTokens.inkOn] —
    // [RelayPalettes.resolve] does.
    accentInk: Color(0xFF121216),
  );

  static const RelayTokens daylight = RelayTokens(
    stage: Color(0xFFECECED),
    bg: Color(0xFFF7F7F8),
    surface: Color(0xFFFFFFFF),
    line: Color(0xFFE2E2E6),
    ink: Color(0xFF17171A),
    inkDim: Color(0xFF6B6B73),
    accent: RelayAccents.defaultAccent,
    // Derived for [RelayAccents.defaultAccent], not chosen: white scores only
    // 3.38:1 on this violet while near-black scores 5.53:1. Any code path that
    // changes the accent must re-derive via [RelayTokens.inkOn] —
    // [RelayPalettes.resolve] does.
    accentInk: Color(0xFF121216),
  );

  static const RelayTokens amber = RelayTokens(
    stage: Color(0xFF0F0D0A),
    bg: Color(0xFF14110D),
    surface: Color(0xFF1C1813),
    line: Color(0xFF2E2820),
    ink: Color(0xFFF5F0E8),
    inkDim: Color(0xFFA89C8A),
    accent: RelayAccents.defaultAccent,
    // Derived for [RelayAccents.defaultAccent], not chosen: white scores only
    // 3.38:1 on this violet while near-black scores 5.53:1. Any code path that
    // changes the accent must re-derive via [RelayTokens.inkOn] —
    // [RelayPalettes.resolve] does.
    accentInk: Color(0xFF121216),
  );

  /// Resolves [palette] (including [RelayPalette.system]) and applies [accent],
  /// deriving `accentInk` rather than trusting the constant above.
  static RelayTokens resolve(
    RelayPalette palette, {
    required bool platformIsDark,
    Color accent = RelayAccents.defaultAccent,
  }) {
    final base = switch (palette) {
      RelayPalette.system => platformIsDark ? midnight : daylight,
      RelayPalette.midnight => midnight,
      RelayPalette.slate => slate,
      RelayPalette.daylight => daylight,
      RelayPalette.amber => amber,
    };
    return base.copyWith(accent: accent);
  }
}
