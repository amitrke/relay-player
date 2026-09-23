import 'package:dart_plex/dart_plex.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relay_player/data/local/history_store.dart';
import 'package:relay_player/features/favorites_history/resume_entries.dart';
import 'package:relay_player/features/favorites_history/watch_state.dart';

/// Plex watch state combined with this device's history.
///
/// Pins the rules, not Plex: that a real server's On Deck and view counts look
/// like these fixtures is a check against a real account (MANUAL_TESTING.md).
HistoryItem _local(String id, {required int positionMin, required DateTime at}) =>
    HistoryItem(
      kind: PlaybackKind.plex,
      sourceId: 'server',
      itemId: id,
      title: 'local $id',
      position: Duration(minutes: positionMin),
      duration: const Duration(minutes: 100),
      lastWatchedAt: at,
    );

PlexMetadata _deck(
  String id, {
  PlexMetadataType type = PlexMetadataType.movie,
  int? offsetMin,
  DateTime? viewed,
}) =>
    PlexMetadata.fromJson({
      'ratingKey': id,
      'key': '/library/metadata/$id',
      'type': type.name,
      'title': 'plex $id',
      'grandparentTitle': 'The Show',
      'parentIndex': 2,
      'index': 3,
      'duration': 100 * 60000,
      'viewOffset': ?(offsetMin == null ? null : offsetMin * 60000),
      'lastViewedAt': ?(viewed == null
          ? null
          : viewed.millisecondsSinceEpoch ~/ 1000),
    });

ResumeEntry _entry(PlexMetadata m) => ResumeEntry.fromPlex('server', m)!;

void main() {
  final earlier = DateTime.utc(2026, 9, 1);
  final later = DateTime.utc(2026, 9, 2);

  group('WatchState', () {
    test('Plex says watched and nothing local', () {
      final w = WatchState.resolve(plexViewCount: 1);
      expect(w.watched, isTrue);
      expect(w.inProgress, isFalse);
    });

    test('a Plex offset on a watched title is a rewatch, shown as progress',
        () {
      final w = WatchState.resolve(
        plexViewCount: 2,
        plexOffset: const Duration(minutes: 30),
        plexDuration: const Duration(minutes: 100),
      );
      expect(w.watched, isFalse);
      expect(w.progress, closeTo(0.3, 0.001));
    });

    test('finishing here beats an older Plex offset', () {
      final w = WatchState.resolve(
        local: _local('1', positionMin: 98, at: later),
        plexOffset: const Duration(minutes: 30),
        plexDuration: const Duration(minutes: 100),
        plexLastViewedAt: earlier,
      );
      expect(w.watched, isTrue);
    });

    test('a newer Plex state beats older local history', () {
      final w = WatchState.resolve(
        local: _local('1', positionMin: 20, at: earlier),
        plexViewCount: 1,
        plexLastViewedAt: later,
      );
      expect(w.watched, isTrue);
    });

    test('a glance here does not undo a watch elsewhere', () {
      final w = WatchState.resolve(
        local: HistoryItem(
          kind: PlaybackKind.plex,
          sourceId: 'server',
          itemId: '1',
          title: 't',
          position: const Duration(seconds: 20),
          duration: const Duration(minutes: 100),
          lastWatchedAt: later,
        ),
        plexViewCount: 1,
        plexLastViewedAt: earlier,
      );
      expect(w.watched, isTrue);
    });
  });

  group('mergeResume', () {
    test('Plex adds what was watched elsewhere, and next-up episodes', () {
      final merged = mergeResume(history: const [], plexDeck: [
        _entry(_deck('a', offsetMin: 40, viewed: later)),
        _entry(_deck('b', type: PlexMetadataType.episode)),
      ]);
      expect(merged.map((e) => e.itemId), ['a', 'b']);
      expect(merged[0].detail, '60 min left');
      expect(merged[1].title, 'The Show');
      expect(merged[1].detail, 'S2 E3 · Up next');
      expect(merged[1].progress, isNull);
    });

    test('the newer of local and Plex wins for the same title', () {
      final merged = mergeResume(
        history: [_local('a', positionMin: 10, at: earlier)],
        plexDeck: [_entry(_deck('a', offsetMin: 50, viewed: later))],
      );
      expect(merged, hasLength(1));
      expect(merged.single.progress, closeTo(0.5, 0.001));
    });

    test('finishing here hides Plex\'s older half-watched entry', () {
      final merged = mergeResume(
        history: [_local('a', positionMin: 99, at: later)],
        plexDeck: [_entry(_deck('a', offsetMin: 50, viewed: earlier))],
      );
      expect(merged, isEmpty);
    });

    test('a dismissed Plex entry stays hidden until its state changes', () {
      final entry = _entry(_deck('a', offsetMin: 50, viewed: earlier));
      final dismissed = {entry.key: entry.signature};
      expect(
          mergeResume(history: const [], plexDeck: [entry], dismissed: dismissed),
          isEmpty);

      final watchedMore = _entry(_deck('a', offsetMin: 70, viewed: later));
      expect(
          mergeResume(
              history: const [], plexDeck: [watchedMore], dismissed: dismissed),
          hasLength(1));
    });

    test('newest first, undated next-up entries last in Plex order', () {
      final merged = mergeResume(
        history: [_local('local', positionMin: 10, at: earlier)],
        plexDeck: [
          _entry(_deck('next1', type: PlexMetadataType.episode)),
          _entry(_deck('recent', offsetMin: 10, viewed: later)),
          _entry(_deck('next2', type: PlexMetadataType.episode)),
        ],
      );
      expect(merged.map((e) => e.itemId), ['recent', 'local', 'next1', 'next2']);
    });
  });
}
