import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relay_player/core/theme/relay_theme.dart';
import 'package:relay_player/core/theme/relay_tokens.dart';
import 'package:relay_player/features/player/player_controls.dart';

/// Pins the #10 player-control behaviour on a remote.
///
/// Every symptom in that issue was key or focus handling (Up seeking, a
/// scrubber stepping by a tenth of the film, controls that never left), and
/// none of it needs libmpv, so it runs against a fake transport. This proves
/// the rules; it does not prove how a real remote's key repeat feels, which is
/// still a device check (MANUAL_TESTING.md §6).
class _FakeTransport implements PlayerTransport {
  final _position = StreamController<Duration>.broadcast();
  final _playing = StreamController<bool>.broadcast();
  final seeks = <Duration>[];

  @override
  Duration position = const Duration(minutes: 10);
  @override
  Duration duration = const Duration(hours: 2);
  @override
  bool playing = true;

  @override
  Stream<Duration> get positionStream => _position.stream;
  @override
  Stream<bool> get playingStream => _playing.stream;

  @override
  Future<void> seek(Duration to) async => seeks.add(to);
  @override
  Future<void> play() async => _set(true);
  @override
  Future<void> pause() async => _set(false);
  @override
  Future<void> playOrPause() async => _set(!playing);

  void _set(bool v) {
    playing = v;
    _playing.add(v);
  }
}

void main() {
  const hideAfter = Duration(seconds: 4);

  Future<_FakeTransport> pump(WidgetTester tester, {bool live = false}) async {
    final transport = _FakeTransport();
    await tester.pumpWidget(MaterialApp(
      home: RelayTheme(
        tokens: RelayPalettes.midnight,
        palette: RelayPalette.midnight,
        child: Scaffold(
          body: PlayerChrome(
            transport: transport,
            title: 'Title',
            live: live,
            enabled: true,
            onBack: () {},
            hideAfter: hideAfter,
            child: const SizedBox.expand(),
          ),
        ),
      ),
    ));
    await tester.pump();
    return transport;
  }

  double chromeOpacity(WidgetTester tester) => tester
      .widget<AnimatedOpacity>(find.descendant(
          of: find.byType(PlayerChrome), matching: find.byType(AnimatedOpacity)))
      .opacity;

  FocusNode? primary() => FocusManager.instance.primaryFocus;

  bool inSeekBar(FocusNode? node) =>
      node?.context?.findAncestorWidgetOfExactType<SeekBar>() != null;

  testWidgets('hides after a few seconds of playback', (tester) async {
    await pump(tester);
    expect(chromeOpacity(tester), 1);
    await tester.pump(hideAfter + const Duration(milliseconds: 100));
    expect(chromeOpacity(tester), 0);
  });

  testWidgets('never hides while paused', (tester) async {
    final t = await pump(tester);
    await t.pause();
    await tester.pump(hideAfter * 3);
    expect(chromeOpacity(tester), 1);
  });

  testWidgets('the first D-pad press only wakes the chrome', (tester) async {
    final t = await pump(tester);
    await tester.pump(hideAfter + const Duration(milliseconds: 100));
    expect(chromeOpacity(tester), 0);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    await tester.pump();
    expect(chromeOpacity(tester), 1);
    expect(t.seeks, isEmpty, reason: 'the waking press must not also seek');
    expect(primary()?.debugLabel, 'player-play');

    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pump(hideAfter + const Duration(milliseconds: 100));
    expect(t.playing, isFalse, reason: 'the second press acts');
    // Pausing surfaced the chrome, and it stays while paused.
    expect(chromeOpacity(tester), 1);
  });

  testWidgets('hiding takes focus out of the controls', (tester) async {
    await pump(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await tester.pump();
    expect(primary()?.debugLabel, 'player-play');

    await tester.pump(hideAfter + const Duration(milliseconds: 100));
    expect(chromeOpacity(tester), 0);
    expect(primary()?.debugLabel, 'player-root');
  });

  testWidgets('seek bar steps in time on Left/Right, and Up leaves it',
      (tester) async {
    final t = await pump(tester);
    // Arrive on play/pause, then go up to the seek bar.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    final seekBarNode = primary();
    expect(inSeekBar(seekBarNode), isTrue, reason: 'Up from play reaches it');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(t.seeks, [const Duration(minutes: 10, seconds: 10)],
        reason: 'one press is ten seconds, not a fraction of two hours');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(t.seeks, hasLength(1), reason: 'Up must never seek');
    expect(inSeekBar(primary()), isFalse, reason: 'Up leaves the bar');
  });

  testWidgets('a held key accelerates and seeks once on release',
      (tester) async {
    final t = await pump(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
    for (var i = 0; i < 12; i++) {
      await tester.sendKeyRepeatEvent(LogicalKeyboardKey.arrowRight);
    }
    await tester.pump();
    expect(t.seeks, isEmpty, reason: 'nothing is seeked while held');
    await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();

    // Down + repeats 1..9 at 10 s, 10..12 at 30 s.
    const expected = Duration(minutes: 10, seconds: 10 * 10 + 30 * 3);
    expect(t.seeks, [expected]);
  });

  testWidgets('media keys act even while hidden', (tester) async {
    final t = await pump(tester);
    await tester.pump(hideAfter + const Duration(milliseconds: 100));
    await tester.sendKeyEvent(LogicalKeyboardKey.mediaFastForward);
    await tester.sendKeyEvent(LogicalKeyboardKey.mediaFastForward);
    expect(t.seeks, [
      const Duration(minutes: 10, seconds: 10),
      const Duration(minutes: 10, seconds: 20),
    ], reason: 'quick skips chain rather than re-reading a stale position');
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('live has no seek bar and no skip buttons', (tester) async {
    await pump(tester, live: true);
    expect(find.byType(SeekBar), findsNothing);
    expect(find.byIcon(Icons.forward_10), findsNothing);
    expect(find.byIcon(Icons.replay_10), findsNothing);
  });
}
