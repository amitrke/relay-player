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
    final url = _client().streaming.universalVideoUrl(
          ratingKey: ratingKey,
          session: session,
          directPlay: false,
          directStream: false,
          videoResolution: '640x360',
          videoBitrate: 1000,
        );
    _log.info('universalVideoUrl -> $url');

    await _log.time('decisionUniversal (what will the server actually do?)',
        () async {
      final decision = await _client().streaming.decisionUniversal(
        params: {
          'path': '/library/metadata/$ratingKey',
          'session': session,
          'directPlay': '0',
          'directStream': '0',
          'videoResolution': '640x360',
          'maxVideoBitrate': '1000',
        },
      );
      _log.info('  decision code: ${decision.code}');
      return decision;
    });

    await _log.time('media_kit open transcode HLS', () async {
      await _player.open(Media(url));
      return true;
    });

    // The keep-alive. S6: "Plex sessions time out without them."
    _pingCount = 0;
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      _pingCount++;
      try {
        await _client().streaming.pingUniversal(session);
        _log.good('ping #$_pingCount OK (session alive)');
      } catch (e) {
        _log.bad('ping #$_pingCount FAILED: $e');
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
