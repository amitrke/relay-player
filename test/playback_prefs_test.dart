import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:media_kit/media_kit.dart';
import 'package:relay_player/core/theme/relay_theme.dart';
import 'package:relay_player/core/theme/relay_tokens.dart';
import 'package:relay_player/features/player/playback_prefs.dart';
import 'package:relay_player/features/player/player_controls.dart';

/// Track choice from the Playback and Subtitles settings, and the player's
/// picker. Track fixtures are shaped like media_kit's, including its "auto"
/// and "no" pseudo-tracks; real files' language tags are a device check.
Tracks _tracks({
  List<AudioTrack> audio = const [],
  List<SubtitleTrack> subtitle = const [],
}) =>
    Tracks(
      audio: [AudioTrack.auto(), AudioTrack.no(), ...audio],
      subtitle: [SubtitleTrack.auto(), SubtitleTrack.no(), ...subtitle],
    );

class _Transport implements PlayerTransport {
  _Transport(this.tracks);

  @override
  Tracks tracks;
  @override
  Track track = Track(subtitle: SubtitleTrack.no());
  final picked = <String>[];

  @override
  Stream<Tracks> get tracksStream => const Stream.empty();
  @override
  Stream<Track> get trackStream => const Stream.empty();
  @override
  Future<void> setAudioTrack(AudioTrack t) async => picked.add('audio ${t.id}');
  @override
  Future<void> setSubtitleTrack(SubtitleTrack t) async =>
      picked.add('sub ${t.id}');

  final seeks = <Duration>[];
  @override
  Future<void> seek(Duration to) async => seeks.add(to);
  @override
  Duration get position => const Duration(minutes: 10);
  @override
  Duration get duration => const Duration(hours: 1);
  @override
  bool get playing => false;
  @override
  Stream<Duration> get positionStream => const Stream.empty();
  @override
  Stream<bool> get playingStream => const Stream.empty();
  @override
  Future<void> play() async {}
  @override
  Future<void> pause() async {}
  @override
  Future<void> playOrPause() async {}
  @override
  Future<void> setVolume(double percent) async {}
}

void main() {
  group('normalizeLanguage', () {
    test('accepts the forms files use', () {
      expect(normalizeLanguage('en'), 'en');
      expect(normalizeLanguage('eng'), 'en');
      expect(normalizeLanguage('EN-us'), 'en');
      expect(normalizeLanguage('ger'), 'de');
      expect(normalizeLanguage('deu'), 'de');
      expect(normalizeLanguage('und'), isNull);
      expect(normalizeLanguage(null), isNull);
      expect(normalizeLanguage('xyz'), isNull);
    });
  });

  group('chooseTracks', () {
    final tracks = _tracks(
      audio: [
        const AudioTrack('1', 'Director commentary', 'eng'),
        const AudioTrack('2', null, 'spa'),
      ],
      subtitle: [
        const SubtitleTrack('3', null, 'eng'),
        const SubtitleTrack('4', 'Forced', 'fre', isDefault: true),
      ],
    );

    test('defaults leave audio alone and turn subtitles off', () {
      final c = chooseTracks(tracks, const PlaybackPrefs());
      expect(c.audio, isNull);
      expect(c.subtitle?.id, 'no');
    });

    test('a preferred audio language picks the matching track', () {
      final c =
          chooseTracks(tracks, const PlaybackPrefs(audioLanguage: 'es'));
      expect(c.audio?.id, '2');
    });

    test('no matching audio leaves the file default', () {
      final c =
          chooseTracks(tracks, const PlaybackPrefs(audioLanguage: 'ja'));
      expect(c.audio, isNull);
    });

    test('subtitles on with a language picks it', () {
      final c = chooseTracks(
          tracks,
          const PlaybackPrefs(subtitlesOn: true, subtitleLanguage: 'en'));
      expect(c.subtitle?.id, '3');
    });

    test('subtitles on in a language the file lacks stay off', () {
      final c = chooseTracks(
          tracks,
          const PlaybackPrefs(subtitlesOn: true, subtitleLanguage: 'ja'));
      expect(c.subtitle?.id, 'no');
    });

    test('subtitles on with no language prefers the default-flagged track',
        () {
      final c = chooseTracks(tracks, const PlaybackPrefs(subtitlesOn: true));
      expect(c.subtitle?.id, '4');
    });
  });

  group('player', () {
    Future<_Transport> pump(WidgetTester tester, Tracks tracks,
        {Duration skip = const Duration(seconds: 10)}) async {
      final t = _Transport(tracks);
      // Theme above the navigator, as the app's MaterialApp.builder does, so
      // the sheet's route can see it.
      await tester.pumpWidget(MaterialApp(
        builder: (context, child) => RelayTheme(
          tokens: RelayPalettes.midnight,
          palette: RelayPalette.midnight,
          child: child!,
        ),
        home: Scaffold(
          body: PlayerChrome(
            transport: t,
            title: 'Title',
            live: false,
            enabled: true,
            onBack: () {},
            skip: skip,
            child: const SizedBox.expand(),
          ),
        ),
      ));
      await tester.pump();
      return t;
    }

    testWidgets('no picker when there is nothing to pick', (tester) async {
      await pump(tester,
          _tracks(audio: [const AudioTrack('1', null, 'eng')]));
      expect(find.byTooltip('Audio and subtitles'), findsNothing);
    });

    testWidgets('the picker lists tracks by language and switches them',
        (tester) async {
      final t = await pump(
        tester,
        _tracks(
          audio: [
            const AudioTrack('1', null, 'eng'),
            const AudioTrack('2', null, 'spa'),
          ],
          subtitle: [const SubtitleTrack('3', 'SDH', 'eng')],
        ),
      );
      await tester.tap(find.byTooltip('Audio and subtitles'));
      await tester.pumpAndSettle();

      expect(find.text('Spanish'), findsOneWidget);
      expect(find.text('English · SDH'), findsOneWidget);
      expect(find.text('Off'), findsOneWidget);

      await tester.tap(find.text('Spanish'));
      await tester.pumpAndSettle();
      expect(t.picked, ['audio 2']);
      expect(find.text('Spanish'), findsNothing, reason: 'sheet closes');
    });

    testWidgets('the skip length comes from the setting', (tester) async {
      final t = await pump(tester, _tracks(), skip: const Duration(seconds: 30));
      expect(find.byIcon(Icons.forward_30), findsOneWidget);
      expect(find.byIcon(Icons.forward_10), findsNothing);

      await tester.sendKeyEvent(LogicalKeyboardKey.mediaFastForward);
      expect(t.seeks, [const Duration(minutes: 10, seconds: 30)]);
      await tester.pump(const Duration(seconds: 2));
    });
  });
}
