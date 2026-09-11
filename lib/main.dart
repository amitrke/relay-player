import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';

import 'core/theme/theme_controller.dart';
import 'features/_gallery/design_gallery.dart';
import 'features/_spike/spike_app.dart';

/// Entry point.
///
/// The app is mid-build: Phase 0 validation (docs/PHASE0_FINDINGS.md) is still
/// open, and the screens from `design/` are being implemented against the
/// design canvas. Debug builds therefore boot into a chooser for the two
/// in-progress surfaces; release builds get a deliberate placeholder, because
/// neither the spike nor the gallery may ever ship.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  runApp(kDebugMode ? const _DebugApp() : const _NotShippableYet());
}

class _DebugApp extends StatefulWidget {
  const _DebugApp();

  @override
  State<_DebugApp> createState() => _DebugAppState();
}

class _DebugAppState extends State<_DebugApp> {
  final _theme = ThemeController();
  bool _showSpike = false;

  @override
  void dispose() {
    _theme.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_showSpike) return const SpikeApp();

    return RelayApp(
      controller: _theme,
      builder: (context) => Stack(
        children: [
          DesignGallery(controller: _theme),
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton.extended(
              onPressed: () => setState(() => _showSpike = true),
              icon: const Icon(Icons.science_outlined),
              label: const Text('Phase 0 spike'),
            ),
          ),
        ],
      ),
    );
  }
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
              'Relay Player is still in development.\n'
              'There is no release build yet.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
