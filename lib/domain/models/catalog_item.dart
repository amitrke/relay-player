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
    this.addedAt,
    this.viewCount,
    this.viewOffset,
    this.duration,
    this.lastViewedAt,
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

  /// Where tapping this item leads.
  ///
  /// A show has no file of its own and resolves to seasons and episodes; a movie
  /// resolves straight to a stream.
  String get route => switch ((source, kind)) {
        (CatalogSource.plex, CatalogKind.show) => '/show/$sourceId/$id',
        (CatalogSource.plex, CatalogKind.movie) => '/play/$sourceId/$id',
        (CatalogSource.xtream, CatalogKind.show) =>
          '/advanced/xtream/$sourceId/series/$id',
        (CatalogSource.xtream, CatalogKind.movie) =>
          '/vod/$sourceId/$id',
      };

  String get sortKey => title.toLowerCase();
}
