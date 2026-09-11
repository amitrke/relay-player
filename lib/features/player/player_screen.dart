import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../core/theme/relay_theme.dart';
import '../../core/theme/relay_widgets.dart';
import '../accounts/plex_session.dart';

/// Playback surface for a single Plex item (§6, §10).
///
/// Phase 0 burned two probe bugs on false positives here, and both lessons are
/// built in: `player.open()` returning proves nothing (the error arrives later
/// on a separate stream), and `videoParams` arriving only means libmpv parsed a
/// header — it fires even when decoding then stalls on a black screen.
///
/// So this screen never shows "playing" off either signal. It waits for the
/// position to actually advance, and if nothing moves before [_stallTimeout] it
/// says so plainly rather than spinning forever.
class PlayerScreen extends ConsumerStatefulWidget {
  const PlayerScreen({super.key, required this.ratingKey});

  final String ratingKey;

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  static const _stallTimeout = Duration(seconds: 20);

  late final Player _player = Player();
  late final VideoController _controller = VideoController(_player);

  final _subs = <StreamSubscription<dynamic>>[];
  Timer? _stallTimer;

  String? _title;
  String? _error;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _subs.add(_player.stream.error.listen(_fail));
    _subs.add(_player.stream.position.listen(_onPosition));
    unawaited(_load());
  }

  @override
  void dispose() {
    _stallTimer?.cancel();
    for (final s in _subs) {
      unawaited(s.cancel());
    }
    _player.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final playable =
          await ref.read(plexServiceProvider).directPlay(widget.ratingKey);
      if (!mounted) return;
      setState(() => _title = playable.title);

      // Arm the stall guard before opening: a source that never yields a frame
      // must reach a stated failure, not an indefinite spinner.
      _stallTimer = Timer(_stallTimeout, () {
        if (!_started) {
          _fail('This did not start playing. The server may be busy, or the '
              'file may need transcoding, which is not supported yet.');
        }
      });

      await _player.open(Media(playable.url));
    } catch (e) {
      _fail('$e');
    }
  }

  /// The only trustworthy "it is playing" signal.
  void _onPosition(Duration position) {
    if (_started || position <= Duration.zero) return;
    _stallTimer?.cancel();
    if (mounted) setState(() => _started = true);
  }

  void _fail(Object message) {
    _stallTimer?.cancel();
    if (mounted && _error == null) setState(() => _error = '$message');
  }

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);

    return Scaffold(
      backgroundColor: t.stage,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Center(child: Video(controller: _controller, controls: null)),
          if (_error != null)
            _PlaybackError(message: _error!, title: _title)
          else if (!_started)
            Center(child: CircularProgressIndicator(color: t.accent)),
          _Controls(
            player: _player,
            title: _title,
            enabled: _started && _error == null,
          ),
        ],
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({
    required this.player,
    required this.title,
    required this.enabled,
  });

  final Player player;
  final String? title;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);

    return SafeArea(
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              Expanded(
                child: Text(
                  title ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
          ),
          const Spacer(),
          if (enabled)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: StreamBuilder<Duration>(
                stream: player.stream.position,
                builder: (context, snapshot) {
                  final position = snapshot.data ?? Duration.zero;
                  final total = player.state.duration;
                  return Column(
                    children: [
                      Row(
                        children: [
                          Text(_fmt(position),
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 12)),
                          Expanded(
                            child: Slider(
                              activeColor: t.accent,
                              inactiveColor: Colors.white24,
                              max: total.inMilliseconds
                                  .clamp(1, 1 << 31)
                                  .toDouble(),
                              value: position.inMilliseconds
                                  .clamp(0, total.inMilliseconds.clamp(1, 1 << 31))
                                  .toDouble(),
                              onChanged: (v) => player
                                  .seek(Duration(milliseconds: v.round())),
                            ),
                          ),
                          Text(_fmt(total),
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                      StreamBuilder<bool>(
                        stream: player.stream.playing,
                        builder: (context, snapshot) {
                          final playing = snapshot.data ?? false;
                          return IconButton(
                            iconSize: 44,
                            icon: Icon(
                              playing
                                  ? Icons.pause_circle_filled
                                  : Icons.play_circle_filled,
                              color: Colors.white,
                            ),
                            onPressed: player.playOrPause,
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  static String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }
}

class _PlaybackError extends StatelessWidget {
  const _PlaybackError({required this.message, this.title});

  final String message;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.white70, size: 36),
            const SizedBox(height: 16),
            if (title != null) ...[
              Text(
                title!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
            ],
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, height: 1.5),
            ),
            const SizedBox(height: 24),
            RelayButton(
              label: 'Back',
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ],
        ),
      ),
    );
  }
}
