import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:relay_player/core/platform/device_kind.dart';
import 'package:relay_player/core/theme/relay_theme.dart';
import 'package:relay_player/core/theme/relay_tokens.dart';
import 'package:relay_player/features/onboarding/onboarding_route.dart';
import 'package:relay_player/features/settings/settings_controller.dart';
import 'package:relay_player/features/settings/settings_screen.dart';
import 'package:relay_player/i18n/strings.g.dart';

/// §8.2's acknowledgement, opened from Add source (2026-11-03,
/// advanced_sources_consent.dart). What must hold: while the gate is off the
/// screen offers no subscription form, only the button; declining changes
/// nothing; accepting turns the gate on and goes straight to the form.
void main() {
  Future<ProviderContainer> pump(WidgetTester tester, {required Size size}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final c = ProviderContainer(
      overrides: [settingsProvider.overrideWith(_InMemorySettings.new)],
    );
    addTearDown(c.dispose);

    final router = GoRouter(
      initialLocation: '/add-source',
      routes: [
        GoRoute(path: '/add-source', builder: (_, _) => const AddSourceRoute()),
        GoRoute(
          path: '/advanced/xtream/new',
          builder: (_, _) => const Text('subscription form'),
        ),
      ],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: MaterialApp.router(
          routerConfig: router,
          builder: (_, child) => RelayTheme(
            tokens: RelayPalettes.midnight,
            palette: RelayPalette.midnight,
            child: child!,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return c;
  }

  for (final (label, size) in [
    ('phone', const Size(390, 1600)),
    ('desktop rail', const Size(1400, 900)),
  ]) {
    testWidgets('$label: declining leaves the gate shut, accepting opens it '
        'and goes to the form', (tester) async {
      DeviceKind.debugSetTelevision(false);
      final c = await pump(tester, size: size);

      // Off: no subscription entry, only the way in.
      expect(find.text(tr.addSource.kind.xtream), findsNothing);
      expect(find.text(tr.addSource.advancedSetUp), findsOneWidget);

      await tester.tap(find.text(tr.addSource.advancedSetUp));
      await tester.pumpAndSettle();
      // The same acknowledgement Settings shows, its store-policy sentences
      // unchanged.
      expect(find.text(tr.settings.advanced.dialogNoContent), findsOneWidget);
      expect(find.text(tr.settings.advanced.dialogRights), findsOneWidget);

      await tester.tap(find.text(tr.common.cancel));
      await tester.pumpAndSettle();
      expect(c.read(advancedSourcesEnabledProvider), isFalse);
      expect(find.text('subscription form'), findsNothing);

      await tester.tap(find.text(tr.addSource.advancedSetUp));
      await tester.pumpAndSettle();
      await tester.tap(find.text(tr.settings.advanced.dialogConfirm));
      await tester.pumpAndSettle();
      expect(c.read(advancedSourcesEnabledProvider), isTrue);
      expect(find.text('subscription form'), findsOneWidget);
    });
  }
}

/// The real controller writes through to Hive, whose writes do not finish on
/// a widget test's fake clock; what is kept between launches is not this
/// test's concern.
class _InMemorySettings extends SettingsController {
  @override
  SettingsState build() => const SettingsState();

  @override
  void update(SettingsState next) => state = next;
}
