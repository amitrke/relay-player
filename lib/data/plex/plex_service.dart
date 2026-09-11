import 'dart:io';

import 'package:dart_plex/dart_plex.dart';

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
  });

  final String url;
  final String title;
  final Duration duration;
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
  PlexService({required String clientId})
      : _client = PlexClient(
          credentials: PlexCredentials(
            clientIdentifier: clientId,
            product: 'Relay Player',
            version: '0.1.0',
            device: Platform.operatingSystem,
            deviceName: Platform.localHostname,
            platform: Platform.operatingSystem,
          ),
        );

  final PlexClient _client;

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

  /// Connects to [server], preferring a LAN route over the Plex relay.
  String connectTo(PlexResource server) {
    final uri = server.bestConnection()?.uri;
    if (uri == null) {
      throw PlexUnreachable('"${server.name}" has no usable connection.');
    }
    _client.connect(uri.toString(), accessToken: server.accessToken);
    return uri.toString();
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

  /// Every item of [type], merged across all sections of that type.
  ///
  /// §12 screen 3: Plex libraries merge into Movies and Series rather than
  /// showing one tab per section. Someone with both "Films" and "4K Films"
  /// thinks of the contents as movies, not as two libraries.
  Future<List<PlexMetadata>> itemsOfType(
    PlexLibraryType type, {
    int perSection = 60,
  }) async {
    final wanted = (await sections()).where((s) => s.type == type);
    final pages =
        await Future.wait(wanted.map((s) => items(s, size: perSection)));
    return pages.expand((page) => page).toList()
      ..sort(
        (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
      );
  }

  /// Server-side search across every library (§12 screen 8).
  ///
  /// Uses Plex's own index rather than filtering a local list — the catalogue
  /// is far too large to hold in memory, which is the §4.1 lesson applied to
  /// Plex rather than Xtream.
  Future<List<PlexMetadata>> search(String query, {int limit = 40}) async {
    if (query.trim().isEmpty) return const [];
    final results = await _client.search.flat(query: query, limit: limit);
    const playable = {
      PlexMetadataType.movie,
      PlexMetadataType.show,
      PlexMetadataType.episode,
    };
    return results.where((m) => playable.contains(m.type)).toList();
  }

  Future<PlexMetadata?> item(String ratingKey) =>
      _client.library.item(ratingKey);

  /// Seasons of a show, or episodes of a season.
  Future<List<PlexMetadata>> children(String ratingKey) =>
      _client.library.children(ratingKey);

  String? posterUrl(PlexMetadata item, {int width = 320, int height = 480}) {
    final thumb = item.thumb ?? item.parentThumb ?? item.grandparentThumb;
    if (thumb == null || thumb.isEmpty || !isConnected) return null;
    return _client.images.transcodeUrl(
      sourcePath: thumb,
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

    return PlexPlayable(
      url: '$base${part.key}?X-Plex-Token=$token',
      title: item.title,
      duration: Duration(milliseconds: item.durationMs ?? 0),
    );
  }
}
