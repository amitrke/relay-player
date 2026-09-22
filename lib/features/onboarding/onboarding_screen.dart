import 'package:flutter/material.dart';

import '../../core/theme/relay_theme.dart';
import '../../core/theme/relay_widgets.dart';

/// Screen 01 — Onboarding / disclaimer.
///
/// Implements `design/Onboarding.dc.html`, which draws four artboards: phone
/// (390×844), tablet (834×1112), desktop (1440×900) and TV (1920×1080, D-pad).
///
/// The copy here is load-bearing, not decorative. §1 and §12 both require that
/// onboarding frames the app generally — Plex, local files, a NAS — and never
/// leads with IPTV. "Advanced sources" appears as a muted, off-by-default note
/// rather than an offer, which is what makes the primary-purpose argument in §1
/// true of the product and not just of the store listing. Do not promote it
/// here, and do not remove the DRM line (§10).
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({
    super.key,
    required this.onAddSource,
    required this.onSkip,
  });

  final VoidCallback onAddSource;
  final VoidCallback onSkip;

  static const String tagline = 'Play from the sources you connect.';

  static const String blurb =
      'Subnext Player streams from sources you connect yourself — a Plex '
      'server, a home NAS or local files, or optionally an IPTV provider or '
      'playlist. We host no content.';

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);
    final form = RelayLayout.of(context);

    return Scaffold(
      backgroundColor: t.bg,
      body: SafeArea(
        child: switch (form) {
          RelayFormFactor.tv => _TvLayout(
              onAddSource: onAddSource,
            ),
          RelayFormFactor.desktop => _DesktopLayout(
              onAddSource: onAddSource,
              onSkip: onSkip,
            ),
          _ => _CompactLayout(
              form: form,
              onAddSource: onAddSource,
              onSkip: onSkip,
            ),
        },
      ),
    );
  }
}

/// The three sources onboarding introduces. Order matters: Plex and Local &
/// Network are the flagship, always-visible sources (§6, §7); Advanced sources
/// is last and rendered muted, because it is off by default (§8.2).
enum _SourceKind { plex, localNetwork, advanced }

@immutable
class _SourceCopy {
  const _SourceCopy(this.kind, this.title, this.subtitle);

  final _SourceKind kind;
  final String title;
  final String subtitle;

  bool get isMuted => kind == _SourceKind.advanced;

  IconData get icon => switch (kind) {
        _SourceKind.plex => Icons.dns_outlined,
        _SourceKind.localNetwork => Icons.folder_outlined,
        _SourceKind.advanced => Icons.tune_outlined,
      };

  /// Per-form-factor wording, taken from the artboards — desktop says "this
  /// PC", TV says "on this TV".
  static List<_SourceCopy> forForm(RelayFormFactor form) {
    final local = switch (form) {
      RelayFormFactor.desktop =>
        'Files on this PC, or a folder on a home NAS or SMB share.',
      RelayFormFactor.tv => 'A folder on a home NAS or SMB share.',
      _ => 'Video on this device, or a folder on a home NAS or SMB share.',
    };
    final plex = form == RelayFormFactor.tv
        ? 'Sign in with your own account on this TV.'
        : 'Your personal library, signed in with your own account.';
    final advanced = form == RelayFormFactor.tv
        ? 'Off by default. Turn on in Settings.'
        : 'Off by default. Turn on in Settings to use an IPTV provider or '
            'playlist.';

    return [
      _SourceCopy(_SourceKind.plex, 'Plex', plex),
      _SourceCopy(_SourceKind.localNetwork, 'Local & Network', local),
      _SourceCopy(_SourceKind.advanced, 'Advanced sources', advanced),
    ];
  }
}

/// One source row. Purely informational on this screen — tapping happens on
/// screen 02 (Add source), so these are not interactive here.
class _SourceRow extends StatelessWidget {
  const _SourceRow({required this.copy, required this.form});

  final _SourceCopy copy;
  final RelayFormFactor form;

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);
    final titleColor = copy.isMuted ? t.inkDim : t.ink;
    final iconSize = form == RelayFormFactor.tv ? 26.0 : 22.0;

    return RelaySurface(
      padding: EdgeInsets.all(form == RelayFormFactor.tv ? 18 : 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(copy.icon,
              size: iconSize, color: copy.isMuted ? t.inkDim : t.accent),
          SizedBox(width: form == RelayFormFactor.tv ? 16 : 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  copy.title,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: RelayLayout.bodySize(form) + 1,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  copy.subtitle,
                  style: TextStyle(
                    color: t.inkDim,
                    fontSize: RelayLayout.bodySize(form) - 1,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Masthead: mark, product name, tagline, blurb. Shared by every layout.
class _Masthead extends StatelessWidget {
  const _Masthead({required this.form, this.centered = false});

  final RelayFormFactor form;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);
    final align =
        centered ? CrossAxisAlignment.center : CrossAxisAlignment.start;
    final textAlign = centered ? TextAlign.center : TextAlign.start;
    final markSize = switch (form) {
      // Sized against the 540 dp a TV actually gives, not the 1080 px the TV
      // artboard was drawn at. At 84 the masthead alone ate a third of the
      // screen and pushed the only focusable control off the bottom.
      RelayFormFactor.tv => 60.0,
      RelayFormFactor.phone => 52.0,
      _ => 64.0,
    };

    return Column(
      crossAxisAlignment: align,
      children: [
        RelayMark(size: markSize),
        SizedBox(height: form == RelayFormFactor.tv ? 16 : 20),
        Text(
          'Subnext Player',
          textAlign: textAlign,
          style: TextStyle(
            color: t.ink,
            fontSize: RelayLayout.titleSize(form),
            fontWeight: FontWeight.w700,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          OnboardingScreen.tagline,
          textAlign: textAlign,
          style: TextStyle(
            color: t.accent,
            fontSize: RelayLayout.bodySize(form) + 2,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: form == RelayFormFactor.tv ? 20 : 14),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Text(
            OnboardingScreen.blurb,
            textAlign: textAlign,
            style: TextStyle(
              color: t.inkDim,
              fontSize: RelayLayout.bodySize(form),
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }
}

/// Phone and tablet: one scrolling column.
class _CompactLayout extends StatelessWidget {
  const _CompactLayout({
    required this.form,
    required this.onAddSource,
    required this.onSkip,
  });

  final RelayFormFactor form;
  final VoidCallback onAddSource;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final sources = _SourceCopy.forForm(form);

    return SingleChildScrollView(
      padding: RelayLayout.pagePadding(form).copyWith(top: 32, bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Masthead(form: form),
          SizedBox(height: form == RelayFormFactor.tablet ? 40 : 28),
          for (final s in sources) ...[
            _SourceRow(copy: s, form: form),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 18),
          const RelayDrmNotice(),
          const SizedBox(height: 24),
          RelayButton(label: 'Add your first source', onPressed: onAddSource),
          const SizedBox(height: 4),
          RelayTextButton(label: 'Not now', onPressed: onSkip),
        ],
      ),
    );
  }
}

/// Desktop: masthead and actions on the left, the source list on the right.
class _DesktopLayout extends StatelessWidget {
  const _DesktopLayout({required this.onAddSource, required this.onSkip});

  final VoidCallback onAddSource;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);
    const form = RelayFormFactor.desktop;
    final sources = _SourceCopy.forForm(form);

    return Padding(
      padding: RelayLayout.pagePadding(form).copyWith(top: 56, bottom: 48),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const _Masthead(form: form),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        RelayButton(
                            label: 'Add your first source',
                            onPressed: onAddSource),
                        const SizedBox(width: 8),
                        RelayTextButton(label: 'Not now', onPressed: onSkip),
                      ],
                    ),
                    const SizedBox(height: 28),
                    const RelayDrmNotice(),
                  ],
                ),
              ),
              const SizedBox(width: 64),
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 2, bottom: 12),
                      child: Text(
                        'Connect a source',
                        style: TextStyle(
                          color: t.ink,
                          fontSize: RelayLayout.bodySize(form) + 2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    for (final s in sources) ...[
                      _SourceRow(copy: s, form: form),
                      const SizedBox(height: 10),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// TV (10-foot). A separate tree, not a scaled phone layout (§11).
///
/// Differences that matter: everything is centred and larger, the primary
/// action takes autofocus so the remote lands somewhere useful, and there is a
/// persistent "OK to select" hint because a D-pad user has no affordance
/// telling them which button acts. There is no "Not now" — on TV the remote's
/// Back button already does that, and a second focusable target would just be
/// one more thing to traverse past.
class _TvLayout extends StatelessWidget {
  const _TvLayout({required this.onAddSource});

  final VoidCallback onAddSource;

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);
    const form = RelayFormFactor.tv;
    final sources = _SourceCopy.forForm(form);

    // Two columns, because a TV is a wide, short canvas: 960 x 540 dp, and only
    // 444 dp of height once the overscan margin is taken. Stacking a masthead,
    // a row of cards and a button vertically needed about 600 dp, so the button
    // — the only focusable control on the screen — was pushed off the bottom.
    // In a release build an overflowing Column clips in silence, with no banner
    // and no log, so it simply looked as though the remote did nothing.
    //
    // Splitting left/right spends the axis there is plenty of.
    return Padding(
      padding: RelayLayout.pagePadding(form),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Expanded(
            flex: 5,
            child: _Masthead(form: form, centered: false),
          ),
          const SizedBox(width: 56),
          Expanded(
            flex: 6,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final s in sources) ...[
                  _SourceRow(copy: s, form: form),
                  const SizedBox(height: 12),
                ],
                const SizedBox(height: 12),
                RelayButton(
                  label: 'Add source',
                  onPressed: onAddSource,
                  autofocus: true,
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: t.line),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('OK',
                          style: TextStyle(color: t.inkDim, fontSize: 16)),
                    ),
                    const SizedBox(width: 10),
                    Text('to select',
                        style: TextStyle(color: t.inkDim, fontSize: 18)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
