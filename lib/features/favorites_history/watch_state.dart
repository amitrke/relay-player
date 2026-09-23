import '../../data/local/history_store.dart';
import '../../domain/models/catalog_item.dart';

/// The history key a catalogue film is recorded under, or null for anything
/// that has no watch state of its own (a show: see [CatalogItem.viewCount]).
String? historyKeyOf(CatalogItem item) {
  if (item.kind != CatalogKind.movie) return null;
  final kind = switch (item.source) {
    CatalogSource.plex => PlaybackKind.plex,
    CatalogSource.xtream => PlaybackKind.xtreamVod,
  };
  return '${kind.wire}:${item.sourceId}:${item.id}';
}

/// Whether something has been watched, or how far through it someone is.
///
/// Plex keeps this per account on the server (`viewCount`, `viewOffset`), so it
/// includes what was watched in other Plex apps. It is also only as fresh as
/// the last library fetch, which does not happen after every play. This
/// device's own history is fresher for anything played here, so
/// [WatchState.resolve] lets it win when it is newer.
///
/// Panels keep no watch state at all, so for them this is local history or
/// nothing.
class WatchState {
  const WatchState._({required this.watched, this.progress});

  static const none = WatchState._(watched: false);
  static const finished = WatchState._(watched: true);

  final bool watched;

  /// 0..1 while part-way through; null when not started or finished.
  final double? progress;

  bool get inProgress => progress != null;

  /// Past this, a title counts as finished. Matches
  /// [HistoryItem.isResumable]'s upper bound, which is roughly where Plex
  /// itself marks things watched.
  static const _finishedAt = 0.95;

  /// Under this, it was a glance rather than a start. Also matches
  /// [HistoryItem.isResumable].
  static const _startedAfter = Duration(seconds: 60);

  /// [override] is a mark made in this session (see `watchOverridesProvider`),
  /// and beats everything: it is the newest thing anyone said about the title,
  /// and neither the library fetch nor local history knows about it yet.
  static WatchState resolve({
    bool? override,
    HistoryItem? local,
    int? plexViewCount,
    Duration? plexOffset,
    Duration? plexDuration,
    DateTime? plexLastViewedAt,
  }) {
    if (override != null) return override ? finished : none;
    final fromPlex = _fromPlex(plexViewCount, plexOffset, plexDuration);

    if (local != null && local.duration > Duration.zero) {
      final localIsNewer = plexLastViewedAt == null ||
          !local.lastWatchedAt.isBefore(plexLastViewedAt);
      if (localIsNewer) {
        if (local.progress >= _finishedAt) return finished;
        if (local.position >= _startedAfter) {
          return WatchState._(watched: false, progress: local.progress);
        }
        // A glance here says nothing about a finished watch elsewhere, so it
        // does not override Plex.
      }
    }
    return fromPlex;
  }

  /// [resolve] for a catalogue item. One function, so the tick on a poster
  /// and the "Unwatched only" filter cannot disagree about the same title.
  static WatchState forItem(
    CatalogItem item, {
    HistoryItem? local,
    bool? override,
  }) {
    if (historyKeyOf(item) == null) return none;
    return resolve(
      override: override,
      local: local,
      plexViewCount: item.viewCount,
      plexOffset: item.viewOffset,
      plexDuration: item.duration,
      plexLastViewedAt: item.lastViewedAt,
    );
  }

  static WatchState _fromPlex(int? views, Duration? offset, Duration? total) {
    // An offset on something already watched means a rewatch in progress,
    // and the bar is the more useful thing to show.
    if (offset != null &&
        total != null &&
        total > Duration.zero &&
        offset >= _startedAfter) {
      final p = offset.inMilliseconds / total.inMilliseconds;
      if (p < _finishedAt) return WatchState._(watched: false, progress: p);
    }
    return (views ?? 0) > 0 ? finished : none;
  }
}
