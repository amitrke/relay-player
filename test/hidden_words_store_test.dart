import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:relay_player/data/local/app_settings_store.dart';
import 'package:relay_player/data/xtream/hidden_words.dart';
import 'package:relay_player/data/xtream/xtream_client.dart';
import 'package:relay_player/features/advanced_sources/hidden_words_controller.dart';
import 'package:relay_player/features/advanced_sources/xtream_controller.dart';
import 'package:relay_player/features/settings/settings_controller.dart';

XtreamChannel _ch(String id, String name) =>
    XtreamChannel(streamId: id, name: name, categoryId: '1');

void main() {
  late AppSettingsStore store;

  setUp(() async {
    final dir = Directory.systemTemp.createTempSync('relay_hidden_test');
    addTearDown(() async {
      await Hive.close();
      try {
        dir.deleteSync(recursive: true);
      } catch (_) {}
    });
    Hive.init(dir.path);
    store = AppSettingsStore.withBox(await Hive.openBox<dynamic>('t'));
  });

  ProviderContainer container() {
    final c = ProviderContainer(
      overrides: [appSettingsStoreProvider.overrideWithValue(store)],
    );
    addTearDown(c.dispose);
    return c;
  }

  test('the list is kept between launches', () async {
    final first = container();
    await first.read(hiddenWordsProvider.notifier).add('Germany');
    await first.read(hiddenWordsProvider.notifier).add('  south   indian ');

    final second = container();
    expect(second.read(hiddenWordsProvider), ['Germany', 'south indian']);
  });

  test('an empty or repeated entry adds nothing', () async {
    final c = container();
    final n = c.read(hiddenWordsProvider.notifier);
    expect(await n.add('Germany'), 'Germany');
    expect(await n.add('germany'), isNull);
    expect(await n.add('   '), isNull);
    expect(await n.add('---'), isNull);
    expect(c.read(hiddenWordsProvider), ['Germany']);
  });

  test('a word can be taken away again', () async {
    final c = container();
    final n = c.read(hiddenWordsProvider.notifier);
    await n.add('Germany');
    await n.add('Poland');
    await n.remove('Germany');
    expect(c.read(hiddenWordsProvider), ['Poland']);
    expect(container().read(hiddenWordsProvider), ['Poland']);
  });

  test('a damaged stored value reads as nothing hidden', () async {
    await store.setString('iptv.hiddenWords', 'not json');
    expect(container().read(hiddenWordsProvider), isEmpty);
  });

  test('Live TV leaves out channels whose name has a hidden word', () {
    final channels = [
      _ch('1', 'PAK: ARY Digital'),
      _ch('2', 'US: ABC News'),
      _ch('3', 'Pakistan Sports'),
    ];
    final kept = withoutHidden(channels, HiddenWords(['Pakistan', 'PAK']));
    expect([for (final c in kept) c.streamId], ['2']);
  });

  test('with nothing hidden every channel stays', () {
    final channels = [_ch('1', 'A'), _ch('2', 'B')];
    expect(withoutHidden(channels, HiddenWords(const [])), channels);
  });
}
