import 'package:dio/dio.dart';

/// What the panel says about the line itself.
class XtreamAccountInfo {
  const XtreamAccountInfo({
    required this.status,
    required this.isTrial,
    required this.maxConnections,
    required this.activeConnections,
    required this.expiresAt,
    required this.outputFormats,
  });

  final String status;
  final bool isTrial;

  /// §4: concurrent streams allowed, total. Phase 0 measured a real line at 1,
  /// which is the common case and constrains the player lifecycle.
  final int maxConnections;

  /// Worth surfacing: a crash can leave a connection held server-side until it
  /// times out, and the next launch then fails with no visible cause.
  final int activeConnections;

  final DateTime? expiresAt;
  final List<String> outputFormats;

  bool get isActive => status.toLowerCase() == 'active';

  String get preferredFormat =>
      outputFormats.contains('ts') ? 'ts' : (outputFormats.firstOrNull ?? 'ts');
}

class XtreamCategory {
  const XtreamCategory({required this.id, required this.name});

  final String id;
  final String name;
}

class XtreamChannel {
  const XtreamChannel({
    required this.streamId,
    required this.name,
    required this.categoryId,
    this.logoUrl,
    this.epgChannelId,
  });

  final String streamId;
  final String name;
  final String categoryId;
  final String? logoUrl;

  /// Phase 0 found 91% of channels on a real panel had none, so the guide can
  /// never be linked for most of them. Nullable on purpose.
  final String? epgChannelId;
}

class XtreamException implements Exception {
  const XtreamException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Client for an Xtream Codes panel (§4).
///
/// Only reachable through the Advanced Sources gate (§8). Two Phase 0 findings
/// shape it:
///
/// - **Never call the unfiltered stream endpoints.** `get_vod_streams` measured
///   26.2 MB / 69,397 items on a real panel. §4.1's design is to fetch
///   categories, let the user pick, then fetch per category — so the bulk is
///   never transferred at all. This class deliberately exposes no "fetch
///   everything" method.
/// - **Panels are flaky.** §4 asks for timeouts and retry-once-on-5xx.
class XtreamClient {
  XtreamClient({
    required this.host,
    required this.username,
    required this.password,
    Dio? dio,
  }) : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 30),
              // Panels answer 200-with-junk more often than a clean status, so
              // parsing decides success rather than the status code alone.
              validateStatus: (code) => code != null && code < 500,
            ));

  /// Scheme and authority, no trailing slash — e.g. `http://panel.example:8080`.
  final String host;
  final String username;
  final String password;

  final Dio _dio;

  String get _api => '$host/player_api.php';

  Map<String, String> get _auth => {
        'username': username,
        'password': password,
      };

  /// One retry on a 5xx or timeout, then give up (§4).
  Future<Response<dynamic>> _get(Map<String, String> query) async {
    DioException? first;
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final response = await _dio.get<dynamic>(_api, queryParameters: query);
        if (response.statusCode != null && response.statusCode! >= 500) {
          if (attempt == 0) continue;
          throw XtreamException(
            'The panel returned ${response.statusCode}. Try again later.',
          );
        }
        return response;
      } on DioException catch (e) {
        first ??= e;
        if (attempt == 1) {
          throw XtreamException(_describe(first));
        }
      }
    }
    throw XtreamException(_describe(first!));
  }

  static String _describe(DioException e) => switch (e.type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.receiveTimeout =>
          'The panel did not respond in time.',
        DioExceptionType.connectionError =>
          'Could not reach that address. Check the host and port.',
        _ => 'Could not talk to the panel (${e.type.name}).',
      };

  /// Authenticates and returns the line's own description of itself.
  Future<XtreamAccountInfo> authenticate() async {
    final response = await _get(_auth);
    final data = response.data;
    if (data is! Map) {
      throw const XtreamException(
        'That address did not answer like an Xtream panel.',
      );
    }

    final user = data['user_info'];
    if (user is! Map) {
      throw const XtreamException('The panel rejected those credentials.');
    }
    if (_asInt(user['auth']) == 0) {
      throw const XtreamException('Wrong username or password.');
    }

    final expiry = _asInt(user['exp_date']);
    return XtreamAccountInfo(
      status: '${user['status'] ?? ''}',
      isTrial: _asInt(user['is_trial']) == 1,
      maxConnections: _asInt(user['max_connections']) ?? 1,
      activeConnections: _asInt(user['active_cons']) ?? 0,
      expiresAt: expiry == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(expiry * 1000),
      outputFormats: [
        for (final f in (user['allowed_output_formats'] as List? ?? const []))
          '$f',
      ],
    );
  }

  Future<List<XtreamCategory>> liveCategories() async {
    final response = await _get({..._auth, 'action': 'get_live_categories'});
    final data = response.data;
    if (data is! List) return const [];
    return [
      for (final entry in data)
        if (entry is Map)
          XtreamCategory(
            id: '${entry['category_id']}',
            name: '${entry['category_name'] ?? 'Unnamed'}',
          ),
    ];
  }

  /// Channels in one category.
  ///
  /// [categoryId] is required rather than optional — §4.1's whole design is that
  /// the unfiltered call is never made, and an optional parameter is an
  /// invitation to forget.
  Future<List<XtreamChannel>> liveStreams(String categoryId) async {
    final response = await _get({
      ..._auth,
      'action': 'get_live_streams',
      'category_id': categoryId,
    });
    final data = response.data;
    if (data is! List) return const [];
    return [
      for (final entry in data)
        if (entry is Map)
          XtreamChannel(
            streamId: '${entry['stream_id']}',
            name: '${entry['name'] ?? 'Unnamed'}',
            categoryId: '${entry['category_id'] ?? categoryId}',
            logoUrl: _asNonEmpty(entry['stream_icon']),
            epgChannelId: _asNonEmpty(entry['epg_channel_id']),
          ),
    ];
  }

  /// §4: stream URLs are built client-side, never returned by the API.
  ///
  /// Phase 0 found these 302-redirect to a different host with a tokenised
  /// path, so whatever plays this must follow redirects — libmpv does by
  /// default. The redirect target is often cleartext HTTP even when the panel
  /// is not, which is the §11 iOS ATS problem.
  String liveStreamUrl(String streamId, {String ext = 'ts'}) =>
      '$host/live/$username/$password/$streamId.$ext';

  static int? _asInt(Object? value) => switch (value) {
        final int v => v,
        final String v => int.tryParse(v),
        _ => null,
      };

  static String? _asNonEmpty(Object? value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }
}
