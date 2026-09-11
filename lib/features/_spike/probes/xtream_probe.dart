import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../probe_log.dart';
import '../spike_config.dart';

/// Probe 5 — Xtream Codes.
///
/// This is the probe §13 Phase 0 actually asks for when it says "media_kit
/// playback spike against real Xtream test accounts". Tab 1 can play a URL you
/// already have; this one gets you those URLs the way the app will: by calling
/// `player_api.php` and constructing stream URLs client-side (§4).
///
/// It answers three things at once:
///   1. Does the panel's API behave as §4 describes? (They vary a lot.)
///   2. What does the account actually allow — expiry, and crucially
///      `max_connections`, which determines whether the app can ever open two
///      streams at once (a second player, or a preview while something plays).
///   3. Does libmpv tolerate what this panel emits? — the Q1 question, now with
///      one tap from a real channel to playback.
class XtreamProbe extends StatefulWidget {
  const XtreamProbe({super.key});

  @override
  State<XtreamProbe> createState() => _XtreamProbeState();
}

class _XtreamProbeState extends State<XtreamProbe> {
  final _log = ProbeLog();
  final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 20),
    // Panels are frequently misconfigured and return text/html for JSON.
    responseType: ResponseType.plain,
    validateStatus: (s) => s != null && s < 500,
  ));

  late final Player _player;
  late final VideoController _controller;
  StreamSubscription<String>? _errSub;
  StreamSubscription<VideoParams>? _paramSub;
  Stopwatch? _openWatch;
  bool _sawFrame = false;

  List<_Channel> _channels = [];
  _Channel? _selected;

  @override
  void initState() {
    super.initState();
    _player = Player();
    _controller = VideoController(_player);
    _errSub = _player.stream.error.listen((e) => _log.bad('player error: $e'));
    _paramSub = _player.stream.videoParams.listen((p) {
      if (p.w != null && !_sawFrame) {
        _sawFrame = true;
        _openWatch?.stop();
        _log.good('FIRST FRAME after ${_openWatch?.elapsedMilliseconds} ms '
            '— ${p.w}x${p.h}');
      }
    });
  }

  @override
  void dispose() {
    _errSub?.cancel();
    _paramSub?.cancel();
    _player.dispose();
    _log.dispose();
    super.dispose();
  }

  String get _base => SpikeConfig.xtreamHost.replaceAll(RegExp(r'/+$'), '');
  String get _user => SpikeConfig.xtreamUsername;
  String get _pass => SpikeConfig.xtreamPassword;

  bool _configured() {
    if (_base.isEmpty || _user.isEmpty || _pass.isEmpty) {
      _log.warn('Set xtreamHost / xtreamUsername / xtreamPassword in '
          'spike_config.dart first.');
      _log.info('xtreamHost must include scheme and port, e.g. '
          'http://line.example.com:8080');
      return false;
    }
    return true;
  }

  Uri _api(Map<String, String> extra) => Uri.parse('$_base/player_api.php')
      .replace(queryParameters: {
    'username': _user,
    'password': _pass,
    ...extra,
  });

  /// Panels lie about content types and occasionally wrap JSON in whitespace or
  /// an HTML error page, so decode defensively and say what came back.
  Future<dynamic> _getJson(Uri uri) async {
    final res = await _dio.getUri<String>(uri);
    final body = (res.data ?? '').trim();
    if (res.statusCode != 200) {
      throw Exception('HTTP ${res.statusCode} — first 200 chars: '
          '${body.substring(0, body.length.clamp(0, 200))}');
    }
    if (body.isEmpty) throw Exception('empty body');
    if (body.startsWith('<')) {
      throw Exception('got HTML, not JSON — panel error page? first 200 '
          'chars: ${body.substring(0, body.length.clamp(0, 200))}');
    }
    try {
      return jsonDecode(body);
    } catch (e) {
      throw Exception('JSON parse failed ($e) — first 200 chars: '
          '${body.substring(0, body.length.clamp(0, 200))}');
    }
  }

  // --- Step 1: authenticate --------------------------------------------
  Future<void> _auth() async {
    if (!_configured()) return;
    _log.info('--- STEP 1: authenticate (§4)');
    _log.info('GET $_base/player_api.php?username=…&password=…');

    final data = await _log.time('player_api auth', () async {
      return _getJson(_api(const {}));
    });
    if (data == null) return;

    final map = data as Map<String, dynamic>;
    final user = map['user_info'] as Map<String, dynamic>?;
    final server = map['server_info'] as Map<String, dynamic>?;

    if (user == null) {
      _log.bad('No user_info in response. This panel may not be Xtream, or '
          'the credentials are wrong. Keys: ${map.keys.join(", ")}');
      return;
    }

    final auth = user['auth'];
    final status = user['status'];
    if (auth != 1 && auth != '1') {
      _log.bad('auth=$auth status=$status — credentials rejected.');
      return;
    }
    _log.good('authenticated · status=$status');

    // The operationally important fields. max_connections in particular
    // decides whether the app may ever hold two streams open at once.
    final exp = user['exp_date'];
    if (exp != null && '$exp'.isNotEmpty) {
      final secs = int.tryParse('$exp');
      if (secs != null) {
        final when = DateTime.fromMillisecondsSinceEpoch(secs * 1000);
        final left = when.difference(DateTime.now()).inDays;
        _log.info('  expires: ${when.toLocal()}  ($left days left)');
      }
    } else {
      _log.info('  expires: never / unlimited');
    }
    _log.warn('  max_connections: ${user['max_connections']}   '
        'active now: ${user['active_cons']}');
    _log.info('  is_trial: ${user['is_trial']}');
    _log.info('  allowed output formats: ${user['allowed_output_formats']}');
    if (server != null) {
      _log.info('  server: ${server['url']}:${server['port']} '
          '(https ${server['https_port']}) tz=${server['timezone']}');
    }

    _log.info('NOTE for §4: if max_connections is 1, the app must guarantee it '
        'never opens a second stream — including a preview or a second window '
        '— or the panel will drop the first.');
  }

  // --- Step 2: categories + streams ------------------------------------
  Future<void> _loadLive() async {
    if (!_configured()) return;
    _log.info('--- STEP 2: live categories and streams');

    final cats = await _log.time('get_live_categories', () async {
      return _getJson(_api(const {'action': 'get_live_categories'}));
    });
    if (cats is! List) {
      _log.bad('Expected a list of categories, got ${cats.runtimeType}');
      return;
    }
    _log.info('${cats.length} live categories');
    for (final c in cats.take(10)) {
      final m = c as Map<String, dynamic>;
      _log.info('  ${m['category_id']}  ${m['category_name']}');
    }

    final streams = await _log.time('get_live_streams (all)', () async {
      return _getJson(_api(const {'action': 'get_live_streams'}));
    });
    if (streams is! List) {
      _log.bad('Expected a list of streams, got ${streams.runtimeType}');
      return;
    }

    _channels = [
      for (final s in streams)
        if (s is Map<String, dynamic> && s['stream_id'] != null)
          _Channel(
            id: '${s['stream_id']}',
            name: '${s['name'] ?? "(unnamed)"}',
            categoryId: '${s['category_id'] ?? ""}',
            epgChannelId: '${s['epg_channel_id'] ?? ""}',
            directSource: '${s['direct_source'] ?? ""}',
          ),
    ];
    _log.good('${_channels.length} live streams');

    // The data-quality question §5 asks of M3U, asked of the API instead.
    final noEpg = _channels.where((c) => c.epgChannelId.isEmpty).length;
    _log.info('  without epg_channel_id: $noEpg / ${_channels.length} '
        '— these cannot be guide-linked');
    final withDirect =
        _channels.where((c) => c.directSource.isNotEmpty).length;
    if (withDirect > 0) {
      _log.warn('  $withDirect stream(s) carry direct_source — some panels '
          'expect you to use that URL verbatim instead of building one.');
    }

    if (_channels.isNotEmpty) {
      _selected = _channels.first;
      _log.info('selected: ${_selected!.name}');
    }
    setState(() {});
  }

  // --- Step 3: build a URL and play ------------------------------------
  //
  // §4: stream URLs are constructed client-side, not returned by the API.
  String _streamUrl(_Channel c, String ext) =>
      '$_base/live/$_user/$_pass/${c.id}.$ext';

  Future<void> _play(String ext) async {
    final c = _selected;
    if (c == null) {
      _log.warn('Load streams first, then pick a channel.');
      return;
    }
    final url = _streamUrl(c, ext);
    _sawFrame = false;
    _openWatch = Stopwatch()..start();
    _log.info('--- STEP 3: play "${c.name}" as .$ext');
    _log.info(url.replaceAll(_pass, '••••'));
    try {
      await _player.open(Media(url));
      await Future<void>.delayed(const Duration(seconds: 10));
      if (!_sawFrame) {
        _log.bad('No frame after 10s on .$ext — record this in Q1.');
      }
    } catch (e) {
      _log.bad('open() threw: $e');
    }
  }

  /// The whole-playlist export. Often the fastest way to get a large, real M3U
  /// for the Tab 4 parser without touching a provider's own playlist link.
  Future<void> _copyM3uUrl() async {
    if (!_configured()) return;
    final url = '$_base/get.php?username=$_user&password=$_pass'
        '&type=m3u_plus&output=ts';
    await Clipboard.setData(ClipboardData(text: url));
    _log.good('M3U export URL copied to clipboard.');
    _log.info('Paste it into Tab 4 to measure parse cost on a real playlist, '
        'and into Tab 1 to play individual channels from it.');
    _log.info('The matching guide URL is '
        '$_base/xmltv.php?username=…&password=… (Tab 4, XMLTV field).');
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
                  onPressed: _auth, child: const Text('1. Authenticate')),
              FilledButton(
                  onPressed: _loadLive, child: const Text('2. Live streams')),
              FilledButton(
                  onPressed: () => _play('ts'), child: const Text('3. Play .ts')),
              OutlinedButton(
                  onPressed: () => _play('m3u8'),
                  child: const Text('Play .m3u8')),
              OutlinedButton(
                  onPressed: _copyM3uUrl,
                  child: const Text('Copy M3U/XMLTV URLs')),
              OutlinedButton(
                onPressed: () async {
                  await _player.stop();
                  _log.info('stopped');
                },
                child: const Text('Stop'),
              ),
            ],
          ),
        ),
        if (_channels.isNotEmpty)
          SizedBox(
            height: 46,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _channels.length.clamp(0, 60),
              itemBuilder: (context, i) {
                final c = _channels[i];
                final sel = c == _selected;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(c.name,
                        style: const TextStyle(fontSize: 11)),
                    selected: sel,
                    onSelected: (_) => setState(() => _selected = c),
                  ),
                );
              },
            ),
          ),
        SizedBox(
          height: 170,
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

@immutable
class _Channel {
  const _Channel({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.epgChannelId,
    required this.directSource,
  });

  final String id;
  final String name;
  final String categoryId;
  final String epgChannelId;
  final String directSource;
}
