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

/// Guards the release-build Settings against unbuilt sections.
///
/// Until 2026-09-21 the TV/desktop layout opened on AI features, whose pane was
/// the design canvas's demo data: a "saved" OpenAI key and consent rows
/// "granted" on dates nobody chose. It looked finished, so nothing about the
/// code reading correctly would have caught it coming back; this does.
///
/// AI features was built for real on 2026-10-09, so Privacy and data is now the
/// section that stands in for "unbuilt" here, and a separate test pins that the
/// AI pane is real controls and never the old demo rows.
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
    await tester.pumpWidget(MaterialApp(
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
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('the TV layout lists only built sections, and opens on one',
      (tester) async {
    await pump(tester);

    // Hidden 2026-09-22: its one switch sent nothing anywhere.
    expect(find.text('Privacy and data'), findsNothing);
    expect(find.textContaining('Granted'), findsNothing);
    expect(find.textContaining('Not implemented'), findsNothing);
    // Built 2026-10-09, so listed now.
    expect(find.text('AI features'), findsOneWidget);
    expect(find.text('Metadata'), findsOneWidget);
    // Built 2026-09-23, so listed now.
    expect(find.text('Playback'), findsOneWidget);
    expect(find.text('Subtitles'), findsOneWidget);
    // Opens on Appearance, not on whatever the enum lists first.
    expect(find.text('Theme'), findsOneWidget);
    expect(find.text('About'), findsOneWidget);
  });

  testWidgets('a state pointing at an unbuilt section still renders a built one',
      (tester) async {
    await pump(
        tester, state: const SettingsState(section: SettingsSection.privacy));

    // Not the unbuilt section's own content, and the section it falls back to.
    expect(find.text('Send crash reports'), findsNothing);
    expect(find.text('Theme'), findsOneWidget);
  });

  testWidgets('AI features is real controls, never the old demo rows',
      (tester) async {
    tester.view.physicalSize = const Size(960, 540);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(ProviderScope(
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
    ));
    await tester.pumpAndSettle();

    // What a person with no provider sees: a form to set one up.
    expect(find.text('Test and save'), findsOneWidget);
    expect(find.text('OpenRouter'), findsOneWidget);
    // And none of the demo data that used to stand in for it.
    expect(find.textContaining('Granted'), findsNothing);
    expect(find.textContaining('Key saved'), findsNothing);
    expect(find.textContaining('192.168.1.24'), findsNothing);
  });

  // The control. Without it the two tests above would pass just as happily if
  // the finders were looking in the wrong place.
  testWidgets('the gallery still reaches the unbuilt sections', (tester) async {
    await pump(tester,
        state: const SettingsState(section: SettingsSection.privacy),
        showUnbuiltSections: true);

    expect(find.text('Privacy and data'), findsWidgets);
    expect(find.text('Send crash reports'), findsOneWidget);
    expect(find.text('Playback'), findsOneWidget);
  });

  testWidgets('the phone layout has no crash-report switch', (tester) async {
    DeviceKind.debugSetTelevision(false);
    tester.view.physicalSize = const Size(390, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(ProviderScope(
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
    ));
    await tester.pumpAndSettle();

    // Control: the finder is looking at a rendered phone Settings.
    expect(find.text('No Plex servers connected.'), findsOneWidget);
    expect(find.text('Send crash reports'), findsNothing);
    expect(find.text('Privacy and data'), findsNothing);
  });

  testWidgets('Playback and Subtitles change what the player will read',
      (tester) async {
    DeviceKind.debugSetTelevision(false);
    tester.view.physicalSize = const Size(390, 3200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final container = ProviderContainer(overrides: [
      plexSessionProvider.overrideWith(_SignedOut.new),
      playbackPrefsProvider.overrideWith(_Prefs.new),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
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
    ));
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

  testWidgets('About shows the running version and the licences entry',
      (tester) async {
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
