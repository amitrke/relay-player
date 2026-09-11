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

/// §8.2's gate, as the rest of the app sees it.
///
/// Read this rather than `settingsProvider.advancedSourcesEnabled` directly, so
/// the remote kill switch (§16.1) has one place to AND itself in later: it can
/// force the feature off globally, but must never force it *on* for a user who
/// has not opted in.
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
