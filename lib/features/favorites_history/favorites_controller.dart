import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/relay_theme.dart';
import '../../data/local/favorites_store.dart';
import '../settings/settings_controller.dart';

final favoritesStoreProvider = Provider<FavoritesStore>((ref) {
  return FavoritesStore(ref.watch(appSettingsStoreProvider));
});

/// Favourite keys, as a set for O(1) lookup while rendering long lists.
///
/// A panel's channel list runs to thousands of rows even after category
/// filtering, and every row asks "am I a favourite?" on every build.
final favoritesProvider =
    NotifierProvider<FavoritesController, Set<String>>(
  FavoritesController.new,
);

class FavoritesController extends Notifier<Set<String>> {
  FavoritesStore get _store => ref.read(favoritesStoreProvider);

  @override
  Set<String> build() => {for (final item in _store.all()) item.key};

  bool contains(FavoriteItem item) => state.contains(item.key);

  Future<void> toggle(FavoriteItem item) async {
    final items = _store.all();
    final next = state.contains(item.key)
        ? [for (final i in items) if (i.key != item.key) i]
        : [...items, item];
    state = {for (final i in next) i.key};
    await _store.write(next);
  }
}

/// Orders [items] so favourites come first, preserving the existing order
/// within each group.
///
/// Reordering rather than filtering: §12's Home shows a favourites row above
/// the full list, not instead of it, and a user who favourites three channels
/// still wants the other 400 reachable.
List<T> favouritesFirst<T>(
  List<T> items,
  Set<String> favorites,
  FavoriteItem Function(T) keyOf,
) {
  final first = <T>[];
  final rest = <T>[];
  for (final item in items) {
    (favorites.contains(keyOf(item).key) ? first : rest).add(item);
  }
  return [...first, ...rest];
}

/// The star. Same control wherever something can be favourited.
class FavoriteButton extends ConsumerWidget {
  const FavoriteButton({
    super.key,
    required this.item,
    this.size = 20,
    this.dense = false,
  });

  final FavoriteItem item;
  final double size;

  /// Tighter hit box for use inside a dense row.
  final bool dense;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = RelayTheme.of(context);
    final isFavorite = ref.watch(favoritesProvider).contains(item.key);

    return IconButton(
      visualDensity: dense ? VisualDensity.compact : null,
      iconSize: size,
      tooltip: isFavorite ? 'Remove from favourites' : 'Add to favourites',
      icon: Icon(
        isFavorite ? Icons.star : Icons.star_border,
        color: isFavorite ? t.accent : t.inkDim,
      ),
      onPressed: () => ref.read(favoritesProvider.notifier).toggle(item),
    );
  }
}
