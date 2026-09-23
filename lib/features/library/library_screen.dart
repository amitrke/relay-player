import 'dart:async';

import 'package:dart_plex/dart_plex.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/relay_theme.dart';
import '../../core/theme/relay_widgets.dart';
import '../../data/xtream/xtream_account_store.dart';
import '../../domain/models/catalog_item.dart';
import '../advanced_sources/xtream_controller.dart';
import '../accounts/plex_session.dart';
import '../settings/settings_controller.dart';
import '../favorites_history/continue_watching_row.dart';
import '../live_tv/live_tv_tab.dart';
import '../local_network/local_network_tab.dart';
import 'library_sort.dart';
import 'library_tab.dart';
import 'poster_grid.dart';

/// One server's video libraries. Shared by the tabs and by Settings → Sources,
/// so the mapping UI lists exactly what the tabs draw from.
final plexSectionsProvider =
    FutureProvider.family<List<PlexLibrarySection>, String>(
        (ref, serverId) async {
  final servers = ref.watch(connectedServersProvider);
  for (final server in servers) {
    if (server.id == serverId) {
      // The timeout belongs here, not at each call site. It used to be applied
      // only where the library tabs merge sources, which left Settings →
      // Sources — the one screen that watches this provider directly — spinning
      // forever on a server that hangs instead of failing. That is the normal
      // behaviour of a sleeping NAS or a dead relay connection, not an edge
      // case, and it made adding a second server look like it never completed.
      return server.service.sections().timeout(
            _perServerTimeout,
            onTimeout: () => throw TimeoutException(
              '${server.name} did not respond within '
              '${_perServerTimeout.inSeconds} seconds. It may be asleep or off '
              'the network.',
            ),
          );
    }
  }
  return const [];
});

/// How long one server gets before the rest of the library goes on without it.
///
/// A try/catch is not enough on its own: an unreachable server does not fail
/// fast, it hangs, and `Future.wait` waits for the slowest member. Without this
/// a single sleeping NAS leaves every tab spinning forever — observed with a
/// relay-connected server that never answered.
const _perServerTimeout = Duration(seconds: 10);

/// Everything feeding [tab], merged across every connected server.
///
/// §12 screen 3: "Movies/Series merge across Plex accounts". One server failing
/// or stalling must not blank the tab — it should cost you its own titles, not
/// everyone else's.
final _libraryProvider =
    FutureProvider.family<List<CatalogItem>, LibraryTab>((ref, tab) async {
  final servers = ref.watch(connectedServersProvider);
  final mapping = ref.watch(libraryMappingProvider);

  final perSource = <Future<List<CatalogItem>>>[
    for (final server in servers)
      () async {
        try {
          final sections =
              await ref.watch(plexSectionsProvider(server.id).future);
          final items = await server.service
              .itemsFrom(mapping.sectionsFor(tab, server.id, sections));
          return [
            for (final i in items) server.service.toCatalogItem(i.metadata),
          ];
        } catch (_) {
          return const <CatalogItem>[];
        }
      }(),

    // Panel catalogues merge into the same tabs: a VOD title is a movie and a
    // panel series is a series, so splitting them out would make the user
    // remember which source something came from in order to find it.
    for (final account in ref.watch(xtreamAccountsProvider))
      if (_catalogueFor(tab) case final catalogue?)
        () async {
          try {
            return await ref
                .watch(xtreamCatalogProvider((account, catalogue)).future);
          } catch (_) {
            return const <CatalogItem>[];
          }
        }(),
  ];

  final gathered = await Future.wait(
    perSource.map((f) => f.timeout(
          _perServerTimeout,
          onTimeout: () => const <CatalogItem>[],
        )),
  );

  return gathered.expand((items) => items).toList()
    ..sort((a, b) => a.sortKey.compareTo(b.sortKey));
});

XtreamCatalogue? _catalogueFor(LibraryTab tab) => switch (tab) {
      LibraryTab.movies => XtreamCatalogue.vod,
      LibraryTab.series => XtreamCatalogue.series,
      _ => null,
    };

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
  /// Null until the user picks one, so a `?tab=` deep link is not immediately
  /// overwritten by a default.
  LibraryTab? _selected;

  static LibraryTab? _tabFromQuery(BuildContext context) {
    final name = GoRouterState.of(context).uri.queryParameters['tab'];
    return switch (name) {
      'local' => LibraryTab.localNetwork,
      'series' => LibraryTab.series,
      'live' => LibraryTab.liveTv,
      'movies' => LibraryTab.movies,
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);
    final f = RelayLayout.of(context);
    final tabs = LibraryTab.visible(
      advancedSources: ref.watch(advancedSourcesEnabledProvider),
    );

    // The gate can retract the tab the user is standing on (§15's kill-switch
    // drill checks exactly this), so fall back rather than render a dead tab.
    final requested = _tabFromQuery(context);
    final selected = tabs.contains(_selected ?? requested)
        ? (_selected ?? requested)!
        : LibraryTab.movies;

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
                  // A count, not a source name. Titles here are merged across
                  // Plex servers, panels and this device, so naming one source
                  // would misdescribe most of what is on screen.
                  if (selected.drawsFromPlex) ...[
                    const _SortButton(),
                    const SizedBox(width: 12),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        switch (ref.watch(_libraryProvider(selected))) {
                          AsyncData(:final value) =>
                            '${value.length} ${selected.label.toLowerCase()}',
                          _ => '',
                        },
                        style: TextStyle(color: t.inkDim, fontSize: 12),
                      ),
                    ),
                  ],
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
      // The 10-foot row needs the height; 46 is a phone tab strip.
      height: f == RelayFormFactor.tv ? 62 : 46,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: RelayLayout.pagePadding(f).copyWith(top: 0, bottom: 0),
        children: [
          for (final tab in tabs)
            Padding(
              padding: const EdgeInsets.only(right: 22),
              // Was a GestureDetector, which a D-pad cannot reach -- the tabs
              // were unreachable by remote, so there was no way to move between
              // Movies, Series and Local & Network at all.
              child: RelayTappable(
                borderRadius: 8,
                onTap: () => onSelect(tab),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
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
    if (tab == LibraryTab.liveTv) return const LiveTvTab();
    if (tab == LibraryTab.localNetwork) return const LocalNetworkTab();

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
      data: (unsorted) {
        final list = ref.watch(librarySortProvider).apply(unsorted);
        return list.isEmpty
          ? LibraryEmptyState(
              icon: tab.emptyIcon,
              message: ref.watch(connectedServersProvider).isEmpty &&
                      ref.watch(xtreamAccountsProvider).isEmpty
                  ? 'No sources connected yet.'
                  : 'Nothing in ${tab.label.toLowerCase()} yet.',
              actionLabel: 'Add a source',
              onAction: () => context.push('/add-source'),
            )
          // The artboard puts the row above the Movies grid, and it is
          // deliberately not repeated per tab — it is one list of what the user
          // was in the middle of, not a per-category view.
          : tab == LibraryTab.movies
              ? Column(
                  children: [
                    const ContinueWatchingRow(),
                    Expanded(child: PosterGrid(items: list)),
                  ],
                )
              : PosterGrid(items: list);
      },
    );
  }
}

/// The current order, and a way to change it.
///
/// A sheet of focusable rows rather than a popup menu: every other chooser in
/// the app is built from [RelayTappable] so a remote can reach it with a
/// visible ring, and Material's menu items have not been checked on a TV
/// (MANUAL_TESTING.md §6 treats unchecked Material surfaces as guilty).
class _SortButton extends ConsumerWidget {
  const _SortButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = RelayTheme.of(context);
    final f = RelayLayout.of(context);
    final sort = ref.watch(librarySortProvider);
    final size = f == RelayFormFactor.tv ? 15.0 : 12.0;

    return RelayTappable(
      borderRadius: 8,
      onTap: () => _choose(context, ref, sort),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sort, size: size + 4, color: t.inkDim),
            const SizedBox(width: 4),
            Text(sort.label, style: TextStyle(color: t.inkDim, fontSize: size)),
          ],
        ),
      ),
    );
  }

  Future<void> _choose(
      BuildContext context, WidgetRef ref, LibrarySort current) async {
    final picked = await showModalBottomSheet<LibrarySort>(
      context: context,
      backgroundColor: RelayTheme.of(context).surface,
      builder: (context) {
        final t = RelayTheme.of(context);
        final f = RelayLayout.of(context);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                  child: Text(
                    'Sort by',
                    style: TextStyle(
                      color: t.inkDim,
                      fontSize: RelayLayout.bodySize(f),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                for (final option in LibrarySort.values)
                  RelayTappable(
                    borderRadius: 10,
                    autofocus: option == current,
                    onTap: () => Navigator.of(context).pop(option),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 14),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              option.label,
                              style: TextStyle(
                                color: t.ink,
                                fontSize: RelayLayout.bodySize(f) + 1,
                              ),
                            ),
                          ),
                          if (option == current)
                            Icon(Icons.check, color: t.accent),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
    if (picked != null) await ref.read(librarySortProvider.notifier).set(picked);
  }
}
