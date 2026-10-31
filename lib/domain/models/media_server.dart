import 'catalog_item.dart';

/// Which kind of personal media server a [MediaServer] talks to
/// (architecture.md §6, §6.2).
///
/// Plex, Jellyfin and Emby are the same thing from the user's side: their own
/// server, their own library, signed in with their own account. That is what
/// keeps all three inside §1's primary-purpose framing, and it is why they sit
/// behind one interface rather than three features.
enum ServerKind {
  plex,
  jellyfin,
  emby;

  /// Product names, the same in every language.
  String get label => switch (this) {
    plex => 'Plex',
    jellyfin => 'Jellyfin',
    emby => 'Emby',
  };

  static ServerKind? fromName(String? name) {
    for (final k in values) {
      if (k.name == name) return k;
    }
    return null;
  }
}

/// What a library holds, as far as the app cares: films or shows. Other
/// library types (music, photos, books) are filtered out by each server.
enum MediaSectionType { movies, shows }

/// One library on one server: "Films", "4K Films", "Anime".
class MediaSection {
  const MediaSection({
    required this.id,
    required this.title,
    required this.type,
    this.typeName = '',
  });

  /// Only unique within its server; see `LibraryMapping.keyFor`.
  final String id;
  final String title;
  final MediaSectionType type;

  /// The server's own word for the library type ("movie", "tvshows"), shown in
  /// Settings so a surprising default can be understood.
  final String typeName;
}

enum MediaItemType { movie, show, season, episode, other }

/// IDs from the public databases, as the server reports them. What a watch
/// tracker (§19) matches on: titles are ambiguous, an IMDb id is not.
class ExternalIds {
  const ExternalIds({this.imdb, this.tmdb, this.tvdb});

  final String? imdb;
  final String? tmdb;
  final String? tvdb;

  bool get isEmpty => imdb == null && tmdb == null && tvdb == null;

  static const none = ExternalIds();
}

/// A titled row the server features, from [MediaServer.featuredRows].
class MediaRow {
  const MediaRow({required this.title, required this.items});

  final String title;
  final List<MediaItem> items;
}

/// One film, show, season or episode, whatever server it came from.
///
/// The neutral form of `PlexMetadata` and Jellyfin's `BaseItemDto`. Only what
/// the app reads is here; each server maps its own shape into it, so no screen
/// knows which server it is drawing.
class MediaItem {
  const MediaItem({
    required this.id,
    required this.type,
    required this.title,
    this.year,
    this.summary,
    this.genres = const [],
    this.posterPath,
    this.artPath,
    this.duration,
    this.viewCount,
    this.viewOffset,
    this.lastViewedAt,
    this.addedAt,
    this.index,
    this.parentIndex,
    this.showTitle,
    this.showId,
    this.parentId,
    this.ids = ExternalIds.none,
    this.showIds = ExternalIds.none,
    this.rating,
    this.unwatchedEpisodes,
    this.cast = const [],
  });

  final String id;
  final MediaItemType type;
  final String title;
  final int? year;
  final String? summary;
  final List<String> genres;

  /// Server-relative artwork reference, safe to persist (§3). Signed or made
  /// absolute by `MediaServer.posterUrlForPath` when shown.
  final String? posterPath;

  /// Server-relative landscape artwork (Plex `art`, a Jellyfin backdrop), for
  /// the TV library's backdrop (§12.4). Safe to persist for the same reason
  /// as [posterPath]; signed by `MediaServer.posterUrlForPath` at a landscape
  /// size when shown. An episode falls back to its show's.
  final String? artPath;

  final Duration? duration;

  /// Times watched by this account; null when the server does not say.
  final int? viewCount;

  /// Resume point, if part-watched.
  final Duration? viewOffset;
  final DateTime? lastViewedAt;
  final DateTime? addedAt;

  /// Episode number within its season, or season number for a season.
  final int? index;

  /// Season number, for an episode.
  final int? parentIndex;

  /// The show an episode or season belongs to.
  final String? showTitle;
  final String? showId;

  /// The season an episode belongs to.
  final String? parentId;

  /// This item's own external IDs (an episode's are the episode's).
  final ExternalIds ids;

  /// The show's IDs, for an episode, when the server reports them.
  final ExternalIds showIds;

  /// Out of 10, when the server has one.
  final double? rating;

  /// For a show this account has started, how many of its episodes it has
  /// not watched; null for anything else, for a show not yet started, and
  /// when the server does not say. What lets a poster say a show you watch
  /// has something new, which Plex's own apps do with a count in the corner
  /// (compared on a TV, 2026-10-30). Not-started shows were counted too until
  /// the same day, and on a large server nearly every poster said "99+".
  final int? unwatchedEpisodes;

  /// Leading actors, billing order, at most six: what Plex's own TV app shows
  /// under a title's plot (§12.4). Empty when the server sent none, which a
  /// library listing often does; a title's own fetch carries them.
  final List<String> cast;

  bool get isWatched => (viewCount ?? 0) > 0;
}

/// A playable stream plus the metadata the player needs to label it.
class MediaPlayable {
  const MediaPlayable({
    required this.url,
    required this.title,
    required this.duration,
    this.posterPath,
    this.resumeFrom,
    this.isEpisode = false,
    this.item,
  });

  /// Carries a credential on most servers (§3): used, never stored.
  final String url;
  final String title;
  final Duration duration;
  final String? posterPath;

  /// The server's own resume point. It beats this device's history: the user
  /// may have watched on another client.
  final Duration? resumeFrom;
  final bool isEpisode;

  /// The item itself, for anything that needs more than a label (a watch
  /// tracker needs its external IDs).
  final MediaItem? item;
}

/// What a download needs to fetch one item and label the copy (§18).
///
/// [url] carries the server's credential, so this lives for one fetch and is
/// never stored.
class MediaDownloadSource {
  const MediaDownloadSource({
    required this.url,
    required this.title,
    required this.duration,
    required this.extension,
    required this.isEpisode,
    this.sizeBytes,
    this.posterPath,
    this.headers = const {},
  });

  final String url;
  final String title;
  final Duration duration;

  /// The container, as a file extension (`mkv`, `mp4`).
  final String extension;
  final bool isEpisode;
  final int? sizeBytes;
  final String? posterPath;

  /// Sent with the request, for servers that take the credential in a header
  /// rather than the URL. Never stored either.
  final Map<String, String> headers;
}

/// The server could not be reached, or would not give us what was asked.
/// The message is fit to show.
class MediaServerUnreachable implements Exception {
  const MediaServerUnreachable(this.message);
  final String message;

  @override
  String toString() => message;
}

/// One connected personal media server (§6, §6.2).
///
/// Everything a screen, the player, downloads, offline sync or a watch tracker
/// asks of a server goes through this. Each method answers in the neutral
/// [MediaItem] shape; the server's own JSON never leaves its implementation.
abstract class MediaServer {
  String get id;
  String get name;
  ServerKind get kind;
  bool get isConnected;

  /// Where the server answers, once connected. Used to prefer a copy on the
  /// local network when two servers have the same title (library_dedupe.dart).
  String? get baseUrl;

  /// Film and show libraries only.
  Future<List<MediaSection>> sections();

  /// Every title in [section], films or shows.
  Future<List<MediaItem>> allItems(MediaSection section);

  /// Titles matching [query] in [sections] only; empty [sections] searches
  /// nothing (a library hidden in Settings is hidden from search too).
  Future<List<MediaItem>> searchIn(
    List<MediaSection> sections,
    String query, {
    int perSection = 20,
  });

  Future<MediaItem?> item(String id);

  /// Seasons of a show, or episodes of a season. A show with no seasons may
  /// answer with its episodes directly.
  Future<List<MediaItem>> children(String id);

  /// Every episode of a show, across seasons.
  Future<List<MediaItem>> episodesOf(String showId);

  /// Part-watched titles and next episodes, across [sections].
  Future<List<MediaItem>> onDeck(List<MediaSection> sections);

  /// Rows the server's owner has chosen to feature for [section], such as a
  /// collection pinned to the library's recommendations ("Deleting Soon",
  /// a seasonal pick), in the server's order. Empty when the server has no
  /// such idea, which is the default; Plex implements it (§12.4).
  Future<List<MediaRow>> featuredRows(MediaSection section) async => const [];

  Future<void> setWatched(String id, {required bool watched});

  /// [state] is `playing`, `paused` or `stopped`.
  Future<void> reportProgress({
    required String id,
    required String state,
    required Duration position,
    required Duration duration,
  });

  Future<MediaPlayable> directPlay(String id);
  Future<MediaDownloadSource> downloadSource(String id);

  /// A displayable URL for a stored [MediaItem.posterPath], or null when it
  /// cannot be made right now (not connected).
  String? posterUrlForPath(String path, {int width = 320, int height = 480});

  String? posterUrl(MediaItem item) {
    final path = item.posterPath;
    return path == null ? null : posterUrlForPath(path);
  }

  /// [item] in the shared catalogue shape (§2). [shelf] names its row.
  CatalogItem toCatalogItem(MediaItem item, {String? shelf}) => CatalogItem(
    source: CatalogSource.server,
    sourceId: id,
    kind: item.type == MediaItemType.show
        ? CatalogKind.show
        : CatalogKind.movie,
    id: item.id,
    title: item.title,
    year: item.year,
    posterUrl: posterUrl(item),
    posterPath: item.posterPath,
    artPath: item.artPath,
    summary: item.summary,
    addedAt: item.addedAt,
    viewCount: item.viewCount,
    viewOffset: item.viewOffset,
    duration: item.duration,
    lastViewedAt: item.lastViewedAt,
    unwatchedEpisodes: item.unwatchedEpisodes,
    cast: item.cast,
    shelf: shelf,
  );
}
