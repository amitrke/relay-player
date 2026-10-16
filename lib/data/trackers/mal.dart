import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';

import '../../i18n/strings.g.dart';
import 'anime_match.dart';
import 'tracker.dart';

/// MyAnimeList (architecture.md §19.3).
///
/// MAL has no device flow. Sign-in is OAuth 2 with PKCE: the app opens the
/// authorise page, MAL sends the browser to the app's registered redirect
/// with a `code`, and the app exchanges that code, with the verifier only it
/// knows, for a token. The registered redirect is a loopback address,
/// [redirectUri], so:
///
/// - on a device with a browser, the app listens there for the moment of the
///   sign-in and catches the code itself ([MalRedirectCatcher]);
/// - anywhere it cannot (the browser was on another device, or the platform
///   suspended the app), the page that fails to load still has the code in
///   its address, and the person pastes that address.
///
/// A TV has neither, and gets MAL with Move to another device (§17). The app
/// is registered as "other" (no client secret): MAL requires no secret for
/// that type, and an installed app cannot keep one anyway.
class MalTracker implements Tracker {
  MalTracker({
    required this.clientId,
    Dio? dio,
    this.apiBase = 'https://api.myanimelist.net/v2',
    this.authBase = 'https://myanimelist.net/v1/oauth2',
  }) : _dio = dio ?? Dio(_options);

  /// Must match the redirect registered for the app exactly.
  static const redirectPort = 41235;
  static const redirectUri = 'http://localhost:$redirectPort/mal';

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
  TrackerKind get kind => TrackerKind.mal;

  static String _random(int length) {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final r = Random.secure();
    return List.generate(length, (_) => chars[r.nextInt(chars.length)]).join();
  }

  /// MAL accepts only the `plain` challenge method, so the challenge is the
  /// verifier itself. Still worth having: it ties the code to this sign-in,
  /// so a code read off a screen by someone else is useless to them.
  @override
  Future<SignInStart> startSignIn() async {
    final verifier = _random(96);
    final state = _random(24);
    return BrowserSignIn(
      url: Uri.parse('$authBase/authorize').replace(
        queryParameters: {
          'response_type': 'code',
          'client_id': clientId,
          'code_challenge': verifier,
          'code_challenge_method': 'plain',
          'state': state,
          'redirect_uri': redirectUri,
        },
      ).toString(),
      verifier: verifier,
      state: state,
    );
  }

  /// The code from what was pasted (the whole redirect address, or the bare
  /// code). An address whose `state` is not this sign-in's is refused.
  static String? codeFrom(String pasted, String? state) {
    final p = pasted.trim();
    if (p.contains('code=')) {
      final uri = Uri.tryParse(p.contains('://') ? p : 'http://x/?$p');
      final code = uri?.queryParameters['code'];
      final got = uri?.queryParameters['state'];
      if (state != null && got != null && got != state) return null;
      return (code == null || code.isEmpty) ? null : code;
    }
    return p.length > 20 && !p.contains(' ') ? p : null;
  }

  @override
  Future<TrackerToken> finishSignIn(SignInStart start, {String? pasted}) async {
    final s = start as BrowserSignIn;
    final code = codeFrom(pasted ?? '', s.state);
    if (code == null) throw SignInFailed(tr.trackers.errors.badPaste);
    final token = await _tokenCall({
      'client_id': clientId,
      'grant_type': 'authorization_code',
      'code': code,
      'code_verifier': s.verifier!,
      'redirect_uri': redirectUri,
    }, onRefused: () => SignInFailed(tr.trackers.errors.expired));
    return token.withUser(await _userName(token.access));
  }

  Future<TrackerToken> _tokenCall(
    Map<String, String> form, {
    required Exception Function() onRefused,
  }) async {
    final Response<dynamic> r;
    try {
      r = await _dio.post<dynamic>(
        '$authBase/token',
        data: form,
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );
    } on DioException {
      throw TrackerUnavailable(tr.trackers.errors.unavailable(service: kind.label));
    }
    final d = r.data;
    if (r.statusCode != 200 || d is! Map || d['access_token'] is! String) {
      throw onRefused();
    }
    final expires = (d['expires_in'] as num?)?.toInt();
    return TrackerToken(
      access: d['access_token'] as String,
      refresh: d['refresh_token'] as String?,
      expiresAt: expires == null
          ? null
          : DateTime.now().add(Duration(seconds: expires)),
    );
  }

  Future<String?> _userName(String token) async {
    try {
      final r = await _dio.get<dynamic>(
        '$apiBase/users/@me',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return r.data is Map ? '${(r.data as Map)['name'] ?? ''}' : null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<TrackerToken> refresh(TrackerToken token) async {
    final refresh = token.refresh;
    if (refresh == null) throw const TrackerSignedOut();
    final next = await _tokenCall({
      'client_id': clientId,
      'grant_type': 'refresh_token',
      'refresh_token': refresh,
    }, onRefused: () => const TrackerSignedOut());
    return next.withUser(token.userName);
  }

  Future<Response<dynamic>> _api(
    String method,
    String path,
    TrackerToken token, {
    Map<String, dynamic>? query,
    Map<String, String>? form,
  }) async {
    final Response<dynamic> r;
    try {
      r = await _dio.request<dynamic>(
        '$apiBase$path',
        queryParameters: query,
        data: form,
        options: Options(
          method: method,
          headers: {'Authorization': 'Bearer ${token.access}'},
          contentType: form == null ? null : Headers.formUrlEncodedContentType,
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
    return r;
  }

  @override
  Future<bool> markWatched(WatchedItem item, TrackerToken token) async {
    final target = animeTarget(item);
    if (target == null) return false;
    // MAL refuses a query over 64 characters, or under 3.
    var q = target.query;
    if (q.length > 64) q = q.substring(0, 64);
    if (q.length < 3) return false;
    final r = await _api('GET', '/anime', token, query: {
      'q': q,
      'limit': '5',
      'fields': 'num_episodes,media_type,my_list_status,alternative_titles',
    });
    final data = r.data is Map ? (r.data as Map)['data'] : null;
    if (data is! List) return false;
    final nodes = [
      for (final d in data)
        if (d is Map && d['node'] is Map) d['node'] as Map,
    ];
    final match = bestAnimeMatch<Map<dynamic, dynamic>>(target.query, [
      for (final n in nodes)
        if (!target.movie || n['media_type'] == 'movie') n,
    ], (n) {
      final alt = n['alternative_titles'] is Map
          ? n['alternative_titles'] as Map
          : const {};
      return [
        if (n['title'] is String) n['title'] as String,
        if (alt['en'] is String) alt['en'] as String,
        if (alt['ja'] is String) alt['ja'] as String,
        for (final s in (alt['synonyms'] as List?) ?? const [])
          if (s is String) s,
      ];
    });
    if (match == null) return false;

    final status = match['my_list_status'];
    final had = status is Map
        ? (status['num_episodes_watched'] as num?)?.toInt() ?? 0
        : 0;
    if (had >= target.progress) return true;
    final total = (match['num_episodes'] as num?)?.toInt() ?? 0;
    final done = total > 0 && target.progress >= total;
    await _api('PATCH', '/anime/${match['id']}/my_list_status', token, form: {
      'status': done ? 'completed' : 'watching',
      'num_watched_episodes': '${target.progress}',
    });
    return true;
  }
}

/// Waits on [MalTracker.redirectUri] for the browser to come back with a
/// code, on a device whose browser is on the same machine as the app.
///
/// Loopback only, one request, gone after [timeout]: it never listens on the
/// network, and it answers the browser with a page saying the window can be
/// closed.
class MalRedirectCatcher {
  HttpServer? _server;

  /// The full redirect address once it arrives, or null on timeout or when
  /// the port is taken.
  Future<String?> wait({Duration timeout = const Duration(minutes: 5)}) async {
    try {
      _server = await HttpServer.bind(
        InternetAddress.loopbackIPv4,
        MalTracker.redirectPort,
      );
    } on SocketException {
      return null;
    }
    final done = Completer<String?>();
    final timer = Timer(timeout, () {
      if (!done.isCompleted) done.complete(null);
    });
    _server!.listen((req) async {
      if (req.uri.path != '/mal') {
        req.response.statusCode = 404;
        await req.response.close();
        return;
      }
      req.response.headers.contentType = ContentType.html;
      req.response.write(
        '<html><body style="font-family:sans-serif">'
        '<p>${tr.trackers.malCaught}</p></body></html>',
      );
      await req.response.close();
      if (!done.isCompleted) {
        done.complete('${MalTracker.redirectUri}?${req.uri.query}');
      }
    });
    final result = await done.future;
    timer.cancel();
    await close();
    return result;
  }

  Future<void> close() async {
    await _server?.close(force: true);
    _server = null;
  }
}
