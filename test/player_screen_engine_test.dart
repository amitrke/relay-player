import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:relay_player/core/theme/relay_theme.dart';
import 'package:relay_player/core/theme/relay_tokens.dart';
import 'package:relay_player/data/downloads/download_record.dart';
import 'package:relay_player/data/filesystem/device_video_source.dart';
import 'package:relay_player/data/local/history_store.dart';
import 'package:relay_player/data/plex/plex_service.dart';
import 'package:relay_player/domain/models/media_server.dart';
import 'package:relay_player/features/accounts/media_servers.dart';
import 'package:relay_player/features/downloads/downloads_controller.dart';
import 'package:relay_player/features/favorites_history/resume_entries.dart';
import 'package:relay_player/features/favorites_history/history_controller.dart';
import 'package:relay_player/features/local_network/local_network_tab.dart';
import 'package:relay_player/features/player/engine/playback_engine.dart';
import 'package:relay_player/features/player/playback_prefs.dart';
import 'package:relay_player/features/player/player_screen.dart';
import 'package:relay_player/features/trackers/trackers_controller.dart';

/// The player screen driven through the engine seam (architecture.md §10.2)
/// by a fake engine, which was impossible while the screen built media_kit's
/// `Player` itself. What this pins is the screen's side of the contract: stop
/// before open, "playing" only once the position moves, a stated failure when
/// it never does, and non-fatal engine errors left alone.
class _FakeEngine implements PlaybackEngine {
  _FakeEngine(this.output);

  final EngineOutput output;
  final calls = <String>[];
  final _position = StreamController<Duration>.broadcast();
  final _errors = StreamController<EngineError>.broadcast();
  final _completed = StreamController<void>.broadcast();

  /// Plays the file to its end, as media_kit's `completed` does: the clock
  /// stops at the duration and playback is no longer running.
  void complete() {
    playing = false;
    emitPosition(duration);
    _completed.add(null);
  }

  void emitPosition(Duration d) {
    position = d;
    _position.add(d);
  }

  void emitError(EngineError e) => _errors.add(e);

  @override
  String get name => 'fake';
  @override
  bool get hasCompatibleFallback => false;
  @override
  Stream<EngineError> get errorStream => _errors.stream;
  @override
  // Nothing: by the time the player listens, the duration is already known
  // (see [duration]), which is the case that once left a resume waiting for
  // ever on a stream that does not replay.
  Stream<Duration> get durationStream => const Stream.empty();
  @override
  Stream<void> get completedStream => _completed.stream;
  @override
  Future<void> open(String url) async => calls.add('open $url');
  @override
  Future<void> stop() async => calls.add('stop');
  @override
  Future<void> dispose() async => calls.add('dispose');
  @override
  Widget buildView({required double subtitleScale}) =>
      const SizedBox.expand();
  @override
  Future<String?> checkOutputAfterStart() async => null;

  @override
  Stream<Duration> get positionStream => _position.stream;
  @override
  Duration position = Duration.zero;
  @override
  Duration duration = Duration.zero;
  @override
  Stream<bool> get playingStream => const Stream.empty();
  @override
  bool playing = true;
  @override
  Future<void> seek(Duration to) async => calls.add('seek $to');
  @override
  Future<void> play() async {}
  @override
  Future<void> pause() async {}
  @override
  Future<void> playOrPause() async {}
  @override
  Future<void> setVolume(double percent) async {}
  @override
  Stream<TrackList> get tracksStream => const Stream.empty();
  @override
  TrackList get tracks => const TrackList();
  @override
  Stream<TrackSelection> get selectionStream => const Stream.empty();
  @override
  TrackSelection get selection => const TrackSelection();
  @override
  Future<void> setAudioTrack(MediaTrack track) async {}
  @override
  Future<void> setSubtitleTrack(MediaTrack? track) async {}
}

class _Source extends DeviceVideoSource {
  const _Source();
  @override
  Future<String?> filePathOf(String assetId) async => '/videos/$assetId.mkv';
  @override
  Future<DeviceVideo?> videoById(String assetId) async =>
      DeviceVideo(id: assetId, title: 'Holiday', duration: Duration.zero);
}

class _Prefs extends PlaybackPrefsController {
  @override
  PlaybackPrefs build() => const PlaybackPrefs();
}

class _NoHistory extends HistoryController {
  @override
  List<HistoryItem> build() => const [];
  @override
  Future<void> record(HistoryItem item) async {}
}

/// A server with one show of two seasons and one film. Plex is the kind, but
/// nothing here is Plex-specific: the screen asks only the [MediaServer]
/// interface, which is the point (§6.2).
class _Server extends PlexService {
  _Server() : super(clientId: 'test', serverId: 'server');

  final reports = <String>[];
  final lookups = <String>[];

  /// Where the server says the viewer got to, as Plex's `viewOffset` does.
  Duration? resumeFrom;

  static MediaItem _ep(String id, int season, int number) => MediaItem(
        id: id,
        type: MediaItemType.episode,
        title: 'Episode $id',
        index: number,
        parentIndex: season,
        showId: 'show',
        showTitle: 'The Show',
        duration: const Duration(minutes: 1),
      );

  static final episodes = [
    _ep('e11', 1, 1),
    _ep('e12', 1, 2),
    _ep('e21', 2, 1),
  ];

  static const film = MediaItem(
    id: 'film',
    type: MediaItemType.movie,
    title: 'A Film',
    // Set so that only the screen's own film rule keeps the card away.
    showId: 'show',
  );

  @override
  Future<MediaPlayable> directPlay(String id) async {
    final item =
        id == 'film' ? film : episodes.firstWhere((e) => e.id == id);
    return MediaPlayable(
      url: 'http://server/$id',
      title: item.title,
      duration: const Duration(minutes: 1),
      isEpisode: item.type == MediaItemType.episode,
      item: item,
      resumeFrom: resumeFrom,
    );
  }

  @override
  Future<List<MediaItem>> episodesOf(String showId) async {
    lookups.add(showId);
    return episodes;
  }

  @override
  Future<void> reportProgress({
    required String id,
    required String state,
    required Duration position,
    required Duration duration,
  }) async =>
      reports.add('$id $state');
}

class _NoDownloads extends DownloadsController {
  @override
  List<DownloadRecord> build() => const [];
}

class _NoTrackers extends TrackersController {
  @override
  TrackersState build() => const TrackersState();
  @override
  Future<void> finished(String serverId, String itemId, {DateTime? at}) async {}
}

void main() {
  late List<_FakeEngine> engines;

  Future<void> pump(WidgetTester tester) async {
    engines = [];
    final router = GoRouter(
      initialLocation: '/play/a1',
      routes: [
        GoRoute(
          path: '/play/:id',
          builder: (_, s) =>
              PlayerScreen.device(assetId: s.pathParameters['id']!),
        ),
      ],
    );
    await tester.pumpWidget(ProviderScope(
      overrides: [
        deviceVideoSourceProvider.overrideWithValue(const _Source()),
        playbackPrefsProvider.overrideWith(_Prefs.new),
        historyProvider.overrideWith(_NoHistory.new),
        playbackEngineFactoryProvider.overrideWithValue((output) {
          final e = _FakeEngine(output);
          engines.add(e);
          return e;
        }),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        builder: (context, child) => RelayTheme(
          tokens: RelayPalettes.midnight,
          palette: RelayPalette.midnight,
          child: child!,
        ),
      ),
    ));
    await tester.pump();
    await tester.pump();
  }

  testWidgets('stops before it opens, and opens what the source resolved',
      (tester) async {
    await pump(tester);
    expect(engines, hasLength(1));
    expect(engines.single.output, EngineOutput.fast);
    expect(engines.single.calls, ['stop', 'open /videos/a1.mkv']);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 20));
  });

  testWidgets('only a moving position counts as playing', (tester) async {
    await pump(tester);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    engines.single.emitPosition(Duration.zero);
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget,
        reason: 'a zero position is not playback');

    engines.single.emitPosition(const Duration(milliseconds: 400));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 20));
  });

  testWidgets('a file that never moves fails with a stated reason',
      (tester) async {
    await pump(tester);
    await tester.pump(const Duration(seconds: 16));
    expect(find.textContaining('did not start playing'), findsOneWidget);
    expect(engines.single.calls.last, 'stop',
        reason: 'the connection is released, not held');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a non-fatal engine error leaves playback alone, a fatal one '
      'does not', (tester) async {
    await pump(tester);
    engines.single.emitPosition(const Duration(seconds: 1));
    await tester.pump();

    engines.single.emitError(
        const EngineError('continuing without audio', fatal: false));
    await tester.pump();
    await tester.pump();
    expect(find.text('continuing without audio'), findsNothing);

    engines.single.emitError(const EngineError('demuxer died', fatal: true));
    // One pump delivers the event and schedules the rebuild; the next draws.
    await tester.pump();
    await tester.pump();
    expect(find.text('demuxer died'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 20));
  });

  /// Up next (architecture.md §12.5). Each of these was run against the
  /// screen with the feature taken out (the end ignored, the film guard
  /// removed, Play now given focus, Back left to leave) and failed, so
  /// passing means something.
  group('when an episode ends', () {
    late _Server server;

    Future<void> pumpServer(
      WidgetTester tester,
      String id, {
      Duration? resumeFrom,
      String query = '',
    }) async {
      engines = [];
      server = _Server()..resumeFrom = resumeFrom;
      // The player is pushed over another page, as it always is in the app.
      // That matters: go_router gives a replacement a fresh page (and so a
      // fresh player) only when the page it replaces was itself pushed.
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (_, _) => const Text('home')),
          GoRoute(
            path: '/play/:serverId/:ratingKey',
            builder: (_, s) => PlayerScreen.plex(
              serverId: s.pathParameters['serverId']!,
              ratingKey: s.pathParameters['ratingKey']!,
              fromStart: s.uri.queryParameters['start'] == '0',
            ),
          ),
        ],
      );
      await tester.pumpWidget(ProviderScope(
        overrides: [
          connectedServersProvider
              .overrideWithValue([ConnectedServer(service: server)]),
          downloadsProvider.overrideWith(_NoDownloads.new),
          trackersProvider.overrideWith(_NoTrackers.new),
          onDeckProvider.overrideWith((_) async => const []),
          playbackPrefsProvider.overrideWith(_Prefs.new),
          historyProvider.overrideWith(_NoHistory.new),
          playbackEngineFactoryProvider.overrideWithValue((output) {
            final e = _FakeEngine(output)
              ..duration = const Duration(minutes: 1);
            engines.add(e);
            return e;
          }),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          builder: (context, child) => RelayTheme(
            tokens: RelayPalettes.midnight,
            palette: RelayPalette.midnight,
            child: child!,
          ),
        ),
      ));
      unawaited(router.push('/play/server/$id$query'));
      for (var i = 0; i < 4; i++) {
        await tester.pump();
      }
      // Past the page transition. Not pumpAndSettle: the spinner never settles.
      await tester.pump(const Duration(milliseconds: 500));
    }

    /// Starts playback and plays it to the end.
    Future<void> playToEnd(WidgetTester tester) async {
      engines.last.emitPosition(const Duration(seconds: 1));
      await tester.pump();
      engines.last.complete();
      for (var i = 0; i < 4; i++) {
        await tester.pump();
      }
    }

    Future<void> finish(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 20));
    }

    // The film page's two buttons (§12 screen 5): Resume uses the saved
    // position, Play from start ignores it. The first is the control: it
    // shows the seek happens at all, so its absence below means something.
    testWidgets('a saved position is resumed from', (tester) async {
      await pumpServer(tester, 'film',
          resumeFrom: const Duration(minutes: 5));
      await tester.pump();
      expect(engines.single.calls, contains('seek 0:05:00.000000'));
      await finish(tester);
    });

    testWidgets('Play from start ignores it', (tester) async {
      await pumpServer(tester, 'film',
          resumeFrom: const Duration(minutes: 5), query: '?start=0');
      await tester.pump();
      expect(engines.single.calls.where((c) => c.startsWith('seek')), isEmpty);
      await finish(tester);
    });

    testWidgets('reports the episode, offers the next season, and plays it '
        'when the countdown runs out', (tester) async {
      await pumpServer(tester, 'e12');
      await playToEnd(tester);

      expect(find.text('Up next'), findsOneWidget);
      expect(find.text('S2 E1 · Episode e21'), findsOneWidget);
      expect(server.reports, ['e12 stopped'],
          reason: 'the finished episode is reported before anything else');

      await tester.pump(const Duration(seconds: 5));
      expect(engines, hasLength(1), reason: 'still counting down');

      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(seconds: 1));
      }
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 300));
      }
      expect(engines, hasLength(2));
      expect(engines.first.calls.last, 'dispose');
      expect(engines.first.calls, contains('stop'));
      expect(engines.last.calls, ['stop', 'open http://server/e21']);
      expect(server.reports, ['e12 stopped'],
          reason: 'leaving the ended player does not report it again');
      await finish(tester);
    });

    testWidgets('Cancel has focus, and pressing it keeps the player here',
        (tester) async {
      await pumpServer(tester, 'e12');
      await playToEnd(tester);
      await tester.pump();

      expect(FocusManager.instance.primaryFocus?.debugLabel, 'up-next-cancel',
          reason: 'one press on a remote must not commit to the next one');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(find.text('Up next'), findsNothing);

      await tester.pump(const Duration(seconds: 15));
      expect(engines, hasLength(1));
      await finish(tester);
    });

    testWidgets('Back cancels the card instead of leaving', (tester) async {
      await pumpServer(tester, 'e12');
      await playToEnd(tester);
      await tester.pump();
      expect(find.text('Up next'), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.text('Up next'), findsNothing);
      expect(find.byType(PlayerScreen), findsOneWidget);

      await tester.pump(const Duration(seconds: 15));
      expect(engines, hasLength(1));
      await finish(tester);
    });

    testWidgets('no card after the last episode', (tester) async {
      await pumpServer(tester, 'e21');
      await playToEnd(tester);
      expect(server.reports, ['e21 stopped']);
      expect(find.text('Up next'), findsNothing);
      await finish(tester);
    });

    testWidgets('no card after a film', (tester) async {
      await pumpServer(tester, 'film');
      await playToEnd(tester);
      expect(server.reports, ['film stopped']);
      expect(server.lookups, isEmpty,
          reason: 'a film is not part of anything to look up');
      expect(find.text('Up next'), findsNothing);
      await tester.pump(const Duration(seconds: 15));
      expect(engines, hasLength(1));
      await finish(tester);
    });
  });
}
