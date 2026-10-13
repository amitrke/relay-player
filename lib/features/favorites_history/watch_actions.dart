import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/relay_theme.dart';
import '../../core/theme/relay_widgets.dart';
import '../../data/downloads/download_record.dart';
import '../../data/local/favorites_store.dart';
import '../../data/local/history_store.dart';
import '../accounts/plex_session.dart';
import '../downloads/downloads_controller.dart';
import 'favorites_controller.dart';
import 'history_controller.dart';
import 'resume_entries.dart';

/// Watched / unwatched marks made in this session, by history key
/// (`plex:<server>:<ratingKey>`).
///
/// Plex is told straight away, but the library and episode lists this app
/// already fetched still carry the old `viewCount`, and they are not refetched
/// after a mark: a Movies tab is one request per library. So the mark is held
/// here and [WatchState.resolve] treats it as the newest word on the title
/// until the next launch, by which time Plex's own answer agrees with it.
final watchOverridesProvider =
    NotifierProvider<WatchOverrides, Map<String, bool>>(WatchOverrides.new);

class WatchOverrides extends Notifier<Map<String, bool>> {
  @override
  Map<String, bool> build() => const {};

  /// Tells Plex, then updates everything on screen that reflects it.
  ///
  /// Throws if Plex refuses; the caller says so rather than showing a tick
  /// that the server does not agree with.
  Future<void> mark({
    required String serverId,
    required String ratingKey,
    required bool watched,
  }) async {
    final server = ref
        .read(connectedServersProvider)
        .where((s) => s.id == serverId)
        .firstOrNull;
    if (server == null) {
      throw StateError('No connected Plex server with id "$serverId".');
    }
    await server.service.setWatched(ratingKey, watched: watched);

    final key = '${PlaybackKind.plex.wire}:$serverId:$ratingKey';
    state = {...state, key: watched};
    // Either way the local position is now wrong: a watched title has nothing
    // to resume, and an unwatched one starts again. Leaving it would put the
    // title straight back in Continue watching.
    await ref.read(historyProvider.notifier).remove(key);
    ref.invalidate(plexOnDeckProvider);
  }
}

/// What a watched action applies to.
class WatchTarget {
  const WatchTarget({
    required this.serverId,
    required this.ratingKey,
    required this.title,
    this.watched,
    this.isShow = false,
    this.downloadable = false,
    this.isEpisode = false,
  });

  final String serverId;
  final String ratingKey;
  final String title;

  /// Null when unknown, which is always the case for a show (see
  /// `CatalogItem.viewCount`); both actions are offered then.
  final bool? watched;

  /// A show marks every episode, and the wording says so.
  final bool isShow;

  /// Whether the sheet offers to save it on this device (§18). A film or an
  /// episode, never a show: a show is a folder, and downloading every episode
  /// of one is a decision about gigabytes that a single press should not make.
  final bool downloadable;
  final bool isEpisode;
}

/// What was picked in the sheet.
enum _Choice {
  watched,
  unwatched,
  download,
  removeDownload,
  favorite,
  dismissResume,
}

/// The long-press sheet for a title: mark it watched or unwatched, save it on
/// this device or take the saved copy off, star it, or take it out of Continue
/// watching.
///
/// A sheet of [RelayTappable] rows, as with the library sort, so a remote can
/// reach it with a visible ring. On a TV it opens from a held centre button.
///
/// [target] is the Plex part and is null for a panel title, which has no
/// watched state and nothing to download; [title] names the sheet then.
/// [favorite] and [resume] add the star and the Continue watching dismissal.
/// Until 2026-10-10 those two were only small icon buttons on the poster, and
/// on a TV that made each tile two or three focus stops instead of one: the
/// star has no focus ring (the theme sets no `focusColor`, §11), so Down from
/// one row landed invisibly on the star at the top of the tile below and
/// looked like a press that did nothing, and Right from that small rect, sitting
/// in the band of the Continue watching row, jumped up into it. Those buttons
/// now stay out of focus on a TV and the actions live here instead.
Future<void> showWatchActions(
  BuildContext context,
  WidgetRef ref,
  WatchTarget? target, {
  String? title,
  FavoriteItem? favorite,
  ResumeEntry? resume,
}) async {
  assert(target != null || title != null, 'The sheet needs a title.');
  final heading = target?.title ?? title ?? '';
  final existing = target != null && target.downloadable
      ? ref
            .read(downloadsProvider.notifier)
            .find(target.serverId, target.ratingKey)
      : null;
  if (!context.mounted) return;
  final choice = await showModalBottomSheet<_Choice>(
    context: context,
    backgroundColor: RelayTheme.of(context).surface,
    // A sheet is capped at 9/16 of the screen unless it is scroll controlled,
    // and a 540 dp TV fits only three rows in that: a Plex film in Continue
    // watching has four, and overflowed by a couple of pixels (2026-10-10).
    // Sized to its rows now, and scrolling if a larger text scale needs it.
    isScrollControlled: true,
    builder: (context) {
      final t = RelayTheme.of(context);
      final f = RelayLayout.of(context);
      final scope = target?.isShow ?? false ? ' (every episode)' : '';

      Widget option(String label, IconData icon, _Choice value, bool first) =>
          RelayTappable(
            borderRadius: 10,
            autofocus: first,
            onTap: () => Navigator.of(context).pop(value),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              child: Row(
                children: [
                  Icon(icon, color: t.inkDim),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: t.ink,
                        fontSize: RelayLayout.bodySize(f) + 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );

      final offerWatched = target != null && target.watched != true;
      final offerUnwatched = target != null && target.watched != false;
      // Download follows the state of any copy already there: nothing yet or a
      // failed one offers to fetch, a finished one offers to delete, and one in
      // progress offers to cancel.
      final offerDownload =
          target != null &&
          target.downloadable &&
          (existing == null || existing.state == DownloadState.failed);
      final offerRemove =
          target != null &&
          target.downloadable &&
          existing != null &&
          !offerDownload;
      final isFavorite =
          favorite != null &&
          ref.read(favoritesProvider).contains(favorite.key);
      var first = true;
      bool takeFirst() {
        final v = first;
        first = false;
        return v;
      }

      return SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                  child: Text(
                    heading,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: t.inkDim,
                      fontSize: RelayLayout.bodySize(f),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (offerWatched)
                  option(
                    'Mark as watched$scope',
                    Icons.check_circle_outline,
                    _Choice.watched,
                    takeFirst(),
                  ),
                if (offerUnwatched)
                  option(
                    'Mark as unwatched$scope',
                    Icons.radio_button_unchecked,
                    _Choice.unwatched,
                    takeFirst(),
                  ),
                if (offerDownload)
                  option(
                    'Download to this device',
                    Icons.download_outlined,
                    _Choice.download,
                    takeFirst(),
                  ),
                if (offerRemove)
                  option(
                    existing.isComplete ? 'Delete download' : 'Cancel download',
                    Icons.delete_outline,
                    _Choice.removeDownload,
                    takeFirst(),
                  ),
                if (favorite != null)
                  option(
                    isFavorite ? 'Remove from favourites' : 'Add to favourites',
                    isFavorite ? Icons.star : Icons.star_border,
                    _Choice.favorite,
                    takeFirst(),
                  ),
                if (resume != null)
                  option(
                    'Remove from Continue watching',
                    Icons.close,
                    _Choice.dismissResume,
                    takeFirst(),
                  ),
              ],
            ),
          ),
        ),
      );
    },
  );
  if (choice == null || !context.mounted) return;

  final messenger = ScaffoldMessenger.maybeOf(context);

  if (choice == _Choice.favorite) {
    await ref.read(favoritesProvider.notifier).toggle(favorite!);
    return;
  }
  if (choice == _Choice.dismissResume) {
    await ref.read(resumeDismissalsProvider.notifier).dismiss(resume!);
    return;
  }
  // Every other choice is one of the Plex ones, offered only with a target.
  final plex = target!;

  if (choice == _Choice.download || choice == _Choice.removeDownload) {
    final downloads = ref.read(downloadsProvider.notifier);
    if (choice == _Choice.download) {
      await downloads.enqueue(
        serverId: plex.serverId,
        ratingKey: plex.ratingKey,
        title: plex.title,
        isEpisode: plex.isEpisode,
      );
      messenger?.showSnackBar(
        const SnackBar(content: Text('Downloading. See the Downloads tab.')),
      );
    } else {
      await downloads.remove(plex.serverId, plex.ratingKey);
    }
    return;
  }

  try {
    await ref
        .read(watchOverridesProvider.notifier)
        .mark(
          serverId: plex.serverId,
          ratingKey: plex.ratingKey,
          watched: choice == _Choice.watched,
        );
  } catch (_) {
    messenger?.showSnackBar(
      const SnackBar(
        content: Text("Plex didn't accept that. The server may be offline."),
      ),
    );
  }
}
