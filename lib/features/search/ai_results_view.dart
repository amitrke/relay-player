import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/relay_theme.dart';
import '../../core/theme/relay_widgets.dart';
import '../ai/ai_controller.dart';
import '../library/poster_grid.dart';
import '../../i18n/strings.g.dart';

/// "3194" as "3,194".
String _count(int n) => n.toString().replaceAllMapped(
  RegExp(r'(\d)(?=(\d{3})+$)'),
  (m) => '${m[1]},',
);

/// What a model picked from the library for [query], as it is found.
///
/// Says plainly that it is the model's pick, and which provider's: these are
/// suggestions from a service the user chose, not search hits, and the two
/// should not look the same.
///
/// A large library is searched in parts (see [aiSearchProvider]), so this fills
/// in over several seconds. It says how far the search has got while it does,
/// and when it has finished, how much of the library it covered: "nothing found"
/// means something different after searching all of it than after searching
/// part of it.
class AiResultsView extends ConsumerWidget {
  const AiResultsView({super.key, required this.query});

  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = RelayTheme.of(context);
    final f = RelayLayout.of(context);
    final provider =
        ref.watch(aiSetupProvider).value?.config.displayName ??
        tr.ai.picks.yourProvider;
    final search = ref.watch(aiSearchProvider(query));

    Widget searching(String label) => Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: t.accent),
          const SizedBox(height: 16),
          Text(label, style: TextStyle(color: t.inkDim)),
        ],
      ),
    );

    return search.when(
      loading: () => searching(tr.ai.search.asking(provider: provider)),
      error: (e, _) => LibraryEmptyState(
        icon: Icons.cloud_off_outlined,
        message: '$e',
        onRetry: () => ref.invalidate(aiSearchProvider(query)),
      ),
      data: (p) {
        if (p.items.isEmpty && !p.done) {
          return searching(
            p.covered == 0
                ? tr.ai.search.asking(provider: provider)
                : tr.ai.search.searching(
                    searched: _count(p.searched),
                    covered: _count(p.covered),
                  ),
          );
        }
        if (p.items.isEmpty) {
          return LibraryEmptyState(
            icon: Icons.auto_awesome,
            message: p.total == 0
                ? tr.ai.search.emptyLibrary
                : [
                    p.truncated
                        ? tr.ai.search.notFoundFirst(
                            covered: _count(p.covered),
                            total: _count(p.total),
                          )
                        : tr.ai.search.notFound(total: _count(p.total)),
                    if (p.partsFailed > 0) _failedNote(p),
                  ].join('\n\n'),
            onRetry: p.partsFailed > 0
                ? () => ref.invalidate(aiSearchProvider(query))
                : null,
          );
        }

        final notes = [
          if (!p.done)
            tr.ai.search.stillSearching(
              searched: _count(p.searched),
              covered: _count(p.covered),
            ),
          if (p.done && p.truncated)
            tr.ai.search.searchedFirst(
              covered: _count(p.covered),
              total: _count(p.total),
            ),
          if (p.partsFailed > 0) _failedNote(p),
        ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: RelayLayout.pagePadding(f).copyWith(top: 4, bottom: 0),
              child: Text(
                tr.ai.search.pickedFor(provider: provider, query: query),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: t.inkDim, fontSize: 13),
              ),
            ),
            if (notes.isNotEmpty)
              Padding(
                padding: RelayLayout.pagePadding(f).copyWith(top: 2, bottom: 0),
                child: Row(
                  children: [
                    if (!p.done) ...[
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: t.accent,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(
                        notes.join(' · '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: t.inkDim, fontSize: 12),
                      ),
                    ),
                    // The parts that failed were not searched, so what is shown
                    // may be missing titles. Asking again is the person's call:
                    // it sends the whole search again.
                    if (p.done && p.partsFailed > 0)
                      RelayTextButton(
                        label: tr.ai.search.searchAgain,
                        onPressed: () =>
                            ref.invalidate(aiSearchProvider(query)),
                      ),
                  ],
                ),
              ),
            Expanded(child: PosterGrid(items: p.items, showKind: true)),
          ],
        );
      },
    );
  }

  /// Said when some parts of a search could not be asked, so a short list is
  /// not mistaken for a full answer.
  static String _failedNote(AiSearchProgress p) =>
      tr.ai.search.partsFailed(failed: p.partsFailed, parts: p.parts);
}
