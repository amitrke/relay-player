import 'package:dart_plex/dart_plex.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/relay_theme.dart';
import '../../core/theme/relay_widgets.dart';
import '../../data/plex/plex_service.dart';
import '../accounts/plex_session.dart';
import '../../data/local/history_store.dart';
import '../favorites_history/history_controller.dart';
import '../favorites_history/watch_state.dart';
import '../library/poster_grid.dart';
import '../library/poster_tile.dart';

/// (serverId, ratingKey). A ratingKey alone is ambiguous once more than one
/// server is connected.
typedef _Ref = (String, String);

PlexService _serviceOf(Ref ref, String serverId) {
  for (final server in ref.watch(connectedServersProvider)) {
    if (server.id == serverId) return server.service;
  }
  throw StateError('No connected Plex server with id "$serverId".');
}

final _showProvider = FutureProvider.family<PlexMetadata?, _Ref>((ref, arg) {
  return _serviceOf(ref, arg.$1).item(arg.$2);
});

/// Seasons of a show — or, for a flat show, its episodes directly.
final _seasonsProvider =
    FutureProvider.family<List<PlexMetadata>, _Ref>((ref, arg) {
  return _serviceOf(ref, arg.$1).children(arg.$2);
});

final _episodesProvider =
    FutureProvider.family<List<PlexMetadata>, _Ref>((ref, arg) {
  return _serviceOf(ref, arg.$1).children(arg.$2);
});

/// §12 screen 5 for a series: poster, plot, seasons and episodes.
class ShowDetailScreen extends ConsumerStatefulWidget {
  const ShowDetailScreen({
    super.key,
    required this.serverId,
    required this.ratingKey,
  });

  final String serverId;
  final String ratingKey;

  @override
  ConsumerState<ShowDetailScreen> createState() => _ShowDetailScreenState();
}

class _ShowDetailScreenState extends ConsumerState<ShowDetailScreen> {
  String? _selectedSeason;

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);
    final f = RelayLayout.of(context);
    final show = ref.watch(_showProvider((widget.serverId, widget.ratingKey)));
    final children = ref.watch(_seasonsProvider((widget.serverId, widget.ratingKey)));

    return Scaffold(
      backgroundColor: t.bg,
      appBar: AppBar(
        backgroundColor: t.bg,
        surfaceTintColor: Colors.transparent,
        foregroundColor: t.ink,
        title: Text(show.value?.title ?? ''),
      ),
      body: children.when(
        loading: () => Center(child: CircularProgressIndicator(color: t.accent)),
        error: (e, _) => LibraryEmptyState(
          icon: Icons.cloud_off_outlined,
          message: '$e',
          onRetry: () => ref.invalidate(_seasonsProvider((widget.serverId, widget.ratingKey))),
        ),
        data: (list) {
          if (list.isEmpty) {
            return const LibraryEmptyState(
              icon: Icons.tv_outlined,
              message: 'This show has no episodes on the server.',
            );
          }

          // Plex usually nests show -> season -> episode, but a show with no
          // season folders returns episodes straight away. Treat both, rather
          // than assuming the nesting and rendering an empty season list.
          final isFlat = list.first.type == PlexMetadataType.episode;
          if (isFlat) {
            return ListView(
              padding: RelayLayout.pagePadding(f).copyWith(bottom: 32),
              children: [
                _ShowHeader(show: show.value, serverId: widget.serverId),
                const SizedBox(height: 18),
                for (final episode in list)
                  _EpisodeRow(serverId: widget.serverId, episode: episode),
              ],
            );
          }

          final selected = list.any((s) => s.ratingKey == _selectedSeason)
              ? _selectedSeason!
              : list.first.ratingKey;

          return ListView(
            padding: RelayLayout.pagePadding(f).copyWith(bottom: 32),
            children: [
              _ShowHeader(show: show.value, serverId: widget.serverId),
              const SizedBox(height: 18),
              _SeasonChips(
                seasons: list,
                selected: selected,
                onSelect: (id) => setState(() => _selectedSeason = id),
              ),
              const SizedBox(height: 14),
              _EpisodeList(serverId: widget.serverId, seasonRatingKey: selected),
            ],
          );
        },
      ),
    );
  }
}

class _ShowHeader extends ConsumerWidget {
  const _ShowHeader({required this.show, required this.serverId});

  final PlexMetadata? show;
  final String serverId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = RelayTheme.of(context);
    final item = show;
    if (item == null) return const SizedBox.shrink();
    final poster = plexServiceFor(ref, serverId).posterUrl(item);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 120,
            height: 180,
            child: poster == null
                ? Container(
                    color: t.surface,
                    child: Icon(Icons.tv_outlined, color: t.inkDim),
                  )
                : Image.network(poster, fit: BoxFit.cover),
          ),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                style: TextStyle(
                  color: t.ink,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                [
                  if (item.year != null) '${item.year}',
                  ...item.genres.take(3),
                ].join(' · '),
                style: TextStyle(color: t.inkDim, fontSize: 13),
              ),
              if ((item.summary ?? '').isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  item.summary!,
                  style: TextStyle(color: t.inkDim, fontSize: 13, height: 1.55),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SeasonChips extends StatelessWidget {
  const _SeasonChips({
    required this.seasons,
    required this.selected,
    required this.onSelect,
  });

  final List<PlexMetadata> seasons;
  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final season in seasons)
          RelayTappable(
            borderRadius: 999,
            onTap: () => onSelect(season.ratingKey),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: season.ratingKey == selected ? t.accent : t.surface,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: season.ratingKey == selected ? t.accent : t.line,
                ),
              ),
              child: Text(
                season.title,
                style: TextStyle(
                  color: season.ratingKey == selected ? t.accentInk : t.inkDim,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _EpisodeList extends ConsumerWidget {
  const _EpisodeList({required this.serverId, required this.seasonRatingKey});

  final String serverId;
  final String seasonRatingKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = RelayTheme.of(context);
    final episodes = ref.watch(_episodesProvider((serverId, seasonRatingKey)));

    return episodes.when(
      loading: () => Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator(color: t.accent)),
      ),
      error: (e, _) => LibraryEmptyState(
        icon: Icons.cloud_off_outlined,
        message: '$e',
        onRetry: () => ref.invalidate(_episodesProvider((serverId, seasonRatingKey))),
      ),
      data: (list) => Column(
        children: [for (final episode in list) _EpisodeRow(serverId: serverId, episode: episode)],
      ),
    );
  }
}

class _EpisodeRow extends ConsumerWidget {
  const _EpisodeRow({required this.serverId, required this.episode});

  final String serverId;
  final PlexMetadata episode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = RelayTheme.of(context);
    final total = episode.durationMs == null
        ? null
        : Duration(milliseconds: episode.durationMs!);
    final key = '${PlaybackKind.plex.wire}:$serverId:${episode.ratingKey}';
    final watch = WatchState.resolve(
      // Only this row's entry, so playback elsewhere does not rebuild the list.
      local: ref.watch(historyProvider
          .select((all) => all.where((h) => h.key == key).firstOrNull)),
      plexViewCount: episode.viewCount,
      plexOffset: episode.viewOffsetMs == null
          ? null
          : Duration(milliseconds: episode.viewOffsetMs!),
      plexDuration: total,
      plexLastViewedAt: episode.lastViewedAt,
    );
    final minutes = (total?.inMinutes ?? 0);
    final meta = switch (watch.progress) {
      final p? when minutes > 0 => '${(minutes * (1 - p)).ceil()} min left',
      _ when minutes > 0 => '$minutes min',
      _ => null,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      // RelaySurface rather than a Material InkWell: the InkWell's focus state
      // is Material's tint, which MANUAL_TESTING §6 found invisible on a TV.
      child: RelaySurface(
        padding: const EdgeInsets.all(14),
        onTap: () => context.push('/play/$serverId/${episode.ratingKey}'),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 34,
              child: Text(
                episode.index == null ? '—' : '${episode.index}',
                style: TextStyle(
                  color: t.inkDim,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    episode.title,
                    style: TextStyle(
                      color: t.ink,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (meta != null) ...[
                    const SizedBox(height: 2),
                    Text(meta, style: TextStyle(color: t.inkDim, fontSize: 12)),
                  ],
                  if (watch.progress case final progress?) ...[
                    const SizedBox(height: 6),
                    SizedBox(
                      width: 160,
                      child: WatchProgressBar(progress: progress),
                    ),
                  ],
                  if ((episode.summary ?? '').isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      episode.summary!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: t.inkDim,
                        fontSize: 12.5,
                        height: 1.45,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            if (watch.watched)
              const WatchedTick()
            else
              Icon(Icons.play_arrow, color: t.inkDim),
          ],
        ),
      ),
    );
  }
}
