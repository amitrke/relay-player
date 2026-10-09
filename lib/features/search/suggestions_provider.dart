import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/tmdb/library_match.dart';
import '../../domain/models/catalog_item.dart';
import '../favorites_history/history_controller.dart';
import '../library/library_screen.dart' show libraryItemsProvider;
import '../library/library_tab.dart';
import '../metadata/tmdb_controller.dart';

/// "Because you watched [seedTitle]": titles the user has that TMDB considers
/// close to it.
class Suggestion {
  const Suggestion(this.seedTitle, this.items);

  final String seedTitle;
  final List<CatalogItem> items;
}

/// How many recent films seed suggestions, and how many titles each row keeps.
const _maxSeeds = 4;
const _maxPerRow = 14;

/// Suggestions for the empty Search screen. Empty whenever there is nothing
/// honest to show: no TMDB key, nothing watched, or no recommendation that the
/// user actually has.
///
/// Seeds are the most recently watched *films*, from Plex's own watch state and
/// this device's history together. Episodes are skipped (see the comment where
/// seeds are chosen); a series-aware seed is a follow-up that needs the show
/// title stored.
///
final suggestionsProvider = FutureProvider<List<Suggestion>>((ref) async {
  final enricher = await ref.watch(tmdbEnricherProvider.future);
  if (enricher == null) return const [];

  // The library first: Plex records what this account watched in any app, which
  // is a better signal than this device's own history and is there from the
  // first launch.
  final library = <CatalogItem>[];
  for (final tab in [LibraryTab.movies, LibraryTab.series]) {
    try {
      library.addAll(await ref.watch(libraryItemsProvider(tab).future));
    } catch (_) {}
  }
  if (library.isEmpty) return const [];

  final history = ref.watch(historyProvider);

  // Candidate seeds from both places, newest first, one per title.
  final candidates = <({CatalogItem item, DateTime at})>[
    for (final i in library)
      if (i.kind == CatalogKind.movie && i.lastViewedAt != null)
        (item: i, at: i.lastViewedAt!),
    for (final h in history)
      // History keeps an episode's own title, not its show's, so an episode
      // would be looked up as a film called "Pilot". Only a film watched past
      // a glance says anything about taste.
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

  final seeds = <CatalogItem>[];
  final seenTitles = <String>{};
  for (final c in candidates) {
    if (!seenTitles.add(c.item.title.toLowerCase())) continue;
    seeds.add(c.item);
    if (seeds.length == _maxSeeds) break;
  }
  if (seeds.isEmpty) return const [];

  // Anything already watched is not a suggestion.
  final watched = {
    for (final h in history) h.title.toLowerCase(),
    for (final i in library)
      if ((i.viewCount ?? 0) > 0) i.title.toLowerCase(),
  };
  final shownKeys = <String>{};

  final rows = <Suggestion>[];
  for (final seed in seeds) {
    final recs = await enricher.recommendationsFor(seed);
    final matched =
        matchRecommendations(
              recs.candidates,
              library,
              tv: recs.tv,
              exclude: shownKeys,
            )
            .where((i) => !watched.contains(i.title.toLowerCase()))
            .take(_maxPerRow)
            .toList();

    if (matched.isEmpty) continue;
    shownKeys.addAll(matched.map((i) => i.key));
    rows.add(Suggestion(seed.title, matched));
  }
  return rows;
});
