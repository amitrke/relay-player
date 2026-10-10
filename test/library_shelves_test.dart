import 'package:flutter_test/flutter_test.dart';
import 'package:relay_player/data/local/library_cache.dart';
import 'package:relay_player/domain/models/catalog_item.dart';
import 'package:relay_player/features/library/library_shelves.dart';

CatalogItem _item(
  String id, {
  String? shelf,
  CatalogSource source = CatalogSource.plex,
}) => CatalogItem(
  source: source,
  sourceId: 's1',
  kind: CatalogKind.movie,
  id: id,
  title: 'Title $id',
  shelf: shelf,
);

void main() {
  group('groupIntoShelves', () {
    test('one row per library or category, Plex before panels', () {
      final shelves = groupIntoShelves([
        _item('1', shelf: 'Action', source: CatalogSource.xtream),
        _item('2', shelf: 'Movies'),
        _item('3', shelf: '4K Movies'),
        _item('4', shelf: 'Movies'),
        _item('5', shelf: 'Comedy', source: CatalogSource.xtream),
      ]);
      expect([for (final s in shelves) s.title], [
        '4K Movies',
        'Movies',
        'Action',
        'Comedy',
      ]);
      expect([for (final i in shelves[1].items) i.id], ['2', '4']);
    });

    test('keeps the order it was given inside a row', () {
      final shelves = groupIntoShelves([
        _item('b', shelf: 'Movies'),
        _item('a', shelf: 'Movies'),
      ]);
      expect([for (final i in shelves.single.items) i.id], ['b', 'a']);
    });

    test('a Plex library and a panel category of the same name stay apart', () {
      final shelves = groupIntoShelves([
        _item('1', shelf: 'Movies'),
        _item('2', shelf: 'Movies', source: CatalogSource.xtream),
      ]);
      expect(shelves, hasLength(2));
    });

    test('a title kept before shelves existed goes under its source', () {
      final shelves = groupIntoShelves([
        _item('1'),
        _item('2', source: CatalogSource.xtream),
      ]);
      expect([for (final s in shelves) s.title], ['Plex', 'IPTV']);
    });

    test('nothing in, nothing out', () {
      expect(groupIntoShelves(const []), isEmpty);
    });
  });

  test('a shelf survives the library cache', () {
    final back = catalogItemFromJson(
      catalogItemToJson(_item('1', shelf: 'Documentaries')),
    );
    expect(back?.shelf, 'Documentaries');
    expect(
      catalogItemFromJson(catalogItemToJson(_item('2')))?.shelf,
      isNull,
    );
  });
}
