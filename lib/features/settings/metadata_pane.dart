import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/relay_theme.dart';
import '../../core/theme/relay_widgets.dart';
import '../../data/tmdb/tmdb_client.dart';
import '../metadata/release_dates.dart';
import '../metadata/tmdb_controller.dart';

/// What the person is agreeing to when they switch on the background lookup, in
/// the same words as the dialog, so a test can pin that it says what it sends.
const releaseDatesConsentText =
    'This looks up the release date of every film and series in your library on '
    'TMDB, in the background, a few at a time. To do that it sends the title '
    '(and the year, when there is one) of each of them from this device to '
    'TMDB, and to no one else, not only the ones you search for. It also fills '
    'in genre and rating for the filters. Results are kept on this device for '
    '90 days, and titles already looked up are not asked again.\n\n'
    'You can switch it off at any time. Removing your TMDB key switches it off '
    'too.';

Future<bool> confirmReleaseDates(BuildContext context) async {
  final t = RelayTheme.of(context);
  final agreed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: t.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: Text(
        'Send your library titles to TMDB?',
        style: TextStyle(
          color: t.ink,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: Text(
        releaseDatesConsentText,
        style: TextStyle(color: t.inkDim, fontSize: 14, height: 1.55),
      ),
      actions: [
        TextButton(
          // The safe answer, focused first so a stray press on a remote declines.
          autofocus: true,
          onPressed: () => Navigator.pop(context, false),
          style: TextButton.styleFrom(foregroundColor: t.inkDim),
          child: const Text('Not now'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(
            backgroundColor: t.accent,
            foregroundColor: t.accentInk,
          ),
          child: const Text('Look them up'),
        ),
      ],
    ),
  );
  return agreed == true;
}

/// The switch for the background release-date lookup, and how it is going.
class _ReleaseDatesControl extends ConsumerWidget {
  const _ReleaseDatesControl();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = RelayTheme.of(context);
    final enabled = ref.watch(releaseDatesEnabledProvider);
    final state = ref.watch(releaseDatesProvider);

    final status = !enabled
        ? null
        : state.total == 0
        ? 'Waiting for your library to load.'
        : state.stoppedEarly
        ? 'Paused: TMDB stopped answering. It carries on the next time the app '
              'opens, and what it found is kept.'
        : state.running
        ? 'Looked up ${state.settled} of ${state.total} titles.'
        : state.settled < state.total
        ? 'Looked up ${state.settled} of ${state.total} titles. The rest '
              'carry on the next time the app opens.'
        : 'Done: ${state.dates.length} release dates found for '
              '${state.total} titles.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Release dates for your library',
                    style: TextStyle(
                      color: t.ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Adds exact release dates in the background, so Sort by '
                    'Release date can order your library properly, including '
                    'titles with no year. Sends every title in your library '
                    'to TMDB.',
                    style: TextStyle(
                      color: t.inkDim,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Switch(
              value: enabled,
              onChanged: (on) async {
                if (!on) {
                  await ref
                      .read(releaseDatesEnabledProvider.notifier)
                      .disable();
                  return;
                }
                final agreed = await confirmReleaseDates(context);
                if (agreed) {
                  await ref.read(releaseDatesEnabledProvider.notifier).enable();
                }
              },
              activeThumbColor: t.accentInk,
              activeTrackColor: t.accent,
              inactiveTrackColor: t.line,
              inactiveThumbColor: t.inkDim,
            ),
          ],
        ),
        if (status != null) ...[
          const SizedBox(height: 8),
          Text(
            status,
            style: TextStyle(color: t.inkDim, fontSize: 12.5, height: 1.5),
          ),
        ],
      ],
    );
  }
}

/// Settings → Metadata: the user's own TMDB key.
///
/// Optional, and absent from the rest of the app until a key is saved. What it
/// adds, and what it costs, is said here rather than left to a privacy page,
/// because the cost is that the titles being looked up leave the device.
class MetadataPane extends ConsumerStatefulWidget {
  const MetadataPane({super.key});

  @override
  ConsumerState<MetadataPane> createState() => _MetadataPaneState();
}

class _MetadataPaneState extends ConsumerState<MetadataPane> {
  final _controller = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_controller.text.trim().isEmpty || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(tmdbKeyProvider.notifier).save(_controller.text);
      if (!mounted) return;
      _controller.clear();
      setState(() => _busy = false);
    } on TmdbException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);
    final saved = ref.watch(tmdbKeyProvider).value != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Connect your own TMDB key to add genre, rating and original '
          'language to search results, and suggestions based on what you have '
          'watched. It is optional, and nothing changes until you add one.',
          style: TextStyle(color: t.inkDim, fontSize: 13.5, height: 1.6),
        ),
        const SizedBox(height: 10),
        Text(
          'The titles being looked up are sent from this device to TMDB, and '
          'to no one else. Create a free key in your TMDB account under '
          'Settings, API. Either the short key or the long Read Access Token '
          'works. On a TV it is easier to paste or type this on a phone or '
          'computer first.',
          style: TextStyle(color: t.inkDim, fontSize: 13.5, height: 1.6),
        ),
        const SizedBox(height: 18),
        if (saved) ...[
          Row(
            children: [
              Icon(Icons.check_circle, color: t.accent, size: 20),
              const SizedBox(width: 8),
              Text(
                'TMDB key saved',
                style: TextStyle(
                  color: t.ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const _ReleaseDatesControl(),
          const SizedBox(height: 18),
          Align(
            alignment: Alignment.centerLeft,
            child: RelayButton(
              label: 'Remove key',
              onPressed: () => ref.read(tmdbKeyProvider.notifier).remove(),
            ),
          ),
        ] else ...[
          RelayFieldTraversal(
            child: TextField(
              controller: _controller,
              autocorrect: false,
              enableSuggestions: false,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _save(),
              style: TextStyle(color: t.ink),
              decoration: InputDecoration(
                labelText: 'TMDB API key',
                labelStyle: TextStyle(color: t.inkDim),
                errorText: _error,
                filled: true,
                fillColor: t.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: t.line),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: t.line),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: t.accent),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: RelayButton(
              label: _busy ? 'Checking...' : 'Verify and save',
              onPressed: _busy ? null : _save,
            ),
          ),
        ],
        const SizedBox(height: 22),
        // TMDB's terms require this wording wherever its data is used.
        Text(
          'This product uses the TMDB API but is not endorsed or certified by '
          'TMDB.',
          style: TextStyle(color: t.inkDim, fontSize: 12, height: 1.5),
        ),
      ],
    );
  }
}
