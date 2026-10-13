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
