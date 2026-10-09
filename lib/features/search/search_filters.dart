import '../../domain/models/catalog_item.dart';

/// The 1960s bucket also holds everything older, so the year chooser stays a
/// short list however deep a catalogue goes.
const _oldestDecade = 1960;

/// Which decade a year falls in, for the year filter.
///
/// Decades, not exact years: nobody remembers the exact year of what they are
/// looking for, and a result set is rarely big enough to need more.
int decadeOf(int year) =>
    year < _oldestDecade + 10 ? _oldestDecade : year ~/ 10 * 10;

String decadeLabel(int decade) =>
    decade == _oldestDecade ? '${decade}s and earlier' : '${decade}s';

/// The rating thresholds on offer. TMDB's scale is out of 10 and most titles
/// sit between 5 and 8, so finer steps would split nothing.
const ratingChoices = [6.0, 7.0, 8.0];

/// Orders results so the closest title matches come first.
///
/// Plex's per-library title filter is "contains", so "man" finds "Mansion" and
/// "Batman" as readily as "A Serious Man". Exact title first, then titles with the
/// query as a whole word, then a word that starts with it, then everything else. Stable within each
/// group, so sources keep the order they gave.
List<CatalogItem> rankByTitleMatch(List<CatalogItem> items, String query) {
  final needle = query.trim().toLowerCase();
  if (needle.isEmpty) return items;

  int rank(CatalogItem i) {
    final title = i.title.toLowerCase();
    if (title == needle) return 0;
    final words = title.split(RegExp(r'[^a-z0-9]+'));
    if (words.contains(needle)) return 1;
    if (words.any((w) => w.startsWith(needle))) return 2;
    return 3;
  }

  final ranked = [for (final (n, i) in items.indexed) (rank(i), n, i)];
  ranked.sort((a, b) {
    final byRank = a.$1.compareTo(b.$1);
    return byRank != 0 ? byRank : a.$2.compareTo(b.$2);
  });
  return [for (final r in ranked) r.$3];
}

/// What the search results are narrowed to. Null on a field means "any".
class SearchFilters {
  const SearchFilters({
    this.kind,
    this.sourceId,
    this.decade,
    this.language,
    this.genre,
    this.minRating,
    this.originalLanguage,
  });

  final CatalogKind? kind;
  final String? sourceId;
  final int? decade;

  /// A guess from a panel category name; see [CatalogItem.language].
  final String? language;

  /// The next three need a TMDB key. Without one no item has the data and
  /// their chips are not offered.
  final String? genre;
  final double? minRating;
  final String? originalLanguage;

  bool get isActive =>
      kind != null ||
      sourceId != null ||
      decade != null ||
      language != null ||
      genre != null ||
      minRating != null ||
      originalLanguage != null;

  /// A copy with one field replaced. Wrapped in a record so that passing null
  /// means "clear it" rather than "leave it".
  SearchFilters with_({
    (CatalogKind?,)? kind,
    (String?,)? sourceId,
    (int?,)? decade,
    (String?,)? language,
    (String?,)? genre,
    (double?,)? minRating,
    (String?,)? originalLanguage,
  }) => SearchFilters(
    kind: kind != null ? kind.$1 : this.kind,
    sourceId: sourceId != null ? sourceId.$1 : this.sourceId,
    decade: decade != null ? decade.$1 : this.decade,
    language: language != null ? language.$1 : this.language,
    genre: genre != null ? genre.$1 : this.genre,
    minRating: minRating != null ? minRating.$1 : this.minRating,
    originalLanguage: originalLanguage != null
        ? originalLanguage.$1
        : this.originalLanguage,
  );

  bool matches(CatalogItem item) {
    if (kind != null && item.kind != kind) return false;
    if (sourceId != null && item.sourceId != sourceId) return false;
    if (decade != null) {
      final year = item.year;
      if (year == null || decadeOf(year) != decade) return false;
    }
    // An item with no known language fails a language filter. It is "unknown",
    // not "any", and showing it under "Hindi" would be a guess presented as fact.
    if (language != null && item.language != language) return false;
    if (genre != null && !item.genres.contains(genre)) return false;
    // Unrated is not "low rated": it fails the filter like any unknown does.
    final rating = item.rating;
    if (minRating != null && (rating == null || rating < minRating!)) {
      return false;
    }
    if (originalLanguage != null && item.originalLanguage != originalLanguage) {
      return false;
    }
    return true;
  }

  List<CatalogItem> apply(List<CatalogItem> items) =>
      isActive ? items.where(matches).toList() : items;
}

/// The choices each filter can offer, taken from the **unfiltered** results.
///
/// Derived from what is actually there so no chip offers a dead end, and so a
/// filter that could not change anything is not offered at all: one source, one
/// kind, no recognised language.
class SearchFilterOptions {
  SearchFilterOptions._(
    this.kinds,
    this.sourceIds,
    this.decades,
    this.languages,
    this.genres,
    this.originalLanguages,
    this.hasRatings,
  );

  factory SearchFilterOptions.of(List<CatalogItem> items) {
    final kinds = <CatalogKind>{};
    final sources = <String>{};
    final decades = <int>{};
    final languages = <String>{};
    final genreCounts = <String, int>{};
    final originals = <String>{};
    var hasRatings = false;
    for (final i in items) {
      kinds.add(i.kind);
      sources.add(i.sourceId);
      if (i.year != null) decades.add(decadeOf(i.year!));
      if (i.language != null) languages.add(i.language!);
      for (final g in i.genres) {
        genreCounts[g] = (genreCounts[g] ?? 0) + 1;
      }
      if (i.originalLanguage != null) originals.add(i.originalLanguage!);
      if (i.rating != null) hasRatings = true;
    }
    return SearchFilterOptions._(
      kinds,
      sources,
      decades.toList()..sort((a, b) => b.compareTo(a)),
      languages.toList()..sort(),
      // Most common first: the genre you are likely to want is the one most of
      // the results share.
      genreCounts.keys.toList()..sort((a, b) {
        final byCount = genreCounts[b]!.compareTo(genreCounts[a]!);
        return byCount != 0 ? byCount : a.compareTo(b);
      }),
      originals.toList()..sort(),
      hasRatings,
    );
  }

  final Set<CatalogKind> kinds;
  final Set<String> sourceIds;

  /// Newest first.
  final List<int> decades;
  final List<String> languages;
  final List<String> genres;
  final List<String> originalLanguages;
  final bool hasRatings;

  bool get offersKind => kinds.length > 1;
  bool get offersSource => sourceIds.length > 1;
  bool get offersYear => decades.length > 1;
  bool get offersLanguage => languages.isNotEmpty;
  bool get offersGenre => genres.isNotEmpty;
  bool get offersRating => hasRatings;
  bool get offersOriginalLanguage => originalLanguages.length > 1;
}
