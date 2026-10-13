import 'package:flutter/material.dart';

import '../../core/theme/relay_theme.dart';
import '../../domain/models/catalog_item.dart';
import '../library/poster_tile.dart';
import 'suggestions_provider.dart';

/// The empty Search screen: an optional [leading] section (the AI one, when a
/// provider is set up), then the "Because you watched" rows.
class SuggestionsView extends StatelessWidget {
  const SuggestionsView({super.key, required this.rows, this.leading});

  final List<Suggestion> rows;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);
    final f = RelayLayout.of(context);

    return ListView(
      padding: RelayLayout.pagePadding(f).copyWith(top: 8, bottom: 28),
      children: [
        ?leading,
        for (final row in rows) ...[
          RowHeading(
            lead: 'Because you watched ',
            title: row.seedTitle,
            color: t.ink,
            dim: t.inkDim,
          ),
          PosterRow(items: row.items),
        ],
      ],
    );
  }
}

/// A heading with a dimmed lead-in: "Because you watched" and then the title.
class RowHeading extends StatelessWidget {
  const RowHeading({
    super.key,
    required this.lead,
    required this.title,
    required this.color,
    required this.dim,
  });

  final String lead;
  final String title;
  final Color color;
  final Color dim;

  @override
  Widget build(BuildContext context) {
    final f = RelayLayout.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 10),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: lead,
              style: TextStyle(color: dim),
            ),
            TextSpan(text: title),
          ],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: RelayLayout.bodySize(f) + 2,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// A horizontal row of poster tiles, the same proportions as the results grid
/// so a tile looks the same here as there.
class PosterRow extends StatelessWidget {
  const PosterRow({super.key, required this.items});

  final List<CatalogItem> items;

  @override
  Widget build(BuildContext context) {
    final f = RelayLayout.of(context);
    final tileWidth = f == RelayFormFactor.phone ? 108.0 : 124.0;
    final tileHeight = tileWidth / 0.52;

    return SizedBox(
      height: tileHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, i) => SizedBox(
          width: tileWidth,
          child: PosterTile(item: items[i], showKind: true),
        ),
      ),
    );
  }
}
