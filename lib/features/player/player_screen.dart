import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../core/theme/relay_theme.dart';
import '../../core/theme/relay_widgets.dart';
import '../accounts/plex_session.dart';
import '../advanced_sources/xtream_controller.dart';

/// What the player was asked to play, before it is resolved to a URL.
class _Playable {
  const _Playable({required this.url, required this.title, required this.live});

  final String url;
  final String title;
  final bool live;
}

/// Playback surface (§6, §10).
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
  const PlayerScreen.plex({
    super.key,
    required String this.serverId,
    required String this.ratingKey,
  })  : accountId = null,
        streamId = null;

  /// A live channel is addressed by account and stream id, never by URL.
  ///
  /// §4 builds live URLs as `{host}/live/{username}/{password}/{id}.ts`, so the
  /// URL contains the line's password in plain text. Putting it in a route would
  /// write a credential into navigation state and anything that logs it.
  const PlayerScreen.live({
    super.key,
    required String this.accountId,
    required String this.streamId,
  })  : serverId = null,
        ratingKey = null;

  final String? serverId;
  final String? ratingKey;
  final String? accountId;
  final String? streamId;

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  /// §10 picked 10s to tell a working channel from a dead one — a real stream
  /// reached first frame in ~1.8s, so this has ample headroom. It matters more
  /// for live than for Plex: with `max_connections: 1` a channel that never
  /// yields a frame must *release* the connection or it burns the only slot.
  static const _stallTimeout = Duration(seconds: 15);

  late final Player _player = Player();
  late final VideoController _controller = VideoController(_player);

  final _subs = <StreamSubscription<dynamic>>[];
  Timer? _stallTimer;

  String? _title;
  String? _error;
  bool _started = false;
  bool _live = false;

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

  Future<_Playable> _resolve() async {
    final accountId = widget.accountId;
    if (accountId != null) {
      final accounts = ref.read(xtreamAccountsProvider);
      final account = accounts.where((a) => a.id == accountId).firstOrNull;
      if (account == null) {
        throw StateError('That line is no longer configured.');
      }
      final client = await ref.read(xtreamClientProvider(account).future);
      final channels = await ref.read(xtreamChannelsProvider(account).future);
      final channel =
          channels.where((c) => c.streamId == widget.streamId).firstOrNull;
      return _Playable(
        url: client.liveStreamUrl(widget.streamId!),
        title: channel?.name ?? 'Live',
        live: true,
      );
    }

    final playable = await plexServiceFor(ref, widget.serverId!)
        .directPlay(widget.ratingKey!);
    return _Playable(url: playable.url, title: playable.title, live: false);
  }

  Future<void> _load() async {
    try {
      final playable = await _resolve();
      if (!mounted) return;
      setState(() {
        _title = playable.title;
        _live = playable.live;
      });

      // Arm the stall guard before opening: a source that never yields a frame
      // must reach a stated failure, not an indefinite spinner.
      _stallTimer = Timer(_stallTimeout, _onStalled);

      // Stop before opening, always. §4 is explicit that with
      // `max_connections: 1` the natural open-then-stop ordering is the wrong
      // one, and fails in a way that looks like a flaky provider rather than a
      // client bug.
      await _player.stop();
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

  void _onStalled() {
    if (_started) return;
    // Release the connection rather than leaving it held. On a one-connection
    // line a dead channel would otherwise cost the user their only slot until
    // the panel times it out server-side.
    unawaited(_player.stop());
    _fail(
      _live
          ? 'This channel is not responding. Listings often outrun reality on '
              'a panel — try another, or the same one again.'
          : 'This did not start playing. The server may be busy, or the file '
              'may need transcoding, which is not supported yet.',
    );
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
            live: _live,
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
    required this.live,
    required this.enabled,
  });

  final Player player;
  final String? title;
  final bool live;
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
              if (live)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
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
              const SizedBox(width: 12),
            ],
          ),
          const Spacer(),
          if (enabled)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: StreamBuilder<Duration>(
                stream: player.stream.position,
                // Seed from the player's own state: a stream's first snapshot
                // is null until an event arrives, and falling back to a
                // constant makes the controls contradict what is on screen.
                initialData: player.state.position,
                builder: (context, snapshot) {
                  final position = snapshot.data ?? player.state.position;
                  final total = player.state.duration;
                  return Column(
                    children: [
                      // A live stream has no duration and nothing to seek to,
                      // so a scrubber would be a control that does nothing.
                      if (!live && total > Duration.zero)
                        Row(
                          children: [
                            Text(_fmt(position),
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 12)),
                            Expanded(
                              child: Slider(
                                activeColor: t.accent,
                                inactiveColor: Colors.white24,
                                max: total.inMilliseconds.toDouble(),
                                value: position.inMilliseconds
                                    .clamp(0, total.inMilliseconds)
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
                        initialData: player.state.playing,
                        builder: (context, snapshot) {
                          final playing =
                              snapshot.data ?? player.state.playing;
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
