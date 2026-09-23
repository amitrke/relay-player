import 'dart:async';
import 'dart:io';

import 'package:dart_plex/dart_plex.dart';

import '../../domain/models/catalog_item.dart';

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

/// A playable stream plus the metadata the player needs to label it.
class PlexPlayable {
  const PlexPlayable({
    required this.url,
    required this.title,
    required this.duration,
    this.posterUrl,
    this.posterPath,
    this.resumeFrom,
  });

  final String url;
  final String title;
  final Duration duration;
  final String? posterUrl;

  /// The unsigned artwork path behind [posterUrl]. This is what gets persisted;
  /// see [PlexService.posterPathOf].
  final String? posterPath;

  /// Plex's own `viewOffset`. The server is the better authority here: the user
  /// may have watched part of this in the Plex app on another device.
  final Duration? resumeFrom;
}

/// A Plex item together with the server it came from.
///
/// A `ratingKey` is only meaningful relative to one server — two servers will
/// happily both have a `/library/metadata/1234`. Once more than one server is
/// connected, an item without its origin cannot be fetched, played, or even
/// have its poster loaded, so the pair travels together everywhere.
class SourcedItem {
  const SourcedItem({required this.serverId, required this.metadata});

  final String serverId;
  final PlexMetadata metadata;
}

/// Raised when the account has no server we can reach.
class PlexUnreachable implements Exception {
  const PlexUnreachable(this.message);
  final String message;

  @override
  String toString() => message;
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
class PlexService {
  PlexService({required String clientId, this.serverId = '', this.serverName = ''})
      : _client = PlexClient(
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

  String? get baseUrl => _client.baseUrl;
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
    return servers.toList()
      ..sort((a, b) {
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
      (
        server.connections.where((c) => c.relay),
        const Duration(seconds: 6),
      ),
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
    throw PlexUnreachable(
      '"${server.name}" did not answer on any of its '
      '${server.connections.length} advertised addresses.',
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

  /// Video sections only. Music and photo libraries are out of scope for §6.
  Future<List<PlexLibrarySection>> sections() async {
    final all = await _client.library.sections();
    return all
        .where((s) =>
            s.type == PlexLibraryType.movie || s.type == PlexLibraryType.show)
        .toList();
  }

  Future<List<PlexMetadata>> items(
    PlexLibrarySection section, {
    int start = 0,
    int size = 60,
  }) async {
    final container = await _client.library.allByType(
      sectionId: section.id,
      type: section.type == PlexLibraryType.show
          ? PlexMetadataType.show
          : PlexMetadataType.movie,
      start: start,
      size: size,
      sort: 'titleSort',
    );
    return container.items;
  }

  /// Items from [wanted], merged and sorted by title.
  ///
  /// §12 screen 3 merges libraries into Movies and Series rather than showing
  /// one tab per section, so someone with "Films" and "4K Films" sees one list.
  /// *Which* libraries feed a tab is the caller's decision — Plex's library type
  /// is only a default, and the user can override it.
  Future<List<SourcedItem>> itemsFrom(
    List<PlexLibrarySection> wanted, {
    int perSection = 60,
  }) async {
    if (wanted.isEmpty) return const [];
    final pages =
        await Future.wait(wanted.map((s) => items(s, size: perSection)));
    return [for (final item in pages.expand((page) => page)) sourced(item)];
  }

  SourcedItem sourced(PlexMetadata metadata) =>
      SourcedItem(serverId: serverId, metadata: metadata);

  /// Plex metadata as the shared catalogue shape (§2).
  ///
  /// Artwork is resolved here because a Plex thumb needs the server's token on
  /// the query string — the widget that renders it has no way to rebuild that.
  CatalogItem toCatalogItem(PlexMetadata metadata) => CatalogItem(
        source: CatalogSource.plex,
        sourceId: serverId,
        kind: metadata.type == PlexMetadataType.show
            ? CatalogKind.show
            : CatalogKind.movie,
        id: metadata.ratingKey,
        title: metadata.title,
        year: metadata.year,
        posterUrl: posterUrl(metadata),
        addedAt: metadata.addedAt,
        viewCount: metadata.viewCount,
        viewOffset: _ms(metadata.viewOffsetMs),
        duration: _ms(metadata.durationMs),
        lastViewedAt: metadata.lastViewedAt,
      );

  static Duration? _ms(int? ms) => ms == null ? null : Duration(milliseconds: ms);

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
  Future<List<PlexMetadata>> onDeck(
    List<PlexLibrarySection> sections, {
    int perSection = 12,
  }) async {
    final pages = await Future.wait(sections.map((s) => _client.hubs
        .sectionOnDeck(sectionId: s.id, count: perSection)
        .catchError((_) => const <PlexMetadata>[])));
    return pages.expand((p) => p).toList();
  }

  /// Server-side search across every library (§12 screen 8).
  ///
  /// Uses Plex's own index rather than filtering a local list — the catalogue
  /// is far too large to hold in memory, which is the §4.1 lesson applied to
  /// Plex rather than Xtream.
  Future<List<SourcedItem>> search(String query, {int limit = 40}) async {
    if (query.trim().isEmpty) return const [];
    final results = await _client.search.flat(query: query, limit: limit);
    const playable = {
      PlexMetadataType.movie,
      PlexMetadataType.show,
      PlexMetadataType.episode,
    };
    return [
      for (final m in results)
        if (playable.contains(m.type)) sourced(m),
    ];
  }

  Future<PlexMetadata?> item(String ratingKey) =>
      _client.library.item(ratingKey);

  /// Reports playback progress to Plex (§6).
  ///
  /// Not merely bookkeeping: without it Subnext Player is a bad citizen on the
  /// user's own server — the Plex app would show nothing watched, and
  /// continue-watching would disagree between clients. Plex asks for a tick
  /// roughly every 10s plus one on each state change.
  Future<void> reportProgress({
    required String ratingKey,
    required String state,
    required Duration position,
    required Duration duration,
  }) async {
    await _client.playback.timeline(
      ratingKey: ratingKey,
      state: state,
      timeMs: position.inMilliseconds,
      durationMs: duration.inMilliseconds,
    );
  }

  /// Seasons of a show, or episodes of a season.
  Future<List<PlexMetadata>> children(String ratingKey) =>
      _client.library.children(ratingKey);

  String? posterUrl(PlexMetadata item, {int width = 320, int height = 480}) {
    final thumb = posterPathOf(item);
    if (thumb == null) return null;
    return posterUrlForPath(thumb, width: width, height: height);
  }

  /// The server-relative artwork path, which is the only form safe to persist.
  ///
  /// §3: [posterUrl] signs this into an image *transcode* URL, and Plex's
  /// image transcoder is authenticated, so the signed form carries
  /// `X-Plex-Token`. Anything that outlives the process — history in
  /// particular — stores what this returns and re-signs on read. Storing the
  /// signed URL instead put a live token in the unencrypted Hive box, which is
  /// the defect STORE_LISTING.md's §15 check was written to catch.
  static String? posterPathOf(PlexMetadata item) {
    final thumb = item.thumb ?? item.parentThumb ?? item.grandparentThumb;
    return (thumb == null || thumb.isEmpty) ? null : thumb;
  }

  /// Signs a stored artwork path for display.
  ///
  /// Null when not connected, which is the reason history keeps the path
  /// rather than the result: a cached signed URL would appear to work while
  /// offline and would still be a token on disk.
  String? posterUrlForPath(String path, {int width = 320, int height = 480}) {
    if (path.isEmpty || !isConnected) return null;
    return _client.images.transcodeUrl(
      sourcePath: path,
      width: width,
      height: height,
    );
  }

  // --- Playback --------------------------------------------------------

  /// Resolves [ratingKey] to a direct-play URL.
  ///
  /// Direct play is the media Part key — `/library/parts/{id}/{ts}/file.mp4`, a
  /// plain file served with byte ranges, which media_kit treats like any
  /// progressive source. It is **not** `universalVideoUrl(directPlay: true)`:
  /// that still routes through `/video/:/transcode/universal/`, and Phase 0
  /// caught the server saying so ("App cannot direct play this item").
  Future<PlexPlayable> directPlay(String ratingKey) async {
    final item = await _client.library.item(ratingKey);
    if (item == null) {
      throw const PlexUnreachable('That item is no longer on the server.');
    }

    final part = item.media
        .expand((m) => m.parts)
        .where((p) => (p.key ?? '').isNotEmpty)
        .firstOrNull;
    if (part == null) {
      throw const PlexUnreachable(
        'No playable file on this item. Transcode-only sources are not '
        'supported yet.',
      );
    }

    final base = _client.baseUrl;
    final token = _client.token;
    if (base == null || token == null) {
      throw const PlexUnreachable('Not connected to a Plex server.');
    }

    final offset = item.viewOffsetMs ?? 0;
    return PlexPlayable(
      url: '$base${part.key}?X-Plex-Token=$token',
      title: item.title,
      duration: Duration(milliseconds: item.durationMs ?? 0),
      posterUrl: posterUrl(item),
      posterPath: posterPathOf(item),
      resumeFrom: offset > 0 ? Duration(milliseconds: offset) : null,
    );
  }
}
