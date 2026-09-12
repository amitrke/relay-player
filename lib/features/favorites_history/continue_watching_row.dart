import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/relay_theme.dart';
import '../../core/theme/relay_widgets.dart';
import '../../data/local/history_store.dart';
import 'history_controller.dart';

/// The continue-watching row from the Home artboard.
///
/// Mixed on purpose: a film, a panel episode and a Plex episode belong in one
/// row because "what was I in the middle of" does not sort by source. It hides
/// itself entirely when nothing is resumable, rather than leaving an empty
/// heading above the grid.
class ContinueWatchingRow extends ConsumerWidget {
  const ContinueWatchingRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = RelayTheme.of(context);
    final f = RelayLayout.of(context);

    ref.watch(historyProvider);
    final items = ref.read(historyProvider.notifier).resumable;
    if (items.isEmpty) return const SizedBox.shrink();

    final tileWidth = f == RelayFormFactor.phone ? 168.0 : 252.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: RelayLayout.pagePadding(f).copyWith(top: 14, bottom: 10),
          child: Text(
            'Continue watching',
            style: TextStyle(
              color: t.ink,
              fontSize: RelayLayout.bodySize(f) + 2,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(
          height: tileWidth * 0.62 + 54,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: RelayLayout.pagePadding(f).copyWith(top: 0, bottom: 0),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, i) => _ResumeTile(
              item: items[i],
              width: tileWidth,
            ),
          ),
        ),
      ],
    );
  }
}

class _ResumeTile extends ConsumerWidget {
  const _ResumeTile({required this.item, required this.width});

  final HistoryItem item;
  final double width;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = RelayTheme.of(context);
    final remaining = item.duration - item.position;

    return SizedBox(
      width: width,
      child: RelayTappable(
        borderRadius: 10,
        onTap: () => context.push(item.route),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: width,
                    height: width * 0.62,
                    color: t.surface,
                    child: item.posterUrl == null
                        ? Icon(Icons.play_circle_outline, color: t.inkDim)
                        : Image.network(
                            item.posterUrl!,
                            // Contain, not cover: sources give us portrait
                            // posters and this tile is landscape, so cropping
                            // slices the artwork through the middle.
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) => Icon(
                              Icons.play_circle_outline,
                              color: t.inkDim,
                            ),
                          ),
                  ),
                ),
                Positioned(
                  left: 8,
                  right: 8,
                  bottom: 8,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: item.progress,
                      minHeight: 3,
                      backgroundColor: Colors.white24,
                      valueColor: AlwaysStoppedAnimation(t.accent),
                    ),
                  ),
                ),
                Positioned(
                  top: -6,
                  right: -6,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: t.stage.withValues(alpha: 0.55),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      visualDensity: VisualDensity.compact,
                      iconSize: 16,
                      tooltip: 'Remove from continue watching',
                      icon: Icon(Icons.close, color: t.inkDim),
                      onPressed: () => ref
                          .read(historyProvider.notifier)
                          .remove(item.key),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: t.ink,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${remaining.inMinutes} min left',
              style: TextStyle(color: t.inkDim, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
