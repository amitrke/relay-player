import 'package:flutter_test/flutter_test.dart';
import 'package:relay_player/data/tmdb/title_match.dart';

void main() {
  group('cleanTitle', () {
    test('leaves a clean title alone', () {
      final c = cleanTitle('The Godfather');
      expect(c.title, 'The Godfather');
      expect(c.year, isNull);
    });

    test('strips a language prefix, brackets and quality tags', () {
      final c = cleanTitle('EN - The Film (2019) 4K');
      expect(c.title, 'The Film');
      expect(c.year, 2019);
    });

    test('reads a dotted release name', () {
      final c = cleanTitle('The.Film.2019.1080p.WEB-DL');
      expect(c.title, 'The Film');
      expect(c.year, 2019);
    });

    test('keeps a title that is a number or starts with one', () {
      expect(cleanTitle('1917').title, '1917');
      expect(cleanTitle('2001: A Space Odyssey').title,
          '2001: A Space Odyssey');
      expect(cleanTitle('12 Angry Men').title, '12 Angry Men');
    });

    test('does not eat a real two-letter word as a prefix', () {
      expect(cleanTitle('It - Chapter Two').title, 'It - Chapter Two');
    });
  });

  group('pickBest', () {
    const a = TmdbCandidate(
        id: 1, title: 'Dune', originalTitle: 'Dune', year: 1984);
    const b = TmdbCandidate(
        id: 2, title: 'Dune', originalTitle: 'Dune', year: 2021);

    test('uses the year to choose between same-named films', () {
      expect(pickBest([a, b], 'Dune', 2021)?.id, 2);
      expect(pickBest([a, b], 'Dune', 1984)?.id, 1);
    });

    test('accepts a year one off', () {
      expect(pickBest([b], 'Dune', 2022)?.id, 2);
    });

    test('returns nothing when no candidate is near the year', () {
      expect(pickBest([a, b], 'Dune', 2005), isNull);
    });

    test('without a year, only an exact title is trusted', () {
      expect(pickBest([a, b], 'Dune', null)?.id, 1);
      expect(pickBest([a, b], 'Dune Messiah', null), isNull);
    });

    test('matches on the original title too', () {
      const c = TmdbCandidate(
          id: 3, title: 'Parasite', originalTitle: 'Gisaengchung', year: 2019);
      expect(pickBest([c], 'Gisaengchung', 2019)?.id, 3);
    });
  });
}
