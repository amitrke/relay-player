import 'dart:async';

import 'package:dart_plex/dart_plex.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/relay_theme.dart';
import '../../core/theme/relay_widgets.dart';
import '../../data/local/library_cache.dart';
import '../../data/local/library_loader.dart';
import '../../data/xtream/xtream_account_store.dart';
import '../../domain/models/catalog_item.dart';
import '../advanced_sources/xtream_controller.dart';
import '../accounts/plex_session.dart';
import '../settings/settings_controller.dart';
import '../favorites_history/continue_watching_row.dart';
import '../live_tv/live_tv_tab.dart';
import '../metadata/tmdb_controller.dart';
import '../local_network/local_network_tab.dart';
import 'library_cache_provider.dart';
import 'library_dedupe.dart';
import 'library_shelves.dart';
import 'library_sort.dart';
import 'library_tab.dart';
import 'poster_grid.dart';

/// One server's video libraries. Shared by the tabs and by Settings → Sources,
/// so the mapping UI lists exactly what the tabs draw from.
final plexSectionsProvider =
    FutureProvider.family<List<PlexLibrarySection>, String>((
      ref,
      serverId,
    ) async {
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

/// Everything feeding [tab], merged across every source, kept between launches.
///
/// §12 screen 3: "Movies/Series merge across Plex accounts". One source failing
/// or stalling must not blank the tab: it costs you nothing, because its last
/// answer is kept and used in its place.
///
/// It answers twice when something was kept: `build` returns that at once, and
/// the fresh answer replaces it as the provider's state when the sources reply
/// (see `loadLibrary`). Until 2026-10-09 this waited for every source up to a 10
/// second timeout and dropped any that missed it, for the whole session. On an
/// emulator that gave 982 items one launch and 1124 the next, the first with no
/// watched films in it, which starved the TMDB rows and the AI picks built on
/// it.
///
/// A notifier and not a `StreamProvider` because the consumers read `.future`
/// without listening, and a stream provider's future never completes in that
/// case in this Riverpod version. Reading ahead of a rebuild is what the
/// background half needs, so everything it asks for is `read`, not `watch`:
/// `watch` is only allowed while `build` is running, and the fresh answer arrives
/// after it has returned.
final _libraryProvider =
    AsyncNotifierProvider.family<
      LibraryController,
      List<CatalogItem>,
      LibraryTab
    >(LibraryController.new);

class LibraryController extends AsyncNotifier<List<CatalogItem>> {
  LibraryController(this.tab);

  final LibraryTab tab;

  @override
  Future<List<CatalogItem>> build() async {
    // Watched here, while build runs, so a change to any of them rebuilds.
    final servers = ref.watch(connectedServersProvider);
    final mapping = ref.watch(libraryMappingProvider);
    final accounts = ref.watch(xtreamAccountsProvider);
    final cacheFuture = ref.watch(libraryCacheProvider.future);

    LibraryCache? cache;
    try {
      cache = await cacheFuture;
    } catch (_) {}

    final sources = <LibrarySource>[
      for (final server in servers)
        LibrarySource(
          key: 'plex|${server.id}|${tab.name}',
          // A kept Plex item has no signed poster URL (§3), so sign its path
          // against the live connection. Null until the server is reachable.
          revive: (item) {
            final path = item.posterPath;
            return path == null
                ? item
                : item.withPosterUrl(server.service.posterUrlForPath(path));
          },
          fetch: () async {
            final sections = await ref.read(
              plexSectionsProvider(server.id).future,
            );
            final wanted = mapping.sectionsFor(tab, server.id, sections);
            // Section by section, and not through `itemsFrom`, which merges
            // them: the section a title came from is what names its row, and
            // is not recoverable after the merge. With more than one server the
            // row carries the server's name too, since two of them can each have
            // a library called "Movies".
            final pages = await Future.wait([
              for (final s in wanted)
                server.service.allItems(s).then((page) => (s, page)),
            ]);
            return LibraryFetch([
              for (final (section, page) in pages)
                for (final m in page)
                  server.service.toCatalogItem(
                    m,
                    shelf: servers.length > 1
                        ? '${server.name} · ${section.title}'
                        : section.title,
                  ),
            ], wanted.map((s) => s.id).join(','));
          },
        ),

      // Panel catalogues merge into the same tabs: a VOD title is a movie and a
      // panel series is a series, so splitting them out would make the user
      // remember which source something came from in order to find it.
      for (final account in accounts)
        if (_catalogueFor(tab) case final catalogue?)
          LibrarySource(
            key: 'xtream|${account.id}|${catalogue.name}',
            expectedSignature: account.categoriesFor(catalogue).join(','),
            fetch: () async => LibraryFetch(
              await ref.read(
                xtreamCatalogProvider((account, catalogue)).future,
              ),
              account.categoriesFor(catalogue).join(','),
            ),
          ),
    ];

    // Deduplicated here, so every reader of a tab (the grid, its count, the
    // AI index, release dates) sees one copy of a title; see dedupeLibrary.
    final localPlex = {
      for (final s in servers)
        if (plexUrlIsLocal(s.stored.baseUrl)) s.id,
    };
    final events = StreamIterator(
      loadLibrary(
        sources,
        cache: cache,
        timeout: _perServerTimeout,
      ).map((items) => dedupeLibrary(items, localPlexServers: localPlex)),
    );
    if (!await events.moveNext()) return const [];
    final first = events.current;
    // Whatever follows is the fresh answer, replacing what was kept.
    unawaited(_applyLater(events));
    return first;
  }

  Future<void> _applyLater(StreamIterator<List<CatalogItem>> events) async {
    try {
      while (await events.moveNext()) {
        if (!ref.mounted) break;
        state = AsyncData(events.current);
      }
    } catch (_) {
      // The kept answer stands; a failed refresh is not an error to show.
    } finally {
      await events.cancel();
    }
  }
}

/// Everything a tab shows, for screens that need to look titles up in it.
final libraryItemsProvider = _libraryProvider;

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

  /// True while a remote is browsing below the first row of a poster grid.
  ///
  /// On a TV the page title, tab strip and continue-watching row together took
  /// so much of the 540 dp height that fewer than two rows of posters showed.
  /// They fold away once focus is past row 0 and return when it comes back, so
  /// pressing Up from the first row still reaches them. TV only: a phone
  /// scrolls with a finger and has no such problem.
  bool _browsing = false;

  void _onRowFocused(int row) {
    final browsing = row > 0;
    if (browsing != _browsing) setState(() => _browsing = browsing);
  }

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

    // The gate can retract the tab the user is standing on (toggling Advanced sources
    // off while standing on it), so fall back rather than render a dead tab.
    final requested = _tabFromQuery(context);
    final selected = tabs.contains(_selected ?? requested)
        ? (_selected ?? requested)!
        : LibraryTab.movies;

    final folded = f == RelayFormFactor.tv && _browsing;

    final tabBar = _TabBar(
      tabs: tabs,
      selected: selected,
      onSelect: (tab) => setState(() {
        _selected = tab;
        _browsing = false;
      }),
    );

    // A count, not a source name. Titles here are merged across Plex servers,
    // panels and this device, so naming one source would misdescribe most of
    // what is on screen.
    final trailing = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (selected.drawsFromPlex) ...[
          LibrarySortButton(tab: selected),
          if (f != RelayFormFactor.phone) ...[
            const SizedBox(width: 12),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(switch (ref.watch(_libraryProvider(selected))) {
                AsyncData(:final value) =>
                  '${value.length} ${selected.label.toLowerCase()}',
                _ => '',
              }, style: TextStyle(color: t.inkDim, fontSize: 12)),
            ),
          ],
        ],
      ],
    );

    return Scaffold(
      backgroundColor: t.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RelayCollapsible(
              collapsed: folded,
              // No "Library" heading on any form factor: the rail, or the phone's
              // bottom bar, already says where you are and the tabs say what you
              // are looking at. On a 540 dp TV it cost ~65 dp for nothing. Sort
              // and count ride on the tab row instead.
              child: Padding(
                padding: EdgeInsets.only(
                  top: f == RelayFormFactor.phone ? 4 : 8,
                ),
                child: Row(
                  children: [
                    Expanded(child: tabBar),
                    if (selected.drawsFromPlex)
                      Padding(
                        padding: EdgeInsets.only(
                          right: f == RelayFormFactor.phone
                              ? 12
                              : RelayLayout.pagePadding(f).right,
                        ),
                        child: trailing,
                      ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: _TabBody(
                tab: selected,
                folded: folded,
                onRowFocused: f == RelayFormFactor.tv ? _onRowFocused : null,
              ),
            ),
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
                        color: tab == selected ? t.accent : Colors.transparent,
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
  const _TabBody({required this.tab, this.folded = false, this.onRowFocused});

  final LibraryTab tab;

  /// Folds the continue-watching row away; see [_LibraryScreenState._browsing].
  final bool folded;
  final ValueChanged<int>? onRowFocused;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (tab == LibraryTab.liveTv) return const LiveTvTab();
    if (tab == LibraryTab.localNetwork) return const LocalNetworkTab();

    if (!tab.drawsFromPlex) {
      return LibraryEmptyState(icon: tab.emptyIcon, message: tab.emptyMessage);
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
        final arranged = arrangeLibrary(ref, tab, unsorted);
        final sorted = arranged.sorted;
        final list = arranged.list;
        final filtering =
            tab == LibraryTab.movies && ref.watch(libraryUnwatchedOnlyProvider);
        // Filtered down to nothing is not "no sources": say what happened and
        // offer the way back, rather than suggesting they add a source.
        if (filtering && list.isEmpty && sorted.isNotEmpty) {
          return LibraryEmptyState(
            icon: Icons.check_circle_outline,
            message: 'Everything in Movies is watched.',
            actionLabel: 'Show all',
            onAction: () =>
                ref.read(libraryUnwatchedOnlyProvider.notifier).set(false),
          );
        }
        return list.isEmpty
            ? LibraryEmptyState(
                icon: tab.emptyIcon,
                message:
                    ref.watch(connectedServersProvider).isEmpty &&
                        ref.watch(xtreamAccountsProvider).isEmpty
                    ? 'No sources connected yet.'
                    : 'Nothing in ${tab.label.toLowerCase()} yet.',
                actionLabel: 'Add a source',
                onAction: () => context.push('/add-source'),
              )
            // Films resume above Movies and episodes above Series. It was one
            // mixed row above Movies until 2026-09-28; see ContinueWatchingRow.
            : tab == LibraryTab.movies || tab == LibraryTab.series
            ? Column(
                children: [
                  RelayCollapsible(
                    collapsed: folded,
                    child: ContinueWatchingRow(
                      episodes: tab == LibraryTab.series,
                    ),
                  ),
                  Expanded(
                    child: ShelvesView(
                      tab: tab,
                      shelves: groupIntoShelves(list),
                      onRowFocused: onRowFocused,
                    ),
                  ),
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
class LibrarySortButton extends ConsumerWidget {
  const LibrarySortButton({super.key, required this.tab});

  /// "Unwatched only" is offered on Movies alone; see [unwatchedOnly].
  final LibraryTab tab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = RelayTheme.of(context);
    final f = RelayLayout.of(context);
    final sort = ref.watch(librarySortProvider);
    final size = f == RelayFormFactor.tv ? 15.0 : 12.0;
    final filtered =
        tab == LibraryTab.movies && ref.watch(libraryUnwatchedOnlyProvider);

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
            Text(
              filtered ? '${sort.label} · Unwatched' : sort.label,
              style: TextStyle(color: t.inkDim, fontSize: size),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _choose(
    BuildContext context,
    WidgetRef ref,
    LibrarySort current,
  ) async {
    final picked = await showModalBottomSheet<LibrarySort>(
      context: context,
      backgroundColor: RelayTheme.of(context).surface,
      // Scroll-controlled, and the content scrolls: a sheet is capped at about
      // half the screen height otherwise, and a 1080p TV is only 540 dp tall
      // (section 11). Four options plus the Unwatched row no longer fit in that,
      // and overflowed by 83 px when Release date was added (seen on the Google
      // TV emulator), which in a release build silently clips the bottom row.
      isScrollControlled: true,
      builder: (context) {
        final t = RelayTheme.of(context);
        final f = RelayLayout.of(context);
        return SafeArea(
          child: SingleChildScrollView(
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
                for (final option in LibrarySort.values.where(
                  (o) =>
                      o != LibrarySort.releaseDate ||
                      ref.read(tmdbKeyProvider).value != null,
                ))
                  RelayTappable(
                    borderRadius: 10,
                    autofocus: option == current,
                    onTap: () => Navigator.of(context).pop(option),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
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
                if (tab == LibraryTab.movies) ...[
                  Divider(color: t.line, height: 20),
                  _UnwatchedToggleRow(onToggled: Navigator.of(context).pop),
                ],
              ],
            ),
          ),
        );
      },
    );
    if (picked != null) {
      await ref.read(librarySortProvider.notifier).set(picked);
    }
  }
}

/// Flips "Unwatched only" and closes the sheet.
class _UnwatchedToggleRow extends ConsumerWidget {
  const _UnwatchedToggleRow({required this.onToggled});

  final VoidCallback onToggled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = RelayTheme.of(context);
    final f = RelayLayout.of(context);
    final on = ref.watch(libraryUnwatchedOnlyProvider);
    return RelayTappable(
      borderRadius: 10,
      onTap: () {
        ref.read(libraryUnwatchedOnlyProvider.notifier).set(!on);
        onToggled();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Unwatched only',
                style: TextStyle(
                  color: t.ink,
                  fontSize: RelayLayout.bodySize(f) + 1,
                ),
              ),
            ),
            // A drawn state rather than a Switch: Material's switch has not
            // been checked with a remote, and the row is the control anyway.
            Icon(
              on ? Icons.check_box : Icons.check_box_outline_blank,
              color: on ? t.accent : t.inkDim,
            ),
          ],
        ),
      ),
    );
  }
}
