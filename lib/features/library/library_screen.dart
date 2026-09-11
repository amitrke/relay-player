import 'dart:async';

import 'package:dart_plex/dart_plex.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/relay_theme.dart';
import '../../data/xtream/xtream_account_store.dart';
import '../../domain/models/catalog_item.dart';
import '../advanced_sources/xtream_controller.dart';
import '../accounts/plex_session.dart';
import '../settings/settings_controller.dart';
import '../live_tv/live_tv_tab.dart';
import 'library_tab.dart';
import 'poster_grid.dart';

/// One server's video libraries. Shared by the tabs and by Settings → Sources,
/// so the mapping UI lists exactly what the tabs draw from.
final plexSectionsProvider =
    FutureProvider.family<List<PlexLibrarySection>, String>(
        (ref, serverId) async {
  final servers = ref.watch(connectedServersProvider);
  for (final server in servers) {
    if (server.id == serverId) return server.service.sections();
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
    final servers = ref.watch(connectedServersProvider);
    // Name the server only when there is exactly one; with several, a single
    // name in the corner would be a lie about where these titles came from.
    final serverName = servers.length == 1 ? servers.single.name : null;

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
    if (tab == LibraryTab.liveTv) return const LiveTvTab();

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
