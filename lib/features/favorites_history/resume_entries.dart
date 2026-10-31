import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/app_settings_store.dart';
import '../../data/local/history_store.dart';
import '../library/library_screen.dart' show serverSectionsProvider;
import '../library/library_tab.dart';
import '../settings/settings_controller.dart';
import 'history_controller.dart';
import '../../i18n/strings.g.dart';
import '../accounts/media_servers.dart';
import '../../domain/models/media_server.dart';

/// One tile in the continue-watching row, from either place it can come from.
///
/// Until 2026-09-22 the row was this device's history alone, so something
/// half-watched in the Plex app on the TV never showed up on the phone. Plex's
/// On Deck is the server's answer to the same question, per account, and it
/// also knows the *next* episode of a show in progress, which local history
/// cannot.
class ResumeEntry {
  const ResumeEntry({
    required this.kind,
    required this.sourceId,
    required this.itemId,
    required this.title,
    required this.detail,
    required this.lastActivity,
    this.progress,
    this.posterPath,
    this.signature = '',
    this.episode = false,
    this.sameAs,
  });

  final PlaybackKind kind;
  final String sourceId;
  final String itemId;
  final String title;

  /// "24 min left", or for an episode "S2 E3 · Up next".
  final String detail;

  /// Null for a next-up episode, which has not been started.
  final double? progress;

  /// Unsigned for Plex, as in [HistoryItem.poster]; signed at render (§3).
  final String? posterPath;

  /// Null only for Plex entries Plex gave no date for, which sort last.
  final DateTime? lastActivity;

  /// What a dismissal is tied to (see [ResumeDismissals]).
  final String signature;

  /// Whether this tile belongs above Series rather than Movies.
  final bool episode;

  /// The same thing on another server: the show, season and episode number
  /// for an episode, the title and year for a film. Two connected servers
  /// that both hold a show each put its next episode in On Deck, so the row
  /// showed it twice (seen on a tablet, 2026-10-30); [mergeResume] keeps one.
  /// Null when there is not enough to tell, and for this device's history.
  final String? sameAs;

  ResumeEntry _asEpisode(bool value) => ResumeEntry(
        kind: kind,
        sourceId: sourceId,
        itemId: itemId,
        title: title,
        detail: detail,
        lastActivity: lastActivity,
        progress: progress,
        posterPath: posterPath,
        signature: signature,
        episode: value,
        sameAs: sameAs,
      );

  String get key => '${kind.wire}:$sourceId:$itemId';

  String get route => switch (kind) {
        PlaybackKind.server => '/play/$sourceId/$itemId',
        PlaybackKind.xtreamVod => '/vod/$sourceId/$itemId',
        PlaybackKind.xtreamEpisode => '/episode/$sourceId/$itemId',
      };

  factory ResumeEntry.fromHistory(HistoryItem item) => ResumeEntry(
        kind: item.kind,
        sourceId: item.sourceId,
        itemId: item.itemId,
        title: item.title,
        detail: _minutesLeft(item.duration - item.position),
        progress: item.progress,
        posterPath: item.poster,
        lastActivity: item.lastWatchedAt,
        signature: 'local:${item.position.inSeconds}',
        episode: item.isEpisode,
      );

  /// Null for anything that is not a film or an episode.
  static ResumeEntry? fromServer(String serverId, MediaItem m) {
    final episode = m.type == MediaItemType.episode;
    if (!episode && m.type != MediaItemType.movie) return null;

    final offset = m.viewOffset?.inMilliseconds ?? 0;
    final total = m.duration?.inMilliseconds ?? 0;
    final started = offset > 0 && total > 0;
    final left =
        started ? _minutesLeft(Duration(milliseconds: total - offset)) : null;
    final numbering = [
      if (m.parentIndex != null) 'S${m.parentIndex}',
      if (m.index != null) 'E${m.index}',
    ].join(' ');

    return ResumeEntry(
      kind: PlaybackKind.server,
      sourceId: serverId,
      itemId: m.id,
      // An episode title alone ("Pilot") says little in a row of mixed
      // things; the show's name is what people look for.
      title: episode ? (m.showTitle ?? m.title) : m.title,
      detail: episode
          ? [
              if (numbering.isNotEmpty) numbering,
              left ?? tr.resume.upNext,
            ].join(' · ')
          : (left ?? tr.resume.upNext),
      progress: started ? offset / total : null,
      posterPath: m.posterPath,
      lastActivity: m.lastViewedAt,
      signature: 'plex:$offset:${m.lastViewedAt?.millisecondsSinceEpoch}',
      episode: episode,
      sameAs: episode
          ? (m.showTitle != null && m.parentIndex != null && m.index != null
                ? 'episode|${m.showTitle!.toLowerCase()}|'
                      '${m.parentIndex}|${m.index}'
                : null)
          : 'film|${m.title.toLowerCase()}|${m.year ?? ''}',
    );
  }

  static String _minutesLeft(Duration d) =>
      tr.units.minutesLeft(m: d.inMinutes < 1 ? 1 : d.inMinutes);
}

/// This device's history and Plex's On Deck, as one row.
///
/// The same title can arrive from both. Whichever record is newer wins, and
/// that includes a local record that is *not* resumable: finishing something
/// here must hide Plex's older "half-watched" entry for it, or the row would
/// offer to resume a film that just ended. Plex catches up on its own from the
/// progress we report.
///
/// Newest first. Plex entries with no date (a next-up episode nobody has
/// opened) keep Plex's order at the end.
List<ResumeEntry> mergeResume({
  required List<HistoryItem> history,
  required List<ResumeEntry> plexDeck,
  Map<String, String> dismissed = const {},
}) {
  final localByKey = {for (final h in history) h.key: h};
  final out = <ResumeEntry>[
    for (final h in history)
      if (h.isResumable) ResumeEntry.fromHistory(h),
  ];
  final seen = {for (final e in out) e.key};

  for (final entry in plexDeck) {
    if (seen.contains(entry.key)) {
      final i = out.indexWhere((e) => e.key == entry.key);
      final mine = out[i].lastActivity;
      final theirs = entry.lastActivity;
      if (theirs != null && mine != null && theirs.isAfter(mine)) {
        out[i] = entry;
      } else if (localByKey[entry.key]?.episode == null) {
        // A Plex record from before history knew episodes from films: Plex
        // does know, so the local entry keeps its position and takes the type.
        out[i] = out[i]._asEpisode(entry.episode);
      }
      continue;
    }
    final local = localByKey[entry.key];
    final theirs = entry.lastActivity;
    if (local != null &&
        (theirs == null || !local.lastWatchedAt.isBefore(theirs))) {
      continue; // Finished or abandoned here more recently than Plex knows.
    }
    seen.add(entry.key);
    out.add(entry);
  }

  final visible = [
    for (final e in out)
      if (dismissed[e.key] != e.signature) e,
  ];
  // Stable, so undated entries keep Plex's own order at the end.
  final dated = [for (final e in visible) if (e.lastActivity != null) e]
    ..sort((a, b) => b.lastActivity!.compareTo(a.lastActivity!));
  return onePerTitle([
    ...dated,
    for (final e in visible) if (e.lastActivity == null) e,
  ]);
}

/// [ordered] with only one entry for the same title on different servers
/// (see [ResumeEntry.sameAs]). The first wins, which in the merged order is
/// the most recently active, except that one already started beats one not
/// yet begun: a place to resume is worth more than an offer to start.
List<ResumeEntry> onePerTitle(List<ResumeEntry> ordered) {
  final at = <String, int>{};
  final out = <ResumeEntry>[];
  for (final e in ordered) {
    final same = e.sameAs;
    if (same == null) {
      out.add(e);
      continue;
    }
    final i = at[same];
    if (i == null) {
      at[same] = out.length;
      out.add(e);
    } else if (out[i].progress == null && e.progress != null) {
      out[i] = e;
    }
  }
  return out;
}

/// On Deck across every connected server, from the libraries that feed Movies
/// and Series.
///
/// Refetched when a Plex playback ends (the player invalidates it), not on a
/// timer: the row only needs to be right when someone is looking at Home.
final onDeckProvider = FutureProvider<List<ResumeEntry>>((ref) async {
  final servers = ref.watch(connectedServersProvider);
  final mapping = ref.watch(libraryMappingProvider);

  final perServer = await Future.wait([
    for (final server in servers)
      () async {
        try {
          final sections =
              await ref.watch(serverSectionsProvider(server.id).future);
          final wanted = [
            ...mapping.sectionsFor(LibraryTab.movies, server.id, sections),
            ...mapping.sectionsFor(LibraryTab.series, server.id, sections),
          ];
          final deck = await server.service
              .onDeck(wanted)
              .timeout(const Duration(seconds: 10));
          return [
            for (final m in deck) ?ResumeEntry.fromServer(server.id, m),
          ];
        } catch (_) {
          // A sleeping server costs its own entries, not the row.
          return const <ResumeEntry>[];
        }
      }(),
  ]);
  return perServer.expand((e) => e).toList();
});

/// Tiles the viewer closed, each tied to the state it was closed in.
///
/// Closing a local entry deletes it from history, but a Plex entry would come
/// straight back on the next fetch. So a dismissal remembers the entry's
/// [ResumeEntry.signature] (its position and last-viewed time), and the tile
/// returns only once that changes, i.e. once it is actually watched again.
/// Nothing is sent to Plex: `dart_plex` 0.1.2 has no call for removing an item
/// from On Deck, so the Plex app will still list it.
final resumeDismissalsProvider =
    NotifierProvider<ResumeDismissals, Map<String, String>>(
  ResumeDismissals.new,
);

const _kDismissed = 'resumeDismissed';

class ResumeDismissals extends Notifier<Map<String, String>> {
  AppSettingsStore get _store => ref.read(appSettingsStoreProvider);

  @override
  Map<String, String> build() => _store.getStringMap(_kDismissed);

  Future<void> dismiss(ResumeEntry entry) async {
    if (entry.kind != PlaybackKind.server) {
      await ref.read(historyProvider.notifier).remove(entry.key);
    }
    final next = {...state, entry.key: entry.signature};
    state = next;
    await _store.setStringMap(_kDismissed, next);
  }
}

/// The row's contents, recomputed when either side changes.
final resumeEntriesProvider = Provider<List<ResumeEntry>>((ref) {
  return mergeResume(
    history: ref.watch(historyProvider),
    plexDeck: ref.watch(onDeckProvider).value ?? const [],
    dismissed: ref.watch(resumeDismissalsProvider),
  );
});
