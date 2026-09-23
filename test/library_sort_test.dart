import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relay_player/core/theme/relay_theme.dart';
import 'package:relay_player/core/theme/relay_tokens.dart';
import 'package:relay_player/domain/models/catalog_item.dart';
import 'package:relay_player/data/local/history_store.dart';
import 'package:relay_player/features/favorites_history/favorites_controller.dart';
import 'package:relay_player/features/favorites_history/history_controller.dart';
import 'package:relay_player/features/library/library_sort.dart';
import 'package:relay_player/features/library/poster_grid.dart';
import 'package:relay_player/features/library/poster_tile.dart';

CatalogItem _item(
  String title, {
  CatalogSource source = CatalogSource.plex,
  DateTime? added,
  int? year,
}) =>
    CatalogItem(
      source: source,
      sourceId: 'server',
      kind: CatalogKind.movie,
      id: title,
      title: title,
      addedAt: added,
      year: year,
    );

class _NoFavourites extends FavoritesController {
  @override
  Set<String> build() => const {};
}

class _NoHistory extends HistoryController {
  @override
  List<HistoryItem> build() => const [];
}

void main() {
  group('LibrarySort', () {
    final items = [
      _item('charlie', added: DateTime.utc(2026, 1, 1), year: 2001),
      _item('alpha', year: 2020),
      _item('bravo', added: DateTime.utc(2026, 6, 1)),
      _item('delta', added: DateTime.utc(2026, 1, 1), year: 2020),
    ];
    List<String> titles(List<CatalogItem> l) => [for (final i in l) i.title];

    test('title is alphabetical', () {
      expect(titles(LibrarySort.title.apply(items)),
          ['alpha', 'bravo', 'charlie', 'delta']);
    });

    test('recently added is newest first, undated last, title breaks ties',
        () {
      expect(titles(LibrarySort.recentlyAdded.apply(items)),
          ['bravo', 'charlie', 'delta', 'alpha']);
    });

    test('year is newest first, unknown last, title breaks ties', () {
      expect(titles(LibrarySort.year.apply(items)),
          ['alpha', 'delta', 'charlie', 'bravo']);
    });

    test('an unknown stored value falls back to title', () {
      expect(LibrarySort.fromName('somethingRemoved'), LibrarySort.title);
      expect(LibrarySort.fromName(null), LibrarySort.title);
    });
  });

  group('source badge', () {
    Future<void> pumpGrid(WidgetTester tester, List<CatalogItem> items) =>
        tester.pumpWidget(ProviderScope(
          overrides: [
            favoritesProvider.overrideWith(_NoFavourites.new),
            historyProvider.overrideWith(_NoHistory.new),
          ],
          child: MaterialApp(
            home: RelayTheme(
              tokens: RelayPalettes.midnight,
              palette: RelayPalette.midnight,
              child: Scaffold(body: PosterGrid(items: items)),
            ),
          ),
        ));

    testWidgets('appears when a grid mixes Plex and IPTV', (tester) async {
      await pumpGrid(tester, [
        _item('alpha'),
        _item('bravo', source: CatalogSource.xtream),
      ]);
      expect(find.byType(SourceBadge), findsNWidgets(2));
      expect(find.text('Plex'), findsOneWidget);
      expect(find.text('IPTV'), findsOneWidget);
    });

    testWidgets('Plex watch state shows as a tick or a bar, films only',
        (tester) async {
      await pumpGrid(tester, [
        CatalogItem(
          source: CatalogSource.plex,
          sourceId: 'server',
          kind: CatalogKind.movie,
          id: 'watched',
          title: 'watched',
          viewCount: 1,
        ),
        CatalogItem(
          source: CatalogSource.plex,
          sourceId: 'server',
          kind: CatalogKind.movie,
          id: 'halfway',
          title: 'halfway',
          viewOffset: const Duration(minutes: 50),
          duration: const Duration(minutes: 100),
        ),
        // A show never gets either: its state is an episode count we do not
        // parse, and a guess would be worse than nothing.
        CatalogItem(
          source: CatalogSource.plex,
          sourceId: 'server',
          kind: CatalogKind.show,
          id: 'show',
          title: 'show',
          viewCount: 1,
        ),
      ]);
      expect(find.byType(WatchedTick), findsOneWidget);
      expect(find.byType(WatchProgressBar), findsOneWidget);
    });

    testWidgets('stays off when everything is from one kind of source',
        (tester) async {
      await pumpGrid(tester, [_item('alpha'), _item('bravo')]);
      // Control: the tiles themselves rendered.
      expect(find.byType(PosterTile), findsNWidgets(2));
      expect(find.byType(SourceBadge), findsNothing);
    });
  });
}
