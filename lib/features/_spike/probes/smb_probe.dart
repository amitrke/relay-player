import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:smb_connect/smb_connect.dart';

import '../probe_log.dart';
import '../spike_config.dart';

/// Probe 3 -- SMB. The highest-leverage question in Phase 0.
///
/// docs/architecture.md S7.2 says: test whether media_kit opens `smb://`
/// natively BEFORE building the loopback bridge, because the answer changes
/// the design. This probe runs that test first, then -- regardless of the
/// answer -- exercises the fallback so both data points exist in one run.
///
/// Step 1  Does libmpv open smb:// directly? (prebuilt libmpv usually lacks
///         libsmbclient, so failure here is the expected outcome, not a bug)
/// Step 2  Does smb_connect 0.0.9 connect, list, and random-access read?
/// Step 3  Does a shelf loopback server re-serve those bytes as HTTP with
///         working Range support, and can media_kit play it?
///
/// Step 3 is the real deliverable: if it works, every future tree-shaped
/// protocol (FTP, WebDAV) reuses it instead of teaching libmpv new schemes.
class SmbProbe extends StatefulWidget {
  const SmbProbe({super.key});

  @override
  State<SmbProbe> createState() => _SmbProbeState();
}

class _SmbProbeState extends State<SmbProbe> {
  final _log = ProbeLog();
  late final Player _player;
  late final VideoController _controller;
  StreamSubscription<String>? _errSub;

  SmbConnect? _smb;
  HttpServer? _bridge;

  @override
  void initState() {
    super.initState();
    _player = Player();
    _controller = VideoController(_player);
    _errSub = _player.stream.error.listen((e) => _log.bad('player error: $e'));
  }

  bool _configured() {
    if (SpikeConfig.smbHost.isEmpty || SpikeConfig.smbShare.isEmpty) {
      _log.warn('Fill in smbHost / smbShare in spike_config.dart first.');
      return false;
    }
    return true;
  }

  // --- Step 1 ----------------------------------------------------------
  // The question S7.2 says to answer before designing anything else.
  Future<void> _testNativeSmb() async {
    if (!_configured()) return;
    if (SpikeConfig.smbTestFilePath.isEmpty) {
      _log.warn('Set smbTestFilePath to a real video file on the share.');
      return;
    }
    final user = Uri.encodeComponent(SpikeConfig.smbUsername);
    final pass = Uri.encodeComponent(SpikeConfig.smbPassword);
    final auth = user.isEmpty ? '' : '$user:$pass@';
    final url =
        'smb://$auth${SpikeConfig.smbHost}${SpikeConfig.smbTestFilePath}';

    _log.info('--- STEP 1: does libmpv open smb:// natively?');
    _log.info('opening $url');
    _log.info('(expected: FAILURE -- prebuilt libmpv rarely bundles '
        'libsmbclient. A failure here confirms the bridge is needed.)');

    var firstFrame = false;
    final sub = _player.stream.videoParams.listen((p) {
      if (p.w != null && !firstFrame) {
        firstFrame = true;
        _log.good('NATIVE smb:// PLAYED -- ${p.w}x${p.h}. '
            'This would let you SKIP the loopback bridge entirely.');
      }
    });

    try {
      await _player.open(Media(url));
      await Future<void>.delayed(const Duration(seconds: 8));
      if (!firstFrame) {
        _log.warn('No frame after 8s -- treat native smb:// as unsupported.');
        _log.warn('=> Proceed with the loopback bridge design (S7.2).');
      }
    } catch (e) {
      _log.warn('native smb:// threw: $e');
      _log.warn('=> Proceed with the loopback bridge design (S7.2).');
    } finally {
      await sub.cancel();
      await _player.stop();
    }
  }

  // --- Step 2 ----------------------------------------------------------
  // smb_connect is 0.0.9. S7.2 says budget spike time to confirm it works
  // rather than trusting the package description. This is that time.
  Future<void> _testSmbClient() async {
    if (!_configured()) return;
    _log.info('--- STEP 2: smb_connect 0.0.9 reliability');

    final conn =
        await _log.time('connectAuth to ${SpikeConfig.smbHost}', () async {
      return SmbConnect.connectAuth(
        host: SpikeConfig.smbHost,
        username: SpikeConfig.smbUsername,
        password: SpikeConfig.smbPassword,
        domain: SpikeConfig.smbDomain,
      );
    });
    if (conn == null) {
      _log.bad('Cannot continue -- connection failed. Record the exception '
          'above verbatim in PHASE0_FINDINGS.md; it decides whether this '
          'package is viable.');
      return;
    }
    _smb = conn;

    await _log.time('listShares', () async {
      final shares = await conn.listShares();
      for (final s in shares) {
        _log.info('  share: ${s.path}');
      }
      return shares;
    });

    final folderPath = '/${SpikeConfig.smbShare}';
    await _log.time('listFiles $folderPath', () async {
      final folder = await conn.file(folderPath);
      final files = await conn.listFiles(folder);
      _log.info('  ${files.length} entries');
      for (final f in files.take(15)) {
        final marker = f.isDirectory() ? '[dir] ' : '      ';
        _log.info('  $marker${f.path}  ${f.size} bytes');
      }
      return files;
    });

    if (SpikeConfig.smbTestFilePath.isEmpty) return;

    // Random access is make-or-break: without working seeks the bridge can
    // only stream start-to-finish, which kills scrubbing.
    await _log.time('random-access read (seek + read 64KB at 50%)', () async {
      final file = await conn.file(SpikeConfig.smbTestFilePath);
      _log.info('  file size: ${file.size} bytes');
      final raf = await conn.open(file);
      try {
        final mid = file.size ~/ 2;
        await raf.setPosition(mid);
        final bytes = await raf.read(65536);
        _log.info('  read ${bytes.length} bytes from offset $mid');
        if (bytes.length < 65536) {
          _log.warn('  short read -- may break Range serving');
        }
        return bytes.length;
      } finally {
        await raf.close();
      }
    });
  }

  // --- Step 3 ----------------------------------------------------------
  Future<void> _startBridgeAndPlay() async {
    if (_smb == null) {
      _log.warn('Run Step 2 first -- no SMB connection.');
      return;
    }
    if (SpikeConfig.smbTestFilePath.isEmpty) {
      _log.warn('Set smbTestFilePath first.');
      return;
    }
    _log.info('--- STEP 3: loopback HTTP bridge -> media_kit');

    await _stopBridge();

    final smb = _smb!;
    final file = await smb.file(SpikeConfig.smbTestFilePath);
    final total = file.size;

    shelf.Response handler(shelf.Request request) {
      // Range is mandatory: libmpv seeks by byte range, and a bridge that
      // ignores Range appears to work until the user scrubs.
      final rangeHeader = request.headers['range'];
      var start = 0;
      var end = total - 1;

      if (rangeHeader != null && rangeHeader.startsWith('bytes=')) {
        final spec = rangeHeader.substring(6).split('-');
        if (spec[0].isNotEmpty) start = int.parse(spec[0]);
        if (spec.length > 1 && spec[1].isNotEmpty) end = int.parse(spec[1]);
        if (end >= total) end = total - 1;
      }
      final length = end - start + 1;
      final label = rangeHeader ?? 'no range';
      _log.info('  bridge: $label -> serving $start-$end ($length bytes)');

      final body = _readRange(smb, file, start, length);
      final headers = <String, String>{
        'content-type': 'video/mp4',
        'accept-ranges': 'bytes',
        'content-length': '$length',
        if (rangeHeader != null) 'content-range': 'bytes $start-$end/$total',
      };
      return shelf.Response(rangeHeader != null ? 206 : 200,
          body: body, headers: headers);
    }

    final server =
        await shelf_io.serve(handler, InternetAddress.loopbackIPv4, 0);
    _bridge = server;
    final url = 'http://127.0.0.1:${server.port}/stream';
    _log.good('bridge listening on $url');

    await _log.time('media_kit open via bridge', () async {
      await _player.open(Media(url));
      return true;
    });
    _log.info('Watch for "bridge:" range lines above -- multiple ranges means '
        'libmpv is seeking through the bridge correctly.');
  }

  /// Streams [length] bytes starting at [start] out of the SMB file in chunks.
  Stream<List<int>> _readRange(
      SmbConnect smb, SmbFile file, int start, int length) async* {
    const chunk = 64 * 1024;
    final raf = await smb.open(file);
    try {
      await raf.setPosition(start);
      var remaining = length;
      while (remaining > 0) {
        final want = remaining < chunk ? remaining : chunk;
        final bytes = await raf.read(want);
        if (bytes.isEmpty) break;
        yield bytes;
        remaining -= bytes.length;
      }
    } finally {
      await raf.close();
    }
  }

  Future<void> _stopBridge() async {
    await _bridge?.close(force: true);
    _bridge = null;
  }

  @override
  void dispose() {
    _errSub?.cancel();
    _stopBridge();
    _smb?.close();
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
                onPressed: _testNativeSmb,
                child: const Text('1. Native smb:// ?'),
              ),
              FilledButton(
                onPressed: _testSmbClient,
                child: const Text('2. smb_connect'),
              ),
              FilledButton(
                onPressed: _startBridgeAndPlay,
                child: const Text('3. Bridge + play'),
              ),
              OutlinedButton(
                onPressed: () async {
                  await _player.stop();
                  await _stopBridge();
                  _log.info('stopped player + bridge');
                },
                child: const Text('Stop'),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 160,
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
