import 'package:flutter/material.dart';

import '../../core/theme/relay_theme.dart';
import '../library/poster_tile.dart';
import 'suggestions_provider.dart';

/// The rows of "Because you watched" under the empty search box.
class SuggestionsView extends StatelessWidget {
  const SuggestionsView({super.key, required this.rows});

  final List<Suggestion> rows;

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);
    final f = RelayLayout.of(context);
    final tileWidth = f == RelayFormFactor.phone ? 108.0 : 124.0;
    // The grid's own poster proportions, so a tile looks the same here as in
    // the results.
    final tileHeight = tileWidth / 0.52;

    return ListView(
      padding: RelayLayout.pagePadding(f).copyWith(top: 8, bottom: 28),
      children: [
        for (final row in rows) ...[
          Padding(
            padding: const EdgeInsets.only(top: 14, bottom: 10),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Because you watched ',
                    style: TextStyle(color: t.inkDim),
                  ),
                  TextSpan(text: row.seedTitle),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: t.ink,
                fontSize: RelayLayout.bodySize(f) + 2,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(
            height: tileHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              itemCount: row.items.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, i) => SizedBox(
                width: tileWidth,
                child: PosterTile(item: row.items[i], showKind: true),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
