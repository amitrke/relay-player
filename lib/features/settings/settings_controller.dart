import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'settings_screen.dart';

/// Holds [SettingsState] for the running app.
///
/// Not yet persisted. §3 puts non-secret settings in the Hive/Isar box, which
/// does not exist yet — deliberately not smuggled into secure storage instead,
/// since establishing "secrets and preferences share a store" is the exact
/// confusion §3's credential rule exists to prevent. The cost today is that the
/// Advanced Sources toggle resets on relaunch.
final settingsProvider = NotifierProvider<SettingsController, SettingsState>(
  SettingsController.new,
);

class SettingsController extends Notifier<SettingsState> {
  @override
  SettingsState build() => const SettingsState();

  void update(SettingsState next) => state = next;
}

/// §8.2's gate, as the rest of the app sees it.
///
/// Read this rather than `settingsProvider.advancedSourcesEnabled` directly, so
/// the remote kill switch (§16.1) has one place to AND itself in later: it can
/// force the feature off globally, but must never force it *on* for a user who
/// has not opted in.
final advancedSourcesEnabledProvider = Provider<bool>((ref) {
  return ref.watch(settingsProvider.select((s) => s.advancedSourcesEnabled));
});
