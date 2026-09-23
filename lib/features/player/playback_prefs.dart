import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';

import '../../data/local/app_settings_store.dart';
import '../settings/settings_controller.dart';

/// Subtitle text size, as a multiplier on media_kit's own default.
enum SubtitleSize {
  small('Small', 0.75),
  medium('Medium', 1.0),
  large('Large', 1.35);

  const SubtitleSize(this.label, this.scale);
  final String label;
  final double scale;

  static SubtitleSize fromName(String? name) =>
      values.where((s) => s.name == name).firstOrNull ?? medium;
}

/// The Playback and Subtitles settings (§12.1).
///
/// Languages are ISO 639-1 codes ("en"), or null for "whatever the file marks
/// as its default", which is what the player did before these existed.
class PlaybackPrefs {
  const PlaybackPrefs({
    this.skipSeconds = 10,
    this.audioLanguage,
    this.subtitlesOn = false,
    this.subtitleLanguage,
    this.subtitleSize = SubtitleSize.medium,
  });

  /// One of [skipChoices]. Only lengths Material has replay/forward icons for,
  /// so the buttons can say what they do.
  final int skipSeconds;
  static const skipChoices = [5, 10, 30];

  final String? audioLanguage;
  final bool subtitlesOn;
  final String? subtitleLanguage;
  final SubtitleSize subtitleSize;

  Duration get skip => Duration(seconds: skipSeconds);

  PlaybackPrefs copyWith({
    int? skipSeconds,
    String? Function()? audioLanguage,
    bool? subtitlesOn,
    String? Function()? subtitleLanguage,
    SubtitleSize? subtitleSize,
  }) =>
      PlaybackPrefs(
        skipSeconds: skipSeconds ?? this.skipSeconds,
        audioLanguage:
            audioLanguage != null ? audioLanguage() : this.audioLanguage,
        subtitlesOn: subtitlesOn ?? this.subtitlesOn,
        subtitleLanguage: subtitleLanguage != null
            ? subtitleLanguage()
            : this.subtitleLanguage,
        subtitleSize: subtitleSize ?? this.subtitleSize,
      );
}

const _kSkip = 'playback.skipSeconds';
const _kAudioLang = 'playback.audioLanguage';
const _kSubsOn = 'subtitles.on';
const _kSubsLang = 'subtitles.language';
const _kSubsSize = 'subtitles.size';

final playbackPrefsProvider =
    NotifierProvider<PlaybackPrefsController, PlaybackPrefs>(
  PlaybackPrefsController.new,
);

class PlaybackPrefsController extends Notifier<PlaybackPrefs> {
  AppSettingsStore get _store => ref.read(appSettingsStoreProvider);

  @override
  PlaybackPrefs build() {
    final skip = int.tryParse(_store.getString(_kSkip) ?? '');
    return PlaybackPrefs(
      skipSeconds:
          PlaybackPrefs.skipChoices.contains(skip) ? skip! : 10,
      audioLanguage: _language(_store.getString(_kAudioLang)),
      subtitlesOn: _store.getBool(_kSubsOn, fallback: false),
      subtitleLanguage: _language(_store.getString(_kSubsLang)),
      subtitleSize: SubtitleSize.fromName(_store.getString(_kSubsSize)),
    );
  }

  static String? _language(String? stored) =>
      (stored == null || stored.isEmpty) ? null : stored;

  /// Changes one thing from the *current* value. The panes use this rather
  /// than [update] with a copy made at build time: two taps before a rebuild
  /// would otherwise each start from the same stale copy, and the second would
  /// undo the first.
  Future<void> edit(PlaybackPrefs Function(PlaybackPrefs) change) =>
      update(change(state));

  Future<void> update(PlaybackPrefs next) async {
    state = next;
    await _store.setString(_kSkip, '${next.skipSeconds}');
    // An empty string stands for "the file's default"; the store has no
    // delete, and a missing key already reads as null.
    await _store.setString(_kAudioLang, next.audioLanguage ?? '');
    await _store.setBool(_kSubsOn, next.subtitlesOn);
    await _store.setString(_kSubsLang, next.subtitleLanguage ?? '');
    await _store.setString(_kSubsSize, next.subtitleSize.name);
  }
}

/// Languages offered in Settings, by ISO 639-1 code.
///
/// A fixed list rather than every language a file might carry: these are the
/// ones common enough in subtitle and audio tracks to be worth a row, and a
/// file in anything else can still be switched by hand in the player.
const playbackLanguages = <String, String>{
  'en': 'English',
  'es': 'Spanish',
  'fr': 'French',
  'de': 'German',
  'it': 'Italian',
  'pt': 'Portuguese',
  'nl': 'Dutch',
  'sv': 'Swedish',
  'no': 'Norwegian',
  'da': 'Danish',
  'fi': 'Finnish',
  'pl': 'Polish',
  'cs': 'Czech',
  'hu': 'Hungarian',
  'ro': 'Romanian',
  'el': 'Greek',
  'ru': 'Russian',
  'uk': 'Ukrainian',
  'tr': 'Turkish',
  'ar': 'Arabic',
  'he': 'Hebrew',
  'hi': 'Hindi',
  'bn': 'Bengali',
  'pa': 'Punjabi',
  'ta': 'Tamil',
  'te': 'Telugu',
  'ur': 'Urdu',
  'th': 'Thai',
  'vi': 'Vietnamese',
  'id': 'Indonesian',
  'zh': 'Chinese',
  'ja': 'Japanese',
  'ko': 'Korean',
};

/// ISO 639-2 codes, both bibliographic and terminological forms, to 639-1.
/// Matroska and MP4 usually tag tracks with these three-letter forms.
const _threeToTwo = <String, String>{
  'eng': 'en', 'spa': 'es', 'fra': 'fr', 'fre': 'fr', 'deu': 'de',
  'ger': 'de', 'ita': 'it', 'por': 'pt', 'nld': 'nl', 'dut': 'nl',
  'swe': 'sv', 'nor': 'no', 'nob': 'no', 'nno': 'no', 'dan': 'da',
  'fin': 'fi', 'pol': 'pl', 'ces': 'cs', 'cze': 'cs', 'hun': 'hu',
  'ron': 'ro', 'rum': 'ro', 'ell': 'el', 'gre': 'el', 'rus': 'ru',
  'ukr': 'uk', 'tur': 'tr', 'ara': 'ar', 'heb': 'he', 'hin': 'hi',
  'ben': 'bn', 'pan': 'pa', 'tam': 'ta', 'tel': 'te', 'urd': 'ur',
  'tha': 'th', 'vie': 'vi', 'ind': 'id', 'zho': 'zh', 'chi': 'zh',
  'jpn': 'ja', 'kor': 'ko',
};

/// A track's language tag as ISO 639-1, or null if it is missing or unknown.
/// Accepts "en", "eng", "en-US" and "EN".
String? normalizeLanguage(String? tag) {
  final base = tag?.trim().toLowerCase().split(RegExp('[-_]')).first ?? '';
  if (base.isEmpty || base == 'und') return null;
  if (base.length == 2) return base;
  return _threeToTwo[base];
}

/// A human name for a track, for the player's picker.
String describeTrack(String? title, String? language, int index) {
  final code = normalizeLanguage(language);
  final lang = code == null ? null : playbackLanguages[code] ?? code;
  final parts = [
    ?lang,
    if (title != null && title.trim().isNotEmpty && title != language) title,
  ];
  return parts.isEmpty ? 'Track ${index + 1}' : parts.join(' · ');
}

/// Real tracks only: media_kit also lists "auto" and "no" as pseudo-tracks.
bool isRealTrack(String id) => id != 'auto' && id != 'no';

/// What to select once a file's tracks are known.
///
/// Null means "leave the player's own choice alone", which for audio is the
/// file's default track. Applied once per file, when the track list first
/// arrives, so a choice the viewer then makes by hand is never overridden.
class TrackChoice {
  const TrackChoice({this.audio, this.subtitle});
  final AudioTrack? audio;
  final SubtitleTrack? subtitle;
}

TrackChoice chooseTracks(Tracks tracks, PlaybackPrefs prefs) {
  final audio = [for (final t in tracks.audio) if (isRealTrack(t.id)) t];
  final subs = [for (final t in tracks.subtitle) if (isRealTrack(t.id)) t];

  AudioTrack? pickedAudio;
  if (prefs.audioLanguage case final want?) {
    pickedAudio =
        audio.where((t) => normalizeLanguage(t.language) == want).firstOrNull;
  }

  final SubtitleTrack pickedSub;
  if (!prefs.subtitlesOn || subs.isEmpty) {
    pickedSub = SubtitleTrack.no();
  } else if (prefs.subtitleLanguage case final want?) {
    // No match means off, not "some other language": subtitles in a language
    // the viewer did not ask for are noise, and they can pick one by hand.
    pickedSub = subs
            .where((t) => normalizeLanguage(t.language) == want)
            .firstOrNull ??
        SubtitleTrack.no();
  } else {
    pickedSub = subs.where((t) => t.isDefault == true).firstOrNull ?? subs.first;
  }
  return TrackChoice(audio: pickedAudio, subtitle: pickedSub);
}
