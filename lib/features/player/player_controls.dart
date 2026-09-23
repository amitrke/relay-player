import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';

import '../../core/theme/relay_theme.dart';
import '../../core/theme/relay_widgets.dart';
import 'playback_prefs.dart';

/// The slice of a player the controls need.
///
/// An interface rather than media_kit's `Player` directly so the controls can
/// be driven in a widget test. Everything that went wrong in #10 was key and
/// focus behaviour, which a test can pin down, and none of it needs libmpv.
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

  /// 0 to 100, media_kit's scale. Used only for ducking (§10).
  Future<void> setVolume(double percent);

  /// Audio and subtitle tracks, including media_kit's "auto" and "no"
  /// pseudo-tracks (see `isRealTrack`).
  Stream<Tracks> get tracksStream;
  Tracks get tracks;

  /// What is selected now.
  Stream<Track> get trackStream;
  Track get track;
  Future<void> setAudioTrack(AudioTrack track);
  Future<void> setSubtitleTrack(SubtitleTrack track);
}

class MediaKitTransport implements PlayerTransport {
  MediaKitTransport(this._player);

  final Player _player;

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
  Stream<Tracks> get tracksStream => _player.stream.tracks;
  @override
  Tracks get tracks => _player.state.tracks;
  @override
  Stream<Track> get trackStream => _player.stream.track;
  @override
  Track get track => _player.state.track;
  @override
  Future<void> setAudioTrack(AudioTrack track) => _player.setAudioTrack(track);
  @override
  Future<void> setSubtitleTrack(SubtitleTrack track) =>
      _player.setSubtitleTrack(track);
}

/// Icons and text drawn over the picture.
///
/// The one deliberate literal colour in this file. The chrome sits on the
/// video, not on a themed surface, so it cannot take [RelayTokens.ink] - in
/// Daylight that is near-black, over a picture that is usually dark. The scrims
/// behind it are [RelayTokens.stage], so legibility still comes from a token.
const _onVideo = Colors.white;
const _onVideoDim = Colors.white70;

/// Player chrome: title bar, seek bar, transport row, and the rules for when
/// they are on screen (#10).
///
/// **Visibility.** Hidden after [hideAfter] of no input while playing. Never
/// hidden while paused, before the first frame, or on an error - those are
/// exactly the moments the viewer needs the controls.
///
/// **Focus.** Hiding the chrome first moves focus onto this widget's own node,
/// outside the controls. #10 asked for the chrome to never hide while a control
/// holds focus; taken literally that means it never hides on a TV, where
/// something always holds focus. What that rule protects against is focus
/// stranded on an invisible widget (§11 defect 3), and taking focus off the
/// controls before hiding them prevents that directly.
///
/// **The first key only wakes.** While hidden, focus sits on this widget, so
/// the next D-pad press arrives here rather than at a control. It reveals the
/// chrome, focuses play/pause, and is consumed, so it never also seeks or
/// toggles playback. Media keys are the exception: they name their action.
class PlayerChrome extends StatefulWidget {
  const PlayerChrome({
    super.key,
    required this.transport,
    required this.title,
    required this.live,
    required this.enabled,
    required this.onBack,
    required this.child,
    this.hideAfter = const Duration(seconds: 4),
    this.skip = const Duration(seconds: 10),
  });

  final PlayerTransport transport;
  final String? title;
  final bool live;

  /// True once playback has actually started and has not failed. Until then
  /// only the title bar is shown and nothing auto-hides.
  final bool enabled;

  final VoidCallback onBack;

  /// The video and anything layered on it (spinner, error).
  final Widget child;

  final Duration hideAfter;

  /// The skip buttons' step and the seek bar's base D-pad step. From the
  /// Playback setting; one of 5, 10 or 30 seconds.
  final Duration skip;

  @override
  State<PlayerChrome> createState() => _PlayerChromeState();
}

class _PlayerChromeState extends State<PlayerChrome> {
  final _root = FocusNode(debugLabel: 'player-root');
  final _playButton = FocusNode(debugLabel: 'player-play');
  final _backButton = FocusNode(debugLabel: 'player-back');

  bool _visible = true;
  Timer? _hideTimer;
  StreamSubscription<bool>? _playingSub;

  /// Where a run of skips is heading. Seeks are asynchronous and the position
  /// stream lags them, so three quick presses of +10 s read the same stale
  /// position three times and land at +10 s. Chaining from the last target
  /// makes them add up.
  Duration? _skipTarget;
  Timer? _skipReset;

  @override
  void initState() {
    super.initState();
    _playingSub = widget.transport.playingStream.listen(_onPlaying);
    // Observes every key, including the ones a focused control consumes (the
    // seek bar eats Left/Right), so that using the controls keeps them up.
    // Returns false: it watches, it never handles.
    HardwareKeyboard.instance.addHandler(_onAnyKey);
    _scheduleHide();
  }

  @override
  void didUpdateWidget(PlayerChrome old) {
    super.didUpdateWidget(old);
    if (old.enabled != widget.enabled) _scheduleHide();
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onAnyKey);
    unawaited(_playingSub?.cancel());
    _hideTimer?.cancel();
    _skipReset?.cancel();
    _root.dispose();
    _playButton.dispose();
    _backButton.dispose();
    super.dispose();
  }

  bool get _canHide => widget.enabled && widget.transport.playing;

  void _onPlaying(bool playing) {
    if (!mounted) return;
    if (playing) {
      _scheduleHide();
    } else {
      _show();
    }
  }

  bool _onAnyKey(KeyEvent event) {
    if (_visible) _scheduleHide();
    return false;
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    if (_canHide) _hideTimer = Timer(widget.hideAfter, _hide);
  }

  void _hide() {
    if (!mounted || !_canHide) return;
    // Take focus out of the controls before they go, so the next press lands
    // on [_root] and wakes the chrome instead of acting on a hidden control.
    _root.requestFocus();
    setState(() => _visible = false);
  }

  void _show({bool focusControls = false}) {
    if (!mounted) return;
    if (!_visible) setState(() => _visible = true);
    if (focusControls) {
      // After the frame: the controls are under ExcludeFocus while hidden, and
      // a node cannot take focus until that has been lifted.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        (widget.enabled ? _playButton : _backButton).requestFocus();
      });
    }
    _scheduleHide();
  }

  void _toggleFromTap() {
    if (_visible && _canHide) {
      _hideTimer?.cancel();
      _hide();
    } else {
      _show();
    }
  }

  void _skip(Duration delta) {
    if (widget.live || !widget.enabled) return;
    final total = widget.transport.duration;
    if (total <= Duration.zero) return;
    final from = _skipTarget ?? widget.transport.position;
    final to = _clamp(from + delta, total);
    _skipTarget = to;
    _skipReset?.cancel();
    _skipReset = Timer(const Duration(seconds: 1), () => _skipTarget = null);
    unawaited(widget.transport.seek(to));
    _show();
  }

  static final _wakeKeys = {
    LogicalKeyboardKey.arrowUp,
    LogicalKeyboardKey.arrowDown,
    LogicalKeyboardKey.arrowLeft,
    LogicalKeyboardKey.arrowRight,
    LogicalKeyboardKey.select,
    LogicalKeyboardKey.enter,
    LogicalKeyboardKey.numpadEnter,
    LogicalKeyboardKey.space,
    LogicalKeyboardKey.gameButtonA,
  };

  /// The audio and subtitle picker. The hide timer is held while it is open:
  /// hiding pulls focus onto [_root], which sits under the sheet, and would
  /// take it out of the sheet mid-choice.
  Future<void> _showTracks() async {
    _hideTimer?.cancel();
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: RelayTheme.of(context).surface,
      isScrollControlled: true,
      builder: (_) => TrackSheet(transport: widget.transport),
    );
    if (mounted) _scheduleHide();
  }

  /// Sees keys the focused control did not handle, and every key while hidden.
  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;

    // Media keys act whether or not the chrome is up. Many remotes send these
    // directly, and a dedicated play/pause button that first "wakes the UI"
    // would read as a dropped press.
    if (event is KeyDownEvent) {
      if (key == LogicalKeyboardKey.mediaPlayPause) {
        unawaited(widget.transport.playOrPause());
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.mediaPlay) {
        unawaited(widget.transport.play());
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.mediaPause) {
        unawaited(widget.transport.pause());
        return KeyEventResult.handled;
      }
    }
    if (key == LogicalKeyboardKey.mediaFastForward) {
      _skip(widget.skip);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.mediaRewind) {
      _skip(-widget.skip);
      return KeyEventResult.handled;
    }

    // Also when visible but nothing inside holds focus, which is the state on
    // arrival: directional traversal from a full-screen node has no sensible
    // "next", so hand the press to play/pause instead of guessing.
    if (_wakeKeys.contains(key) && (!_visible || _root.hasPrimaryFocus)) {
      _show(focusControls: true);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);
    final total = widget.transport.duration;
    final seekable = !widget.live && total > Duration.zero;

    return Focus(
      focusNode: _root,
      autofocus: true,
      onKeyEvent: _onKey,
      child: MouseRegion(
        // Desktop: the pointer hides with the chrome and any movement wakes it.
        cursor: _visible ? MouseCursor.defer : SystemMouseCursors.none,
        onHover: (_) => _show(),
        child: Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _toggleFromTap,
              child: widget.child,
            ),
            IgnorePointer(
              ignoring: !_visible,
              child: ExcludeFocus(
                excluding: !_visible,
                child: AnimatedOpacity(
                  opacity: _visible ? 1 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Column(
                    children: [
                      _Scrim(
                        top: true,
                        color: t.stage,
                        child: _TitleBar(
                          title: widget.title,
                          live: widget.live,
                          backFocus: _backButton,
                          onBack: widget.onBack,
                        ),
                      ),
                      const Spacer(),
                      if (widget.enabled)
                        _Scrim(
                          top: false,
                          color: t.stage,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // A live stream has no duration and nothing to
                                // seek to, and §4 makes a seek on a live line
                                // anything but free: no scrubber, no skips.
                                if (seekable)
                                  StreamBuilder<Duration>(
                                    stream: widget.transport.positionStream,
                                    // Seed from the player's own state: a
                                    // stream's first snapshot is null until an
                                    // event arrives.
                                    initialData: widget.transport.position,
                                    builder: (context, snap) => SeekBar(
                                      step: widget.skip,
                                      position: snap.data ??
                                          widget.transport.position,
                                      duration: widget.transport.duration,
                                      onSeek: (to) {
                                        _skipTarget = null;
                                        unawaited(widget.transport.seek(to));
                                      },
                                    ),
                                  ),
                                _TransportRow(
                                  transport: widget.transport,
                                  seekable: seekable,
                                  playFocus: _playButton,
                                  skip: widget.skip,
                                  onSkip: _skip,
                                  onTracks: _showTracks,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Duration _clamp(Duration d, Duration total) =>
    d < Duration.zero ? Duration.zero : (d > total ? total : d);

String formatPlaybackTime(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return h > 0 ? '$h:$m:$s' : '$m:$s';
}

/// A gradient from [color] so white chrome stays legible over a bright frame.
class _Scrim extends StatelessWidget {
  const _Scrim({required this.top, required this.color, required this.child});

  final bool top;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: top ? Alignment.topCenter : Alignment.bottomCenter,
          end: top ? Alignment.bottomCenter : Alignment.topCenter,
          colors: [color.withValues(alpha: 0.75), color.withValues(alpha: 0)],
        ),
      ),
      child: SafeArea(top: top, bottom: !top, child: child),
    );
  }
}

class _TitleBar extends StatelessWidget {
  const _TitleBar({
    required this.title,
    required this.live,
    required this.backFocus,
    required this.onBack,
  });

  final String? title;
  final bool live;
  final FocusNode backFocus;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 12, 24),
      child: Row(
        children: [
          _ChromeButton(
            icon: Icons.arrow_back,
            tooltip: 'Back',
            focusNode: backFocus,
            onPressed: onBack,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              title ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _onVideo,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (live)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: t.accent,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                'LIVE',
                style: TextStyle(
                  color: t.accentInk,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TransportRow extends StatelessWidget {
  const _TransportRow({
    required this.transport,
    required this.seekable,
    required this.playFocus,
    required this.skip,
    required this.onSkip,
    required this.onTracks,
  });

  final PlayerTransport transport;
  final bool seekable;
  final FocusNode playFocus;
  final Duration skip;
  final void Function(Duration) onSkip;
  final VoidCallback onTracks;

  static (IconData, IconData) _skipIcons(int seconds) => switch (seconds) {
        5 => (Icons.replay_5, Icons.forward_5),
        30 => (Icons.replay_30, Icons.forward_30),
        _ => (Icons.replay_10, Icons.forward_10),
      };

  @override
  Widget build(BuildContext context) {
    final (back, forward) = _skipIcons(skip.inSeconds);
    return Stack(
      alignment: Alignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (seekable)
              _ChromeButton(
                icon: back,
                tooltip: 'Back ${skip.inSeconds} seconds',
                onPressed: () => onSkip(-skip),
              ),
            const SizedBox(width: 16),
            StreamBuilder<bool>(
              stream: transport.playingStream,
              initialData: transport.playing,
              builder: (context, snap) {
                final playing = snap.data ?? transport.playing;
                return _ChromeButton(
                  icon: playing
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_filled,
                  tooltip: playing ? 'Pause' : 'Play',
                  size: 48,
                  focusNode: playFocus,
                  onPressed: transport.playOrPause,
                );
              },
            ),
            const SizedBox(width: 16),
            if (seekable)
              _ChromeButton(
                icon: forward,
                tooltip: 'Forward ${skip.inSeconds} seconds',
                onPressed: () => onSkip(skip),
              ),
          ],
        ),
        // Off to the side so play/pause stays centred. Only when there is a
        // choice to make: one audio track and no subtitles has nothing to pick.
        Align(
          alignment: Alignment.centerRight,
          child: StreamBuilder<Tracks>(
            stream: transport.tracksStream,
            initialData: transport.tracks,
            builder: (context, snap) {
              final tracks = snap.data ?? transport.tracks;
              final audio = tracks.audio.where((t) => isRealTrack(t.id));
              final subs = tracks.subtitle.where((t) => isRealTrack(t.id));
              if (audio.length < 2 && subs.isEmpty) {
                return const SizedBox.shrink();
              }
              return _ChromeButton(
                icon: Icons.subtitles_outlined,
                tooltip: 'Audio and subtitles',
                onPressed: onTracks,
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Audio and subtitle tracks for the file that is playing (§12 screen 6).
///
/// Drawn on the theme's surface rather than over the video, so it uses the
/// theme's ink, not the chrome's white. Rows are [RelayTappable] so a remote
/// can reach them with a visible ring.
class TrackSheet extends StatelessWidget {
  const TrackSheet({super.key, required this.transport});

  final PlayerTransport transport;

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);
    final f = RelayLayout.of(context);

    return StreamBuilder<Track>(
      stream: transport.trackStream,
      initialData: transport.track,
      builder: (context, snap) {
        final current = snap.data ?? transport.track;
        final tracks = transport.tracks;
        final audio = [
          for (final a in tracks.audio)
            if (isRealTrack(a.id)) a,
        ];
        final subs = [
          for (final s in tracks.subtitle)
            if (isRealTrack(s.id)) s,
        ];
        final subsOff = !isRealTrack(current.subtitle.id);
        // Focus starts on what is selected in the first section shown.
        final audioFirst = audio.length > 1;

        Widget header(String label) => Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
              child: Text(
                label.toUpperCase(),
                style: TextStyle(
                  color: t.inkDim,
                  fontSize: RelayLayout.bodySize(f) - 2,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
            );

        Widget row(
          String label,
          bool selected,
          VoidCallback onTap, {
          bool autofocus = false,
        }) =>
            RelayTappable(
              borderRadius: 10,
              autofocus: autofocus,
              onTap: () {
                onTap();
                Navigator.of(context).pop();
              },
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          color: t.ink,
                          fontSize: RelayLayout.bodySize(f) + 1,
                        ),
                      ),
                    ),
                    if (selected) Icon(Icons.check, color: t.accent),
                  ],
                ),
              ),
            );

        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.8,
            ),
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.all(12),
              children: [
                if (audioFirst) ...[
                  header('Audio'),
                  for (final (i, a) in audio.indexed)
                    row(
                      describeTrack(a.title, a.language, i),
                      a.id == current.audio.id,
                      () => transport.setAudioTrack(a),
                      autofocus: a.id == current.audio.id,
                    ),
                ],
                if (subs.isNotEmpty) ...[
                  header('Subtitles'),
                  row(
                    'Off',
                    subsOff,
                    () => transport.setSubtitleTrack(SubtitleTrack.no()),
                    autofocus: !audioFirst && subsOff,
                  ),
                  for (final (i, s) in subs.indexed)
                    row(
                      describeTrack(s.title, s.language, i),
                      s.id == current.subtitle.id,
                      () => transport.setSubtitleTrack(s),
                      autofocus: !audioFirst && s.id == current.subtitle.id,
                    ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

/// An icon button with the standard focus ring.
///
/// Not `IconButton`: its focus state is Material's tint, which MANUAL_TESTING
/// §6 found invisible across a room. The player had no visible focus at all
/// before this, which made every other #10 symptom harder to see on a TV.
class _ChromeButton extends StatelessWidget {
  const _ChromeButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.focusNode,
    this.size = 28,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final FocusNode? focusNode;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: RelayTappable(
        focusNode: focusNode,
        borderRadius: 40,
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: size, color: _onVideo),
        ),
      ),
    );
  }
}

/// A seek bar that moves in time, not in fractions of the film (#10).
///
/// Replaces a Material `Slider`, which got two things wrong for a remote. With
/// no `divisions`, its keyboard step is a fraction of the range - minutes per
/// press on a feature film. And it claims Up and Down as well as Left and
/// Right, so Up seeked forward instead of leaving the bar.
///
/// Here Left/Right step [step], accelerating while held; Up and
/// Down are ignored so focus traversal gets them. A held key moves only the
/// displayed target; the seek is issued once, on release. A network source
/// asked to seek twenty times a second does all twenty.
class SeekBar extends StatefulWidget {
  const SeekBar({
    super.key,
    required this.position,
    required this.duration,
    required this.onSeek,
    this.step = const Duration(seconds: 10),
  });

  final Duration position;
  final Duration duration;
  final void Function(Duration) onSeek;

  /// The first step of a press; the Playback setting's skip length.
  final Duration step;

  /// The step for the [repeats]th auto-repeat of a held key. Android TV repeats
  /// at roughly 20 Hz after a half-second delay, so this is about half a second
  /// at 10 s, then 30 s, then a minute per step.
  static Duration stepFor(
    int repeats, {
    Duration base = const Duration(seconds: 10),
  }) {
    if (repeats < 10) return base;
    if (repeats < 25) return const Duration(seconds: 30);
    return const Duration(seconds: 60);
  }

  @override
  State<SeekBar> createState() => _SeekBarState();
}

class _SeekBarState extends State<SeekBar> {
  bool _focused = false;

  /// Where the viewer is taking it. Shown instead of [SeekBar.position] from
  /// the first press until the player has had a moment to arrive, so the thumb
  /// does not snap back to the old position mid-scrub.
  Duration? _target;
  bool _committed = true;
  int _repeats = 0;
  Timer? _settle;

  @override
  void dispose() {
    _settle?.cancel();
    super.dispose();
  }

  Duration get _shown => _target ?? widget.position;

  void _move(Duration to) {
    _settle?.cancel();
    setState(() {
      _target = _clamp(to, widget.duration);
      _committed = false;
    });
  }

  void _commit() {
    final target = _target;
    if (target == null || _committed) return;
    _committed = true;
    widget.onSeek(target);
    _settle?.cancel();
    _settle = Timer(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _target = null);
    });
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    final key = event.logicalKey;
    final sign = key == LogicalKeyboardKey.arrowRight
        ? 1
        : key == LogicalKeyboardKey.arrowLeft
            ? -1
            : 0;
    if (sign == 0) return KeyEventResult.ignored;

    if (event is KeyUpEvent) {
      _commit();
      return KeyEventResult.handled;
    }
    _repeats = event is KeyRepeatEvent ? _repeats + 1 : 0;
    _move(_shown + SeekBar.stepFor(_repeats, base: widget.step) * sign);
    return KeyEventResult.handled;
  }

  void _fromPointer(Offset local, double width) {
    if (width <= 0) return;
    final f = (local.dx / width).clamp(0.0, 1.0);
    _move(widget.duration * f);
  }

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);
    final total = widget.duration.inMilliseconds;
    final frac = total <= 0 ? 0.0 : _shown.inMilliseconds / total;
    const label = TextStyle(color: _onVideoDim, fontSize: 12);

    return Row(
      children: [
        Text(formatPlaybackTime(_shown), style: label),
        const SizedBox(width: 12),
        Expanded(
          child: Focus(
            onKeyEvent: _onKey,
            onFocusChange: (v) {
              // Leaving mid-scrub must not throw the target away.
              if (!v) _commit();
              setState(() => _focused = v);
            },
            child: LayoutBuilder(
              builder: (context, box) => GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (d) => _fromPointer(d.localPosition, box.maxWidth),
                onTapUp: (_) => _commit(),
                onHorizontalDragStart: (d) =>
                    _fromPointer(d.localPosition, box.maxWidth),
                onHorizontalDragUpdate: (d) =>
                    _fromPointer(d.localPosition, box.maxWidth),
                onHorizontalDragEnd: (_) => _commit(),
                child: RelayFocusRing(
                  focused: _focused,
                  borderRadius: BorderRadius.circular(20),
                  child: SizedBox(
                    height: 32,
                    child: CustomPaint(
                      painter: _SeekPainter(
                        fraction: frac.clamp(0.0, 1.0),
                        focused: _focused,
                        accent: t.accent,
                        track: _onVideo.withValues(alpha: 0.24),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(formatPlaybackTime(widget.duration), style: label),
      ],
    );
  }
}

class _SeekPainter extends CustomPainter {
  _SeekPainter({
    required this.fraction,
    required this.focused,
    required this.accent,
    required this.track,
  });

  final double fraction;
  final bool focused;
  final Color accent;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    const inset = 14.0;
    final y = size.height / 2;
    final w = size.width - inset * 2;
    final x = inset + w * fraction;
    final stroke = Paint()
      ..strokeWidth = focused ? 6 : 4
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
        Offset(inset, y), Offset(inset + w, y), stroke..color = track);
    canvas.drawLine(Offset(inset, y), Offset(x, y), stroke..color = accent);
    canvas.drawCircle(
        Offset(x, y), focused ? 9 : 6, Paint()..color = accent);
  }

  @override
  bool shouldRepaint(_SeekPainter old) =>
      old.fraction != fraction ||
      old.focused != focused ||
      old.accent != accent ||
      old.track != track;
}
