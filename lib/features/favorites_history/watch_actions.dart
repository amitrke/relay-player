import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/relay_theme.dart';
import '../../core/theme/relay_widgets.dart';
import '../../data/downloads/download_record.dart';
import '../../data/local/history_store.dart';
import '../accounts/plex_session.dart';
import '../downloads/downloads_controller.dart';
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
enum _Choice { watched, unwatched, download, removeDownload }

/// The long-press sheet for a Plex title: mark it watched or unwatched, and
/// save it on this device or take the saved copy off.
///
/// A sheet of [RelayTappable] rows, as with the library sort, so a remote can
/// reach it with a visible ring. On a TV it opens from a held centre button.
Future<void> showWatchActions(
  BuildContext context,
  WidgetRef ref,
  WatchTarget target,
) async {
  final existing = target.downloadable
      ? ref
            .read(downloadsProvider.notifier)
            .find(target.serverId, target.ratingKey)
      : null;
  if (!context.mounted) return;
  final choice = await showModalBottomSheet<_Choice>(
    context: context,
    backgroundColor: RelayTheme.of(context).surface,
    builder: (context) {
      final t = RelayTheme.of(context);
      final f = RelayLayout.of(context);
      final scope = target.isShow ? ' (every episode)' : '';

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

      final offerWatched = target.watched != true;
      final offerUnwatched = target.watched != false;
      // Download follows the state of any copy already there: nothing yet or a
      // failed one offers to fetch, a finished one offers to delete, and one in
      // progress offers to cancel.
      final offerDownload =
          target.downloadable &&
          (existing == null || existing.state == DownloadState.failed);
      final offerRemove =
          target.downloadable && existing != null && !offerDownload;
      var first = true;
      bool takeFirst() {
        final v = first;
        first = false;
        return v;
      }

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                child: Text(
                  target.title,
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
            ],
          ),
        ),
      );
    },
  );
  if (choice == null || !context.mounted) return;

  final messenger = ScaffoldMessenger.maybeOf(context);

  if (choice == _Choice.download || choice == _Choice.removeDownload) {
    final downloads = ref.read(downloadsProvider.notifier);
    if (choice == _Choice.download) {
      await downloads.enqueue(
        serverId: target.serverId,
        ratingKey: target.ratingKey,
        title: target.title,
        isEpisode: target.isEpisode,
      );
      messenger?.showSnackBar(
        const SnackBar(content: Text('Downloading. See the Downloads tab.')),
      );
    } else {
      await downloads.remove(target.serverId, target.ratingKey);
    }
    return;
  }

  try {
    await ref
        .read(watchOverridesProvider.notifier)
        .mark(
          serverId: target.serverId,
          ratingKey: target.ratingKey,
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
