import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:relay_player/data/ai/ai_provider.dart';
import 'package:relay_player/data/ai/text_client.dart';
import 'package:relay_player/data/local/app_settings_store.dart';
import 'package:relay_player/data/local/history_store.dart';
import 'package:relay_player/domain/models/catalog_item.dart';
import 'package:relay_player/features/ai/ai_controller.dart';
import 'package:relay_player/features/ai/ai_recommendations_controller.dart';
import 'package:relay_player/features/favorites_history/history_controller.dart';
import 'package:relay_player/features/library/library_screen.dart'
    show libraryItemsProvider;
import 'package:relay_player/features/settings/settings_controller.dart';

/// The behaviour that keeps background recommendations from becoming a drain on
/// the user's quota: what is shown at once, and when anything is sent at all.

CatalogItem _film(
  String id,
  String title, {
  int? year,
  DateTime? watchedAt,
  int views = 0,
}) => CatalogItem(
  source: CatalogSource.plex,
  sourceId: 's',
  kind: CatalogKind.movie,
  id: id,
  title: title,
  year: year,
  viewCount: views,
  lastViewedAt: watchedAt,
);

class _Client implements TextGenerationClient {
  int calls = 0;
  String answer = '[1]';
  bool fail = false;

  @override
  Future<String> complete({
    required String system,
    required String user,
    int maxTokens = 600,
  }) async {
    calls++;
    if (fail) throw const AiException('provider said no');
    return answer;
  }
}

class _Setup extends AiSetupController {
  _Setup(this.config);

  final AiProviderConfig config;

  @override
  Future<AiSetup?> build() async => AiSetup(config, null);
}

class _History extends HistoryController {
  _History(this.items);

  final List<HistoryItem> items;

  @override
  List<HistoryItem> build() => items;
}

// A local address, so no consent is needed and the controller is enabled.
const _local = AiProviderConfig(
  preset: AiPreset.custom,
  baseUrl: 'http://127.0.0.1:1/v1',
  model: 'm',
);
const _remote = AiProviderConfig(
  preset: AiPreset.openRouter,
  baseUrl: 'https://openrouter.ai/api/v1',
  model: 'm',
);

void main() {
  late AppSettingsStore store;
  late _Client client;

  setUp(() async {
    final dir = Directory.systemTemp.createTempSync('relay_ai_test');
    // Close the box before the directory goes, or Windows refuses the delete.
    addTearDown(() async {
      await Hive.close();
      try {
        dir.deleteSync(recursive: true);
      } catch (_) {}
    });
    Hive.init(dir.path);
    store = AppSettingsStore.withBox(await Hive.openBox<dynamic>('t'));
    client = _Client();
  });

  final watched = _film(
    '1',
    'Heat',
    year: 1995,
    watchedAt: DateTime(2026, 10, 1),
    views: 1,
  );
  final library = [
    watched,
    _film('2', 'Ronin', year: 1998),
    _film('3', 'Casino', year: 1995),
  ];

  ProviderContainer container({
    AiProviderConfig config = _local,
    List<CatalogItem>? items,
  }) {
    final c = ProviderContainer(
      overrides: [
        appSettingsStoreProvider.overrideWithValue(store),
        aiSetupProvider.overrideWith(() => _Setup(config)),
        aiClientProvider.overrideWithValue(client),
        libraryItemsProvider.overrideWith(
          (ref, tab) async =>
              tab.name == 'movies' ? (items ?? library) : const <CatalogItem>[],
        ),
        historyProvider.overrideWith(() => _History(const [])),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  Future<AiRecsState> settled(ProviderContainer c) async {
    await c.read(aiRecommendationsProvider.future);
    // The background refresh starts after build returns.
    for (var i = 0; i < 20; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    return c.read(aiRecommendationsProvider).value!;
  }

  test('with nothing cached it asks once and keeps the picks', () async {
    // Heat is watched, so the unwatched list is 1. Ronin, 2. Casino.
    client.answer = '[1]';
    final state = await settled(container());
    expect(client.calls, 1);
    expect(state.items.map((i) => i.id), ['2']);
    expect(store.getString(aiRecommendationsCacheKey), isNotNull);
  });

  test(
    'a relaunch with nothing new shows the cached picks and sends nothing',
    () async {
      await settled(container());
      expect(client.calls, 1);

      final second = container();
      final first = await second.read(aiRecommendationsProvider.future);
      // Shown at once, straight from the cache.
      expect(first.items, isNotEmpty);
      expect(first.refreshing, isFalse);
      await settled(second);
      expect(client.calls, 1);
    },
  );

  test('watching something new makes the picks stale and asks again', () async {
    await settled(container());
    expect(client.calls, 1);

    final newer = [
      library[0],
      _film(
        '2',
        'Ronin',
        year: 1998,
        watchedAt: DateTime(2026, 10, 8),
        views: 1,
      ),
      library[2],
    ];
    await settled(container(items: newer));
    expect(client.calls, 2);
  });

  test('without consent nothing is prepared and nothing is sent', () async {
    final state = await settled(container(config: _remote));
    expect(state.enabled, isFalse);
    expect(client.calls, 0);
    expect(store.getString(aiRecommendationsCacheKey), isNull);
  });

  test(
    'a failed attempt keeps the old picks, says why, and is not retried',
    () async {
      await settled(container());
      expect(client.calls, 1);

      client.fail = true;
      final newer = [
        library[0],
        _film(
          '2',
          'Ronin',
          year: 1998,
          watchedAt: DateTime(2026, 10, 8),
          views: 1,
        ),
        library[2],
      ];
      final c = container(items: newer);
      final state = await settled(c);
      expect(client.calls, 2);
      expect(state.error, contains('provider said no'));

      // Opening Search again must not retry: a rejected key is not a loop.
      await c.read(aiRecommendationsProvider.notifier).refreshIfStale();
      expect(client.calls, 2);
    },
  );

  test('Again leaves the current picks out, so the answer differs', () async {
    client.answer = '[1]'; // Ronin.
    final c = container();
    await settled(c);
    expect(c.read(aiRecommendationsProvider).value!.items.single.id, '2');

    // With Ronin excluded the unwatched list is just Casino, now line 1.
    await c.read(aiRecommendationsProvider.notifier).refresh();
    expect(c.read(aiRecommendationsProvider).value!.items.single.id, '3');
  });
}
