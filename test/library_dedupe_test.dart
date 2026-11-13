import 'package:flutter_test/flutter_test.dart';
import 'package:relay_player/domain/models/catalog_item.dart';
import 'package:relay_player/features/library/library_dedupe.dart';

CatalogItem _item(
  String sourceId,
  String title, {
  int? year = 2026,
  CatalogSource source = CatalogSource.server,
  CatalogKind kind = CatalogKind.movie,
}) => CatalogItem(
  source: source,
  sourceId: sourceId,
  kind: kind,
  id: '$sourceId-$title',
  title: title,
  year: year,
);

/// The same title on two servers showed twice in Movies (2026-10-10).
void main() {
  group('dedupeLibrary', () {
    test('keeps the copy on the LAN server, in the first copy\'s place', () {
      final out = dedupeLibrary([
        _item('remote', 'Film A'),
        _item('remote', 'Film B'),
        _item('lan', 'Film A'),
      ], localPlexServers: {'lan'});
      expect(out.map((i) => '${i.sourceId} ${i.title}'), [
        'lan Film A',
        'remote Film B',
      ]);
    });

    test('between two non-local servers the first stays', () {
      final out = dedupeLibrary([
        _item('one', 'Film A'),
        _item('two', 'Film A'),
      ], localPlexServers: {});
      expect(out.single.sourceId, 'one');
    });

    test('a Plex copy wins over a panel copy, wherever it comes', () {
      final out = dedupeLibrary([
        _item('panel', 'Film A', source: CatalogSource.xtream),
        _item('remote', 'Film A'),
      ], localPlexServers: {});
      expect(out.single.source, CatalogSource.server);
    });

    test('a different year is a different film (remakes)', () {
      final out = dedupeLibrary([
        _item('a', 'Dune', year: 1984),
        _item('b', 'Dune', year: 2021),
      ], localPlexServers: {});
      expect(out, hasLength(2));
    });

    test('no year, no merge: two tiles beat a wrong one hiding the other', () {
      final out = dedupeLibrary([
        _item('a', 'Film A', year: null),
        _item('b', 'Film A', year: null),
      ], localPlexServers: {'b'});
      expect(out, hasLength(2));
    });

    test('a film and a series of the same name both stay', () {
      final out = dedupeLibrary([
        _item('a', 'Fargo', year: 2014),
        _item('b', 'Fargo', year: 2014, kind: CatalogKind.show),
      ], localPlexServers: {});
      expect(out, hasLength(2));
    });

    test('titles that differ only in case and punctuation match', () {
      final out = dedupeLibrary([
        _item('remote', 'Spider-Man: No Way Home'),
        _item('lan', 'spider man no way home'),
      ], localPlexServers: {'lan'});
      expect(out.single.sourceId, 'lan');
    });
  });

  // Reported 2026-11-12: the copy not kept vanished, and nothing said which
  // server the kept one was on. Now the kept copy lists the others.
  group('copies folded into a kept title', () {
    test('the kept copy lists every other copy, and only merged titles '
        'carry any', () {
      final out = dedupeLibrary(
        [
          _item('remote', 'Film A'),
          _item('remote', 'Film B'),
          _item('lan', 'Film A'),
          _item('panel', 'Film A', source: CatalogSource.xtream),
        ],
        localPlexServers: {'lan'},
      );
      final a = out.first;
      expect(a.sourceId, 'lan');
      expect(a.alsoOn.map((c) => '${c.source.wire} ${c.sourceId} ${c.id}'), [
        'plex remote remote-Film A',
        'xtream panel panel-Film A',
      ]);
      expect(out.last.alsoOn, isEmpty);
    });

    test('copies survive a later metadata rebuild', () {
      final kept = dedupeLibrary([
        _item('one', 'Film A'),
        _item('two', 'Film A'),
      ], localPlexServers: {}).single;
      final enriched = kept.withMetadata(genres: const ['Drama']);
      expect(enriched.alsoOn.single.sourceId, 'two');
      expect(enriched.withPosterUrl(null).alsoOn, hasLength(1));
    });
  });

  group('CatalogCopy in a route', () {
    test(
      'round-trips, including ids with the separator and slashes in them',
      () {
        const copies = [
          CatalogCopy(
            source: CatalogSource.server,
            sourceId: 'abc,def~ghi',
            id: '12/34',
            kind: CatalogKind.movie,
          ),
          CatalogCopy(
            source: CatalogSource.xtream,
            sourceId: 'acct 1',
            id: '99',
            kind: CatalogKind.movie,
          ),
        ];
        final route = CatalogCopy.withCopies('/film/srv/1', copies);
        final uri = Uri.parse(route);
        expect(uri.path, '/film/srv/1');
        final back = CatalogCopy.fromQuery(uri, CatalogKind.movie);
        expect(back, hasLength(2));
        expect(back[0].sameAs(copies[0]), isTrue);
        expect(back[1].sameAs(copies[1]), isTrue);
        expect(back[1].route, '/vod/acct 1/99');
      },
    );

    test('no copies leaves the route bare, and junk is skipped', () {
      expect(CatalogCopy.withCopies('/film/srv/1', const []), '/film/srv/1');
      final uri = Uri.parse('/film/srv/1?also=nonsense&also=bogus,x,y');
      expect(CatalogCopy.fromQuery(uri, CatalogKind.movie), isEmpty);
    });

    test('a tile opens its page with its copies; route stays bare', () {
      final kept = dedupeLibrary([
        _item('one', 'Film A'),
        _item('two', 'Film A'),
      ], localPlexServers: {}).single;
      expect(kept.route, '/film/one/one-Film A');
      final uri = Uri.parse(kept.routeWithCopies);
      expect(Uri.decodeFull(uri.path), '/film/one/one-Film A');
      expect(
        CatalogCopy.fromQuery(uri, CatalogKind.movie).single.sourceId,
        'two',
      );
    });
  });

  group('plexUrlIsLocal', () {
    test('a private address is local', () {
      expect(plexUrlIsLocal('http://192.168.1.5:32400'), isTrue);
      expect(plexUrlIsLocal('http://10.0.0.2:32400'), isTrue);
    });

    test('a plex.direct name spelling a private address is local', () {
      expect(
        plexUrlIsLocal('https://192-168-1-5.0123abcd.plex.direct:32400'),
        isTrue,
      );
    });

    test('a plex.direct name spelling a public address is not', () {
      expect(
        plexUrlIsLocal('https://203-0-113-9.0123abcd.plex.direct:8443'),
        isFalse,
      );
    });

    test('a public host is not', () {
      expect(plexUrlIsLocal('https://example.com:32400'), isFalse);
      expect(plexUrlIsLocal('not a url'), isFalse);
    });
  });
}
