/// Guesses a language from a panel category name, or null.
///
/// Panels file titles under categories whose names usually carry a language
/// marker by convention: a two-letter prefix ("EN | Movies", "HI - Bollywood")
/// or the language spelled out ("English Series", "Hindi Dubbed"). That is the
/// only language signal a panel gives us, so the search filter leans on it. It
/// is a heuristic and is labelled as one where it is shown.
///
/// Two-letter codes are honoured **only as the first word, in capitals**. Mid
/// name they collide with ordinary words ("IT", "DE", "HI", "AR" all appear in
/// English category titles), and a wrong guess is worse than no guess because
/// it hides a title behind the wrong filter. Spelled-out names are specific
/// enough to match anywhere.
String? languageOfCategory(String name) {
  final words = RegExp(r"[A-Za-z]+")
      .allMatches(name)
      .map((m) => m.group(0)!)
      .toList();
  if (words.isEmpty) return null;

  final first = words.first;
  if (first.length <= 3 && first == first.toUpperCase()) {
    final byCode = _codes[first];
    if (byCode != null) return byCode;
  }

  for (final word in words) {
    final byName = _names[word.toLowerCase()];
    if (byName != null) return byName;
  }
  return null;
}

const _codes = <String, String>{
  'EN': 'English',
  'ENG': 'English',
  'FR': 'French',
  'DE': 'German',
  'GER': 'German',
  'ES': 'Spanish',
  'SPA': 'Spanish',
  'IT': 'Italian',
  'PT': 'Portuguese',
  'POR': 'Portuguese',
  'NL': 'Dutch',
  'PL': 'Polish',
  'RU': 'Russian',
  'TR': 'Turkish',
  'AR': 'Arabic',
  'HI': 'Hindi',
  'TA': 'Tamil',
  'TE': 'Telugu',
  'ML': 'Malayalam',
  'KN': 'Kannada',
  'BN': 'Bengali',
  'PA': 'Punjabi',
  'UR': 'Urdu',
  'JA': 'Japanese',
  'JP': 'Japanese',
  'KO': 'Korean',
  'KR': 'Korean',
  'ZH': 'Chinese',
  'CN': 'Chinese',
};

const _names = <String, String>{
  'english': 'English',
  'french': 'French',
  'german': 'German',
  'spanish': 'Spanish',
  'italian': 'Italian',
  'portuguese': 'Portuguese',
  'dutch': 'Dutch',
  'polish': 'Polish',
  'russian': 'Russian',
  'turkish': 'Turkish',
  'arabic': 'Arabic',
  'hindi': 'Hindi',
  'tamil': 'Tamil',
  'telugu': 'Telugu',
  'malayalam': 'Malayalam',
  'kannada': 'Kannada',
  'bengali': 'Bengali',
  'punjabi': 'Punjabi',
  'urdu': 'Urdu',
  'japanese': 'Japanese',
  'korean': 'Korean',
  'chinese': 'Chinese',
  'mandarin': 'Chinese',
};
