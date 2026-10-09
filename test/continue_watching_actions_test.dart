import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:relay_player/core/theme/relay_theme.dart';
import 'package:relay_player/core/theme/relay_tokens.dart';
import 'package:relay_player/data/downloads/download_record.dart';
import 'package:relay_player/data/local/history_store.dart';
import 'package:relay_player/features/downloads/downloads_controller.dart';
import 'package:relay_player/features/favorites_history/continue_watching_row.dart';
import 'package:relay_player/features/favorites_history/resume_entries.dart';

/// Records what the sheet asks for, without a network or a disk.
class _Fake extends DownloadsController {
  _Fake(this.records);

  final List<DownloadRecord> records;
  final calls = <String>[];

  @override
  List<DownloadRecord> build() => records;

  @override
  Future<void> enqueue({
    required String serverId,
    required String ratingKey,
    required String title,
    bool isEpisode = false,
  }) async =>
      calls.add('enqueue $serverId/$ratingKey $title episode=$isEpisode');

  @override
  Future<void> remove(String serverId, String ratingKey) async =>
      calls.add('remove $serverId/$ratingKey');
}

ResumeEntry _entry(
  PlaybackKind kind, {
  String title = 'Half Watched',
  bool episode = false,
}) => ResumeEntry(
  kind: kind,
  sourceId: 'srv',
  itemId: '42',
  title: title,
  detail: '24 min left',
  lastActivity: DateTime.utc(2026, 10, 9),
  progress: 0.5,
  episode: episode,
);

/// A title that is part-way through has to be downloadable from where it is
/// found, which is the Continue watching row. Until 2026-10-09 these tiles took
/// a tap and nothing else.
void main() {
  late _Fake fake;

  Future<void> pump(
    WidgetTester tester,
    List<ResumeEntry> entries, {
    List<DownloadRecord> downloads = const [],
    bool episodes = false,
  }) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    fake = _Fake(downloads);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          resumeEntriesProvider.overrideWithValue(entries),
          downloadsProvider.overrideWith(() => fake),
        ],
        child: MaterialApp.router(
          // In `builder`, as the app installs it: the sheet is built under the
          // Navigator, which a `home:` wrapper would not cover.
          builder: (context, child) => RelayTheme(
            tokens: RelayPalettes.midnight,
            palette: RelayPalette.midnight,
            child: child!,
          ),
          routerConfig: GoRouter(
            routes: [
              GoRoute(
                path: '/',
                builder: (_, _) =>
                    Scaffold(body: ContinueWatchingRow(episodes: episodes)),
              ),
              GoRoute(
                path: '/vod/:a/:b',
                builder: (_, _) => const Scaffold(body: Text('PLAYER')),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('holding an in-progress Plex title offers to download it', (
    tester,
  ) async {
    await pump(tester, [_entry(PlaybackKind.plex)]);

    await tester.longPress(find.text('Half Watched'));
    await tester.pumpAndSettle();

    expect(find.text('Download to this device'), findsOneWidget);
    // And the watched marks that were already there for a poster in the grid.
    expect(find.text('Mark as watched'), findsOneWidget);
    expect(find.text('Mark as unwatched'), findsOneWidget);

    await tester.tap(find.text('Download to this device'));
    await tester.pumpAndSettle();
    expect(fake.calls, ['enqueue srv/42 Half Watched episode=false']);
  });

  testWidgets('an episode is downloaded as an episode', (tester) async {
    await pump(tester, [
      _entry(PlaybackKind.plex, title: 'Show S1 E2', episode: true),
    ], episodes: true);

    await tester.longPress(find.text('Show S1 E2'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Download to this device'));
    await tester.pumpAndSettle();

    expect(fake.calls, ['enqueue srv/42 Show S1 E2 episode=true']);
  });

  testWidgets('one already saved offers to delete it instead', (tester) async {
    await pump(
      tester,
      [_entry(PlaybackKind.plex)],
      downloads: [
        DownloadRecord(
          serverId: 'srv',
          ratingKey: '42',
          title: 'Half Watched',
          addedAt: DateTime.utc(2026, 10, 9),
          state: DownloadState.complete,
          totalBytes: 100,
          receivedBytes: 100,
        ),
      ],
    );

    await tester.longPress(find.text('Half Watched'));
    await tester.pumpAndSettle();

    expect(find.text('Download to this device'), findsNothing);
    await tester.tap(find.text('Delete download'));
    await tester.pumpAndSettle();
    expect(fake.calls, ['remove srv/42']);
  });

  testWidgets('a panel title gets no sheet: nothing to mark or download', (
    tester,
  ) async {
    await pump(tester, [_entry(PlaybackKind.xtreamVod, title: 'Panel Film')]);

    await tester.longPress(find.text('Panel Film'));
    await tester.pumpAndSettle();

    expect(find.text('Download to this device'), findsNothing);
    expect(find.textContaining('Mark as'), findsNothing);
    expect(fake.calls, isEmpty);
    // Holding it just opens it, as it always did.
    expect(find.text('PLAYER'), findsOneWidget);
  });
}
