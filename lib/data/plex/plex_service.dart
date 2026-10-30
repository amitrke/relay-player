import 'dart:async';
import 'dart:io';

import 'package:dart_plex/dart_plex.dart';

import '../../domain/models/media_server.dart';
import 'paging.dart';
import '../../i18n/strings.g.dart';

/// A 4-character code the user types at plex.tv/link.
class PlexLinkCode {
  const PlexLinkCode({
    required this.pinId,
    required this.code,
    required this.expiresAt,
  });

  final int pinId;
  final String code;
  final DateTime expiresAt;
}

/// The app's single entry point to Plex.
///
/// §6 adopted `dart_plex` "with two mandatory workarounds and standing
/// caution". Both workarounds live here and nowhere else, so no caller can
/// forget one:
///
/// 1. [startLink] must pass `strong: false`. The package defaults to `true`,
///    which yields a 25-character code that plex.tv/link will not accept — it
///    does not error, it just hands you an unusable PIN.
/// 2. Any universal-transcode URL needs `hasMDE=1` appended, which the package
///    never emits. Modern PMS answers a bare 400 without it.
///
/// Phase 0 verified 1 and root-caused 2, but only *direct play* was proven to
/// run end to end. The transcode lifecycle (decision → ping → stop) is still
/// open, with a leaked server-side session as the named risk, so this class
/// deliberately exposes direct play only.
class PlexService extends MediaServer {
  PlexService({
    required String clientId,
    this.serverId = '',
    this.serverName = '',
  }) : _client = PlexClient(
         credentials: PlexCredentials(
           clientIdentifier: clientId,
           product: 'Subnext Player',
           version: '0.1.0',
           device: Platform.operatingSystem,
           deviceName: Platform.localHostname,
           platform: Platform.operatingSystem,
         ),
       );

  final PlexClient _client;

  /// Empty while this instance is only doing account-level work (the PIN flow
  /// and server discovery), set once it is bound to a server.
  final String serverId;
  final String serverName;

  @override
  String? get baseUrl => _client.baseUrl;
  @override
  bool get isConnected => _client.baseUrl != null && _client.token != null;

  // --- Linking ---------------------------------------------------------

  Future<PlexLinkCode> startLink() async {
    final pin = await _client.account.createPin(strong: false);
    if (pin.code.length != 4) {
      // Guard the regression rather than trusting the parameter: if a future
      // version changes the default or the response shape, fail loudly instead
      // of showing the user a code nothing will accept.
      throw StateError(
        'Expected a 4-character link code, got ${pin.code.length}. '
        'Check the `strong` flag on createPin.',
      );
    }
    return PlexLinkCode(
      pinId: pin.id,
      code: pin.code,
      expiresAt: pin.expiresAt,
    );
  }

  /// Returns the auth token once the user approves, or null while still
  /// pending.
  Future<String?> pollLink(int pinId) async {
    final pin = await _client.account.pollPin(pinId);
    final token = pin.authToken;
    return (token == null || token.isEmpty) ? null : token;
  }

  void useToken(String token) => _client.setToken(token);

  // --- Servers ---------------------------------------------------------

  /// Every server this account can reach, owned first.
  Future<List<PlexResource>> servers() async {
    final resources = await _client.account.fetchResources();
    final servers = resources.where((r) => r.provides.contains('server'));
    return servers.toList()..sort((a, b) {
      if (a.owned == b.owned) return a.name.compareTo(b.name);
      return a.owned ? -1 : 1;
    });
  }

  /// Connects to [server] using a route that actually answers.
  ///
  /// Deliberately not `bestConnection()`. That picks the first `local &&
  /// !relay` candidate unconditionally, and `local` is plex.tv's guess that the
  /// server shares a LAN with whoever asked. For a server *shared with you*
  /// that candidate is a private address on someone else's network: connecting
  /// to an unroutable RFC1918 address is not refused, it hangs until the OS
  /// gives up, so a shared server appeared to be an endless spinner rather than
  /// an error. Plex's own `relay: true` on the resource says there is no direct
  /// path, and `bestConnection()` hands back the dead LAN candidate anyway.
  ///
  /// So candidates are probed instead, in tiers, racing within each tier and
  /// taking the first that responds. The tier order keeps the LAN preference
  /// that is right for an owned server on the same network, while the timeouts
  /// mean a wrong guess costs seconds rather than the whole connection.
  Future<String> connectTo(PlexResource server) async {
    final tiers = <(Iterable<PlexServerConnection>, Duration)>[
      // Short: if a LAN address is wrong it is unroutable, and the point is to
      // stop waiting on it quickly.
      (
        server.connections.where((c) => c.local && !c.relay),
        const Duration(seconds: 2),
      ),
      (
        server.connections.where((c) => !c.local && !c.relay),
        const Duration(seconds: 4),
      ),
      // Relay last and slowest: it is the fallback that usually works for a
      // shared server, and it is not fast.
      (server.connections.where((c) => c.relay), const Duration(seconds: 6)),
    ];

    for (final (candidates, timeout) in tiers) {
      final uri = await _firstThatAnswers(
        candidates.toList(growable: false),
        server.accessToken,
        timeout,
      );
      if (uri != null) {
        _client.connect(uri, accessToken: server.accessToken);
        return uri;
      }
    }
    throw MediaServerUnreachable(
      tr.plex.errors.noAnswer(
        server: server.name,
        count: server.connections.length,
      ),
    );
  }

  /// Races [candidates], returning the first URI that responds, or null.
  Future<String?> _firstThatAnswers(
    List<PlexServerConnection> candidates,
    String token,
    Duration timeout,
  ) {
    if (candidates.isEmpty) return Future.value(null);

    final done = Completer<String?>();
    var outstanding = candidates.length;
    for (final candidate in candidates) {
      // _answers never throws, so every probe settles and `outstanding`
      // always reaches zero.
      _answers(candidate.uri, token, timeout).then((ok) {
        if (ok && !done.isCompleted) {
          done.complete(candidate.uri);
        } else if (--outstanding == 0 && !done.isCompleted) {
          done.complete(null);
        }
      });
    }
    return done.future;
  }

  /// Whether something at [uri] responds as a Plex server. Never throws.
  ///
  /// `/identity` is the cheapest endpoint that proves a server is there: it
  /// needs no token and returns the machine identifier.
  Future<bool> _answers(String uri, String token, Duration timeout) async {
    final client = HttpClient()..connectionTimeout = timeout;
    try {
      // connectionTimeout bounds the TCP connect, which is the hang this
      // exists to escape. The outer timeout covers the other half: a peer that
      // accepts the connection and then never answers.
      final response = await Future(() async {
        final request = await client.getUrl(Uri.parse('$uri/identity'));
        request.headers.set('X-Plex-Token', token);
        request.headers.set('Accept', 'application/json');
        return request.close();
      }).timeout(timeout);
      await response.drain<void>();
      // Any answer at all means the transport works; a 401 would be an auth
      // problem worth reporting rather than a reason to try another address.
      return response.statusCode < 500;
    } catch (_) {
      return false;
    } finally {
      client.close(force: true);
    }
  }

  /// Reconnects a restored session without re-running discovery.
  void reconnect({required String baseUrl, required String token}) {
    _client.setToken(token);
    _client.connect(baseUrl);
  }

  // --- Library ---------------------------------------------------------

  @override
  String get id => serverId;

  @override
  String get name => serverName;

  @override
  ServerKind get kind => ServerKind.plex;

  /// Video sections only. Music and photo libraries are out of scope for §6.
  @override
  Future<List<MediaSection>> sections() async {
    final all = await _client.library.sections();
    return [
      for (final s in all)
        if (s.type == PlexLibraryType.movie || s.type == PlexLibraryType.show)
          MediaSection(
            id: s.id,
            title: s.title,
            type: s.type == PlexLibraryType.show
                ? MediaSectionType.shows
                : MediaSectionType.movies,
            typeName: s.type.name,
          ),
    ];
  }

  static PlexMetadataType _typeOf(MediaSection section) =>
      section.type == MediaSectionType.shows
      ? PlexMetadataType.show
      : PlexMetadataType.movie;

  Future<PlexMediaContainer<PlexMetadata>> _page(
    MediaSection section,
    int start,
    int size,
  ) => _client.library.allByType(
    sectionId: section.id,
    type: _typeOf(section),
    start: start,
    size: size,
    sort: 'titleSort',
  );

  /// Every title in [section], sorted by title, page by page.
  ///
  /// Until 2026-10-09 the library asked for the first 60 of each section and
  /// stopped, so a Plex library showed (and the AI search could see) only its
  /// first 60 titles alphabetically. The rest were on the server, reachable by
  /// searching for them by name, and absent from every list built on this one:
  /// found when "James Bond movies" found no Bond film that the Continue
  /// watching row was showing.
  ///
  /// A show library also asks for its newest episodes, so each show carries
  /// when its latest episode arrived rather than when the show itself was
  /// first added (see [CatalogItem.addedAt]).
  @override
  Future<List<MediaItem>> allItems(MediaSection section) async {
    final (titles, newest) = await (
      readAllPages<PlexMetadata>((start, size) async {
        final page = await _page(section, start, size);
        return (total: page.totalSize, items: page.items);
      }),
      section.type == MediaSectionType.shows
          ? newestEpisodes(section)
          : Future.value(const <String, DateTime>{}),
    ).wait;
    return [
      for (final m in titles) itemOf(m, newestEpisodeAt: newest[m.ratingKey]),
    ];
  }

  /// How many recent episodes [newestEpisodes] reads. Enough for every show
  /// with an episode in roughly the last few months on a busy server.
  static const newestEpisodeWindow = 500;

  /// When each show's newest episode arrived, for the shows among a library's
  /// latest [newestEpisodeWindow] episodes, keyed by the show's `ratingKey`.
  ///
  /// A show's own metadata has no such date: `addedAt` is when the show was
  /// first added, and `updatedAt` moves on any metadata refresh. Plex's own
  /// "Recently Added in TV Shows" row is built from episodes, so this is too:
  /// one request for the section's episodes, newest first.
  ///
  /// A show outside the window keeps its own date. That is never later than
  /// its true newest episode, which is older than everything in the window,
  /// so every show inside still sorts above every show outside, which is the
  /// part a person sees. Failure leaves every show on its own date rather
  /// than failing the library: worse ordering, nothing missing.
  Future<Map<String, DateTime>> newestEpisodes(MediaSection section) async {
    try {
      final page = await _client.library.allByType(
        sectionId: section.id,
        type: PlexMetadataType.episode,
        size: newestEpisodeWindow,
        sort: 'addedAt:desc',
      );
      final newest = <String, DateTime>{};
      for (final e in page.items) {
        final show = e.grandparentRatingKey;
        final added = e.addedAt;
        if (show == null || added == null) continue;
        // Asked for newest first, but kept as a max, not first-seen, so a
        // server that ignores `sort` still gives the right answer.
        final seen = newest[show];
        if (seen == null || added.isAfter(seen)) newest[show] = added;
      }
      return newest;
    } catch (_) {
      return const {};
    }
  }

  /// Plex metadata in the neutral shape every screen reads (§6.2).
  ///
  /// [newestEpisodeAt], for a show, replaces its `addedAt` when later.
  static MediaItem itemOf(PlexMetadata m, {DateTime? newestEpisodeAt}) =>
      MediaItem(
        id: m.ratingKey,
        type: switch (m.type) {
          PlexMetadataType.movie => MediaItemType.movie,
          PlexMetadataType.show => MediaItemType.show,
          PlexMetadataType.season => MediaItemType.season,
          PlexMetadataType.episode => MediaItemType.episode,
          _ => MediaItemType.other,
        },
        title: m.title,
        year: m.year,
        summary: m.summary,
        genres: m.genres,
        posterPath: posterPathOf(m),
        artPath: artPathOf(m),
        duration: _ms(m.durationMs),
        viewCount: m.viewCount,
        viewOffset: _ms(m.viewOffsetMs),
        lastViewedAt: m.lastViewedAt,
        addedAt: _later(m.addedAt, newestEpisodeAt),
        index: m.index,
        parentIndex: m.parentIndex,
        showTitle: m.grandparentTitle ?? m.parentTitle,
        showId: m.grandparentRatingKey ?? m.parentRatingKey,
        parentId: m.parentRatingKey,
        ids: idsOf(m.raw),
        rating: m.rating ?? m.userRating,
        unwatchedEpisodes: m.type == PlexMetadataType.show
            ? unwatchedOf(m.raw)
            : null,
      );

  /// A show's unwatched episodes from `leafCount` (its episodes) and
  /// `viewedLeafCount` (those this account has watched). dart_plex 0.1.2 does
  /// not parse either, so they come from the raw JSON. Null unless both are
  /// there.
  static int? unwatchedOf(Map<String, dynamic> raw) {
    final all = raw['leafCount'];
    final seen = raw['viewedLeafCount'];
    if (all is! int || seen is! int) return null;
    return all > seen ? all - seen : 0;
  }

  static DateTime? _later(DateTime? a, DateTime? b) =>
      a == null ? b : (b == null || a.isAfter(b) ? a : b);

  /// External IDs from Plex's `Guid` tags (`imdb://tt0111161`, `tmdb://278`,
  /// `tvdb://81189`). The new Plex agents put these on an item's own
  /// metadata; older libraries matched by legacy agents carry a single
  /// `guid` like `com.plexapp.agents.imdb://tt0111161?lang=en` instead, which
  /// is read as a fallback.
  static ExternalIds idsOf(Map<String, dynamic> raw) {
    String? imdb, tmdb, tvdb;
    void take(String value) {
      final m = RegExp(r'(imdb|tmdb|tvdb|themoviedb|thetvdb)://([^?/]+)')
          .firstMatch(value);
      if (m == null) return;
      final id = m.group(2)!;
      switch (m.group(1)) {
        case 'imdb':
          imdb ??= id;
        case 'tmdb' || 'themoviedb':
          tmdb ??= id;
        case 'tvdb' || 'thetvdb':
          tvdb ??= id;
      }
    }

    final tags = raw['Guid'];
    if (tags is List) {
      for (final t in tags) {
        if (t is Map && t['id'] is String) take(t['id'] as String);
      }
    }
    if (raw['guid'] is String) take(raw['guid'] as String);
    return ExternalIds(imdb: imdb, tmdb: tmdb, tvdb: tvdb);
  }

  static Duration? _ms(int? ms) =>
      ms == null ? null : Duration(milliseconds: ms);

  /// Marks an item watched or unwatched for this account (`/:/scrobble`,
  /// `/:/unscrobble`). On a show or season Plex applies it to every episode
  /// beneath, and unwatched also clears the resume position.
  @override
  Future<void> setWatched(String id, {required bool watched}) =>
      watched ? _client.playback.scrobble(id) : _client.playback.unscrobble(id);

  /// What Plex thinks this account is in the middle of, across [sections].
  ///
  /// Per-library On Deck (`/library/sections/{id}/onDeck`) rather than the
  /// global `/hubs/continueWatching`: Plex nests the hub's items inside a
  /// `Hub` element, while `dart_plex` 0.1.2 parses that call as though they
  /// were top-level, so it would most likely come back empty. Per section also
  /// means a library the user hid from Movies and Series stays hidden here.
  ///
  /// On Deck holds both kinds of entry: something part-watched (with a
  /// `viewOffset`), and the next unwatched episode of a show in progress
  /// (without one).
  @override
  Future<List<MediaItem>> onDeck(List<MediaSection> sections) async {
    final pages = await Future.wait(
      sections.map(
        (s) => _client.hubs
            .sectionOnDeck(sectionId: s.id, count: 12)
            .catchError((_) => const <PlexMetadata>[]),
      ),
    );
    return [for (final m in pages.expand((p) => p)) itemOf(m)];
  }

  /// Search restricted to [sections], one library at a time.
  ///
  /// Plex's `/search` has no library filter and no section id on its results, so
  /// a hidden library cannot be dropped afterwards: found 2026-10-08, when the
  /// first two rows of a search for "man" were course recordings from a library
  /// hidden in Settings → Sources, which the Movies and Series tabs had always
  /// respected. `/hubs/search?sectionId=` looks like the fix and is not: this
  /// server answered every `sectionId` with the same unscoped hubs (identical
  /// counts for different libraries), so it was ignored. What does scope is a
  /// library's own listing, `/library/sections/{id}/all`, with a `title`
  /// filter, which the server reads as "contains". That is looser than the hub
  /// search's word matching ("man" also finds "Batman"), the price of a search
  /// that can be limited to the libraries the user kept.
  ///
  /// An empty [sections] searches nothing rather than falling back to
  /// everything, because "the user hid every library" must not mean "search all
  /// of them".
  @override
  Future<List<MediaItem>> searchIn(
    List<MediaSection> sections,
    String query, {
    int perSection = 20,
  }) async {
    final needle = query.trim();
    if (needle.isEmpty || sections.isEmpty) return const [];
    final perLibrary = await Future.wait(
      sections.map((s) async {
        try {
          final page = await _client.library.allByType(
            sectionId: s.id,
            type: _typeOf(s),
            size: perSection,
            sort: 'titleSort',
            filters: [
              PlexFilter(field: 'title', values: [needle]),
            ],
          );
          return page.items;
        } catch (_) {
          // One library failing should cost its own matches, not the others'.
          return const <PlexMetadata>[];
        }
      }),
    );
    return [for (final m in perLibrary.expand((items) => items)) itemOf(m)];
  }

  @override
  Future<MediaItem?> item(String id) async {
    final m = await _client.library.item(id);
    return m == null ? null : itemOf(m);
  }

  /// Reports playback progress to Plex (§6).
  ///
  /// Not merely bookkeeping: without it Subnext Player is a bad citizen on the
  /// user's own server — the Plex app would show nothing watched, and
  /// continue-watching would disagree between clients. Plex asks for a tick
  /// roughly every 10s plus one on each state change.
  @override
  Future<void> reportProgress({
    required String id,
    required String state,
    required Duration position,
    required Duration duration,
  }) async {
    await _client.playback.timeline(
      ratingKey: id,
      state: state,
      timeMs: position.inMilliseconds,
      durationMs: duration.inMilliseconds,
    );
  }

  /// Seasons of a show, or episodes of a season.
  @override
  Future<List<MediaItem>> children(String id) async => [
    for (final m in await _client.library.children(id)) itemOf(m),
  ];

  /// Every episode of a show, across seasons, in one request (`allLeaves`).
  /// What an episode rule (§18.7) plans from: one call per show rather than
  /// one per season.
  @override
  Future<List<MediaItem>> episodesOf(String showId) async => [
    for (final m in await _client.library.allLeaves(showId)) itemOf(m),
  ];

  /// The server-relative artwork path, which is the only form safe to persist.
  ///
  /// §3: a displayable URL signs this into an image *transcode* URL, and
  /// Plex's image transcoder is authenticated, so the signed form carries
  /// `X-Plex-Token`. Anything that outlives the process — history in
  /// particular — stores what this returns and re-signs on read. Storing the
  /// signed URL instead put a live token in the unencrypted Hive box, which is
  /// the defect STORE_LISTING.md's §15 check was written to catch.
  /// Landscape art, an episode's or season's falling back to its show's.
  /// dart_plex parses `art` only, so the parents' come from the raw JSON.
  static String? artPathOf(PlexMetadata item) {
    for (final a in [
      item.art,
      item.raw['grandparentArt'],
      item.raw['parentArt'],
    ]) {
      if (a is String && a.isNotEmpty) return a;
    }
    return null;
  }

  static String? posterPathOf(PlexMetadata item) {
    final thumb = item.thumb ?? item.parentThumb ?? item.grandparentThumb;
    return (thumb == null || thumb.isEmpty) ? null : thumb;
  }

  /// Signs a stored artwork path for display.
  ///
  /// Null when not connected, which is the reason history keeps the path
  /// rather than the result: a cached signed URL would appear to work while
  /// offline and would still be a token on disk.
  @override
  String? posterUrlForPath(String path, {int width = 320, int height = 480}) {
    if (path.isEmpty || !isConnected) return null;
    return _client.images.transcodeUrl(
      sourcePath: path,
      width: width,
      height: height,
    );
  }

  // --- Playback --------------------------------------------------------

  /// Resolves [id] to a direct-play URL.
  ///
  /// Direct play is the media Part key — `/library/parts/{id}/{ts}/file.mp4`, a
  /// plain file served with byte ranges, which media_kit treats like any
  /// progressive source. It is **not** `universalVideoUrl(directPlay: true)`:
  /// that still routes through `/video/:/transcode/universal/`, and Phase 0
  /// caught the server saying so ("App cannot direct play this item").
  @override
  Future<MediaPlayable> directPlay(String id) async {
    final (item, part) = await _itemAndPart(id);
    final (base, token) = _credentials();

    final offset = item.viewOffsetMs ?? 0;
    return MediaPlayable(
      url: '$base${part.key}?X-Plex-Token=$token',
      title: item.title,
      duration: Duration(milliseconds: item.durationMs ?? 0),
      posterPath: posterPathOf(item),
      resumeFrom: offset > 0 ? Duration(milliseconds: offset) : null,
      isEpisode: item.type == PlexMetadataType.episode,
      item: itemOf(item),
    );
  }

  /// The item and the file direct play (and a download) would use.
  Future<(PlexMetadata, PlexPart)> _itemAndPart(String id) async {
    final item = await _client.library.item(id);
    if (item == null) {
      throw MediaServerUnreachable(tr.plex.errors.itemGone);
    }

    final part = item.media
        .expand((m) => m.parts)
        .where((p) => (p.key ?? '').isNotEmpty)
        .firstOrNull;
    if (part == null) {
      throw MediaServerUnreachable(tr.plex.errors.noFile);
    }
    return (item, part);
  }

  (String, String) _credentials() {
    final base = _client.baseUrl;
    final token = _client.token;
    if (base == null || token == null) {
      throw MediaServerUnreachable(tr.plex.errors.notConnected);
    }
    return (base, token);
  }

  /// Resolves [id] to the original file, for saving on this device (§18).
  ///
  /// The same Part key direct play streams, fetched whole instead of watched,
  /// so nothing here is a transcode and the server does no work beyond
  /// serving a file. Called again whenever a download starts or resumes
  /// rather than remembered, because the URL carries the token (§3) and the
  /// server's address may have changed since.
  @override
  Future<MediaDownloadSource> downloadSource(String id) async {
    final (item, part) = await _itemAndPart(id);
    final (base, token) = _credentials();
    final container = (part.container ?? '').toLowerCase();
    final fromKey = RegExp(r'\.([A-Za-z0-9]{2,5})$').firstMatch(part.key!);
    return MediaDownloadSource(
      url: '$base${part.key}?X-Plex-Token=$token',
      title: item.title,
      duration: Duration(milliseconds: item.durationMs ?? 0),
      extension: container.isNotEmpty
          ? container
          : (fromKey?.group(1) ?? 'mkv'),
      isEpisode: item.type == PlexMetadataType.episode,
      sizeBytes: part.size,
      posterPath: posterPathOf(item),
    );
  }
}
