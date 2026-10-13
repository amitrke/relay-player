import 'package:flutter_test/flutter_test.dart';
import 'package:relay_player/data/xtream/category_groups.dart';
import 'package:relay_player/data/xtream/xtream_client.dart';

List<XtreamCategory> _cats(List<String> names) => [
  for (final (i, n) in names.indexed) XtreamCategory(id: '$i', name: n),
];

CategoryGroup _group(List<CategoryGroup> groups, String label) =>
    groups.firstWhere(
      (g) => g.label == label,
      orElse: () => throw StateError(
        'no group "$label" in '
        '${groups.map((g) => g.label).toList()}',
      ),
    );

List<String> _names(CategoryGroup g) => [for (final c in g.categories) c.name];

void main() {
  test('year buckets of one thing collapse into one group', () {
    final groups = groupCategories(
      _cats([
        'BOLLYWOOD (2025-2026)',
        'BOLLYWOOD 2016-2018',
        'BOLLYWOOD | OLD IS GOLD',
        'BOLLYWOOD (1900-1980)',
        '(2024) HOLLYWOOD',
        '(2022) HOLLYWOOD',
        'HOLLYWOOD | Horror',
      ]),
    );
    expect(groups.map((g) => g.label), ['BOLLYWOOD', 'HOLLYWOOD']);
    expect(_group(groups, 'BOLLYWOOD').categories.length, 4);
    expect(_group(groups, 'HOLLYWOOD').categories.length, 3);
  });

  test('a country, with and without a genre after it, is one group', () {
    final groups = groupCategories(
      _cats([
        'Germany',
        'Germany ➾ News',
        'Germany ➾ Sports',
        'France ➾ Music',
        'France',
      ]),
    );
    expect(_names(_group(groups, 'Germany')), [
      'Germany',
      'Germany ➾ News',
      'Germany ➾ Sports',
    ]);
    expect(_group(groups, 'France').categories.length, 2);
  });

  test('bars, colons and spaced dashes all separate', () {
    final groups = groupCategories(
      _cats(['IND | ORIYA', 'IND: SPORTS', 'IND - MUSIC']),
    );
    expect(groups.single.label, 'IND');
    expect(groups.single.categories.length, 3);
  });

  test('a hyphen inside a word is not a separator', () {
    final groups = groupCategories(_cats(['Hip-Hop Live', 'Hip-Hop Classics']));
    // Split at the hyphen they would be two singletons; as words they share
    // an opening word and cluster.
    expect(groups.length, 1);
    expect(groups.single.categories.length, 2);
  });

  test('"24/7" stays one token and groups its channels together', () {
    final groups = groupCategories(
      _cats([
        '24/7 BOLLYWOOD MUSIC',
        '24/7 HOLLYWOOD ACTION MOVIES',
        '24/7 RAMAZAN SPECIAL',
      ]),
    );
    expect(groups.single.label, '24/7');
    expect(groups.single.categories.length, 3);
  });

  test('a longer name joins the group it extends', () {
    final groups = groupCategories(
      _cats([
        'HINDI DUBBED | A',
        'HINDI DUBBED | B',
        'HINDI DUBBED HOLLYWOOD (2023-2024)',
      ]),
    );
    expect(groups.single.label, 'HINDI DUBBED');
    expect(groups.single.categories.length, 3);
  });

  test(
    'singletons sharing an opening word cluster, others go to the remainder',
    () {
      final groups = groupCategories(
        _cats([
          'Cinemania Pakistan',
          'CineMania Hindi Web Series',
          'Cinemania Kids',
          'Quiet Corner',
          'Lone Wolf',
        ]),
      );
      expect(groups.first.label, 'Cinemania');
      expect(groups.last.isRemainder, isTrue);
      expect(groups.last.label, 'Everything else');
      expect(_names(groups.last), ['Quiet Corner', 'Lone Wolf']);
    },
  );

  test('every category lands in exactly one group, in panel order', () {
    final input = _cats([
      'USA',
      'USA ➾ News',
      'UK',
      'Something unique',
      '24/7 A',
      '24/7 B',
      '(2020) FILMS',
      'FILMS | Drama',
      'X',
    ]);
    final groups = groupCategories(input);
    final all = [for (final g in groups) ...g.categories];
    expect(all.length, input.length);
    expect({for (final c in all) c.id}.length, input.length);
    for (final g in groups) {
      final ids = [for (final c in g.categories) int.parse(c.id)];
      expect(ids, [...ids]..sort(), reason: g.label);
    }
  });

  test('biggest groups come first and the remainder last', () {
    final groups = groupCategories(
      _cats(['AA | 1', 'BB | 1', 'BB | 2', 'BB | 3', 'lonely']),
    );
    expect(groups.map((g) => g.label), ['BB', 'Everything else']);
  });

  test('a name that is only a year keeps itself rather than vanishing', () {
    final groups = groupCategories(_cats(['(2024)', '(2023)']));
    final all = [for (final g in groups) ...g.categories];
    expect(all.length, 2);
  });

  test('empty in, empty out', () {
    expect(groupCategories(const []), isEmpty);
  });

  group('browsing a big group by letter', () {
    test('a name files under its first letter, digits and symbols under #', () {
      expect(letterOf('Amazon'), 'A');
      expect(letterOf('  hbo max'), 'H');
      expect(letterOf('24/7 Music'), '#');
      expect(letterOf('(2024) Films'), '#');
      expect(letterOf('...'), '#');
      expect(letterOf(''), '#');
    });

    test(
      'sorts A to Z ignoring case and leading punctuation, digits first',
      () {
        final sorted = sortedAlphabetically(
          _cats(['banana', 'Apple', '*Cherry', '24/7 X', 'apple pie']),
          (c) => c.name,
        );
        expect(
          [for (final c in sorted) c.name],
          ['24/7 X', 'Apple', 'apple pie', 'banana', '*Cherry'],
        );
      },
    );

    test('equal names keep the panel order', () {
      final input = _cats(['Same', 'Other', 'Same']);
      final sorted = sortedAlphabetically(input, (c) => c.name);
      expect([for (final c in sorted) c.id], ['1', '0', '2']);
    });

    test('sorts by what is shown, not by the full name', () {
      final input = _cats(['Z ➾ Apple', 'A ➾ Zebra']);
      final sorted = sortedAlphabetically(
        input,
        (c) => categoryLabelInGroup(c.name),
      );
      expect([for (final c in sorted) c.name], ['Z ➾ Apple', 'A ➾ Zebra']);
    });
  });
}
