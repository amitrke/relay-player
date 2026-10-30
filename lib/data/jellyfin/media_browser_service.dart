import 'dart:io';

import 'package:dio/dio.dart';

import '../../domain/models/media_server.dart';
import '../../i18n/strings.g.dart';
import '../plex/paging.dart';

/// What a server says about itself before anyone signs in.
class MediaBrowserServerInfo {
  const MediaBrowserServerInfo({
    required this.id,
    required this.name,
    required this.kind,
    required this.version,
    required this.apiBase,
  });

  /// The server's own `Id`: stable across renames and address changes.
  final String id;
  final String name;
  final ServerKind kind;
  final String version;

  /// Where the API answered, with no trailing slash. Usually the address the
  /// person typed; `.../emby` for an Emby server that only answers there.
  final String apiBase;
}

/// A signed-in user on a server.
class MediaBrowserAuth {
  const MediaBrowserAuth({
    required this.userId,
    required this.userName,
    required this.token,
  });

  final String userId;
  final String userName;

  /// Secret (§3): secure storage only.
  final String token;
}

/// A Quick Connect code on screen, and the secret that claims it.
class QuickConnectCode {
  const QuickConnectCode({required this.code, required this.secret});

  /// Six digits the person types on a device already signed in to Jellyfin.
  final String code;
  final String secret;
}

/// Who this app is, as the server's auth header wants it.
class MediaBrowserClientInfo {
  const MediaBrowserClientInfo({
    required this.deviceId,
    this.client = 'Subnext Player',
    this.device = '',
    this.version = '1.0',
  });

  /// Stable per install: the server lists sessions and devices by it, and a
  /// new one per launch would fill the server's device list.
  final String deviceId;
  final String client;
  final String device;
  final String version;
}

/// Jellyfin and Emby (architecture.md §6.2).
///
/// One client for both. Jellyfin began as a fork of Emby and the two still
/// share the API this uses: `/Users/{id}/Items`, `/Shows`, `/Sessions/Playing`,
/// `/Videos/{id}/stream`. Where they differ it is in how a request
/// authenticates, so that, and only that, branches on [kind]:
///
/// - **Jellyfin** takes `Authorization: MediaBrowser ..., Token="..."` and an
///   `ApiKey` query parameter on media URLs.
/// - **Emby** takes `X-Emby-Authorization` with an `X-Emby-Token` header, and
///   `api_key` on media URLs.
///
/// Both forms are as documented by each project; neither has been run against
/// a real server from this app yet (MANUAL_TESTING.md).
///
/// **Artwork carries no credential.** Both servers serve `/Items/{id}/Images`
/// without auth, so the poster path stored on disk and the URL built from it
/// are free of tokens, unlike Plex's (§3).
class MediaBrowserService extends MediaServer {
  MediaBrowserService({
    required this.info,
    required this.auth,
    required this.client,
    Dio? dio,
  }) : _dio = dio ?? _defaultDio();

  final MediaBrowserServerInfo info;
  final MediaBrowserClientInfo client;
  /// Holds the token: never written anywhere but secure storage (§3).
  final MediaBrowserAuth auth;
  final Dio _dio;

  /// Started playbacks, so the first progress report says "started" and the
  /// rest say "progress", as the session API expects.
  final _started = <String>{};

  static Dio _defaultDio() => Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      responseType: ResponseType.json,
    ),
  );

  @override
  String get id => info.id;

  @override
  String get name => info.name;

  @override
  ServerKind get kind => info.kind;

  @override
  String? get baseUrl => info.apiBase;

  @override
  bool get isConnected => auth.token.isNotEmpty;

  String get _user => auth.userId;

  /// The fields every item request asks for, so one parse serves all of them.
  ///
  /// `DateLastMediaAdded` is a series' newest episode's arrival, which is what
  /// a show's "Recently added" date means here (CatalogItem.addedAt). A
  /// series' `UnplayedItemCount` is in `UserData` and needs no field.
  static const _fields =
      'ProviderIds,Genres,Overview,DateCreated,DateLastMediaAdded,'
      'ProductionYear,CommunityRating,PrimaryImageAspectRatio,'
      'SeriesPrimaryImageTag,ParentId';

  Map<String, String> get _headers =>
      authHeaders(kind: kind, client: client, token: auth.token);

  /// The auth header for [kind], with [token] once signed in.
  static Map<String, String> authHeaders({
    required ServerKind kind,
    required MediaBrowserClientInfo client,
    String? token,
  }) {
    String q(String s) => s.replaceAll('"', "'");
    final value =
        'MediaBrowser Client="${q(client.client)}", '
        'Device="${q(client.device.isEmpty ? Platform.operatingSystem : client.device)}", '
        'DeviceId="${q(client.deviceId)}", Version="${q(client.version)}"'
        '${token == null || token.isEmpty ? '' : ', Token="${q(token)}"'}';
    return kind == ServerKind.emby
        ? {
            'X-Emby-Authorization': value,
            if (token != null && token.isNotEmpty) 'X-Emby-Token': token,
          }
        : {'Authorization': value};
  }

  /// The query parameter that carries the token on a media URL.
  String get _tokenParam => kind == ServerKind.emby ? 'api_key' : 'ApiKey';

  Future<dynamic> _get(String path, [Map<String, dynamic>? query]) async {
    try {
      final r = await _dio.get<dynamic>(
        '${info.apiBase}$path',
        queryParameters: query,
        options: Options(headers: _headers),
      );
      return r.data;
    } on DioException catch (e) {
      throw MediaServerUnreachable(_describe(e, info.name));
    }
  }

  Future<dynamic> _send(
    String method,
    String path, {
    Object? body,
    Map<String, dynamic>? query,
  }) async {
    try {
      final r = await _dio.request<dynamic>(
        '${info.apiBase}$path',
        data: body,
        queryParameters: query,
        options: Options(method: method, headers: _headers),
      );
      return r.data;
    } on DioException catch (e) {
      throw MediaServerUnreachable(_describe(e, info.name));
    }
  }

  static String _describe(DioException e, String server) {
    final status = e.response?.statusCode;
    if (status == 401 || status == 403) {
      return tr.mediaBrowser.errors.signedOut(server: server);
    }
    if (status != null) {
      return tr.mediaBrowser.errors.status(server: server, code: status);
    }
    return tr.mediaBrowser.errors.unreachable(server: server);
  }

  // --- Signing in ------------------------------------------------------

  /// Finds a server at [address] and says what it is, before any sign-in.
  ///
  /// Tries the address as typed, then with `/emby` added, which is where an
  /// Emby server answers when it has no reverse proxy in front.
  static Future<MediaBrowserServerInfo> probe(String address, {Dio? dio}) async {
    final http = dio ?? _defaultDio();
    final base = normaliseAddress(address);
    for (final candidate in [base, '$base/emby']) {
      try {
        final r = await http.get<dynamic>('$candidate/System/Info/Public');
        final data = r.data;
        if (data is Map && data['Id'] is String) {
          final product = '${data['ProductName'] ?? ''}'.toLowerCase();
          return MediaBrowserServerInfo(
            id: data['Id'] as String,
            name: '${data['ServerName'] ?? address}',
            // Jellyfin says "Jellyfin Server"; Emby says "Emby Server", and
            // older Emby builds say nothing, so anything else is Emby.
            kind: product.contains('jellyfin')
                ? ServerKind.jellyfin
                : ServerKind.emby,
            version: '${data['Version'] ?? ''}',
            apiBase: candidate,
          );
        }
      } on DioException {
        // Try the next form.
      }
    }
    throw MediaServerUnreachable(tr.mediaBrowser.errors.notAServer);
  }

  /// `nas:8096`, `http://nas:8096/`, `https://jf.example` all become a base
  /// URL with a scheme and no trailing slash. No port is added: someone who
  /// typed a host behind a proxy means that host.
  static String normaliseAddress(String address) {
    var a = address.trim();
    if (!a.contains('://')) a = 'http://$a';
    while (a.endsWith('/')) {
      a = a.substring(0, a.length - 1);
    }
    return a;
  }

  static MediaBrowserAuth _authFrom(dynamic data) {
    if (data is! Map || data['AccessToken'] is! String) {
      throw MediaServerUnreachable(tr.mediaBrowser.errors.badAnswer);
    }
    final user = data['User'];
    return MediaBrowserAuth(
      userId: user is Map ? '${user['Id']}' : '',
      userName: user is Map ? '${user['Name'] ?? ''}' : '',
      token: data['AccessToken'] as String,
    );
  }

  static Future<MediaBrowserAuth> signIn(
    MediaBrowserServerInfo info,
    MediaBrowserClientInfo client, {
    required String username,
    required String password,
    Dio? dio,
  }) async {
    final http = dio ?? _defaultDio();
    try {
      final r = await http.post<dynamic>(
        '${info.apiBase}/Users/AuthenticateByName',
        data: {'Username': username, 'Pw': password},
        options: Options(
          headers: authHeaders(kind: info.kind, client: client),
        ),
      );
      return _authFrom(r.data);
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 401 || status == 403) {
        throw MediaServerUnreachable(tr.mediaBrowser.errors.wrongLogin);
      }
      throw MediaServerUnreachable(_describe(e, info.name));
    }
  }

  /// Whether the server offers Quick Connect (Jellyfin 10.7 and later, when
  /// the admin has it switched on). Emby has no such thing.
  static Future<bool> quickConnectEnabled(
    MediaBrowserServerInfo info, {
    Dio? dio,
  }) async {
    if (info.kind != ServerKind.jellyfin) return false;
    try {
      final r = await (dio ?? _defaultDio()).get<dynamic>(
        '${info.apiBase}/QuickConnect/Enabled',
      );
      return r.data == true || r.data == 'true';
    } on DioException {
      return false;
    }
  }

  static Future<QuickConnectCode> startQuickConnect(
    MediaBrowserServerInfo info,
    MediaBrowserClientInfo client, {
    Dio? dio,
  }) async {
    try {
      final r = await (dio ?? _defaultDio()).post<dynamic>(
        '${info.apiBase}/QuickConnect/Initiate',
        options: Options(headers: authHeaders(kind: info.kind, client: client)),
      );
      final data = r.data;
      if (data is! Map || data['Code'] == null || data['Secret'] == null) {
        throw MediaServerUnreachable(tr.mediaBrowser.errors.badAnswer);
      }
      return QuickConnectCode(
        code: '${data['Code']}',
        secret: '${data['Secret']}',
      );
    } on DioException catch (e) {
      throw MediaServerUnreachable(_describe(e, info.name));
    }
  }

  /// The signed-in user once [code] has been approved, or null while it is
  /// still waiting.
  static Future<MediaBrowserAuth?> pollQuickConnect(
    MediaBrowserServerInfo info,
    MediaBrowserClientInfo client,
    QuickConnectCode code, {
    Dio? dio,
  }) async {
    final http = dio ?? _defaultDio();
    final headers = authHeaders(kind: info.kind, client: client);
    try {
      final state = await http.get<dynamic>(
        '${info.apiBase}/QuickConnect/Connect',
        queryParameters: {'Secret': code.secret},
        options: Options(headers: headers),
      );
      final data = state.data;
      if (data is! Map || data['Authenticated'] != true) return null;
      final r = await http.post<dynamic>(
        '${info.apiBase}/Users/AuthenticateWithQuickConnect',
        data: {'Secret': code.secret},
        options: Options(headers: headers),
      );
      return _authFrom(r.data);
    } on DioException catch (e) {
      throw MediaServerUnreachable(_describe(e, info.name));
    }
  }

  // --- Library ---------------------------------------------------------

  @override
  Future<List<MediaSection>> sections() async {
    final data = await _get('/Users/$_user/Views');
    final items = data is Map ? data['Items'] : null;
    if (items is! List) return const [];
    return [
      for (final v in items)
        if (v is Map)
          if (switch ('${v['CollectionType'] ?? ''}') {
            'movies' => MediaSectionType.movies,
            'tvshows' => MediaSectionType.shows,
            // A "mixed" library has no CollectionType; it is usually home
            // video, which plays as films.
            '' => MediaSectionType.movies,
            _ => null,
          }
              case final type?)
            MediaSection(
              id: '${v['Id']}',
              title: '${v['Name'] ?? ''}',
              type: type,
              typeName: '${v['CollectionType'] ?? 'mixed'}',
            ),
    ];
  }

  static String _typesOf(MediaSection s) =>
      s.type == MediaSectionType.shows ? 'Series' : 'Movie';

  @override
  Future<List<MediaItem>> allItems(MediaSection section) async =>
      readAllPages<MediaItem>((start, size) async {
        final data = await _get('/Users/$_user/Items', {
          'ParentId': section.id,
          'IncludeItemTypes': _typesOf(section),
          'Recursive': 'true',
          'Fields': _fields,
          'SortBy': 'SortName',
          'SortOrder': 'Ascending',
          'StartIndex': '$start',
          'Limit': '$size',
        });
        return _page(data);
      });

  ({int total, List<MediaItem> items}) _page(dynamic data) {
    if (data is! Map) return (total: 0, items: const []);
    final items = [
      for (final i in (data['Items'] as List?) ?? const [])
        if (i is Map<String, dynamic>) itemOf(i),
    ];
    final total = data['TotalRecordCount'];
    return (total: total is int ? total : items.length, items: items);
  }

  List<MediaItem> _items(dynamic data) => _page(data).items;

  /// A `BaseItemDto` in the neutral shape (§6.2).
  static MediaItem itemOf(Map<String, dynamic> j) {
    final type = switch ('${j['Type']}') {
      'Movie' || 'Video' => MediaItemType.movie,
      'Series' => MediaItemType.show,
      'Season' => MediaItemType.season,
      'Episode' => MediaItemType.episode,
      _ => MediaItemType.other,
    };
    final user = j['UserData'] is Map ? j['UserData'] as Map : const {};
    final id = '${j['Id']}';
    final seriesId = j['SeriesId'] is String ? j['SeriesId'] as String : null;
    final tags = j['ImageTags'] is Map ? j['ImageTags'] as Map : const {};
    final ownPoster = tags['Primary'] != null;
    final posterOf = ownPoster
        ? id
        : (j['SeriesPrimaryImageTag'] != null ? seriesId : null);
    final played = user['Played'] == true;
    final playCount = user['PlayCount'];
    return MediaItem(
      id: id,
      type: type,
      title: '${j['Name'] ?? ''}',
      year: j['ProductionYear'] is int ? j['ProductionYear'] as int : null,
      summary: j['Overview'] as String?,
      genres: [
        for (final g in (j['Genres'] as List?) ?? const []) '$g',
      ],
      posterPath: posterOf == null ? null : '/Items/$posterOf/Images/Primary',
      duration: _ticks(j['RunTimeTicks']),
      viewCount: played
          ? (playCount is int && playCount > 0 ? playCount : 1)
          : 0,
      viewOffset: _ticks(user['PlaybackPositionTicks']),
      lastViewedAt: DateTime.tryParse('${user['LastPlayedDate'] ?? ''}'),
      // A series' newest episode when the server says, else its own date.
      addedAt: type == MediaItemType.show
          ? DateTime.tryParse('${j['DateLastMediaAdded'] ?? ''}') ??
                DateTime.tryParse('${j['DateCreated'] ?? ''}')
          : DateTime.tryParse('${j['DateCreated'] ?? ''}'),
      index: j['IndexNumber'] is int ? j['IndexNumber'] as int : null,
      parentIndex: j['ParentIndexNumber'] is int
          ? j['ParentIndexNumber'] as int
          : null,
      showTitle: j['SeriesName'] as String?,
      showId: seriesId,
      parentId: (j['SeasonId'] ?? j['ParentId']) as String?,
      ids: _ids(j['ProviderIds']),
      rating: (j['CommunityRating'] as num?)?.toDouble(),
      unwatchedEpisodes:
          type == MediaItemType.show && user['UnplayedItemCount'] is int
          ? user['UnplayedItemCount'] as int
          : null,
    );
  }

  static ExternalIds _ids(Object? raw) {
    if (raw is! Map) return ExternalIds.none;
    String? get(String k) {
      for (final e in raw.entries) {
        if ('${e.key}'.toLowerCase() == k && '${e.value}'.isNotEmpty) {
          return '${e.value}';
        }
      }
      return null;
    }

    return ExternalIds(imdb: get('imdb'), tmdb: get('tmdb'), tvdb: get('tvdb'));
  }

  /// Ticks are 100 ns. Zero means "none" for a position.
  static Duration? _ticks(Object? t) {
    if (t is! num || t <= 0) return null;
    return Duration(microseconds: t ~/ 10);
  }

  static int _toTicks(Duration d) => d.inMicroseconds * 10;

  @override
  Future<List<MediaItem>> searchIn(
    List<MediaSection> sections,
    String query, {
    int perSection = 20,
  }) async {
    final needle = query.trim();
    if (needle.isEmpty || sections.isEmpty) return const [];
    final per = await Future.wait(
      sections.map((s) async {
        try {
          return _items(
            await _get('/Users/$_user/Items', {
              'ParentId': s.id,
              'SearchTerm': needle,
              'IncludeItemTypes': _typesOf(s),
              'Recursive': 'true',
              'Fields': _fields,
              'Limit': '$perSection',
            }),
          );
        } catch (_) {
          return const <MediaItem>[];
        }
      }),
    );
    return per.expand((e) => e).toList();
  }

  @override
  Future<MediaItem?> item(String id) async {
    try {
      final data = await _get('/Users/$_user/Items/$id', {'Fields': _fields});
      return data is Map<String, dynamic> ? itemOf(data) : null;
    } on MediaServerUnreachable {
      return null;
    }
  }

  /// Seasons of a show, or episodes of a season, in order.
  @override
  Future<List<MediaItem>> children(String id) async => _items(
    await _get('/Users/$_user/Items', {
      'ParentId': id,
      'Fields': _fields,
      'SortBy': 'ParentIndexNumber,IndexNumber,SortName',
      'SortOrder': 'Ascending',
    }),
  );

  @override
  Future<List<MediaItem>> episodesOf(String showId) async => _items(
    await _get('/Shows/$showId/Episodes', {
      'UserId': _user,
      'Fields': _fields,
    }),
  );

  /// Resume and Next Up, per library, so a library hidden in Settings stays
  /// hidden here as it does on Plex.
  @override
  Future<List<MediaItem>> onDeck(List<MediaSection> sections) async {
    final per = await Future.wait([
      for (final s in sections) ...[
        _get('/Users/$_user/Items/Resume', {
          'ParentId': s.id,
          'Limit': '12',
          'MediaTypes': 'Video',
          'Fields': _fields,
        }).then(_items).catchError((_) => const <MediaItem>[]),
        if (s.type == MediaSectionType.shows)
          _get('/Shows/NextUp', {
            'UserId': _user,
            'ParentId': s.id,
            'Limit': '12',
            'Fields': _fields,
          }).then(_items).catchError((_) => const <MediaItem>[]),
      ],
    ]);
    final seen = <String>{};
    return [
      for (final m in per.expand((p) => p))
        if (seen.add(m.id)) m,
    ];
  }

  @override
  Future<void> setWatched(String id, {required bool watched}) async {
    await _send(watched ? 'POST' : 'DELETE', '/Users/$_user/PlayedItems/$id');
  }

  /// The session API: started once, then progress, then stopped. A stopped
  /// report for something never started (an offline watch being replayed,
  /// §18.6) sends "started" first, so the server has a session to close.
  @override
  Future<void> reportProgress({
    required String id,
    required String state,
    required Duration position,
    required Duration duration,
  }) async {
    final body = {
      'ItemId': id,
      'PositionTicks': _toTicks(position),
      'PlayMethod': 'DirectPlay',
      'CanSeek': true,
      'IsPaused': state == 'paused',
    };
    if (_started.add(id)) {
      await _send('POST', '/Sessions/Playing', body: body);
    }
    if (state == 'stopped') {
      _started.remove(id);
      await _send('POST', '/Sessions/Playing/Stopped', body: body);
    } else {
      await _send('POST', '/Sessions/Playing/Progress', body: body);
    }
  }

  /// The first media source, which is the file direct play and a download
  /// would use.
  Future<(MediaItem, Map<dynamic, dynamic>)> _withSource(String id) async {
    final data = await _get('/Users/$_user/Items/$id', {
      'Fields': '$_fields,MediaSources',
    });
    if (data is! Map<String, dynamic>) {
      throw MediaServerUnreachable(tr.plex.errors.itemGone);
    }
    final sources = data['MediaSources'];
    final source = sources is List && sources.isNotEmpty && sources.first is Map
        ? sources.first as Map
        : null;
    if (source == null) {
      throw MediaServerUnreachable(tr.plex.errors.noFile);
    }
    return (itemOf(data), source);
  }

  static String _extension(Map<dynamic, dynamic> source) {
    // `Container` can be a list ("mov,mp4,m4a,3gp,3g2,mj2"); the first is
    // the file's own.
    final c = '${source['Container'] ?? ''}'.split(',').first.trim();
    return c.isEmpty ? 'mkv' : c.toLowerCase();
  }

  /// `/Videos/{id}/stream?static=true`: the original file, served with byte
  /// ranges, the same direct play Plex gets (§10). No transcode is asked for.
  @override
  Future<MediaPlayable> directPlay(String id) async {
    final (item, source) = await _withSource(id);
    final url = Uri.parse('${info.apiBase}/Videos/$id/stream').replace(
      queryParameters: {
        'static': 'true',
        'MediaSourceId': '${source['Id'] ?? id}',
        _tokenParam: auth.token,
      },
    );
    return MediaPlayable(
      url: '$url',
      title: item.title,
      duration: item.duration ?? Duration.zero,
      posterPath: item.posterPath,
      resumeFrom: item.viewOffset,
      isEpisode: item.type == MediaItemType.episode,
      item: item,
    );
  }

  /// `/Items/{id}/Download`: the original file, which the server only serves
  /// to a user whose account is allowed downloads. That permission is the
  /// owner's to give, and a refusal reaches the person as §18's "the server
  /// would not let this device download that".
  @override
  Future<MediaDownloadSource> downloadSource(String id) async {
    final (item, source) = await _withSource(id);
    final url = Uri.parse(
      '${info.apiBase}/Items/$id/Download',
    ).replace(queryParameters: {_tokenParam: auth.token});
    final size = source['Size'];
    return MediaDownloadSource(
      url: '$url',
      title: item.title,
      duration: item.duration ?? Duration.zero,
      extension: _extension(source),
      isEpisode: item.type == MediaItemType.episode,
      sizeBytes: size is int ? size : null,
      posterPath: item.posterPath,
    );
  }

  @override
  String? posterUrlForPath(String path, {int width = 320, int height = 480}) {
    if (path.isEmpty) return null;
    return Uri.parse('${info.apiBase}$path').replace(
      queryParameters: {
        'fillWidth': '$width',
        'fillHeight': '$height',
        'quality': '90',
      },
    ).toString();
  }
}
