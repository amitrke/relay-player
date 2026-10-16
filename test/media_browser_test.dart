import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:relay_player/data/jellyfin/media_browser_service.dart';
import 'package:relay_player/domain/models/media_server.dart';

/// The Jellyfin and Emby client (architecture.md §6.2) against a local fake
/// that answers in the shapes both projects document. Not a real server:
/// whether a real Jellyfin or Emby accepts these requests is a manual check
/// (MANUAL_TESTING.md). What this pins is what the app sends and how it reads
/// the answers.
class _Fake {
  _Fake({this.product = 'Jellyfin Server', this.onlyUnderEmby = false});

  final String product;
  final bool onlyUnderEmby;
  late HttpServer _server;
  final requests = <String>[];
  final headers = <String, Map<String, String>>{};
  final bodies = <String, Object?>{};
  var quickConnectApproved = false;
  var totalMovies = 450;

  String get base => 'http://127.0.0.1:${_server.port}';

  Future<void> start() async {
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _server.listen(_handle);
  }

  Future<void> stop() => _server.close(force: true);

  Future<void> _handle(HttpRequest req) async {
    var path = req.uri.path;
    final line = '${req.method} $path';
    requests.add('$line?${req.uri.query}');
    headers[line] = {
      for (final h in ['authorization', 'x-emby-authorization', 'x-emby-token'])
        h: ?req.headers.value(h),
    };
    final raw = await utf8.decoder.bind(req).join();
    bodies[line] = raw.isEmpty ? null : jsonDecode(raw);

    if (onlyUnderEmby) {
      if (!path.startsWith('/emby/')) return _send(req, 404, '');
      path = path.substring('/emby'.length);
    }
    final q = req.uri.queryParameters;
    final Object? body = switch (path) {
      '/System/Info/Public' => {
        'Id': 'srv-1',
        'ServerName': 'Home',
        'ProductName': product,
        'Version': '10.10.0',
      },
      '/QuickConnect/Enabled' => true,
      '/QuickConnect/Initiate' => {'Code': '123456', 'Secret': 'sec'},
      '/QuickConnect/Connect' => {'Authenticated': quickConnectApproved},
      '/Users/AuthenticateWithQuickConnect' || '/Users/AuthenticateByName' =>
        {
          'User': {'Id': 'u1', 'Name': 'me'},
          'AccessToken': 'tok-1',
        },
      '/Users/u1/Views' => {
        'Items': [
          {'Id': 'lib-m', 'Name': 'Films', 'CollectionType': 'movies'},
          {'Id': 'lib-s', 'Name': 'Shows', 'CollectionType': 'tvshows'},
          {'Id': 'lib-x', 'Name': 'Music', 'CollectionType': 'music'},
        ],
      },
      '/Users/u1/Items' when q['SearchTerm'] != null => {
        'Items': [_movie('m-search')],
        'TotalRecordCount': 1,
      },
      '/Users/u1/Items' when q['ParentId'] == 'lib-m' => _page(q),
      '/Users/u1/Items' when q['ParentId'] == 'show-1' => {
        'Items': [_season()],
        'TotalRecordCount': 1,
      },
      '/Users/u1/Items/m-1' => {
        ..._movie('m-1'),
        'MediaSources': [
          {'Id': 'ms-1', 'Container': 'mkv', 'Size': 1234},
        ],
      },
      '/Users/u1/Items/Resume' => {
        'Items': [_movie('m-1'), _episode()],
      },
      '/Shows/NextUp' => {
        'Items': [_episode()],
      },
      '/Shows/show-1/Episodes' => {
        'Items': [_episode()],
      },
      _ when path.startsWith('/Users/u1/PlayedItems/') => {},
      _ when path.startsWith('/Sessions/Playing') => null,
      _ => 'missing',
    };
    if (body == 'missing') return _send(req, 404, '');
    _send(req, 200, body == null ? '' : jsonEncode(body));
  }

  Map<String, Object?> _page(Map<String, String> q) {
    final start = int.parse(q['StartIndex'] ?? '0');
    final limit = int.parse(q['Limit'] ?? '100');
    final end = (start + limit).clamp(0, totalMovies);
    return {
      'Items': [for (var i = start; i < end; i++) _movie('m-$i')],
      'TotalRecordCount': totalMovies,
    };
  }

  void _send(HttpRequest req, int status, String body) {
    req.response
      ..statusCode = status
      ..headers.contentType = ContentType.json
      ..write(body);
    req.response.close();
  }
}

Map<String, Object?> _movie(String id) => {
  'Id': id,
  'Name': 'Film $id',
  'Type': 'Movie',
  'ProductionYear': 1994,
  'RunTimeTicks': 90 * 60 * 10000000,
  'ImageTags': {'Primary': 'abc'},
  'ProviderIds': {'Imdb': 'tt0111161', 'Tmdb': '278'},
  'Genres': ['Drama'],
  'UserData': {
    'Played': false,
    'PlayCount': 0,
    'PlaybackPositionTicks': 10 * 60 * 10000000,
  },
};

Map<String, Object?> _season() => {
  'Id': 'season-1',
  'Name': 'Season 1',
  'Type': 'Season',
  'IndexNumber': 1,
  'SeriesId': 'show-1',
  'SeriesName': 'The Show',
  'SeriesPrimaryImageTag': 'x',
};

Map<String, Object?> _episode() => {
  'Id': 'ep-1',
  'Name': 'Pilot',
  'Type': 'Episode',
  'IndexNumber': 1,
  'ParentIndexNumber': 1,
  'SeriesId': 'show-1',
  'SeasonId': 'season-1',
  'SeriesName': 'The Show',
  'SeriesPrimaryImageTag': 'x',
  'ProviderIds': {'Tvdb': '349232'},
  'UserData': {'Played': true, 'PlayCount': 2},
};

const _client = MediaBrowserClientInfo(deviceId: 'dev-1', device: 'test');

void main() {
  late _Fake fake;

  Future<MediaBrowserService> signedIn({String product = 'Jellyfin Server'}) async {
    fake = _Fake(product: product);
    await fake.start();
    addTearDown(fake.stop);
    final info = await MediaBrowserService.probe(fake.base);
    final auth = await MediaBrowserService.signIn(
      info,
      _client,
      username: 'me',
      password: 'pw',
    );
    return MediaBrowserService(info: info, auth: auth, client: _client);
  }

  test('an address becomes a base URL with a scheme and no trailing slash', () {
    expect(MediaBrowserService.normaliseAddress('nas:8096'), 'http://nas:8096');
    expect(
      MediaBrowserService.normaliseAddress(' https://jf.example/ '),
      'https://jf.example',
    );
  });

  test('the server says whether it is Jellyfin or Emby', () async {
    final jf = await signedIn();
    expect(jf.kind, ServerKind.jellyfin);
    expect(jf.id, 'srv-1');
    expect(jf.name, 'Home');

    final emby = await signedIn(product: 'Emby Server');
    expect(emby.kind, ServerKind.emby);
  });

  test('an Emby server that only answers under /emby is found there', () async {
    fake = _Fake(product: 'Emby Server', onlyUnderEmby: true);
    await fake.start();
    addTearDown(fake.stop);
    final info = await MediaBrowserService.probe(fake.base);
    expect(info.apiBase, '${fake.base}/emby');
    expect(info.kind, ServerKind.emby);
  });

  test('Jellyfin signs in with Authorization, Emby with X-Emby-Authorization',
      () async {
    final jf = await signedIn();
    await jf.sections();
    final jfh = fake.headers['GET /Users/u1/Views']!;
    expect(jfh['authorization'], startsWith('MediaBrowser Client="Subnext Player"'));
    expect(jfh['authorization'], contains('DeviceId="dev-1"'));
    expect(jfh['authorization'], contains('Token="tok-1"'));
    expect(jfh.containsKey('x-emby-authorization'), isFalse);

    final emby = await signedIn(product: 'Emby Server');
    await emby.sections();
    final eh = fake.headers['GET /Users/u1/Views']!;
    expect(eh['x-emby-authorization'], contains('DeviceId="dev-1"'));
    expect(eh['x-emby-token'], 'tok-1');
    expect(fake.bodies['POST /Users/AuthenticateByName'],
        {'Username': 'me', 'Pw': 'pw'});
  });

  test('film and show libraries only; a music library is left out', () async {
    final s = await signedIn();
    final sections = await s.sections();
    expect([for (final x in sections) (x.title, x.type)], [
      ('Films', MediaSectionType.movies),
      ('Shows', MediaSectionType.shows),
    ]);
  });

  test('a large library is read page by page, all of it', () async {
    final s = await signedIn();
    final films = (await s.sections()).first;
    final items = await s.allItems(films);
    expect(items, hasLength(450));
    expect(items.last.id, 'm-449');
    expect(
      fake.requests.where((r) => r.startsWith('GET /Users/u1/Items?')).length,
      greaterThan(1),
    );
  });

  test('an item reads into the neutral shape', () async {
    final s = await signedIn();
    final m = (await s.item('m-1'))!;
    expect(m.type, MediaItemType.movie);
    expect(m.title, 'Film m-1');
    expect(m.year, 1994);
    expect(m.duration, const Duration(minutes: 90));
    expect(m.viewOffset, const Duration(minutes: 10));
    expect(m.viewCount, 0);
    expect(m.ids.imdb, 'tt0111161');
    expect(m.ids.tmdb, '278');
    expect(m.posterPath, '/Items/m-1/Images/Primary');
    expect(m.genres, ['Drama']);
  });

  test('an episode without its own poster uses its show\'s, and counts plays',
      () async {
    final s = await signedIn();
    final e = (await s.episodesOf('show-1')).single;
    expect(e.type, MediaItemType.episode);
    expect(e.showTitle, 'The Show');
    expect(e.parentIndex, 1);
    expect(e.index, 1);
    expect(e.viewCount, 2);
    expect(e.isWatched, isTrue);
    expect(e.ids.tvdb, '349232');
    expect(e.posterPath, '/Items/show-1/Images/Primary');
  });

  test('posters carry no token', () async {
    final s = await signedIn();
    final url = s.posterUrlForPath('/Items/m-1/Images/Primary')!;
    expect(url, startsWith('${fake.base}/Items/m-1/Images/Primary?'));
    expect(url, isNot(contains('tok-1')));
  });

  test('direct play is the static stream, with the token Jellyfin expects',
      () async {
    final s = await signedIn();
    final p = await s.directPlay('m-1');
    final uri = Uri.parse(p.url);
    expect(uri.path, '/Videos/m-1/stream');
    expect(uri.queryParameters['static'], 'true');
    expect(uri.queryParameters['MediaSourceId'], 'ms-1');
    expect(uri.queryParameters['ApiKey'], 'tok-1');
    expect(p.resumeFrom, const Duration(minutes: 10));
    expect(p.item?.ids.imdb, 'tt0111161');

    final d = await s.downloadSource('m-1');
    expect(Uri.parse(d.url).path, '/Items/m-1/Download');
    expect(d.extension, 'mkv');
    expect(d.sizeBytes, 1234);
  });

  test('Emby media URLs use api_key', () async {
    final s = await signedIn(product: 'Emby Server');
    final uri = Uri.parse((await s.directPlay('m-1')).url);
    expect(uri.queryParameters['api_key'], 'tok-1');
    expect(uri.queryParameters.containsKey('ApiKey'), isFalse);
  });

  test('progress is started, then progress, then stopped', () async {
    final s = await signedIn();
    Future<void> report(String state, int min) => s.reportProgress(
      id: 'm-1',
      state: state,
      position: Duration(minutes: min),
      duration: const Duration(minutes: 90),
    );
    await report('playing', 1);
    await report('playing', 2);
    await report('stopped', 3);
    expect(
      [for (final r in fake.requests) if (r.contains('/Sessions/')) r.split('?').first],
      [
        'POST /Sessions/Playing',
        'POST /Sessions/Playing/Progress',
        'POST /Sessions/Playing/Progress',
        'POST /Sessions/Playing/Stopped',
      ],
    );
    final stopped = fake.bodies['POST /Sessions/Playing/Stopped']! as Map;
    expect(stopped['ItemId'], 'm-1');
    expect(stopped['PositionTicks'], 3 * 60 * 10000000);
  });

  test('a stopped report with no session first starts one (offline replay)',
      () async {
    final s = await signedIn();
    await s.reportProgress(
      id: 'm-1',
      state: 'stopped',
      position: const Duration(minutes: 40),
      duration: const Duration(minutes: 90),
    );
    expect(
      [for (final r in fake.requests) if (r.contains('/Sessions/')) r.split('?').first],
      ['POST /Sessions/Playing', 'POST /Sessions/Playing/Stopped'],
    );
  });

  test('watched and unwatched', () async {
    final s = await signedIn();
    await s.setWatched('m-1', watched: true);
    await s.setWatched('m-1', watched: false);
    expect(
      [for (final r in fake.requests) if (r.contains('PlayedItems')) r.split('?').first],
      ['POST /Users/u1/PlayedItems/m-1', 'DELETE /Users/u1/PlayedItems/m-1'],
    );
  });

  test('on deck merges resume and next up, once each', () async {
    final s = await signedIn();
    final deck = await s.onDeck(await s.sections());
    expect([for (final m in deck) m.id], ['m-1', 'ep-1']);
  });

  test('Quick Connect: a code, then nothing until it is approved', () async {
    fake = _Fake();
    await fake.start();
    addTearDown(fake.stop);
    final info = await MediaBrowserService.probe(fake.base);
    expect(await MediaBrowserService.quickConnectEnabled(info), isTrue);
    final code = await MediaBrowserService.startQuickConnect(info, _client);
    expect(code.code, '123456');
    expect(
      await MediaBrowserService.pollQuickConnect(info, _client, code),
      isNull,
    );
    fake.quickConnectApproved = true;
    final auth = await MediaBrowserService.pollQuickConnect(info, _client, code);
    expect(auth?.token, 'tok-1');
    expect(fake.bodies['POST /Users/AuthenticateWithQuickConnect'],
        {'Secret': 'sec'});
  });

  test('nothing at the address is said plainly', () async {
    expect(
      () => MediaBrowserService.probe('http://127.0.0.1:1'),
      throwsA(isA<MediaServerUnreachable>()),
    );
  });
}
