import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/xtream/xtream_account_store.dart';
import '../../data/xtream/xtream_client.dart';
import '../../domain/models/catalog_item.dart';
import '../settings/settings_controller.dart';

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
    state = _store.accounts();
  }
}

/// A ready-to-use client for [account], with its password joined back in.
final xtreamClientProvider =
    FutureProvider.family<XtreamClient, XtreamAccount>((ref, account) async {
  final password = await ref.watch(xtreamAccountStoreProvider).password(
        account.id,
      );
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
});

/// (account, catalogue) — Riverpod families take one argument.
typedef XtreamScope = (XtreamAccount, XtreamCatalogue);

final xtreamCategoriesProvider =
    FutureProvider.family<List<XtreamCategory>, XtreamScope>(
        (ref, scope) async {
  final (account, catalogue) = scope;
  final client = await ref.watch(xtreamClientProvider(account).future);
  return switch (catalogue) {
    XtreamCatalogue.live => client.liveCategories(),
    XtreamCatalogue.vod => client.vodCategories(),
    XtreamCatalogue.series => client.seriesCategories(),
  };
});

/// Channels for the categories the user actually chose (§4.1).
final xtreamChannelsProvider =
    FutureProvider.family<List<XtreamChannel>, XtreamAccount>(
        (ref, account) async {
  if (account.liveCategoryIds.isEmpty) return const [];
  final client = await ref.watch(xtreamClientProvider(account).future);

  final pages = await Future.wait(
    account.liveCategoryIds.map((id) async {
      try {
        return await client.liveStreams(id);
      } catch (_) {
        // One bad category should cost its own channels, not the whole list.
        return const <XtreamChannel>[];
      }
    }),
  );
  return pages.expand((page) => page).toList();
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

  final pages = await Future.wait(
    ids.map((id) async {
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
    FutureProvider.family<List<XtreamSeason>, (XtreamAccount, String)>(
        (ref, arg) async {
  final client = await ref.watch(xtreamClientProvider(arg.$1).future);
  return client.seriesInfo(arg.$2);
});
