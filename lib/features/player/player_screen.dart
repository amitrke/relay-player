import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../core/theme/relay_theme.dart';
import '../../core/theme/relay_widgets.dart';
import '../../data/plex/plex_service.dart';
import '../accounts/plex_session.dart';
import '../../data/local/history_store.dart';
import '../../data/xtream/xtream_account_store.dart';
import '../advanced_sources/xtream_controller.dart';
import '../../data/filesystem/loopback_bridge.dart';
import '../../data/filesystem/saf_folder_source.dart';
import '../local_network/local_network_tab.dart';
import '../local_network/smb_controller.dart';
import '../downloads/downloads_controller.dart';
import '../favorites_history/history_controller.dart';
import '../favorites_history/resume_entries.dart';
import 'playback_focus.dart';
import 'playback_prefs.dart';
import 'player_controls.dart';
import 'player_errors.dart';
import 'video_output.dart';

/// Which §4 stream path a panel item uses — live, movie, or series.
enum XtreamStreamKind { live, vod, episode }

/// What the player was asked to play, once resolved.
class _Playable {
  const _Playable({
    required this.url,
    required this.title,
    required this.live,
    this.posterRef,
    this.historyKind,
    this.historyId,
    this.resumeFrom,
    this.episode,
  });

  final String url;
  final String title;
  final bool live;

  /// Artwork as history will store it: an absolute URL for a panel, and the
  /// unsigned path for Plex (§3 — the signed form carries `X-Plex-Token`).
  /// Nothing else reads this; it exists to reach [HistoryItem.poster].
  final String? posterRef;

  /// Null for live, which has no position worth remembering.
  final PlaybackKind? historyKind;
  final String? historyId;

  /// Where the *source* thinks the user got to. Plex knows this server-side,
  /// so its answer beats ours — the user may have watched on another client.
  final Duration? resumeFrom;

  /// Plex only; see [HistoryItem.episode].
  final bool? episode;
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
        kind = XtreamStreamKind.live,
        assetId = null,
        safUri = null,
        safName = null,
        safSize = 0,
        smbShareId = null,
        smbPath = null;

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
        kind = XtreamStreamKind.live,
        assetId = null,
        safUri = null,
        safName = null,
        safSize = 0,
        smbShareId = null,
        smbPath = null;

  /// Panel VOD. [streamId] carries the container extension (`1234.mkv`) because
  /// §4 puts it in the URL and the panel does not hand it back later.
  const PlayerScreen.vod({
    super.key,
    required String this.accountId,
    required String this.streamId,
  })  : serverId = null,
        ratingKey = null,
        kind = XtreamStreamKind.vod,
        assetId = null,
        safUri = null,
        safName = null,
        safSize = 0,
        smbShareId = null,
        smbPath = null;

  /// A panel series episode. §4 streams these from `/series/...`, a different
  /// path from films, so the two cannot share one route.
  const PlayerScreen.episode({
    super.key,
    required String this.accountId,
    required String this.streamId,
  })  : serverId = null,
        ratingKey = null,
        kind = XtreamStreamKind.episode,
        assetId = null,
        safUri = null,
        safName = null,
        safSize = 0,
        smbShareId = null,
        smbPath = null;

  /// A video on this device, addressed by its MediaStore id.
  ///
  /// The id is resolved to a path at play time rather than stored: MediaStore
  /// hands back an id, not a path, and the file may not be materialised locally
  /// until it is asked for.
  const PlayerScreen.device({super.key, required String this.assetId})
      : serverId = null,
        ratingKey = null,
        accountId = null,
        streamId = null,
        safUri = null,
        safName = null,
        safSize = 0,
        smbShareId = null,
        smbPath = null,
        kind = XtreamStreamKind.live;

  /// A file inside a folder the user granted through SAF.
  /// A file on a network share. Like live TV, addressed by id and path rather
  /// than by anything containing the credential.
  const PlayerScreen.smb({
    super.key,
    required String this.smbShareId,
    required String this.smbPath,
  })  : serverId = null,
        ratingKey = null,
        accountId = null,
        streamId = null,
        assetId = null,
        safUri = null,
        safName = null,
        safSize = 0,
        kind = XtreamStreamKind.live;

  const PlayerScreen.saf({
    super.key,
    required String this.safUri,
    String? name,
    int size = 0,
  })  : safName = name,
        safSize = size,
        smbShareId = null,
        smbPath = null,
        serverId = null,
        ratingKey = null,
        accountId = null,
        streamId = null,
        assetId = null,
        kind = XtreamStreamKind.live;

  final String? serverId;
  final String? ratingKey;
  final String? accountId;
  final String? streamId;
  final String? assetId;

  /// A `content://` URI from a SAF-granted folder.
  final String? safUri;
  final String? safName;

  /// Known up front from the directory listing, and required: the bridge has to
  /// answer `Content-Length` and ranges before anything is read.
  final int safSize;

  /// A file on a configured SMB share, addressed by share id and path.
  final String? smbShareId;
  final String? smbPath;

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

  /// How long a live picture may sit still before it is treated as frozen. The
  /// position clock is the signal for the same reason it is at startup: a frozen
  /// frame still has a playing mpv behind it, so no error ever arrives.
  static const _freezeTimeout = Duration(seconds: 10);

  /// Consecutive reconnects before giving up and showing the error. Each waits
  /// longer than the last (2s, 4s, 6s), so a panel that is briefly overloaded
  /// gets room without a dead channel spinning forever.
  static const _maxReconnects = 3;

  /// Playing this long after a reconnect counts it as having worked, so a
  /// channel that drops once an hour never exhausts its budget.
  static const _stableAfter = Duration(seconds: 30);

  /// Player routes that had to fall back to compatible output this session, so
  /// opening the same title again goes straight there instead of failing over
  /// a second time. Memory only: a TV update can bring the decoder it lacked.
  static final _compatibleRoutes = <String>{};

  late final Player _player = Player();

  /// Decided on first build, when the route is known; see [VideoOutput].
  late final VideoOutput _output = _compatibleRoutes.contains(_route)
      ? VideoOutput.compatible
      : defaultVideoOutput();
  late final VideoController _controller = VideoController(
    _player,
    configuration: videoConfigurationFor(_output),
  );

  /// Every player is a route (app_router.dart), and the location is what is
  /// pushed again to reopen it.
  String get _route => GoRouterState.of(context).uri.toString();
  bool _fellBack = false;
  late final PlayerTransport _transport = MediaKitTransport(_player);

  final _subs = <StreamSubscription<dynamic>>[];
  Timer? _stallTimer;
  Timer? _freezeWatch;
  Timer? _reconnectTimer;
  DateTime _lastAdvance = DateTime.now();
  DateTime _playingSince = DateTime.now();
  Duration _lastPosition = Duration.zero;
  int _reconnects = 0;

  String? _title;
  String? _error;
  bool _started = false;
  bool _live = false;

  /// A live stream stopped because the app was hidden or lost audio focus
  /// (§10). Shown as its own state with *Rejoin*, not as an error: nothing
  /// failed, the connection was handed back on purpose.
  bool _released = false;

  /// Whether the Playback and Subtitles preferences have been applied to the
  /// file now open. Once only: after that the track is the viewer's to change
  /// in the picker, and re-applying on a later track event would undo them.
  bool _tracksApplied = false;

  late final PlaybackFocusPolicy _focus = PlaybackFocusPolicy(
    transport: _transport,
    isLive: () => _live,
    releaseLive: _releaseLive,
  );
  AudioFocusBinding? _audioFocus;
  AppLifecycleListener? _lifecycle;

  _Playable? _playable;
  Timer? _progressTimer;

  // Captured while the widget is alive. `dispose` still needs to write the
  // final position, and reading a Riverpod ref during disposal throws — so the
  // last write would be the one that crashes rather than the one that saves.
  HistoryController? _history;
  PlexService? _plexService;

  /// For refreshing Plex's On Deck once playback ends. Captured for the same
  /// reason as [_history]: `ref` is unusable in `dispose`.
  ProviderContainer? _container;

  /// Torn down with the player. Left running it would keep a port open and hold
  /// the SAF read handle for a file nobody is watching.
  LoopbackBridge? _bridge;

  /// Plex asks for roughly this cadence, and it doubles as how often local
  /// history is written — often enough that a crash loses seconds, rare enough
  /// that it is not a write per frame.
  static const _progressInterval = Duration(seconds: 10);

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    // Not straight to _fail: media_kit forwards mpv *log lines* here, and some
    // of them mean mpv carried on without something (player_errors.dart).
    _subs.add(_player.stream.error.listen(_onPlayerError));
    _subs.add(_player.stream.position.listen(_onPosition));
    _subs.add(_player.stream.tracks.listen(_onTracks));
    // Focus is asked for whenever playback starts, not once: after a permanent
    // loss, pressing play is the viewer taking it back from the other app.
    _subs.add(_player.stream.playing.listen((playing) {
      if (playing) unawaited(_audioFocus?.request());
    }));
    // `hidden`, not `inactive`: pulling down the notification shade is
    // inactive, and must not stop a film (§10).
    _lifecycle = AppLifecycleListener(
      onHide: () => _focus.handle(FocusEvent.hidden),
    );
    unawaited(_attachAudioFocus());
    unawaited(_load());
  }

  Future<void> _attachAudioFocus() async {
    final binding = await AudioFocusBinding.attach(_focus.handle);
    if (!mounted) {
      unawaited(binding?.dispose());
      return;
    }
    _audioFocus = binding;
    if (_player.state.playing) unawaited(binding?.request());
  }

  void _onTracks(Tracks tracks) {
    if (_tracksApplied || !mounted) return;
    // media_kit lists its "auto" and "no" pseudo-tracks before the file is
    // parsed; wait for a real one so there is something to choose between.
    if (!tracks.audio.any((t) => isRealTrack(t.id))) return;
    _tracksApplied = true;
    final choice = chooseTracks(tracks, ref.read(playbackPrefsProvider));
    if (choice.audio case final audio?) unawaited(_player.setAudioTrack(audio));
    if (choice.subtitle case final sub?) {
      unawaited(_player.setSubtitleTrack(sub));
    }
  }

  void _releaseLive() {
    if (_released || !mounted) return;
    _stallTimer?.cancel();
    _progressTimer?.cancel();
    _freezeWatch?.cancel();
    _reconnectTimer?.cancel();
    unawaited(_player.stop());
    setState(() {
      _released = true;
      _started = false;
    });
  }

  void _rejoin() {
    _reconnects = 0;
    setState(() {
      _released = false;
      _error = null;
    });
    unawaited(_load());
  }

  @override
  void dispose() {
    _lifecycle?.dispose();
    unawaited(_audioFocus?.dispose());
    _stallTimer?.cancel();
    _freezeWatch?.cancel();
    _reconnectTimer?.cancel();
    _progressTimer?.cancel();
    // Record where they actually got to before tearing down. Without this the
    // last up-to-ten-seconds is lost on every exit, which is exactly the moment
    // the position matters most.
    _recordProgress(state: 'stopped');
    // Plex has just been told where this stopped, so its On Deck has moved:
    // the next episode may now be up. Deferred a microtask because
    // invalidating while the tree is being torn down is exactly the kind of
    // provider change Riverpod refuses mid-lifecycle.
    final container = _container;
    if (container != null) {
      scheduleMicrotask(() => container.invalidate(plexOnDeckProvider));
    }
    for (final s in _subs) {
      unawaited(s.cancel());
    }
    _player.dispose();
    unawaited(_bridge?.stop());
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<_Playable> _resolve() async {
    final smbShareId = widget.smbShareId;
    if (smbShareId != null) {
      final share = ref
          .read(smbSharesProvider)
          .where((s) => s.id == smbShareId)
          .firstOrNull;
      if (share == null) {
        throw StateError('That share is no longer configured.');
      }
      final session = await ref.read(smbSessionProvider(share).future);
      final entries = await session.list(_parentOf(widget.smbPath!));
      final entry =
          entries.where((e) => e.path == widget.smbPath).firstOrNull;
      if (entry == null) {
        throw StateError('That file is no longer on the share.');
      }

      final bridge = LoopbackBridge();
      _bridge = bridge;
      return _Playable(
        url: await bridge.serve(await session.bridgeSourceFor(entry)),
        title: entry.name,
        live: false,
      );
    }

    final safUri = widget.safUri;
    if (safUri != null) {
      // libmpv cannot open a `content://` URI — it answers "Failed to recognize
      // file format". §7.2's loopback bridge puts an HTTP server in front so the
      // player gets something it can actually read.
      final source = await ref.read(safFolderSourceProvider).bridgeSourceFor(
            SafVideo(
              uri: safUri,
              name: widget.safName ?? 'Video',
              sizeBytes: widget.safSize,
            ),
          );
      final bridge = LoopbackBridge();
      _bridge = bridge;
      return _Playable(
        url: await bridge.serve(source),
        title: widget.safName ?? 'Video',
        live: false,
      );
    }

    final assetId = widget.assetId;
    if (assetId != null) {
      final source = ref.read(deviceVideoSourceProvider);
      final path = await source.filePathOf(assetId);
      if (path == null) {
        throw StateError('That file is no longer on this device.');
      }
      final video = await source.videoById(assetId);
      return _Playable(
        url: path,
        title: video?.title ?? 'Video',
        live: false,
      );
    }

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
          posterRef: match?.posterUrl,
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

    // A saved copy is played in preference to the server's, online or not
    // (§18.4): it needs no bandwidth, starts at once, and is the only thing
    // that works with no network. Everything about the title except the file
    // comes from the record, because the server may not be reachable to ask.
    final saved = await ref
        .read(downloadsProvider.notifier)
        .fileFor(widget.serverId!, widget.ratingKey!);
    if (saved != null) {
      final record = ref
          .read(downloadsProvider.notifier)
          .find(widget.serverId!, widget.ratingKey!)!;
      Duration? resumeFrom;
      try {
        // Where Plex last saw this title, if it can be asked quickly. Another
        // device may have watched on since. Offline this just fails, and the
        // position kept on this device is used instead.
        resumeFrom = (await plexServiceFor(
          ref,
          widget.serverId!,
        ).directPlay(widget.ratingKey!).timeout(const Duration(seconds: 3)))
            .resumeFrom;
      } catch (_) {}
      return _Playable(
        url: saved.path,
        title: record.title,
        live: false,
        posterRef: record.posterPath,
        historyKind: PlaybackKind.plex,
        historyId: widget.ratingKey,
        resumeFrom: resumeFrom,
        episode: record.isEpisode,
      );
    }

    final playable = await plexServiceFor(ref, widget.serverId!)
        .directPlay(widget.ratingKey!);
    return _Playable(
      url: playable.url,
      title: playable.title,
      live: false,
      posterRef: playable.posterPath,
      historyKind: PlaybackKind.plex,
      historyId: widget.ratingKey,
      resumeFrom: playable.resumeFrom,
      episode: playable.isEpisode,
    );
  }

  Future<void> _load() async {
    _tracksApplied = false;
    try {
      final playable = await _resolve();
      if (!mounted) return;
      _history = ref.read(historyProvider.notifier);
      if (widget.serverId != null) {
        // A saved copy outlives the server it came from (§18.4): with the
        // server removed there is nobody to report progress to, and that must
        // not stop the film playing.
        try {
          _plexService = plexServiceFor(ref, widget.serverId!);
        } on StateError {
          _plexService = null;
        }
        _container = ProviderScope.containerOf(context, listen: false);
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
      _progressTimer?.cancel();
      _progressTimer =
          Timer.periodic(_progressInterval, (_) => _recordProgress());
    } catch (e) {
      _fail('$e');
    }
  }

  static String _parentOf(String path) {
    final slash = path.lastIndexOf('/');
    return slash <= 0 ? path : path.substring(0, slash);
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
            poster: playable.posterRef,
            episode: playable.episode,
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
    if (position != _lastPosition) {
      _lastPosition = position;
      _lastAdvance = DateTime.now();
    }
    if (_started || position <= Duration.zero) return;
    _stallTimer?.cancel();
    _playingSince = DateTime.now();
    if (_live) {
      _freezeWatch?.cancel();
      _freezeWatch = Timer.periodic(const Duration(seconds: 2), (_) => _watch());
    }
    if (mounted) setState(() => _started = true);
    if (_output == VideoOutput.direct) unawaited(_checkVideoOutput());
  }

  /// Once playing on the direct path, asks mpv which decoder it ended up with.
  /// Software means a black picture under direct output (see [VideoOutput]), so
  /// the title is reopened on the compatible path.
  Future<void> _checkVideoOutput() async {
    // The decoder is settled by the first position tick; the pause is margin
    // for mpv's own fallback, which happens on the first frames it cannot take.
    await Future<void>.delayed(const Duration(seconds: 1));
    if (!mounted || _fellBack) return;
    final String hwdec;
    try {
      hwdec = await (_player.platform as NativePlayer).getProperty(
        'hwdec-current',
      );
    } catch (_) {
      return;
    }
    final hasVideo =
        _player.state.track.video.id != 'no' &&
        _player.state.tracks.video.any((t) => t.id != 'auto' && t.id != 'no');
    debugPrint('Player: direct output, hwdec-current=$hwdec video=$hasVideo');
    if (needsCompatibleOutput(
      output: _output,
      hasVideo: hasVideo,
      hwdecCurrent: hwdec,
    )) {
      await _reopenCompatible('hardware decoder declined (hwdec=$hwdec)');
    }
  }

  /// Opens this title again on a fresh player with compatible output.
  ///
  /// A new route rather than reconfiguring this player: media_kit re-applies
  /// its configured `vo` whenever the Android surface is recreated (coming
  /// back from the background), which would silently put the direct output
  /// back under a software decoder. This player is stopped first, because the
  /// new one opens while this route is still animating out and §4's
  /// `max_connections: 1` allows only one of them a connection.
  Future<void> _reopenCompatible(String why) async {
    if (_fellBack || !mounted) return;
    _fellBack = true;
    debugPrint('Player: reopening on compatible output: $why');
    final route = _route;
    final router = GoRouter.of(context);
    _compatibleRoutes.add(route);
    _stallTimer?.cancel();
    _recordProgress(state: 'stopped');
    await _player.stop();
    if (!mounted) return;
    router.pushReplacement(route);
  }

  /// Catches a live channel that froze *after* it started, which neither the
  /// startup guard nor mpv's error stream sees. A viewer-paused stream is left
  /// alone: its clock is meant to stand still.
  void _watch() {
    if (!_live || !_started || _released || _error != null) return;
    final now = DateTime.now();
    if (_reconnects > 0 && now.difference(_playingSince) >= _stableAfter) {
      _reconnects = 0;
    }
    if (!_player.state.playing) return;
    if (now.difference(_lastAdvance) >= _freezeTimeout) {
      _reconnect('This channel stopped and did not come back.');
    }
  }

  /// Stop, wait, reopen: never a second connection beside the first. §4's
  /// `max_connections: 1` means the old one has to be released before the new
  /// one is asked for, and the wait gives the panel time to notice it is gone.
  ///
  /// Returns false when the budget is spent, after showing [giveUp].
  bool _reconnect(String giveUp) {
    if (_reconnectTimer?.isActive ?? false) return true;
    if (_reconnects >= _maxReconnects) {
      _freezeWatch?.cancel();
      unawaited(_player.stop());
      _fail(giveUp);
      return false;
    }
    _reconnects++;
    debugPrint('Player: live stream stalled, reconnect $_reconnects of '
        '$_maxReconnects');
    _freezeWatch?.cancel();
    _stallTimer?.cancel();
    _progressTimer?.cancel();
    unawaited(_player.stop());
    _lastPosition = Duration.zero;
    if (mounted) setState(() => _started = false);
    _reconnectTimer = Timer(Duration(seconds: 2 * _reconnects), () {
      if (mounted && !_released && _error == null) unawaited(_load());
    });
    return true;
  }

  void _onStalled() {
    if (_started) return;
    // A reconnect that itself yields nothing tries again rather than giving up
    // on the first miss. A first-ever open still fails straight away: a dead
    // listing should say so in 15s, not after three more attempts.
    if (_live && _reconnects > 0) {
      _reconnect('This channel is not responding. Listings often outrun '
          'reality on a panel - try another, or the same one again.');
      return;
    }
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

  void _onPlayerError(String message) {
    if (isFatalPlayerError(message)) {
      // A live stream that dies mid-watch is the common drop, so it gets the
      // same reconnect as a freeze rather than an immediate error screen.
      if (_live && !_released && (_started || _reconnects > 0)) {
        _reconnect(message);
        return;
      }
      // On the direct path, failing before the first frame gets one retry on
      // the compatible one: a decoder or output that would not start there is
      // exactly what the direct path adds. A source that is really broken fails
      // the same way again and shows its error then.
      if (_output == VideoOutput.direct && !_started) {
        unawaited(_reopenCompatible(message));
        return;
      }
      _fail(message);
    } else {
      debugPrint('Player: continuing past non-fatal mpv error: $message');
    }
  }

  void _fail(Object message) {
    _stallTimer?.cancel();
    if (mounted && _error == null) setState(() => _error = '$message');
  }

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);
    final prefs = ref.watch(playbackPrefsProvider);

    return Scaffold(
      backgroundColor: t.stage,
      body: PlayerChrome(
        transport: _transport,
        title: _title,
        live: _live,
        enabled: _started && _error == null,
        onBack: () => Navigator.of(context).maybePop(),
        skip: prefs.skip,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: Video(
                controller: _controller,
                controls: null,
                subtitleViewConfiguration: SubtitleViewConfiguration(
                  textScaler: TextScaler.linear(prefs.subtitleSize.scale),
                ),
              ),
            ),
            if (_released)
              _PlaybackError(
                title: _title,
                message: 'Stopped while the app was in the background, so the '
                    'connection is free for other devices.',
                icon: Icons.pause_circle_outline,
                action: ('Rejoin', _rejoin),
              )
            else if (_error != null)
              _PlaybackError(message: _error!, title: _title)
            else if (!_started)
              Center(child: CircularProgressIndicator(color: t.accent)),
          ],
        ),
      ),
    );
  }
}

class _PlaybackError extends StatefulWidget {
  const _PlaybackError({
    required this.message,
    this.title,
    this.icon = Icons.error_outline,
    this.action,
  });

  final String message;
  final String? title;
  final IconData icon;

  /// A primary action shown before Back, e.g. rejoining a released stream.
  final (String, VoidCallback)? action;

  @override
  State<_PlaybackError> createState() => _PlaybackErrorState();
}

class _PlaybackErrorState extends State<_PlaybackError> {
  final _actionFocus = FocusNode(debugLabel: 'playback-action');

  @override
  void initState() {
    super.initState();
    // Asked for explicitly: `autofocus` only fires when nothing in the scope
    // has focus, and the player's own node always does. On a TV the action
    // would otherwise be a press or two away from a viewer who just came back.
    if (widget.action != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _actionFocus.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _actionFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final action = widget.action;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(widget.icon, color: Colors.white70, size: 36),
            const SizedBox(height: 16),
            if (widget.title != null) ...[
              Text(
                widget.title!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
            ],
            Text(
              widget.message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, height: 1.5),
            ),
            const SizedBox(height: 24),
            if (action != null) ...[
              RelayButton(
                label: action.$1,
                onPressed: action.$2,
                focusNode: _actionFocus,
              ),
              const SizedBox(height: 8),
              RelayTextButton(
                label: 'Back',
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ] else
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
