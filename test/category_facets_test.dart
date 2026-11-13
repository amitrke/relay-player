import 'package:flutter_test/flutter_test.dart';
import 'package:relay_player/data/xtream/category_facets.dart';

/// The region and kind guesses behind "What do you watch?"
/// (category_facets.dart). Made-up category names in the shapes real panels
/// use (category_groups.dart); no provider's own (CLAUDE.md §1).
void main() {
  group('region', () {
    test('codes, names and languages for one place agree', () {
      for (final name in [
        'DE | News',
        'GER: Sport',
        'Germany ➾ Documentary',
        'German Movies',
        'DE ➾ Kids FHD',
      ]) {
        expect(regionOf(name), 'de', reason: name);
      }
    });

    test('a code counts only as a leading word, or a part of its own', () {
      expect(regionOf('IT | Sport'), 'it');
      // "IT" mid-name is the English word, not Italy.
      expect(regionOf('Learn IT Now'), isNull);
      // A place after the kind, as some panels write it.
      expect(regionOf('SPORTS | UK'), 'uk');
      expect(regionOf('Sports | Us and them'), isNull);
    });

    test('two-word names, and languages filed under their country', () {
      expect(regionOf('United Kingdom ➾ Entertainment'), 'uk');
      expect(regionOf('Latin America Sports'), 'latam');
      expect(regionOf('IND | ORIYA'), 'in');
      expect(regionOf('Tamil Movies'), 'in');
    });

    test('a code longer than four letters is still a code', () {
      // A length limit once left the table's own LATAM unreachable.
      expect(regionOf('LATAM | Deportes'), 'latam');
      expect(regionOf('LATIN | Sports'), 'latam');
      expect(regionOf('SPORTS | LATAM'), 'latam');
      // Capitals alone do not make a code: it has to be in the table.
      expect(regionOf('MUSIC | Hits'), isNull);
    });

    test('a name that says no place gives none', () {
      for (final name in ['24/7 Classics', 'BOLLYWOOD (2016-2018)', 'Music']) {
        expect(regionOf(name), isNull, reason: name);
      }
    });
  });

  group('kinds', () {
    test('whole words, in a few languages', () {
      expect(kindsOf('DE | Nachrichten'), {'news'});
      expect(kindsOf('UK ➾ Football HD'), {'sport'});
      expect(kindsOf('Kids & Cartoons'), {'kids'});
      expect(kindsOf('US | News & Sports'), {'news', 'sport'});
      // Not a word that merely contains one.
      expect(kindsOf('Newsroom Classics'), isEmpty);
      expect(kindsOf('Sportsbar Live'), isEmpty);
    });

    test('a word spelled with its accents is the same word', () {
      expect(kindsOf('FR | Actualités'), {'news'});
      expect(kindsOf('ES | Películas'), {'films'});
      expect(kindsOf('ES | Fútbol'), {'sport'});
      expect(kindsOf('DE | Fußball'), {'sport'});
      expect(kindsOf('ES | MÚSICA'), {'music'});
      // Without them, as before.
      expect(kindsOf('ES | Peliculas'), {'films'});
    });
  });

  group('choosing', () {
    const names = [
      'DE | News',
      'DE | Sport',
      'DE | Kids',
      'Germany ➾ Documentary',
      'FR | News',
      'UK | Sport',
      '24/7 Classics',
    ];
    List<String> pick(Set<String> regionCodes, Set<String> kindCodes) =>
        categoriesForFacets<String>(names, (n) => n,
            regionCodes: regionCodes, kindCodes: kindCodes);

    test('nothing chosen reaches nothing (§4.1 opt-in)', () {
      expect(pick({}, {}), isEmpty);
    });

    test('a place and some kinds: both have to fit', () {
      expect(pick({'de'}, {'news', 'sport'}), ['DE | News', 'DE | Sport']);
    });

    test('a place alone takes all of it; kinds alone take every place', () {
      expect(pick({'de'}, {}), [
        'DE | News',
        'DE | Sport',
        'DE | Kids',
        'Germany ➾ Documentary',
      ]);
      expect(pick({}, {'sport'}), ['DE | Sport', 'UK | Sport']);
    });
  });
}
