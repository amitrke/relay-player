import 'package:flutter_test/flutter_test.dart';
import 'package:relay_player/data/xtream/category_language.dart';

void main() {
  test('reads a leading capitalised code', () {
    expect(languageOfCategory('EN | Movies'), 'English');
    expect(languageOfCategory('HI - Bollywood'), 'Hindi');
    expect(languageOfCategory('|FR| Films'), 'French');
  });

  test('reads a spelled-out language anywhere in the name', () {
    expect(languageOfCategory('Series - Hindi Dubbed'), 'Hindi');
    expect(languageOfCategory('Top English Movies'), 'English');
  });

  test('does not treat a code-like ordinary word as a language', () {
    expect(languageOfCategory('Is It Worth It'), isNull);
    expect(languageOfCategory('Movies IT'), isNull);
    expect(languageOfCategory('Hi Def Movies'), isNull);
    expect(languageOfCategory('Action'), isNull);
    expect(languageOfCategory(''), isNull);
  });
}
