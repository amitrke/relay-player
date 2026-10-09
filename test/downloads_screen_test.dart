import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relay_player/core/theme/relay_theme.dart';
import 'package:relay_player/core/theme/relay_tokens.dart';
import 'package:relay_player/data/downloads/download_record.dart';
import 'package:relay_player/features/downloads/downloads_controller.dart';
import 'package:relay_player/features/downloads/downloads_screen.dart';
import 'package:relay_player/features/favorites_history/watch_actions.dart';

/// Records what the screen asks for, without touching a network or a disk.
class _Fake extends DownloadsController {
  _Fake(this.records);

  final List<DownloadRecord> records;
  final calls = <String>[];

  @override
  List<DownloadRecord> build() => records;

  @override
  Future<void> pause(String serverId, String ratingKey) async =>
      calls.add('pause $ratingKey');

  @override
  Future<void> resume(String serverId, String ratingKey) async =>
      calls.add('resume $ratingKey');

  @override
  Future<void> remove(String serverId, String ratingKey) async =>
      calls.add('remove $ratingKey');

  @override
  Future<void> enqueue({
    required String serverId,
    required String ratingKey,
    required String title,
    bool isEpisode = false,
  }) async => calls.add('enqueue $ratingKey $title');
}

DownloadRecord _rec(
  String key,
  DownloadState state, {
  String? title,
  int? total,
  int received = 0,
  String? error,
}) => DownloadRecord(
  serverId: 'srv',
  ratingKey: key,
  title: title ?? 'Film $key',
  addedAt: DateTime.utc(2026, 10, 9),
  state: state,
  totalBytes: total,
  receivedBytes: received,
  duration: const Duration(minutes: 95),
  error: error,
);

void main() {
  group('formatting', () {
    test('sizes read the way storage quotes them', () {
      expect(formatBytes(0), '0 B');
      expect(formatBytes(999), '999 B');
      expect(formatBytes(12000), '12 KB');
      expect(formatBytes(850 * 1000 * 1000), '850 MB');
      expect(formatBytes(1400 * 1000 * 1000), '1.4 GB');
      expect(formatBytes(12 * 1000 * 1000 * 1000 * 1000), '12.0 TB');
    });

    test('runtimes', () {
      expect(formatRuntime(Duration.zero), '');
      expect(formatRuntime(const Duration(minutes: 45)), '45 min');
      expect(formatRuntime(const Duration(minutes: 120)), '2 h');
      expect(formatRuntime(const Duration(minutes: 95)), '1 h 35 min');
    });
  });

  group('screen', () {
    late _Fake fake;

    Future<void> pump(WidgetTester tester, List<DownloadRecord> records) async {
      tester.view.physicalSize = const Size(390, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      fake = _Fake(records);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [downloadsProvider.overrideWith(() => fake)],
          child: MaterialApp(
            home: RelayTheme(
              tokens: RelayPalettes.midnight,
              palette: RelayPalette.midnight,
              child: const DownloadsScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('says how to get something here when there is nothing', (
      tester,
    ) async {
      await pump(tester, const []);
      expect(find.textContaining('Nothing downloaded yet'), findsOneWidget);
      expect(find.textContaining('with no network'), findsOneWidget);
    });

    testWidgets('shows each state in words, with size and progress', (
      tester,
    ) async {
      await pump(tester, [
        _rec('1', DownloadState.complete, total: 1400 * 1000 * 1000),
        _rec(
          '2',
          DownloadState.downloading,
          total: 1000 * 1000 * 1000,
          received: 430 * 1000 * 1000,
        ),
        _rec('3', DownloadState.queued),
        _rec(
          '4',
          DownloadState.paused,
          total: 1000 * 1000,
          received: 250 * 1000,
        ),
        _rec('5', DownloadState.failed, error: 'The server answered 500.'),
      ]);

      expect(find.text('1.4 GB · 1 h 35 min'), findsOneWidget);
      expect(
        find.text('Downloading 43% · 430 MB of 1.0 GB'),
        findsOneWidget,
      );
      expect(find.text('Waiting for its turn'), findsOneWidget);
      expect(find.text('Paused at 25% · select to resume'), findsOneWidget);
      expect(
        find.text('The server answered 500. Select to try again.'),
        findsOneWidget,
      );
      // And the limit is stated, since nothing runs once the app is closed.
      expect(find.textContaining('continue while the app is open'), findsOneWidget);
    });

    testWidgets('no warning about the app closing when everything is saved', (
      tester,
    ) async {
      await pump(tester, [_rec('1', DownloadState.complete, total: 5000)]);
      expect(find.textContaining('continue while the app is open'), findsNothing);
      expect(find.textContaining('1 item'), findsOneWidget);
    });

    testWidgets('selecting a row does what its state suggests', (tester) async {
      await pump(tester, [
        _rec('2', DownloadState.downloading, title: 'Going', total: 100),
        _rec('4', DownloadState.paused, title: 'Stopped', total: 100),
        _rec('5', DownloadState.failed, title: 'Broken'),
      ]);

      await tester.tap(find.text('Going'));
      await tester.tap(find.text('Stopped'));
      await tester.tap(find.text('Broken'));
      expect(fake.calls, ['pause 2', 'resume 4', 'resume 5']);
    });

    testWidgets('delete asks first, and the safe answer is the one in focus', (
      tester,
    ) async {
      await pump(tester, [
        _rec('1', DownloadState.complete, title: 'Keeper', total: 2000 * 1000),
      ]);

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      expect(find.text('Delete this download?'), findsOneWidget);
      expect(find.textContaining('stays on your Plex server'), findsOneWidget);
      expect(find.textContaining('freeing 2 MB'), findsOneWidget);

      // The safe button holds focus, so a stray select cannot delete.
      final keep = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'Keep it'),
      );
      expect(keep.autofocus, isTrue);

      await tester.tap(find.text('Keep it'));
      await tester.pumpAndSettle();
      expect(fake.calls, isEmpty);

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(fake.calls, ['remove 1']);
    });

    testWidgets('cancelling an unfinished one is worded as cancelling', (
      tester,
    ) async {
      await pump(tester, [
        _rec('2', DownloadState.paused, total: 100, received: 10),
      ]);
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      expect(find.text('Cancel this download?'), findsOneWidget);
    });
  });

  group('long-press sheet', () {
    late _Fake fake;

    Future<void> open(
      WidgetTester tester,
      List<DownloadRecord> records, {
      bool downloadable = true,
      bool isShow = false,
    }) async {
      tester.view.physicalSize = const Size(390, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      fake = _Fake(records);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [downloadsProvider.overrideWith(() => fake)],
          child: MaterialApp(
            // In `builder`, as the app installs it: a bottom sheet is built
            // under the Navigator, which a `home:` wrapper would not cover.
            builder: (context, child) => RelayTheme(
              tokens: RelayPalettes.midnight,
              palette: RelayPalette.midnight,
              child: child!,
            ),
            home: Consumer(
              builder: (context, ref, _) => Scaffold(
                body: TextButton(
                  onPressed: () => showWatchActions(
                    context,
                    ref,
                    WatchTarget(
                      serverId: 'srv',
                      ratingKey: '1',
                      title: 'Film 1',
                      downloadable: downloadable,
                      isShow: isShow,
                    ),
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('offers Download for something not yet saved, and queues it', (
      tester,
    ) async {
      await open(tester, const []);
      expect(find.text('Mark as watched'), findsOneWidget);
      expect(find.text('Download to this device'), findsOneWidget);

      await tester.tap(find.text('Download to this device'));
      await tester.pumpAndSettle();
      expect(fake.calls, ['enqueue 1 Film 1']);
      expect(find.textContaining('See the Downloads tab'), findsOneWidget);
    });

    testWidgets('offers Delete for a saved copy instead', (tester) async {
      await open(tester, [_rec('1', DownloadState.complete, total: 10)]);
      expect(find.text('Download to this device'), findsNothing);
      await tester.tap(find.text('Delete download'));
      await tester.pumpAndSettle();
      expect(fake.calls, ['remove 1']);
    });

    testWidgets('offers Cancel while it is still coming', (tester) async {
      await open(tester, [
        _rec('1', DownloadState.downloading, total: 10, received: 3),
      ]);
      expect(find.text('Cancel download'), findsOneWidget);
    });

    testWidgets('offers it again after a failure', (tester) async {
      await open(tester, [_rec('1', DownloadState.failed)]);
      expect(find.text('Download to this device'), findsOneWidget);
    });

    testWidgets('a show is never offered for download', (tester) async {
      await open(tester, const [], downloadable: false, isShow: true);
      expect(find.textContaining('Download'), findsNothing);
      expect(find.textContaining('Mark as watched'), findsOneWidget);
    });
  });
}
