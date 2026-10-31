import 'package:flutter/widgets.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../player_errors.dart';
import '../video_output.dart';
import 'playback_engine.dart';

/// libmpv through media_kit: the one engine, on every platform (§10).
///
/// This is where everything media_kit-shaped now lives — its pseudo-tracks,
/// its log-lines-as-errors, the Android direct/compatible output choice and
/// the `hwdec-current` check behind it. Before §10.2 it was spread through the
/// player screen and the controls.
class MediaKitEngine implements PlaybackEngine {
  MediaKitEngine(EngineOutput output)
      : _output = output == EngineOutput.compatible
            ? VideoOutput.compatible
            : defaultVideoOutput() {
    _controller = VideoController(
      _player,
      configuration: videoConfigurationFor(_output),
    );
  }

  final Player _player = Player();
  final VideoOutput _output;
  late final VideoController _controller;

  @override
  String get name => 'media_kit/${_output.name}';

  @override
  bool get hasCompatibleFallback => _output == VideoOutput.direct;

  @override
  Stream<EngineError> get errorStream => _player.stream.error
      .map((m) => EngineError(m, fatal: isFatalPlayerError(m)));

  @override
  Stream<Duration> get durationStream => _player.stream.duration;

  /// media_kit reports `completed` as a flag that goes true at end of file and
  /// back to false on the next open or seek; only the rising edge is an end.
  ///
  /// media_kit runs mpv with `keep-open=yes` and `network-timeout=5`, so a
  /// live stream whose connection closes, or which sends nothing for about
  /// five seconds, rises this too, with mpv paused on the last frame and
  /// nothing on [errorStream] (measured against a local server, 2026-10-31,
  /// §10 "Live end of file"). The ffmpeg-prefixed "Stream ends prematurely"
  /// line that comes with a dropped connection is not one media_kit forwards.
  @override
  Stream<void> get completedStream =>
      _player.stream.completed.where((done) => done);

  @override
  Future<void> open(String url) => _player.open(Media(url));

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> dispose() => _player.dispose();

  @override
  Widget buildView({required double subtitleScale}) => Video(
        controller: _controller,
        controls: null,
        subtitleViewConfiguration: SubtitleViewConfiguration(
          textScaler: TextScaler.linear(subtitleScale),
        ),
      );

  /// On the direct path, asks mpv which decoder it ended up with. Software
  /// means a black picture under direct output (see [VideoOutput]).
  @override
  Future<String?> checkOutputAfterStart() async {
    if (_output != VideoOutput.direct) return null;
    final String hwdec;
    try {
      hwdec = await (_player.platform as NativePlayer).getProperty(
        'hwdec-current',
      );
    } catch (_) {
      return null;
    }
    final hasVideo =
        _player.state.track.video.id != 'no' &&
        _player.state.tracks.video.any((t) => isRealTrackId(t.id));
    debugPrint('Player: direct output, hwdec-current=$hwdec video=$hasVideo');
    return needsCompatibleOutput(
      output: _output,
      hasVideo: hasVideo,
      hwdecCurrent: hwdec,
    )
        ? 'hardware decoder declined (hwdec=$hwdec)'
        : null;
  }

  @override
  Stream<Duration> get positionStream => _player.stream.position;
  @override
  Duration get position => _player.state.position;
  @override
  Duration get duration => _player.state.duration;
  @override
  Stream<bool> get playingStream => _player.stream.playing;
  @override
  bool get playing => _player.state.playing;
  @override
  Future<void> seek(Duration to) => _player.seek(to);
  @override
  Future<void> play() => _player.play();
  @override
  Future<void> pause() => _player.pause();
  @override
  Future<void> playOrPause() => _player.playOrPause();
  @override
  Future<void> setVolume(double percent) => _player.setVolume(percent);

  @override
  Stream<TrackList> get tracksStream => _player.stream.tracks.map(trackListOf);
  @override
  TrackList get tracks => trackListOf(_player.state.tracks);
  @override
  Stream<TrackSelection> get selectionStream =>
      _player.stream.track.map(selectionOf);
  @override
  TrackSelection get selection => selectionOf(_player.state.track);

  @override
  Future<void> setAudioTrack(MediaTrack track) => _player.setAudioTrack(
        _player.state.tracks.audio.where((t) => t.id == track.id).firstOrNull ??
            AudioTrack(track.id, track.title, track.language),
      );

  @override
  Future<void> setSubtitleTrack(MediaTrack? track) =>
      _player.setSubtitleTrack(
        track == null
            ? SubtitleTrack.no()
            : _player.state.tracks.subtitle
                    .where((t) => t.id == track.id)
                    .firstOrNull ??
                SubtitleTrack(track.id, track.title, track.language),
      );
}

/// media_kit lists "auto" and "no" before and beside the real tracks. They
/// are commands, not tracks, and stop here.
bool isRealTrackId(String id) => id != 'auto' && id != 'no';

TrackList trackListOf(Tracks tracks) => TrackList(
      audio: [
        for (final t in tracks.audio)
          if (isRealTrackId(t.id))
            MediaTrack(t.id,
                title: t.title,
                language: t.language,
                isDefault: t.isDefault == true),
      ],
      subtitle: [
        for (final t in tracks.subtitle)
          if (isRealTrackId(t.id))
            MediaTrack(t.id,
                title: t.title,
                language: t.language,
                isDefault: t.isDefault == true),
      ],
    );

TrackSelection selectionOf(Track track) => TrackSelection(
      audioId: isRealTrackId(track.audio.id) ? track.audio.id : null,
      subtitleId: isRealTrackId(track.subtitle.id) ? track.subtitle.id : null,
    );
