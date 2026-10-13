import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/xtream/category_language.dart';
import '../../data/xtream/hidden_words.dart';
import '../../data/xtream/xtream_account_store.dart';
import '../../data/xtream/xtream_client.dart';
import '../../domain/models/catalog_item.dart';
import '../library/library_cache_provider.dart';
import '../settings/settings_controller.dart';
import 'hidden_words_controller.dart';

final xtreamAccountStoreProvider = Provider<XtreamAccountStore>((ref) {
  return XtreamAccountStore(settings: ref.watch(appSettingsStoreProvider));
});

/// Configured Xtream lines.
///
/// Gated by §8.2: when Advanced Sources is off this reports nothing, so every
/// screen downstream renders as if no line were configured — without deleting
/// the accounts, which §12.1 requires to survive the toggle.
final xtreamAccountsProvider =
    NotifierProvider<XtreamAccountsController, List<XtreamAccount>>(
      XtreamAccountsController.new,
    );

class XtreamAccountsController extends Notifier<List<XtreamAccount>> {
  XtreamAccountStore get _store => ref.read(xtreamAccountStoreProvider);

  @override
  List<XtreamAccount> build() {
    if (!ref.watch(advancedSourcesEnabledProvider)) return const [];
    return _store.accounts();
  }

  Future<void> save(XtreamAccount account, {String? password}) async {
    await _store.save(account, password: password);
    state = _store.accounts();
  }

  Future<void> remove(String id) async {
    await _store.remove(id);
    // Its kept catalogue goes with it, not onto disk to wait for the age limit.
    await forgetSourceCache(ref, 'xtream|$id|');
    state = _store.accounts();
  }
}

/// A ready-to-use client for [account], with its password joined back in.
final xtreamClientProvider = FutureProvider.family<XtreamClient, XtreamAccount>(
  (ref, account) async {
    final password = await ref
        .watch(xtreamAccountStoreProvider)
        .password(account.id);
    if (password == null) {
      throw const XtreamException(
        'That line has no stored password. Remove it and add it again.',
      );
    }
    return XtreamClient(
      host: account.host,
      username: account.username,
      password: password,
    );
  },
);

/// (account, catalogue) — Riverpod families take one argument.
typedef XtreamScope = (XtreamAccount, XtreamCatalogue);

final xtreamCategoriesProvider =
    FutureProvider.family<List<XtreamCategory>, XtreamScope>((
      ref,
      scope,
    ) async {
      final (account, catalogue) = scope;
      final client = await ref.watch(xtreamClientProvider(account).future);
      return switch (catalogue) {
        XtreamCatalogue.live => client.liveCategories(),
        XtreamCatalogue.vod => client.vodCategories(),
        XtreamCatalogue.series => client.seriesCategories(),
      };
    });

/// [all] narrowed to the channels picked from a category, or all of them when
/// nothing was picked (the whole category is kept).
///
/// A picked channel the panel no longer lists simply drops out; the pick is not
/// an error. Order is the panel's, not the order of picking.
List<XtreamChannel> pickChannels(List<XtreamChannel> all, List<String>? picks) {
  if (picks == null || picks.isEmpty) return all;
  final wanted = picks.toSet();
  return [
    for (final c in all)
      if (wanted.contains(c.streamId)) c,
  ];
}

/// [channels] without those whose name has a hidden word in it. Applied to the
/// channels of the categories that were kept, after any picks, so a channel the
/// user hid is gone from Live TV whichever category it sits in.
List<XtreamChannel> withoutHidden(
  List<XtreamChannel> channels,
  HiddenWords hidden,
) =>
    hidden.isEmpty
        ? channels
        : [
            for (final c in channels)
              if (!hidden.matches(c.name)) c,
          ];

/// Every channel in one category, for the screen that picks among them. Not the
/// chosen categories: that is [xtreamChannelsProvider], which applies the picks.
final xtreamCategoryChannelsProvider =
    FutureProvider.family<List<XtreamChannel>, (XtreamAccount, String)>((
      ref,
      arg,
    ) async {
      final client = await ref.watch(xtreamClientProvider(arg.$1).future);
      return client.liveStreams(arg.$2);
    });

/// Channels for the categories the user actually chose (§4.1).
final xtreamChannelsProvider =
    FutureProvider.family<List<XtreamChannel>, XtreamAccount>((
      ref,
      account,
    ) async {
      if (account.liveCategoryIds.isEmpty) return const [];
      final client = await ref.watch(xtreamClientProvider(account).future);
      // Watched, so adding a word takes effect without a restart.
      final hidden = HiddenWords(ref.watch(hiddenWordsProvider));

      final pages = await Future.wait(
        account.liveCategoryIds.map((id) async {
          try {
            return pickChannels(
              await client.liveStreams(id),
              account.liveChannelPicks[id],
            );
          } catch (_) {
            // One bad category should cost its own channels, not the whole list.
            return const <XtreamChannel>[];
          }
        }),
      );
      return withoutHidden(pages.expand((page) => page).toList(), hidden);
    });

/// Panel movies and series, as catalogue items for the shared grid.
///
/// Never calls the unfiltered endpoints — Phase 0 measured those at 26.2 MB
/// across 69,397 items for VOD alone. Nothing selected means nothing fetched,
/// which is what opt-in is for.
final xtreamCatalogProvider =
    FutureProvider.family<List<CatalogItem>, XtreamScope>((ref, scope) async {
      final (account, catalogue) = scope;
      final ids = account.categoriesFor(catalogue);
      if (ids.isEmpty) return const [];

      final client = await ref.watch(xtreamClientProvider(account).future);

      // Category names, only to guess a language from. Best effort: a panel that
      // will not list them costs the language filter its guesses, not the catalogue
      // its titles.
      final names = <String, String>{};
      try {
        for (final c in await ref.watch(
          xtreamCategoriesProvider(scope).future,
        )) {
          names[c.id] = c.name;
        }
      } catch (_) {}

      final pages = await Future.wait(
        ids.map((id) async {
          final language = switch (names[id]) {
            final name? => languageOfCategory(name),
            null => null,
          };
          try {
            return switch (catalogue) {
              XtreamCatalogue.vod => [
                for (final v in await client.vodStreams(id))
                  CatalogItem(
                    source: CatalogSource.xtream,
                    sourceId: account.id,
                    kind: CatalogKind.movie,
                    // The container extension is part of the playback URL and is
                    // not recoverable later, so it rides along in the id.
                    id: '${v.streamId}.${v.containerExtension}',
                    title: v.name,
                    year: v.year,
                    posterUrl: v.posterUrl,
                    addedAt: v.addedAt,
                    language: language,
                    shelf: names[id],
                  ),
              ],
              XtreamCatalogue.series => [
                for (final s in await client.series(id))
                  CatalogItem(
                    source: CatalogSource.xtream,
                    sourceId: account.id,
                    kind: CatalogKind.show,
                    id: s.seriesId,
                    title: s.name,
                    year: s.year,
                    posterUrl: s.posterUrl,
                    addedAt: s.addedAt,
                    language: language,
                    shelf: names[id],
                  ),
              ],
              XtreamCatalogue.live => const <CatalogItem>[],
            };
          } catch (_) {
            return const <CatalogItem>[];
          }
        }),
      );
      return pages.expand((page) => page).toList();
    });

/// Seasons and episodes of one panel series.
final xtreamSeriesInfoProvider =
    FutureProvider.family<List<XtreamSeason>, (XtreamAccount, String)>((
      ref,
      arg,
    ) async {
      final client = await ref.watch(xtreamClientProvider(arg.$1).future);
      return client.seriesInfo(arg.$2);
    });
