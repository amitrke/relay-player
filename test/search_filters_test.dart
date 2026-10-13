import 'package:flutter_test/flutter_test.dart';
import 'package:relay_player/domain/models/catalog_item.dart';
import 'package:relay_player/features/search/search_filters.dart';

CatalogItem _item(
  String id, {
  CatalogKind kind = CatalogKind.movie,
  String source = 'a',
  int? year,
  String? language,
  List<String> genres = const [],
  double? rating,
  String? originalLanguage,
}) => CatalogItem(
  source: CatalogSource.plex,
  sourceId: source,
  kind: kind,
  id: id,
  title: id,
  year: year,
  language: language,
  genres: genres,
  rating: rating,
  originalLanguage: originalLanguage,
);

void main() {
  final items = [
    _item('m1', year: 2021),
    _item('s1', kind: CatalogKind.show, year: 2015, source: 'b'),
    _item('m2', year: 1950, language: 'Hindi', source: 'b'),
    _item('m3'),
  ];

  test('decades bucket, with the oldest holding everything earlier', () {
    expect(decadeOf(2021), 2020);
    expect(decadeOf(1999), 1990);
    expect(decadeOf(1950), 1960);
    expect(decadeLabel(1960), '1960s and earlier');
    expect(decadeLabel(2020), '2020s');
  });

  test('no filter passes everything through unchanged', () {
    expect(const SearchFilters().apply(items), items);
  });

  test('filters combine', () {
    final out = const SearchFilters(
      kind: CatalogKind.movie,
      sourceId: 'b',
    ).apply(items);
    expect(out.map((i) => i.id), ['m2']);
  });

  test('a year filter drops items with no year', () {
    final out = const SearchFilters(decade: 2020).apply(items);
    expect(out.map((i) => i.id), ['m1']);
  });

  test('a language filter drops items with unknown language', () {
    final out = const SearchFilters(language: 'Hindi').apply(items);
    expect(out.map((i) => i.id), ['m2']);
  });

  test('with_ can clear a field as well as set one', () {
    const f = SearchFilters(kind: CatalogKind.show, decade: 2010);
    final cleared = f.with_(kind: (null,));
    expect(cleared.kind, isNull);
    expect(cleared.decade, 2010);
  });

  test('options are offered only when they could change the result', () {
    final one = SearchFilterOptions.of([_item('a', year: 2020)]);
    expect(one.offersKind, isFalse);
    expect(one.offersSource, isFalse);
    expect(one.offersYear, isFalse);
    expect(one.offersLanguage, isFalse);

    final many = SearchFilterOptions.of(items);
    expect(many.offersKind, isTrue);
    expect(many.offersSource, isTrue);
    expect(many.offersYear, isTrue);
    expect(many.offersLanguage, isTrue);
    expect(many.decades, [2020, 2010, 1960]);
  });

  group('TMDB-backed filters', () {
    final rich = [
      _item(
        'a',
        genres: ['Drama', 'Thriller'],
        rating: 8.1,
        originalLanguage: 'Korean',
      ),
      _item('b', genres: ['Comedy'], rating: 6.2, originalLanguage: 'English'),
      _item('c'),
    ];

    test('genre matches any genre of the item and drops unknowns', () {
      expect(
        const SearchFilters(genre: 'Thriller').apply(rich).map((i) => i.id),
        ['a'],
      );
    });

    test(
      'a minimum rating drops unrated items rather than treating them as low',
      () {
        expect(const SearchFilters(minRating: 6).apply(rich).map((i) => i.id), [
          'a',
          'b',
        ]);
        expect(const SearchFilters(minRating: 8).apply(rich).map((i) => i.id), [
          'a',
        ]);
      },
    );

    test('original language filters on the TMDB value', () {
      expect(
        const SearchFilters(originalLanguage: 'Korean')
            .apply(rich)
            .map((i) => i.id),
        ['a'],
      );
    });

    test(
      'options list genres most common first and offer nothing without data',
      () {
        final o = SearchFilterOptions.of([
          _item('x', genres: ['Drama', 'Comedy']),
          _item('y', genres: ['Drama']),
        ]);
        expect(o.genres, ['Drama', 'Comedy']);
        final none = SearchFilterOptions.of([_item('z')]);
        expect(none.offersGenre, isFalse);
        expect(none.offersRating, isFalse);
        expect(none.offersOriginalLanguage, isFalse);
      },
    );
  });

  test('title matches rank exact, whole word, word-start, then substring', () {
    final out = rankByTitleMatch([
      _item('Haunted Mansion'),
      _item('Batman'),
      _item('Hit Man'),
      _item('Man'),
      _item('Manhattan'),
    ], 'man');
    expect(out.map((i) => i.id), [
      'Man',
      'Hit Man',
      'Haunted Mansion',
      'Manhattan',
      'Batman',
    ]);
  });
}
