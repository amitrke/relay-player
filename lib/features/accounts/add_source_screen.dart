
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../core/theme/relay_theme.dart';
import '../../core/theme/relay_widgets.dart';

/// Screen 02 — Add a source.
///
/// Implements `design/Add Source.dc.html` (phone; desktop with Plex pairing).
///
/// The canvas gates its Advanced-sources block on an `advancedEnabled` prop,
/// which is §8.2 made literal: while the toggle is off there are no Xtream/M3U
/// entries in Add source at all — not disabled ones, absent ones. When off, a
/// single muted line points at Settings. Keep it that way; a greyed-out row
/// still advertises the feature, which is the thing §1 is trying not to do.
class AddSourceScreen extends StatelessWidget {
  const AddSourceScreen({
    super.key,
    required this.advancedEnabled,
    required this.onBack,
    required this.onPickSource,
    this.onOpenSettings,
  });

  /// Mirrors the Advanced sources toggle (§8.2).
  final bool advancedEnabled;
  final VoidCallback onBack;
  final ValueChanged<SourceKind> onPickSource;
  final VoidCallback? onOpenSettings;

  /// The privacy line the canvas leads with. It is the no-backend decision
  /// (§16) stated where it is most reassuring — at the moment credentials are
  /// about to be typed.
  static const String privacyNote =
      'Credentials stay on this device. Nothing is sent to us — there is no '
      'account and no server in the middle.';

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);
    final form = RelayLayout.of(context);

    return Scaffold(
      backgroundColor: t.bg,
      body: SafeArea(
        child: form == RelayFormFactor.desktop || form == RelayFormFactor.tv
            ? _DesktopAddSource(
                advancedEnabled: advancedEnabled,
                onPickSource: onPickSource,
              )
            : _CompactAddSource(
                advancedEnabled: advancedEnabled,
                onBack: onBack,
                onPickSource: onPickSource,
                onOpenSettings: onOpenSettings,
              ),
      ),
    );
  }
}

/// Every source the app can add. [isAdvanced] entries are reachable only when
/// the §8.2 toggle is on.
///
/// Only sources that are built belong here. M3U/XMLTV and Provider Profile
/// import (§5, §8.3) were listed until 2026-09-21 and answered a tap with "not
/// available in this build"; they come back with v1.2.0 on the RELEASING.md
/// ladder, together with their screens.
enum SourceKind {
  plex('Plex server', 'Link with code', Icons.dns_outlined, false),
  localFiles('Video on this device', 'Scan your media library, or pick a single folder to keep access to.', Icons.smartphone_outlined, false),
  smb('Network share (SMB)', 'A NAS or Windows share on your home network.', Icons.lan_outlined, false),
  xtream('Xtream Codes login', 'Host, username and password from your provider.', Icons.vpn_key_outlined, true);

  const SourceKind(this.title, this.subtitle, this.icon, this.isAdvanced);

  final String title;
  final String subtitle;
  final IconData icon;
  final bool isAdvanced;

  static List<SourceKind> get flagship =>
      values.where((k) => !k.isAdvanced).toList();

  static List<SourceKind> get advanced =>
      values.where((k) => k.isAdvanced).toList();
}

class _SourceTile extends StatelessWidget {
  const _SourceTile({required this.kind, required this.onTap});

  final SourceKind kind;
  final VoidCallback onTap;

  /// Plex's subtitle is longer on this screen than the enum's short form.
  static const Map<SourceKind, String> _expanded = {
    SourceKind.plex:
        'Approve this device in your browser. Your own server plus anything '
            'shared with you.',
  };

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);
    final form = RelayLayout.of(context);
    return RelaySurface(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(kind.icon, size: 22, color: t.accent),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  kind.title,
                  style: TextStyle(
                    color: t.ink,
                    fontSize: RelayLayout.bodySize(form) + 1,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _expanded[kind] ?? kind.subtitle,
                  style: TextStyle(
                      color: t.inkDim,
                      fontSize: RelayLayout.bodySize(form) - 1,
                      height: 1.45),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, size: 20, color: t.inkDim),
        ],
      ),
    );
  }
}

class _CompactAddSource extends StatelessWidget {
  const _CompactAddSource({
    required this.advancedEnabled,
    required this.onBack,
    required this.onPickSource,
    this.onOpenSettings,
  });

  final bool advancedEnabled;
  final VoidCallback onBack;
  final ValueChanged<SourceKind> onPickSource;
  final VoidCallback? onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);
    final form = RelayLayout.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: RelayLayout.pagePadding(form).copyWith(top: 8, bottom: 8),
          child: Row(
            children: [
              IconButton(
                onPressed: onBack,
                icon: Icon(Icons.chevron_left, color: t.ink),
                tooltip: 'Back',
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding:
                RelayLayout.pagePadding(form).copyWith(bottom: 32),
            children: [
              Text(
                'Add a source',
                style: TextStyle(
                  color: t.ink,
                  fontSize: RelayLayout.titleSize(form),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                AddSourceScreen.privacyNote,
                style: TextStyle(
                    color: t.inkDim,
                    fontSize: RelayLayout.bodySize(form),
                    height: 1.55),
              ),
              const SizedBox(height: 22),
              for (final kind in SourceKind.flagship) ...[
                _SourceTile(kind: kind, onTap: () => onPickSource(kind)),
                const SizedBox(height: 10),
              ],
              if (advancedEnabled) ...[
                const SizedBox(height: 14),
                _SectionLabel(text: 'Advanced sources'),
                const SizedBox(height: 10),
                for (final kind in SourceKind.advanced) ...[
                  _SourceTile(kind: kind, onTap: () => onPickSource(kind)),
                  const SizedBox(height: 10),
                ],
              ] else ...[
                const SizedBox(height: 18),
                _AdvancedOffHint(onOpenSettings: onOpenSettings),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        color: t.inkDim,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
      ),
    );
  }
}

/// Shown in place of the Advanced block while the toggle is off.
///
/// One muted sentence, pointing at Settings — deliberately not a button that
/// enables the feature. §8.2 requires the acknowledgement flow to happen in
/// Settings, so this only navigates there.
class _AdvancedOffHint extends StatefulWidget {
  const _AdvancedOffHint({this.onOpenSettings});

  final VoidCallback? onOpenSettings;

  @override
  State<_AdvancedOffHint> createState() => _AdvancedOffHintState();
}

class _AdvancedOffHintState extends State<_AdvancedOffHint> {
  // Owned rather than built per-frame: a TapGestureRecognizer must be disposed.
  late final TapGestureRecognizer _tap = TapGestureRecognizer()
    ..onTap = () => widget.onOpenSettings?.call();

  @override
  void dispose() {
    _tap.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);
    final form = RelayLayout.of(context);
    final style = TextStyle(
        color: t.inkDim, fontSize: RelayLayout.bodySize(form) - 1, height: 1.5);

    return Text.rich(
      TextSpan(
        style: style,
        children: [
          const TextSpan(
              text: 'Looking for an IPTV provider or playlist? Turn on '),
          TextSpan(
            text: 'Advanced sources',
            style:
                style.copyWith(color: t.accent, fontWeight: FontWeight.w600),
            recognizer: widget.onOpenSettings == null ? null : _tap,
          ),
          const TextSpan(text: ' in Settings.'),
        ],
      ),
    );
  }
}

/// Desktop: a source-type rail on the left, the active flow on the right.
/// The canvas shows the Plex pairing step, which is the only flow with real
/// state worth drawing (§6 — PIN create, poll, expiry).
class _DesktopAddSource extends StatelessWidget {
  const _DesktopAddSource({
    required this.advancedEnabled,
    required this.onPickSource,
  });

  final bool advancedEnabled;
  final ValueChanged<SourceKind> onPickSource;

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 340,
          child: Container(
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: t.line)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SectionLabel(text: 'Source type'),
                const SizedBox(height: 14),
                _RailItem(
                  title: 'Plex server',
                  subtitle: 'Link with a code',
                  icon: Icons.dns_outlined,
                  selected: false,
                  onTap: () => onPickSource(SourceKind.plex),
                ),
                _RailItem(
                  title: 'Files on this PC',
                  subtitle: 'Choose a folder',
                  icon: Icons.folder_outlined,
                  selected: false,
                  onTap: () => onPickSource(SourceKind.localFiles),
                ),
                _RailItem(
                  title: 'Network share (SMB)',
                  subtitle: 'NAS or Windows share',
                  icon: Icons.lan_outlined,
                  selected: false,
                  onTap: () => onPickSource(SourceKind.smb),
                ),
                if (advancedEnabled) ...[
                  const SizedBox(height: 14),
                  _SectionLabel(text: 'Advanced sources'),
                  const SizedBox(height: 10),
                  for (final kind in SourceKind.advanced)
                    _RailItem(
                      title: kind.title,
                      subtitle: kind.subtitle,
                      icon: kind.icon,
                      selected: false,
                      onTap: () => onPickSource(kind),
                    ),
                ],
                const Spacer(),
                Text(
                  // The artboard said "Windows Credential Manager", which is
                  // wrong on every other platform this ships to. §3's rule is
                  // what actually matters and it is platform-neutral.
                  'Credentials are stored in your device keystore, never in '
                  'the app database.',
                  style:
                      TextStyle(color: t.inkDim, fontSize: 12, height: 1.5),
                ),
              ],
            ),
          ),
        ),
        // NOT the canvas's PlexPairingPanel. That draws a mock pairing step
        // with a hardcoded code, and wiring it into the real app showed a
        // fabricated code a user could actually try to enter at plex.tv/link.
        // Picking Plex opens the real link screen instead.
        const Expanded(child: _PickAPrompt()),
      ],
    );
  }
}

/// The right-hand pane before a source type is chosen.
class _PickAPrompt extends StatelessWidget {
  const _PickAPrompt();

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_link, color: t.inkDim, size: 34),
            const SizedBox(height: 16),
            Text(
              'Choose a source type to get started.',
              textAlign: TextAlign.center,
              style: TextStyle(color: t.inkDim, fontSize: 14, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _RailItem extends StatelessWidget {
  const _RailItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected ? t.surface : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: selected ? t.accent : Colors.transparent),
            ),
            child: Row(
              children: [
                Icon(icon, size: 20, color: selected ? t.accent : t.inkDim),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: TextStyle(
                              color: t.ink,
                              fontSize: 14,
                              fontWeight: FontWeight.w600)),
                      Text(subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: t.inkDim, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

