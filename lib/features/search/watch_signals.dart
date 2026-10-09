import '../../data/local/history_store.dart';
import '../../domain/models/catalog_item.dart';

/// What the user has watched, for features that guess what they might like.
///
/// Used by TMDB's "because you watched" rows and by AI recommendations, so both
/// agree about what counts as watched.

/// Recently watched films, newest first, one per title.
///
/// From two places together: Plex's own watch state on the library items (any
/// Plex app, present from first launch) and this device's history. Episodes are
/// left out: history keeps an episode's own title and not its show's, so one
/// would be taken for a film called "Pilot". Only a film played past a minute
/// counts, since opening something for ten seconds says little about taste.
List<CatalogItem> recentlyWatchedFilms(
  List<CatalogItem> library,
  List<HistoryItem> history,
) {
  final candidates = <({CatalogItem item, DateTime at})>[
    for (final i in library)
      if (i.kind == CatalogKind.movie && i.lastViewedAt != null)
        (item: i, at: i.lastViewedAt!),
    for (final h in history)
      if (!h.isEpisode && h.position >= const Duration(minutes: 1))
        (
          item: CatalogItem(
            source: CatalogSource.plex,
            sourceId: h.sourceId,
            kind: CatalogKind.movie,
            id: h.itemId,
            title: h.title,
          ),
          at: h.lastWatchedAt,
        ),
  ]..sort((a, b) => b.at.compareTo(a.at));

  final seen = <String>{};
  return [
    for (final c in candidates)
      if (seen.add(c.item.title.toLowerCase())) c.item,
  ];
}

/// Titles to treat as already watched: anything in this device's history, and
/// anything Plex says has been played.
Set<String> watchedTitles(
  List<CatalogItem> library,
  List<HistoryItem> history,
) => {
  for (final h in history) h.title.toLowerCase(),
  for (final i in library)
    if ((i.viewCount ?? 0) > 0) i.title.toLowerCase(),
};
