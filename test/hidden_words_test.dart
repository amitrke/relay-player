import 'package:flutter_test/flutter_test.dart';
import 'package:relay_player/data/xtream/hidden_words.dart';

void main() {
  test('hides a category that has the word in it', () {
    final h = HiddenWords(['Germany']);
    expect(h.matches('Germany ➾ News'), isTrue);
    expect(h.matches('Germany'), isTrue);
    expect(h.matches('PAKISTAN | NEWS'), isFalse);
  });

  test('is whole words: UK does not hide Ukraine', () {
    final h = HiddenWords(['UK']);
    expect(h.matches('UK ➾ Sports'), isTrue);
    expect(h.matches('Ukraine'), isFalse);
    expect(h.matches('Luke Cage'), isFalse);
    expect(h.matches('BBC UK'), isTrue);
  });

  test('ignores case', () {
    expect(HiddenWords(['pakistan']).matches('PAKISTAN | NEWS'), isTrue);
    expect(HiddenWords(['PAKISTAN']).matches('Cinemania Pakistan'), isTrue);
  });

  test('a phrase must match as a phrase, in order', () {
    final h = HiddenWords(['south indian']);
    expect(h.matches('SOUTH INDIAN HINDI (2021-2022)'), isTrue);
    expect(h.matches('INDIAN SOUTH'), isFalse);
    expect(h.matches('South Africa Indian Ocean'), isFalse);
  });

  test('punctuation and separators do not get in the way', () {
    final h = HiddenWords(['24/7']);
    expect(h.matches('24/7 BOLLYWOOD MUSIC'), isTrue);
    expect(HiddenWords(['K-Pop']).matches('Korea | K Pop Hits'), isTrue);
  });

  test('works on letters outside the Latin alphabet', () {
    expect(HiddenWords(['россия']).matches('Россия | Новости'), isTrue);
  });

  test('an empty list, or entries with no words, hide nothing', () {
    expect(HiddenWords(const []).matches('anything'), isFalse);
    expect(HiddenWords(['', '  ', '---']).isEmpty, isTrue);
    expect(HiddenWords(['---']).matches('---'), isFalse);
  });

  test('says which entry matched', () {
    final h = HiddenWords(['Germany', 'Poland']);
    expect(h.whichMatches('Poland ➾ Sports'), 'poland');
    expect(h.whichMatches('France'), isNull);
  });

  test('tidy trims and collapses spaces, and refuses an empty entry', () {
    expect(HiddenWords.tidy('  South   Indian '), 'South Indian');
    expect(HiddenWords.tidy('   '), isNull);
    expect(HiddenWords.tidy('!!!'), isNull);
  });
}
