import 'package:flutter/material.dart';

import 'relay_theme.dart';
import 'relay_tokens.dart';

/// Holds the Appearance selection (§12.2) and rebuilds the app when it changes.
///
/// Phase 1 will persist this alongside the other non-secret settings (§3 —
/// Hive/Isar, never secure storage; a theme choice is not a credential). For
/// now it lives in memory so the screens can be built and reviewed.
class ThemeController extends ChangeNotifier {
  // Initializing formals are not possible here: a named parameter cannot be
  // private, and these fields must stay private behind notifying setters.
  // ignore_for_file: prefer_initializing_formals
  ThemeController({
    RelayPalette palette = RelayPalette.system,
    Color accent = RelayAccents.defaultAccent,
  })  : _palette = palette,
        _accent = accent;

  RelayPalette _palette;
  Color _accent;

  RelayPalette get palette => _palette;
  Color get accent => _accent;

  set palette(RelayPalette value) {
    if (value == _palette) return;
    _palette = value;
    notifyListeners();
  }

  set accent(Color value) {
    if (value == _accent) return;
    _accent = value;
    notifyListeners();
  }
}

/// Applies the current [ThemeController] selection to [child].
///
/// Watches the platform brightness so `System` keeps following the OS while the
/// app is running — §12.2 calls that out specifically, and it is easy to get
/// wrong by reading brightness once at startup.
class RelayApp extends StatelessWidget {
  const RelayApp({
    super.key,
    required this.controller,
    required this.builder,
    this.title = 'Relay Player',
  });

  final ThemeController controller;
  final WidgetBuilder builder;
  final String title;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return MediaQuery.fromView(
          view: View.of(context),
          child: Builder(
            builder: (context) {
              final platformIsDark =
                  MediaQuery.platformBrightnessOf(context) == Brightness.dark;
              final tokens = RelayPalettes.resolve(
                controller.palette,
                platformIsDark: platformIsDark,
                accent: controller.accent,
              );
              final isDark = controller.palette == RelayPalette.system
                  ? platformIsDark
                  : controller.palette.isDarkPalette;

              return MaterialApp(
                title: title,
                debugShowCheckedModeBanner: false,
                theme: relayThemeData(tokens, isDark: isDark),
                home: RelayTheme(
                  tokens: tokens,
                  palette: controller.palette,
                  child: Builder(builder: builder),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
