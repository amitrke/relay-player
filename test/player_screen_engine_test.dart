import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:relay_player/core/theme/relay_theme.dart';
import 'package:relay_player/core/theme/relay_tokens.dart';
import 'package:relay_player/data/filesystem/device_video_source.dart';
import 'package:relay_player/data/local/history_store.dart';
import 'package:relay_player/features/favorites_history/history_controller.dart';
import 'package:relay_player/features/local_network/local_network_tab.dart';
import 'package:relay_player/features/player/engine/playback_engine.dart';
import 'package:relay_player/features/player/playback_prefs.dart';
import 'package:relay_player/features/player/player_screen.dart';

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
  Stream<Duration> get durationStream => const Stream.empty();
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
  Duration get duration => Duration.zero;
  @override
  Stream<bool> get playingStream => const Stream.empty();
  @override
  bool get playing => true;
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
}
