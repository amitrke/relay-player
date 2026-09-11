import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/relay_theme.dart';
import '../../data/xtream/xtream_client.dart';
import '../library/poster_grid.dart';
import 'xtream_controller.dart';

/// Seasons and episodes of a panel series (§12 screen 5).
class XtreamSeriesScreen extends ConsumerStatefulWidget {
  const XtreamSeriesScreen({
    super.key,
    required this.accountId,
    required this.seriesId,
  });

  final String accountId;
  final String seriesId;

  @override
  ConsumerState<XtreamSeriesScreen> createState() =>
      _XtreamSeriesScreenState();
}

class _XtreamSeriesScreenState extends ConsumerState<XtreamSeriesScreen> {
  int? _season;

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);
    final f = RelayLayout.of(context);

    final account = ref
        .watch(xtreamAccountsProvider)
        .where((a) => a.id == widget.accountId)
        .firstOrNull;

    if (account == null) {
      return Scaffold(
        backgroundColor: t.bg,
        appBar: AppBar(backgroundColor: t.bg, foregroundColor: t.ink),
        body: const Center(child: Text('That line is no longer configured.')),
      );
    }

    final seasons =
        ref.watch(xtreamSeriesInfoProvider((account, widget.seriesId)));

    return Scaffold(
      backgroundColor: t.bg,
      appBar: AppBar(
        backgroundColor: t.bg,
        surfaceTintColor: Colors.transparent,
        foregroundColor: t.ink,
        title: const Text('Series'),
      ),
      body: seasons.when(
        loading: () => Center(child: CircularProgressIndicator(color: t.accent)),
        error: (e, _) => LibraryEmptyState(
          icon: Icons.cloud_off_outlined,
          message: '$e',
          onRetry: () => ref.invalidate(
            xtreamSeriesInfoProvider((account, widget.seriesId)),
          ),
        ),
        data: (list) {
          if (list.isEmpty) {
            return const LibraryEmptyState(
              icon: Icons.tv_outlined,
              message: 'The panel returned no episodes for this series.',
            );
          }

          final selected =
              list.any((s) => s.number == _season) ? _season! : list.first.number;
          final episodes = list
              .firstWhere((s) => s.number == selected)
              .episodes;

          return ListView(
            padding: RelayLayout.pagePadding(f).copyWith(top: 12, bottom: 28),
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final season in list)
                    GestureDetector(
                      onTap: () => setState(() => _season = season.number),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: season.number == selected
                              ? t.accent
                              : t.surface,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: season.number == selected
                                ? t.accent
                                : t.line,
                          ),
                        ),
                        child: Text(
                          'Season ${season.number}',
                          style: TextStyle(
                            color: season.number == selected
                                ? t.accentInk
                                : t.inkDim,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              for (final episode in episodes)
                _EpisodeRow(accountId: account.id, episode: episode),
            ],
          );
        },
      ),
    );
  }
}

class _EpisodeRow extends StatelessWidget {
  const _EpisodeRow({required this.accountId, required this.episode});

  final String accountId;
  final XtreamEpisode episode;

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: t.surface,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          // A series episode streams from its own §4 path, but the player's VOD
          // route builds `/movie/...`. Episodes therefore get their own route
          // rather than being squeezed through the film one.
          onTap: () => context.push(
            '/episode/$accountId/${episode.id}.${episode.containerExtension}',
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                SizedBox(
                  width: 34,
                  child: Text(
                    episode.episodeNumber?.toString() ?? '—',
                    style: TextStyle(
                      color: t.inkDim,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    episode.title,
                    style: TextStyle(
                      color: t.ink,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(Icons.play_arrow, color: t.inkDim),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
