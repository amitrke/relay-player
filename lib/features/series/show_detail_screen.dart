import 'package:dart_plex/dart_plex.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/relay_theme.dart';
import '../accounts/plex_session.dart';
import '../library/poster_grid.dart';

final _showProvider =
    FutureProvider.family<PlexMetadata?, String>((ref, ratingKey) {
  return ref.watch(plexServiceProvider).item(ratingKey);
});

/// Seasons of a show — or, for a flat show, its episodes directly.
final _seasonsProvider =
    FutureProvider.family<List<PlexMetadata>, String>((ref, ratingKey) {
  return ref.watch(plexServiceProvider).children(ratingKey);
});

final _episodesProvider =
    FutureProvider.family<List<PlexMetadata>, String>((ref, seasonRatingKey) {
  return ref.watch(plexServiceProvider).children(seasonRatingKey);
});

/// §12 screen 5 for a series: poster, plot, seasons and episodes.
class ShowDetailScreen extends ConsumerStatefulWidget {
  const ShowDetailScreen({super.key, required this.ratingKey});

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
    final show = ref.watch(_showProvider(widget.ratingKey));
    final children = ref.watch(_seasonsProvider(widget.ratingKey));

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
          onRetry: () => ref.invalidate(_seasonsProvider(widget.ratingKey)),
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
                _ShowHeader(show: show.value),
                const SizedBox(height: 18),
                for (final episode in list) _EpisodeRow(episode: episode),
              ],
            );
          }

          final selected = list.any((s) => s.ratingKey == _selectedSeason)
              ? _selectedSeason!
              : list.first.ratingKey;

          return ListView(
            padding: RelayLayout.pagePadding(f).copyWith(bottom: 32),
            children: [
              _ShowHeader(show: show.value),
              const SizedBox(height: 18),
              _SeasonChips(
                seasons: list,
                selected: selected,
                onSelect: (id) => setState(() => _selectedSeason = id),
              ),
              const SizedBox(height: 14),
              _EpisodeList(seasonRatingKey: selected),
            ],
          );
        },
      ),
    );
  }
}

class _ShowHeader extends ConsumerWidget {
  const _ShowHeader({required this.show});

  final PlexMetadata? show;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = RelayTheme.of(context);
    final item = show;
    if (item == null) return const SizedBox.shrink();
    final poster = ref.read(plexServiceProvider).posterUrl(item);

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
          GestureDetector(
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
  const _EpisodeList({required this.seasonRatingKey});

  final String seasonRatingKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = RelayTheme.of(context);
    final episodes = ref.watch(_episodesProvider(seasonRatingKey));

    return episodes.when(
      loading: () => Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator(color: t.accent)),
      ),
      error: (e, _) => LibraryEmptyState(
        icon: Icons.cloud_off_outlined,
        message: '$e',
        onRetry: () => ref.invalidate(_episodesProvider(seasonRatingKey)),
      ),
      data: (list) => Column(
        children: [for (final episode in list) _EpisodeRow(episode: episode)],
      ),
    );
  }
}

class _EpisodeRow extends StatelessWidget {
  const _EpisodeRow({required this.episode});

  final PlexMetadata episode;

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);
    final minutes = (episode.durationMs ?? 0) ~/ 60000;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: t.surface,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => context.push('/play/${episode.ratingKey}'),
          child: Padding(
            padding: const EdgeInsets.all(14),
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
                      if (minutes > 0) ...[
                        const SizedBox(height: 2),
                        Text(
                          '$minutes min',
                          style: TextStyle(color: t.inkDim, fontSize: 12),
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
                Icon(Icons.play_arrow, color: t.inkDim),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
