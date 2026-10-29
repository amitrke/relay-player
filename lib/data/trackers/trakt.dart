import 'package:dio/dio.dart';

import '../../domain/models/media_server.dart';
import '../../i18n/strings.g.dart';
import 'tracker.dart';

/// Trakt (architecture.md §19.2).
///
/// Sign-in is Trakt's device flow: a code typed at trakt.tv/activate on any
/// device, so a TV types nothing. A finished watch goes to `/sync/history`
/// with the time it happened, rather than the real-time `/scrobble` calls: it
/// is the one call that is right both live and when an offline watch is
/// delivered days later (§18.6), and "watching now" was not asked for.
///
/// Matching is by IMDb, TMDB or TVDB id. An episode is sent as its show's ids
/// plus season and number, which every Trakt client understands and which a
/// server knows more often than the episode's own ids.
class TraktTracker implements Tracker {
  TraktTracker({
    required this.clientId,
    required this.clientSecret,
    Dio? dio,
    this.apiBase = 'https://api.trakt.tv',
  }) : _dio = dio ?? Dio(_options);

  final String clientId;
  final String clientSecret;
  final String apiBase;
  final Dio _dio;

  static final _options = BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 20),
    validateStatus: (_) => true,
  );

  @override
  TrackerKind get kind => TrackerKind.trakt;

  Map<String, String> _headers([String? token]) => {
    'Content-Type': 'application/json',
    'trakt-api-version': '2',
    'trakt-api-key': clientId,
    'Authorization': ?(token == null ? null : 'Bearer $token'),
  };

  @override
  Future<SignInStart> startSignIn() async {
    final r = await _post('/oauth/device/code', {'client_id': clientId});
    final d = r.data;
    if (r.statusCode != 200 || d is! Map) {
      throw TrackerUnavailable(tr.trackers.errors.unavailable(service: kind.label));
    }
    return DeviceCodeSignIn(
      userCode: '${d['user_code']}',
      verificationUrl: '${d['verification_url']}',
      deviceCode: '${d['device_code']}',
      expiresAt: DateTime.now().add(
        Duration(seconds: (d['expires_in'] as num?)?.toInt() ?? 600),
      ),
      interval: Duration(seconds: (d['interval'] as num?)?.toInt() ?? 5),
    );
  }

  @override
  Future<TrackerToken> finishSignIn(SignInStart start, {String? pasted}) async {
    final code = start as DeviceCodeSignIn;
    final r = await _post('/oauth/device/token', {
      'code': code.deviceCode,
      'client_id': clientId,
      'client_secret': clientSecret,
    });
    switch (r.statusCode) {
      case 200:
        final token = _token(r.data);
        return token.withUser(await _userName(token.access));
      // 400: not approved yet; 429: polling too fast, which is still pending.
      case 400 || 429:
        throw const SignInPending();
      case 418:
        throw SignInFailed(tr.trackers.errors.denied);
      default:
        // 404 invalid, 409 already used, 410 expired: a new code is needed.
        throw SignInFailed(tr.trackers.errors.expired);
    }
  }

  TrackerToken _token(Object? d) {
    if (d is! Map || d['access_token'] is! String) {
      throw TrackerUnavailable(tr.trackers.errors.unavailable(service: kind.label));
    }
    final created = (d['created_at'] as num?)?.toInt();
    final expires = (d['expires_in'] as num?)?.toInt();
    return TrackerToken(
      access: d['access_token'] as String,
      refresh: d['refresh_token'] as String?,
      expiresAt: created != null && expires != null
          ? DateTime.fromMillisecondsSinceEpoch((created + expires) * 1000)
          : null,
    );
  }

  Future<String?> _userName(String token) async {
    try {
      final r = await _dio.get<dynamic>(
        '$apiBase/users/settings',
        options: Options(headers: _headers(token)),
      );
      final user = r.data is Map ? (r.data as Map)['user'] : null;
      return user is Map ? '${user['username'] ?? ''}' : null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<TrackerToken> refresh(TrackerToken token) async {
    final refresh = token.refresh;
    if (refresh == null) throw const TrackerSignedOut();
    final r = await _post('/oauth/token', {
      'refresh_token': refresh,
      'client_id': clientId,
      'client_secret': clientSecret,
      'redirect_uri': 'urn:ietf:wg:oauth:2.0:oob',
      'grant_type': 'refresh_token',
    });
    if (r.statusCode != 200) throw const TrackerSignedOut();
    return _token(r.data).withUser(token.userName);
  }

  @override
  Future<bool> markWatched(WatchedItem item, TrackerToken token) async {
    final body = historyBody(item);
    if (body == null) return false;
    final r = await _post('/sync/history', body, token: token.access);
    final status = r.statusCode ?? 0;
    if (status == 401) throw const TrackerSignedOut();
    if (status == 429 || status >= 500) {
      throw TrackerUnavailable(tr.trackers.errors.unavailable(service: kind.label));
    }
    if (status != 201 && status != 200) return false;
    // Trakt answers 201 with a `not_found` list for ids it does not know.
    final added = r.data is Map ? (r.data as Map)['added'] : null;
    if (added is Map) {
      return ((added['movies'] as num?) ?? 0) +
              ((added['episodes'] as num?) ?? 0) >
          0;
    }
    return true;
  }

  static Map<String, Object> _ids(ExternalIds i) => {
    if (i.imdb != null) 'imdb': i.imdb!,
    if (i.tmdb != null) 'tmdb': int.tryParse(i.tmdb!) ?? i.tmdb!,
    if (i.tvdb != null) 'tvdb': int.tryParse(i.tvdb!) ?? i.tvdb!,
  };

  /// The `/sync/history` body for [item], or null when there is nothing to
  /// match it by.
  static Map<String, Object>? historyBody(WatchedItem item) {
    final at = item.watchedAt.toUtc().toIso8601String();
    if (!item.isEpisode) {
      if (item.ids.isEmpty) return null;
      return {
        'movies': [
          {
            'title': item.title,
            'year': ?item.year,
            'ids': _ids(item.ids),
            'watched_at': at,
          },
        ],
      };
    }
    if (!item.showIds.isEmpty && item.season != null && item.episode != null) {
      return {
        'shows': [
          {
            'title': ?item.showTitle,
            'year': ?item.showYear,
            'ids': _ids(item.showIds),
            'seasons': [
              {
                'number': item.season,
                'episodes': [
                  {'number': item.episode, 'watched_at': at},
                ],
              },
            ],
          },
        ],
      };
    }
    if (item.ids.isEmpty) return null;
    return {
      'episodes': [
        {'ids': _ids(item.ids), 'watched_at': at},
      ],
    };
  }

  Future<Response<dynamic>> _post(
    String path,
    Object body, {
    String? token,
  }) async {
    try {
      return await _dio.post<dynamic>(
        '$apiBase$path',
        data: body,
        options: Options(headers: _headers(token)),
      );
    } on DioException {
      throw TrackerUnavailable(tr.trackers.errors.unavailable(service: kind.label));
    }
  }
}
