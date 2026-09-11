import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/theme_controller.dart';
import 'settings_controller.dart';
import 'settings_screen.dart';

/// Binds the design-canvas [SettingsScreen] to app state.
///
/// [SettingsScreen] is deliberately presentational — it takes its state and a
/// change callback rather than reaching for providers — so the design gallery
/// can drive it with fabricated values. This is the one place that connects it
/// to the real thing.
class SettingsRoute extends ConsumerWidget {
  const SettingsRoute({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SettingsScreen(
      theme: ref.watch(themeControllerProvider),
      state: ref.watch(settingsProvider),
      onStateChanged: ref.read(settingsProvider.notifier).update,
    );
  }
}
