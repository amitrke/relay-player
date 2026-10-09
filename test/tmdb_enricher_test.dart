import 'package:flutter_test/flutter_test.dart';
import 'package:relay_player/data/tmdb/title_match.dart';
import 'package:relay_player/data/tmdb/tmdb_cache.dart';
import 'package:relay_player/data/tmdb/tmdb_client.dart';
import 'package:relay_player/data/tmdb/tmdb_enricher.dart';
import 'package:relay_player/domain/models/catalog_item.dart';

class _FakeApi implements TmdbApi {
  int searches = 0;
  int detailCalls = 0;
  bool fail = false;

  @override
  Future<List<TmdbCandidate>> search(String title,
      {required bool tv, int? year}) async {
    searches++;
    if (fail) throw const TmdbException('down');
    if (title == 'Parasite') {
      return const [
        TmdbCandidate(
            id: 7, title: 'Parasite', originalTitle: 'Gisaengchung', year: 2019),
      ];
    }
    return const [];
  }

  @override
  Future<TmdbInfo> details(int id, {required bool tv}) async {
    detailCalls++;
    return TmdbInfo(
      id: id,
      isTv: tv,
      genres: const ['Thriller', 'Drama'],
      originalLanguage: 'ko',
      rating: 8.5,
    );
  }

  @override
  Future<List<TmdbCandidate>> recommendations(int id,
          {required bool tv}) async =>
      const [];
}

CatalogItem _item(String title, {int? year}) => CatalogItem(
      source: CatalogSource.xtream,
      sourceId: 'p',
      kind: CatalogKind.movie,
      id: title,
      title: title,
      year: year,
    );

void main() {
  test('finds a title through a messy panel name and fills the metadata',
      () async {
    final api = _FakeApi();
    final e = TmdbEnricher(api, MemoryTmdbCache());
    final out = await e.enrich([_item('EN - Parasite (2019) 4K')]);
    expect(out.single.genres, ['Thriller', 'Drama']);
    expect(out.single.originalLanguage, 'Korean');
    expect(out.single.rating, 8.5);
  });

  test('a second lookup of the same title is served from the cache', () async {
    final api = _FakeApi();
    final e = TmdbEnricher(api, MemoryTmdbCache());
    await e.enrich([_item('Parasite', year: 2019)]);
    await e.enrich([_item('Parasite', year: 2019)]);
    expect(api.searches, 1);
    expect(api.detailCalls, 1);
  });

  test('a miss is remembered, then retried once it is old enough', () async {
    var clock = DateTime(2026, 1, 1);
    final api = _FakeApi();
    final e = TmdbEnricher(api, MemoryTmdbCache(), now: () => clock);

    await e.enrich([_item('Nothing Like It', year: 2000)]);
    await e.enrich([_item('Nothing Like It', year: 2000)]);
    expect(api.searches, 1);

    clock = clock.add(tmdbMissLifetime + const Duration(days: 1));
    await e.enrich([_item('Nothing Like It', year: 2000)]);
    expect(api.searches, 2);
  });

  test('a failed request is not cached as a miss', () async {
    final api = _FakeApi()..fail = true;
    final e = TmdbEnricher(api, MemoryTmdbCache());
    final out = await e.enrich([_item('Parasite', year: 2019)]);
    expect(out.single.genres, isEmpty);

    api.fail = false;
    final again = await e.enrich([_item('Parasite', year: 2019)]);
    expect(again.single.genres, isNotEmpty);
  });

  test('items past the limit come back untouched, in order', () async {
    final api = _FakeApi();
    final e = TmdbEnricher(api, MemoryTmdbCache());
    final items = [
      _item('Parasite', year: 2019),
      _item('Other One', year: 2001),
      _item('Parasite', year: 2019),
    ];
    final out = await e.enrich(items, limit: 1);
    expect(out.map((i) => i.id), items.map((i) => i.id));
    expect(out[0].genres, isNotEmpty);
    expect(out[2].genres, isEmpty);
  });
}
