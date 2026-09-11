import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';

import 'core/routing/app_router.dart';
import 'core/theme/theme_controller.dart';
import 'data/local/app_settings_store.dart';
import 'features/settings/settings_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  // Opened before the first frame so settings read synchronously afterwards.
  // Otherwise the app renders its defaults and then visibly corrects itself —
  // the Advanced Sources gate would flicker a tab into existence on every
  // launch.
  final settings = await AppSettingsStore.open();

  runApp(
    ProviderScope(
      overrides: [appSettingsStoreProvider.overrideWithValue(settings)],
      child: const RelayPlayerApp(),
    ),
  );
}

class RelayPlayerApp extends ConsumerWidget {
  const RelayPlayerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RelayApp(
      controller: ref.watch(themeControllerProvider),
      routerConfig: ref.watch(routerProvider),
    );
  }
}
