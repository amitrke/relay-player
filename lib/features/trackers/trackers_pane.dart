import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/relay_theme.dart';
import '../../core/theme/relay_widgets.dart';
import '../../data/trackers/tracker.dart';
import '../../i18n/strings.g.dart';
import 'trackers_controller.dart';

/// Settings → Watch tracking (§19). Only the trackers this build has
/// credentials for are listed; with none, the section is not shown at all.
class TrackersPane extends ConsumerWidget {
  const TrackersPane({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = RelayTheme.of(context);
    final kinds = ref.watch(availableTrackersProvider);
    final state = ref.watch(trackersProvider);
    final style = TextStyle(color: t.inkDim, fontSize: 13.5, height: 1.6);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(tr.trackers.intro, style: style),
        if (kinds.any((k) => k.animeOnly)) ...[
          const SizedBox(height: 8),
          Text(tr.trackers.animeNote, style: style),
        ],
        const SizedBox(height: 18),
        for (final kind in kinds) ...[
          _TrackerRow(kind: kind, token: state.tokens[kind]),
          const SizedBox(height: 10),
        ],
        if (state.pending > 0) ...[
          const SizedBox(height: 6),
          Text(
            tr.trackers.pending(n: state.pending),
            style: TextStyle(color: t.inkDim, fontSize: 12.5),
          ),
        ],
      ],
    );
  }
}

class _TrackerRow extends ConsumerWidget {
  const _TrackerRow({required this.kind, required this.token});

  final TrackerKind kind;
  final TrackerToken? token;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = RelayTheme.of(context);
    final signedIn = token != null;
    final name = token?.userName;
    return RelaySurface(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  kind.label,
                  style: TextStyle(
                    color: t.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  !signedIn
                      ? tr.trackers.notConnected
                      : (name == null || name.isEmpty)
                      ? tr.trackers.signedIn
                      : tr.trackers.signedInAs(name: name),
                  style: TextStyle(
                    color: signedIn ? t.accent : t.inkDim,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          RelayTextButton(
            label: signedIn ? tr.trackers.signOut : tr.trackers.signIn,
            onPressed: () async {
              if (signedIn) {
                await ref.read(trackersProvider.notifier).signOut(kind);
              } else if (await confirmTrackerConsent(context, kind)) {
                if (context.mounted) {
                  await context.push('/trackers/${kind.name}');
                }
              }
            },
          ),
        ],
      ),
    );
  }
}

/// What the person agrees to before signing in (§19.1), worded per tracker.
/// The safe answer has focus, so a stray press on a remote declines.
Future<bool> confirmTrackerConsent(
  BuildContext context,
  TrackerKind kind,
) async {
  final t = RelayTheme.of(context);
  final yes = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: t.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: Text(
        tr.trackers.consentTitle(service: kind.label),
        style: TextStyle(
          color: t.ink,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: Text(
        [
          tr.trackers.consentBody(service: kind.label),
          if (kind.animeOnly) tr.trackers.consentAnime(service: kind.label),
        ].join('\n\n'),
        style: TextStyle(color: t.inkDim, fontSize: 14, height: 1.55),
      ),
      actions: [
        TextButton(
          autofocus: true,
          onPressed: () => Navigator.pop(context, false),
          style: TextButton.styleFrom(foregroundColor: t.inkDim),
          child: Text(tr.trackers.notNow),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(
            backgroundColor: t.accent,
            foregroundColor: t.accentInk,
          ),
          child: Text(tr.trackers.agree),
        ),
      ],
    ),
  );
  return yes == true;
}
