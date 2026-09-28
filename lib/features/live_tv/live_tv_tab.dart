import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/relay_theme.dart';
import '../../core/theme/relay_widgets.dart';
import '../../data/local/favorites_store.dart';
import '../../data/xtream/xtream_account_store.dart';
import '../../data/xtream/xtream_client.dart';
import '../advanced_sources/xtream_controller.dart';
import '../favorites_history/favorites_controller.dart';
import '../library/poster_grid.dart';
import 'channel_groups.dart';

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

/// The chosen channels, grouped under their categories (see [groupChannels]).
///
/// Two layouts over the same groups. Phone and tablet get a row of chips under
/// the search box; a TV gets the categories as a column on the left and the
/// channels on the right. "All" is the flat list the tab showed before
/// 2026-09-28, so grouping needs no setting to turn off.
class _ChannelList extends ConsumerStatefulWidget {
  const _ChannelList({required this.account});

  final XtreamAccount account;

  @override
  ConsumerState<_ChannelList> createState() => _ChannelListState();
}

class _ChannelListState extends ConsumerState<_ChannelList> {
  final _search = TextEditingController();
  String _query = '';

  /// The chosen group: a category id, [favouritesGroupId], or null for All.
  String? _groupId;

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

        final favorites = ref.watch(favoritesProvider);
        FavoriteItem keyOf(XtreamChannel c) => FavoriteItem(
              kind: FavoriteKind.channel,
              sourceId: account.id,
              itemId: c.streamId,
            );
        final groups = groupChannels(
          channels: list,
          categoryOrder: account.liveCategoryIds,
          names: _categoryNames(account),
          isFavourite: (c) => favorites.contains(keyOf(c).key),
        );

        // Filtered in memory, not over the wire. The channels for the chosen
        // categories are already here, and the Xtream API has no channel-search
        // endpoint — asking the panel again would be slower and no better.
        //
        // A search covers every group, whichever is selected, and the
        // selection reads as All while it runs. Searching inside one category
        // would make a channel that is simply elsewhere look missing.
        final query = _query.trim().toLowerCase();
        final searching = query.isNotEmpty;
        // A selected group can vanish under the viewer: unstarring the last
        // favourite removes Favourites. Falling back to All beats an empty list.
        final selected = searching
            ? null
            : groups.where((g) => g.id == _groupId).firstOrNull;
        final shown = searching
            ? favouritesFirst(
                [
                  for (final c in list)
                    if (c.name.toLowerCase().contains(query)) c,
                ],
                favorites,
                keyOf,
              )
            : selected?.channels ?? favouritesFirst(list, favorites, keyOf);

        final tv = f == RelayFormFactor.tv;
        void select(String? id) => setState(() => _groupId = id);

        final padding = RelayLayout.pagePadding(f);
        final Widget channelPane = shown.isEmpty
            ? LibraryEmptyState(
                icon: Icons.search_off,
                message: 'No channel matching "$_query".',
              )
            : ListView.builder(
                // Keyed by the selection so a new group starts at its top
                // rather than at the previous group's scroll offset.
                key: ValueKey('channels:${selected?.id}:$searching'),
                padding: (tv ? EdgeInsets.only(right: padding.right) : padding)
                    .copyWith(top: 8, bottom: 28),
                itemCount: shown.length,
                itemBuilder: (context, i) =>
                    _ChannelRow(account: account, channel: shown[i]),
              );

        return Column(
          children: [
            Padding(
              padding: padding.copyWith(top: 10, bottom: 4),
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
            if (tv)
              // Categories down the left, channels on the right: the usual
              // shape for a channel list on a TV, and the one that lets a remote
              // jump between groups rather than scroll through every channel.
              // No RelayFocusBoundary is needed between the two panes, because
              // they share one route scope and directional traversal crosses
              // between siblings by position. Left from the category column
              // still reaches the rail through the shell's own boundary.
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 260,
                      child: ListView(
                        padding: EdgeInsets.only(
                          left: padding.left,
                          right: 16,
                          top: 8,
                          bottom: 28,
                        ),
                        children: [
                          _GroupRow(
                            label: 'All',
                            count: list.length,
                            selected: selected == null,
                            onTap: () => select(null),
                          ),
                          for (final g in groups)
                            _GroupRow(
                              label: g.name,
                              count: g.channels.length,
                              selected: selected?.id == g.id,
                              onTap: () => select(g.id),
                            ),
                        ],
                      ),
                    ),
                    Expanded(child: channelPane),
                  ],
                ),
              )
            else ...[
              SizedBox(
                height: 46,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: padding.copyWith(top: 6, bottom: 4),
                  children: [
                    _GroupChip(
                      label: 'All',
                      selected: selected == null,
                      onTap: () => select(null),
                    ),
                    for (final g in groups)
                      _GroupChip(
                        label: g.name,
                        selected: selected?.id == g.id,
                        onTap: () => select(g.id),
                      ),
                  ],
                ),
              ),
              Expanded(child: channelPane),
            ],
          ],
        );
      },
    );
  }

  /// Names for the chosen categories: saved ones, else fetched once.
  ///
  /// A line saved before 2026-09-28 has ids and no names, because the picker
  /// did not keep them. Rather than label its groups "Category 3" until the
  /// viewer happens to reopen the picker, this asks the panel for its category
  /// list, a small call (Phase 0: 466 live categories in under a second). It
  /// is watched only while a name is missing, so a line saved since then never
  /// makes the call. Not written back to the account: the picker does that on
  /// its next save, and a tab quietly rewriting stored settings as a side
  /// effect of being looked at would be a surprise.
  Map<String, String> _categoryNames(XtreamAccount account) {
    final saved = account.liveCategoryNames;
    if (account.liveCategoryIds.every(saved.containsKey)) return saved;
    final fetched = ref
        .watch(xtreamCategoriesProvider((account, XtreamCatalogue.live)))
        .value;
    if (fetched == null) return saved;
    return {for (final c in fetched) c.id: c.name, ...saved};
  }
}

/// One channel, reachable and visibly focused on a remote.
///
/// Was a Material `InkWell` until 2026-09-28. That takes D-pad focus but draws
/// nothing for it, because the theme sets no `focusColor` (§11), and the TV
/// layout above makes this list something a remote is expected to walk.
class _ChannelRow extends StatelessWidget {
  const _ChannelRow({required this.account, required this.channel});

  final XtreamAccount account;
  final XtreamChannel channel;

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);
    Widget placeholder() => Container(
          color: t.bg,
          child: Icon(Icons.tv, color: t.inkDim, size: 18),
        );

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RelayTappable(
        borderRadius: 10,
        onTap: () => context.push('/live/${account.id}/${channel.streamId}'),
        child: Ink(
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  width: 48,
                  height: 36,
                  child: channel.logoUrl == null
                      ? placeholder()
                      : Image.network(
                          channel.logoUrl!,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => placeholder(),
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
    );
  }
}

/// A group in the phone and tablet chip row.
class _GroupChip extends StatelessWidget {
  const _GroupChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: RelayTappable(
        borderRadius: 18,
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: selected ? t.accent : t.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: selected ? t.accent : t.line),
          ),
          child: Center(
            widthFactor: 1,
            child: Text(
              label,
              style: TextStyle(
                color: selected ? t.accentInk : t.ink,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A group in the TV layout's left column, with its channel count.
class _GroupRow extends StatelessWidget {
  const _GroupRow({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RelayTappable(
        borderRadius: 10,
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? t.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected ? t.accent : t.ink,
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$count',
                style: TextStyle(color: t.inkDim, fontSize: 12.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
