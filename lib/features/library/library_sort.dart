import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/app_settings_store.dart';
import '../../domain/models/catalog_item.dart';
import '../settings/settings_controller.dart';

/// How Movies and Series are ordered.
///
/// One choice for both tabs rather than one each: the question "what's new?"
/// is the same question on either tab, and a second control to keep in sync
/// is not worth it until someone asks for it.
enum LibrarySort {
  title('Title'),
  recentlyAdded('Recently added'),
  year('Year');

  const LibrarySort(this.label);

  final String label;

  static LibrarySort fromName(String? name) {
    for (final s in values) {
      if (s.name == name) return s;
    }
    return title;
  }

  /// Sorted copy of [items].
  ///
  /// Items a source gave no date or year for go last rather than first: a
  /// panel that sends no `added` field would otherwise put its whole catalogue
  /// at the top of "Recently added". Title breaks every tie, so the order is
  /// stable across refreshes.
  List<CatalogItem> apply(List<CatalogItem> items) {
    int byTitle(CatalogItem a, CatalogItem b) =>
        a.sortKey.compareTo(b.sortKey);

    int newestFirst(Comparable<dynamic>? a, Comparable<dynamic>? b) {
      if (a == null && b == null) return 0;
      if (a == null) return 1;
      if (b == null) return -1;
      return b.compareTo(a);
    }

    final sorted = [...items];
    switch (this) {
      case title:
        sorted.sort(byTitle);
      case recentlyAdded:
        sorted.sort((a, b) {
          final c = newestFirst(a.addedAt, b.addedAt);
          return c != 0 ? c : byTitle(a, b);
        });
      case year:
        sorted.sort((a, b) {
          final c = newestFirst(a.year, b.year);
          return c != 0 ? c : byTitle(a, b);
        });
    }
    return sorted;
  }
}

const _kLibrarySort = 'librarySort';

final librarySortProvider =
    NotifierProvider<LibrarySortController, LibrarySort>(
  LibrarySortController.new,
);

class LibrarySortController extends Notifier<LibrarySort> {
  AppSettingsStore get _store => ref.read(appSettingsStoreProvider);

  @override
  LibrarySort build() => LibrarySort.fromName(_store.getString(_kLibrarySort));

  Future<void> set(LibrarySort sort) async {
    state = sort;
    await _store.setString(_kLibrarySort, sort.name);
  }
}
