import 'dart:convert';

import 'package:dio/dio.dart';

import '../../i18n/strings.g.dart';

/// How a Seerr server is signed in to.
enum SeerrAuth { apiKey, plex, password }

/// What the server says about itself before sign-in (`/settings/public`).
class SeerrServerInfo {
  const SeerrServerInfo({
    required this.baseUrl,
    required this.title,
    required this.mediaServer,
    required this.localLogin,
  });

  /// With no trailing slash; the API is under `/api/v1`.
  final String baseUrl;

  /// The name its owner gave it ("Overseerr", "Jellyseerr", or their own).
  final String title;

  /// 1 Plex, 2 Jellyfin, 3 Emby: which sign-in the server's users have.
  final int mediaServer;

  /// Whether email-and-password accounts are switched on.
  final bool localLogin;

  bool get usesPlex => mediaServer == 1;
}

/// A signed-in session. Secret (§3): secure storage only.
class SeerrSession {
  const SeerrSession({
    required this.auth,
    this.apiKey,
    this.cookie,
    this.userName,
  });

  final SeerrAuth auth;

  /// For [SeerrAuth.apiKey]: an admin-level key from the server's settings.
  final String? apiKey;

  /// For the other two: the `connect.sid` session cookie.
  final String? cookie;
  final String? userName;

  Map<String, String> get headers => {
    'X-Api-Key': ?apiKey,
    'Cookie': ?cookie,
  };

  Map<String, Object?> toJson() => {
    'auth': auth.name,
    'apiKey': ?apiKey,
    'cookie': ?cookie,
    'user': ?userName,
  };

  static SeerrSession? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final auth = SeerrAuth.values
        .where((a) => a.name == raw['auth'])
        .firstOrNull;
    if (auth == null) return null;
    return SeerrSession(
      auth: auth,
      apiKey: raw['apiKey'] as String?,
      cookie: raw['cookie'] as String?,
      userName: raw['user'] as String?,
    );
  }
}

/// Where a title stands on the server. Seerr's own media status numbers.
enum SeerrAvailability {
  unknown,
  pending,
  processing,
  partial,
  available;

  static SeerrAvailability of(Object? status) => switch (status) {
    2 => pending,
    3 => processing,
    4 => partial,
    5 => available,
    _ => unknown,
  };

  /// Requestable: nothing on the server yet, or only some of a show.
  bool get canRequest => this == unknown || this == partial;
}

/// One search result: a title on TMDB, and whether the server has it.
class SeerrTitle {
  const SeerrTitle({
    required this.tmdbId,
    required this.isShow,
    required this.title,
    required this.availability,
    this.year,
    this.posterPath,
  });

  final int tmdbId;
  final bool isShow;
  final String title;
  final int? year;

  /// TMDB's image path ("/abc.jpg"). Images come from TMDB's public image
  /// host and carry no credential.
  final String? posterPath;
  final SeerrAvailability availability;

  String? posterUrl({int width = 300}) =>
      posterPath == null ? null : 'https://image.tmdb.org/t/p/w$width$posterPath';
}

/// One of the person's requests, for the list in Settings.
class SeerrRequest {
  const SeerrRequest({
    required this.title,
    required this.status,
    required this.availability,
    this.requestedAt,
  });

  final String title;

  /// 1 waiting for approval, 2 approved, 3 declined.
  final int status;
  final SeerrAvailability availability;
  final DateTime? requestedAt;
}

/// The server's answer, or a message fit to show.
class SeerrException implements Exception {
  const SeerrException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Overseerr, Jellyseerr and Seerr (architecture.md §20): the request server
/// that sits beside a person's own Plex, Jellyfin or Emby server.
///
/// It is theirs, on their network or behind their own domain, so requests
/// go from this device to it and nowhere else. The app asks it to find
/// titles and to request one; the server's owner decides what happens next,
/// exactly as with a request from Seerr's own web page.
class SeerrClient {
  SeerrClient(this.info, this.session, {Dio? dio}) : _dio = dio ?? _http();

  final SeerrServerInfo info;
  final SeerrSession session;
  final Dio _dio;

  static Dio _http() => Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
      validateStatus: (_) => true,
    ),
  );

  static String normalise(String address) {
    var a = address.trim();
    if (!a.contains('://')) a = 'http://$a';
    while (a.endsWith('/')) {
      a = a.substring(0, a.length - 1);
    }
    return a;
  }

  /// Finds a Seerr server at [address] and reads its public settings.
  static Future<SeerrServerInfo> probe(String address, {Dio? dio}) async {
    final base = normalise(address);
    try {
      final r = await (dio ?? _http()).get<dynamic>(
        '$base/api/v1/settings/public',
      );
      final d = r.data;
      if (r.statusCode == 200 && d is Map && d.containsKey('mediaServerType')) {
        return SeerrServerInfo(
          baseUrl: base,
          title: '${d['applicationTitle'] ?? 'Seerr'}',
          mediaServer: (d['mediaServerType'] as num?)?.toInt() ?? 1,
          localLogin: d['localLogin'] == true,
        );
      }
    } on DioException {
      // Falls through to the message below.
    }
    throw SeerrException(tr.seerr.errors.notASeerr);
  }

  /// Signs in and returns the session to keep.
  ///
  /// [plexToken] signs in as the person's Plex account, which a Plex-backed
  /// server knows; [username] and [password] are a Jellyfin or Emby user on
  /// such a server, or a local account; [apiKey] is the server's own key.
  static Future<SeerrSession> signIn(
    SeerrServerInfo info, {
    String? apiKey,
    String? plexToken,
    String? username,
    String? password,
    Dio? dio,
  }) async {
    final http = dio ?? _http();
    final base = '${info.baseUrl}/api/v1';
    if (apiKey != null) {
      final r = await _try(
        () => http.get<dynamic>(
          '$base/auth/me',
          options: Options(headers: {'X-Api-Key': apiKey}),
        ),
      );
      if (r.statusCode != 200) {
        throw SeerrException(tr.seerr.errors.badKey);
      }
      return SeerrSession(
        auth: SeerrAuth.apiKey,
        apiKey: apiKey,
        userName: _name(r.data),
      );
    }
    final (path, body) = plexToken != null
        ? ('/auth/plex', {'authToken': plexToken})
        : info.usesPlex
        ? ('/auth/local', {'email': username, 'password': password})
        : ('/auth/jellyfin', {'username': username, 'password': password});
    final r = await _try(() => http.post<dynamic>('$base$path', data: body));
    final cookie = _cookie(r.headers);
    if (r.statusCode != 200 || cookie == null) {
      throw SeerrException(
        r.statusCode == 401 || r.statusCode == 403
            ? tr.seerr.errors.refused
            : tr.seerr.errors.status(code: r.statusCode ?? 0),
      );
    }
    return SeerrSession(
      auth: plexToken != null ? SeerrAuth.plex : SeerrAuth.password,
      cookie: cookie,
      userName: _name(r.data),
    );
  }

  static Future<Response<dynamic>> _try(
    Future<Response<dynamic>> Function() call,
  ) async {
    try {
      return await call();
    } on DioException {
      throw SeerrException(tr.seerr.errors.unreachable);
    }
  }

  /// `connect.sid=...` from Set-Cookie, without its attributes.
  static String? _cookie(Headers headers) {
    for (final c in headers['set-cookie'] ?? const <String>[]) {
      final first = c.split(';').first.trim();
      if (first.startsWith('connect.sid=')) return first;
    }
    return null;
  }

  static String? _name(Object? d) => d is Map
      ? '${d['displayName'] ?? d['username'] ?? d['plexUsername'] ?? d['email'] ?? ''}'
      : null;

  Future<dynamic> _get(String path, [Map<String, dynamic>? query]) async {
    final r = await _try(
      () => _dio.get<dynamic>(
        '${info.baseUrl}/api/v1$path',
        queryParameters: query,
        options: Options(headers: session.headers),
      ),
    );
    _check(r);
    return r.data;
  }

  void _check(Response<dynamic> r) {
    final s = r.statusCode ?? 0;
    if (s == 401 || s == 403) throw SeerrException(tr.seerr.errors.signedOut);
    if (s < 200 || s >= 300) {
      throw SeerrException(tr.seerr.errors.status(code: s));
    }
  }

  /// Films and shows matching [query], whatever the server has.
  Future<List<SeerrTitle>> search(String query) async {
    final q = query.trim();
    if (q.isEmpty) return const [];
    // Percent-encoded by hand, spaces as %20: Seerr's request validator
    // refuses the `+` a form-style query encoder would put there.
    final data = await _get('/search?query=${Uri.encodeComponent(q)}&page=1');
    final results = data is Map ? data['results'] : null;
    if (results is! List) return const [];
    return [
      for (final r in results)
        if (r is Map && (r['mediaType'] == 'movie' || r['mediaType'] == 'tv'))
          titleOf(r),
    ];
  }

  static SeerrTitle titleOf(Map<dynamic, dynamic> r) {
    final show = r['mediaType'] == 'tv';
    final date = '${r[show ? 'firstAirDate' : 'releaseDate'] ?? ''}';
    final info = r['mediaInfo'];
    return SeerrTitle(
      tmdbId: (r['id'] as num).toInt(),
      isShow: show,
      title: '${r[show ? 'name' : 'title'] ?? ''}',
      year: date.length >= 4 ? int.tryParse(date.substring(0, 4)) : null,
      posterPath: r['posterPath'] as String?,
      availability: SeerrAvailability.of(info is Map ? info['status'] : null),
    );
  }

  /// Asks the server for [title]. A show is asked for in full, every season
  /// but specials: picking seasons is what Seerr's own page is for.
  Future<void> request(SeerrTitle title) async {
    final body = <String, Object>{
      'mediaType': title.isShow ? 'tv' : 'movie',
      'mediaId': title.tmdbId,
    };
    if (title.isShow) {
      final show = await _get('/tv/${title.tmdbId}');
      final seasons = show is Map ? show['seasons'] : null;
      body['seasons'] = [
        if (seasons is List)
          for (final s in seasons)
            if (s is Map && (s['seasonNumber'] as num? ?? 0) > 0)
              (s['seasonNumber'] as num).toInt(),
      ];
    }
    final r = await _try(
      () => _dio.post<dynamic>(
        '${info.baseUrl}/api/v1/request',
        data: jsonEncode(body),
        options: Options(
          headers: {...session.headers, 'Content-Type': 'application/json'},
        ),
      ),
    );
    if (r.statusCode == 409) {
      throw SeerrException(tr.seerr.errors.alreadyRequested);
    }
    _check(r);
  }

  /// The signed-in user's latest requests.
  Future<List<SeerrRequest>> myRequests({int take = 20}) async {
    final me = await _get('/auth/me');
    final id = me is Map ? me['id'] : null;
    final data = await _get('/request', {
      'take': '$take',
      'skip': '0',
      'sort': 'added',
      'requestedBy': ?id?.toString(),
    });
    final results = data is Map ? data['results'] : null;
    if (results is! List) return const [];
    final out = <SeerrRequest>[];
    for (final r in results) {
      if (r is! Map) continue;
      final media = r['media'] is Map ? r['media'] as Map : const {};
      out.add(
        SeerrRequest(
          // A request carries TMDB ids, not titles; the title is looked up.
          title: await _titleOf(media),
          status: (r['status'] as num?)?.toInt() ?? 1,
          availability: SeerrAvailability.of(media['status']),
          requestedAt: DateTime.tryParse('${r['createdAt'] ?? ''}'),
        ),
      );
    }
    return out;
  }

  Future<String> _titleOf(Map<dynamic, dynamic> media) async {
    final id = media['tmdbId'];
    final type = media['mediaType'];
    if (id == null || (type != 'movie' && type != 'tv')) return '';
    try {
      final d = await _get('/$type/$id');
      if (d is Map) return '${d[type == 'tv' ? 'name' : 'title'] ?? ''}';
    } catch (_) {}
    return '';
  }
}
