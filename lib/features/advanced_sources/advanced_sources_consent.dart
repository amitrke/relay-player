import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/relay_theme.dart';
import '../../i18n/strings.g.dart';
import '../settings/settings_controller.dart';

/// The §8.2 acknowledgement. Separate from, and additional to, the general
/// onboarding disclaimer — this is a materially different consent moment, and
/// the wording is chosen to be specific rather than reassuring.
///
/// **One dialog, two ways in (2026-11-03).** It lived in settings_screen.dart
/// and was reachable only from the Settings switch, which Add source pointed
/// at with a sentence. That sent someone who had just said "I have an IPTV
/// subscription" away to Settings, through the dialog, and back again with
/// nothing telling them where to go next. §8.2 asks that the acknowledgement
/// is made *before* the subscription forms are reachable, not that it is made
/// in Settings, so Add source now opens this same dialog in place. The gate,
/// what it hides while off, and what it says are unchanged; only where it can
/// be opened from is new.
///
/// **Three points rather than three paragraphs.** The no-content and rights
/// sentences are word for word what they were (they are the store-policy
/// text, §1.3 and §8.4); each gains a short heading so the dialog can be read
/// at a glance, and a third point says where the login is kept, which is the
/// question people actually ask at this moment. The headings and that third
/// point are new consent text: README.md in lib/i18n asks for the drafts of
/// `settings.advanced.*` to be read for meaning, and that now includes them.
Future<bool?> showAdvancedSourcesDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (context) {
      final t = RelayTheme.of(context);
      return AlertDialog(
        backgroundColor: t.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          tr.settings.advanced.dialogTitle,
          style: TextStyle(
            color: t.ink,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        // Scrolls: at a large text scale on a 540 dp TV the three points are
        // taller than the dialog may be, and an AlertDialog's content does not
        // scroll by itself.
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr.settings.advanced.dialogLead,
                style: TextStyle(color: t.ink, fontSize: 14, height: 1.55),
              ),
              const SizedBox(height: 16),
              _Point(
                icon: Icons.block_outlined,
                title: tr.settings.advanced.pointNoContent,
                body: tr.settings.advanced.dialogNoContent,
              ),
              const SizedBox(height: 14),
              _Point(
                icon: Icons.shield_outlined,
                title: tr.settings.advanced.pointRights,
                body: tr.settings.advanced.dialogRights,
              ),
              const SizedBox(height: 14),
              _Point(
                icon: Icons.lock_outline,
                title: tr.settings.advanced.pointLogin,
                body: tr.settings.advanced.dialogLogin,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(foregroundColor: t.inkDim),
            child: Text(tr.common.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: t.accent,
              foregroundColor: t.accentInk,
            ),
            child: Text(tr.settings.advanced.dialogConfirm),
          ),
        ],
      );
    },
  );
}

/// Shows the acknowledgement and, if it is accepted, turns the gate on.
/// Returns whether the gate is on afterwards.
///
/// For callers that are not Settings (Add source): Settings keeps its own
/// [SettingsState] in hand and goes through `setAdvancedSources`, which shows
/// the same dialog. Already on is answered without asking again, since the
/// acknowledgement was made once and turning off and on again asks anew.
Future<bool> turnOnAdvancedSources(BuildContext context, WidgetRef ref) async {
  if (ref.read(advancedSourcesEnabledProvider)) return true;
  final accepted = await showAdvancedSourcesDialog(context);
  if (accepted != true) return false;
  final settings = ref.read(settingsProvider.notifier);
  settings.update(
    ref.read(settingsProvider).copyWith(advancedSourcesEnabled: true),
  );
  return true;
}

class _Point extends StatelessWidget {
  const _Point({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: t.accent),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: t.ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                body,
                style: TextStyle(color: t.inkDim, fontSize: 13, height: 1.55),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
