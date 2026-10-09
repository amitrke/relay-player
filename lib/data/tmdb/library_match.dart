import '../../domain/models/catalog_item.dart';
import 'title_match.dart';

/// Which of TMDB's recommendations the user actually has.
///
/// This is the rule that keeps "because you watched" a library-navigation aid
/// and not a way to find things to acquire (§9.2): TMDB proposes, and only what
/// already sits in a connected source survives. A recommendation with no match
/// here is dropped, never shown.
///
/// A match needs the same title (either of TMDB's two), the same kind, and a
/// year within one when both sides know it. Titles are compared after the same
/// cleaning a panel's names get for TMDB lookups, so "EN - Parasite (2019) 4K"
/// on a panel is found by TMDB's "Parasite".
///
/// [candidates] is in TMDB's relevance order and the result keeps it, with at
/// most one item per candidate. Anything
/// whose [CatalogItem.key] is in [exclude] is left out, which is how the seed
/// itself and what was already watched stay out.
List<CatalogItem> matchRecommendations(
  List<TmdbCandidate> candidates,
  List<CatalogItem> library, {
  required bool tv,
  Set<String> exclude = const {},
}) {
  final byTitle = <String, List<CatalogItem>>{};
  for (final item in library) {
    if ((item.kind == CatalogKind.show) != tv) continue;
    final cleaned = cleanTitle(item.title);
    byTitle.putIfAbsent(normalizeTitle(cleaned.title), () => []).add(item);
  }

  bool yearCompatible(CatalogItem item, int? candidateYear) {
    final year = item.year ?? cleanTitle(item.title).year;
    if (year == null || candidateYear == null) return true;
    return (year - candidateYear).abs() <= 1;
  }

  final seen = <String>{};
  final out = <CatalogItem>[];
  for (final c in candidates) {
    final pool = [
      ...?byTitle[normalizeTitle(c.title)],
      if (normalizeTitle(c.originalTitle) != normalizeTitle(c.title))
        ...?byTitle[normalizeTitle(c.originalTitle)],
    ];
    // One copy per recommendation. The same film on two sources is one
    // suggestion, and the library's own order decides which copy: Plex first.
    for (final item in pool) {
      if (exclude.contains(item.key) || !yearCompatible(item, c.year)) continue;
      if (seen.contains(item.key)) continue;
      seen.add(item.key);
      out.add(item);
      break;
    }
  }
  return out;
}
