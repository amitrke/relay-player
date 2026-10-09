import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/tmdb/library_match.dart';
import '../../domain/models/catalog_item.dart';
import '../favorites_history/history_controller.dart';
import '../library/library_screen.dart' show libraryItemsProvider;
import '../library/library_tab.dart';
import '../metadata/tmdb_controller.dart';
import 'watch_signals.dart';

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

  final seeds = recentlyWatchedFilms(library, history).take(_maxSeeds).toList();
  if (seeds.isEmpty) return const [];

  // Anything already watched is not a suggestion.
  final watched = watchedTitles(library, history);
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
