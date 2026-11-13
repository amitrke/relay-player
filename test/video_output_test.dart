import 'package:flutter_test/flutter_test.dart';
import 'package:relay_player/features/player/video_output.dart';

/// The rule that decides when a title on the direct (MediaCodec to surface)
/// path must be reopened, since a software decode there plays sound over a
/// black picture. The path itself needs a device; see MANUAL_TESTING.md.
void main() {
  bool needs(VideoOutput output, {bool hasVideo = true, String hwdec = ''}) =>
      needsCompatibleOutput(
        output: output,
        hasVideo: hasVideo,
        hwdecCurrent: hwdec,
      );

  test('hardware decoding on the direct path stays', () {
    expect(needs(VideoOutput.direct, hwdec: 'mediacodec'), isFalse);
  });

  test('software decoding on the direct path falls back', () {
    expect(needs(VideoOutput.direct, hwdec: 'no'), isTrue);
    expect(needs(VideoOutput.direct, hwdec: ''), isTrue);
    expect(needs(VideoOutput.direct, hwdec: ' no\n'), isTrue);
  });

  test('an audio-only file never falls back: there is no decoder to ask', () {
    expect(needs(VideoOutput.direct, hasVideo: false, hwdec: 'no'), isFalse);
  });

  test('the compatible path never falls back further', () {
    expect(needs(VideoOutput.compatible, hwdec: 'no'), isFalse);
  });

  test('direct output is the MediaCodec surface pair', () {
    final c = videoConfigurationFor(VideoOutput.direct);
    expect(c.vo, 'mediacodec_embed');
    expect(c.hwdec, 'mediacodec');
    final compat = videoConfigurationFor(VideoOutput.compatible);
    expect(compat.vo, isNull);
    expect(compat.hwdec, isNull);
  });

  // MPEG-4 part 2 must stay out of Android's hardware list: on a Pixel 10a
  // (2026-11-12) MediaCodec froze the picture of an AVI after every seek, with
  // the audio playing on. See [androidHardwareCodecs].
  test('MPEG-4 part 2 is left to software decoding on Android', () {
    expect(androidHardwareCodecs.split(','), isNot(contains('mpeg4')));
  });

  test('the codecs that do work in hardware are still allowed', () {
    final codecs = androidHardwareCodecs.split(',');
    for (final codec in ['h264', 'hevc', 'vp9', 'av1']) {
      expect(codecs, contains(codec));
    }
  });
}
