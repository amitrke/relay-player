import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:relay_player/data/local/library_cache.dart';
import 'package:relay_player/data/local/library_loader.dart';
import 'package:relay_player/domain/models/catalog_item.dart';

CatalogItem _plex(
  String id,
  String title, {
  String? path,
  String? signedUrl,
  int? views,
}) => CatalogItem(
  source: CatalogSource.plex,
  sourceId: 's1',
  kind: CatalogKind.movie,
  id: id,
  title: title,
  year: 2000,
  posterUrl: signedUrl,
  posterPath: path,
  viewCount: views,
  lastViewedAt: views == null ? null : DateTime(2026, 1, 2),
);

CatalogItem _panel(String id, String title) => CatalogItem(
  source: CatalogSource.xtream,
  sourceId: 'p1',
  kind: CatalogKind.movie,
  id: id,
  title: title,
  posterUrl: 'https://img.example/$id.jpg',
);

LibraryFetch _fetched(List<CatalogItem> items, [String sig = 'a']) =>
    LibraryFetch(items, sig);

Future<List<List<CatalogItem>>> _run(
  List<LibrarySource> sources,
  LibraryCache? cache, {
  Duration timeout = const Duration(milliseconds: 50),
}) => loadLibrary(
  sources,
  cache: cache,
  timeout: timeout,
  timeoutWithCache: timeout,
).toList();

List<String> _titles(List<CatalogItem> l) => [for (final i in l) i.title];

void main() {
  group('what reaches disk', () {
    test('a Plex poster is stored as its path, never its signed URL', () {
      final json = catalogItemToJson(
        _plex(
          '1',
          'Heat',
          path: '/library/metadata/1/thumb/9',
          signedUrl: 'http://192.0.2.1:32400/photo/:/transcode?url=%2Fx&X-Plex-Token=abc123',
        ),
      );
      final text = jsonEncode(json).toLowerCase();
      expect(text.contains('x-plex-token'), isFalse);
      expect(text.contains('abc123'), isFalse);
      expect(json['pp'], '/library/metadata/1/thumb/9');
      expect(json.containsKey('pu'), isFalse);
    });

    test('a URL carrying a token is dropped whatever its source', () {
      final item = CatalogItem(
        source: CatalogSource.xtream,
        sourceId: 'p',
        kind: CatalogKind.movie,
        id: '1',
        title: 'T',
        posterUrl: 'https://x/img?X-Plex-Token=secret',
      );
      expect(jsonEncode(catalogItemToJson(item)).contains('secret'), isFalse);
    });

    test('control: a panel poster URL, which has no credential, is kept', () {
      expect(
        catalogItemToJson(_panel('1', 'T'))['pu'],
        'https://img.example/1.jpg',
      );
    });

    test('an item survives the round trip, watch state included', () {
      final back = catalogItemFromJson(
        catalogItemToJson(_plex('1', 'Heat', path: '/p', views: 2)),
      )!;
      expect(back.title, 'Heat');
      expect(back.year, 2000);
      expect(back.posterPath, '/p');
      expect(back.posterUrl, isNull);
      expect(back.viewCount, 2);
      expect(back.lastViewedAt, DateTime(2026, 1, 2));
    });

    test('junk reads back as nothing', () {
      expect(catalogItemFromJson('x'), isNull);
      expect(catalogItemFromJson({'s': 'plex'}), isNull);
    });
  });

  group('loadLibrary', () {
    test('with nothing kept there is one emission, the fresh one', () async {
      final out = await _run([
        LibrarySource(
          key: 'a',
          fetch: () async => _fetched([_plex('1', 'Heat')]),
        ),
      ], MemoryLibraryCache());
      expect(out.length, 1);
      expect(_titles(out.single), ['Heat']);
    });

    test(
      'what was kept shows first, then the fresh answer replaces it',
      () async {
        final cache = MemoryLibraryCache();
        await cache.write(
          'a',
          CachedSource(
            items: [_plex('1', 'Old')],
            signature: 'a',
            at: DateTime.now(),
          ),
        );
        final out = await _run([
          LibrarySource(
            key: 'a',
            fetch: () async => _fetched([_plex('2', 'New')]),
          ),
        ], cache);
        expect(out.map(_titles), [
          ['Old'],
          ['New'],
        ]);
      },
    );

    test('a source that fails keeps its kept answer in the merge', () async {
      final cache = MemoryLibraryCache();
      await cache.write(
        'slow',
        CachedSource(
          items: [_plex('1', 'Kept')],
          signature: 'a',
          at: DateTime.now(),
        ),
      );
      final out = await _run([
        LibrarySource(
          key: 'slow',
          fetch: () async => throw Exception('timed out'),
        ),
        LibrarySource(
          key: 'ok',
          fetch: () async => _fetched([_panel('2', 'Fresh')]),
        ),
      ], cache);
      expect(_titles(out.last), ['Fresh', 'Kept']);
    });

    test('a source that hangs is cut off and keeps its kept answer', () async {
      final cache = MemoryLibraryCache();
      await cache.write(
        'slow',
        CachedSource(
          items: [_plex('1', 'Kept')],
          signature: 'a',
          at: DateTime.now(),
        ),
      );
      final out = await _run([
        LibrarySource(
          key: 'slow',
          fetch: () => Completer<LibraryFetch>().future,
        ),
      ], cache);
      expect(_titles(out.last), ['Kept']);
    });

    test(
      'a failing source with nothing kept simply contributes nothing',
      () async {
        final out = await _run([
          LibrarySource(key: 'a', fetch: () async => throw Exception('down')),
          LibrarySource(
            key: 'b',
            fetch: () async => _fetched([_panel('2', 'Fresh')]),
          ),
        ], MemoryLibraryCache());
        expect(_titles(out.last), ['Fresh']);
      },
    );

    test('a fresh answer is kept for next time', () async {
      final cache = MemoryLibraryCache();
      await _run([
        LibrarySource(
          key: 'a',
          fetch: () async => _fetched([_plex('1', 'Heat')], 'sig1'),
        ),
      ], cache);
      final stored = await cache.read('a');
      expect(_titles(stored!.items), ['Heat']);
      expect(stored.signature, 'sig1');
    });

    test('a genuinely empty fresh answer replaces what was kept', () async {
      final cache = MemoryLibraryCache();
      await cache.write(
        'a',
        CachedSource(
          items: [_plex('1', 'Gone')],
          signature: 'a',
          at: DateTime.now(),
        ),
      );
      final out = await _run([
        LibrarySource(key: 'a', fetch: () async => _fetched([])),
      ], cache);
      expect(out.last, isEmpty);
      expect((await cache.read('a'))!.items, isEmpty);
    });

    test(
      'an answer made for other choices is not used as a stand-in',
      () async {
        final cache = MemoryLibraryCache();
        await cache.write(
          'a',
          CachedSource(
            items: [_plex('1', 'Wrong')],
            signature: 'old-categories',
            at: DateTime.now(),
          ),
        );
        final out = await _run([
          LibrarySource(
            key: 'a',
            expectedSignature: 'new-categories',
            fetch: () async => throw Exception('down'),
          ),
        ], cache);
        expect(out.last, isEmpty);
      },
    );

    test(
      'kept items are revived, so a Plex poster can be signed again',
      () async {
        final cache = MemoryLibraryCache();
        await cache.write(
          'a',
          CachedSource(
            items: [_plex('1', 'Heat', path: '/thumb')],
            signature: 'a',
            at: DateTime.now(),
          ),
        );
        final out = await _run([
          LibrarySource(
            key: 'a',
            revive: (i) => i.withPosterUrl('signed:${i.posterPath}'),
            fetch: () async => throw Exception('down'),
          ),
        ], cache);
        expect(out.first.single.posterUrl, 'signed:/thumb');
      },
    );

    test('works with no cache at all', () async {
      final out = await _run([
        LibrarySource(
          key: 'a',
          fetch: () async => _fetched([_plex('1', 'Heat')]),
        ),
      ], null);
      expect(_titles(out.single), ['Heat']);
    });
  });

  group('keeping the cache bounded', () {
    CachedSource at(DateTime when, [String title = 'X']) =>
        CachedSource(items: [_plex('1', title)], signature: 'a', at: when);
    final now = DateTime(2026, 10, 9);

    test(
      'prune drops entries older than the limit and keeps the rest',
      () async {
        final cache = MemoryLibraryCache();
        await cache.write('old', at(now.subtract(const Duration(days: 31))));
        await cache.write('new', at(now.subtract(const Duration(days: 2))));
        await cache.prune(libraryCacheMaxAge, now: now);
        expect(await cache.read('old'), isNull);
        expect(await cache.read('new'), isNotNull);
      },
    );

    test('deletePrefix removes one source and leaves the others', () async {
      final cache = MemoryLibraryCache();
      await cache.write('plex|s1|movies', at(now));
      await cache.write('plex|s1|series', at(now));
      await cache.write('plex|s2|movies', at(now));
      await cache.write('xtream|p1|vod', at(now));
      await cache.deletePrefix('plex|s1|');
      expect(await cache.read('plex|s1|movies'), isNull);
      expect(await cache.read('plex|s1|series'), isNull);
      expect(await cache.read('plex|s2|movies'), isNotNull);
      expect(await cache.read('xtream|p1|vod'), isNotNull);
    });

    test('signing out clears every Plex entry, and only those', () async {
      final cache = MemoryLibraryCache();
      await cache.write('plex|s1|movies', at(now));
      await cache.write('plex|s2|series', at(now));
      await cache.write('xtream|p1|vod', at(now));
      await cache.deletePrefix('plex|');
      expect(cache.map.keys, ['xtream|p1|vod']);
    });

    test(
      'a kept answer past the age limit is not used as a stand-in',
      () async {
        final cache = MemoryLibraryCache();
        await cache.write(
          'a',
          at(DateTime.now().subtract(const Duration(days: 45)), 'Stale'),
        );
        final out = await _run([
          LibrarySource(key: 'a', fetch: () async => throw Exception('down')),
        ], cache);
        // Neither shown first nor used after the failure.
        expect(out, [<CatalogItem>[]]);
      },
    );

    test('control: the same entry a day old is used', () async {
      final cache = MemoryLibraryCache();
      await cache.write(
        'a',
        at(DateTime.now().subtract(const Duration(days: 1)), 'Fresh'),
      );
      final out = await _run([
        LibrarySource(key: 'a', fetch: () async => throw Exception('down')),
      ], cache);
      expect(_titles(out.last), ['Fresh']);
    });
  });
}
