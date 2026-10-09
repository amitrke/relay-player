import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/relay_theme.dart';
import '../../core/theme/relay_widgets.dart';
import '../../domain/models/catalog_item.dart';
import '../../data/ai/ai_provider.dart';
import '../../data/xtream/xtream_account_store.dart';
import '../accounts/plex_session.dart';
import '../advanced_sources/xtream_controller.dart';
import '../ai/ai_controller.dart';
import '../metadata/tmdb_controller.dart';
import '../library/library_screen.dart' show plexSectionsProvider;
import '../library/poster_grid.dart';
import '../settings/settings_controller.dart';
import 'search_filters.dart';
import 'search_results_view.dart';
import 'ai_recommendations_view.dart';
import 'ai_results_view.dart';
import 'suggestions_provider.dart';
import 'suggestions_view.dart';

final _queryProvider = NotifierProvider<_QueryController, String>(
  _QueryController.new,
);

class _QueryController extends Notifier<String> {
  @override
  String build() => '';

  void update(String value) => state = value;
}

/// The query the user has handed to the AI provider, or null for ordinary
/// search. It only applies while the box still holds that exact text, so
/// editing the query drops back to ordinary results with nothing to reset.
final _askAiProvider = NotifierProvider<_AskAiController, String?>(
  _AskAiController.new,
);

class _AskAiController extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? query) => state = query;
}

final _filtersProvider = NotifierProvider<_FiltersController, SearchFilters>(
  _FiltersController.new,
);

class _FiltersController extends Notifier<SearchFilters> {
  @override
  SearchFilters build() => const SearchFilters();

  void set(SearchFilters value) => state = value;
}

/// Search every connected server and every panel catalogue, and merge.
///
/// One unreachable source must not blank the results — it should cost you its
/// own matches, not everyone else's.
///
/// Panels are matched locally on title, against the categories the user chose
/// for the library tabs. There is no panel-side search call to lean on, and
/// fetching a whole panel to look through it is exactly what §4.1 forbids, so
/// "searchable" and "chosen in Settings" are the same set.
final _resultsProvider = FutureProvider<List<CatalogItem>>((ref) async {
  final query = ref.watch(_queryProvider);
  if (query.trim().length < 2) return const [];

  final needle = query.trim().toLowerCase();
  final panels = Future.wait([
    for (final account in ref.watch(xtreamAccountsProvider))
      for (final catalogue in const [
        XtreamCatalogue.vod,
        XtreamCatalogue.series,
      ])
        () async {
          try {
            final all = await ref.watch(
              xtreamCatalogProvider((account, catalogue)).future,
            );
            return [
              for (final i in all)
                if (i.title.toLowerCase().contains(needle)) i,
            ];
          } catch (_) {
            return const <CatalogItem>[];
          }
        }().timeout(
          const Duration(seconds: 10),
          onTimeout: () => const <CatalogItem>[],
        ),
  ]);

  final servers = ref.watch(connectedServersProvider);
  final mapping = ref.watch(libraryMappingProvider);
  final perServer = await Future.wait(
    servers
        .map((server) async {
          try {
            // Only libraries not hidden in Settings → Sources; see
            // PlexService.searchIn for why this cannot be filtered afterwards.
            final sections = await ref.watch(
              plexSectionsProvider(server.id).future,
            );
            final found = await server.service.searchIn(
              mapping.visibleSections(server.id, sections),
              query,
            );
            return [
              for (final i in found) server.service.toCatalogItem(i.metadata),
            ];
          } catch (_) {
            return const <CatalogItem>[];
          }
        })
        .map(
          (f) => f.timeout(
            const Duration(seconds: 10),
            onTimeout: () => const <CatalogItem>[],
          ),
        ),
  );
  return rankByTitleMatch([
    ...perServer.expand((items) => items),
    ...(await panels).expand((items) => items),
  ], query);
});

/// The results with TMDB metadata folded in, when there is a key.
///
/// Separate from [_resultsProvider] on purpose: the grid shows the moment the
/// sources answer, and this lands a few seconds later and only adds chips. A
/// lookup that fails or finds nothing leaves its items as they were.
final _enrichedProvider = FutureProvider<List<CatalogItem>>((ref) async {
  final results = await ref.watch(_resultsProvider.future);
  final enricher = await ref.watch(tmdbEnricherProvider.future);
  if (enricher == null || results.isEmpty) return results;
  return enricher.enrich(results);
});

/// Search across the connected sources (§12 screen 8).
///
/// The "Ask" affordance from the Home artboard is deliberately absent: §9.2
/// only shows it once an AI text-generation provider is configured, and none
/// can be yet.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  /// Each keystroke is a round trip to the server, so wait for a pause. Without
  /// this, typing "godfather" fires ten searches and the answers can land out
  /// of order.
  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      ref.read(_queryProvider.notifier).update(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);
    final f = RelayLayout.of(context);
    final query = ref.watch(_queryProvider);
    // AI is offered only once a provider is set up (section 9.1), and only on
    // text long enough to be a request.
    final hasAi = ref.watch(aiSetupProvider).value != null;
    final askedAi = ref.watch(_askAiProvider);
    final aiOn = hasAi && query.trim().isNotEmpty && askedAi == query.trim();
    final results = ref.watch(_resultsProvider);
    final filters = ref.watch(_filtersProvider);
    // The plain results until the enriched ones arrive, so a slow or failing
    // TMDB never holds the grid back.
    final enriched = ref.watch(_enrichedProvider).value;
    final sourceNames = <String, String>{
      for (final s in ref.watch(connectedServersProvider)) s.id: s.name,
      for (final a in ref.watch(xtreamAccountsProvider)) a.id: a.name,
    };

    return Scaffold(
      backgroundColor: t.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: RelayLayout.pagePadding(f).copyWith(top: 16, bottom: 8),
              child: RelayFieldTraversal(
                child: TextField(
                  controller: _controller,
                  onChanged: _onChanged,
                  autocorrect: false,
                  textInputAction: TextInputAction.search,
                  // A touch anywhere else puts the keyboard away. Android has
                  // Back for this, iOS has nothing, so without it the keyboard
                  // stayed over the results after typing a query and tapping
                  // Ask AI or scrolling. Only a pointer triggers this, so a
                  // remote's focus (section 11) is left where it is.
                  onTapOutside: (_) =>
                      FocusManager.instance.primaryFocus?.unfocus(),
                  style: TextStyle(color: t.ink),
                  decoration: InputDecoration(
                    hintText: 'Search your sources',
                    hintStyle: TextStyle(color: t.inkDim),
                    prefixIcon: Icon(Icons.search, color: t.inkDim, size: 20),
                    suffixIcon: query.isEmpty
                        ? null
                        : IconButton(
                            icon: Icon(Icons.close, color: t.inkDim, size: 18),
                            onPressed: () {
                              _controller.clear();
                              _debounce?.cancel();
                              ref.read(_queryProvider.notifier).update('');
                            },
                          ),
                    filled: true,
                    fillColor: t.surface,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
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
            ),
            if (hasAi && query.trim().length >= 3)
              Padding(
                padding: RelayLayout.pagePadding(f).copyWith(top: 0, bottom: 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _AskAiChip(
                    active: aiOn,
                    onTap: () async {
                      if (aiOn) {
                        ref.read(_askAiProvider.notifier).set(null);
                        return;
                      }
                      final go = await ensureAiConsent(
                        context,
                        ref,
                        AiFeature.naturalSearch,
                      );
                      if (go && mounted) {
                        ref.read(_askAiProvider.notifier).set(query.trim());
                      }
                    },
                  ),
                ),
              ),
            Expanded(
              child: aiOn
                  ? AiResultsView(query: query.trim())
                  : switch (query.trim().length) {
                      // Suggestions when there are honest ones, else the plain prompt.
                      // While they load, or if they fail, the prompt shows: nothing
                      // here is worth a spinner or an error.
                      // With an AI provider the AI section leads, even when there
                      // are no TMDB rows: it is the one thing here that can run
                      // with no TMDB key and no history of its own.
                      0 => switch (ref.watch(suggestionsProvider).value) {
                        final rows? when rows.isNotEmpty || hasAi =>
                          SuggestionsView(
                            rows: rows,
                            leading: hasAi
                                ? const AiRecommendationsSection()
                                : null,
                          ),
                        null when hasAi => const SuggestionsView(
                          rows: [],
                          leading: AiRecommendationsSection(),
                        ),
                        _ => const LibraryEmptyState(
                          icon: Icons.search,
                          message:
                              'Search movies and series across your server.',
                        ),
                      },
                      1 => const LibraryEmptyState(
                        icon: Icons.search,
                        message: 'Keep typing…',
                      ),
                      _ => results.when(
                        loading: () => Center(
                          child: CircularProgressIndicator(color: t.accent),
                        ),
                        error: (e, _) => LibraryEmptyState(
                          icon: Icons.cloud_off_outlined,
                          message: '$e',
                          onRetry: () => ref.invalidate(_resultsProvider),
                        ),
                        data: (list) => list.isEmpty
                            ? LibraryEmptyState(
                                icon: Icons.search_off,
                                message: 'Nothing matching "$query".',
                              )
                            : SearchResultsView(
                                all: enriched ?? list,
                                filters: filters,
                                sourceNames: sourceNames,
                                onFilters: (v) =>
                                    ref.read(_filtersProvider.notifier).set(v),
                              ),
                      ),
                    },
            ),
          ],
        ),
      ),
    );
  }
}

/// "Ask AI" beside the results, and "Back to results" while its picks show.
class _AskAiChip extends StatelessWidget {
  const _AskAiChip({required this.active, required this.onTap});

  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);
    final f = RelayLayout.of(context);
    final size = f == RelayFormFactor.tv ? 15.0 : 13.0;
    return RelayTappable(
      borderRadius: 20,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? t.surface : t.accent.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? t.line : t.accent),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              active ? Icons.arrow_back : Icons.auto_awesome,
              size: size + 3,
              color: active ? t.inkDim : t.accent,
            ),
            const SizedBox(width: 6),
            Text(
              active ? 'Back to results' : 'Ask AI',
              style: TextStyle(
                color: active ? t.inkDim : t.ink,
                fontSize: size,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
