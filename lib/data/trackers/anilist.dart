import 'package:dio/dio.dart';

import '../../i18n/strings.g.dart';
import 'anime_match.dart';
import 'tracker.dart';

/// AniList (architecture.md §19.3).
///
/// Sign-in is AniList's implicit grant with its own "PIN" page: the app opens
/// `anilist.co/api/v2/oauth/authorize`, and after approval AniList shows the
/// token on a page of its own for the person to copy. The app's registered
/// redirect must be `https://anilist.co/api/v2/oauth/pin` for that page to
/// appear (RELEASING.md). Pasting a token is a phone or computer job; a TV
/// gets it with Move to another device (§17).
///
/// The token lasts a year and cannot be refreshed; when it lapses the person
/// signs in again.
class AniListTracker implements Tracker {
  AniListTracker({
    required this.clientId,
    Dio? dio,
    this.apiBase = 'https://graphql.anilist.co',
    this.authBase = 'https://anilist.co/api/v2/oauth',
  }) : _dio = dio ?? Dio(_options);

  final String clientId;
  final String apiBase;
  final String authBase;
  final Dio _dio;

  static final _options = BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 20),
    validateStatus: (_) => true,
  );

  @override
  TrackerKind get kind => TrackerKind.anilist;

  Future<Map<dynamic, dynamic>> _query(
    String query,
    Map<String, Object?> variables,
    String token,
  ) async {
    final Response<dynamic> r;
    try {
      r = await _dio.post<dynamic>(
        apiBase,
        data: {'query': query, 'variables': variables},
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );
    } on DioException {
      throw TrackerUnavailable(tr.trackers.errors.unavailable(service: kind.label));
    }
    final status = r.statusCode ?? 0;
    if (status == 401) throw const TrackerSignedOut();
    if (status == 429 || status >= 500) {
      throw TrackerUnavailable(tr.trackers.errors.unavailable(service: kind.label));
    }
    final data = r.data is Map ? (r.data as Map)['data'] : null;
    if (data is! Map) {
      // GraphQL reports an invalid token as an error with status 400.
      final errors = r.data is Map ? (r.data as Map)['errors'] : null;
      if (errors is List &&
          errors.any((e) => e is Map && e['status'] == 401)) {
        throw const TrackerSignedOut();
      }
      return const {};
    }
    return data;
  }

  @override
  Future<SignInStart> startSignIn() async => BrowserSignIn(
    url: Uri.parse('$authBase/authorize').replace(
      queryParameters: {'client_id': clientId, 'response_type': 'token'},
    ).toString(),
  );

  @override
  Future<TrackerToken> finishSignIn(SignInStart start, {String? pasted}) async {
    final token = _tokenFrom(pasted ?? '');
    if (token == null) throw SignInFailed(tr.trackers.errors.badPaste);
    try {
      final data = await _query('query { Viewer { name } }', {}, token);
      final viewer = data['Viewer'];
      if (viewer is! Map) throw SignInFailed(tr.trackers.errors.badPaste);
      return TrackerToken(access: token, userName: '${viewer['name'] ?? ''}');
    } on TrackerSignedOut {
      throw SignInFailed(tr.trackers.errors.badPaste);
    }
  }

  /// The token from whatever was pasted: the bare token, or the address
  /// with `#access_token=...` in it.
  static String? _tokenFrom(String pasted) {
    final p = pasted.trim();
    final m = RegExp(r'access_token=([^&\s]+)').firstMatch(p);
    if (m != null) return Uri.decodeComponent(m.group(1)!);
    // A JWT: three dot-separated base64url parts, long.
    return RegExp(r'^[A-Za-z0-9_\-]+\.[A-Za-z0-9_\-]+\.[A-Za-z0-9_\-]+$')
                .hasMatch(p) &&
            p.length > 40
        ? p
        : null;
  }

  @override
  Future<TrackerToken> refresh(TrackerToken token) async =>
      throw const TrackerSignedOut();

  static const _search = r'''
query ($search: String, $format: MediaFormat) {
  Page(perPage: 5) {
    media(search: $search, type: ANIME, format: $format) {
      id
      episodes
      title { romaji english native }
      synonyms
      mediaListEntry { progress status }
    }
  }
}''';

  static const _save = r'''
mutation ($mediaId: Int, $progress: Int, $status: MediaListStatus) {
  SaveMediaListEntry(mediaId: $mediaId, progress: $progress, status: $status) {
    id
  }
}''';

  @override
  Future<bool> markWatched(WatchedItem item, TrackerToken token) async {
    final target = animeTarget(item);
    if (target == null) return false;
    final data = await _query(_search, {
      'search': target.query,
      'format': ?(target.movie ? 'MOVIE' : null),
    }, token.access);
    final page = data['Page'];
    final media = page is Map ? page['media'] : null;
    if (media is! List) return false;
    final match = bestAnimeMatch<Map<dynamic, dynamic>>(
      target.query,
      [for (final m in media) if (m is Map) m],
      (m) {
        final t = m['title'] is Map ? m['title'] as Map : const {};
        return [
          for (final v in [...t.values, ...?(m['synonyms'] as List?)])
            if (v is String) v,
        ];
      },
    );
    if (match == null) return false;

    final entry = match['mediaListEntry'];
    final had = entry is Map ? (entry['progress'] as num?)?.toInt() ?? 0 : 0;
    // Never lower progress: a rewatch of an early episode must not undo a
    // list someone has kept by hand.
    if (had >= target.progress) return true;
    final total = (match['episodes'] as num?)?.toInt();
    final done = total != null && target.progress >= total;
    await _query(_save, {
      'mediaId': match['id'],
      'progress': target.progress,
      'status': done ? 'COMPLETED' : 'CURRENT',
    }, token.access);
    return true;
  }
}
