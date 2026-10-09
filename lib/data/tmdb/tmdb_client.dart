import 'package:dio/dio.dart';

import 'title_match.dart';

/// What TMDB knows about one title, reduced to what the app filters on.
class TmdbInfo {
  const TmdbInfo({
    required this.id,
    required this.isTv,
    this.genres = const [],
    this.originalLanguage,
    this.rating,
    this.runtime,
    this.overview,
  });

  final int id;
  final bool isTv;
  final List<String> genres;

  /// ISO 639-1 code of the *original* language, which is not the audio language
  /// of a dubbed copy. Shown as "Original language" for that reason.
  final String? originalLanguage;

  /// Average vote out of 10. TMDB's own, not IMDb's.
  final double? rating;
  final int? runtime;
  final String? overview;

  Map<String, dynamic> toJson() => {
    'id': id,
    'tv': isTv,
    'genres': genres,
    'lang': originalLanguage,
    'rating': rating,
    'runtime': runtime,
    'overview': overview,
  };

  static TmdbInfo? fromJson(Object? json) {
    if (json is! Map) return null;
    final id = json['id'];
    if (id is! int) return null;
    return TmdbInfo(
      id: id,
      isTv: json['tv'] == true,
      genres: [
        for (final g in (json['genres'] as List? ?? const []))
          if (g is String) g,
      ],
      originalLanguage: json['lang'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      runtime: json['runtime'] as int?,
      overview: json['overview'] as String?,
    );
  }
}

class TmdbException implements Exception {
  const TmdbException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// What the app asks of TMDB, so the matching can be tested without a network.
abstract class TmdbApi {
  Future<List<TmdbCandidate>> search(
    String title, {
    required bool tv,
    int? year,
  });
  Future<TmdbInfo> details(int id, {required bool tv});
  Future<List<TmdbCandidate>> recommendations(int id, {required bool tv});
}

/// A minimal TMDB v3 client.
///
/// The key is the user's own, entered in Settings (§2: no backend, so no key of
/// ours to ship, and one embedded in the app could be lifted out of it). Both
/// credential shapes TMDB issues are accepted: the long "API Read Access Token"
/// goes in a bearer header, the short v3 key in the query string.
class TmdbClient implements TmdbApi {
  TmdbClient({required String key, Dio? dio})
    : _key = key.trim(),
      _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: 'https://api.themoviedb.org/3',
              connectTimeout: const Duration(seconds: 8),
              receiveTimeout: const Duration(seconds: 8),
            ),
          );

  final String _key;
  final Dio _dio;

  /// A bearer token is a JWT; a v3 key is 32 hex characters.
  bool get _isBearer => _key.startsWith('eyJ');

  Future<Map<String, dynamic>> _get(
    String path, [
    Map<String, dynamic> query = const {},
  ]) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        path,
        queryParameters: {...query, if (!_isBearer) 'api_key': _key},
        options: Options(
          headers: {if (_isBearer) 'Authorization': 'Bearer $_key'},
        ),
      );
      return response.data ?? const {};
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 401) {
        throw const TmdbException('TMDB rejected that key.');
      }
      if (status == 429) {
        throw const TmdbException('TMDB is rate limiting this device.');
      }
      throw TmdbException('Could not reach TMDB (${e.type.name}).');
    }
  }

  /// Whether the key works.
  Future<void> verify() async {
    final body = await _get('/authentication');
    if (body['success'] != true) {
      throw const TmdbException('TMDB rejected that key.');
    }
  }

  static int? _year(Object? date) {
    if (date is! String || date.length < 4) return null;
    return int.tryParse(date.substring(0, 4));
  }

  List<TmdbCandidate> _candidates(Map<String, dynamic> body, bool tv) => [
    for (final r in (body['results'] as List? ?? const []))
      if (r is Map && r['id'] is int)
        TmdbCandidate(
          id: r['id'] as int,
          title: (tv ? r['name'] : r['title']) as String? ?? '',
          originalTitle:
              (tv ? r['original_name'] : r['original_title']) as String? ?? '',
          year: _year(tv ? r['first_air_date'] : r['release_date']),
        ),
  ];

  @override
  Future<List<TmdbCandidate>> search(
    String title, {
    required bool tv,
    int? year,
  }) async {
    final body = await _get(tv ? '/search/tv' : '/search/movie', {
      'query': title,
      (tv ? 'first_air_date_year' : 'year'): ?year,
    });
    return _candidates(body, tv);
  }

  @override
  Future<TmdbInfo> details(int id, {required bool tv}) async {
    final body = await _get(tv ? '/tv/$id' : '/movie/$id');
    final runtime = tv
        ? ((body['episode_run_time'] as List?)?.firstOrNull as int?)
        : body['runtime'] as int?;
    return TmdbInfo(
      id: id,
      isTv: tv,
      genres: [
        for (final g in (body['genres'] as List? ?? const []))
          if (g is Map && g['name'] is String) g['name'] as String,
      ],
      originalLanguage: body['original_language'] as String?,
      rating: (body['vote_average'] as num?)?.toDouble(),
      runtime: runtime == 0 ? null : runtime,
      overview: body['overview'] as String?,
    );
  }

  /// Titles TMDB considers close to this one, best first. Used for
  /// "because you watched", and only ever to *look up* things already in the
  /// user's sources, never to suggest something they do not have (§9.2).
  @override
  Future<List<TmdbCandidate>> recommendations(
    int id, {
    required bool tv,
  }) async {
    final body = await _get(
      tv ? '/tv/$id/recommendations' : '/movie/$id/recommendations',
    );
    return _candidates(body, tv);
  }
}

/// A language's display name from TMDB's ISO 639-1 code.
String languageNameOfIso(String code) =>
    _isoNames[code.toLowerCase()] ?? code.toUpperCase();

const _isoNames = <String, String>{
  'en': 'English',
  'fr': 'French',
  'de': 'German',
  'es': 'Spanish',
  'it': 'Italian',
  'pt': 'Portuguese',
  'nl': 'Dutch',
  'pl': 'Polish',
  'ru': 'Russian',
  'tr': 'Turkish',
  'ar': 'Arabic',
  'he': 'Hebrew',
  'fa': 'Persian',
  'hi': 'Hindi',
  'ta': 'Tamil',
  'te': 'Telugu',
  'ml': 'Malayalam',
  'kn': 'Kannada',
  'bn': 'Bengali',
  'pa': 'Punjabi',
  'ur': 'Urdu',
  'mr': 'Marathi',
  'ja': 'Japanese',
  'ko': 'Korean',
  'zh': 'Chinese',
  'cn': 'Cantonese',
  'th': 'Thai',
  'id': 'Indonesian',
  'vi': 'Vietnamese',
  'sv': 'Swedish',
  'da': 'Danish',
  'no': 'Norwegian',
  'nb': 'Norwegian',
  'fi': 'Finnish',
  'el': 'Greek',
  'cs': 'Czech',
  'hu': 'Hungarian',
  'ro': 'Romanian',
  'uk': 'Ukrainian',
};
