import 'package:flutter/material.dart';

import 'probes/parse_probe.dart';
import 'probes/player_probe.dart';
import 'probes/plex_probe.dart';
import 'probes/smb_probe.dart';

/// Phase 0 spike harness -- see docs/architecture.md S13 and
/// docs/PHASE0_FINDINGS.md.
///
/// This screen exists to answer four questions with evidence and then be
/// deleted. It is debug-only and must never be reachable from a release
/// build; `main.dart` enforces that with a `kDebugMode` check.
class SpikeApp extends StatelessWidget {
  const SpikeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Relay Player -- Phase 0 Spike',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: const _SpikeHome(),
    );
  }
}

class _SpikeHome extends StatelessWidget {
  const _SpikeHome();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Phase 0 Spike'),
          bottom: const TabBar(
            tabs: [
              Tab(text: '1. Player'),
              Tab(text: '2. Plex'),
              Tab(text: '3. SMB'),
              Tab(text: '4. Parse'),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'What am I looking at?',
              icon: const Icon(Icons.help_outline),
              onPressed: () => showDialog<void>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Phase 0 Spike'),
                  content: const SingleChildScrollView(
                    child: Text(
                      'Four probes, each answering one open question from '
                      'docs/architecture.md:\n\n'
                      '1. Player  -- does libmpv tolerate real Xtream '
                      'streams? (S10, media_kit vs better_player)\n\n'
                      '2. Plex    -- is dart_plex 0.1.2 viable, especially '
                      'the transcode keep-alive/stop lifecycle? (S6)\n\n'
                      '3. SMB     -- does smb:// work natively, or is the '
                      'loopback bridge needed? (S7.2)\n\n'
                      '4. Parse   -- how expensive is XMLTV really, and does '
                      'this M3U carry usable tvg-id/group-title? (S5)\n\n'
                      'Record every result in docs/PHASE0_FINDINGS.md as you '
                      'go. Negative results are just as valuable -- they are '
                      'what the phase is for.',
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        body: const TabBarView(
          physics: NeverScrollableScrollPhysics(),
          children: [
            PlayerProbe(),
            PlexProbe(),
            SmbProbe(),
            ParseProbe(),
          ],
        ),
      ),
    );
  }
}
