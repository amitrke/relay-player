import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';

import 'features/_spike/spike_app.dart';

/// Entry point.
///
/// The app is in Phase 0 (see docs/architecture.md S13): the real UI does not
/// exist yet, so debug builds boot straight into the spike harness. Release
/// builds get a deliberate placeholder -- the spike must never ship, and
/// gating on [kDebugMode] means it cannot, even by accident.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  runApp(kDebugMode ? const SpikeApp() : const _NotShippableYet());
}

class _NotShippableYet extends StatelessWidget {
  const _NotShippableYet();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Relay Player',
      theme: ThemeData.dark(useMaterial3: true),
      home: const Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Relay Player is in Phase 0 validation.\n'
              'There is no release build yet.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
