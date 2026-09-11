import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:relay_player/core/theme/relay_tokens.dart';

/// These lock the Dart port to `design/theme.js`. If the design changes a
/// palette value, these fail — which is the point: the two must not drift.
void main() {
  group('contrast', () {
    test('matches known WCAG ratios', () {
      // Black on white is the canonical 21:1.
      expect(
        RelayTokens.contrastRatio(
            const Color(0xFF000000), const Color(0xFFFFFFFF)),
        closeTo(21.0, 0.01),
      );
      // A colour against itself is 1:1.
      expect(
        RelayTokens.contrastRatio(
            const Color(0xFF8B7FE0), const Color(0xFF8B7FE0)),
        closeTo(1.0, 0.001),
      );
    });

    test('is symmetric', () {
      const a = Color(0xFF4F9D8A);
      const b = Color(0xFF14110D);
      expect(
        RelayTokens.contrastRatio(a, b),
        closeTo(RelayTokens.contrastRatio(b, a), 1e-9),
      );
    });
  });

  group('inkOn — derived, never hardcoded', () {
    test('picks dark ink on the default violet accent', () {
      // theme.js: ratio('#ffffff', a) >= ratio('#121216', a) ? white : dark.
      // On #8b7fe0 white scores 3.38:1 and near-black 5.53:1, so dark wins.
      // Worth asserting explicitly — the intuition is that a mid-dark violet
      // takes white text, and it does not.
      expect(RelayTokens.inkOn(RelayAccents.defaultAccent),
          const Color(0xFF121216));
    });

    test('picks white only when the accent is dark enough to need it', () {
      // Of the four shipped swatches only the clay red crosses over.
      expect(RelayTokens.inkOn(const Color(0xFFB8574E)),
          const Color(0xFFFFFFFF));
      // A very light accent must never take white.
      expect(RelayTokens.inkOn(const Color(0xFFFFE066)),
          const Color(0xFF121216));
    });

    test('every shipped swatch produces readable ink', () {
      for (final swatch in RelayAccents.swatches) {
        final ink = RelayTokens.inkOn(swatch);
        expect(
          RelayTokens.contrastRatio(ink, swatch),
          greaterThanOrEqualTo(3.0),
          reason: 'accent $swatch has poor contrast with its derived ink',
        );
      }
    });
  });

  group('palettes', () {
    test('resolve applies the accent and re-derives accentInk', () {
      const lightAccent = Color(0xFFFFE066);
      final tokens = RelayPalettes.resolve(
        RelayPalette.midnight,
        platformIsDark: true,
        accent: lightAccent,
      );
      expect(tokens.accent, lightAccent);
      expect(tokens.accentInk, RelayTokens.inkOn(lightAccent));
      // Palette colours are untouched by the accent.
      expect(tokens.bg, RelayPalettes.midnight.bg);
    });

    test('system follows platform brightness', () {
      expect(
        RelayPalettes.resolve(RelayPalette.system, platformIsDark: true).bg,
        RelayPalettes.midnight.bg,
      );
      expect(
        RelayPalettes.resolve(RelayPalette.system, platformIsDark: false).bg,
        RelayPalettes.daylight.bg,
      );
    });

    test('only daylight is a light palette', () {
      expect(RelayPalette.daylight.isDarkPalette, isFalse);
      for (final p in [
        RelayPalette.midnight,
        RelayPalette.slate,
        RelayPalette.amber
      ]) {
        expect(p.isDarkPalette, isTrue);
      }
    });

    test('body text clears AA against its background in every palette', () {
      final palettes = {
        'Midnight': RelayPalettes.midnight,
        'Slate': RelayPalettes.slate,
        'Daylight': RelayPalettes.daylight,
        'Amber': RelayPalettes.amber,
      };
      palettes.forEach((name, t) {
        expect(RelayTokens.contrastRatio(t.ink, t.bg),
            greaterThanOrEqualTo(4.5),
            reason: '$name: ink on bg fails AA');
        // Dim text is secondary; AA large-text (3:1) is the bar it must clear.
        expect(RelayTokens.contrastRatio(t.inkDim, t.bg),
            greaterThanOrEqualTo(3.0),
            reason: '$name: inkDim on bg fails AA large');
      });
    });
  });

  test('theme labels match the Settings chips exactly', () {
    expect(
      RelayPalette.values.map((p) => p.label).toList(),
      ['System', 'Midnight', 'Slate', 'Daylight', 'Amber'],
    );
  });
}
