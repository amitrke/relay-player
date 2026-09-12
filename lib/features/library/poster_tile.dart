import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/relay_theme.dart';
import '../../core/theme/relay_widgets.dart';
import '../../data/local/favorites_store.dart';
import '../../domain/models/catalog_item.dart';
import '../favorites_history/favorites_controller.dart';

/// One catalogue item: poster, title, year, favourite star.
class PosterTile extends ConsumerWidget {
  const PosterTile({super.key, required this.item, this.autofocus = false});

  final CatalogItem item;

  /// The first tile in a grid takes focus, so a remote lands on the content
  /// rather than nowhere.
  final bool autofocus;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = RelayTheme.of(context);
    final f = RelayLayout.of(context);
    final poster = item.posterUrl;

    return RelayTappable(
      autofocus: autofocus,
      borderRadius: 10,
      onTap: () => context.push(item.route),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: double.infinity,
                    color: t.surface,
                    child: poster == null
                        ? Icon(Icons.movie_outlined, color: t.inkDim)
                        : Image.network(
                            poster,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) =>
                                Icon(Icons.movie_outlined, color: t.inkDim),
                          ),
                  ),
                ),
                Positioned(
                  top: -6,
                  right: -6,
                  // Artwork is unpredictable, so the star needs its own
                  // backing to stay legible on a bright poster.
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: t.stage.withValues(alpha: 0.55),
                      shape: BoxShape.circle,
                    ),
                    child: FavoriteButton(
                      dense: true,
                      size: 18,
                      item: FavoriteItem(
                        kind: item.kind == CatalogKind.show
                            ? FavoriteKind.show
                            : FavoriteKind.movie,
                        sourceId: item.sourceId,
                        itemId: item.id,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: t.ink,
              // 12.5 is a phone caption and unreadable across a room.
              fontSize: f == RelayFormFactor.tv ? 18 : 12.5,
              height: 1.3,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (item.year != null)
            Text(
              '${item.year}',
              style: TextStyle(
                color: t.inkDim,
                fontSize: f == RelayFormFactor.tv ? 15 : 11,
              ),
            ),
        ],
      ),
    );
  }
}
