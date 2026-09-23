import 'package:flutter_test/flutter_test.dart';
import 'package:relay_player/features/player/playback_focus.dart';
import 'package:relay_player/features/player/player_controls.dart';

/// The architecture.md §10 audio-focus table (#17), row by row.
///
/// This pins the decisions, not the platform: whether Android actually delivers
/// these events for a call, a notification and another app's music is a
/// real-phone check in MANUAL_TESTING.md.
class _Transport implements PlayerTransport {
  @override
  bool playing = true;
  double volume = 100;
  final calls = <String>[];

  @override
  Future<void> play() async {
    calls.add('play');
    playing = true;
  }

  @override
  Future<void> pause() async {
    calls.add('pause');
    playing = false;
  }

  @override
  Future<void> setVolume(double percent) async => volume = percent;

  @override
  Stream<Duration> get positionStream => const Stream.empty();
  @override
  Duration get position => Duration.zero;
  @override
  Duration get duration => const Duration(hours: 1);
  @override
  Stream<bool> get playingStream => const Stream.empty();
  @override
  Future<void> seek(Duration to) async {}
  @override
  Future<void> playOrPause() async => playing ? pause() : play();
}

void main() {
  late _Transport t;
  late int released;

  PlaybackFocusPolicy policy({bool live = false}) => PlaybackFocusPolicy(
        transport: t,
        isLive: () => live,
        releaseLive: () => released++,
      );

  setUp(() {
    t = _Transport();
    released = 0;
  });

  group('VOD', () {
    test('a call pauses, and focus coming back resumes', () {
      final p = policy()..handle(FocusEvent.transientLoss);
      expect(t.playing, isFalse);
      p.handle(FocusEvent.transientEnded);
      expect(t.playing, isTrue);
    });

    test('a call does not resume what the viewer had already paused', () {
      t.playing = false;
      policy()
        ..handle(FocusEvent.transientLoss)
        ..handle(FocusEvent.transientEnded);
      expect(t.calls, isNot(contains('play')));
    });

    test('another app taking focus pauses for good', () {
      policy()
        ..handle(FocusEvent.lost)
        // A stray end must not resume after a permanent loss.
        ..handle(FocusEvent.transientEnded);
      expect(t.playing, isFalse);
      expect(t.calls, ['pause']);
    });

    test('being hidden pauses and stays paused', () {
      policy().handle(FocusEvent.hidden);
      expect(t.playing, isFalse);
      expect(released, 0, reason: 'only live releases the connection');
    });

    test('unplugged headphones pause', () {
      policy().handle(FocusEvent.noisy);
      expect(t.playing, isFalse);
    });

    test('a notification ducks and restores', () {
      final p = policy()..handle(FocusEvent.duck);
      expect(t.volume, PlaybackFocusPolicy.duckedVolume);
      expect(t.playing, isTrue, reason: 'ducking is not pausing');
      p.handle(FocusEvent.duckEnded);
      expect(t.volume, 100);
    });
  });

  group('live', () {
    for (final event in [
      FocusEvent.hidden,
      FocusEvent.transientLoss,
      FocusEvent.lost,
      FocusEvent.noisy,
    ]) {
      test('$event releases the connection instead of pausing', () {
        policy(live: true).handle(event);
        expect(released, 1);
        expect(t.calls, isEmpty);
      });
    }

    test('does not rejoin by itself after a call', () {
      policy(live: true)
        ..handle(FocusEvent.transientLoss)
        ..handle(FocusEvent.transientEnded);
      expect(t.calls, isEmpty);
    });

    test('releases even before the first frame', () {
      t.playing = false;
      policy(live: true).handle(FocusEvent.hidden);
      expect(released, 1,
          reason: 'a stream still connecting already holds the connection');
    });
  });
}
