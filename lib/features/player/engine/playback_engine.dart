import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'media_kit_engine.dart';

/// The seam between the player screen and whatever decodes the video
/// (architecture.md §10.2).
///
/// Everything above this line — the screen's stall guard, live reconnect,
/// progress reporting, focus policy, controls and track picker — talks only to
/// these types. Everything below it is one engine's business. Today there is
/// exactly one engine, [MediaKitEngine], and that is deliberate: §10.2 records
/// why a second (ExoPlayer on Android) was looked at and not built. What this
/// buys is that adding one later means writing an engine, not rewriting the
/// screen, and that the screen can be driven by a fake in tests.
///
/// **The position rule from §10 is part of the contract.** An engine's
/// [PlayerTransport.positionStream] must advance only while frames are being
/// presented, because the screen builds "it is playing" on it and on nothing
/// else. An engine that reports a clock without a picture (as media_kit does
/// on the Android emulator) is a known lie the screen cannot see through.

/// One audio or subtitle track the viewer can choose.
///
/// Engine-neutral: media_kit's own track classes include "auto" and "no"
/// pseudo-tracks that are not tracks at all, and another engine would have
/// its own shapes again. Engines map into this and filter those out.
@immutable
class MediaTrack {
  const MediaTrack(this.id, {this.title, this.language, this.isDefault = false});

  /// Opaque to everything but the engine that produced it.
  final String id;
  final String? title;

  /// As the file has it: "en", "eng", "en-US" and "und" all occur.
  final String? language;
  final bool isDefault;

  @override
  bool operator ==(Object other) =>
      other is MediaTrack &&
      other.id == id &&
      other.title == title &&
      other.language == language &&
      other.isDefault == isDefault;

  @override
  int get hashCode => Object.hash(id, title, language, isDefault);

  @override
  String toString() => 'MediaTrack($id, $title, $language)';
}

/// The real tracks in the open file. Empty until the engine has parsed it.
@immutable
class TrackList {
  const TrackList({this.audio = const [], this.subtitle = const []});

  final List<MediaTrack> audio;
  final List<MediaTrack> subtitle;

  bool get isEmpty => audio.isEmpty && subtitle.isEmpty;
}

/// What is selected now. A null [subtitleId] means subtitles are off; a null
/// [audioId] means the engine has not said (before the file is parsed).
@immutable
class TrackSelection {
  const TrackSelection({this.audioId, this.subtitleId});

  final String? audioId;
  final String? subtitleId;
}

/// Something went wrong below the seam.
///
/// [fatal] is the engine's judgement, because only it knows its own error
/// vocabulary: media_kit forwards mpv *log lines*, some of which mean mpv
/// carried on without something (player_errors.dart). The screen acts on
/// fatal ones and logs the rest.
@immutable
class EngineError {
  const EngineError(this.message, {required this.fatal});

  final String message;
  final bool fatal;

  @override
  String toString() => message;
}

/// The slice of a player the controls and the focus policy need.
///
/// Kept separate from [PlaybackEngine] so the controls can be driven in a
/// widget test without an engine at all. Everything that went wrong in #10 was
/// key and focus behaviour, which a test can pin down, and none of it needs a
/// decoder.
abstract class PlayerTransport {
  Stream<Duration> get positionStream;
  Duration get position;
  Duration get duration;
  Stream<bool> get playingStream;
  bool get playing;
  Future<void> seek(Duration to);
  Future<void> play();
  Future<void> pause();
  Future<void> playOrPause();

  /// 0 to 100. Used only for ducking (§10).
  Future<void> setVolume(double percent);

  Stream<TrackList> get tracksStream;
  TrackList get tracks;

  Stream<TrackSelection> get selectionStream;
  TrackSelection get selection;
  Future<void> setAudioTrack(MediaTrack track);

  /// Null turns subtitles off.
  Future<void> setSubtitleTrack(MediaTrack? track);
}

/// A decoder and renderer the player screen can drive.
abstract class PlaybackEngine implements PlayerTransport {
  /// For logs and the debug menu. Never shown to users.
  String get name;

  Stream<EngineError> get errorStream;
  Stream<Duration> get durationStream;

  /// Fires once each time the open file plays through to its end. Not on a
  /// stop, an error or a seek near the end: only the decoder running out of
  /// file. What the screen offers the next episode on (§12.5).
  ///
  /// For a live stream, which has no end, this is the source going away: the
  /// panel closing the connection, or a read stall the engine gave up on.
  /// The screen reconnects on it (§10, "Live end of file", 2026-10-31). An
  /// engine must report that case here, or as a fatal error, and not only by
  /// stopping: a stream that silently stops playing looks to the screen like
  /// a viewer's pause.
  Stream<void> get completedStream;

  /// Queues [url] for playback. Returning means the command was accepted,
  /// **not** that anything opened (§10): failures arrive on [errorStream], and
  /// success is only ever the position advancing.
  Future<void> open(String url);

  /// Releases the source. The screen calls this before every [open], because
  /// §4's `max_connections: 1` requires the old connection gone first.
  Future<void> stop();

  /// The picture, with subtitles drawn at [subtitleScale] times the engine's
  /// default size.
  Widget buildView({required double subtitleScale});

  /// Called once, about a second after the first frame. Returns a reason to
  /// reopen on [EngineOutput.compatible] when the fast output path turned out
  /// unable to show this file, or null when all is well.
  ///
  /// This exists for one engine-specific trap (video_output.dart: direct
  /// output has no software path, so a declined decoder means sound over
  /// black). Engines without such a path return null.
  Future<String?> checkOutputAfterStart();

  /// Whether a failure before the first frame is worth one retry on
  /// [EngineOutput.compatible]: true only while on a fast path that has
  /// something to fall back from.
  bool get hasCompatibleFallback;

  Future<void> dispose();
}

/// Which output path an engine should use for a title. [fast] is the engine's
/// preferred path; [compatible] is the one that works for anything it can
/// decode at all, chosen after [PlaybackEngine.checkOutputAfterStart] or a
/// failed start asked for it.
enum EngineOutput { fast, compatible }

typedef PlaybackEngineFactory = PlaybackEngine Function(EngineOutput output);

/// How the player screen gets its engine. Overridden in tests with a fake.
///
/// One engine for every platform and source (§10's "one pipeline" finding).
/// If a second engine is ever added, the choice belongs here and nowhere else.
final playbackEngineFactoryProvider = Provider<PlaybackEngineFactory>(
  (ref) => MediaKitEngine.new,
);
