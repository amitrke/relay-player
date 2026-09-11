import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/xtream/xtream_account_store.dart';
import '../../data/xtream/xtream_client.dart';
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

final xtreamCategoriesProvider =
    FutureProvider.family<List<XtreamCategory>, XtreamAccount>(
        (ref, account) async {
  final client = await ref.watch(xtreamClientProvider(account).future);
  return client.liveCategories();
});

/// Channels for the categories the user actually chose (§4.1).
///
/// Never calls the unfiltered endpoint — Phase 0 measured that at 5.3 MB for
/// live and 26.2 MB for VOD on a real panel. Nothing selected means nothing
/// fetched, which is the point of opt-in.
final xtreamChannelsProvider =
    FutureProvider.family<List<XtreamChannel>, XtreamAccount>(
        (ref, account) async {
  if (account.selectedCategoryIds.isEmpty) return const [];
  final client = await ref.watch(xtreamClientProvider(account).future);

  final pages = await Future.wait(
    account.selectedCategoryIds.map((id) async {
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
