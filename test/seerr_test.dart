import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:relay_player/data/seerr/seerr_client.dart';

/// The Seerr client (architecture.md §20) against a local fake that answers
/// in the shapes Overseerr's API documents. Not a real server: whether a real
/// Overseerr, Jellyseerr or Seerr accepts these requests is a manual check
/// (MANUAL_TESTING.md). What this pins is what the app sends and how it reads
/// the answers.
class _Fake {
  _Fake({this.mediaServerType = 1});

  final int mediaServerType;
  late HttpServer _server;
  final requests = <String>[];
  final headers = <String, Map<String, String>>{};
  final bodies = <String, Object?>{};
  var requestStatus = 201;

  String get base => 'http://127.0.0.1:${_server.port}';

  Future<void> start() async {
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _server.listen(_handle);
  }

  Future<void> stop() => _server.close(force: true);

  bool _signedIn(HttpRequest req) =>
      req.headers.value('x-api-key') == 'key-1' ||
      (req.headers.value('cookie') ?? '').contains('connect.sid=sid-1');

  Future<void> _handle(HttpRequest req) async {
    final path = req.uri.path;
    final line = '${req.method} $path';
    requests.add('$line?${req.uri.query}');
    headers[line] = {
      for (final h in ['x-api-key', 'cookie', 'content-type'])
        h: ?req.headers.value(h),
    };
    final raw = await utf8.decoder.bind(req).join();
    bodies[line] = raw.isEmpty ? null : jsonDecode(raw);

    if (path == '/api/v1/settings/public') {
      return _send(req, 200, {
        'applicationTitle': 'Home Requests',
        'mediaServerType': mediaServerType,
        'localLogin': true,
      });
    }
    if (path.startsWith('/api/v1/auth/') && req.method == 'POST') {
      final b = bodies[line];
      final ok =
          b is Map &&
          (b['authToken'] == 'plex-tok' || b['password'] == 'right');
      if (!ok) return _send(req, 401, {'message': 'nope'});
      req.response.headers.add(
        'set-cookie',
        'connect.sid=sid-1; Path=/; HttpOnly',
      );
      return _send(req, 200, {'id': 7, 'displayName': 'me'});
    }
    if (!_signedIn(req)) return _send(req, 403, {'message': 'no'});
    final Object? body = switch (path) {
      '/api/v1/auth/me' => {'id': 7, 'displayName': 'me'},
      '/api/v1/search' => {
        'results': [
          {
            'id': 11,
            'mediaType': 'movie',
            'title': 'A Film',
            'releaseDate': '2019-05-01',
            'posterPath': '/p.jpg',
          },
          {
            'id': 22,
            'mediaType': 'tv',
            'name': 'A Show',
            'firstAirDate': '2021-01-01',
            'mediaInfo': {'status': 4},
          },
          {'id': 33, 'mediaType': 'person', 'name': 'Someone'},
          {
            'id': 44,
            'mediaType': 'movie',
            'title': 'Owned',
            'mediaInfo': {'status': 5},
          },
        ],
      },
      '/api/v1/tv/22' => {
        'name': 'A Show',
        'seasons': [
          {'seasonNumber': 0},
          {'seasonNumber': 1},
          {'seasonNumber': 2},
        ],
      },
      '/api/v1/movie/11' => {'title': 'A Film'},
      '/api/v1/request' when req.method == 'GET' => {
        'results': [
          {
            'status': 2,
            'createdAt': '2026-10-01T10:00:00.000Z',
            'media': {'tmdbId': 11, 'mediaType': 'movie', 'status': 3},
          },
        ],
      },
      '/api/v1/request' => null,
      _ => null,
    };
    if (path == '/api/v1/request' && req.method == 'POST') {
      return _send(req, requestStatus, {});
    }
    if (body == null) return _send(req, 404, {});
    return _send(req, 200, body);
  }

  Future<void> _send(HttpRequest req, int status, Object? body) async {
    req.response.statusCode = status;
    req.response.headers.contentType = ContentType.json;
    req.response.write(jsonEncode(body));
    await req.response.close();
  }
}

void main() {
  late _Fake fake;

  setUp(() async {
    fake = _Fake();
    await fake.start();
  });
  tearDown(() => fake.stop());

  test('normalise adds a scheme and strips trailing slashes', () {
    expect(SeerrClient.normalise(' host:5055// '), 'http://host:5055');
    expect(SeerrClient.normalise('https://r.example'), 'https://r.example');
  });

  test('probe reads the public settings', () async {
    final info = await SeerrClient.probe('${fake.base}/');
    expect(info.baseUrl, fake.base);
    expect(info.title, 'Home Requests');
    expect(info.usesPlex, isTrue);
    expect(info.localLogin, isTrue);
  });

  test('probe of something that is not Seerr says so', () async {
    final base = fake.base;
    await fake.stop();
    // Nothing listening any more: a refused connection, not a hang.
    expect(() => SeerrClient.probe(base), throwsA(isA<SeerrException>()));
  });

  test('signing in with Plex posts the account token and keeps the cookie '
      'without its attributes', () async {
    final info = await SeerrClient.probe(fake.base);
    final s = await SeerrClient.signIn(info, plexToken: 'plex-tok');
    expect(s.auth, SeerrAuth.plex);
    expect(s.cookie, 'connect.sid=sid-1');
    expect(s.userName, 'me');
    expect(fake.bodies['POST /api/v1/auth/plex'], {'authToken': 'plex-tok'});
  });

  test('a Plex-backed server takes a password at /auth/local, a Jellyfin-'
      'backed one at /auth/jellyfin', () async {
    var info = await SeerrClient.probe(fake.base);
    await SeerrClient.signIn(info, username: 'me@x', password: 'right');
    expect(fake.bodies['POST /api/v1/auth/local'], {
      'email': 'me@x',
      'password': 'right',
    });

    await fake.stop();
    fake = _Fake(mediaServerType: 2);
    await fake.start();
    info = await SeerrClient.probe(fake.base);
    expect(info.usesPlex, isFalse);
    await SeerrClient.signIn(info, username: 'me', password: 'right');
    expect(fake.bodies['POST /api/v1/auth/jellyfin'], {
      'username': 'me',
      'password': 'right',
    });
  });

  test('a wrong password is refused with a message', () async {
    final info = await SeerrClient.probe(fake.base);
    expect(
      () => SeerrClient.signIn(info, username: 'me', password: 'wrong'),
      throwsA(isA<SeerrException>()),
    );
  });

  test('an API key is checked against /auth/me', () async {
    final info = await SeerrClient.probe(fake.base);
    final s = await SeerrClient.signIn(info, apiKey: 'key-1');
    expect(s.auth, SeerrAuth.apiKey);
    expect(s.headers, {'X-Api-Key': 'key-1'});
    expect(
      () => SeerrClient.signIn(info, apiKey: 'bad'),
      throwsA(isA<SeerrException>()),
    );
  });

  test('a session survives a round trip through its stored form', () {
    const s = SeerrSession(
      auth: SeerrAuth.password,
      cookie: 'connect.sid=x',
      userName: 'me',
    );
    final back = SeerrSession.fromJson(jsonDecode(jsonEncode(s.toJson())))!;
    expect(back.auth, SeerrAuth.password);
    expect(back.cookie, 'connect.sid=x');
    expect(back.apiKey, isNull);
    expect(back.userName, 'me');
    expect(SeerrSession.fromJson({'auth': 'nonsense'}), isNull);
  });

  group('signed in', () {
    late SeerrClient client;

    setUp(() async {
      final info = await SeerrClient.probe(fake.base);
      client = SeerrClient(
        info,
        await SeerrClient.signIn(info, plexToken: 'plex-tok'),
      );
    });

    test('search encodes spaces as %20, sends the cookie, and keeps films '
        'and shows only', () async {
      final titles = await client.search('a film');
      expect(
        fake.requests.where((r) => r.startsWith('GET /api/v1/search')).single,
        'GET /api/v1/search?query=a%20film&page=1',
      );
      expect(
        fake.headers['GET /api/v1/search']!['cookie'],
        'connect.sid=sid-1',
      );
      expect(titles.map((t) => t.title), ['A Film', 'A Show', 'Owned']);
      final film = titles[0];
      expect(film.isShow, isFalse);
      expect(film.year, 2019);
      expect(film.posterUrl(), 'https://image.tmdb.org/t/p/w300/p.jpg');
      expect(film.availability, SeerrAvailability.unknown);
      expect(film.availability.canRequest, isTrue);
      expect(titles[1].availability, SeerrAvailability.partial);
      expect(titles[1].availability.canRequest, isTrue);
      expect(titles[2].availability.canRequest, isFalse);
    });

    test('a film request sends its TMDB id', () async {
      final film = (await client.search('a film')).first;
      await client.request(film);
      expect(fake.bodies['POST /api/v1/request'], {
        'mediaType': 'movie',
        'mediaId': 11,
      });
      expect(
        fake.headers['POST /api/v1/request']!['content-type'],
        startsWith('application/json'),
      );
    });

    test('a show request asks for every season but specials', () async {
      final show = (await client.search('a show'))[1];
      await client.request(show);
      expect(fake.bodies['POST /api/v1/request'], {
        'mediaType': 'tv',
        'mediaId': 22,
        'seasons': [1, 2],
      });
    });

    test('a request the server already has is said plainly', () async {
      fake.requestStatus = 409;
      final film = (await client.search('a film')).first;
      expect(
        () => client.request(film),
        throwsA(
          isA<SeerrException>().having(
            (e) => e.message,
            'message',
            contains('already'),
          ),
        ),
      );
    });

    test('my requests are filtered to me and carry looked-up titles', () async {
      final list = await client.myRequests();
      final get = fake.requests
          .where((r) => r.startsWith('GET /api/v1/request?'))
          .single;
      expect(get, contains('requestedBy=7'));
      expect(list.single.title, 'A Film');
      expect(list.single.status, 2);
      expect(list.single.availability, SeerrAvailability.processing);
      expect(list.single.requestedAt, DateTime.utc(2026, 10, 1, 10));
    });

    test(
      'a session the server no longer accepts is reported as signed out',
      () async {
        final stale = SeerrClient(
          client.info,
          const SeerrSession(auth: SeerrAuth.plex, cookie: 'connect.sid=old'),
        );
        expect(
          () => stale.search('a film'),
          throwsA(
            isA<SeerrException>().having(
              (e) => e.message,
              'message',
              contains('no longer'),
            ),
          ),
        );
      },
    );
  });
}
