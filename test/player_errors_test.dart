import 'package:flutter_test/flutter_test.dart';
import 'package:relay_player/features/player/player_errors.dart';

/// Pins which media_kit error-stream messages stop playback.
///
/// The benign case is the exact text mpv logged on the iOS simulator on
/// 2026-09-23, not a paraphrase, so the test fails if the match drifts away
/// from what mpv actually says. The controls are real fatal messages of the
/// kinds media_kit forwards, so an over-broad match (treating everything as
/// benign) fails too.
void main() {
  test('audio output failing to start is not fatal', () {
    expect(
      isFatalPlayerError(
          'Could not open/initialize audio device -> no sound.'),
      isFalse,
    );
  });

  test('one undecodable audio packet is not fatal', () {
    // Exact text from a real iPad, 2026-11-12: an AVI with AC-3 audio, resumed
    // mid-film. mpv's next line was "playback restart complete ...
    // audio=playing, video=playing".
    expect(isFatalPlayerError('Error decoding audio.'), isFalse);
  });

  test('a codec that will not open is still fatal', () {
    // Reported from Android on the same film. Kept fatal on purpose: for a
    // video track this is a black screen, and its cause has not been seen.
    expect(isFatalPlayerError('Could not open codec.'), isTrue);
  });

  test('real failures are still fatal', () {
    for (final message in [
      'Failed to open https://<panel-host>/movie/1.mkv.',
      'tcp: Connection refused',
      'Failed to initialize a decoder for codec \'hevc\'.',
      'No video or audio streams selected.',
      '',
    ]) {
      expect(isFatalPlayerError(message), isTrue, reason: message);
    }
  });
}
