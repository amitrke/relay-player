import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:relay_player/core/theme/relay_theme.dart';
import 'package:relay_player/core/theme/relay_tokens.dart';
import 'package:relay_player/data/local/app_settings_store.dart';
import 'package:relay_player/data/tmdb/title_match.dart';
import 'package:relay_player/data/tmdb/tmdb_cache.dart';
import 'package:relay_player/data/tmdb/tmdb_client.dart';
import 'package:relay_player/data/tmdb/tmdb_enricher.dart';
import 'package:relay_player/data/transfer/transfer_bundle.dart';
import 'package:relay_player/domain/models/catalog_item.dart';
import 'package:relay_player/features/library/library_screen.dart'
    show LibraryController, libraryItemsProvider;
import 'package:relay_player/features/library/library_tab.dart';
import 'package:relay_player/features/metadata/release_dates.dart';
import 'package:relay_player/features/metadata/release_dates_job.dart';
import 'package:relay_player/features/metadata/tmdb_controller.dart';
import 'package:relay_player/features/settings/metadata_pane.dart';
import 'package:relay_player/features/settings/settings_controller.dart';

/// A TMDB that knows a few titles, counts what it is asked, and can fail.
class _FakeApi implements TmdbApi {
  int searches = 0;
  int detailCalls = 0;
  final searched = <String>[];

  /// Fail every request with this.
  bool fail = false;

  /// Fail the first n requests only.
  int failFirst = 0;

  /// title -> release date, or null for "TMDB knows it, has no date".
  final known = <String, DateTime?>{
    'Alpha': DateTime.utc(2020, 6, 15),
    'Bravo': DateTime.utc(2020, 2, 1),
    'Charlie': DateTime.utc(2018, 9, 9),
    'Unreleased': null,
  };

  void _maybeFail() {
    if (fail || failFirst > 0) {
      if (failFirst > 0) failFirst--;
      throw const TmdbException('down');
    }
  }

  @override
  Future<List<TmdbCandidate>> search(
    String title, {
    required bool tv,
    int? year,
  }) async {
    searches++;
    searched.add(title);
    _maybeFail();
    if (!known.containsKey(title)) return const [];
    return [
      TmdbCandidate(
        id: title.hashCode & 0xFFFF,
        title: title,
        originalTitle: title,
        year: known[title]?.year,
      ),
    ];
  }

  @override
  Future<TmdbInfo> details(int id, {required bool tv}) async {
    detailCalls++;
    _maybeFail();
    final entry = known.entries.firstWhere(
      (e) => (e.key.hashCode & 0xFFFF) == id,
    );
    return TmdbInfo(
      id: id,
      isTv: tv,
      genres: const ['Drama'],
      releaseDate: entry.value,
      releaseChecked: true,
    );
  }

  @override
  Future<List<TmdbCandidate>> recommendations(
    int id, {
    required bool tv,
  }) async => const [];
}

CatalogItem _movie(String title, {int? year, String source = 'plex'}) =>
    CatalogItem(
      source: CatalogSource.plex,
      sourceId: source,
      kind: CatalogKind.movie,
      id: '$source-$title',
      title: title,
      year: year,
    );

String _key(CatalogItem item) => TmdbEnricher.cacheKey(item);

/// Two films in Movies and nothing in Series. Static because a family override
/// builds its own instance and has no other way to be handed the list.
class _FakeLibrary extends LibraryController {
  _FakeLibrary(super.tab);

  @override
  Future<List<CatalogItem>> build() async => tab == LibraryTab.movies
      ? [_movie('Alpha'), _movie('Bravo')]
      : const <CatalogItem>[];
}

void main() {
  group('TmdbInfo release date', () {
    test('round trips a date', () {
      final info = TmdbInfo(
        id: 1,
        isTv: false,
        releaseDate: DateTime.utc(2019, 5, 30),
        releaseChecked: true,
      );
      final back = TmdbInfo.fromJson(info.toJson())!;
      expect(back.releaseDate, DateTime.utc(2019, 5, 30));
      expect(back.releaseChecked, isTrue);
    });

    test('"asked, TMDB has none" is not the same as "never asked"', () {
      final none = TmdbInfo.fromJson(
        const TmdbInfo(id: 1, isTv: false, releaseChecked: true).toJson(),
      )!;
      expect(none.releaseDate, isNull);
      expect(none.releaseChecked, isTrue);

      final never = TmdbInfo.fromJson(
        const TmdbInfo(id: 1, isTv: false).toJson(),
      )!;
      expect(never.releaseChecked, isFalse);
    });

    test('a record kept before dates existed reads as never asked', () {
      final old = TmdbInfo.fromJson({
        'id': 9,
        'tv': false,
        'genres': ['Drama'],
        'lang': 'en',
        'rating': 7.5,
        'runtime': 100,
        'overview': 'x',
      })!;
      expect(old.releaseChecked, isFalse);
      expect(old.releaseDate, isNull);
      // And everything it did know survives.
      expect(old.genres, ['Drama']);
      expect(old.rating, 7.5);
    });

    test('parses TMDB dates, and nothing else', () {
      expect(TmdbInfo.parseDate('2019-05-30'), DateTime.utc(2019, 5, 30));
      expect(
        TmdbInfo.parseDate('2019-05-30T10:00:00Z'),
        DateTime.utc(2019, 5, 30),
      );
      // TMDB sends an empty string for "no date yet".
      expect(TmdbInfo.parseDate(''), isNull);
      expect(TmdbInfo.parseDate(null), isNull);
      expect(TmdbInfo.parseDate('not a date'), isNull);
      expect(TmdbInfo.parseDate(2019), isNull);
    });
  });

  group('enricher release lookups', () {
    late _FakeApi api;
    late MemoryTmdbCache cache;
    var clock = DateTime.utc(2026, 10, 9);
    late TmdbEnricher enricher;

    setUp(() {
      api = _FakeApi();
      cache = MemoryTmdbCache();
      clock = DateTime.utc(2026, 10, 9);
      enricher = TmdbEnricher(api, cache, now: () => clock);
    });

    test('nothing is known about a title nobody has asked about', () async {
      final peek = await enricher.peekRelease(_movie('Alpha'));
      expect(peek.date, isNull);
      expect(peek.settled, isFalse);
      expect(api.searches, 0);
    });

    test('asks once, then knows without asking again', () async {
      final item = _movie('Alpha');
      final fetched = await enricher.fetchRelease(item);
      expect(fetched.date, DateTime.utc(2020, 6, 15));
      expect(fetched.failed, isFalse);
      expect(api.searches, 1);
      expect(api.detailCalls, 1);

      final peek = await enricher.peekRelease(item);
      expect(peek.date, DateTime.utc(2020, 6, 15));
      expect(peek.settled, isTrue);
      expect(api.searches, 1, reason: 'peek must not ask');
    });

    test(
      'TMDB knowing a title but having no date is settled, not retried',
      () async {
        final item = _movie('Unreleased');
        final fetched = await enricher.fetchRelease(item);
        expect(fetched.date, isNull);
        expect(fetched.failed, isFalse);

        final peek = await enricher.peekRelease(item);
        expect(peek.date, isNull);
        expect(peek.settled, isTrue);
      },
    );

    test(
      'a title TMDB has never heard of is settled, then asked again in time',
      () async {
        final item = _movie('Nobody Knows');
        await enricher.fetchRelease(item);
        expect((await enricher.peekRelease(item)).settled, isTrue);

        clock = clock.add(tmdbMissLifetime + const Duration(days: 1));
        expect((await enricher.peekRelease(item)).settled, isFalse);
      },
    );

    test('a failure says so and is neither cached nor settled', () async {
      api.fail = true;
      final item = _movie('Alpha');
      final fetched = await enricher.fetchRelease(item);
      expect(fetched.failed, isTrue);
      expect(fetched.date, isNull);

      expect((await enricher.peekRelease(item)).settled, isFalse);
      api.fail = false;
      expect(
        (await enricher.fetchRelease(item)).date,
        DateTime.utc(2020, 6, 15),
      );
    });

    test(
      'a record saved before dates existed costs one request, not two',
      () async {
        final item = _movie('Alpha');
        await cache.put(
          _key(item),
          TmdbLookup(
            TmdbInfo(
              id: 'Alpha'.hashCode & 0xFFFF,
              isTv: false,
              genres: const ['Old genre'],
            ),
            clock,
          ),
        );

        final peek = await enricher.peekRelease(item);
        expect(peek.settled, isFalse, reason: 'it has no date yet');

        final fetched = await enricher.fetchRelease(item);
        expect(fetched.date, DateTime.utc(2020, 6, 15));
        expect(api.searches, 0, reason: 'the id was already known');
        expect(api.detailCalls, 1);
        expect((await enricher.peekRelease(item)).settled, isTrue);
      },
    );

    test(
      'the same title with a year and without are separate records',
      () async {
        expect(_key(_movie('Alpha', year: 2020)), isNot(_key(_movie('Alpha'))));
      },
    );
  });

  group('the job', () {
    late _FakeApi api;
    late MemoryTmdbCache cache;
    late TmdbEnricher enricher;
    late ProviderContainer container;

    const fast = ReleaseDatesConfig(
      startDelay: Duration.zero,
      pause: Duration.zero,
      concurrency: 1,
      flushEvery: 2,
    );

    setUp(() {
      api = _FakeApi();
      cache = MemoryTmdbCache();
      enricher = TmdbEnricher(api, cache);
      container = ProviderContainer();
      addTearDown(container.dispose);
      container.listen(releaseDatesProvider, (_, _) {});
    });

    ReleaseDatesJob job(
      List<CatalogItem> items, {
      ReleaseDatesConfig config = fast,
    }) => ReleaseDatesJob(
      enricher: enricher,
      items: items,
      sink: container.read(releaseDatesProvider.notifier),
      config: config,
    );

    ReleaseDatesState state() => container.read(releaseDatesProvider);

    test('finds a date for each title and says it is done', () async {
      final items = [
        _movie('Alpha', year: 2020),
        _movie('Charlie', year: 2018),
      ];
      await job(items).run();

      expect(state().dates[_key(items[0])], DateTime.utc(2020, 6, 15));
      expect(state().dates[_key(items[1])], DateTime.utc(2018, 9, 9));
      expect(state().total, 2);
      expect(state().settled, 2);
      expect(state().running, isFalse);
      expect(state().stoppedEarly, isFalse);
    });

    test('a title TMDB does not know is settled and has no date', () async {
      final items = [_movie('Alpha'), _movie('Nobody Knows')];
      await job(items).run();

      expect(state().dates.keys, [_key(items[0])]);
      expect(state().settled, 2);
    });

    test('what is kept is used without a request, on the next run', () async {
      final items = [_movie('Alpha'), _movie('Bravo')];
      await job(items).run();
      final asked = api.searches;
      expect(asked, 2);

      container.read(releaseDatesProvider.notifier).reset();
      await job(items).run();
      expect(api.searches, asked, reason: 'nothing new to ask');
      expect(state().dates, hasLength(2), reason: 'but the dates are back');
      expect(state().settled, 2);
    });

    test('the same title from two sources is looked up once', () async {
      final a = _movie('Alpha', year: 2020, source: 'one');
      final b = _movie('Alpha', year: 2020, source: 'two');
      await job([a, b]).run();

      expect(api.searches, 1);
      expect(state().total, 1);
      expect(state().dates[_key(a)], state().dates[_key(b)]);
    });

    test(
      'titles with no year go first, because a date is worth most there',
      () async {
        await job([
          _movie('Alpha', year: 2020),
          _movie('Bravo', year: 2020),
          _movie('Charlie'),
        ]).run();

        expect(api.searched.first, 'Charlie');
      },
    );

    test('a run is capped, and the rest waits for the next one', () async {
      final items = [_movie('Alpha'), _movie('Bravo'), _movie('Charlie')];
      await job(
        items,
        config: const ReleaseDatesConfig(
          startDelay: Duration.zero,
          pause: Duration.zero,
          concurrency: 1,
          limitPerRun: 2,
        ),
      ).run();

      expect(api.searches, 2);
      expect(state().settled, 2);
      expect(state().total, 3);
      expect(state().running, isFalse);
      // Reaching the cap is an ordinary end, not a failure.
      expect(state().stoppedEarly, isFalse);
    });

    test(
      'a streak of failures stops the run and keeps what was found',
      () async {
        // Alpha succeeds, then everything fails.
        final items = [
          _movie('Alpha', year: 2020),
          _movie('Bravo', year: 2021),
          _movie('Charlie', year: 2022),
          _movie('Unreleased', year: 2023),
          _movie('Alpha', year: 2024),
        ];
        var calls = 0;
        final flaky = _FlakyAfter(api, goodCalls: 2, onCall: () => calls++);
        final j = ReleaseDatesJob(
          enricher: TmdbEnricher(flaky, cache),
          items: items,
          sink: container.read(releaseDatesProvider.notifier),
          config: const ReleaseDatesConfig(
            startDelay: Duration.zero,
            pause: Duration.zero,
            concurrency: 1,
            giveUpAfter: 2,
          ),
        );
        await j.run();

        expect(state().stoppedEarly, isTrue);
        expect(state().running, isFalse);
        expect(state().dates, isNotEmpty, reason: 'the first found is kept');
        expect(state().settled, lessThan(state().total));
      },
    );

    test('one failure in the middle does not stop it', () async {
      api.failFirst = 1;
      final items = [_movie('Alpha'), _movie('Bravo'), _movie('Charlie')];
      await job(items).run();

      expect(state().stoppedEarly, isFalse);
      // The failed one is unsettled and tried next run; the others are done.
      expect(state().settled, 2);
      expect(state().dates, hasLength(2));
    });

    test('cancelling stops it asking', () async {
      final items = [for (var i = 0; i < 50; i++) _movie('Nobody $i')];
      final j = job(
        items,
        config: const ReleaseDatesConfig(
          startDelay: Duration.zero,
          pause: Duration(milliseconds: 5),
          concurrency: 1,
        ),
      );
      final done = j.run();
      await Future<void>.delayed(const Duration(milliseconds: 30));
      j.cancel();
      await done;

      expect(api.searches, lessThan(50));
    });

    test('with nothing in the library it does nothing', () async {
      await job(const []).run();
      expect(api.searches, 0);
      expect(state().total, 0);
    });
  });

  group('switched on and off', () {
    late _FakeApi api;
    late AppSettingsStore store;
    late Directory dir;
    var boxes = 0;

    setUp(() async {
      api = _FakeApi();
      dir = Directory.systemTemp.createTempSync('relay_release_test');
      Hive.init(dir.path);
      store = AppSettingsStore.withBox(
        await Hive.openBox<dynamic>('r${boxes++}'),
      );
      addTearDown(() async {
        await Hive.close();
        try {
          dir.deleteSync(recursive: true);
        } catch (_) {}
      });
    });

    ProviderContainer container({String? key = 'key'}) {
      final c = ProviderContainer(
        overrides: [
          appSettingsStoreProvider.overrideWithValue(store),
          tmdbKeyProvider.overrideWith(() => _Key(key)),
          tmdbEnricherProvider.overrideWith(
            (ref) async =>
                key == null ? null : TmdbEnricher(api, MemoryTmdbCache()),
          ),
          releaseDatesConfigProvider.overrideWithValue(
            const ReleaseDatesConfig(
              startDelay: Duration.zero,
              pause: Duration.zero,
              concurrency: 1,
            ),
          ),
          libraryItemsProvider.overrideWith2(_FakeLibrary.new),
        ],
      );
      addTearDown(c.dispose);
      c.listen(releaseDatesJobProvider, (_, _) {});
      c.listen(releaseDatesProvider, (_, _) {});
      return c;
    }

    Future<void> settle() async {
      for (var i = 0; i < 30; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
    }

    test('off by default: a key and a library are not enough', () async {
      final c = container();
      await settle();

      expect(c.read(releaseDatesEnabledProvider), isFalse);
      expect(api.searches, 0, reason: 'nothing leaves the device unasked');
      expect(c.read(releaseDatesProvider).dates, isEmpty);
    });

    test('agreeing starts it, and records when', () async {
      final c = container();
      await c.read(releaseDatesEnabledProvider.notifier).enable();
      await settle();

      expect(api.searches, 2);
      expect(c.read(releaseDatesProvider).dates, hasLength(2));
      expect(store.getString('metadata.releaseDatesAt'), isNotNull);
    });

    test('the agreement survives a restart', () async {
      final first = container();
      await first.read(releaseDatesEnabledProvider.notifier).enable();

      final second = container();
      expect(second.read(releaseDatesEnabledProvider), isTrue);
    });

    test('switching it off clears what the sort was given', () async {
      final c = container();
      await c.read(releaseDatesEnabledProvider.notifier).enable();
      await settle();
      expect(c.read(releaseDatesProvider).dates, isNotEmpty);

      await c.read(releaseDatesEnabledProvider.notifier).disable();
      await settle();
      expect(c.read(releaseDatesProvider).dates, isEmpty);
      expect(store.getBool('metadata.releaseDates', fallback: true), isFalse);
    });

    test(
      'without a key it never runs, even if it was agreed to before',
      () async {
        await store.setBool('metadata.releaseDates', true);
        final c = container(key: null);
        await settle();

        expect(api.searches, 0);
        // The agreement was to use that key: without one it is withdrawn, so a
        // key added later asks again.
        expect(c.read(releaseDatesEnabledProvider), isFalse);
      },
    );

    test('removing the key withdraws the agreement and stops it', () async {
      final c = container();
      await c.read(releaseDatesEnabledProvider.notifier).enable();
      await settle();
      expect(c.read(releaseDatesProvider).dates, isNotEmpty);

      (c.read(tmdbKeyProvider.notifier) as _Key).clear();
      await settle();

      expect(c.read(releaseDatesEnabledProvider), isFalse);
      expect(c.read(releaseDatesProvider).dates, isEmpty);
    });
  });

  group('the Settings control', () {
    Future<ProviderContainer> pump(
      WidgetTester tester, {
      ReleaseDatesState? progress,
      bool enabled = false,
    }) async {
      tester.view.physicalSize = const Size(900, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final c = ProviderContainer(
        overrides: [
          releaseDatesEnabledProvider.overrideWith(() => _MemEnabled(enabled)),
          tmdbKeyProvider.overrideWith(() => _Key('key')),
        ],
      );
      addTearDown(c.dispose);
      if (progress != null) {
        c.read(releaseDatesProvider.notifier)
          ..merge(progress.dates)
          ..progress(
            total: progress.total,
            settled: progress.settled,
            running: progress.running,
            stoppedEarly: progress.stoppedEarly,
          );
      }
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: MaterialApp(
            builder: (context, child) => RelayTheme(
              tokens: RelayPalettes.midnight,
              palette: RelayPalette.midnight,
              child: child!,
            ),
            home: const Scaffold(
              body: SingleChildScrollView(child: MetadataPane()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return c;
    }

    testWidgets('is off, and says what turning it on sends', (tester) async {
      final c = await pump(tester);
      expect(c.read(releaseDatesEnabledProvider), isFalse);
      expect(find.text('Release dates for your library'), findsOneWidget);
      expect(
        find.textContaining('Sends every title in your library'),
        findsOneWidget,
      );
      expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
    });

    testWidgets('turning it on asks first, naming what is sent', (
      tester,
    ) async {
      final c = await pump(tester);
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(find.text('Send your library titles to TMDB?'), findsOneWidget);
      expect(
        find.textContaining('every film and series in your library'),
        findsOneWidget,
      );
      expect(find.textContaining('sends the title'), findsOneWidget);
      // Nothing is agreed yet.
      expect(c.read(releaseDatesEnabledProvider), isFalse);
    });

    testWidgets('the safe answer is in focus, and declining changes nothing', (
      tester,
    ) async {
      final c = await pump(tester);
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      final notNow = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'Not now'),
      );
      expect(notNow.autofocus, isTrue);

      await tester.tap(find.text('Not now'));
      await tester.pumpAndSettle();
      expect(c.read(releaseDatesEnabledProvider), isFalse);
      expect(
        (c.read(releaseDatesEnabledProvider.notifier) as _MemEnabled).enables,
        0,
      );
    });

    testWidgets('agreeing turns it on', (tester) async {
      final c = await pump(tester);
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Look them up'));
      await tester.pumpAndSettle();

      expect(c.read(releaseDatesEnabledProvider), isTrue);
      expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
    });

    testWidgets('turning it off needs no question', (tester) async {
      final c = await pump(tester, enabled: true);
      expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(find.text('Send your library titles to TMDB?'), findsNothing);
      expect(c.read(releaseDatesEnabledProvider), isFalse);
    });

    testWidgets('says how far it has got, and when it has stopped short', (
      tester,
    ) async {
      await pump(
        tester,
        enabled: true,
        progress: const ReleaseDatesState(
          total: 800,
          settled: 312,
          running: true,
        ),
      );
      expect(find.text('Looked up 312 of 800 titles.'), findsOneWidget);
    });

    testWidgets('done reports how many dates were found', (tester) async {
      await pump(
        tester,
        enabled: true,
        progress: ReleaseDatesState(
          total: 3,
          settled: 3,
          dates: {'a': DateTime.utc(2020), 'b': DateTime.utc(2021)},
        ),
      );
      expect(
        find.text('Done: 2 release dates found for 3 titles.'),
        findsOneWidget,
      );
    });

    testWidgets('a capped run says the rest carries on next time', (
      tester,
    ) async {
      await pump(
        tester,
        enabled: true,
        progress: const ReleaseDatesState(total: 1500, settled: 600),
      );
      expect(find.textContaining('carry on the next time'), findsOneWidget);
    });

    testWidgets('a run that gave up says why, and that nothing is lost', (
      tester,
    ) async {
      await pump(
        tester,
        enabled: true,
        progress: const ReleaseDatesState(
          total: 100,
          settled: 10,
          stoppedEarly: true,
        ),
      );
      expect(find.textContaining('TMDB stopped answering'), findsOneWidget);
      expect(find.textContaining('what it found is kept'), findsOneWidget);
    });
  });

  test('the agreement is not something one device can copy to another', () {
    // architecture.md 17.3: consent is the person at each device's own. The
    // transfer allowlist must never grow to include it.
    final copyable = TransferPreferences.keys.toSet();
    expect(copyable, isNot(contains('metadata.releaseDates')));
    expect(copyable, isNot(contains('metadata.releaseDatesAt')));
  });
}

/// A TMDB that behaves for [goodCalls] requests and then fails every one.
class _FlakyAfter implements TmdbApi {
  _FlakyAfter(this._inner, {required this.goodCalls, required this.onCall});

  final _FakeApi _inner;
  final int goodCalls;
  final void Function() onCall;
  int _n = 0;

  void _tick() {
    onCall();
    if (++_n > goodCalls) throw const TmdbException('rate limited');
  }

  @override
  Future<List<TmdbCandidate>> search(
    String title, {
    required bool tv,
    int? year,
  }) {
    _tick();
    return _inner.search(title, tv: tv, year: year);
  }

  @override
  Future<TmdbInfo> details(int id, {required bool tv}) {
    _tick();
    return _inner.details(id, tv: tv);
  }

  @override
  Future<List<TmdbCandidate>> recommendations(int id, {required bool tv}) =>
      _inner.recommendations(id, tv: tv);
}

/// The key, without secure storage. [clear] is the key being removed.
class _Key extends TmdbKeyController {
  _Key(this._key);

  final String? _key;

  @override
  Future<String?> build() async => _key;

  void clear() => state = const AsyncData(null);
}

/// The switch without a settings box, for tests of the pane: the real one writes
/// a file, which a widget test's fake time cannot wait for. What it persists is
/// tested against a real box above.
class _MemEnabled extends ReleaseDatesEnabledController {
  _MemEnabled(this._initial);

  final bool _initial;
  int enables = 0;

  @override
  bool build() => _initial;

  @override
  Future<void> enable() async {
    enables++;
    state = true;
  }

  @override
  Future<void> disable() async => state = false;
}
