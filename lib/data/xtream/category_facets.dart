/// Where a category is from, and what kind of channel it holds, guessed from
/// its name: the two dimensions of "What do you watch?" (2026-11-03).
///
/// **Why a guess, and not the groups.** [groupCategories] groups by the
/// leading part of a name *as the panel writes it*, which is right for
/// browsing and wrong for a first choice: one real panel had "DE", "GER" and
/// "Germany" as three groups, and groups that are not places at all
/// ("BOLLYWOOD", "24/7"). A person asked "what do you watch?" answers
/// "German news and sport", so the screen offers places and kinds, and the
/// groups stay where they were, under Fine-tune.
///
/// **How sure it is.** Not very, and it says so: providers name categories
/// however they like (category_groups.dart lists what one panel did), and
/// none of this is standardised. Two rules keep a wrong guess cheap:
/// - a short code (DE, IT, US) counts only as a whole leading word, or a whole
///   part, in capitals, the same rule as `languageOfCategory`, because mid-name
///   "IT", "IN" and "US" are ordinary words;
/// - a category the guess cannot place is never dropped. It is simply not
///   reached by a chip, and Fine-tune still lists it, which the screen says.
///
/// Nothing here chooses anything: the chips set the selection the person
/// then sees and can change, as the pattern box does (§4.1).
library;

import 'category_groups.dart';

/// A region code from [regions], or null when the name gives none.
String? regionOf(String name) {
  final parts = categoryNameParts(name);
  if (parts.isEmpty) return null;
  // The leading part decides when it can; otherwise any later part that is a
  // place on its own ("SPORTS | UK").
  return _regionOfPart(parts.first, leading: true) ??
      parts.skip(1).map((p) => _regionOfPart(p, leading: false)).firstWhere(
            (r) => r != null,
            orElse: () => null,
          );
}

/// The channel kinds a live category's name mentions, from [kinds].
Set<String> kindsOf(String name) {
  final words = _words(name).map((w) => w.toLowerCase()).toList();
  final found = <String>{};
  for (final w in words) {
    final kind = _kindWords[w];
    if (kind != null) found.add(kind);
  }
  return found;
}

/// The categories a set of chips reaches: in one of [regionCodes] (any, if
/// none is chosen) and, when [kindCodes] is not empty, of one of those kinds.
/// Nothing chosen reaches nothing, which keeps §4.1's opt-in.
List<T> categoriesForFacets<T>(
  Iterable<T> categories,
  String Function(T) nameOf, {
  required Set<String> regionCodes,
  required Set<String> kindCodes,
}) {
  if (regionCodes.isEmpty && kindCodes.isEmpty) return const [];
  return [
    for (final c in categories)
      if ((regionCodes.isEmpty || regionCodes.contains(regionOf(nameOf(c)))) &&
          (kindCodes.isEmpty ||
              kindsOf(nameOf(c)).any(kindCodes.contains)))
        c,
  ];
}

/// Every region code, in the order the screen would list them when counts
/// tie. Display names are `tr.xtream.regions[code]`.
const regions = <String>[
  'uk', 'us', 'ca', 'au', 'en', 'de', 'at', 'ch', 'fr', 'be', 'nl', 'es',
  'latam', 'pt', 'br', 'it', 'pl', 'tr', 'gr', 'ro', 'ru', 'ar', 'in', 'pk',
  'af', 'jp', 'kr', 'cn',
];

/// Every kind code. Display names are `tr.xtream.kinds[code]`.
const kinds = <String>[
  'news', 'sport', 'kids', 'films', 'docs', 'music', 'entertainment',
];

String? _regionOfPart(String part, {required bool leading}) {
  final words = _words(part);
  if (words.isEmpty) return null;
  final first = words.first;
  final isCode = first.length <= 4 && first == first.toUpperCase();
  // A code counts as the first word of the leading part, or as a later part
  // that is nothing but the code.
  if (isCode && (leading || words.length == 1)) {
    final byCode = _regionCodes[first];
    if (byCode != null) return byCode;
  }
  final lower = words.map((w) => w.toLowerCase()).toList();
  for (var i = 0; i < lower.length; i++) {
    // Two-word names first ("united kingdom", "latin america").
    if (i + 1 < lower.length) {
      final pair = _regionNames['${lower[i]} ${lower[i + 1]}'];
      if (pair != null) return pair;
    }
    final single = _regionNames[lower[i]];
    if (single != null) return single;
  }
  return null;
}

List<String> _words(String text) => RegExp(r'[A-Za-zÀ-ÿ0-9]+')
    .allMatches(text)
    .map((m) => m.group(0)!)
    .toList();

const _regionCodes = <String, String>{
  'UK': 'uk', 'GB': 'uk',
  'US': 'us', 'USA': 'us',
  'CA': 'ca', 'CAN': 'ca',
  'AU': 'au', 'AUS': 'au',
  'EN': 'en', 'ENG': 'en',
  'DE': 'de', 'GER': 'de', 'DEU': 'de',
  'AT': 'at', 'AUT': 'at',
  'CH': 'ch', 'SUI': 'ch',
  'FR': 'fr', 'FRA': 'fr',
  'BE': 'be', 'BEL': 'be',
  'NL': 'nl', 'NED': 'nl',
  'ES': 'es', 'ESP': 'es', 'SPA': 'es',
  'LAT': 'latam', 'LATAM': 'latam', 'LATIN': 'latam',
  'PT': 'pt', 'POR': 'pt',
  'BR': 'br', 'BRA': 'br',
  'IT': 'it', 'ITA': 'it',
  'PL': 'pl', 'POL': 'pl',
  'TR': 'tr', 'TUR': 'tr',
  'GR': 'gr', 'GRE': 'gr',
  'RO': 'ro', 'ROM': 'ro',
  'RU': 'ru', 'RUS': 'ru',
  'AR': 'ar', 'ARA': 'ar', 'ARB': 'ar',
  'IN': 'in', 'IND': 'in', 'HI': 'in',
  'PK': 'pk', 'PAK': 'pk', 'UR': 'pk',
  'AF': 'af', 'AFR': 'af',
  'JP': 'jp', 'JA': 'jp', 'JPN': 'jp',
  'KR': 'kr', 'KO': 'kr', 'KOR': 'kr',
  'CN': 'cn', 'ZH': 'cn', 'CHN': 'cn',
};

const _regionNames = <String, String>{
  'united kingdom': 'uk', 'britain': 'uk', 'british': 'uk',
  'united states': 'us', 'usa': 'us', 'american': 'us', 'america': 'us',
  'canada': 'ca', 'canadian': 'ca',
  'australia': 'au', 'australian': 'au',
  'english': 'en',
  'germany': 'de', 'german': 'de', 'deutsch': 'de', 'deutschland': 'de',
  'austria': 'at', 'austrian': 'at', 'österreich': 'at',
  'switzerland': 'ch', 'swiss': 'ch', 'schweiz': 'ch',
  'france': 'fr', 'french': 'fr', 'français': 'fr',
  'belgium': 'be', 'belgique': 'be',
  'netherlands': 'nl', 'dutch': 'nl', 'holland': 'nl', 'nederland': 'nl',
  'spain': 'es', 'spanish': 'es', 'españa': 'es', 'espana': 'es',
  'latin america': 'latam', 'latino': 'latam', 'latin': 'latam',
  'portugal': 'pt', 'portuguese': 'pt',
  'brazil': 'br', 'brasil': 'br',
  'italy': 'it', 'italian': 'it', 'italia': 'it',
  'poland': 'pl', 'polish': 'pl', 'polska': 'pl',
  'turkey': 'tr', 'turkish': 'tr', 'türkiye': 'tr', 'turkiye': 'tr',
  'greece': 'gr', 'greek': 'gr',
  'romania': 'ro', 'romanian': 'ro',
  'russia': 'ru', 'russian': 'ru',
  'arabic': 'ar', 'arab': 'ar',
  'india': 'in', 'indian': 'in', 'hindi': 'in', 'tamil': 'in',
  'telugu': 'in', 'malayalam': 'in', 'kannada': 'in', 'bengali': 'in',
  'punjabi': 'in', 'marathi': 'in', 'gujarati': 'in', 'oriya': 'in',
  'pakistan': 'pk', 'urdu': 'pk',
  'africa': 'af', 'african': 'af',
  'japan': 'jp', 'japanese': 'jp',
  'korea': 'kr', 'korean': 'kr',
  'china': 'cn', 'chinese': 'cn', 'mandarin': 'cn',
};

/// Whole words only, so "Newsroom Classics" is not news and "Sportsbar" is
/// not sport. English first, since that is what most providers write
/// whatever the language, then the words seen most often in the languages the
/// app has drafts for.
const _kindWords = <String, String>{
  'news': 'news', 'nachrichten': 'news', 'noticias': 'news',
  'actualites': 'news', 'info': 'news',
  'sport': 'sport', 'sports': 'sport', 'football': 'sport',
  'soccer': 'sport', 'fussball': 'sport', 'futbol': 'sport', 'deportes': 'sport',
  'cricket': 'sport', 'tennis': 'sport', 'golf': 'sport', 'boxing': 'sport',
  'racing': 'sport', 'motorsport': 'sport', 'f1': 'sport', 'nba': 'sport',
  'nfl': 'sport', 'nhl': 'sport', 'ufc': 'sport', 'wwe': 'sport',
  'kids': 'kids', 'children': 'kids', 'cartoon': 'kids', 'cartoons': 'kids',
  'kinder': 'kids', 'junior': 'kids', 'enfants': 'kids', 'infantil': 'kids',
  'movies': 'films', 'movie': 'films', 'films': 'films', 'film': 'films',
  'cinema': 'films', 'kino': 'films', 'cine': 'films', 'peliculas': 'films',
  'documentary': 'docs', 'documentaries': 'docs', 'docu': 'docs',
  'doku': 'docs', 'documentaires': 'docs', 'documentales': 'docs',
  'nature': 'docs', 'science': 'docs',
  'music': 'music', 'musik': 'music', 'musica': 'music', 'musique': 'music',
  'entertainment': 'entertainment', 'general': 'entertainment',
  'unterhaltung': 'entertainment', 'variety': 'entertainment',
  'comedy': 'entertainment', 'reality': 'entertainment',
};
