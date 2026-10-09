import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/relay_theme.dart';
import '../ai/ai_controller.dart';
import '../library/poster_grid.dart';

/// What a model picked from the library for [query].
///
/// Says plainly that it is the model's pick, and which provider's: these are
/// suggestions from a service the user chose, not search hits, and the two
/// should not look the same.
class AiResultsView extends ConsumerWidget {
  const AiResultsView({super.key, required this.query});

  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = RelayTheme.of(context);
    final f = RelayLayout.of(context);
    final provider =
        ref.watch(aiSetupProvider).value?.config.displayName ?? 'your provider';
    final picks = ref.watch(aiSearchProvider(query));

    return picks.when(
      loading: () => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: t.accent),
            const SizedBox(height: 16),
            Text('Asking $provider...', style: TextStyle(color: t.inkDim)),
          ],
        ),
      ),
      error: (e, _) => LibraryEmptyState(
        icon: Icons.cloud_off_outlined,
        message: '$e',
        onRetry: () => ref.invalidate(aiSearchProvider(query)),
      ),
      data: (items) => items.isEmpty
          ? const LibraryEmptyState(
              icon: Icons.auto_awesome,
              message:
                  'The model did not pick anything from your library for '
                  'that. Try describing it differently.',
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: RelayLayout.pagePadding(f)
                      .copyWith(top: 4, bottom: 0),
                  child: Text(
                    'Picked by $provider for "$query"',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: t.inkDim, fontSize: 13),
                  ),
                ),
                Expanded(child: PosterGrid(items: items, showKind: true)),
              ],
            ),
    );
  }
}
