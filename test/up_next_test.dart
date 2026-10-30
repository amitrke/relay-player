import 'package:flutter_test/flutter_test.dart';
import 'package:relay_player/domain/models/media_server.dart';
import 'package:relay_player/features/player/up_next.dart';

/// Which episode Up next offers (architecture.md §12.5). The order is worked
/// out here rather than trusted from the server, because Plex sends specials
/// first and Jellyfin's order follows its display settings.
MediaItem _ep(String id, int? season, int? number) => MediaItem(
      id: id,
      type: MediaItemType.episode,
      title: id,
      parentIndex: season,
      index: number,
      showId: 'show',
    );

void main() {
  final s0e1 = _ep('s0e1', 0, 1);
  final s1e1 = _ep('s1e1', 1, 1);
  final s1e2 = _ep('s1e2', 1, 2);
  final s2e1 = _ep('s2e1', 2, 1);

  test('the next episode in the same season', () {
    expect(episodeAfter(s1e1, [s1e1, s1e2, s2e1])?.id, 's1e2');
  });

  test('the next season starts after a finale, whatever order the server '
      'sent', () {
    expect(episodeAfter(s1e2, [s2e1, s0e1, s1e2, s1e1])?.id, 's2e1');
  });

  test('nothing after the last episode', () {
    expect(episodeAfter(s2e1, [s1e1, s1e2, s2e1]), isNull);
  });

  test('specials are never offered, and get no card themselves', () {
    // Plex's allLeaves order: specials first.
    expect(episodeAfter(s1e2, [s0e1, s1e1, s1e2]), isNull);
    expect(episodeAfter(s0e1, [s0e1, s1e1, s1e2]), isNull);
  });

  test('without numbers, the server order is kept', () {
    final a = _ep('a', null, null);
    final b = _ep('b', null, null);
    expect(episodeAfter(a, [a, b])?.id, 'b');
  });

  test('an episode the list does not contain gets nothing', () {
    expect(episodeAfter(s1e1, [s1e2, s2e1]), isNull);
  });

  test('the card label', () {
    expect(upNextLabel(s2e1), 'S2 E1 · s2e1');
    expect(upNextLabel(_ep('x', null, null)), 'x');
  });
}
