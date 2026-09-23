import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/relay_theme.dart';
import '../../core/theme/relay_widgets.dart';
import '../player/playback_prefs.dart';

/// Settings → Playback (§12.1).
///
/// Only settings the player actually reads. The section was hidden until
/// 2026-09-23 because it had none, for the reason `SettingsSection.built`
/// gives: a section that exists advertises controls.
class PlaybackPane extends ConsumerWidget {
  const PlaybackPane({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(playbackPrefsProvider);
    final edit = ref.read(playbackPrefsProvider.notifier).edit;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ChoiceRow(
          title: 'Skip back and forward',
          subtitle: 'The skip buttons, the fast-forward and rewind keys on a '
              'remote, and the first step when moving along the seek bar.',
          options: [
            for (final s in PlaybackPrefs.skipChoices)
              (
                '$s s',
                prefs.skipSeconds == s,
                () => edit((p) => p.copyWith(skipSeconds: s)),
              ),
          ],
        ),
        const SizedBox(height: 18),
        _LanguageRow(
          title: 'Preferred audio language',
          subtitle: 'Used when a file has more than one audio track. '
              "Otherwise the file's own default plays.",
          value: prefs.audioLanguage,
          noneLabel: "File's default",
          onChanged: (lang) => edit((p) => p.copyWith(audioLanguage: () => lang)),
        ),
      ],
    );
  }
}

/// Settings → Subtitles (§12.1).
class SubtitlesPane extends ConsumerWidget {
  const SubtitlesPane({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(playbackPrefsProvider);
    final edit = ref.read(playbackPrefsProvider.notifier).edit;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CheckRow(
          title: 'Show subtitles',
          subtitle: 'Turn them on when a file has them. You can always switch '
              'in the player.',
          value: prefs.subtitlesOn,
          onChanged: (v) => edit((p) => p.copyWith(subtitlesOn: v)),
        ),
        const SizedBox(height: 18),
        _LanguageRow(
          title: 'Preferred subtitle language',
          subtitle: 'If a file has no subtitles in this language, none are '
              'shown.',
          value: prefs.subtitleLanguage,
          noneLabel: 'Any',
          onChanged: (lang) =>
              edit((p) => p.copyWith(subtitleLanguage: () => lang)),
        ),
        const SizedBox(height: 18),
        _ChoiceRow(
          title: 'Size',
          subtitle: 'For text subtitles, such as SRT and ASS.',
          options: [
            for (final size in SubtitleSize.values)
              (
                size.label,
                prefs.subtitleSize == size,
                () => edit((p) => p.copyWith(subtitleSize: size)),
              ),
          ],
        ),
      ],
    );
  }
}

class _Label extends StatelessWidget {
  const _Label({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);
    final f = RelayLayout.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: t.ink,
            fontSize: RelayLayout.bodySize(f),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            color: t.inkDim,
            fontSize: RelayLayout.bodySize(f) - 2,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

/// A row of mutually exclusive choices, each its own focus stop.
class _ChoiceRow extends StatelessWidget {
  const _ChoiceRow({
    required this.title,
    required this.subtitle,
    required this.options,
  });

  final String title;
  final String subtitle;
  final List<(String, bool, VoidCallback)> options;

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);
    final f = RelayLayout.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label(title: title, subtitle: subtitle),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (label, selected, onTap) in options)
              RelayTappable(
                borderRadius: 18,
                onTap: onTap,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? t.accent : t.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: selected ? t.accent : t.line),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: selected ? t.accentInk : t.ink,
                      fontSize: RelayLayout.bodySize(f) - 1,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// On/off as a whole focusable row. Not a Material Switch: its focus state has
/// never been checked with a remote, and the row is the control anyway.
class _CheckRow extends StatelessWidget {
  const _CheckRow({
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
    return RelayTappable(
      borderRadius: 10,
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _Label(title: title, subtitle: subtitle)),
            const SizedBox(width: 14),
            Icon(
              value ? Icons.check_box : Icons.check_box_outline_blank,
              color: value ? t.accent : t.inkDim,
            ),
          ],
        ),
      ),
    );
  }
}

/// Shows the chosen language and opens the list to change it.
class _LanguageRow extends StatelessWidget {
  const _LanguageRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.noneLabel,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final String? value;

  /// What "no preference" is called in this row.
  final String noneLabel;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);
    final f = RelayLayout.of(context);
    final current =
        value == null ? noneLabel : (playbackLanguages[value] ?? value!);
    return RelayTappable(
      borderRadius: 10,
      onTap: () async {
        final picked = await showModalBottomSheet<(String?,)>(
          context: context,
          backgroundColor: t.surface,
          isScrollControlled: true,
          builder: (context) => _LanguageSheet(
            title: title,
            value: value,
            noneLabel: noneLabel,
          ),
        );
        // A record, so "picked no preference" (null inside) is told apart
        // from "dismissed the sheet" (no record at all).
        if (picked != null) onChanged(picked.$1);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _Label(title: title, subtitle: subtitle)),
            const SizedBox(width: 14),
            Text(
              current,
              style: TextStyle(
                color: t.accent,
                fontSize: RelayLayout.bodySize(f) - 1,
                fontWeight: FontWeight.w600,
              ),
            ),
            Icon(Icons.chevron_right, color: t.inkDim),
          ],
        ),
      ),
    );
  }
}

class _LanguageSheet extends StatelessWidget {
  const _LanguageSheet({
    required this.title,
    required this.value,
    required this.noneLabel,
  });

  final String title;
  final String? value;
  final String noneLabel;

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);
    final f = RelayLayout.of(context);
    final entries = <(String?, String)>[
      (null, noneLabel),
      for (final e in playbackLanguages.entries) (e.key, e.value),
    ];
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.8,
        ),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(12),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
              child: Text(
                title,
                style: TextStyle(
                  color: t.inkDim,
                  fontSize: RelayLayout.bodySize(f),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            for (final (code, label) in entries)
              RelayTappable(
                borderRadius: 10,
                autofocus: code == value,
                onTap: () => Navigator.of(context).pop((code,)),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          label,
                          style: TextStyle(
                            color: t.ink,
                            fontSize: RelayLayout.bodySize(f) + 1,
                          ),
                        ),
                      ),
                      if (code == value) Icon(Icons.check, color: t.accent),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
