import 'package:flutter_test/flutter_test.dart';
import 'package:relay_player/data/local/history_store.dart';

/// Guards the Hive box against credential material (§3).
///
/// Written after the §15 inspection in STORE_LISTING.md was run for the first
/// time, on 2026-09-22, and failed: `settings.hive` held nine continue-watching
/// entries whose `poster` was Plex's *signed* image transcode URL, so a live
/// `X-Plex-Token` sat in plaintext on disk once per row. The architecture was
/// already right everywhere else — favourites store ids, and neither
/// `XtreamAccount` nor `SmbShare` has a password field to serialize — which is
/// exactly why one convenience field went unnoticed.
///
/// The listing claims "your credentials stay in encrypted storage", so this is
/// a store-copy guarantee and not only a code preference.
void main() {
  HistoryItem itemWith(String? poster) => HistoryItem(
        kind: PlaybackKind.plex,
        sourceId: 'server-1',
        itemId: '1234',
        title: 'Big Buck Bunny',
        poster: poster,
        position: const Duration(minutes: 3),
        duration: const Duration(minutes: 10),
        lastWatchedAt: DateTime.fromMillisecondsSinceEpoch(0),
      );

  const signed =
      'http://192.0.2.10:32400/photo/:/transcode?width=320&height=480'
      '&url=%2Flibrary%2Fmetadata%2F1234%2Fthumb%2F1&X-Plex-Token=abc123def456ghi789jk';

  group('a signed Plex URL never reaches the box', () {
    test('toJson drops it on write', () {
      expect(itemWith(signed).toJson()['poster'], isNull);
    });

    test('fromJson drops it on read, cleaning boxes the old code wrote', () {
      final raw = itemWith(null).toJson()..['poster'] = signed;
      expect(HistoryItem.fromJson(raw)!.poster, isNull);
    });

    test('the token never survives serialisation in any form', () {
      final encoded = itemWith(signed).toJson().toString().toLowerCase();
      expect(encoded.contains('x-plex-token'), isFalse);
      expect(encoded.contains('abc123def456ghi789jk'), isFalse);
    });
  });

  // Controls. Without these the tests above would pass just as happily if
  // `poster` were hardcoded to null, which would silently remove every
  // continue-watching thumbnail rather than fix anything.
  group('legitimate artwork references still survive', () {
    test('an unsigned Plex path round-trips', () {
      const path = '/library/metadata/1234/thumb/1';
      expect(itemWith(path).toJson()['poster'], path);
      expect(HistoryItem.fromJson(itemWith(path).toJson())!.poster, path);
    });

    test('a panel image URL carrying no credential round-trips', () {
      const url = 'http://example.invalid/images/cover.jpg';
      expect(HistoryItem.fromJson(itemWith(url).toJson())!.poster, url);
    });
  });
}
