import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/ai/ai_provider.dart';
import '../../data/ai/ai_recommendations.dart';
import '../../data/ai/natural_search.dart';
import '../../data/ai/text_client.dart';
import '../../domain/models/catalog_item.dart';
import '../favorites_history/history_controller.dart';
import '../library/library_screen.dart' show libraryItemsProvider;
import '../library/library_tab.dart';
import '../search/watch_signals.dart';
import '../settings/settings_controller.dart';
import 'ai_controller.dart';

/// Where the last picks are kept. Cleared with the provider.
const aiRecommendationsCacheKey = 'ai.recs';

class AiRecsState {
  const AiRecsState({
    this.enabled = false,
    this.items = const [],
    this.refreshing = false,
    this.error,
  });

  /// False until the user has allowed recommendations for this provider.
  /// Nothing is prepared, and nothing is sent, before that.
  final bool enabled;

  /// The picks to show: the cached ones at once, replaced when new ones land.
  final List<CatalogItem> items;

  /// A request to the provider is in flight.
  final bool refreshing;

  /// Why the last attempt gave nothing, in words fit to show.
  final String? error;

  AiRecsState copyWith({
    List<CatalogItem>? items,
    bool? refreshing,
    String? error,
    bool clearError = false,
  }) => AiRecsState(
    enabled: enabled,
    items: items ?? this.items,
    refreshing: refreshing ?? this.refreshing,
    error: clearError ? null : (error ?? this.error),
  );
}

/// AI recommendations, kept ready.
///
/// Picks used to be made when the user pressed a button and took however long
/// the model took. Once they have allowed the feature they are now prepared in
/// advance and kept: the last picks are stored and shown the moment Search
/// opens, and refreshed in the background when something that matters changed.
///
/// What keeps that from becoming a quiet drain on the user's quota and privacy:
/// - Nothing happens until recommendations are allowed for this provider.
/// - A refresh happens only when the recent films or the model changed, or the
///   picks are over a day old ([recommendationsStale]). Relaunching or opening
///   Search with nothing new sends nothing.
/// - A failed attempt is not retried until the next launch, so a rejected key
///   or a rate limit cannot turn into a loop.
/// - The consent dialog says this happens, and revoking it stops it.
final aiRecommendationsProvider =
    AsyncNotifierProvider<AiRecommendationsController, AiRecsState>(
      AiRecommendationsController.new,
    );

class AiRecommendationsController extends AsyncNotifier<AiRecsState> {
  bool _failedThisSession = false;

  @override
  Future<AiRecsState> build() async {
    final setup = await ref.watch(aiSetupProvider.future);
    if (setup == null) return const AiRecsState();
    // Watched so that allowing the feature, or switching it off, takes effect
    // at once.
    ref.watch(aiConsentProvider);
    if (!ref
        .read(aiConsentProvider.notifier)
        .allows(AiFeature.recommendations, setup.config)) {
      return const AiRecsState();
    }

    final library = await _library();
    final cache = _readCache();
    final items = _resolve(cache?.keys ?? const [], library);

    final plan = _plan(setup, library, const {});
    final stale =
        plan.input.hasSignal &&
        !_failedThisSession &&
        recommendationsStale(cache, plan.signature, DateTime.now());
    // After build returns, so the cached picks show first.
    if (stale) Future.microtask(() => _generate(setup, exclude: const {}));
    return AiRecsState(enabled: true, items: items, refreshing: stale);
  }

  /// Called when Search opens: refresh if what the picks were made from has
  /// changed since, and otherwise do nothing.
  Future<void> refreshIfStale() async {
    final current = state.value;
    final setup = ref.read(aiSetupProvider).value;
    if (current == null || !current.enabled || current.refreshing) return;
    if (setup == null || _failedThisSession) return;

    final library = await _library();
    final plan = _plan(setup, library, const {});
    if (plan.input.hasSignal &&
        recommendationsStale(_readCache(), plan.signature, DateTime.now())) {
      await _generate(setup, exclude: const {});
    }
  }

  /// The user asked for a different set. Leaves the current picks out of the
  /// list so the model cannot just say the same thing again.
  Future<void> refresh() async {
    final current = state.value;
    final setup = ref.read(aiSetupProvider).value;
    if (current == null || !current.enabled || current.refreshing) return;
    if (setup == null) return;
    _failedThisSession = false;
    await _generate(setup, exclude: {for (final i in current.items) i.key});
  }

  Future<void> _generate(AiSetup setup, {required Set<String> exclude}) async {
    final client = ref.read(aiClientProvider);
    final before = state.value ?? const AiRecsState(enabled: true);
    if (client == null) return;
    state = AsyncData(before.copyWith(refreshing: true, clearError: true));

    try {
      final library = await _library();
      final plan = _plan(setup, library, exclude);
      if (!plan.input.hasSignal) {
        throw const AiException(
          'Watch a film first, so there is something to base picks on.',
        );
      }

      final answer = await client.complete(
        system: recommendationSystemPrompt,
        user: recommendationUserMessage(plan.input),
        maxTokens: aiPickMaxTokens,
      );
      final picks = resolvePicks(answer, plan.input.index);
      if (picks.isEmpty) {
        throw const AiException('The model did not pick anything this time.');
      }

      await ref
          .read(appSettingsStoreProvider)
          .setString(
            aiRecommendationsCacheKey,
            RecommendationCache(
              at: DateTime.now(),
              signature: plan.signature,
              keys: [for (final p in picks) p.key],
            ).toJson(),
          );
      state = AsyncData(AiRecsState(enabled: true, items: picks));
    } on AiException catch (e) {
      _failedThisSession = true;
      state = AsyncData(before.copyWith(refreshing: false, error: e.message));
    }
  }

  ({RecommendationInput input, String signature}) _plan(
    AiSetup setup,
    List<CatalogItem> library,
    Set<String> exclude,
  ) {
    final history = ref.read(historyProvider);
    final watched = watchedTitles(library, history);
    final input = buildRecommendationInput(
      recentlyWatched: recentlyWatchedFilms(library, history),
      library: library,
      isWatched: (i) => watched.contains(i.title.toLowerCase()),
      exclude: exclude,
    );
    return (
      input: input,
      signature: recommendationSignature(input, setup.config.model),
    );
  }

  RecommendationCache? _readCache() => RecommendationCache.fromJson(
    ref.read(appSettingsStoreProvider).getString(aiRecommendationsCacheKey),
  );

  /// Cached keys back to live library items, in the order they were picked. A
  /// title that has since left a source is dropped.
  List<CatalogItem> _resolve(List<String> keys, List<CatalogItem> library) {
    final byKey = {for (final i in library) i.key: i};
    return [
      for (final k in keys)
        if (byKey[k] != null) byKey[k]!,
    ];
  }

  Future<List<CatalogItem>> _library() async {
    final library = <CatalogItem>[];
    for (final tab in [LibraryTab.movies, LibraryTab.series]) {
      try {
        library.addAll(await ref.read(libraryItemsProvider(tab).future));
      } catch (_) {}
    }
    return library;
  }
}

/// Starts [aiRecommendationsProvider] shortly after launch, so the picks are
/// ready before anyone opens Search. Watched from the app root.
///
/// Delayed so it does not compete with the first screen and the library for the
/// network on a slow box, and it does nothing at all unless a provider is set up
/// and recommendations are allowed.
final aiRecommendationsPrefetchProvider = FutureProvider<void>((ref) async {
  await Future<void>.delayed(const Duration(seconds: 8));
  await ref.read(aiRecommendationsProvider.future);
});
