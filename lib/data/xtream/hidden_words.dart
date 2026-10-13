/// Words and phrases the user never wants to see from a panel: a country they
/// do not watch, a language, a kind of channel.
///
/// **Whole words, not substrings.** "UK" must hide "UK ➾ News" and leave
/// "Ukraine" and "Luke Cage" alone, and a substring match cannot do that. A text
/// is split into words (letters and digits, in any script) and a hidden entry
/// matches when its words appear in it next to each other and in order, so a
/// phrase such as "south indian" is one thing to hide rather than two words.
/// Case is ignored.
class HiddenWords {
  HiddenWords(Iterable<String> entries)
    : phrases = [
        for (final e in entries)
          if (_words(e) case final w when w.isNotEmpty) w,
      ];

  /// Each entry as its words, entries with none (only symbols) dropped.
  final List<List<String>> phrases;

  bool get isEmpty => phrases.isEmpty;

  /// Whether [text] contains any hidden entry.
  bool matches(String text) {
    if (phrases.isEmpty) return false;
    final words = _words(text);
    for (final phrase in phrases) {
      if (_contains(words, phrase)) return true;
    }
    return false;
  }

  /// The hidden entry that matches [text], as the user wrote it is not kept, so
  /// this gives its words joined, for saying why something was hidden.
  String? whichMatches(String text) {
    final words = _words(text);
    for (final phrase in phrases) {
      if (_contains(words, phrase)) return phrase.join(' ');
    }
    return null;
  }

  static bool _contains(List<String> words, List<String> phrase) {
    if (phrase.length > words.length) return false;
    for (var i = 0; i <= words.length - phrase.length; i++) {
      var ok = true;
      for (var j = 0; j < phrase.length; j++) {
        if (words[i + j] != phrase[j]) {
          ok = false;
          break;
        }
      }
      if (ok) return true;
    }
    return false;
  }

  static final _wordPattern = RegExp(r'[\p{L}\p{N}]+', unicode: true);

  static List<String> _words(String text) => [
    for (final m in _wordPattern.allMatches(text)) m.group(0)!.toLowerCase(),
  ];

  /// An entry tidied for storing: trimmed, single-spaced. Null when it holds no
  /// word at all, which is not an entry.
  static String? tidy(String raw) {
    final words = _words(raw);
    return words.isEmpty ? null : raw.trim().replaceAll(RegExp(r'\s+'), ' ');
  }
}
