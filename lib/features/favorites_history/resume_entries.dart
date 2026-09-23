import 'dart:async';

import 'package:dart_plex/dart_plex.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/app_settings_store.dart';
import '../../data/local/history_store.dart';
import '../accounts/plex_session.dart';
import '../library/library_screen.dart' show plexSectionsProvider;
import '../library/library_tab.dart';
import '../settings/settings_controller.dart';
import 'history_controller.dart';

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

  String get key => '${kind.wire}:$sourceId:$itemId';

  String get route => switch (kind) {
        PlaybackKind.plex => '/play/$sourceId/$itemId',
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
      );

  /// Null for anything that is not a film or an episode.
  static ResumeEntry? fromPlex(String serverId, PlexMetadata m) {
    final episode = m.type == PlexMetadataType.episode;
    if (!episode && m.type != PlexMetadataType.movie) return null;

    final offset = m.viewOffsetMs ?? 0;
    final total = m.durationMs ?? 0;
    final started = offset > 0 && total > 0;
    final left =
        started ? _minutesLeft(Duration(milliseconds: total - offset)) : null;
    final numbering = [
      if (m.parentIndex != null) 'S${m.parentIndex}',
      if (m.index != null) 'E${m.index}',
    ].join(' ');

    return ResumeEntry(
      kind: PlaybackKind.plex,
      sourceId: serverId,
      itemId: m.ratingKey,
      // An episode title alone ("Pilot") says little in a row of mixed
      // things; the show's name is what people look for.
      title: episode ? (m.grandparentTitle ?? m.title) : m.title,
      detail: episode
          ? [if (numbering.isNotEmpty) numbering, left ?? 'Up next'].join(' · ')
          : (left ?? 'Up next'),
      progress: started ? offset / total : null,
      posterPath: m.thumb,
      lastActivity: m.lastViewedAt,
      signature: 'plex:$offset:${m.lastViewedAt?.millisecondsSinceEpoch}',
    );
  }

  static String _minutesLeft(Duration d) =>
      '${d.inMinutes < 1 ? 1 : d.inMinutes} min left';
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
  return [...dated, for (final e in visible) if (e.lastActivity == null) e];
}

/// On Deck across every connected server, from the libraries that feed Movies
/// and Series.
///
/// Refetched when a Plex playback ends (the player invalidates it), not on a
/// timer: the row only needs to be right when someone is looking at Home.
final plexOnDeckProvider = FutureProvider<List<ResumeEntry>>((ref) async {
  final servers = ref.watch(connectedServersProvider);
  final mapping = ref.watch(libraryMappingProvider);

  final perServer = await Future.wait([
    for (final server in servers)
      () async {
        try {
          final sections =
              await ref.watch(plexSectionsProvider(server.id).future);
          final wanted = [
            ...mapping.sectionsFor(LibraryTab.movies, server.id, sections),
            ...mapping.sectionsFor(LibraryTab.series, server.id, sections),
          ];
          final deck = await server.service
              .onDeck(wanted)
              .timeout(const Duration(seconds: 10));
          return [
            for (final m in deck) ?ResumeEntry.fromPlex(server.id, m),
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
    if (entry.kind != PlaybackKind.plex) {
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
    plexDeck: ref.watch(plexOnDeckProvider).value ?? const [],
    dismissed: ref.watch(resumeDismissalsProvider),
  );
});
