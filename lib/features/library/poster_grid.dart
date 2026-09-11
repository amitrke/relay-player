import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/plex/plex_service.dart';
import '../../core/theme/relay_theme.dart';
import '../../core/theme/relay_widgets.dart';
import '../favorites_history/favorites_controller.dart';
import '../../data/local/favorites_store.dart';
import 'poster_tile.dart';

/// The responsive poster grid shared by Library and Search.
class PosterGrid extends ConsumerWidget {
  const PosterGrid({super.key, required this.items});

  final List<SourcedItem> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final f = RelayLayout.of(context);
    final ordered = favouritesFirst(
      items,
      ref.watch(favoritesProvider),
      (item) => FavoriteItem(
        kind: item.metadata.type.wire == 'show'
            ? FavoriteKind.show
            : FavoriteKind.movie,
        sourceId: item.serverId,
        itemId: item.metadata.ratingKey,
      ),
    );
    final columns = switch (f) {
      RelayFormFactor.phone => 3,
      RelayFormFactor.tablet => 5,
      RelayFormFactor.desktop => 6,
      RelayFormFactor.tv => 7,
    };

    return GridView.builder(
      padding: RelayLayout.pagePadding(f).copyWith(top: 14, bottom: 28),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        childAspectRatio: 0.52,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
      ),
      itemCount: ordered.length,
      itemBuilder: (context, i) => PosterTile(item: ordered[i]),
    );
  }
}

/// A stated reason the area is blank — never a bare empty grid.
///
/// Phase 0 made this a requirement rather than a nicety: an empty guide with no
/// explanation reads as broken software, and several of this app's sources are
/// legitimately empty (a provider with no EPG data, a tab whose source type is
/// not connected).
class LibraryEmptyState extends StatelessWidget {
  const LibraryEmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.onRetry,
  });

  final IconData icon;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: t.inkDim, size: 34),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: t.inkDim, height: 1.5),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 18),
              RelayButton(label: 'Try again', onPressed: onRetry),
            ],
          ],
        ),
      ),
    );
  }
}
