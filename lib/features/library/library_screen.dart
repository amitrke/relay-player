import 'package:dart_plex/dart_plex.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/relay_theme.dart';
import '../accounts/plex_session.dart';
import '../settings/settings_controller.dart';
import 'library_tab.dart';
import 'poster_grid.dart';

/// The server's video libraries. Shared by the tabs and by Settings → Sources,
/// so the mapping UI lists exactly what the tabs draw from.
final plexSectionsProvider = FutureProvider<List<PlexLibrarySection>>((ref) {
  return ref.watch(plexServiceProvider).sections();
});

final _libraryProvider =
    FutureProvider.family<List<PlexMetadata>, LibraryTab>((ref, tab) async {
  final sections = await ref.watch(plexSectionsProvider.future);
  final mapping = ref.watch(libraryMappingProvider);
  return ref
      .watch(plexServiceProvider)
      .itemsFrom(mapping.sectionsFor(tab, sections));
});

/// Home (§12 screen 3).
///
/// The tabs are content types, not Plex sections: §12 merges every Plex movie
/// library into Movies and every show library into Series. Local & Network
/// stays separate because a folder tree has no movie/series structure to merge
/// into, and Live TV exists only behind the §8.2 gate.
class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  LibraryTab _selected = LibraryTab.movies;

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);
    final f = RelayLayout.of(context);
    final tabs = LibraryTab.visible(
      advancedSources: ref.watch(advancedSourcesEnabledProvider),
    );

    // The gate can retract the tab the user is standing on (§15's kill-switch
    // drill checks exactly this), so fall back rather than render a dead tab.
    final selected = tabs.contains(_selected) ? _selected : LibraryTab.movies;
    final serverName = ref.watch(plexSessionProvider).serverName;

    return Scaffold(
      backgroundColor: t.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: RelayLayout.pagePadding(f).copyWith(top: 12, bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      'Library',
                      style: TextStyle(
                        color: t.ink,
                        fontSize: RelayLayout.titleSize(f) - 4,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (serverName != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        serverName,
                        style: TextStyle(color: t.inkDim, fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
            _TabBar(
              tabs: tabs,
              selected: selected,
              onSelect: (tab) => setState(() => _selected = tab),
            ),
            Expanded(child: _TabBody(tab: selected)),
          ],
        ),
      ),
    );
  }
}

class _TabBar extends StatelessWidget {
  const _TabBar({
    required this.tabs,
    required this.selected,
    required this.onSelect,
  });

  final List<LibraryTab> tabs;
  final LibraryTab selected;
  final ValueChanged<LibraryTab> onSelect;

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);
    final f = RelayLayout.of(context);

    return SizedBox(
      height: 46,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: RelayLayout.pagePadding(f).copyWith(top: 0, bottom: 0),
        children: [
          for (final tab in tabs)
            GestureDetector(
              onTap: () => onSelect(tab),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.only(right: 22),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Center(
                        child: Text(
                          tab.label,
                          style: TextStyle(
                            color: tab == selected ? t.ink : t.inkDim,
                            fontSize: RelayLayout.bodySize(f) + 1,
                            fontWeight: tab == selected
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      height: 2,
                      width: 100,
                      color:
                          tab == selected ? t.accent : Colors.transparent,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TabBody extends ConsumerWidget {
  const _TabBody({required this.tab});

  final LibraryTab tab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!tab.drawsFromPlex) {
      return LibraryEmptyState(
        icon: tab.emptyIcon,
        message: tab.emptyMessage,
      );
    }

    final items = ref.watch(_libraryProvider(tab));
    return items.when(
      loading: () => Center(
        child: CircularProgressIndicator(color: RelayTheme.of(context).accent),
      ),
      error: (e, _) => LibraryEmptyState(
        icon: Icons.cloud_off_outlined,
        message: '$e',
        onRetry: () => ref.invalidate(_libraryProvider(tab)),
      ),
      data: (list) => list.isEmpty
          ? LibraryEmptyState(
              icon: tab.emptyIcon,
              message: 'Nothing in ${tab.label.toLowerCase()} yet.',
            )
          : PosterGrid(items: list),
    );
  }
}
