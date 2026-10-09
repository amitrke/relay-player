import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:relay_player/core/platform/device_kind.dart';
import 'package:relay_player/core/theme/relay_theme.dart';
import 'package:relay_player/core/theme/relay_tokens.dart';
import 'package:relay_player/core/theme/theme_controller.dart';
import 'package:relay_player/features/accounts/plex_session.dart';
import 'package:relay_player/features/ai/ai_controller.dart';
import 'package:relay_player/features/player/playback_prefs.dart';
import 'package:relay_player/features/settings/settings_screen.dart';

/// Guards the release-build Settings against sections that look finished and are
/// not.
///
/// Until 2026-09-21 the TV/desktop layout opened on AI features, whose pane was
/// the design canvas's demo data: a "saved" OpenAI key and consent rows
/// "granted" on dates nobody chose. It looked finished, so nothing about the
/// code reading correctly would have caught it coming back; this does.
///
/// AI features (and Metadata) were built for real on 2026-10-09, and Privacy and
/// data the same day, around clearing cached data. Every section is built now, so
/// the "unbuilt sections stay out" rule has nothing to stand on in these tests,
/// but the `SettingsSection.built` flag and the code that honours it remain: the
/// tests below pin that the panes are real controls and never the old demo rows
/// or the crash-report switch that stored a preference nothing read.
void main() {
  setUp(() {
    DeviceKind.debugSetTelevision(true);
    PackageInfo.setMockInitialValues(
      appName: 'Subnext Player',
      packageName: 'com.subnext.relay',
      version: '1.0.0',
      buildNumber: '42',
      buildSignature: '',
    );
  });
  tearDown(() => DeviceKind.debugSetTelevision(false));

  Future<void> pump(
    WidgetTester tester, {
    SettingsState state = const SettingsState(),
    bool showUnbuiltSections = false,
  }) async {
    // A TV's real logical size (see tv_navigation_test.dart).
    tester.view.physicalSize = const Size(960, 540);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    var current = state;
    await tester.pumpWidget(
      MaterialApp(
        home: RelayTheme(
          tokens: RelayPalettes.midnight,
          palette: RelayPalette.midnight,
          child: StatefulBuilder(
            builder: (context, setState) => SettingsScreen(
              theme: ThemeController(),
              state: current,
              onStateChanged: (s) => setState(() => current = s),
              showUnbuiltSections: showUnbuiltSections,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the TV layout lists every section, and opens on Appearance', (
    tester,
  ) async {
    await pump(tester);

    for (final label in [
      'Sources',
      'Appearance',
      'Playback',
      'Subtitles',
      'Metadata',
      'AI features',
      'Advanced sources',
      'Privacy and data',
      'About',
    ]) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    // None of the old demo rows or stubs.
    expect(find.textContaining('Granted'), findsNothing);
    expect(find.textContaining('Not implemented'), findsNothing);
    // Opens on Appearance, not on whatever the enum lists first.
    expect(find.text('Theme'), findsOneWidget);
  });

  testWidgets(
    'Privacy and data has the clear-cache control and no crash switch',
    (tester) async {
      await pump(
        tester,
        state: const SettingsState(section: SettingsSection.privacy),
      );

      expect(find.text('Clear cached data'), findsOneWidget);
      expect(
        find.textContaining('no backend and no analytics'),
        findsOneWidget,
      );
      // A switch for a data flow that does not exist.
      expect(find.text('Send crash reports'), findsNothing);
    },
  );

  testWidgets('AI features is real controls, never the old demo rows', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(960, 540);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [aiSetupProvider.overrideWith(_NoAi.new)],
        child: MaterialApp(
          home: RelayTheme(
            tokens: RelayPalettes.midnight,
            palette: RelayPalette.midnight,
            child: SettingsScreen(
              theme: ThemeController(),
              state: const SettingsState(section: SettingsSection.aiFeatures),
              onStateChanged: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // What a person with no provider sees: a form to set one up.
    expect(find.text('Test and save'), findsOneWidget);
    expect(find.text('OpenRouter'), findsOneWidget);
    // And none of the demo data that used to stand in for it.
    expect(find.textContaining('Granted'), findsNothing);
    expect(find.textContaining('Key saved'), findsNothing);
    expect(find.textContaining('192.168.1.24'), findsNothing);
  });

  testWidgets('the phone layout has no crash-report switch', (tester) async {
    DeviceKind.debugSetTelevision(false);
    // Tall enough for the whole list: it builds lazily, and Privacy and data is
    // near the bottom, below Metadata and AI features.
    tester.view.physicalSize = const Size(390, 12000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        // The phone layout renders Sources inline, and the real controller
        // would reach for secure storage.
        overrides: [
          plexSessionProvider.overrideWith(_SignedOut.new),
          playbackPrefsProvider.overrideWith(_Prefs.new),
        ],
        child: MaterialApp(
          home: RelayTheme(
            tokens: RelayPalettes.midnight,
            palette: RelayPalette.midnight,
            child: SettingsScreen(
              theme: ThemeController(),
              state: const SettingsState(),
              onStateChanged: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Control: the finder is looking at a rendered phone Settings.
    expect(find.text('No Plex servers connected.'), findsOneWidget);
    expect(find.text('Send crash reports'), findsNothing);
    // The section is there, with its real control and not the old switch. The
    // phone layout upper-cases section titles, so the old check that this title
    // was absent could not have failed whatever the layout contained.
    expect(find.text('PRIVACY AND DATA'), findsOneWidget);
    expect(find.text('Clear cached data'), findsOneWidget);
  });

  testWidgets('Playback and Subtitles change what the player will read', (
    tester,
  ) async {
    DeviceKind.debugSetTelevision(false);
    tester.view.physicalSize = const Size(390, 3200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final container = ProviderContainer(
      overrides: [
        plexSessionProvider.overrideWith(_SignedOut.new),
        playbackPrefsProvider.overrideWith(_Prefs.new),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: RelayTheme(
            tokens: RelayPalettes.midnight,
            palette: RelayPalette.midnight,
            child: SettingsScreen(
              theme: ThemeController(),
              state: const SettingsState(),
              onStateChanged: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('30 s'));
    await tester.tap(find.text('Show subtitles'));
    await tester.tap(find.text('Large'));
    await tester.pump();

    final prefs = container.read(playbackPrefsProvider);
    expect(prefs.skipSeconds, 30);
    expect(prefs.subtitlesOn, isTrue);
    expect(prefs.subtitleSize, SubtitleSize.large);
  });

  testWidgets('About shows the running version and the licences entry', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.text('About'));
    await tester.pumpAndSettle();

    expect(find.text('Version 1.0.0 (42)'), findsOneWidget);
    expect(find.textContaining('We host no content'), findsOneWidget);
    expect(find.text('Open-source licences'), findsOneWidget);
  });
}

class _SignedOut extends PlexSessionController {
  @override
  PlexState build() => const PlexState(stage: PlexStage.signedOut);
}

/// In memory: the real controller writes to the Hive-backed settings store.
class _Prefs extends PlaybackPrefsController {
  @override
  PlaybackPrefs build() => const PlaybackPrefs();

  @override
  Future<void> update(PlaybackPrefs next) async => state = next;
}

/// No provider configured, without reaching for the settings box.
class _NoAi extends AiSetupController {
  @override
  Future<AiSetup?> build() async => null;
}
