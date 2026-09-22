import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/relay_theme.dart';
import '../../core/theme/relay_widgets.dart';
import '../../data/local/favorites_store.dart';
import '../../data/xtream/xtream_account_store.dart';
import '../advanced_sources/xtream_controller.dart';
import '../favorites_history/favorites_controller.dart';
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

class _ChannelList extends ConsumerStatefulWidget {
  const _ChannelList({required this.account});

  final XtreamAccount account;

  @override
  ConsumerState<_ChannelList> createState() => _ChannelListState();
}

class _ChannelListState extends ConsumerState<_ChannelList> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);
    final f = RelayLayout.of(context);
    final account = widget.account;

    if (account.liveCategoryIds.isEmpty) {
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
                'channels, so Subnext Player only fetches the ones you pick.',
                textAlign: TextAlign.center,
                style: TextStyle(color: t.inkDim, height: 1.5),
              ),
              const SizedBox(height: 18),
              RelayButton(
                label: 'Choose categories',
                onPressed: () => context.push(
                    '/advanced/xtream/${account.id}/categories/live'),
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
        // Filtered in memory, not over the wire. The channels for the chosen
        // categories are already here, and the Xtream API has no channel-search
        // endpoint — asking the panel again would be slower and no better.
        final query = _query.trim().toLowerCase();
        final matching = query.isEmpty
            ? list
            : [
                for (final c in list)
                  if (c.name.toLowerCase().contains(query)) c,
              ];

        final favorites = ref.watch(favoritesProvider);
        final ordered = favouritesFirst(
          matching,
          favorites,
          (c) => FavoriteItem(
            kind: FavoriteKind.channel,
            sourceId: account.id,
            itemId: c.streamId,
          ),
        );

        return Column(
          children: [
            Padding(
              padding: RelayLayout.pagePadding(f).copyWith(top: 10, bottom: 4),
              child: TextField(
                controller: _search,
                onChanged: (v) => setState(() => _query = v),
                autocorrect: false,
                style: TextStyle(color: t.ink),
                decoration: InputDecoration(
                  hintText: 'Search ${list.length} channels',
                  hintStyle: TextStyle(color: t.inkDim),
                  prefixIcon: Icon(Icons.search, color: t.inkDim, size: 19),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          icon: Icon(Icons.close, color: t.inkDim, size: 18),
                          onPressed: () {
                            _search.clear();
                            setState(() => _query = '');
                          },
                        ),
                  filled: true,
                  fillColor: t.surface,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: t.line),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: t.line),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: t.accent),
                  ),
                ),
              ),
            ),
            if (ordered.isEmpty)
              Expanded(
                child: LibraryEmptyState(
                  icon: Icons.search_off,
                  message: 'No channel matching "$_query".',
                ),
              )
            else
              Expanded(
                child: ListView.builder(
          padding: RelayLayout.pagePadding(f).copyWith(top: 8, bottom: 28),
          itemCount: ordered.length,
          itemBuilder: (context, i) {
            final channel = ordered[i];
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
                        FavoriteButton(
                          dense: true,
                          item: FavoriteItem(
                            kind: FavoriteKind.channel,
                            sourceId: account.id,
                            itemId: channel.streamId,
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
                ),
              ),
          ],
        );
      },
    );
  }
}
