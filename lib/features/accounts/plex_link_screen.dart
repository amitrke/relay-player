import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/relay_theme.dart';
import '../../core/theme/relay_widgets.dart';
import 'plex_session.dart';

/// Connects a Plex account (§6) via the plex.tv/link PIN flow.
class PlexLinkScreen extends ConsumerWidget {
  const PlexLinkScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = RelayTheme.of(context);
    final f = RelayLayout.of(context);
    final state = ref.watch(plexSessionProvider);

    // Leave as soon as a server is actually connected.
    //
    // This cannot be left to the router's redirect. `/link` is reached with
    // `push` from `/add-source`, and go_router does not re-run a top-level
    // redirect for a pushed route when `refreshListenable` fires — pinned by
    // test/router_refresh_push_test.dart. Without this, a successful link fell
    // through the `switch` below to `_ConnectButton` and redrew "Connect to
    // Plex" under the heading "Connect to Plex", so a link that had worked was
    // indistinguishable from one that had not (issue #3).
    ref.listen(plexSessionProvider, (previous, next) {
      if (previous?.stage == PlexStage.ready ||
          next.stage != PlexStage.ready) {
        return;
      }
      if (!context.mounted) return;
      final name = next.servers.isEmpty ? null : next.servers.last.name;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(name == null ? 'Plex connected.' : 'Connected to $name.'),
        ),
      );
      // `go`, not `pop`: returning to "Add a source" after adding one reads as
      // the same "add a source" prompt again, which is the complaint. The
      // library is the thing they just earned.
      context.go('/library');
    });

    return Scaffold(
      backgroundColor: t.bg,
      // Linking Plex is optional now, so there has to be a way out. Without
      // this the screen is a dead end for anyone who opened it to look.
      appBar: context.canPop()
          ? AppBar(
              backgroundColor: t.bg,
              surfaceTintColor: Colors.transparent,
              foregroundColor: t.ink,
              elevation: 0,
            )
          : null,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: RelayLayout.pagePadding(f).add(
              const EdgeInsets.symmetric(vertical: 32),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    // Long-press the mark for the developer tools. Debug-only:
                    // the route does not exist in a release build.
                    child: GestureDetector(
                      onLongPress: kDebugMode
                          ? () => context.push('/debug')
                          : null,
                      child: const RelayMark(size: 52),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Connect to Plex',
                    style: TextStyle(
                      color: t.ink,
                      fontSize: RelayLayout.titleSize(f),
                      fontWeight: FontWeight.w700,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Relay Player plays what your own Plex server already '
                    'holds. Nothing is uploaded, and no account details reach '
                    'anyone but Plex.',
                    style: TextStyle(
                      color: t.inkDim,
                      fontSize: RelayLayout.bodySize(f),
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 28),
                  if (state.error != null) ...[
                    _ErrorNote(message: state.error!),
                    const SizedBox(height: 20),
                  ],
                  switch (state.stage) {
                    PlexStage.awaitingApproval =>
                      _LinkCodePanel(code: state.linkCode?.code ?? '····'),
                    PlexStage.choosingServer => const _ServerPicker(),
                    // Navigation above happens in the same frame as this
                    // rebuild, so `ready` needs an honest holding state. Left
                    // to `_`, it would show a "Connect to Plex" button for the
                    // frame after the connection succeeded.
                    PlexStage.ready =>
                      const _Spinner(label: 'Connected. Opening your library…'),
                    _ => _ConnectButton(busy: state.busy),
                  },
                  const SizedBox(height: 32),
                  const RelayDrmNotice(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ConnectButton extends ConsumerWidget {
  const _ConnectButton({required this.busy});

  final bool busy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (busy) return const _Spinner(label: 'Contacting Plex…');
    return RelayButton(
      label: 'Connect to Plex',
      autofocus: true,
      onPressed: () => ref.read(plexSessionProvider.notifier).startLink(),
    );
  }
}

/// The four-character code, shown large enough to read off a TV.
class _LinkCodePanel extends ConsumerWidget {
  const _LinkCodePanel({required this.code});

  final String code;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = RelayTheme.of(context);
    final f = RelayLayout.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'On any device, open plex.tv/link and enter:',
          style: TextStyle(
            color: t.inkDim,
            fontSize: RelayLayout.bodySize(f),
          ),
        ),
        const SizedBox(height: 16),
        RelaySurface(
          borderColor: t.accent,
          padding: const EdgeInsets.symmetric(vertical: 28),
          child: Center(
            child: SelectableText(
              code,
              style: TextStyle(
                color: t.ink,
                fontSize: f == RelayFormFactor.tv ? 60 : 52,
                fontWeight: FontWeight.w700,
                letterSpacing: 14,
                height: 1,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: t.accent,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Waiting for approval…',
              style: TextStyle(
                color: t.inkDim,
                fontSize: RelayLayout.bodySize(f),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Center(
          child: RelayTextButton(
            label: 'Copy code',
            onPressed: () => Clipboard.setData(ClipboardData(text: code)),
          ),
        ),
      ],
    );
  }
}

class _ServerPicker extends ConsumerWidget {
  const _ServerPicker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = RelayTheme.of(context);
    final f = RelayLayout.of(context);
    final state = ref.watch(plexSessionProvider);

    if (state.busy) return const _Spinner(label: 'Connecting…');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Choose a server',
          style: TextStyle(
            color: t.ink,
            fontSize: RelayLayout.bodySize(f) + 3,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        for (final server in state.available) ...[
          RelaySurface(
            autofocus: server == state.available.first,
            onTap: () =>
                ref.read(plexSessionProvider.notifier).connect(server),
            child: Row(
              children: [
                Icon(Icons.dns_outlined, color: t.inkDim, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        server.name,
                        style: TextStyle(
                          color: t.ink,
                          fontSize: RelayLayout.bodySize(f) + 1,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        [
                          if (server.owned) 'Yours' else 'Shared with you',
                          if (server.relay) 'via relay',
                        ].join(' · '),
                        style: TextStyle(
                          color: t.inkDim,
                          fontSize: RelayLayout.bodySize(f) - 1,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: t.inkDim),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _Spinner extends StatelessWidget {
  const _Spinner({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2, color: t.accent),
        ),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(color: t.inkDim)),
      ],
    );
  }
}

class _ErrorNote extends StatelessWidget {
  const _ErrorNote({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);
    return RelaySurface(
      borderColor: const Color(0xFFB8574E),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFB8574E), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: t.ink, fontSize: 13, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}
