import 'dart:async';

import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../probe_log.dart';
import '../spike_config.dart';

/// Probe 1 -- media_kit / libmpv against arbitrary stream URLs.
///
/// Answers docs/architecture.md S10: does libmpv actually tolerate the raw
/// MPEG-TS and off-spec HLS that cheap Xtream panels emit, and how long does
/// it take to first frame? The interesting output is not "did it play" but
/// time-to-first-frame plus whatever libmpv logs on the way.
///
/// Feed it, in order of usefulness:
///   - an Xtream live URL  {host}/live/{user}/{pass}/{id}.ts
///   - an Xtream VOD URL   {host}/movie/{user}/{pass}/{id}.mp4
///   - a raw .m3u8 from a provider
///   - anything from the M3U playlist the parse probe dumps
class PlayerProbe extends StatefulWidget {
  const PlayerProbe({super.key});

  @override
  State<PlayerProbe> createState() => _PlayerProbeState();
}

class _PlayerProbeState extends State<PlayerProbe> {
  final _log = ProbeLog();
  final _urlController =
      TextEditingController(text: SpikeConfig.scratchUrl);

  late final Player _player;
  late final VideoController _controller;
  final List<StreamSubscription<dynamic>> _subs = [];

  Stopwatch? _openWatch;
  bool _sawFirstFrame = false;

  @override
  void initState() {
    super.initState();
    _player = Player();
    _controller = VideoController(_player);
    _wireDiagnostics();
  }

  /// Everything libmpv tells us. This is the actual product of the probe.
  void _wireDiagnostics() {
    _subs.add(_player.stream.error.listen((e) {
      _log.bad('player error: $e');
    }));

    _subs.add(_player.stream.log.listen((e) {
      // libmpv is chatty; surface only what bears on stream health.
      final text = e.text.trim();
      if (text.isEmpty) return;
      final lower = text.toLowerCase();
      if (lower.contains('error') ||
          lower.contains('fail') ||
          lower.contains('corrupt') ||
          lower.contains('drop') ||
          lower.contains('discontinuity')) {
        _log.warn('mpv[${e.prefix}] $text');
      }
    }));

    _subs.add(_player.stream.videoParams.listen((p) {
      if (p.w == null || p.h == null) return;
      if (!_sawFirstFrame) {
        _sawFirstFrame = true;
        _openWatch?.stop();
        _log.good(
          'FIRST FRAME after ${_openWatch?.elapsedMilliseconds} ms '
          '-- ${p.w}x${p.h} pixelformat=${p.pixelformat ?? "?"}',
        );
      }
    }));

    _subs.add(_player.stream.tracks.listen((t) {
      _log.info(
        'tracks: ${t.video.length} video / ${t.audio.length} audio / '
        '${t.subtitle.length} subtitle',
      );
      for (final v in t.video) {
        if (v.id == 'auto' || v.id == 'no') continue;
        _log.info('  video #${v.id} codec=${v.codec ?? "?"} '
            '${v.w ?? "?"}x${v.h ?? "?"} fps=${v.fps ?? "?"}');
      }
      for (final a in t.audio) {
        if (a.id == 'auto' || a.id == 'no') continue;
        _log.info('  audio #${a.id} codec=${a.codec ?? "?"} '
            'ch=${a.channels ?? "?"} lang=${a.language ?? "?"}');
      }
    }));

    _subs.add(_player.stream.buffering.listen((b) {
      _log.info(b ? 'buffering...' : 'buffering ended');
    }));

    _subs.add(_player.stream.completed.listen((c) {
      if (c) _log.info('playback completed');
    }));
  }

  Future<void> _open() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      _log.warn('Enter a URL first.');
      return;
    }
    _sawFirstFrame = false;
    _openWatch = Stopwatch()..start();
    _log.info('--- opening: $url');
    _log.info('(watch for FIRST FRAME timing and any mpv warnings below)');
    try {
      await _player.open(Media(url));
    } catch (e) {
      _log.bad('open() threw: $e');
    }
  }

  Future<void> _stop() async {
    await _player.stop();
    _log.info('stopped');
  }

  /// S10 notes live streams have no seek. Confirm libmpv agrees rather than
  /// assuming -- some panels do serve seekable TS.
  Future<void> _trySeek() async {
    _log.info('attempting 30s seek (expected to fail on live)');
    try {
      await _player.seek(const Duration(seconds: 30));
      _log.good('seek accepted -- position now ${_player.state.position}');
    } catch (e) {
      _log.warn('seek rejected: $e');
    }
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _player.dispose();
    _urlController.dispose();
    _log.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _urlController,
                  style: const TextStyle(fontSize: 13),
                  decoration: const InputDecoration(
                    isDense: true,
                    border: OutlineInputBorder(),
                    labelText: 'Stream URL (.ts / .m3u8 / .mp4 / http)',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(onPressed: _open, child: const Text('Open')),
              const SizedBox(width: 6),
              OutlinedButton(onPressed: _trySeek, child: const Text('Seek')),
              const SizedBox(width: 6),
              OutlinedButton(onPressed: _stop, child: const Text('Stop')),
            ],
          ),
        ),
        SizedBox(
          height: 200,
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
