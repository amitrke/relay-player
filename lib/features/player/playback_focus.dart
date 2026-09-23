import 'dart:async';
import 'dart:io';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';

import 'player_controls.dart';

/// Something outside the player that should change what it is doing (#17).
enum FocusEvent {
  /// Another app took audio focus for good, usually by starting to play.
  lost,

  /// A call or similar; focus is expected back.
  transientLoss,

  /// Focus came back after a [transientLoss].
  transientEnded,

  /// A notification or navigation prompt wants us quieter for a moment.
  duck,
  duckEnded,

  /// Headphones were unplugged. Carrying on would play through the speaker.
  noisy,

  /// The app is no longer visible: home, recents, screen off.
  hidden,
}

/// What the player does for each [FocusEvent], as decided in architecture.md
/// §10 before this was written.
///
/// Kept free of any platform API so the table in §10 can be tested as a table.
/// [AudioFocusBinding] and the player's lifecycle listener only translate
/// platform signals into [FocusEvent]s.
class PlaybackFocusPolicy {
  PlaybackFocusPolicy({
    required this.transport,
    required this.isLive,
    required this.releaseLive,
  });

  final PlayerTransport transport;
  final bool Function() isLive;

  /// Stops a live stream and frees its connection. Live never just pauses: a
  /// paused live stream cannot pick up where it was, and holding it keeps the
  /// only connection on a `max_connections: 1` line busy (§4).
  final VoidCallback releaseLive;

  /// Volume while ducked, as a media_kit percentage.
  static const duckedVolume = 30.0;

  bool _resumeOnRegain = false;
  bool _ducked = false;

  void handle(FocusEvent event) {
    switch (event) {
      case FocusEvent.duck:
        if (_ducked) return;
        _ducked = true;
        unawaited(transport.setVolume(duckedVolume));
      case FocusEvent.duckEnded:
        if (!_ducked) return;
        _ducked = false;
        unawaited(transport.setVolume(100));
      case FocusEvent.transientEnded:
        // Only what we paused. Resuming something the viewer had paused
        // themselves before the call would be the player overruling them.
        if (!_resumeOnRegain) return;
        _resumeOnRegain = false;
        unawaited(transport.play());
      case FocusEvent.lost:
      case FocusEvent.transientLoss:
      case FocusEvent.noisy:
      case FocusEvent.hidden:
        if (isLive()) {
          // Whether or not the position is moving yet: a live stream that is
          // still connecting already holds the connection.
          _resumeOnRegain = false;
          releaseLive();
          return;
        }
        _resumeOnRegain =
            event == FocusEvent.transientLoss && transport.playing;
        unawaited(transport.pause());
    }
  }
}

/// Audio focus from the platform, as [FocusEvent]s.
///
/// Android and iOS only; elsewhere [attach] returns null and the player simply
/// has no focus handling, which is what desktop players generally do.
class AudioFocusBinding {
  AudioFocusBinding._(this._session, this._subs);

  final AudioSession _session;
  final List<StreamSubscription<dynamic>> _subs;

  static Future<AudioFocusBinding?> attach(
      void Function(FocusEvent) onEvent) async {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) return null;
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playback,
        avAudioSessionMode: AVAudioSessionMode.moviePlayback,
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType.movie,
          usage: AndroidAudioUsage.media,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
        // Let Android 8+ duck us itself. Asking to pause instead is for
        // speech, where a lowered voice is lost; a film is not that (§10).
        androidWillPauseWhenDucked: false,
      ));
      final subs = <StreamSubscription<dynamic>>[
        session.interruptionEventStream.listen((e) {
          final event = switch ((e.begin, e.type)) {
            (true, AudioInterruptionType.pause) => FocusEvent.transientLoss,
            (true, AudioInterruptionType.duck) => FocusEvent.duck,
            (true, AudioInterruptionType.unknown) => FocusEvent.lost,
            (false, AudioInterruptionType.pause) => FocusEvent.transientEnded,
            (false, AudioInterruptionType.duck) => FocusEvent.duckEnded,
            // A permanent loss has no end; if one arrives, do nothing.
            (false, AudioInterruptionType.unknown) => null,
          };
          if (event != null) onEvent(event);
        }),
        session.becomingNoisyEventStream.listen((_) => onEvent(FocusEvent.noisy)),
      ];
      return AudioFocusBinding._(session, subs);
    } catch (e) {
      // Losing focus handling is not worth losing playback over.
      debugPrint('AudioFocusBinding: unavailable ($e)');
      return null;
    }
  }

  /// Asks for focus. Called each time playback starts, including after a
  /// permanent loss, since pressing play is the viewer taking it back.
  Future<void> request() async {
    try {
      await _session.setActive(true);
    } catch (e) {
      debugPrint('AudioFocusBinding: request failed ($e)');
    }
  }

  Future<void> dispose() async {
    for (final s in _subs) {
      await s.cancel();
    }
    try {
      await _session.setActive(false);
    } catch (_) {}
  }
}
