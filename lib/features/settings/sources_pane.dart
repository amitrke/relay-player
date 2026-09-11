import 'package:dart_plex/dart_plex.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/relay_theme.dart';
import '../accounts/plex_session.dart';
import '../library/library_mapping.dart';
import '../library/library_screen.dart';
import 'settings_controller.dart';

/// Settings → Sources (§12.1): the connected server and what each of its
/// libraries feeds.
///
/// Plex's library type is only a guess at intent. A library typed `movie` may
/// hold course recordings or home video, and merging it into Movies while
/// discarding its name produces a tab its owner does not recognise. This is
/// where that gets corrected.
class SourcesPane extends ConsumerWidget {
  const SourcesPane({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = RelayTheme.of(context);
    final serverName = ref.watch(plexSessionProvider).serverName;
    final sections = ref.watch(plexSectionsProvider);

    // A Column, not a ListView: both Settings layouts already scroll, and
    // nesting a second scrollable inside them fights for the gesture.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.dns_outlined, color: t.inkDim, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                serverName ?? 'Plex',
                style: TextStyle(
                  color: t.ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () =>
                  ref.read(plexSessionProvider.notifier).signOut(),
              child: Text('Disconnect', style: TextStyle(color: t.inkDim)),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          'Libraries',
          style: TextStyle(
            color: t.ink,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Choose where each library appears. Plex’s own type is only the '
          'default — a library named for what it holds usually knows better.',
          style: TextStyle(color: t.inkDim, fontSize: 13, height: 1.5),
        ),
        const SizedBox(height: 14),
        sections.when(
          loading: () => Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator(color: t.accent)),
          ),
          error: (e, _) => Text(
            '$e',
            style: TextStyle(color: t.inkDim, fontSize: 13),
          ),
          data: (list) => Column(
            children: [
              for (final section in list) _LibraryRow(section: section),
            ],
          ),
        ),
      ],
    );
  }
}

class _LibraryRow extends ConsumerWidget {
  const _LibraryRow({required this.section});

  final PlexLibrarySection section;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = RelayTheme.of(context);
    final mapping = ref.watch(libraryMappingProvider);
    final placement = mapping.placementOf(section);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: t.line),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  section.title,
                  style: TextStyle(
                    color: t.ink,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  [
                    'Plex type: ${section.type.name}',
                    if (mapping.isOverridden(section)) 'changed by you',
                  ].join(' · '),
                  style: TextStyle(color: t.inkDim, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _PlacementChips(
            selected: placement,
            onSelect: (next) => ref
                .read(libraryMappingProvider.notifier)
                .setPlacement(section, next),
          ),
        ],
      ),
    );
  }
}

class _PlacementChips extends StatelessWidget {
  const _PlacementChips({required this.selected, required this.onSelect});

  final LibraryPlacement selected;
  final ValueChanged<LibraryPlacement> onSelect;

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);

    return Wrap(
      spacing: 6,
      children: [
        for (final placement in LibraryPlacement.values)
          GestureDetector(
            onTap: () => onSelect(placement),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: placement == selected ? t.accent : t.bg,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: placement == selected ? t.accent : t.line,
                ),
              ),
              child: Text(
                placement.label,
                style: TextStyle(
                  color: placement == selected ? t.accentInk : t.inkDim,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
