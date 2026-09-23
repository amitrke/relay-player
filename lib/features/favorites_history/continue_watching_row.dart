import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/relay_theme.dart';
import '../../core/theme/relay_widgets.dart';
import '../../data/local/history_store.dart';
import '../accounts/plex_session.dart';
import 'history_controller.dart';

// Type sizes for the two lines under a resume tile's poster, and the gaps
// around them. Shared because the row must reserve exactly the height the tile
// then draws into: a horizontal ListView needs a bounded height, so the two
// cannot each decide independently.
const double _titleSize = 13;
const double _metaSize = 11;
const double _gapAbovePoster = 8;
const double _gapBetweenLines = 2;

/// Line box multiplier, set explicitly on both text styles below.
///
/// Pinning it is what makes [_tileHeight] exact instead of a guess. Left to
/// the font's own metrics the line box is unknowable before layout, and the
/// first attempt at this fix approximated it at 1.45 and still overflowed by
/// 6px at a 1.5 text scale. A reservation that has to predict the renderer
/// will always be wrong at some scale; one that *dictates* the line height
/// cannot be.
const double _lineFactor = 1.25;

/// Height of one resume tile: poster, then the title and remaining-time lines.
///
/// The text block was a flat `54` until 2026-09-22, which silently assumed a
/// text scale of 1.0. On a phone set to 1.3 — an ordinary accessibility
/// setting, not an extreme one — the tile overflowed its row by 7px and the
/// remaining-time line was clipped. Release builds clip without complaint, so
/// this only became visible the first time a debug build ran on a phone.
/// Reserving against the live [TextScaler] is what makes it follow the user.
double _tileHeight(BuildContext context, double tileWidth) {
  final scaler = MediaQuery.textScalerOf(context);
  final text = _gapAbovePoster +
      scaler.scale(_titleSize) * _lineFactor +
      _gapBetweenLines +
      scaler.scale(_metaSize) * _lineFactor;
  return tileWidth * 0.62 + text.ceilToDouble();
}

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
          height: _tileHeight(context, tileWidth),
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

  /// Resolves [HistoryItem.poster] to something `Image.network` can fetch.
  ///
  /// A Plex entry stores the unsigned artwork path, because the signed
  /// transcode URL carries `X-Plex-Token` and history is kept in the
  /// unencrypted Hive box (§3). Signing happens here, per frame, from the live
  /// session — so a server that is not currently reachable simply shows the
  /// placeholder rather than a stale credential. A panel entry already holds
  /// an absolute URL with no credential in it, and passes through.
  String? _poster(WidgetRef ref) {
    final ref0 = item.poster;
    if (ref0 == null || ref0.isEmpty) return null;
    if (item.kind != PlaybackKind.plex) return ref0;
    return plexServiceFor(ref, item.sourceId).posterUrlForPath(ref0);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = RelayTheme.of(context);
    final remaining = item.duration - item.position;
    final poster = _poster(ref);

    return SizedBox(
      width: width,
      child: RelayTappable(
        borderRadius: 10,
        onTap: () => context.push(item.route),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Expanded, not a fixed poster height: the two text lines below
            // take whatever the user's text scale needs and the poster absorbs
            // the remainder. Pinning both — a fixed poster *and* a predicted
            // text block — is what put a "BOTTOM OVERFLOWED" banner on this
            // tile at every text scale above 1.0, clipped silently in release
            // (2026-09-22). This way a reservation that is slightly off costs
            // a few pixels of artwork instead of clipping the text.
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                clipBehavior: Clip.none,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      color: t.surface,
                      child: poster == null
                          ? Icon(Icons.play_circle_outline, color: t.inkDim)
                          : Image.network(
                              poster,
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
            ),
            const SizedBox(height: _gapAbovePoster),
            Text(
              item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: t.ink,
                fontSize: _titleSize,
                height: _lineFactor,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: _gapBetweenLines),
            Text(
              '${remaining.inMinutes} min left',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: t.inkDim,
                fontSize: _metaSize,
                height: _lineFactor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
