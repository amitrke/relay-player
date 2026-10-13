import 'package:flutter_test/flutter_test.dart';
import 'package:relay_player/domain/models/catalog_item.dart';
import 'package:relay_player/features/library/library_dedupe.dart';

CatalogItem _item(
  String sourceId,
  String title, {
  int? year = 2026,
  CatalogSource source = CatalogSource.plex,
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
      expect(out.single.source, CatalogSource.plex);
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
