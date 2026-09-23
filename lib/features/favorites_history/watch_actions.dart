import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/relay_theme.dart';
import '../../core/theme/relay_widgets.dart';
import '../../data/local/history_store.dart';
import '../accounts/plex_session.dart';
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
  });

  final String serverId;
  final String ratingKey;
  final String title;

  /// Null when unknown, which is always the case for a show (see
  /// `CatalogItem.viewCount`); both actions are offered then.
  final bool? watched;

  /// A show marks every episode, and the wording says so.
  final bool isShow;
}

/// The long-press sheet for a Plex title: mark it watched or unwatched.
///
/// A sheet of [RelayTappable] rows, as with the library sort, so a remote can
/// reach it with a visible ring. On a TV it opens from a held centre button.
Future<void> showWatchActions(
  BuildContext context,
  WidgetRef ref,
  WatchTarget target,
) async {
  final choice = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: RelayTheme.of(context).surface,
    builder: (context) {
      final t = RelayTheme.of(context);
      final f = RelayLayout.of(context);
      final scope = target.isShow ? ' (every episode)' : '';

      Widget option(String label, IconData icon, bool value, bool first) =>
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
                option('Mark as watched$scope', Icons.check_circle_outline,
                    true, true),
              if (offerUnwatched)
                option('Mark as unwatched$scope', Icons.radio_button_unchecked,
                    false, !offerWatched),
            ],
          ),
        ),
      );
    },
  );
  if (choice == null || !context.mounted) return;

  final messenger = ScaffoldMessenger.maybeOf(context);
  try {
    await ref.read(watchOverridesProvider.notifier).mark(
          serverId: target.serverId,
          ratingKey: target.ratingKey,
          watched: choice,
        );
  } catch (_) {
    messenger?.showSnackBar(const SnackBar(
      content: Text("Plex didn't accept that. The server may be offline."),
    ));
  }
}
