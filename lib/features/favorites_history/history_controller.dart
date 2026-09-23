import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/history_store.dart';
import '../settings/settings_controller.dart';

final historyStoreProvider = Provider<HistoryStore>((ref) {
  return HistoryStore(ref.watch(appSettingsStoreProvider));
});

final historyProvider =
    NotifierProvider<HistoryController, List<HistoryItem>>(
  HistoryController.new,
);

class HistoryController extends Notifier<List<HistoryItem>> {
  HistoryStore get _store => ref.read(historyStoreProvider);

  @override
  List<HistoryItem> build() {
    final items = _store.all();
    // Fire-and-forget: a box written by the pre-2026-09-22 code holds a live
    // X-Plex-Token per continue-watching row, and `items` above is already the
    // cleaned view, so there is nothing to wait for before rendering.
    unawaited(_store.purgeLeakedCredentials());
    return items;
  }

  /// Everything worth offering to resume, newest first.
  List<HistoryItem> get resumable =>
      [for (final item in state) if (item.isResumable) item];

  HistoryItem? find(PlaybackKind kind, String sourceId, String itemId) {
    final key = '${kind.wire}:$sourceId:$itemId';
    for (final item in state) {
      if (item.key == key) return item;
    }
    return null;
  }

  Future<void> record(HistoryItem item) async {
    final next = [
      item,
      for (final existing in state)
        if (existing.key != item.key) existing,
    ];
    state = next;
    await _store.write(next);
  }

  Future<void> remove(String key) async {
    final next = [for (final i in state) if (i.key != key) i];
    state = next;
    await _store.write(next);
  }
}
