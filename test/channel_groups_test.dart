import 'package:flutter_test/flutter_test.dart';
import 'package:relay_player/data/xtream/xtream_account_store.dart';
import 'package:relay_player/data/xtream/xtream_client.dart';
import 'package:relay_player/features/live_tv/channel_groups.dart';

/// Placeholder category and channel names throughout: real panels' labels
/// are provider and brand names, which stay out of the repo (CLAUDE.md §1).
XtreamChannel _ch(String id, String category) => XtreamChannel(
      streamId: id,
      name: 'Channel $id',
      categoryId: category,
    );

void main() {
  group('groupChannels', () {
    List<ChannelGroup> group(
      List<XtreamChannel> channels, {
      List<String> order = const ['10', '20'],
      Map<String, String> names = const {'10': 'News', '20': 'Sport'},
      Set<String> favourites = const {},
    }) =>
        groupChannels(
          channels: channels,
          categoryOrder: order,
          names: names,
          isFavourite: (c) => favourites.contains(c.streamId),
        );

    test('groups in the chosen order, channels in the order they came', () {
      final groups = group(
        [_ch('3', '20'), _ch('1', '10'), _ch('4', '20'), _ch('2', '10')],
      );
      expect(groups.map((g) => g.name), ['News', 'Sport']);
      expect(groups[0].channels.map((c) => c.streamId), ['1', '2']);
      expect(groups[1].channels.map((c) => c.streamId), ['3', '4']);
    });

    test('favourites lead, and stay in their category too', () {
      final groups = group(
        [_ch('1', '10'), _ch('2', '10'), _ch('3', '20')],
        favourites: {'3'},
      );
      expect(groups.map((g) => g.id), [favouritesGroupId, '10', '20']);
      expect(groups.first.channels.single.streamId, '3');
      expect(groups.last.channels.single.streamId, '3');
    });

    test('no favourites, no Favourites heading', () {
      expect(group([_ch('1', '10')]).map((g) => g.id), ['10']);
    });

    test('a chosen category with no channels gets no heading', () {
      expect(group([_ch('1', '20')]).map((g) => g.id), ['20']);
    });

    test('a missing name reads as its position, not its id', () {
      final groups = group(
        [_ch('1', '10'), _ch('2', '20')],
        names: const {'10': 'News'},
      );
      expect(groups.map((g) => g.name), ['News', 'Category 2']);
    });

    test('a channel filed under an unchosen category is kept, under Other',
        () {
      final groups = group([_ch('1', '10'), _ch('2', '99')]);
      expect(groups.map((g) => g.name), ['News', 'Other']);
      expect(groups.last.channels.single.streamId, '2');
    });
  });

  group('category names on the account', () {
    const account = XtreamAccount(
      id: 'a',
      name: 'Line',
      host: 'http://panel-host.example.invalid',
      username: 'user',
    );

    test('survive storage', () {
      final saved = account.withCategories(
        XtreamCatalogue.live,
        ['10', '20'],
        names: {'10': 'News', '20': 'Sport', '30': 'Not chosen'},
      );
      final stored = XtreamAccount.fromJson(saved.toJson())!;
      expect(stored.liveCategoryIds, ['10', '20']);
      expect(stored.liveCategoryNames, {'10': 'News', '20': 'Sport'},
          reason: 'names are kept for chosen categories only');
    });

    test('a deselected category drops its name; a kept one keeps it', () {
      final first = account.withCategories(
        XtreamCatalogue.live,
        ['10', '20'],
        names: {'10': 'News', '20': 'Sport'},
      );
      // Saved without names, as when the category list failed to load.
      final second = first.withCategories(XtreamCatalogue.live, ['20']);
      expect(second.liveCategoryNames, {'20': 'Sport'});
    });

    test('a line saved before names existed loads with none', () {
      final json = account.withCategories(XtreamCatalogue.live, ['10']).toJson()
        ..remove('liveNames');
      final stored = XtreamAccount.fromJson(json)!;
      expect(stored.liveCategoryIds, ['10']);
      expect(stored.liveCategoryNames, isEmpty);
    });

    test('saving Movies or Series leaves the live names alone', () {
      final live = account.withCategories(XtreamCatalogue.live, ['10'],
          names: {'10': 'News'});
      final both = live.withCategories(XtreamCatalogue.vod, ['5'],
          names: {'5': 'Films'});
      expect(both.liveCategoryNames, {'10': 'News'});
    });
  });
}
