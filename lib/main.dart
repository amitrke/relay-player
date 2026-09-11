import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';

import 'core/routing/app_router.dart';
import 'core/theme/theme_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  runApp(const ProviderScope(child: RelayPlayerApp()));
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
