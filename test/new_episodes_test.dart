import 'dart:convert';
import 'dart:io';

import 'package:dart_plex/dart_plex.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relay_player/data/jellyfin/media_browser_service.dart';
import 'package:relay_player/data/local/library_cache.dart';
import 'package:relay_player/data/plex/plex_service.dart';
import 'package:relay_player/domain/models/catalog_item.dart';
import 'package:relay_player/domain/models/media_server.dart';
import 'package:relay_player/features/library/library_sort.dart';

/// Shows ordered by their newest episode, and how many episodes are unwatched
/// (2026-10-30). Found by putting the app beside Plex's own TV app on the same
/// server: Plex put a show with an episode from last night first, with a count
/// on its poster, and this app left it wherever the show had first been added.
///
/// Against fakes in the shapes Plex and Jellyfin send, not a real server; the
/// emulator check against a real one is in MANUAL_TESTING.md.
class _FakePlex {
  _FakePlex({this.episodesFail = false});

  final bool episodesFail;
  late HttpServer _server;
  final requests = <Uri>[];

  String get base => 'http://127.0.0.1:${_server.port}';

  Future<void> start() async {
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _server.listen((req) {
      requests.add(req.uri);
      final type = req.uri.queryParameters['type'];
      final status = type == '4' && episodesFail ? 500 : 200;
      final items = switch (type) {
        // Shows, by title. "Old Show" was added long ago and had an episode
        // yesterday; "New Show" arrived last month and has had nothing since.
        '2' => [
          _show('s-new', 'New Show', added: _day(20), leaves: 8, viewed: 8),
          _show('s-old', 'Old Show', added: _day(1), leaves: 62, viewed: 56),
          _show('s-quiet', 'Quiet Show', added: _day(5)),
        ],
        // Episodes, newest first, as asked.
        '4' => [
          _episode('s-old', added: _day(29)),
          _episode('s-old', added: _day(27)),
          _episode('s-new', added: _day(20)),
        ],
        _ => const <Map<String, Object?>>[],
      };
      req.response
        ..statusCode = status
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({
          'MediaContainer': {'totalSize': items.length, 'Metadata': items},
        }))
        ..close();
    });
  }

  Future<void> stop() => _server.close(force: true);
}

/// Day [d] of a fixed month, as Plex's epoch seconds.
int _day(int d) => DateTime.utc(2026, 9, d).millisecondsSinceEpoch ~/ 1000;

Map<String, Object?> _show(
  String key,
  String title, {
  required int added,
  int? leaves,
  int? viewed,
}) => {
  'ratingKey': key,
  'key': '/library/metadata/$key/children',
  'type': 'show',
  'title': title,
  'addedAt': added,
  'leafCount': ?leaves,
  'viewedLeafCount': ?viewed,
};

Map<String, Object?> _episode(String show, {required int added}) => {
  'ratingKey': 'e-$show-$added',
  'key': '/library/metadata/e',
  'type': 'episode',
  'title': 'An episode',
  'grandparentRatingKey': show,
  'addedAt': added,
};

const _shows = MediaSection(
  id: '2',
  title: 'TV',
  type: MediaSectionType.shows,
  typeName: 'show',
);

void main() {
  Future<(PlexService, _FakePlex)> plex({bool episodesFail = false}) async {
    final fake = _FakePlex(episodesFail: episodesFail);
    await fake.start();
    addTearDown(fake.stop);
    final s = PlexService(clientId: 'test', serverId: 'srv')
      ..reconnect(baseUrl: fake.base, token: '<redacted>');
    return (s, fake);
  }

  List<String> recentlyAdded(MediaServer s, List<MediaItem> items) => [
    for (final c in LibrarySort.recentlyAdded.apply([
      for (final i in items) s.toCatalogItem(i),
    ]))
      c.title,
  ];

  group('Plex', () {
    test('a show is dated by its newest episode, so it sorts first', () async {
      final (s, fake) = await plex();
      final items = await s.allItems(_shows);

      final old = items.firstWhere((i) => i.id == 's-old');
      expect(old.addedAt, DateTime.utc(2026, 9, 29));
      expect(recentlyAdded(s, items), ['Old Show', 'New Show', 'Quiet Show']);

      // What was asked: one page of the section's episodes, newest first.
      final ask = fake.requests.firstWhere(
        (u) => u.queryParameters['type'] == '4',
      );
      expect(ask.path, '/library/sections/2/all');
      expect(ask.queryParameters['sort'], 'addedAt:desc');
      expect(
        ask.queryParameters['X-Plex-Container-Size'],
        '${PlexService.newestEpisodeWindow}',
      );
    });

    test('control: without the episode request, the old order comes back',
        () async {
      // The order this fixes, so the test above is shown to depend on the
      // episodes rather than passing on the shows' own dates.
      final (s, _) = await plex(episodesFail: true);
      final items = await s.allItems(_shows);
      expect(recentlyAdded(s, items), ['New Show', 'Quiet Show', 'Old Show']);
    });

    test('a failed episode request still loads every show', () async {
      final (s, _) = await plex(episodesFail: true);
      expect(await s.allItems(_shows), hasLength(3));
    });

    test('a film library makes no episode request', () async {
      final (s, fake) = await plex();
      await s.allItems(const MediaSection(
        id: '1',
        title: 'Films',
        type: MediaSectionType.movies,
        typeName: 'movie',
      ));
      expect(
        fake.requests.where((u) => u.queryParameters['type'] == '4'),
        isEmpty,
      );
    });

    test('unwatched episodes come from leafCount and viewedLeafCount', () async {
      final (s, _) = await plex();
      final byId = {for (final i in await s.allItems(_shows)) i.id: i};
      expect(byId['s-old']!.unwatchedEpisodes, 6);
      expect(byId['s-new']!.unwatchedEpisodes, 0);
      expect(byId['s-quiet']!.unwatchedEpisodes, isNull,
          reason: 'no counts sent, so unknown rather than zero');
    });

    test('a film never carries an unwatched count', () {
      final film = PlexService.itemOf(PlexMetadata.fromJson(const {
        'ratingKey': 'm1',
        'key': '/library/metadata/m1',
        'type': 'movie',
        'title': 'Film',
        'leafCount': 1,
        'viewedLeafCount': 0,
      }));
      expect(film.unwatchedEpisodes, isNull);
    });
  });

  group('Jellyfin and Emby', () {
    Map<String, dynamic> series({String? lastAdded, int? unplayed}) => {
      'Id': 'show-1',
      'Name': 'The Show',
      'Type': 'Series',
      'DateCreated': '2024-01-01T00:00:00Z',
      'DateLastMediaAdded': ?lastAdded,
      'UserData': {'UnplayedItemCount': ?unplayed},
    };

    test('a series is dated by DateLastMediaAdded', () {
      final i = MediaBrowserService.itemOf(
        series(lastAdded: '2026-09-29T00:00:00Z', unplayed: 3),
      );
      expect(i.addedAt, DateTime.utc(2026, 9, 29));
      expect(i.unwatchedEpisodes, 3);
    });

    test('without it, its own date, as before', () {
      final i = MediaBrowserService.itemOf(series());
      expect(i.addedAt, DateTime.utc(2024));
      expect(i.unwatchedEpisodes, isNull);
    });

    test('a film keeps DateCreated and has no count', () {
      final i = MediaBrowserService.itemOf({
        'Id': 'm',
        'Name': 'Film',
        'Type': 'Movie',
        'DateCreated': '2024-01-01T00:00:00Z',
        'DateLastMediaAdded': '2026-09-29T00:00:00Z',
        'UserData': {'UnplayedItemCount': 1},
      });
      expect(i.addedAt, DateTime.utc(2024));
      expect(i.unwatchedEpisodes, isNull);
    });
  });

  test('the count survives the library cache', () {
    const show = CatalogItem(
      source: CatalogSource.server,
      sourceId: 'srv',
      kind: CatalogKind.show,
      id: 's',
      title: 'Show',
      unwatchedEpisodes: 6,
    );
    final back = catalogItemFromJson(
      jsonDecode(jsonEncode(catalogItemToJson(show))),
    )!;
    expect(back.unwatchedEpisodes, 6);
    // And through the copies the app makes of a cached item.
    expect(back.withPosterUrl('x').unwatchedEpisodes, 6);
    expect(back.withMetadata(genres: const []).unwatchedEpisodes, 6);
  });
}
