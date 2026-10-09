import 'package:flutter/material.dart';

import '../advanced_sources/xtream_accounts_pane.dart';
import 'about_pane.dart';
import 'ai_pane.dart';
import 'metadata_pane.dart';
import 'privacy_pane.dart';
import 'playback_panes.dart';
import 'sources_pane.dart';

import '../../core/theme/relay_theme.dart';
import '../../core/theme/relay_tokens.dart';
import '../../core/theme/relay_widgets.dart';
import '../../core/theme/theme_controller.dart';

/// Screen 09 — Settings.
///
/// Implements `design/Settings.dc.html`, reconciled with §12.1. Sections, in
/// order: Sources, Appearance, Playback, Subtitles, AI features, Advanced
/// sources, Privacy and data, About.
///
/// Two invariants the design gets right and that are easy to erode:
///
/// 1. **Advanced sources and AI features are independent switches** (§9.5).
///    They must not read as one "power user" bundle, which is why they are
///    separate sections rather than neighbours under a shared heading.
/// 2. **Consent is per feature × provider, never one blanket AI opt-in**
///    (§9.3). Each row is independently revocable and revoking keeps the key.
///
/// Only sections with [SettingsSection.built] set appear in the app. The rest
/// are reachable from the design gallery alone, through
/// [showUnbuiltSections] — see that field for why this is not cosmetic.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.theme,
    required this.state,
    required this.onStateChanged,
    this.showUnbuiltSections = false,
  });

  final ThemeController theme;
  final SettingsState state;
  final ValueChanged<SettingsState> onStateChanged;

  /// Gallery only. Until 2026-09-21 every section was on the desktop/TV rail,
  /// and that layout *opened* on AI features — a pane rendering the canvas's
  /// demo data: an OpenAI key "saved", a LAN Ollama "reachable", and consent
  /// rows "granted" on dates nobody chose. Shipped, that is a TV user's first
  /// view of Settings claiming the app sends their watch history to a cloud
  /// provider it has never contacted, which a reviewer checks against the
  /// privacy policy and the data-safety form (§9.3, §9.4). Playback and
  /// Subtitles showed a "Not implemented yet" pane pointing at a repo file.
  final bool showUnbuiltSections;

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);
    final form = RelayLayout.of(context);
    final wide = form == RelayFormFactor.desktop || form == RelayFormFactor.tv;

    return Scaffold(
      backgroundColor: t.bg,
      body: SafeArea(
        child: wide
            ? _DesktopSettings(
                theme: theme,
                state: state,
                onStateChanged: onStateChanged,
                showUnbuiltSections: showUnbuiltSections,
              )
            : _PhoneSettings(
                theme: theme,
                state: state,
                onStateChanged: onStateChanged,
              ),
      ),
    );
  }
}

/// The settings this screen can change. Immutable so the gallery (and later,
/// Riverpod) can drive it without hidden mutation.
@immutable
class SettingsState {
  const SettingsState({
    this.advancedSourcesEnabled = false,
    this.crashReportingEnabled = false,
    this.section = SettingsSection.appearance,
  });

  /// §8.2 — off by default on first install.
  final bool advancedSourcesEnabled;

  /// §16 — opt-in, never on by default.
  final bool crashReportingEnabled;

  /// Which section the desktop rail has selected. Defaults to Appearance, the
  /// section users actually visit (§12.2), and never to an unbuilt one: the
  /// default used to be AI features, which is how the demo pane became the
  /// first thing the real TV layout showed.
  final SettingsSection section;

  SettingsState copyWith({
    bool? advancedSourcesEnabled,
    bool? crashReportingEnabled,
    SettingsSection? section,
  }) => SettingsState(
    advancedSourcesEnabled:
        advancedSourcesEnabled ?? this.advancedSourcesEnabled,
    crashReportingEnabled: crashReportingEnabled ?? this.crashReportingEnabled,
    section: section ?? this.section,
  );
}

/// §12.1's section list, in order.
///
/// [built] is whether a section has real controls behind it. An unbuilt one is
/// absent from the app rather than shown as a stub, for the same reason
/// Advanced sources is absent rather than greyed out while off: a section that
/// exists advertises a feature. Flip it only when the pane reads and writes
/// real state. AI features was the cautionary case: it was a finished-looking
/// pane of demo data until 2026-10-09.
enum SettingsSection {
  sources('Sources', built: true),
  appearance('Appearance', built: true),
  // Built 2026-09-23: skip length and preferred audio language, and
  // subtitles on/off, language and size, all read by the player.
  playback('Playback', built: true),
  subtitles('Subtitles', built: true),
  // Built 2026-10-08: the user's own TMDB key, which unlocks genre, rating and
  // original-language filters in Search.
  metadata('Metadata', built: true),
  // Built 2026-10-09: one OpenAI-compatible provider (OpenRouter, OpenAI,
  // Ollama or any other), a key in secure storage, and a real consent record.
  aiFeatures('AI features', built: true),
  advancedSources('Advanced sources', built: true),
  // Unbuilt from 2026-09-22 to 2026-10-09: its only control was "Send crash
  // reports", which stored a preference nothing read while the privacy policy
  // says no crash reports are sent. Built again around clearing cached data,
  // which does something. The crash switch stays out until crash reporting
  // (#6) exists.
  privacy('Privacy and data', built: true),
  about('About', built: true);

  const SettingsSection(this.label, {this.built = false});
  final String label;
  final bool built;
}

// --- Phone ------------------------------------------------------------

class _PhoneSettings extends StatelessWidget {
  const _PhoneSettings({
    required this.theme,
    required this.state,
    required this.onStateChanged,
  });

  final ThemeController theme;
  final SettingsState state;
  final ValueChanged<SettingsState> onStateChanged;

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);
    final form = RelayLayout.of(context);

    return ListView(
      padding: RelayLayout.pagePadding(form).copyWith(top: 20, bottom: 40),
      children: [
        Text(
          'Settings',
          style: TextStyle(
            color: t.ink,
            fontSize: RelayLayout.titleSize(form),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 24),

        // Appearance first: it is the section users actually visit, and theme
        // is a real runtime setting (§12.2).
        _Section(
          title: 'Appearance',
          child: _AppearanceControls(theme: theme),
        ),
        const SizedBox(height: 22),

        const _Section(title: 'Sources', child: SourcesPane()),
        const SizedBox(height: 22),

        const _Section(title: 'Playback', child: PlaybackPane()),
        const SizedBox(height: 22),

        const _Section(title: 'Subtitles', child: SubtitlesPane()),
        const SizedBox(height: 22),

        const _Section(title: 'Metadata', child: MetadataPane()),
        const SizedBox(height: 22),

        const _Section(title: 'AI features', child: AiPane()),
        const SizedBox(height: 22),

        _Section(
          title: 'Advanced sources',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AdvancedSourcesControl(
                enabled: state.advancedSourcesEnabled,
                onChanged: (v) =>
                    setAdvancedSources(context, state, onStateChanged, v),
              ),
              if (state.advancedSourcesEnabled) ...[
                const SizedBox(height: 18),
                const XtreamAccountsPane(),
              ],
            ],
          ),
        ),
        const SizedBox(height: 22),

        // Hand-listed here rather than driven by the enum, so it has to ask.
        if (SettingsSection.privacy.built) ...[
          const _Section(title: 'Privacy and data', child: PrivacyPane()),
          const SizedBox(height: 22),
        ],

        // Last, as in §12.1: compliance-shaped, rarely visited, but required.
        const _Section(title: 'About', child: AboutPane()),
      ],
    );
  }
}

/// The §8.2 acknowledgement. Separate from, and additional to, the general
/// onboarding disclaimer — this is a materially different consent moment, and
/// the wording is chosen to be specific rather than reassuring.
Future<bool?> showAdvancedSourcesDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (context) {
      final t = RelayTheme.of(context);
      return AlertDialog(
        backgroundColor: t.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          'Turning on advanced sources',
          style: TextStyle(
            color: t.ink,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You are about to connect a third-party provider using your own '
              'credentials.',
              style: TextStyle(color: t.ink, fontSize: 14, height: 1.55),
            ),
            const SizedBox(height: 12),
            Text(
              'Subnext Player does not provide, host, or endorse any content or '
              'provider. You supply the address and the login, and the app '
              'plays whatever that address returns.',
              style: TextStyle(color: t.inkDim, fontSize: 13, height: 1.6),
            ),
            const SizedBox(height: 12),
            Text(
              'You are responsible for holding the rights to whatever you '
              'connect to.',
              style: TextStyle(color: t.inkDim, fontSize: 13, height: 1.6),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(foregroundColor: t.inkDim),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: t.accent,
              foregroundColor: t.accentInk,
            ),
            child: const Text('I understand — turn on'),
          ),
        ],
      );
    },
  );
}

class _AdvancedSourcesControl extends StatelessWidget {
  const _AdvancedSourcesControl({
    required this.enabled,
    required this.onChanged,
  });

  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ToggleRow(
          title: 'IPTV provider or playlist',
          // Names only what this build has. It said "the guide, and Xtream or
          // M3U sources" before either existed (v1.2.0 on the RELEASING.md
          // ladder); widen it again when they land.
          subtitle: 'Adds Live TV and Xtream Codes logins.',
          value: enabled,
          onChanged: onChanged,
        ),
        if (enabled) ...[
          const SizedBox(height: 10),
          Text(
            'Turning this off later hides Live TV but keeps any '
            'accounts you added.',
            style: TextStyle(color: t.inkDim, fontSize: 12, height: 1.5),
          ),
        ],
      ],
    );
  }
}

class _AppearanceControls extends StatelessWidget {
  const _AppearanceControls({required this.theme});

  final ThemeController theme;

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Theme',
          style: TextStyle(
            color: t.ink,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final p in RelayPalette.values)
              _ThemeChip(
                label: p.label,
                selected: theme.palette == p,
                onTap: () => theme.palette = p,
              ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          'Accent',
          style: TextStyle(
            color: t.ink,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            for (final c in RelayAccents.swatches) ...[
              _Swatch(
                color: c,
                selected: theme.accent.toARGB32() == c.toARGB32(),
                onTap: () => theme.accent = c,
              ),
              const SizedBox(width: 10),
            ],
          ],
        ),
      ],
    );
  }
}

class _ThemeChip extends StatelessWidget {
  const _ThemeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? t.accent : Colors.transparent,
          border: Border.all(color: selected ? t.accent : t.line),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? t.accentInk : t.inkDim,
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? t.ink : Colors.transparent,
            width: 2,
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: TextStyle(
            color: t.inkDim,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 10),
        RelaySurface(child: child),
      ],
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: t.ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(color: t.inkDim, fontSize: 12, height: 1.5),
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: t.accentInk,
          activeTrackColor: t.accent,
          inactiveTrackColor: t.line,
          inactiveThumbColor: t.inkDim,
        ),
      ],
    );
  }
}

// --- Desktop ----------------------------------------------------------

class _DesktopSettings extends StatelessWidget {
  const _DesktopSettings({
    required this.theme,
    required this.state,
    required this.onStateChanged,
    required this.showUnbuiltSections,
  });

  final ThemeController theme;
  final SettingsState state;
  final ValueChanged<SettingsState> onStateChanged;
  final bool showUnbuiltSections;

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);
    final sections = [
      for (final s in SettingsSection.values)
        if (s.built || showUnbuiltSections) s,
    ];
    // Belt and braces for the default above: whatever selected an unbuilt
    // section, the app never renders one, and falls back to the same place
    // the default opens rather than to whichever section the rail lists first.
    final section = sections.contains(state.section)
        ? state.section
        : SettingsSection.appearance;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 260,
          child: Container(
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: t.line)),
            ),
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final s in sections)
                  _RailRow(
                    label: s.label,
                    selected: section == s,
                    onTap: () => onStateChanged(state.copyWith(section: s)),
                  ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(40, 32, 40, 32),
            child: switch (section) {
              SettingsSection.aiFeatures => const _DesktopPane(
                title: 'AI features',
                child: AiPane(),
              ),
              SettingsSection.appearance => SingleChildScrollView(
                child: _AppearanceControls(theme: theme),
              ),
              SettingsSection.sources => const _DesktopPane(
                title: 'Sources',
                child: SourcesPane(),
              ),
              SettingsSection.playback => const _DesktopPane(
                title: 'Playback',
                child: PlaybackPane(),
              ),
              SettingsSection.subtitles => const _DesktopPane(
                title: 'Subtitles',
                child: SubtitlesPane(),
              ),
              SettingsSection.metadata => const _DesktopPane(
                title: 'Metadata',
                child: MetadataPane(),
              ),
              SettingsSection.advancedSources => _DesktopPane(
                title: 'Advanced sources',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _AdvancedSourcesControl(
                      enabled: state.advancedSourcesEnabled,
                      onChanged: (v) =>
                          setAdvancedSources(context, state, onStateChanged, v),
                    ),
                    if (state.advancedSourcesEnabled) ...[
                      const SizedBox(height: 22),
                      const XtreamAccountsPane(),
                    ],
                  ],
                ),
              ),
              SettingsSection.privacy => const _DesktopPane(
                title: 'Privacy and data',
                child: PrivacyPane(),
              ),
              SettingsSection.about => const _DesktopPane(
                title: 'About',
                child: AboutPane(),
              ),
            },
          ),
        ),
      ],
    );
  }
}

class _RailRow extends StatelessWidget {
  const _RailRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);
    // Was a bare Material/InkWell, which takes D-pad focus but draws nothing
    // for it — confirmed still invisible on the emulator (architecture.md
    // §11 defect 3). RelayTappable is what makes every other focusable
    // surface in the app show a ring; this section list was the one left over.
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: RelayTappable(
        borderRadius: 8,
        onTap: onTap,
        child: Container(
          color: selected ? t.bg : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? t.ink : t.inkDim,
              fontSize: 13.5,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

/// Turning Advanced Sources ON requires the §8.2 acknowledgement; turning it
/// OFF is free and non-destructive, and configured accounts survive.
///
/// Shared by both layouts so the acknowledgement cannot be bypassed by whichever
/// one happens to be on screen.
Future<void> setAdvancedSources(
  BuildContext context,
  SettingsState state,
  ValueChanged<SettingsState> onStateChanged,
  bool value,
) async {
  if (!value) {
    onStateChanged(state.copyWith(advancedSourcesEnabled: false));
    return;
  }
  final accepted = await showAdvancedSourcesDialog(context);
  if (accepted == true) {
    onStateChanged(state.copyWith(advancedSourcesEnabled: true));
  }
}

/// A titled pane in the desktop rail layout.
class _DesktopPane extends StatelessWidget {
  const _DesktopPane({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: t.ink,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}
