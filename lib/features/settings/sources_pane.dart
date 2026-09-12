import 'dart:async';

import 'package:dart_plex/dart_plex.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/relay_theme.dart';
import '../accounts/plex_session.dart';
import '../library/library_mapping.dart';
import '../library/library_screen.dart';
import 'settings_controller.dart';

/// Settings → Sources (§12.1): every connected Plex server, and what each of
/// its libraries feeds.
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
    final state = ref.watch(plexSessionProvider);

    // A Column, not a ListView: both Settings layouts already scroll, and
    // nesting a second scrollable inside them fights for the gesture.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final server in state.servers) ...[
          _ServerBlock(server: server),
          const SizedBox(height: 22),
        ],
        if (state.servers.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              'No Plex servers connected.',
              style: TextStyle(color: t.inkDim, fontSize: 13),
            ),
          ),
        const _AddServer(),
      ],
    );
  }
}

class _ServerBlock extends ConsumerWidget {
  const _ServerBlock({required this.server});

  final ConnectedServer server;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = RelayTheme.of(context);
    final sections = ref.watch(plexSectionsProvider(server.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.dns_outlined, color: t.inkDim, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                server.name,
                style: TextStyle(
                  color: t.ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () => ref
                  .read(plexSessionProvider.notifier)
                  .disconnect(server.id),
              child: Text('Remove', style: TextStyle(color: t.inkDim)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        sections.when(
          loading: () => Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator(color: t.accent)),
          ),
          // A server that cannot be reached is a normal state here, not a
          // crash: it says so and offers a retry, rather than printing an
          // exception at the user.
          error: (e, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                e is TimeoutException && e.message != null
                    ? e.message!
                    : 'Could not load libraries from this server.\n\n$e',
                style: TextStyle(color: t.inkDim, fontSize: 13, height: 1.45),
              ),
              const SizedBox(height: 6),
              TextButton(
                onPressed: () =>
                    ref.invalidate(plexSectionsProvider(server.id)),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 36),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text('Try again', style: TextStyle(color: t.accent)),
              ),
            ],
          ),
          data: (list) => Column(
            children: [
              for (final section in list)
                _LibraryRow(serverId: server.id, section: section),
            ],
          ),
        ),
      ],
    );
  }
}

/// Offers any server the account can reach that is not already connected.
class _AddServer extends ConsumerWidget {
  const _AddServer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = RelayTheme.of(context);
    final state = ref.watch(plexSessionProvider);
    final connectable = state.connectable;

    if (connectable.isEmpty) {
      return TextButton.icon(
        onPressed: () =>
            ref.read(plexSessionProvider.notifier).refreshAvailable(),
        icon: Icon(Icons.refresh, size: 18, color: t.inkDim),
        label: Text(
          'Look for more servers',
          style: TextStyle(color: t.inkDim),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Add another server',
          style: TextStyle(
            color: t.ink,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        for (final resource in connectable)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: t.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: t.line),
            ),
            child: ListTile(
              title: Text(
                resource.name,
                style: TextStyle(color: t.ink, fontSize: 14.5),
              ),
              subtitle: Text(
                [
                  if (resource.owned) 'Yours' else 'Shared with you',
                  if (resource.relay) 'via relay',
                ].join(' · '),
                style: TextStyle(color: t.inkDim, fontSize: 12),
              ),
              trailing: Icon(Icons.add, color: t.accent),
              onTap: () =>
                  ref.read(plexSessionProvider.notifier).connect(resource),
            ),
          ),
      ],
    );
  }
}

class _LibraryRow extends ConsumerWidget {
  const _LibraryRow({required this.serverId, required this.section});

  final String serverId;
  final PlexLibrarySection section;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = RelayTheme.of(context);
    final mapping = ref.watch(libraryMappingProvider);
    final placement = mapping.placementOf(serverId, section);

    // Three chips beside the name is a tablet layout. On a phone the chips are
    // not flexible and the name is, so the chips take the width they want and
    // the name gets whatever is left — about a third of the row, which wraps a
    // name like "English TV Shows" onto three lines and clips it outright once
    // the system font is scaled up. Stack them instead, which costs a little
    // height and gives the name the full width.
    //
    // Text scale matters as much as form factor here: a tablet at 1.3x hits the
    // same wall, so this keys off both rather than assuming phones are the only
    // narrow case.
    final stacked = RelayLayout.of(context) == RelayFormFactor.phone ||
        MediaQuery.textScalerOf(context).scale(14) > 16;

    final name = Column(
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
            if (mapping.isOverridden(serverId, section)) 'changed by you',
          ].join(' · '),
          style: TextStyle(color: t.inkDim, fontSize: 12),
        ),
      ],
    );

    final chips = _PlacementChips(
      selected: placement,
      onSelect: (next) => ref
          .read(libraryMappingProvider.notifier)
          .setPlacement(serverId, section, next),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: t.line),
      ),
      child: stacked
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: double.infinity, child: name),
                const SizedBox(height: 10),
                chips,
              ],
            )
          : Row(
              children: [
                Expanded(child: name),
                const SizedBox(width: 12),
                chips,
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
