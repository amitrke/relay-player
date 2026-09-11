import 'dart:async';

import 'package:dart_plex/dart_plex.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../probe_log.dart';

/// Probe 2 -- dart_plex viability.
///
/// docs/architecture.md S6 downgrades dart_plex from "recommended" to
/// "candidate": it is pre-1.0, days old, ~118 downloads, and sits on the
/// flagship integration. This probe decides whether to adopt it or fall back
/// to hand-rolling the needed subset (costed at roughly a week).
///
/// It exercises exactly the surface the app depends on, in order:
///   1. PIN flow          createPin -> user approves -> pollPin -> token
///   2. Server discovery  fetchResources -> bestConnection -> connect
///   3. Library browse    sections -> items
///   4. TRANSCODE LIFECYCLE  decision -> url -> ping -> stop
///
/// Step 4 is the one that matters. S6 calls the transcode session "real
/// lifecycle logic that Xtream/M3U don't need at all" -- keep-alive pings,
/// explicit teardown. A README claiming support is not evidence; a session
/// that survives 60s of pings and then stops cleanly is.
class PlexProbe extends StatefulWidget {
  const PlexProbe({super.key});

  @override
  State<PlexProbe> createState() => _PlexProbeState();
}

class _PlexProbeState extends State<PlexProbe> {
  final _log = ProbeLog();
  late final Player _player;
  late final VideoController _controller;
  StreamSubscription<String>? _errSub;

  PlexClient? _plex;
  PlexPin? _pin;
  List<PlexResource> _servers = [];
  String? _sampleRatingKey;

  String? _transcodeSession;
  Timer? _pingTimer;
  int _pingCount = 0;

  // Stable per-install id. A real build persists this; S6 notes the
  // X-Plex-Client-Identifier must not change between runs.
  static const _clientId = 'relay-player-phase0-spike-0001';

  @override
  void initState() {
    super.initState();
    _player = Player();
    _controller = VideoController(_player);
    _errSub = _player.stream.error.listen((e) => _log.bad('player error: $e'));
  }

  PlexClient _client() {
    return _plex ??= PlexClient(
      credentials: const PlexCredentials(
        clientIdentifier: _clientId,
        product: 'Relay Player (Phase 0 spike)',
        version: '0.0.1',
        device: 'Desktop',
        deviceName: 'Phase 0 Spike',
        platform: 'Flutter',
      ),
    );
  }

  // --- Step 1: PIN flow ------------------------------------------------
  Future<void> _createPin() async {
    _log.info('--- STEP 1: PIN flow (S6)');
    final pin = await _log.time('account.createPin(strong: false)', () async {
      // MUST be strong: false for the plex.tv/link flow.
      //
      // dart_plex defaults to `strong: true`, which makes Plex issue a
      // JWT-grade token with a long opaque code (25+ chars). plex.tv/link
      // only accepts the 4-character code, so the default silently produces
      // a PIN the user cannot enter anywhere.
      //
      // The package's own docstring says "Plex returns a PlexPin with a
      // 4-character code" while its default guarantees the opposite. See
      // docs/PHASE0_FINDINGS.md Q2.
      return _client().account.createPin(strong: false);
    });
    if (pin == null) return;
    _pin = pin;

    // Guard the regression rather than trusting the parameter: if a future
    // version changes the default or the response shape, this says so loudly
    // instead of printing an unusable code.
    if (pin.code.length != 4) {
      _log.bad('EXPECTED a 4-character link code, got ${pin.code.length} '
          'characters: "${pin.code}"');
      _log.bad('plex.tv/link will not accept this. Check the `strong` flag.');
    } else {
      _log.good('LINK CODE: ${pin.code}');
      _log.warn('Go to https://plex.tv/link and enter: ${pin.code}');
    }
    _log.info('(code copied to clipboard; expires ${pin.expiresAt.toLocal()})');
    await Clipboard.setData(ClipboardData(text: pin.code));
    setState(() {});
  }

  Future<void> _pollPin() async {
    final pin = _pin;
    if (pin == null) {
      _log.warn('Create a PIN first.');
      return;
    }
    // Real app polls on a timer; here it is manual so the transcript stays
    // readable and the poll interval is a deliberate observation.
    final polled = await _log.time('account.pollPin(${pin.id})', () async {
      return _client().account.pollPin(pin.id);
    });
    if (polled == null) return;

    final token = polled.authToken;
    if (token == null || token.isEmpty) {
      _log.warn('Not linked yet -- approve at plex.tv/link, then poll again.');
      return;
    }
    // Register before anything can echo it back. universalVideoUrl embeds the
    // token as X-Plex-Token, and media_kit's "Failed to open <url>" error
    // reproduces that URL in full.
    ProbeLog.registerSecrets([token]);
    _log.good('AUTH TOKEN acquired (${token.length} chars, not logged)');
    _client().setToken(token);
  }

  // --- Step 2: server discovery ----------------------------------------
  Future<void> _discoverServers() async {
    _log.info('--- STEP 2: server discovery');
    final resources = await _log.time('account.fetchResources', () async {
      return _client().account.fetchResources();
    });
    if (resources == null) return;

    _servers = resources.where((r) => r.provides.contains('server')).toList();
    if (_servers.isEmpty) {
      // provides may be shaped differently; fall back to everything owned.
      _servers = resources.where((r) => r.owned).toList();
    }
    _log.info('${_servers.length} server(s) reachable:');
    for (final s in _servers) {
      final conn = s.bestConnection();
      _log.info('  ${s.name}  owned=${s.owned} relay=${s.relay} '
          'https=${s.httpsRequired}');
      _log.info('    best connection: ${conn?.uri ?? "NONE"}');
      if (conn == null) {
        _log.warn('    no usable connection -- note this in FINDINGS');
      }
    }

    final first = _servers.isEmpty ? null : _servers.first;
    final uri = first?.bestConnection()?.uri;
    if (first == null || uri == null) {
      _log.bad('No connectable server. Cannot continue.');
      return;
    }
    _client().connect(uri.toString(), accessToken: first.accessToken);
    _log.good('connected to ${first.name} at $uri');
    setState(() {});
  }

  // --- Step 3: library browse ------------------------------------------
  Future<void> _browseLibrary() async {
    _log.info('--- STEP 3: library browse');
    final sections = await _log.time('library.sections', () async {
      return _client().library.sections();
    });
    if (sections == null) return;
    for (final s in sections) {
      _log.info('  section ${s.id}  "${s.title}"  type=${s.type.name}');
    }

    final movies = sections.where((s) => s.type == PlexLibraryType.movie);
    if (movies.isEmpty) {
      _log.warn('No movie section -- transcode test needs one.');
      return;
    }

    final section = movies.first;
    final container =
        await _log.time('library.allByType(movie) in "${section.title}"',
            () async {
      return _client().library.allByType(
        sectionId: section.id,
        type: PlexMetadataType.movie,
        size: 10,
      );
    });
    final items = container?.items ?? const <PlexMetadata>[];
    if (items.isEmpty) {
      _log.warn('No items returned.');
      return;
    }
    _log.info('${items.length} of ${container?.totalSize ?? "?"} item(s):');
    for (final m in items.take(10)) {
      _log.info('  ratingKey=${m.ratingKey}  "${m.title}"  (${m.year ?? "?"})');
    }
    _sampleRatingKey = items.first.ratingKey;
    _log.good('using ratingKey=$_sampleRatingKey for the transcode test');
    setState(() {});
  }

  /// Hides the auth token so a transcript can be pasted into FINDINGS.
  String _redact(String url) =>
      url.replaceAll(RegExp(r'X-Plex-Token=[^&]+'), 'X-Plex-Token=••••');

  /// Opens [url] and waits for a real outcome.
  ///
  /// `player.open()` returns as soon as the command is queued, so timing it
  /// reports "OK" in ~140 ms even when the stream then fails to open — the
  /// error arrives later on a different stream. That made the earlier
  /// transcript read as a success followed by an unexplained error. This waits
  /// for whichever comes first: a frame, or an error.
  /// **`videoParams` is not proof of playback.** It fires when libmpv has
  /// parsed the stream header and knows the dimensions — which happens even
  /// when decoding then stalls and the surface stays black. An earlier version
  /// of this probe reported "PLAYING" on that signal and was wrong.
  ///
  /// The only trustworthy evidence is the clock moving, so this samples
  /// [Player.state.position] and requires it to actually advance.
  Future<bool> _openAndAwait(String url, String label,
      {Duration timeout = const Duration(seconds: 15)}) async {
    final opened = Completer<bool>();
    final sw = Stopwatch()..start();
    int? headerMs;

    late final StreamSubscription<String> errSub;
    late final StreamSubscription<VideoParams> paramSub;

    void finish(bool ok) {
      if (!opened.isCompleted) opened.complete(ok);
    }

    errSub = _player.stream.error.listen((e) {
      _log.bad('$label FAILED after ${sw.elapsedMilliseconds} ms');
      _log.bad('  $e');
      finish(false);
    });
    paramSub = _player.stream.videoParams.listen((p) {
      if (p.w != null && headerMs == null) {
        headerMs = sw.elapsedMilliseconds;
        _log.info('$label: header parsed at ${headerMs}ms '
            '— ${p.w}x${p.h} (NOT yet proof of playback)');
        finish(true);
      }
    });

    _log.info('$label: opening ...');
    try {
      await _player.open(Media(url));
      final headerOk = await opened.future.timeout(timeout, onTimeout: () {
        _log.bad('$label: no header and no error after ${timeout.inSeconds}s');
        return false;
      });
      if (!headerOk) return false;

      // Now the real test: does the clock move?
      final samples = <Duration>[];
      for (var i = 0; i < 6; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 500));
        samples.add(_player.state.position);
      }
      final advanced = samples.last > samples.first;
      final s = _player.state;
      _log.info('$label: position samples '
          '${samples.map((d) => d.inMilliseconds).join(", ")} ms');
      _log.info('$label: playing=${s.playing} buffering=${s.buffering} '
          'duration=${s.duration.inSeconds}s '
          'audioTracks=${s.tracks.audio.length} '
          'videoTracks=${s.tracks.video.length}');

      if (advanced) {
        _log.good('$label ACTUALLY PLAYING — position advanced '
            '${samples.last.inMilliseconds - samples.first.inMilliseconds} ms '
            'over 3s (header at ${headerMs}ms)');
        return true;
      }

      _log.bad('$label OPENED BUT STALLED — libmpv parsed the header but the '
          'position never advanced. This is why the picture is black.');
      if (s.buffering) {
        _log.warn('  still buffering: the server is accepting the request but '
            'not delivering data fast enough, or at all.');
      }
      if (s.duration == Duration.zero) {
        _log.warn('  duration is 0 — libmpv may not have a seekable/complete '
            'stream. Check the server is serving byte ranges (206).');
      }
      return false;
    } catch (e) {
      _log.bad('$label: open() threw: $e');
      return false;
    } finally {
      await errSub.cancel();
      await paramSub.cancel();
    }
  }

  /// Step 3.5 — REAL direct play, via the media Part key.
  ///
  /// An earlier version of this probe called `universalVideoUrl(directPlay:
  /// true)`, which is not direct play at all — it still goes through
  /// `/video/:/transcode/universal/`, just asking the transcoder to pass the
  /// file through. The server's own decision confirms it: *"App cannot direct
  /// play this item. Direct play is disabled."*
  ///
  /// Genuine direct play is the Part key — a plain file served with byte
  /// ranges, which is what §6 describes and what media_kit handles like any
  /// progressive source. It is also the correct isolation test, because it
  /// touches no transcoder machinery at all.
  Future<void> _directPlay() async {
    final ratingKey = _sampleRatingKey;
    if (ratingKey == null) {
      _log.warn('Run Step 3 first -- no item selected.');
      return;
    }
    _log.info('--- STEP 3.5: DIRECT PLAY via Part key (real direct play)');

    final item = await _log.time('library.item($ratingKey)', () async {
      return _client().library.item(ratingKey);
    });
    if (item == null) return;

    final part = item.media
        .expand((m) => m.parts)
        .where((p) => (p.key ?? '').isNotEmpty)
        .firstOrNull;
    if (part == null) {
      _log.bad('No media Part with a key — cannot direct play this item.');
      return;
    }

    final media = item.media.first;
    _log.info('  container=${media.container} video=${media.videoCodec} '
        'audio=${media.audioCodec} '
        '${media.width ?? "?"}x${media.height ?? "?"}');
    _log.info('  part ${part.id}  ${part.size ?? "?"} bytes  key=${part.key}');

    final base = _client().baseUrl;
    final token = _client().token;
    if (base == null || token == null) {
      _log.bad('Not connected.');
      return;
    }
    final url = '$base${part.key}?X-Plex-Token=$token';
    _log.info(_redact(url));

    final ok = await _openAndAwait(url, 'direct play (Part key, https)');
    await _player.stop();

    if (ok) {
      _log.good('Transport and direct play are BOTH fine. A transcode failure '
          'after this is a transcoder/URL problem, not a connection problem.');
      return;
    }

    // Automatic control. curl reaches this server over HTTPS without trouble,
    // but curl uses the OS certificate store and libmpv ships its own. If the
    // identical request succeeds over plain HTTP, the difference is TLS
    // validation inside libmpv -- which would affect every Plex stream and is
    // a far bigger finding than anything transcoder-specific.
    _log.warn('HTTPS direct play did not progress. Retrying the SAME file over '
        'plain HTTP to isolate libmpv TLS ...');

    final plain = _plainHttpBase();
    if (plain == null) {
      _log.bad('No plain-HTTP candidate available to test with.');
      _logConnectionCandidates();
      return;
    }

    final plainUrl = '$plain${part.key}?X-Plex-Token=$token';
    _log.info(_redact(plainUrl));
    final plainOk = await _openAndAwait(plainUrl, 'direct play (Part key, http)');
    await _player.stop();

    if (plainOk) {
      _log.bad('DIAGNOSIS: plain HTTP plays, HTTPS does not.');
      _log.bad('libmpv cannot validate the *.plex.direct certificate. This '
          'affects EVERY Plex stream, not just transcode, and is a '
          'media_kit/libmpv issue rather than a dart_plex one.');
      _log.warn('Options: ship a CA bundle with the app, configure libmpv with '
          'tls-ca-file, or prefer the plain-HTTP LAN connection when the '
          'server is local. Record this in Q2 and revisit S10.');
    } else {
      _log.bad('Neither HTTPS nor HTTP progressed. The problem is not TLS. '
          'Check whether the server is serving byte ranges and whether this '
          'file is playable at all.');
      _logConnectionCandidates();
    }
  }

  /// A `http://<address>:<port>` form of the connected server, for the control
  /// test above.
  String? _plainHttpBase() {
    for (final server in _servers) {
      for (final c in server.connections) {
        if (c.local) return 'http://${c.address}:${c.port}';
      }
    }
    return null;
  }

  /// bestConnection() picks one URI; when it fails the others are worth
  /// trying by hand, especially the plain-http local one.
  void _logConnectionCandidates() {
    if (_servers.isEmpty) {
      _log.info('(run Step 2 first to list connections)');
      return;
    }
    final server = _servers.first;
    _log.info('connection candidates for "${server.name}":');
    for (final c in server.connections) {
      _log.info('  ${c.protocol}  local=${c.local} relay=${c.relay}  '
          '${c.uri}');
      if (c.protocol == 'https' && c.local) {
        _log.warn('    plain-HTTP equivalent to try: '
            'http://${c.address}:${c.port}');
      }
    }
    _log.info('To force one, note it here and set it in code: '
        'plex.connect("<uri>", accessToken: ...)');
  }

  // --- Step 4: transcode lifecycle (the real test) ---------------------
  Future<void> _transcodeLifecycle() async {
    final ratingKey = _sampleRatingKey;
    if (ratingKey == null) {
      _log.warn('Run Step 3 first -- no item selected.');
      return;
    }
    _log.info('--- STEP 4: TRANSCODE LIFECYCLE (the decisive test, S6)');

    final session = 'phase0-${DateTime.now().millisecondsSinceEpoch}';
    _transcodeSession = session;
    _log.info('session id: $session');

    // Force a transcode by disallowing direct play/stream and asking for a
    // low resolution. Direct play would bypass exactly what we want to test.
    // BLOCKING dart_plex DEFECT, worked around here.
    //
    // universalVideoUrl omits `hasMDE=1`, and Plex Media Server 1.43 rejects
    // the universal transcode endpoint with a bare HTTP 400 without it. The
    // parameter tells the server the client speaks the Media Decision Engine
    // protocol. Verified by bisection against a real server: identical URL,
    // 400 without the flag and 200 with it.
    //
    // The package contains no occurrence of "hasMDE" at all, so nothing it
    // builds can drive the transcoder. See docs/PHASE0_FINDINGS.md Q2.
    final url = '${_client().streaming.universalVideoUrl(
      ratingKey: ratingKey,
      session: session,
      directPlay: false,
      directStream: false,
      videoResolution: '640x360',
      videoBitrate: 1000,
    )}&hasMDE=1';
    _log.info('universalVideoUrl + hasMDE -> ${_redact(url)}');

    // The decision call MUST carry the same parameter set as the start URL.
    // Plex rejects it with HTTP 400 if mediaIndex/partIndex are missing, and
    // an incomplete set makes the server decide about a different request than
    // the one you are about to make -- which is worse than not asking.
    await _log.time('decisionUniversal (what will the server actually do?)',
        () async {
      final decision = await _client().streaming.decisionUniversal(
        params: <String, dynamic>{
          // Same defect as the start URL — 400 without it.
          'hasMDE': '1',
          'path': '/library/metadata/$ratingKey',
          'mediaIndex': '0',
          'partIndex': '0',
          'protocol': 'hls',
          'container': 'mpegts',
          'directPlay': '0',
          'directStream': '0',
          'fastSeek': '1',
          'offset': '0',
          'audioBoost': '100',
          'videoResolution': '640x360',
          'maxVideoBitrate': '1000',
          'session': session,
        },
      );
      final raw = decision.raw;
      _log.info('  generalDecisionCode:     ${decision.code}');
      _log.info('  directPlayDecisionCode:  ${raw['directPlayDecisionCode']}');
      _log.info('  transcodeDecisionCode:   ${raw['transcodeDecisionCode']}');
      final text = raw['generalDecisionText'] ?? raw['transcodeDecisionText'];
      if (text != null) _log.info('  server says: $text');
      final code = decision.code;
      if (code != null && (code < 1000 || code >= 2000)) {
        _log.bad('  decision code $code is outside [1000,2000) -- the server '
            'says this is NOT playable. Playback below will fail.');
      }
      return decision;
    });

    await _openAndAwait(url, 'transcode HLS');

    // The keep-alive. S6: "Plex sessions time out without them."
    _pingCount = 0;
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      _pingCount++;
      try {
        await _client().streaming.pingUniversal(session);
        _log.good('ping #$_pingCount OK (session alive)');
      } catch (e) {
        final is404 = e.toString().contains('404') ||
            e.toString().contains('notFound');
        _log.bad('ping #$_pingCount FAILED: $e');
        if (is404 && _pingCount == 1) {
          // Distinguish cause from symptom. Plex has no session to keep alive
          // if the transcode never started, so a 404 here after a failed
          // decision/open is expected fallout -- not independent evidence that
          // pingUniversal is broken. Only a 404 while playback is running
          // would indict the package.
          _log.warn('  404 means the server has no such session. If the '
              'decision or the open above failed, this is a SYMPTOM of that, '
              'not a separate bug -- fix those first and re-run.');
        }
      }
    });
    _log.warn('Pinging every 10s. Let this run 60s+, confirm playback does '
        'not stall, then press "Stop session".');
  }

  Future<void> _stopSession() async {
    _pingTimer?.cancel();
    _pingTimer = null;
    final session = _transcodeSession;
    await _player.stop();
    if (session == null) {
      _log.info('no active session');
      return;
    }
    await _log.time('stopUniversal($session)', () async {
      await _client().streaming.stopUniversal(session);
      return true;
    });
    _log.warn('Now check the Plex server dashboard: the session should be '
        'GONE. A lingering session means teardown is broken -- that is a '
        'blocking finding for dart_plex.');
    _transcodeSession = null;
  }

  @override
  void dispose() {
    _pingTimer?.cancel();
    _errSub?.cancel();
    _player.dispose();
    _log.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton(
                  onPressed: _createPin, child: const Text('1a. Create PIN')),
              FilledButton(
                  onPressed: _pollPin, child: const Text('1b. Poll PIN')),
              FilledButton(
                  onPressed: _discoverServers,
                  child: const Text('2. Servers')),
              FilledButton(
                  onPressed: _browseLibrary, child: const Text('3. Library')),
              FilledButton(
                  onPressed: _directPlay,
                  child: const Text('3.5 Direct play')),
              FilledButton(
                  onPressed: _transcodeLifecycle,
                  child: const Text('4. Transcode')),
              OutlinedButton(
                  onPressed: _stopSession,
                  child: const Text('Stop session')),
            ],
          ),
        ),
        if (_pin != null)
          Container(
            width: double.infinity,
            color: const Color(0xFF1E3A5F),
            padding: const EdgeInsets.all(10),
            child: SelectableText(
              'plex.tv/link  ->  ${_pin!.code}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
          ),
        SizedBox(
          height: 150,
          child: Container(
            color: Colors.black,
            child: Video(controller: _controller),
          ),
        ),
        Expanded(child: ProbeLogView(log: _log)),
      ],
    );
  }
}
