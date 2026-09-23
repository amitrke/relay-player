import 'package:dart_plex/dart_plex.dart' show PlexResource;
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

    final stage = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (state.error != null) ...[
          _ErrorNote(message: state.error!),
          const SizedBox(height: 20),
        ],
        switch (state.stage) {
          PlexStage.awaitingApproval =>
            _LinkCodePanel(code: state.linkCode?.code ?? '····'),
          PlexStage.choosingServer => const _ServerPicker(),
          // Navigation above happens in the same frame as this rebuild, so
          // `ready` needs an honest holding state. Left to `_`, it would show
          // a "Connect to Plex" button for the frame after the connection
          // succeeded.
          PlexStage.ready =>
            const _Spinner(label: 'Connected. Opening your library…'),
          _ => _ConnectButton(busy: state.busy),
        },
      ],
    );

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
        child: f == RelayFormFactor.tv
            ? _TvLayout(stage: stage)
            : Center(
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
                        const _Intro(),
                        const SizedBox(height: 28),
                        stage,
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

/// Two columns on a TV, as TV onboarding already does (#5).
///
/// A 1080p TV is 960 × 540 dp (§11), and the AppBar leaves roughly 430 of
/// that. Stacked, the phone column put the code panel near the bottom edge and
/// "Waiting for approval…" under it, off screen, with nothing focusable above
/// it to scroll it into view. Side by side, the part that changes (code,
/// waiting state, server list) gets the full height of its own column.
class _TvLayout extends StatelessWidget {
  const _TvLayout({required this.stage});

  final Widget stage;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: RelayLayout.pagePadding(RelayFormFactor.tv),
      child: Row(
        children: [
          const Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Intro(),
                  SizedBox(height: 24),
                  RelayDrmNotice(),
                ],
              ),
            ),
          ),
          const SizedBox(width: 48),
          Expanded(
            child: Center(
              // Scrolls only for a long server list; directional focus
              // traversal keeps the focused row in view.
              child: SingleChildScrollView(child: stage),
            ),
          ),
        ],
      ),
    );
  }
}

class _Intro extends StatelessWidget {
  const _Intro();

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);
    final f = RelayLayout.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          // Long-press the mark for the developer tools. Debug-only: the route
          // does not exist in a release build.
          child: GestureDetector(
            onLongPress: kDebugMode ? () => context.push('/debug') : null,
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
          'Subnext Player plays what your own Plex server already holds. '
          'Nothing is uploaded, and no account details reach anyone but Plex.',
          style: TextStyle(
            color: t.inkDim,
            fontSize: RelayLayout.bodySize(f),
            height: 1.55,
          ),
        ),
      ],
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
///
/// The waiting state sits *inside* the panel, directly under the code, so the
/// two are never separated by a fold (#5). It used to be a 16 dp spinner in
/// dim text below the panel, which on a TV was either off screen or too small
/// to see from the sofa.
class _LinkCodePanel extends ConsumerWidget {
  const _LinkCodePanel({required this.code});

  final String code;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = RelayTheme.of(context);
    final f = RelayLayout.of(context);
    final tv = f == RelayFormFactor.tv;
    final codeStyle = TextStyle(
      color: t.ink,
      fontSize: tv ? 60 : 52,
      fontWeight: FontWeight.w700,
      letterSpacing: 14,
      height: 1,
    );

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
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            children: [
              // Plain text on a TV: SelectableText takes a focus node, which a
              // D-pad can land on with no visible ring and nothing to do.
              if (tv)
                Text(code, style: codeStyle)
              else
                SelectableText(code, style: codeStyle),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: tv ? 28 : 18,
                    height: tv ? 28 : 18,
                    child: CircularProgressIndicator(
                      strokeWidth: tv ? 3 : 2,
                      color: t.accent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      'Waiting for approval…',
                      style: TextStyle(
                        color: t.ink,
                        fontSize: RelayLayout.bodySize(f),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Focused on arrival. The "Connect to Plex" button that held focus
            // is gone once linking starts, and without a new target focus sat
            // on a widget that no longer existed (#5).
            RelayTextButton(
              label: 'Cancel',
              autofocus: true,
              onPressed: () =>
                  ref.read(plexSessionProvider.notifier).cancelLink(),
            ),
            // A clipboard on a TV goes nowhere useful.
            if (!tv)
              RelayTextButton(
                label: 'Copy code',
                onPressed: () => Clipboard.setData(ClipboardData(text: code)),
              ),
          ],
        ),
      ],
    );
  }
}

/// Picks a server when the account can see more than one (#5).
///
/// Grouped into the viewer's own servers and those shared with them, each
/// sorted online-first and then by name, so D-pad travel is predictable and a
/// dead server is not the first thing focused. Servers already connected are
/// left out, via [PlexState.connectable].
///
/// Not done here: naming who shared a server. plex.tv sends it (`sourceTitle`)
/// but `dart_plex` 0.1.2 does not parse it, so two friends' servers with the
/// default name are still indistinguishable. That needs the raw field read or
/// a package change (§6).
class _ServerPicker extends ConsumerStatefulWidget {
  const _ServerPicker();

  @override
  ConsumerState<_ServerPicker> createState() => _ServerPickerState();
}

class _ServerPickerState extends ConsumerState<_ServerPicker> {
  /// The row the viewer picked. Probing a shared server can take about 12 s
  /// (2 s local, 4 s remote, 6 s relay), so that row says it is working while
  /// the rest of the list stays put, instead of the whole list being swapped
  /// for one "Connecting…".
  String? _connecting;

  static List<PlexResource> _sorted(Iterable<PlexResource> servers) =>
      servers.toList()
        ..sort((a, b) {
          if (a.presence != b.presence) return a.presence ? -1 : 1;
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });

  void _pick(PlexResource server) {
    if (ref.read(plexSessionProvider).busy) return;
    setState(() => _connecting = server.clientIdentifier);
    ref.read(plexSessionProvider.notifier).connect(server);
  }

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);
    final f = RelayLayout.of(context);
    final state = ref.watch(plexSessionProvider);
    final candidates = state.connectable;
    final own = _sorted(candidates.where((s) => s.owned));
    final shared = _sorted(candidates.where((s) => !s.owned));
    final first = [...own, ...shared].firstOrNull;

    Widget header(String label) => Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 10),
          child: Text(
            label.toUpperCase(),
            style: TextStyle(
              color: t.inkDim,
              fontSize: RelayLayout.bodySize(f) - 2,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
        );

    Widget row(PlexResource server) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _ServerRow(
            server: server,
            autofocus: server == first,
            connecting: state.busy && _connecting == server.clientIdentifier,
            onTap: () => _pick(server),
          ),
        );

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
        const SizedBox(height: 8),
        if (candidates.isEmpty)
          Text(
            'Every server on this account is already connected.',
            style:
                TextStyle(color: t.inkDim, fontSize: RelayLayout.bodySize(f)),
          ),
        if (own.isNotEmpty) ...[
          header('Your servers'),
          for (final s in own) row(s),
        ],
        if (shared.isNotEmpty) ...[
          header('Shared with you'),
          for (final s in shared) row(s),
        ],
      ],
    );
  }
}

class _ServerRow extends StatelessWidget {
  const _ServerRow({
    required this.server,
    required this.autofocus,
    required this.connecting,
    required this.onTap,
  });

  final PlexResource server;
  final bool autofocus;
  final bool connecting;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);
    final f = RelayLayout.of(context);
    final detail = connecting
        ? 'Connecting… this can take a few seconds'
        : [
            // Still tappable: plex.tv's presence can lag a server that has
            // just woken, and refusing the tap would be the worse mistake.
            if (!server.presence) 'Offline',
            // Plex Relay is bandwidth-capped, which is what matters about it.
            if (server.relay) 'Plex Relay only, playback may be limited',
          ].join(' · ');

    return Opacity(
      opacity: server.presence ? 1 : 0.55,
      child: RelaySurface(
        autofocus: autofocus,
        onTap: onTap,
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
                  if (detail.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      detail,
                      style: TextStyle(
                        color: t.inkDim,
                        fontSize: RelayLayout.bodySize(f) - 1,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (connecting)
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: t.accent,
                ),
              )
            else
              Icon(Icons.chevron_right, color: t.inkDim),
          ],
        ),
      ),
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
