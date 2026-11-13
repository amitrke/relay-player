import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relay_player/data/plex/plex_service.dart';
import 'package:relay_player/data/tmdb/tmdb_client.dart';
import 'package:relay_player/domain/models/media_server.dart';
import 'package:relay_player/features/library/title_extras.dart';

/// Ratings named by source and trailers on a title's page (decided
/// 2026-11-01, title_extras.dart). The page widgets are in
/// film_detail_screen_test.dart and Jellyfin's parsing in
/// media_browser_test.dart; this pins Plex's tags, the labels, and which of
/// TMDB's videos counts as the trailer.
void main() {
  group("Plex's ratings", () {
    test('each tag by the image that names its source', () {
      final r = PlexService.ratingsOf({
        'Rating': [
          {'image': 'imdb://image.rating', 'value': 7.8, 'type': 'audience'},
          {
            'image': 'rottentomatoes://image.rating.ripe',
            'value': 9.1,
            'type': 'critic',
          },
          {
            'image': 'rottentomatoes://image.rating.upright',
            'value': 8.7,
            'type': 'audience',
          },
          {
            'image': 'themoviedb://image.rating',
            'value': '8.0',
            'type': 'audience',
          },
        ],
      });
      expect(ratingLabels(r), [
        'IMDb 7.8',
        'Rotten Tomatoes 91%',
        'RT audience 87%',
        'TMDB 8.0',
      ]);
    });

    test("a listing's two slots, without repeating what a tag gave", () {
      final r = PlexService.ratingsOf({
        'Rating': [
          {'image': 'imdb://image.rating', 'value': 7.8, 'type': 'audience'},
        ],
        'rating': 7.8,
        'ratingImage': 'imdb://image.rating',
        'audienceRating': 8.7,
        'audienceRatingImage': 'rottentomatoes://image.rating.upright',
      });
      expect(ratingLabels(r), ['IMDb 7.8', 'RT audience 87%']);
    });

    test('an old agent names no source, and is left out', () {
      // MediaItem.rating still carries it; only the named line omits it.
      expect(
        PlexService.ratingsOf({'rating': 6.5, 'ratingImage': ''}),
        isEmpty,
      );
      expect(PlexService.ratingsOf({'rating': 6.5}), isEmpty);
    });
  });

  // Plex relays the trailers it supplies from a part key that already has a
  // query (seen 2026-11-01), so the token must be joined with `&`.
  test("the server's token joins a part key with or without a query", () {
    expect(
      PlexService.withToken('http://s/library/parts/1/2/file.mkv', 't'),
      'http://s/library/parts/1/2/file.mkv?X-Plex-Token=t',
    );
    expect(
      PlexService.withToken(
        'http://s/services/iva/assets/9/video.mp4?fmt=4&bitrate=5000',
        't',
      ),
      'http://s/services/iva/assets/9/video.mp4?fmt=4&bitrate=5000'
      '&X-Plex-Token=t',
    );
  });

  test('an unnamed score is a plain star', () {
    expect(
      ratingLabels(const [
        SourcedRating(source: RatingSource.unknown, value: 8.66),
      ]),
      ['★ 8.7'],
    );
  });

  group("TMDB's trailer", () {
    late HttpServer server;
    late List<Object?> results;

    setUp(() async {
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((req) {
        req.response
          ..headers.contentType = ContentType.json
          ..write(jsonEncode({'results': results}));
        req.response.close();
      });
    });
    tearDown(() => server.close(force: true));

    TmdbClient client() => TmdbClient(
      key: '0123456789abcdef0123456789abcdef',
      dio: Dio(BaseOptions(baseUrl: 'http://127.0.0.1:${server.port}')),
    );

    test('a YouTube trailer, an official one before a fan upload', () async {
      results = [
        {
          'site': 'YouTube',
          'type': 'Teaser',
          'key': 'teaser',
          'official': true,
        },
        {'site': 'Vimeo', 'type': 'Trailer', 'key': 'vimeo', 'official': true},
        {'site': 'YouTube', 'type': 'Trailer', 'key': 'fan', 'official': false},
        {'site': 'YouTube', 'type': 'Trailer', 'key': 'real', 'official': true},
      ];
      expect(
        await client().trailerUrl(278, tv: false),
        'https://www.youtube.com/watch?v=real',
      );
    });

    test('teasers and clips are not trailers', () async {
      results = [
        {'site': 'YouTube', 'type': 'Clip', 'key': 'clip'},
        {'site': 'YouTube', 'type': 'Featurette', 'key': 'f'},
      ];
      expect(await client().trailerUrl(278, tv: true), isNull);
    });
  });
}
