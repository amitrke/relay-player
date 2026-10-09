import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/relay_theme.dart';
import '../../core/theme/relay_widgets.dart';
import '../../data/tmdb/tmdb_client.dart';
import '../metadata/tmdb_controller.dart';

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
          const SizedBox(height: 14),
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
