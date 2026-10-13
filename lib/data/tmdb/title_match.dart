// Turning a source's title into something TMDB can find, and choosing among
// what it returns.
//
// Plex titles are usually clean. A panel's are not: "EN - The Film (2019) 4K"
// or "The.Film.2019.1080p.WEB-DL" are ordinary. Matching those wrongly is
// worse than not matching, because a wrong match puts a title under someone
// else's genre and rating, so [pickBest] prefers to return nothing.

/// A title with the decoration a source adds taken off, and the year if one was
/// tucked into it.
class CleanedTitle {
  const CleanedTitle(this.title, this.year);

  final String title;
  final int? year;
}

final _bracketed = RegExp(r'[\(\[\{][^\)\]\}]*[\)\]\}]');
final _yearIn = RegExp(r'[\(\[]((?:19|20)\d{2})[\)\]]');
final _languagePrefix = RegExp(
  r'^\s*[|\[]?\s*[A-Z]{2,3}\s*[|\]]?\s*[-:|]\s*(?=\S)',
);
final _trailingYear = RegExp(r'[\s.]((?:19|20)\d{2})\s*$');
final _quality = RegExp(
  r'\b(4k|uhd|fhd|hd|sd|2160p|1080p|720p|480p|bluray|blu-ray|bdrip|brrip|'
  r'web-?dl|webrip|hdrip|dvdrip|hdr10?|hdr|x264|x265|h\.?264|h\.?265|hevc|'
  r'dubbed|dual|multi|subbed|remux|extended|unrated|imax)\b',
  caseSensitive: false,
);

CleanedTitle cleanTitle(String raw) {
  var s = raw;

  // A year in brackets is the most reliable one, so take it before the
  // brackets are thrown away.
  int? year;
  final bracketYear = _yearIn.firstMatch(s);
  if (bracketYear != null) year = int.parse(bracketYear.group(1)!);

  s = s.replaceAll(_bracketed, ' ');

  // "Name.2019.1080p" style: dots stand in for spaces.
  if (!s.contains(' ') && (s.contains('.') || s.contains('_'))) {
    s = s.replaceAll(RegExp(r'[._]'), ' ');
  }

  s = s.replaceFirst(_languagePrefix, '');
  s = s.replaceAll(_quality, ' ');
  s = s.replaceAll(RegExp(r'\s+'), ' ').trim();

  final trailing = _trailingYear.firstMatch(s);
  if (trailing != null && s.length > trailing.group(0)!.length) {
    year ??= int.parse(trailing.group(1)!);
    s = s.substring(0, trailing.start).trim();
  }

  s = s.replaceAll(RegExp(r'[\s\-:|]+$'), '').trim();
  return CleanedTitle(s, year);
}

/// Lower-case, letters and digits only, so "Spider-Man: Homecoming" and
/// "Spider Man Homecoming" compare equal.
String normalizeTitle(String s) =>
    s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();

/// One search hit, reduced to what matching needs.
class TmdbCandidate {
  const TmdbCandidate({
    required this.id,
    required this.title,
    required this.originalTitle,
    this.year,
  });

  final int id;
  final String title;
  final String originalTitle;
  final int? year;
}

/// The right candidate, or null when nothing is convincing.
///
/// TMDB ranks by relevance, so the first hit is usually right, but "usually" is
/// not enough to hang a rating on. With a year, a hit must be within a year of
/// it (sources and TMDB disagree about release dates by that much). Without
/// one, a hit must match the title exactly.
TmdbCandidate? pickBest(
  List<TmdbCandidate> candidates,
  String title,
  int? year,
) {
  final wanted = normalizeTitle(title);

  bool titleMatches(TmdbCandidate c) =>
      normalizeTitle(c.title) == wanted ||
      normalizeTitle(c.originalTitle) == wanted;

  if (year != null) {
    final close = [
      for (final c in candidates)
        if (c.year != null && (c.year! - year).abs() <= 1) c,
    ];
    if (close.isEmpty) return null;
    return close.firstWhere(titleMatches, orElse: () => close.first);
  }

  for (final c in candidates) {
    if (titleMatches(c)) return c;
  }
  return null;
}
