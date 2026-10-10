import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/relay_theme.dart';
import '../../core/theme/relay_widgets.dart';
import '../../data/local/favorites_store.dart';
import '../../domain/models/catalog_item.dart';
import '../favorites_history/favorites_controller.dart';
import '../favorites_history/history_controller.dart';
import '../favorites_history/watch_actions.dart';
import '../metadata/release_dates.dart';
import 'library_screen.dart' show libraryItemsProvider;
import 'library_sort.dart';
import 'library_tab.dart';
import 'poster_grid.dart';
import 'poster_tile.dart';

/// One titled row of Movies or Series: a Plex library, or a panel category.
class Shelf {
  const Shelf({required this.title, required this.source, required this.items});

  final String title;
  final CatalogSource source;

  /// In the order the caller sorted them; grouping never reorders within a row.
  final List<CatalogItem> items;

  /// Unique across sources, so a Plex library and a panel category with the
  /// same name are two shelves, and stable enough to put in a route.
  String get key => '${source.name}|$title';
}

/// How many titles a row draws before it ends in a "See all" tile. A panel
/// category can hold thousands, and a row is for glancing along, not scrolling
/// through; the full list is one press away.
const shelfPreviewCount = 30;

/// Splits [items] into rows, Plex libraries first and panel categories after,
/// each group alphabetical.
///
/// The order is by name, not the order the user chose categories in, because by
/// the time the sources are merged that order is gone. A title with no shelf
/// (kept before the field existed, until the next refresh) goes under its
/// source's own name rather than vanishing.
List<Shelf> groupIntoShelves(List<CatalogItem> items) {
  final byKey = <String, Shelf>{};
  final members = <String, List<CatalogItem>>{};
  for (final item in items) {
    final title = switch (item.shelf?.trim()) {
      final s? when s.isNotEmpty => s,
      _ => SourceBadge.labelFor(item.source),
    };
    final shelf = Shelf(title: title, source: item.source, items: const []);
    final list = members.putIfAbsent(shelf.key, () {
      byKey[shelf.key] = shelf;
      return [];
    });
    list.add(item);
  }
  final shelves = [
    for (final e in byKey.entries)
      Shelf(
        title: e.value.title,
        source: e.value.source,
        items: members[e.key]!,
      ),
  ];
  shelves.sort((a, b) {
    final bySource = a.source.index.compareTo(b.source.index);
    return bySource != 0
        ? bySource
        : a.title.toLowerCase().compareTo(b.title.toLowerCase());
  });
  return shelves;
}

/// A tab's items sorted as the person chose, and then narrowed to unwatched
/// when they asked. Both the rows and a row's "See all" page read it, so they
/// can never disagree about order.
({List<CatalogItem> sorted, List<CatalogItem> list}) arrangeLibrary(
  WidgetRef ref,
  LibraryTab tab,
  List<CatalogItem> unsorted,
) {
  final sort = ref.watch(librarySortProvider);
  final sorted = sort.apply(
    unsorted,
    // Only read for the one sort that uses it, so a date arriving in the
    // background does not rebuild a list sorted by title.
    releaseDates: sort == LibrarySort.releaseDate
        ? ref.watch(releaseDatesProvider.select((s) => s.dates))
        : const {},
  );
  final filtering =
      tab == LibraryTab.movies && ref.watch(libraryUnwatchedOnlyProvider);
  final list = filtering
      ? unwatchedOnly(
          sorted,
          history: {for (final h in ref.watch(historyProvider)) h.key: h},
          overrides: ref.watch(watchOverridesProvider),
        )
      : sorted;
  return (sorted: sorted, list: list);
}

FavoriteItem _favoriteOf(CatalogItem item) => FavoriteItem(
  kind: item.kind == CatalogKind.show ? FavoriteKind.show : FavoriteKind.movie,
  sourceId: item.sourceId,
  itemId: item.id,
);

double _tileWidth(RelayFormFactor f) => switch (f) {
  RelayFormFactor.phone => 108,
  RelayFormFactor.tablet => 130,
  RelayFormFactor.desktop => 140,
  RelayFormFactor.tv => 132,
};

/// Height of one poster tile in a row: a portrait poster, then the title (two
/// lines) and year [PosterTile] draws beneath it.
///
/// Reserved against the live text scaler, like the continue-watching row's
/// tiles, because a horizontal list needs a bounded height and a flat guess
/// clips the text at any scale above 1.0. The poster is `Expanded` inside the
/// tile, so an estimate that is a few pixels off costs artwork, not text.
double _rowHeight(BuildContext context, double width, bool tv) {
  final scaler = MediaQuery.textScalerOf(context);
  final title = scaler.scale(tv ? 18 : 12.5) * 1.3 * 2;
  final year = scaler.scale(tv ? 15 : 11) * 1.4;
  return width * 1.5 + 8 + title + year;
}

/// Movies or Series as rows, one per Plex library and per panel category, each
/// a horizontal strip with its name above it and a "See all" tile at the end.
///
/// Replaces the single poster grid (architecture.md section 12). Left at the
/// first poster of a row is left unhandled so it reaches the navigation rail,
/// and Right at the last tile is swallowed: with nothing to the right,
/// letting geometry answer is what sent focus into the wrong row on the grid.
class ShelvesView extends ConsumerWidget {
  const ShelvesView({
    super.key,
    required this.tab,
    required this.shelves,
    this.onRowFocused,
  });

  final LibraryTab tab;
  final List<Shelf> shelves;

  /// Told which row took focus, so the screen can fold its own chrome away once
  /// the viewer is below the first row and bring it back on row 0.
  final ValueChanged<int>? onRowFocused;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = RelayTheme.of(context);
    final f = RelayLayout.of(context);
    final tv = f == RelayFormFactor.tv;
    final favourites = ref.watch(favoritesProvider);
    final width = _tileWidth(f);
    final height = _rowHeight(context, width, tv);

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 28),
      itemCount: shelves.length,
      itemBuilder: (context, row) {
        final shelf = shelves[row];
        final ordered = favouritesFirst(shelf.items, favourites, _favoriteOf);
        final shown = ordered.take(shelfPreviewCount).toList();
        final more = ordered.length > shown.length;
        final count = shown.length + 1; // The See all tile ends every row.

        return Focus(
          canRequestFocus: false,
          skipTraversal: true,
          onFocusChange: onRowFocused == null
              ? null
              : (focused) {
                  if (focused) onRowFocused!(row);
                },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: RelayLayout.pagePadding(f)
                    .copyWith(top: 14, bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Flexible(
                      child: Text(
                        shelf.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: t.ink,
                          fontSize: RelayLayout.bodySize(f) + 2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${ordered.length}',
                      style: TextStyle(
                        color: t.inkDim,
                        fontSize: RelayLayout.bodySize(f) - 1,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: height,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: RelayLayout.pagePadding(f)
                      .copyWith(top: 0, bottom: 0),
                  itemCount: count,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, i) {
                    final Widget tile = i < shown.length
                        ? PosterTile(
                            item: shown[i],
                            // The first poster of the first row takes focus on
                            // a TV so a remote starts on content.
                            autofocus: tv && row == 0 && i == 0,
                          )
                        : _SeeAllTile(
                            tab: tab,
                            shelf: shelf,
                            // Only worth saying when there is more than the row
                            // shows, but the tile is always the end of the row.
                            more: more,
                          );
                    final last = i == count - 1;
                    return SizedBox(
                      width: width,
                      child: last
                          ? Focus(
                              canRequestFocus: false,
                              skipTraversal: true,
                              onKeyEvent: (_, event) =>
                                  event is! KeyUpEvent &&
                                      event.logicalKey ==
                                          LogicalKeyboardKey.arrowRight
                                  ? KeyEventResult.handled
                                  : KeyEventResult.ignored,
                              child: tile,
                            )
                          : tile,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SeeAllTile extends StatelessWidget {
  const _SeeAllTile({
    required this.tab,
    required this.shelf,
    required this.more,
  });

  final LibraryTab tab;
  final Shelf shelf;
  final bool more;

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);
    final f = RelayLayout.of(context);
    final tv = f == RelayFormFactor.tv;
    final size = tv ? 18.0 : 12.5;

    // The card fills the whole tile, caption space included, so the focus ring
    // hugs the card instead of boxing a card and a gap beneath it (seen on the
    // Google TV emulator, 2026-10-10).
    return RelayTappable(
      borderRadius: 10,
      onTap: () => context.push(shelfLocation(tab, shelf)),
      child: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: t.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.grid_view_rounded,
                    color: t.inkDim,
                    size: tv ? 34 : 26,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'See all',
                    style: TextStyle(
                      color: t.ink,
                      fontSize: size,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (more)
                    Text(
                      '${shelf.items.length} titles',
                      style: TextStyle(color: t.inkDim, fontSize: size - 2),
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

/// Where a row's full list lives, so the tile and the router spell it once.
String shelfLocation(LibraryTab tab, Shelf shelf) => Uri(
  path: '/shelf',
  queryParameters: {'tab': tab.name, 'shelf': shelf.key},
).toString();

/// One row's whole list as a grid, reached from its "See all" tile.
class ShelfScreen extends ConsumerWidget {
  const ShelfScreen({super.key, required this.tab, required this.shelfKey});

  final LibraryTab tab;
  final String shelfKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = RelayTheme.of(context);
    final items = ref.watch(libraryItemsProvider(tab));

    Shelf? shelf;
    if (items.value case final all?) {
      final list = arrangeLibrary(ref, tab, all).list;
      for (final s in groupIntoShelves(list)) {
        if (s.key == shelfKey) shelf = s;
      }
    }

    return Scaffold(
      backgroundColor: t.bg,
      appBar: AppBar(
        backgroundColor: t.bg,
        surfaceTintColor: Colors.transparent,
        foregroundColor: t.ink,
        title: Text(shelf?.title ?? ''),
      ),
      body: shelf != null
          ? PosterGrid(items: shelf.items)
          : items.isLoading
          ? Center(child: CircularProgressIndicator(color: t.accent))
          : const LibraryEmptyState(
              icon: Icons.movie_outlined,
              message: 'Nothing here any more.',
            ),
    );
  }
}
