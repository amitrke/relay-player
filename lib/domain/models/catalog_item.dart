/// Which kind of source produced an item.
enum CatalogSource { plex, xtream }

/// What the item is, which decides where tapping it goes.
enum CatalogKind { movie, show }

/// One browsable catalogue entry, whatever produced it.
///
/// §2: "Xtream, M3U, and Plex all fit a `ContentRepository` interface ... because
/// they're all fundamentally category/item catalogs." This is that common shape.
/// Until it existed the grid rendered `PlexMetadata` directly, which worked only
/// for as long as Plex was the sole catalogue.
///
/// [sourceId] is load-bearing rather than decoration: a Plex `ratingKey` and an
/// Xtream `stream_id` are both small ids that collide freely between servers and
/// panels, so nothing may be fetched, played, or favourited by [id] alone.
class CatalogItem {
  const CatalogItem({
    required this.source,
    required this.sourceId,
    required this.kind,
    required this.id,
    required this.title,
    this.year,
    this.posterUrl,
    this.posterPath,
    this.addedAt,
    this.viewCount,
    this.viewOffset,
    this.duration,
    this.lastViewedAt,
    this.language,
    this.genres = const [],
    this.rating,
    this.originalLanguage,
  });

  final CatalogSource source;
  final String sourceId;
  final CatalogKind kind;

  /// Plex `ratingKey`, or Xtream `stream_id` / `series_id`.
  final String id;

  final String title;
  final int? year;

  /// Already resolved and authenticated — Plex artwork needs a token on the
  /// query string, so the URL cannot be rebuilt by the widget that shows it.
  final String? posterUrl;

  /// The unsigned artwork reference, for Plex: a server-relative path that
  /// [posterUrl] was made from. The one form that is safe to write to disk
  /// (section 3), since the signed URL carries `X-Plex-Token`; the library cache
  /// stores this and signs it again when it reads. Null for a panel, whose
  /// [posterUrl] is an absolute address with no credential in it.
  final String? posterPath;

  /// When the item arrived in its source, for "Recently added". Plex reports
  /// it per item. Panels report `added` for films and only `last_modified` for
  /// series, which moves when an episode is added: close enough for sorting,
  /// and the nearest thing a panel offers. Null when a source says nothing,
  /// and such items sort last.
  final DateTime? addedAt;

  /// Plex's per-account watch state, as the library fetch saw it. Null for
  /// panels, which keep none, and for Plex shows, whose watched state lives in
  /// episode counts `dart_plex` 0.1.2 does not parse. `WatchState.resolve`
  /// combines these with this device's history.
  final int? viewCount;
  final Duration? viewOffset;
  final Duration? duration;
  final DateTime? lastViewedAt;

  /// Display name of the language, when something told us ("English", "Hindi").
  ///
  /// **Inferred, not read.** `dart_plex` 0.1.2 does not parse a language off
  /// Plex metadata and a panel has no such field, so this is guessed from the
  /// category a panel title was filed under (`languageOfCategory`). Null means
  /// "unknown", never "English": every Plex item and any panel category with no
  /// recognisable marker is null, and a language filter must say so rather than
  /// treat the gap as a language.
  final String? language;

  /// From TMDB, when the user has given a key and a lookup matched. Empty,
  /// null and null mean "not looked up or not found", never "no genres".
  final List<String> genres;

  /// TMDB's average vote out of 10.
  final double? rating;

  /// Display name of the *original* language. Distinct from [language], which
  /// is a guess at what a panel copy is dubbed in: a Korean film dubbed into
  /// English has `originalLanguage` Korean and `language` English.
  final String? originalLanguage;

  /// Stable across rebuilds, unique across sources. [id] alone is not: a Plex
  /// `ratingKey` and a panel `stream_id` collide freely.
  String get key => '${source.name}|$sourceId|$id';

  /// This item with its artwork URL replaced, for re-signing a cached Plex path.
  CatalogItem withPosterUrl(String? url) => CatalogItem(
        source: source,
        sourceId: sourceId,
        kind: kind,
        id: id,
        title: title,
        year: year,
        posterUrl: url,
        posterPath: posterPath,
        addedAt: addedAt,
        viewCount: viewCount,
        viewOffset: viewOffset,
        duration: duration,
        lastViewedAt: lastViewedAt,
        language: language,
        genres: genres,
        rating: rating,
        originalLanguage: originalLanguage,
      );

  CatalogItem withMetadata({
    required List<String> genres,
    double? rating,
    String? originalLanguage,
  }) =>
      CatalogItem(
        source: source,
        sourceId: sourceId,
        kind: kind,
        id: id,
        title: title,
        year: year,
        posterUrl: posterUrl,
        posterPath: posterPath,
        addedAt: addedAt,
        viewCount: viewCount,
        viewOffset: viewOffset,
        duration: duration,
        lastViewedAt: lastViewedAt,
        language: language,
        genres: genres,
        rating: rating,
        originalLanguage: originalLanguage,
      );

  /// Where tapping this item leads.
  ///
  /// A show has no file of its own and resolves to seasons and episodes; a movie
  /// resolves straight to a stream.
  String get route => switch ((source, kind)) {
    (CatalogSource.plex, CatalogKind.show) => '/show/$sourceId/$id',
    (CatalogSource.plex, CatalogKind.movie) => '/play/$sourceId/$id',
    (CatalogSource.xtream, CatalogKind.show) =>
      '/advanced/xtream/$sourceId/series/$id',
    (CatalogSource.xtream, CatalogKind.movie) => '/vod/$sourceId/$id',
  };

  String get sortKey => title.toLowerCase();
}
