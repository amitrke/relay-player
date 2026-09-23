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
  const PosterTile({
    super.key,
    required this.item,
    this.autofocus = false,
    this.showSource = false,
  });

  final CatalogItem item;

  /// Whether to label the poster with where it comes from. The grid decides,
  /// because only it knows whether its items come from more than one source.
  final bool showSource;

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
                if (showSource)
                  Positioned(
                    left: 6,
                    bottom: 6,
                    child: SourceBadge(source: item.source),
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

/// A small label naming where an item comes from.
///
/// The wording follows what the app already calls these sources on screen:
/// Plex by name, and a panel as IPTV, as in Settings and onboarding. Never the
/// panel's own name: a provider label on a poster belongs to the user, but it
/// would also turn up in anything shot from a screen (§1).
class SourceBadge extends StatelessWidget {
  const SourceBadge({super.key, required this.source});

  final CatalogSource source;

  static String labelFor(CatalogSource source) => switch (source) {
        CatalogSource.plex => 'Plex',
        CatalogSource.xtream => 'IPTV',
      };

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);
    final tv = RelayLayout.of(context) == RelayFormFactor.tv;
    return DecoratedBox(
      // Backed like the favourite star: artwork is unpredictable, and stage
      // with ink reads in light and dark palettes alike.
      decoration: BoxDecoration(
        color: t.stage.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        child: Text(
          labelFor(source),
          style: TextStyle(
            color: t.ink,
            fontSize: tv ? 12 : 9.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}
