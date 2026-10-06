import 'package:dart_plex/dart_plex.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/app_settings_store.dart';
import '../library/library_mapping.dart';
import 'settings_screen.dart';

/// Set once at startup, before `runApp`, so settings are readable synchronously
/// and the first frame never renders a default the user already changed.
final appSettingsStoreProvider = Provider<AppSettingsStore>((ref) {
  throw StateError('appSettingsStoreProvider was not overridden in main().');
});

const _kAdvancedSources = 'advancedSourcesEnabled';
const _kCrashReporting = 'crashReportingEnabled';
const _kLibraryMapping = 'plex.libraryMapping';
const _kOnboardingSeen = 'onboardingSeen';

final settingsProvider = NotifierProvider<SettingsController, SettingsState>(
  SettingsController.new,
);

class SettingsController extends Notifier<SettingsState> {
  AppSettingsStore get _store => ref.read(appSettingsStoreProvider);

  @override
  SettingsState build() {
    return SettingsState(
      advancedSourcesEnabled:
          _store.getBool(_kAdvancedSources, fallback: false),
      crashReportingEnabled:
          _store.getBool(_kCrashReporting, fallback: false),
    );
  }

  /// Persists whatever changed. [SettingsState] also carries transient UI state
  /// (which section the desktop rail has open), which deliberately is not
  /// written — reopening Settings on the section you last viewed is not a
  /// preference worth surviving a restart.
  void update(SettingsState next) {
    final previous = state;
    state = next;
    if (next.advancedSourcesEnabled != previous.advancedSourcesEnabled) {
      _store.setBool(_kAdvancedSources, next.advancedSourcesEnabled);
    }
    if (next.crashReportingEnabled != previous.crashReportingEnabled) {
      _store.setBool(_kCrashReporting, next.crashReportingEnabled);
    }
  }
}

/// Whether the user has been past first-run once.
///
/// Deliberately *not* "has a source configured". §12 screen 1 is general
/// framing, and screen 2 makes Plex and Local & Network both optional — an app
/// that re-demands setup on every launch until you connect something has turned
/// one source into a gate.
final onboardingSeenProvider =
    NotifierProvider<OnboardingSeenController, bool>(
  OnboardingSeenController.new,
);

class OnboardingSeenController extends Notifier<bool> {
  @override
  bool build() =>
      ref.read(appSettingsStoreProvider).getBool(_kOnboardingSeen, fallback: false);

  Future<void> markSeen() async {
    state = true;
    await ref.read(appSettingsStoreProvider).setBool(_kOnboardingSeen, true);
  }
}

/// §8.2's gate, as the rest of the app sees it.
///
/// Read this rather than `settingsProvider.advancedSourcesEnabled` directly, so
/// anything that later needs to gate the feature has one place to do it. (A
/// remote kill switch was meant to be that, and was dropped 2026-10-06, §16.1.)
final advancedSourcesEnabledProvider = Provider<bool>((ref) {
  return ref.watch(settingsProvider.select((s) => s.advancedSourcesEnabled));
});

final libraryMappingProvider =
    NotifierProvider<LibraryMappingController, LibraryMapping>(
  LibraryMappingController.new,
);

class LibraryMappingController extends Notifier<LibraryMapping> {
  AppSettingsStore get _store => ref.read(appSettingsStoreProvider);

  @override
  LibraryMapping build() =>
      LibraryMapping.fromStorage(_store.getStringMap(_kLibraryMapping));

  Future<void> setPlacement(
    String serverId,
    PlexLibrarySection section,
    LibraryPlacement placement,
  ) async {
    final next = state.withPlacement(serverId, section, placement);
    state = next;
    await _store.setStringMap(_kLibraryMapping, next.toStorage());
  }
}
