import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relay_player/core/platform/device_kind.dart';
import 'package:relay_player/core/theme/relay_theme.dart';
import 'package:relay_player/core/theme/relay_tokens.dart';
import 'package:relay_player/data/local/history_store.dart';
import 'package:relay_player/domain/models/catalog_item.dart';
import 'package:relay_player/features/favorites_history/favorites_controller.dart';
import 'package:relay_player/features/favorites_history/history_controller.dart';
import 'package:relay_player/features/library/library_hero.dart';
import 'package:relay_player/features/library/library_shelves.dart';
import 'package:relay_player/features/library/library_tab.dart';
import 'package:relay_player/features/library/poster_tile.dart';

/// The TV library after Plex's own TV app (architecture.md §12.4, 2026-10-30):
/// a hero describing the focused title, posters with no caption beneath, and
/// the focused row brought to the top of the rows.

class _NoFavourites extends FavoritesController {
  @override
  Set<String> build() => const {};
}

class _NoHistory extends HistoryController {
  @override
  List<HistoryItem> build() => const [];
}

CatalogItem _film(String id, {String? summary}) => CatalogItem(
  source: CatalogSource.server,
  sourceId: 'srv',
  kind: CatalogKind.movie,
  id: id,
  title: 'Film $id',
  year: 2007,
  duration: const Duration(minutes: 100),
  summary: summary,
);

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.binding.setSurfaceSize(const Size(960, 540));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        favoritesProvider.overrideWith(_NoFavourites.new),
        historyProvider.overrideWith(_NoHistory.new),
      ],
      child: MaterialApp(
        home: RelayTheme(
          tokens: RelayPalettes.midnight,
          palette: RelayPalette.midnight,
          child: Scaffold(body: child),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => DeviceKind.debugSetTelevision(true));
  tearDown(() => DeviceKind.debugSetTelevision(false));

  group('HeroInfo', () {
    test('a film: year, runtime, plot; its server for signing the art', () {
      final h = HeroInfo.ofItem(_film('1', summary: 'A plot.'));
      expect(h.meta, ['2007', '1 h 40 min']);
      expect(h.summary, 'A plot.');
      expect(h.serverId, 'srv');
    });

    test('a show says how many episodes are unwatched', () {
      const show = CatalogItem(
        source: CatalogSource.server,
        sourceId: 'srv',
        kind: CatalogKind.show,
        id: 's',
        title: 'Show',
        unwatchedEpisodes: 3,
      );
      expect(HeroInfo.ofItem(show).meta, ['3 unwatched episodes']);
    });

    test('a panel title has no server to sign art against', () {
      const panel = CatalogItem(
        source: CatalogSource.xtream,
        sourceId: 'acct',
        kind: CatalogKind.movie,
        id: 'v',
        title: 'Title',
        artPath: '/should/not/be/signed',
      );
      expect(HeroInfo.ofItem(panel).serverId, isNull);
    });
  });

  testWidgets('focusing a poster on a TV describes it in the hero', (
    tester,
  ) async {
    await _pump(
      tester,
      Column(
        children: [
          const LibraryHero(),
          SizedBox(
            width: 120,
            height: 180,
            child: PosterTile(
              item: _film('1', summary: 'The plot of film one.'),
              autofocus: true,
              caption: false,
            ),
          ),
        ],
      ),
    );
    expect(find.text('The plot of film one.'), findsOneWidget);
    // Once, in the hero: the tile has no caption to repeat it.
    expect(find.text('Film 1'), findsOneWidget);
  });

  testWidgets('control: with the caption on, the title is under the poster', (
    tester,
  ) async {
    DeviceKind.debugSetTelevision(false);
    await _pump(
      tester,
      SizedBox(
        width: 120,
        height: 240,
        child: PosterTile(item: _film('1')),
      ),
    );
    expect(find.text('Film 1'), findsOneWidget);
  });

  testWidgets('the focused row is brought to the top of the rows', (
    tester,
  ) async {
    final shelves = [
      for (var s = 0; s < 6; s++)
        Shelf(
          title: 'Shelf $s',
          source: CatalogSource.server,
          items: [for (var i = 0; i < 3; i++) _film('$s-$i')],
        ),
    ];
    await _pump(
      tester,
      SizedBox(
        height: 340,
        child: ShelvesView(tab: LibraryTab.movies, shelves: shelves),
      ),
    );
    final listTop = tester.getTopLeft(find.byType(ShelvesView)).dy;

    for (var i = 0; i < 3; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
    }
    // Row 3 has focus; its title sits at the top, padding aside.
    final header = tester.getTopLeft(find.text('Shelf 3')).dy - listTop;
    expect(header, inInclusiveRange(0, 16));
  });
}
