import 'tracker.dart';

/// What an anime list should record for a finished [item], or null when it is
/// not one to send (§19.3).
///
/// AniList and MyAnimeList key everything on their own ids, and a media
/// server knows TMDB and TVDB, not those, so a title has to be found by name.
/// Anime also numbers differently: a list usually has one entry per season
/// ("Title Season 2"), where a server has one show with seasons. So the name
/// searched for is the show's, with " Season N" added after the first, and
/// the progress is the episode's number within that season. Wrong for a show
/// a server numbers absolutely across seasons, and for one a list splits
/// into "cours"; both are recorded as known gaps rather than guessed at.
({String query, int progress, bool movie})? animeTarget(WatchedItem item) {
  if (!item.isAnime) return null;
  if (!item.isEpisode) {
    return (query: item.title, progress: 1, movie: true);
  }
  final show = item.showTitle;
  final episode = item.episode;
  if (show == null || show.isEmpty || episode == null || episode < 1) {
    return null;
  }
  final season = item.season ?? 1;
  return (
    query: season > 1 ? '$show Season $season' : show,
    progress: episode,
    movie: false,
  );
}

/// The closest of [candidates] to [query]: an exact title match (any of the
/// names a list gives a title, ignoring case and punctuation) first, then the
/// service's own first result, which both rank by relevance.
T? bestAnimeMatch<T>(
  String query,
  List<T> candidates,
  Iterable<String> Function(T) titles,
) {
  if (candidates.isEmpty) return null;
  String norm(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
  final want = norm(query);
  for (final c in candidates) {
    if (titles(c).any((t) => norm(t) == want)) return c;
  }
  return candidates.first;
}
