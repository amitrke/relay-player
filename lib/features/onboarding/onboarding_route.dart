import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../accounts/add_source_screen.dart';
import '../settings/settings_controller.dart';
import 'onboarding_screen.dart';

/// First run (§12 screen 1).
///
/// General framing only: Plex, local files and network shares are peers here,
/// and none of them is required to get into the app. Skipping is a first-class
/// outcome — an empty library the user can add to beats a setup screen they
/// cannot get past.
class OnboardingRoute extends ConsumerWidget {
  const OnboardingRoute({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Future<void> finish(String destination) async {
      await ref.read(onboardingSeenProvider.notifier).markSeen();
      if (context.mounted) context.go(destination);
    }

    return OnboardingScreen(
      onAddSource: () => finish('/add-source'),
      onSkip: () => finish('/library'),
    );
  }
}

/// Add source (§12 screen 2).
///
/// Plex and Local & Network are always offered; the Xtream/M3U/profile entries
/// appear only behind the §8.2 gate, which is why this reads the flag rather
/// than listing everything and disabling some.
class AddSourceRoute extends ConsumerWidget {
  const AddSourceRoute({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AddSourceScreen(
      advancedEnabled: ref.watch(advancedSourcesEnabledProvider),
      onBack: () => context.canPop() ? context.pop() : context.go('/library'),
      onOpenSettings: () => context.go('/settings'),
      onPickSource: (kind) => _open(context, kind),
    );
  }

  void _open(BuildContext context, SourceKind kind) {
    switch (kind) {
      case SourceKind.plex:
        context.push('/link');
      case SourceKind.localFiles:
        // The Local & Network tab owns the permission prompt, so send the user
        // there rather than asking for access from a screen they are leaving.
        context.go('/library?tab=local');
      case SourceKind.xtream:
        context.push('/advanced/xtream/new');
      case SourceKind.smb:
      case SourceKind.m3u:
      case SourceKind.providerProfile:
        _notYet(context, kind);
    }
  }

  /// Says plainly that something is not built yet, rather than opening a screen
  /// that silently does nothing.
  void _notYet(BuildContext context, SourceKind kind) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${kind.title} is not available in this build.')),
    );
  }
}
