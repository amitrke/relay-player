import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/relay_theme.dart';
import '../../core/theme/relay_widgets.dart';
import '../../data/xtream/xtream_account_store.dart';
import '../advanced_sources/xtream_controller.dart';
import '../library/poster_grid.dart';

/// The Live TV tab (§12 screen 3), reachable only behind the §8.2 gate.
class LiveTvTab extends ConsumerWidget {
  const LiveTvTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = RelayTheme.of(context);
    final accounts = ref.watch(xtreamAccountsProvider);

    if (accounts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.live_tv_outlined, color: t.inkDim, size: 34),
              const SizedBox(height: 14),
              Text(
                'No playlist or panel configured.',
                textAlign: TextAlign.center,
                style: TextStyle(color: t.inkDim, height: 1.5),
              ),
              const SizedBox(height: 18),
              RelayButton(
                label: 'Add one',
                onPressed: () => context.push('/advanced/xtream/new'),
              ),
            ],
          ),
        ),
      );
    }

    // One line for now. Multiple lines get a selector here, the same shape the
    // Sources screen already uses for Plex servers.
    return _ChannelList(account: accounts.first);
  }
}

class _ChannelList extends ConsumerWidget {
  const _ChannelList({required this.account});

  final XtreamAccount account;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = RelayTheme.of(context);
    final f = RelayLayout.of(context);

    if (account.selectedCategoryIds.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.filter_list, color: t.inkDim, size: 34),
              const SizedBox(height: 14),
              Text(
                'No categories chosen yet.\nPanels carry tens of thousands of '
                'channels, so Relay Player only fetches the ones you pick.',
                textAlign: TextAlign.center,
                style: TextStyle(color: t.inkDim, height: 1.5),
              ),
              const SizedBox(height: 18),
              RelayButton(
                label: 'Choose categories',
                onPressed: () => context
                    .push('/advanced/xtream/${account.id}/categories'),
              ),
            ],
          ),
        ),
      );
    }

    final channels = ref.watch(xtreamChannelsProvider(account));

    return channels.when(
      loading: () => Center(child: CircularProgressIndicator(color: t.accent)),
      error: (e, _) => LibraryEmptyState(
        icon: Icons.cloud_off_outlined,
        message: '$e',
        onRetry: () => ref.invalidate(xtreamChannelsProvider(account)),
      ),
      data: (list) {
        if (list.isEmpty) {
          return const LibraryEmptyState(
            icon: Icons.live_tv_outlined,
            message: 'Those categories returned no channels.',
          );
        }
        return ListView.builder(
          padding: RelayLayout.pagePadding(f).copyWith(top: 12, bottom: 28),
          itemCount: list.length,
          itemBuilder: (context, i) {
            final channel = list[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: t.surface,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => context.push(
                    '/live/${account.id}/${channel.streamId}',
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: SizedBox(
                            width: 48,
                            height: 36,
                            child: channel.logoUrl == null
                                ? Container(
                                    color: t.bg,
                                    child: Icon(Icons.tv,
                                        color: t.inkDim, size: 18),
                                  )
                                : Image.network(
                                    channel.logoUrl!,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, _, _) => Container(
                                      color: t.bg,
                                      child: Icon(Icons.tv,
                                          color: t.inkDim, size: 18),
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            channel.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
          },
        );
      },
    );
  }
}
