import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../core/theme/relay_theme.dart';
import '../../core/theme/relay_widgets.dart';
import '../../data/plex/plex_service.dart';
import '../accounts/plex_session.dart';
import '../../data/local/history_store.dart';
import '../../data/xtream/xtream_account_store.dart';
import '../advanced_sources/xtream_controller.dart';
import '../favorites_history/history_controller.dart';

/// Which §4 stream path a panel item uses — live, movie, or series.
enum XtreamStreamKind { live, vod, episode }

/// What the player was asked to play, once resolved.
class _Playable {
  const _Playable({
    required this.url,
    required this.title,
    required this.live,
    this.posterUrl,
    this.historyKind,
    this.historyId,
    this.resumeFrom,
  });

  final String url;
  final String title;
  final bool live;
  final String? posterUrl;

  /// Null for live, which has no position worth remembering.
  final PlaybackKind? historyKind;
  final String? historyId;

  /// Where the *source* thinks the user got to. Plex knows this server-side,
  /// so its answer beats ours — the user may have watched on another client.
  final Duration? resumeFrom;
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
        streamId = null,
        kind = XtreamStreamKind.live;

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
        ratingKey = null,
        kind = XtreamStreamKind.live;

  /// Panel VOD. [streamId] carries the container extension (`1234.mkv`) because
  /// §4 puts it in the URL and the panel does not hand it back later.
  const PlayerScreen.vod({
    super.key,
    required String this.accountId,
    required String this.streamId,
  })  : serverId = null,
        ratingKey = null,
        kind = XtreamStreamKind.vod;

  /// A panel series episode. §4 streams these from `/series/...`, a different
  /// path from films, so the two cannot share one route.
  const PlayerScreen.episode({
    super.key,
    required String this.accountId,
    required String this.streamId,
  })  : serverId = null,
        ratingKey = null,
        kind = XtreamStreamKind.episode;

  final String? serverId;
  final String? ratingKey;
  final String? accountId;
  final String? streamId;
  final XtreamStreamKind kind;

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

  _Playable? _playable;
  Timer? _progressTimer;

  // Captured while the widget is alive. `dispose` still needs to write the
  // final position, and reading a Riverpod ref during disposal throws — so the
  // last write would be the one that crashes rather than the one that saves.
  HistoryController? _history;
  PlexService? _plexService;

  /// Plex asks for roughly this cadence, and it doubles as how often local
  /// history is written — often enough that a crash loses seconds, rare enough
  /// that it is not a write per frame.
  static const _progressInterval = Duration(seconds: 10);

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
    _progressTimer?.cancel();
    // Record where they actually got to before tearing down. Without this the
    // last up-to-ten-seconds is lost on every exit, which is exactly the moment
    // the position matters most.
    _recordProgress(state: 'stopped');
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

      if (widget.kind != XtreamStreamKind.live) {
        final raw = widget.streamId!;
        final dot = raw.lastIndexOf('.');
        final id = dot == -1 ? raw : raw.substring(0, dot);
        final ext = dot == -1 ? 'mp4' : raw.substring(dot + 1);

        if (widget.kind == XtreamStreamKind.episode) {
          return _Playable(
            url: client.seriesStreamUrl(id, ext),
            title: 'Episode',
            live: false,
            historyKind: PlaybackKind.xtreamEpisode,
            historyId: raw,
          );
        }

        final items = await ref
            .read(xtreamCatalogProvider((account, XtreamCatalogue.vod)).future);
        final match = items.where((i) => i.id == raw).firstOrNull;
        return _Playable(
          url: client.vodStreamUrl(id, ext),
          title: match?.title ?? 'Film',
          live: false,
          posterUrl: match?.posterUrl,
          historyKind: PlaybackKind.xtreamVod,
          historyId: raw,
        );
      }

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
    return _Playable(
      url: playable.url,
      title: playable.title,
      live: false,
      posterUrl: playable.posterUrl,
      historyKind: PlaybackKind.plex,
      historyId: widget.ratingKey,
      resumeFrom: playable.resumeFrom,
    );
  }

  Future<void> _load() async {
    try {
      final playable = await _resolve();
      if (!mounted) return;
      _history = ref.read(historyProvider.notifier);
      if (widget.serverId != null) {
        _plexService = plexServiceFor(ref, widget.serverId!);
      }
      setState(() {
        _playable = playable;
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

      final resume = _resumePoint(playable);
      if (resume != null) {
        // Seek after opening: libmpv needs the stream long enough to know it is
        // seekable, and a seek issued before that is silently dropped.
        await _player.stream.duration.firstWhere((d) => d > Duration.zero);
        await _player.seek(resume);
      }
      _progressTimer =
          Timer.periodic(_progressInterval, (_) => _recordProgress());
    } catch (e) {
      _fail('$e');
    }
  }

  /// Where to pick up, preferring the source's own answer over ours.
  Duration? _resumePoint(_Playable playable) {
    if (playable.live || playable.historyKind == null) return null;
    final fromSource = playable.resumeFrom;
    if (fromSource != null && fromSource > const Duration(seconds: 60)) {
      return fromSource;
    }
    final local = ref
        .read(historyProvider.notifier)
        .find(playable.historyKind!, _sourceIdOf(playable), playable.historyId!);
    return (local != null && local.isResumable) ? local.position : null;
  }

  String _sourceIdOf(_Playable playable) =>
      widget.accountId ?? widget.serverId ?? '';

  /// Writes progress locally, and tells Plex when the item is theirs.
  void _recordProgress({String state = 'playing'}) {
    final playable = _playable;
    final kind = playable?.historyKind;
    if (playable == null || kind == null || !_started) return;

    final position = _player.state.position;
    final duration = _player.state.duration;
    if (duration <= Duration.zero) return;

    unawaited(_history?.record(
          HistoryItem(
            kind: kind,
            sourceId: _sourceIdOf(playable),
            itemId: playable.historyId!,
            title: playable.title,
            posterUrl: playable.posterUrl,
            position: position,
            duration: duration,
            lastWatchedAt: DateTime.now(),
          ),
        ));

    // Best effort: a server that has gone away must not break playback that is
    // otherwise fine.
    if (kind == PlaybackKind.plex) {
      unawaited(
        _plexService
            ?.reportProgress(
              ratingKey: playable.historyId!,
              state: state,
              position: position,
              duration: duration,
            )
            .catchError((_) {}),
      );
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
