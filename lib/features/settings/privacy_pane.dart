import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/relay_theme.dart';
import '../../core/theme/relay_widgets.dart';
import '../ai/ai_recommendations_controller.dart';
import '../library/library_cache_provider.dart';
import '../library/library_screen.dart' show libraryItemsProvider;
import '../metadata/tmdb_controller.dart';
import '../search/suggestions_provider.dart';
import 'settings_controller.dart';

/// Empties everything the app keeps only to be faster: the library lists, the
/// TMDB lookups and the AI picks. Your sources, keys, settings and watch history
/// are untouched, and everything cleared is fetched again on demand.
///
/// The library reloads straight away, and the AI picks are asked for again if
/// that is allowed, because both are what the screens show.
Future<void> clearCachedData(WidgetRef ref) async {
  try {
    await (await ref.read(libraryCacheProvider.future)).clear();
  } catch (_) {}
  try {
    await (await ref.read(tmdbCacheProvider.future)).clear();
  } catch (_) {}
  try {
    await ref
        .read(appSettingsStoreProvider)
        .setString(aiRecommendationsCacheKey, '');
  } catch (_) {}

  ref.invalidate(libraryItemsProvider);
  ref.invalidate(suggestionsProvider);
  ref.invalidate(aiRecommendationsProvider);
}

/// Settings -> Privacy and data (section 12.1).
///
/// Built 2026-10-09 around the one control that does something: clearing cached
/// data. Its old "Send crash reports" switch stored a preference nothing read
/// while the privacy policy says no crash reports are sent, and a switch for a
/// data flow that does not exist is the same fault as the AI pane's demo data,
/// so it stays out until crash reporting is real (#6).
class PrivacyPane extends ConsumerStatefulWidget {
  const PrivacyPane({super.key});

  @override
  ConsumerState<PrivacyPane> createState() => _PrivacyPaneState();
}

class _PrivacyPaneState extends ConsumerState<PrivacyPane> {
  bool _busy = false;
  bool _cleared = false;

  Future<void> _clear() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _cleared = false;
    });
    await clearCachedData(ref);
    if (mounted) {
      setState(() {
        _busy = false;
        _cleared = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);
    final style = TextStyle(color: t.inkDim, fontSize: 13.5, height: 1.6);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Subnext Player has no backend and no analytics. What it keeps lives '
          'on this device, and the only places data is sent are the sources, '
          'TMDB and AI provider you connect yourself.',
          style: style,
        ),
        const SizedBox(height: 22),
        Text(
          'Cached data',
          style: TextStyle(
            color: t.ink,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Your library lists, TMDB lookups and AI picks are kept so the app '
          'opens quickly. Old ones clear themselves, after 30 days for a '
          'library and 90 for a lookup, and a source\'s entry goes when you '
          'remove the source. Clearing now leaves your sources, keys, settings '
          'and watch history alone, and everything is fetched again when '
          'needed.',
          style: style,
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerLeft,
          child: RelayButton(
            label: _busy ? 'Clearing...' : 'Clear cached data',
            onPressed: _busy ? null : _clear,
          ),
        ),
        if (_cleared) ...[
          const SizedBox(height: 10),
          Text(
            'Cleared. Your library is loading again.',
            style: TextStyle(color: t.accent, fontSize: 13),
          ),
        ],
      ],
    );
  }
}
