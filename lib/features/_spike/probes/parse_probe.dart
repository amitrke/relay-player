import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:xml/xml_events.dart';

import '../probe_log.dart';
import '../spike_config.dart';

/// One channel line recovered from an M3U playlist.
@immutable
class M3uEntry {
  const M3uEntry(this.name, this.url, this.group, this.tvgId, this.logo);

  final String name;
  final String url;
  final String? group;
  final String? tvgId;
  final String? logo;
}

/// Probe 4 -- M3U and XMLTV parsing cost.
///
/// docs/architecture.md S5 asserts two things this probe tests rather than
/// assumes:
///   1. A hand-rolled M3U parser is "plenty" -- confirm against a real
///      playlist, including how many entries lack tvg-id (which decides
///      whether EPG linkage actually works) and whether group-title
///      conventions cleanly separate Movies/Series (S5 says "common but not
///      guaranteed" -- this measures it).
///   2. XMLTV must parse in a background isolate because guides "routinely
///      run to tens or hundreds of megabytes."
///
/// For (2) it deliberately parses the SAME file twice: once on the main
/// isolate and once via compute(). The main-isolate run is the evidence --
/// if it blocks for seconds, the isolate requirement is proven rather than
/// asserted, and the number goes straight into PHASE0_FINDINGS.md.
class ParseProbe extends StatefulWidget {
  const ParseProbe({super.key});

  @override
  State<ParseProbe> createState() => _ParseProbeState();
}

class _ParseProbeState extends State<ParseProbe> {
  final _log = ProbeLog();
  final _dio = Dio();

  final _m3uController = TextEditingController(text: SpikeConfig.m3uUrl);
  final _xmltvController = TextEditingController(text: SpikeConfig.xmltvUrl);

  bool _busy = false;

  Future<Uint8List?> _download(String url, String label) async {
    return _log.time('$label download', () async {
      final res = await _dio.get<List<int>>(
        url,
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = Uint8List.fromList(res.data ?? const []);
      final mb = (bytes.length / (1024 * 1024)).toStringAsFixed(2);
      _log.info('  $mb MB (${bytes.length} bytes)');
      return bytes;
    });
  }

  // --- M3U -------------------------------------------------------------
  Future<void> _runM3u() async {
    final url = _m3uController.text.trim();
    if (url.isEmpty) {
      _log.warn('Set an M3U URL first.');
      return;
    }
    setState(() => _busy = true);
    try {
      _log.info('--- M3U PARSE (S5)');
      final bytes = await _download(url, 'M3U');
      if (bytes == null) return;

      final text = utf8.decode(bytes, allowMalformed: true);

      final entries = await _log.time('parse on MAIN isolate', () async {
        return _parseM3u(text);
      });
      if (entries == null) return;

      await _log.time('parse via compute()', () async {
        return compute(_parseM3u, text);
      });

      _log.good('${entries.length} entries parsed');

      // The numbers that actually decide design questions in S5.
      final noTvgId =
          entries.where((e) => e.tvgId == null || e.tvgId!.isEmpty).length;
      final noGroup =
          entries.where((e) => e.group == null || e.group!.isEmpty).length;
      final noLogo =
          entries.where((e) => e.logo == null || e.logo!.isEmpty).length;

      _log.info('missing tvg-id:     $noTvgId / ${entries.length}'
          '  <- these channels CANNOT be EPG-linked');
      _log.info('missing group-title: $noGroup / ${entries.length}');
      _log.info('missing tvg-logo:    $noLogo / ${entries.length}');

      final groups = <String, int>{};
      for (final e in entries) {
        final g = (e.group == null || e.group!.isEmpty) ? '(none)' : e.group!;
        groups[g] = (groups[g] ?? 0) + 1;
      }
      _log.info('${groups.length} distinct group-title values; top 15:');
      final sorted = groups.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      for (final g in sorted.take(15)) {
        _log.info('  ${g.value.toString().padLeft(6)}  ${g.key}');
      }

      // S5: treat M3U as "Live only" unless groups clearly separate VOD.
      final vodish = sorted.where((g) {
        final k = g.key.toLowerCase();
        return k.contains('movie') ||
            k.contains('vod') ||
            k.contains('series') ||
            k.contains('film');
      }).toList();
      if (vodish.isEmpty) {
        _log.good('No movie/series-looking groups -> S5 "Live only" default '
            'is correct for this playlist.');
      } else {
        _log.warn('${vodish.length} group(s) look like VOD/series '
            '(e.g. "${vodish.first.key}") -- S5 says do NOT guess; this is '
            'the ambiguity the onboarding copy has to set expectations for.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Top-level so it can cross an isolate boundary via [compute].
  static List<M3uEntry> _parseM3u(String text) {
    final entries = <M3uEntry>[];
    final lines = const LineSplitter().convert(text);

    String? name;
    String? group;
    String? tvgId;
    String? logo;

    String? attr(String line, String key) {
      final i = line.indexOf('$key="');
      if (i < 0) return null;
      final start = i + key.length + 2;
      final end = line.indexOf('"', start);
      if (end < 0) return null;
      return line.substring(start, end);
    }

    for (final raw in lines) {
      final line = raw.trim();
      if (line.isEmpty) continue;

      if (line.startsWith('#EXTINF')) {
        tvgId = attr(line, 'tvg-id');
        logo = attr(line, 'tvg-logo');
        group = attr(line, 'group-title');
        final comma = line.lastIndexOf(',');
        name = comma >= 0 ? line.substring(comma + 1).trim() : '(unnamed)';
      } else if (!line.startsWith('#')) {
        entries.add(M3uEntry(name ?? '(unnamed)', line, group, tvgId, logo));
        name = group = tvgId = logo = null;
      }
    }
    return entries;
  }

  // --- XMLTV -----------------------------------------------------------
  Future<void> _runXmltv() async {
    final url = _xmltvController.text.trim();
    if (url.isEmpty) {
      _log.warn('Set an XMLTV URL first.');
      return;
    }
    setState(() => _busy = true);
    try {
      _log.info('--- XMLTV PARSE (S5)');
      var bytes = await _download(url, 'XMLTV');
      if (bytes == null) return;

      // Guides are commonly served .xml.gz.
      if (bytes.length > 2 && bytes[0] == 0x1f && bytes[1] == 0x8b) {
        final out = await _log.time('gunzip', () async {
          return Uint8List.fromList(gzip.decode(bytes!));
        });
        if (out == null) return;
        bytes = out;
        final mb = (bytes.length / (1024 * 1024)).toStringAsFixed(2);
        _log.info('  decompressed to $mb MB');
      }

      final text = utf8.decode(bytes, allowMalformed: true);
      final mb = (text.length / (1024 * 1024)).toStringAsFixed(2);

      _log.warn('Parsing $mb MB on the MAIN isolate now -- if the UI freezes, '
          'that IS the finding S5 predicts.');

      final mainResult = await _log.time('parse on MAIN isolate', () async {
        return _parseXmltv(text);
      });
      if (mainResult == null) return;

      final isolateResult = await _log.time('parse via compute()', () async {
        return compute(_parseXmltv, text);
      });

      _log.good('channels=${mainResult.$1}  programmes=${mainResult.$2}');
      if (isolateResult != null &&
          (isolateResult.$1 != mainResult.$1 ||
              isolateResult.$2 != mainResult.$2)) {
        _log.bad('Isolate and main-isolate counts DISAGREE -- parser bug.');
      }
      _log.info('Compare the two timings above. Record both, plus the source '
          'file size, in docs/PHASE0_FINDINGS.md. Then re-run this same '
          'probe on the weakest target device (Fire TV, S11) -- desktop '
          'timings understate the problem badly.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Streaming event parse -- never builds a full DOM, per S5.
  /// Returns (channelCount, programmeCount).
  static (int, int) _parseXmltv(String text) {
    var channels = 0;
    var programmes = 0;
    for (final event in parseEvents(text)) {
      if (event is XmlStartElementEvent) {
        if (event.name == 'channel') {
          channels++;
        } else if (event.name == 'programme') {
          programmes++;
        }
      }
    }
    return (channels, programmes);
  }

  @override
  void dispose() {
    _m3uController.dispose();
    _xmltvController.dispose();
    _log.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _m3uController,
                      style: const TextStyle(fontSize: 13),
                      decoration: const InputDecoration(
                        isDense: true,
                        border: OutlineInputBorder(),
                        labelText: 'M3U playlist URL',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _busy ? null : _runM3u,
                    child: const Text('Parse M3U'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _xmltvController,
                      style: const TextStyle(fontSize: 13),
                      decoration: const InputDecoration(
                        isDense: true,
                        border: OutlineInputBorder(),
                        labelText: 'XMLTV guide URL (.xml or .xml.gz)',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _busy ? null : _runXmltv,
                    child: const Text('Parse XMLTV'),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (_busy) const LinearProgressIndicator(),
        Expanded(child: ProbeLogView(log: _log)),
      ],
    );
  }
}
