import 'dart:io' show Platform;

import 'package:media_kit_video/media_kit_video.dart';
// Not exported, but it is the same check media_kit itself uses to force
// software decoding on an emulator, and it is already initialised by then.
// ignore: implementation_imports
import 'package:media_kit/src/player/native/utils/android_helper.dart';

/// How decoded frames reach the screen.
///
/// **Direct** is what the Plex app does on Android TV, and mpv-android's
/// default: MediaCodec decodes in hardware and renders straight into the
/// surface (`hwdec=mediacodec`, `vo=mediacodec_embed`). The frame never comes
/// back to memory and the GPU does no work on it.
///
/// **Compatible** is media_kit's own default and what this app used until
/// 2026-10-10: MediaCodec decodes, each frame is copied back to memory, uploaded
/// to the GPU, and drawn by mpv's OpenGL renderer (`hwdec=auto-safe`, which on
/// Android resolves to `mediacodec-copy`, and `vo=gpu`). On the Chromecast with
/// Google TV, whose GPU is a small Mali, Plex titles played "mostly jittery"
/// this way while the Plex app played the same files smoothly
/// (MANUAL_TESTING.md, reported 2026-10-10). That the copy is the cause is the
/// leading hypothesis, not a measurement; see that row.
///
/// The price of direct is that it has no software path. When MediaCodec cannot
/// take a stream (a codec or profile the TV's decoder lacks), mpv falls back to
/// software decoding, and `mediacodec_embed` can only show MediaCodec's own
/// frames, so the sound plays over a black picture. [needsCompatibleOutput]
/// detects that and the player reopens the title on the compatible path.
///
/// mpv draws nothing itself on either path here: subtitles are text drawn by
/// Flutter (`SubtitleView`, with libass off), so direct output loses none.
enum VideoOutput { direct, compatible }

/// Direct on a real Android device; compatible everywhere else.
///
/// Not on the emulator, where media_kit forces software decoding anyway and
/// video does not render at all (CLAUDE.md section 6): direct would only add a
/// second way for it to fail. Desktop and iOS keep media_kit's defaults, which
/// these options do not apply to.
VideoOutput defaultVideoOutput() =>
    Platform.isAndroid && AndroidHelper.isPhysicalDevice
    ? VideoOutput.direct
    : VideoOutput.compatible;

VideoControllerConfiguration videoConfigurationFor(VideoOutput output) =>
    switch (output) {
      VideoOutput.direct => const VideoControllerConfiguration(
        vo: 'mediacodec_embed',
        hwdec: 'mediacodec',
      ),
      // media_kit's own choices, left to it.
      VideoOutput.compatible => const VideoControllerConfiguration(),
    };

/// The codecs mpv may hardware-decode on Android: media_kit's own list
/// (`h264,hevc,mpeg4,mpeg2video,vp8,vp9,av1`) **minus `mpeg4`**.
///
/// MPEG-4 part 2 (DivX/Xvid, usually in AVI) froze the picture on a Pixel 10a
/// (Android 17), 2026-11-12, on a Plex film that is an AVI with MPEG-4 video
/// and AC-3 audio. The container carries no video timestamps, and mpv logged
/// "mpeg4_mediacodec: Input packet is missing PTS" for every packet. After each
/// seek, resume included, MediaCodec's output timestamps restarted near zero:
/// "Invalid video timestamp: 848.43 -> -0.04", then "Audio/Video
/// desynchronisation detected!". The audio played on while the picture stood
/// still. Software decoding rebuilds the timestamps itself and played the same
/// file correctly, on this Pixel and on a real iPad (where mpv's own
/// whitelist leaves MPEG-4 to software already). Cheap to decode in software,
/// since MPEG-4 part 2 is old and is seen at DVD-era resolutions.
///
/// On the direct path (hwdec=mediacodec, no software path) mpv now declines
/// hardware for such a file, `hwdec-current` comes back empty, and
/// [needsCompatibleOutput] reopens it on the compatible path about a second
/// after it starts. Seen working on the Pixel, same day.
const androidHardwareCodecs = 'h264,hevc,mpeg2video,vp8,vp9,av1';

/// Whether a title playing on the direct path has to be reopened on the
/// compatible one.
///
/// [hwdecCurrent] is mpv's `hwdec-current`: the decoder actually in use, which
/// is `no` (or empty) once mpv has fallen back to software. Only meaningful
/// when there is a video track at all; an audio file has no decoder to ask
/// about and must not bounce.
bool needsCompatibleOutput({
  required VideoOutput output,
  required bool hasVideo,
  required String hwdecCurrent,
}) {
  if (output != VideoOutput.direct || !hasVideo) return false;
  final current = hwdecCurrent.trim();
  return current.isEmpty || current == 'no';
}
