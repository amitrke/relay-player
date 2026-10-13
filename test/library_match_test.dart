import 'package:flutter_test/flutter_test.dart';
import 'package:relay_player/data/tmdb/library_match.dart';
import 'package:relay_player/data/tmdb/title_match.dart';
import 'package:relay_player/domain/models/catalog_item.dart';

CatalogItem _item(
  String id,
  String title, {
  int? year,
  CatalogKind kind = CatalogKind.movie,
  String source = 'a',
}) => CatalogItem(
  source: CatalogSource.plex,
  sourceId: source,
  kind: kind,
  id: id,
  title: title,
  year: year,
);

TmdbCandidate _cand(String title, int year, {String? original}) =>
    TmdbCandidate(
      id: title.hashCode,
      title: title,
      originalTitle: original ?? title,
      year: year,
    );

void main() {
  test('only recommendations the user has survive, in TMDB order', () {
    final library = [
      _item('1', 'Heat', year: 1995),
      _item('2', 'Ronin', year: 1998),
    ];
    final out = matchRecommendations(
      [_cand('Casino', 1995), _cand('Ronin', 1998), _cand('Heat', 1995)],
      library,
      tv: false,
    );
    expect(out.map((i) => i.id), ['2', '1']);
  });

  test('a recommendation the user lacks is dropped, never shown', () {
    final out = matchRecommendations(
      [_cand('Unowned', 2020)],
      [_item('1', 'Something Else')],
      tv: false,
    );
    expect(out, isEmpty);
  });

  test('year separates same-named films', () {
    final library = [
      _item('old', 'Dune', year: 1984),
      _item('new', 'Dune', year: 2021),
    ];
    final out = matchRecommendations([_cand('Dune', 2021)], library, tv: false);
    expect(out.map((i) => i.id), ['new']);
  });

  test('a movie never matches a series recommendation', () {
    final library = [_item('s', 'Fargo', kind: CatalogKind.show, year: 2014)];
    expect(
      matchRecommendations([_cand('Fargo', 2014)], library, tv: false),
      isEmpty,
    );
    expect(
      matchRecommendations([_cand('Fargo', 2014)], library, tv: true),
      hasLength(1),
    );
  });

  test('finds a panel copy through its decorated name', () {
    final library = [_item('p', 'EN - Parasite (2019) 4K', source: 'panel')];
    final out = matchRecommendations(
      [_cand('Parasite', 2019, original: 'Gisaengchung')],
      library,
      tv: false,
    );
    expect(out.map((i) => i.id), ['p']);
  });

  test('the seed and anything excluded stay out', () {
    final seed = _item('1', 'Heat', year: 1995);
    final out = matchRecommendations(
      [_cand('Heat', 1995), _cand('Ronin', 1998)],
      [seed, _item('2', 'Ronin', year: 1998)],
      tv: false,
      exclude: {seed.key},
    );
    expect(out.map((i) => i.id), ['2']);
  });

  test('the same film on two sources is offered once, first source wins', () {
    final library = [
      _item('1', 'Heat', year: 1995, source: 'a'),
      _item('1', 'Heat', year: 1995, source: 'b'),
    ];
    final out = matchRecommendations([_cand('Heat', 1995)], library, tv: false);
    expect(out.map((i) => i.sourceId), ['a']);
  });
}
