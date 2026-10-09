import 'package:flutter_test/flutter_test.dart';
import 'package:relay_player/data/xtream/category_groups.dart';
import 'package:relay_player/data/xtream/xtream_account_store.dart';
import 'package:relay_player/data/xtream/xtream_client.dart';
import 'package:relay_player/features/advanced_sources/xtream_controller.dart';

XtreamAccount _account({
  List<String> live = const ['10', '20'],
  Map<String, List<String>> picks = const {},
}) => XtreamAccount(
  id: 'a',
  name: 'Line',
  host: 'http://panel.example:8080',
  username: 'u',
  liveCategoryIds: live,
  liveChannelPicks: picks,
);

XtreamChannel _ch(String id, String name) =>
    XtreamChannel(streamId: id, name: name, categoryId: '10');

void main() {
  group('channel picks in the stored account', () {
    test('survive storage', () {
      final a = _account(
        picks: {
          '10': ['1', '2'],
        },
      );
      final back = XtreamAccount.fromJson(a.toJson())!;
      expect(back.liveChannelPicks, {
        '10': ['1', '2'],
      });
    });

    test(
      'an account saved before picks existed reads as keeping everything',
      () {
        final json = _account().toJson()..remove('livePicks');
        expect(XtreamAccount.fromJson(json)!.liveChannelPicks, isEmpty);
        // And none is written when there is nothing to say.
        expect(_account().toJson().containsKey('livePicks'), isFalse);
      },
    );

    test('are dropped with the category they narrow', () {
      final a = _account(
        picks: {
          '10': ['1'],
          '20': ['2'],
        },
      );
      final kept = a.withCategories(XtreamCatalogue.live, ['10']);
      expect(kept.liveChannelPicks.keys, ['10']);
    });

    test('are left alone when another catalogue is saved', () {
      final a = _account(
        picks: {
          '10': ['1'],
        },
      );
      final saved = a.withCategories(XtreamCatalogue.vod, ['5']);
      expect(saved.liveChannelPicks, {
        '10': ['1'],
      });
    });

    test('an empty pick means the whole category and is not stored', () {
      final a = _account().withChannelPicks({
        '10': [],
        '20': ['7'],
      });
      expect(a.liveChannelPicks, {
        '20': ['7'],
      });
    });

    test('a pick for a category that is not chosen is not stored', () {
      final a = _account(live: ['10']).withChannelPicks({
        '10': ['1'],
        '99': ['2'],
      });
      expect(a.liveChannelPicks.keys, ['10']);
    });
  });

  group('pickChannels', () {
    final all = [_ch('1', 'One'), _ch('2', 'Two'), _ch('3', 'Three')];

    test('keeps only the picked channels, in the panel\'s order', () {
      expect(pickChannels(all, ['3', '1']).map((c) => c.streamId), ['1', '3']);
    });

    test('no picks keeps the whole category', () {
      expect(pickChannels(all, null), all);
      expect(pickChannels(all, const []), all);
    });

    test('a picked channel the panel no longer lists just drops out', () {
      expect(pickChannels(all, ['2', '999']).map((c) => c.streamId), ['2']);
    });
  });

  group('names under a group', () {
    test('drop the part the group already says', () {
      expect(categoryLabelInGroup('USA ➾ Documentary'), 'Documentary');
      expect(categoryLabelInGroup('IND | ORIYA'), 'ORIYA');
      expect(categoryLabelInGroup('Germany ➾ News'), 'News');
    });

    test('keep the full name when there is nothing after the head', () {
      expect(categoryLabelInGroup('USA'), 'USA');
      expect(
        categoryLabelInGroup('BOLLYWOOD (2016-2018)'),
        'BOLLYWOOD (2016-2018)',
      );
      expect(categoryLabelInGroup('(2024) HOLLYWOOD'), '(2024) HOLLYWOOD');
    });

    test('keep "24/7" in what is left', () {
      expect(categoryLabelInGroup('Sports | 24/7 Cricket'), '24/7 Cricket');
    });
  });
}
