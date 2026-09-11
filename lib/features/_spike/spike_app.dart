import 'package:flutter/material.dart';

import 'probes/parse_probe.dart';
import 'probes/player_probe.dart';
import 'probes/plex_probe.dart';
import 'probes/smb_probe.dart';
import 'probes/xtream_probe.dart';
import 'probe_log.dart';
import 'spike_config.dart';

/// Phase 0 spike harness -- see docs/architecture.md S13 and
/// docs/PHASE0_FINDINGS.md.
///
/// Phase 0 is closed, but this stays until its two loose ends are tied off: the
/// Plex transcode lifecycle (decision -> ping -> stop, with the `hasMDE=1` fix
/// in place) and the Q5 Android-device questions. Deleting it before those are
/// answered would mean rebuilding it to answer them.
///
/// Debug-only, and it must never be reachable from a release build. The
/// `kDebugMode` guard that enforces that lives in `core/routing/app_router.dart`,
/// which is the only thing that routes here.
class SpikeHome extends StatelessWidget {
  const SpikeHome({super.key});

  @override
  Widget build(BuildContext context) {
    // Before any probe can log. Covers exception text from media_kit, Dio and
    // smb_connect, none of which know these strings are secret.
    ProbeLog.registerSecrets([
      SpikeConfig.xtreamPassword,
      SpikeConfig.xtreamUsername,
      SpikeConfig.smbPassword,
      SpikeConfig.smbUsername,
    ]);
    // The Plex auth token is acquired at runtime, so PlexProbe registers it
    // the moment pollPin returns it.
    //
    // The probes were written against a dark Material surface and read their
    // colours from it, not from RelayTokens — they are scaffolding, not app UI.
    return Theme(
      data: ThemeData.dark(useMaterial3: true),
      child: const _SpikeHome(),
    );
  }
}

class _SpikeHome extends StatelessWidget {
  const _SpikeHome();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Phase 0 Spike'),
          bottom: const TabBar(
            tabs: [
              Tab(text: '1. Player'),
              Tab(text: '2. Plex'),
              Tab(text: '3. SMB'),
              Tab(text: '4. Parse'),
              Tab(text: '5. Xtream'),
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
            XtreamProbe(),
          ],
        ),
      ),
    );
  }
}
