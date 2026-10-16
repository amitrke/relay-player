import 'package:dio/dio.dart';

import '../../domain/models/media_server.dart';
import '../../i18n/strings.g.dart';
import 'tracker.dart';

/// Simkl (architecture.md §19.2).
///
/// Sign-in is Simkl's PIN flow: a code typed at simkl.com/pin on any device.
/// It needs only the app's client id, no secret, and the token it gives does
/// not expire. A finished watch goes to `/sync/history` with its time, in
/// the same shape as Trakt's.
class SimklTracker implements Tracker {
  SimklTracker({
    required this.clientId,
    Dio? dio,
    this.apiBase = 'https://api.simkl.com',
  }) : _dio = dio ?? Dio(_options);

  final String clientId;
  final String apiBase;
  final Dio _dio;

  static final _options = BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 20),
    validateStatus: (_) => true,
  );

  @override
  TrackerKind get kind => TrackerKind.simkl;

  Map<String, String> _headers([String? token]) => {
    'Content-Type': 'application/json',
    'simkl-api-key': clientId,
    'Authorization': ?(token == null ? null : 'Bearer $token'),
  };

  Future<Response<dynamic>> _call(
    String method,
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    String? token,
  }) async {
    try {
      return await _dio.request<dynamic>(
        '$apiBase$path',
        data: body,
        queryParameters: query,
        options: Options(method: method, headers: _headers(token)),
      );
    } on DioException {
      throw TrackerUnavailable(tr.trackers.errors.unavailable(service: kind.label));
    }
  }

  @override
  Future<SignInStart> startSignIn() async {
    final r = await _call('GET', '/oauth/pin', query: {'client_id': clientId});
    final d = r.data;
    if (r.statusCode != 200 || d is! Map || d['user_code'] == null) {
      throw TrackerUnavailable(tr.trackers.errors.unavailable(service: kind.label));
    }
    final code = '${d['user_code']}';
    return DeviceCodeSignIn(
      userCode: code,
      verificationUrl: '${d['verification_url'] ?? 'https://simkl.com/pin'}',
      deviceCode: code,
      expiresAt: DateTime.now().add(
        Duration(seconds: (d['expires_in'] as num?)?.toInt() ?? 900),
      ),
      interval: Duration(seconds: (d['interval'] as num?)?.toInt() ?? 5),
    );
  }

  @override
  Future<TrackerToken> finishSignIn(SignInStart start, {String? pasted}) async {
    final code = start as DeviceCodeSignIn;
    if (DateTime.now().isAfter(code.expiresAt)) {
      throw SignInFailed(tr.trackers.errors.expired);
    }
    final r = await _call(
      'GET',
      '/oauth/pin/${code.deviceCode}',
      query: {'client_id': clientId},
    );
    final d = r.data;
    if (d is Map && d['result'] == 'OK' && d['access_token'] is String) {
      final token = TrackerToken(access: d['access_token'] as String);
      return token.withUser(await _userName(token.access));
    }
    throw const SignInPending();
  }

  Future<String?> _userName(String token) async {
    try {
      final r = await _call('POST', '/users/settings', token: token);
      final user = r.data is Map ? (r.data as Map)['user'] : null;
      return user is Map ? '${user['name'] ?? ''}' : null;
    } catch (_) {
      return null;
    }
  }

  /// Simkl tokens do not expire, so there is nothing to refresh.
  @override
  Future<TrackerToken> refresh(TrackerToken token) async =>
      throw const TrackerSignedOut();

  @override
  Future<bool> markWatched(WatchedItem item, TrackerToken token) async {
    final body = historyBody(item);
    if (body == null) return false;
    final r = await _call(
      'POST',
      '/sync/history',
      body: body,
      token: token.access,
    );
    final status = r.statusCode ?? 0;
    if (status == 401) throw const TrackerSignedOut();
    if (status == 429 || status >= 500) {
      throw TrackerUnavailable(tr.trackers.errors.unavailable(service: kind.label));
    }
    if (status != 201 && status != 200) return false;
    final added = r.data is Map ? (r.data as Map)['added'] : null;
    if (added is Map) {
      return ((added['movies'] as num?) ?? 0) +
              ((added['episodes'] as num?) ?? 0) +
              ((added['shows'] as num?) ?? 0) >
          0;
    }
    return true;
  }

  static Map<String, Object> _ids(ExternalIds i) => {
    if (i.imdb != null) 'imdb': i.imdb!,
    if (i.tmdb != null) 'tmdb': i.tmdb!,
    if (i.tvdb != null) 'tvdb': i.tvdb!,
  };

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
    if (item.showIds.isEmpty || item.season == null || item.episode == null) {
      return null;
    }
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
}
