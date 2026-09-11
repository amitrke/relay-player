import 'package:dart_plex/dart_plex.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/relay_theme.dart';
import '../../core/theme/relay_widgets.dart';
import '../accounts/plex_session.dart';
import 'poster_tile.dart';

final _sectionsProvider = FutureProvider<List<PlexLibrarySection>>((ref) {
  return ref.watch(plexServiceProvider).sections();
});

final _itemsProvider = FutureProvider.family<List<PlexMetadata>,
    PlexLibrarySection>((ref, section) {
  return ref.watch(plexServiceProvider).items(section);
});

/// Browse the connected server's video libraries (§6).
class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  PlexLibrarySection? _selected;

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);
    final f = RelayLayout.of(context);
    final sections = ref.watch(_sectionsProvider);
    final serverName = ref.watch(plexSessionProvider).serverName;

    return Scaffold(
      backgroundColor: t.bg,
      appBar: AppBar(
        backgroundColor: t.bg,
        surfaceTintColor: Colors.transparent,
        titleSpacing: RelayLayout.pagePadding(f).left,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Library',
              style: TextStyle(
                color: t.ink,
                fontSize: RelayLayout.titleSize(f) - 6,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (serverName != null)
              Text(
                serverName,
                style: TextStyle(color: t.inkDim, fontSize: 12),
              ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Disconnect',
            icon: Icon(Icons.logout, color: t.inkDim),
            onPressed: () => ref.read(plexSessionProvider.notifier).signOut(),
          ),
          SizedBox(width: RelayLayout.pagePadding(f).right - 12),
        ],
      ),
      body: sections.when(
        loading: () => Center(
          child: CircularProgressIndicator(color: t.accent),
        ),
        error: (e, _) => _Failure(
          message: '$e',
          onRetry: () => ref.invalidate(_sectionsProvider),
        ),
        data: (list) {
          if (list.isEmpty) {
            return const _Failure(
              message: 'This server has no movie or TV libraries.',
            );
          }
          final selected = _selected ?? list.first;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionTabs(
                sections: list,
                selected: selected,
                onSelect: (s) => setState(() => _selected = s),
              ),
              Expanded(child: _ItemGrid(section: selected)),
            ],
          );
        },
      ),
    );
  }
}

class _SectionTabs extends StatelessWidget {
  const _SectionTabs({
    required this.sections,
    required this.selected,
    required this.onSelect,
  });

  final List<PlexLibrarySection> sections;
  final PlexLibrarySection selected;
  final ValueChanged<PlexLibrarySection> onSelect;

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);
    final f = RelayLayout.of(context);

    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: RelayLayout.pagePadding(f).copyWith(top: 0, bottom: 0),
        itemCount: sections.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final section = sections[i];
          final isSelected = section.id == selected.id;
          return Center(
            child: GestureDetector(
              onTap: () => onSelect(section),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? t.accent : t.surface,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: isSelected ? t.accent : t.line),
                ),
                child: Text(
                  section.title,
                  style: TextStyle(
                    color: isSelected ? t.accentInk : t.inkDim,
                    fontSize: RelayLayout.bodySize(f),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ItemGrid extends ConsumerWidget {
  const _ItemGrid({required this.section});

  final PlexLibrarySection section;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = RelayTheme.of(context);
    final f = RelayLayout.of(context);
    final items = ref.watch(_itemsProvider(section));

    return items.when(
      loading: () => Center(child: CircularProgressIndicator(color: t.accent)),
      error: (e, _) => _Failure(
        message: '$e',
        onRetry: () => ref.invalidate(_itemsProvider(section)),
      ),
      data: (list) {
        if (list.isEmpty) {
          return const _Failure(message: 'Nothing in this library yet.');
        }
        final columns = switch (f) {
          RelayFormFactor.phone => 3,
          RelayFormFactor.tablet => 5,
          RelayFormFactor.desktop => 6,
          RelayFormFactor.tv => 7,
        };
        return GridView.builder(
          padding: RelayLayout.pagePadding(f).copyWith(top: 12, bottom: 32),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            childAspectRatio: 0.52,
            crossAxisSpacing: 12,
            mainAxisSpacing: 16,
          ),
          itemCount: list.length,
          itemBuilder: (context, i) => PosterTile(item: list[i]),
        );
      },
    );
  }
}

class _Failure extends StatelessWidget {
  const _Failure({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined, color: t.inkDim, size: 34),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: t.inkDim, height: 1.5),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 18),
              RelayButton(label: 'Try again', onPressed: onRetry),
            ],
          ],
        ),
      ),
    );
  }
}
