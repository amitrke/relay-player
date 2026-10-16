import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ce/hive.dart';
import 'package:relay_player/core/platform/device_kind.dart';
import 'package:relay_player/core/theme/relay_theme.dart';
import 'package:relay_player/core/theme/relay_tokens.dart';
import 'package:relay_player/data/local/app_settings_store.dart';
import 'package:relay_player/features/library/library_tab.dart';
import 'package:relay_player/features/onboarding/onboarding_route.dart';
import 'package:relay_player/features/settings/settings_controller.dart';

/// Local & Network is on Home only once it is used (§12 screen 3, from
/// 2026-10-16). Before that it was always there, so the risk in the change is
/// someone who plays device files losing the tab on update; the first two
/// tests are about that.
void main() {
  late AppSettingsStore store;

  setUp(() async {
    final dir = Directory.systemTemp.createTempSync('relay_local_tab_test');
    addTearDown(() async {
      await Hive.close();
      try {
        dir.deleteSync(recursive: true);
      } catch (_) {}
    });
    Hive.init(dir.path);
    store = AppSettingsStore.withBox(await Hive.openBox<dynamic>('t'));
  });

  ProviderContainer container() {
    final c = ProviderContainer(
      overrides: [appSettingsStoreProvider.overrideWithValue(store)],
    );
    addTearDown(c.dispose);
    return c;
  }

  test('an install already past first run keeps the tab it always had', () {
    store.setBool('onboardingSeen', true);
    expect(container().read(localNetworkTabProvider), isTrue);
  });

  test('a new install starts without it, and finishing first run later does '
      'not bring it back', () async {
    expect(container().read(localNetworkTabProvider), isFalse);
    // The first read decided and wrote it down, so the migration rule above
    // cannot fire on the next launch for someone who has just been onboarded.
    await store.setBool('onboardingSeen', true);
    expect(container().read(localNetworkTabProvider), isFalse);
  });

  test('the switch is kept between launches, both ways', () async {
    store.setBool('onboardingSeen', true);
    await container().read(localNetworkTabProvider.notifier).set(false);
    expect(container().read(localNetworkTabProvider), isFalse);
    await container().read(localNetworkTabProvider.notifier).set(true);
    expect(container().read(localNetworkTabProvider), isTrue);
  });

  test('the tab strip follows it', () {
    expect(LibraryTab.visible(advancedSources: false, localNetwork: false), [
      LibraryTab.movies,
      LibraryTab.series,
    ]);
    expect(LibraryTab.visible(advancedSources: true, localNetwork: true), [
      LibraryTab.movies,
      LibraryTab.series,
      LibraryTab.localNetwork,
      LibraryTab.liveTv,
    ]);
  });

  testWidgets('picking a network share in Add source turns the tab on before '
      'going there', (tester) async {
    DeviceKind.debugSetTelevision(false);
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    // In memory: a Hive write does not finish on the widget test's fake
    // clock, and keeping the value is the unit tests' job above. This one
    // pins the order, tab first and then the screen.
    final c = ProviderContainer(
      overrides: [
        appSettingsStoreProvider.overrideWithValue(store),
        localNetworkTabProvider.overrideWith(_InMemory.new),
      ],
    );
    addTearDown(c.dispose);
    expect(c.read(localNetworkTabProvider), isFalse);

    final router = GoRouter(
      initialLocation: '/add-source',
      routes: [
        GoRoute(path: '/add-source', builder: (_, _) => const AddSourceRoute()),
        GoRoute(
          path: '/smb/new',
          builder: (_, _) => Consumer(
            builder: (_, ref, _) =>
                Text('smb form, tab ${ref.read(localNetworkTabProvider)}'),
          ),
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

    await tester.tap(find.text('Network share (SMB)'));
    await tester.pumpAndSettle();
    expect(find.text('smb form, tab true'), findsOneWidget);
  });
}

class _InMemory extends LocalNetworkTabController {
  @override
  bool build() => false;

  @override
  Future<void> set(bool shown) async => state = shown;
}
