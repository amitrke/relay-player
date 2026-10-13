import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/relay_theme.dart';
import '../../core/theme/relay_widgets.dart';
import '../../domain/models/catalog_item.dart';
import '../favorites_history/favorites_controller.dart';
import '../../data/local/favorites_store.dart';
import 'poster_tile.dart';

/// The responsive poster grid shared by Library and Search.
///
/// Left and Right step to the neighbouring tile by index, not by geometry.
/// Flutter's directional traversal picks the nearest node whose rect overlaps
/// the focused one's vertical band, and a grid row scrolled partly up under
/// the Continue watching row above it overlaps that row's band: Right from the
/// third poster went to the third resume tile, which is nearer by x than the
/// fourth poster (seen on the Google TV emulator, 2026-10-10). The resume row
/// does not have the problem the other way round because traversal already
/// prefers nodes in the same horizontal scrollable, and a grid is vertical.
/// Up and Down are left to geometry, which is what reaches that row at all.
class PosterGrid extends ConsumerStatefulWidget {
  const PosterGrid({
    super.key,
    required this.items,
    this.onRowFocused,
    this.showKind = false,
  });

  final List<CatalogItem> items;

  /// Passed to each tile; see [PosterTile.showKind].
  final bool showKind;

  /// Told which row of the grid took focus, so a screen can fold its own chrome
  /// away once the viewer is past the first row and bring it back on row 0.
  final ValueChanged<int>? onRowFocused;

  @override
  ConsumerState<PosterGrid> createState() => _PosterGridState();
}

class _PosterGridState extends ConsumerState<PosterGrid> {
  /// One per slot, made when the slot is first built. Per index rather than per
  /// item: the slot is what a key press moves between, whatever is in it.
  final _nodes = <int, FocusNode>{};

  FocusNode _nodeAt(int i) => _nodes.putIfAbsent(i, FocusNode.new);

  @override
  void dispose() {
    for (final node in _nodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  /// Left at the first column is ignored, so it carries on up to
  /// [RelayFocusBoundary] and reaches the rail. Right at the end of a row is
  /// swallowed: nothing is to the right, and letting geometry answer is the bug
  /// this replaces.
  KeyEventResult _onKey(KeyEvent event, int i, int columns, int count) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowRight) {
      final last = i % columns == columns - 1 || i == count - 1;
      if (!last) _nodeAt(i + 1).requestFocus();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowLeft && i % columns != 0) {
      _nodeAt(i - 1).requestFocus();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    final showKind = widget.showKind;
    final f = RelayLayout.of(context);
    final ordered = favouritesFirst(
      items,
      ref.watch(favoritesProvider),
      (item) => FavoriteItem(
        kind: item.kind == CatalogKind.show
            ? FavoriteKind.show
            : FavoriteKind.movie,
        sourceId: item.sourceId,
        itemId: item.id,
      ),
    );
    // Label each poster with its source only when the grid mixes them. With
    // Plex alone, which is most people, a "Plex" tag on every tile says
    // nothing and covers artwork.
    final mixed = items.map((i) => i.source).toSet().length > 1;
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
      // The first tile takes focus on a TV so a remote starts on the content
      // instead of nowhere. Only on a TV: on a phone it would pull an unwanted
      // focus highlight onto a tile nobody touched.
      itemBuilder: (context, i) {
        final tile = PosterTile(
          item: ordered[i],
          showSource: mixed,
          showKind: showKind,
          focusNode: _nodeAt(i),
          autofocus: i == 0 && RelayLayout.of(context) == RelayFormFactor.tv,
        );
        final onRowFocused = widget.onRowFocused;
        // A passive node above the tile: it never takes focus or joins
        // traversal itself, but `onFocusChange` fires when focus arrives
        // anywhere beneath it, and arrow keys the tile ignores reach it.
        return Focus(
          canRequestFocus: false,
          skipTraversal: true,
          onFocusChange: onRowFocused == null
              ? null
              : (focused) {
                  if (focused) onRowFocused(i ~/ columns);
                },
          onKeyEvent: (_, event) => _onKey(event, i, columns, ordered.length),
          child: tile,
        );
      },
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
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final VoidCallback? onRetry;

  /// An action offered instead of a bare dead end — an empty library should say
  /// what to do about it.
  final String? actionLabel;
  final VoidCallback? onAction;

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
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: 18),
              RelayButton(label: actionLabel!, onPressed: onAction),
            ],
          ],
        ),
      ),
    );
  }
}
