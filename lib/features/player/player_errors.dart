/// Which messages on media_kit's error stream actually stop playback.
///
/// media_kit does not report failures, it reports *log lines*: every mpv log
/// message at level `error` from the `cplayer`, `vd`, `ad`, `stream` and `file`
/// prefixes is forwarded to `Player.stream.error` verbatim (media_kit 1.2.6,
/// `real.dart`). Some of those are mpv saying it carried on without something.
/// The player screen used to treat every one as fatal and draw its error
/// overlay on top of a picture that was still playing.
///
/// Found on the first iOS store-screenshot session (2026-09-23): on an iOS 18.6
/// simulator, Plex direct play of an open-licensed film decoded and presented
/// frames while mpv logged "Could not open/initialize audio device -> no
/// sound.", and the screen showed "Big Buck Bunny" over an error icon with the
/// film visible behind it. The same film on a real iPhone, TestFlight 1.0.4 (8)
/// without this filter, played with no overlay the same day, so the trigger
/// is the simulator's audio output rather than anything a user normally
/// meets. The filter stays anyway: a device can still fail to open audio (say,
/// another app holding the audio session), and even then losing the sound is
/// no reason to stop the video.
///
/// Deliberately an allow-list of the known-benign, not a guess at which
/// messages are fatal: an unrecognised message still fails loudly, which is
/// the safer mistake for a player whose sources are often malformed.
bool isFatalPlayerError(String message) {
  for (final benign in _nonFatal) {
    if (message.contains(benign)) return false;
  }
  return true;
}

/// Substrings of mpv messages that mean "continuing without this".
///
/// Matched as substrings because media_kit passes mpv's text through trimmed
/// but otherwise untouched, and mpv has printed this sentence unchanged for
/// years (`player/audio.c`). If an mpv upgrade rewords it, the symptom returns
/// as an overlay, not as silence, so it will be noticed.
const _nonFatal = [
  // Audio output could not start. mpv plays the video without sound.
  'Could not open/initialize audio device',
];
