import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/relay_theme.dart';
import '../../core/theme/relay_widgets.dart';

/// Debug-only way back into the two surfaces the real app no longer boots into.
///
/// Reached by long-pressing the mark on the sign-in screen. Both destinations
/// are development scaffolding that must never ship, so the routes here are
/// registered behind a `kDebugMode` guard in `core/routing/app_router.dart`.
class DebugMenuScreen extends StatelessWidget {
  const DebugMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);

    return Scaffold(
      backgroundColor: t.bg,
      appBar: AppBar(
        backgroundColor: t.bg,
        surfaceTintColor: Colors.transparent,
        foregroundColor: t.ink,
        title: const Text('Developer tools'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _Entry(
            icon: Icons.science_outlined,
            title: 'Phase 0 spike',
            subtitle: 'Probe harness. Still needed for the Plex transcode '
                'lifecycle and the Q5 Android-device questions.',
            onTap: () => context.push('/debug/spike'),
          ),
          const SizedBox(height: 12),
          _Entry(
            icon: Icons.palette_outlined,
            title: 'Design gallery',
            subtitle: 'The artboards from design/, rendered at their canvas '
                'sizes.',
            onTap: () => context.push('/debug/gallery'),
          ),
        ],
      ),
    );
  }
}

class _Entry extends StatelessWidget {
  const _Entry({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);

    return RelaySurface(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: t.accent, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: t.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: t.inkDim,
                    fontSize: 12.5,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
