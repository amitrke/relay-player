import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:relay_player/core/platform/device_kind.dart';
import 'package:relay_player/core/theme/relay_theme.dart';
import 'package:relay_player/core/theme/relay_tokens.dart';
import 'package:relay_player/core/theme/relay_widgets.dart';
import 'package:relay_player/data/xtream/xtream_account_store.dart';
import 'package:relay_player/data/xtream/xtream_client.dart';
import 'package:relay_player/features/advanced_sources/hidden_words_controller.dart';
import 'package:relay_player/features/advanced_sources/xtream_controller.dart';
import 'package:relay_player/features/favorites_history/favorites_controller.dart';
import 'package:relay_player/features/live_tv/live_tv_tab.dart';

/// Refreshing Live TV's channel list (2026-11-01). Until then the list was
/// fetched once per process and only Retry, on an error page, fetched it
/// again; on a TV the process can live for days. Placeholder names
/// throughout (CLAUDE.md §1).

/// A panel whose categories answer from [lineUp], or fail when [down].
class _Panel extends XtreamClient {
  _Panel()
    : super(
        host: 'http://panel-host.example.invalid',
        username: 'user',
        password: 'pass',
      );

  var down = false;
  var fetches = 0;
  Map<String, List<String>> lineUp = {
    '10': ['Channel One'],
    '20': ['Channel Two'],
  };

  @override
  Future<List<XtreamChannel>> liveStreams(String categoryId) async {
    fetches++;
    if (down) throw Exception('connection refused');
    return [
      for (final (i, name) in (lineUp[categoryId] ?? const []).indexed)
        XtreamChannel(
          streamId: '$categoryId-$i',
          name: name,
          categoryId: categoryId,
        ),
    ];
  }
}

class _Accounts extends XtreamAccountsController {
  _Accounts(this._accounts);
  final List<XtreamAccount> _accounts;
  @override
  List<XtreamAccount> build() => _accounts;
}

class _NoFavourites extends FavoritesController {
  @override
  Set<String> build() => const {};
}

class _NoHiddenWords extends HiddenWordsController {
  @override
  List<String> build() => const [];
}

const _account = XtreamAccount(
  id: 'a',
  name: 'Line',
  host: 'http://panel-host.example.invalid',
  username: 'user',
  liveCategoryIds: ['10', '20'],
  liveCategoryNames: {'10': 'News', '20': 'Sport'},
);

void main() {
  late _Panel panel;

  List<Override> overrides() => [
    xtreamAccountsProvider.overrideWith(() => _Accounts(const [_account])),
    xtreamClientProvider.overrideWith((ref, _) async => panel),
    hiddenWordsProvider.overrideWith(_NoHiddenWords.new),
    favoritesProvider.overrideWith(_NoFavourites.new),
  ];

  setUp(() {
    panel = _Panel();
    xtreamChannelsFetchedAt.clear();
  });

  group('the channel list', () {
    test('one failed category costs only its own channels', () async {
      final container = ProviderContainer(overrides: overrides());
      addTearDown(container.dispose);
      panel.lineUp = {
        '20': ['Channel Two'],
      };
      container.listen(xtreamChannelsProvider(_account), (_, _) {});
      final list = await container.read(
        xtreamChannelsProvider(_account).future,
      );
      expect(list.map((c) => c.name), ['Channel Two']);
      expect(xtreamChannelsFetchedAt, contains('a'));
    });

    // The control is the test above: a missing category is no error. Every
    // category failing is the panel being down, and used to read as "no
    // channels", with no Retry.
    test('every category failing is an error, not an empty list', () async {
      final container = ProviderContainer(overrides: overrides());
      addTearDown(container.dispose);
      panel.down = true;
      // Watched, as the tab watches it; unwatched, Riverpod disposes it
      // before the error arrives.
      container.listen(xtreamChannelsProvider(_account), (_, _) {});
      await expectLater(
        container.read(xtreamChannelsProvider(_account).future),
        throwsException,
      );
      expect(xtreamChannelsFetchedAt, isNot(contains('a')));
    });
  });

  Future<void> pump(
    WidgetTester tester, {
    Size size = const Size(390, 844),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides(),
        child: MaterialApp(
          home: RelayTheme(
            tokens: RelayPalettes.midnight,
            palette: RelayPalette.midnight,
            child: const Scaffold(body: LiveTvTab()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Refresh shows a channel the panel added since', (tester) async {
    await pump(tester);
    expect(find.text('Channel One'), findsOneWidget);
    expect(find.text('Channel New'), findsNothing);

    panel.lineUp = {
      '10': ['Channel One', 'Channel New'],
      '20': ['Channel Two'],
    };
    await tester.tap(find.byTooltip('Refresh channels'));
    await tester.pumpAndSettle();
    expect(find.text('Channel New'), findsOneWidget);
  });

  testWidgets('a failed refresh keeps the list and says so', (tester) async {
    await pump(tester);
    panel.down = true;
    await tester.tap(find.byTooltip('Refresh channels'));
    await tester.pumpAndSettle();
    expect(find.text('Channel One'), findsOneWidget);
    expect(find.textContaining('Could not refresh'), findsOneWidget);
  });

  testWidgets('a first load with the panel down offers Retry', (tester) async {
    panel.down = true;
    await pump(tester);
    expect(find.text('Channel One'), findsNothing);
    expect(find.text('Try again'), findsOneWidget);
  });

  // The TV case: the app comes back to the front with a list fetched hours
  // ago in the same process. A fresh list is the control.
  Future<void> resume(WidgetTester tester) async {
    for (final state in const [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
    await tester.pumpAndSettle();
  }

  testWidgets('coming back to a fresh list fetches nothing', (tester) async {
    await pump(tester);
    final before = panel.fetches;
    await resume(tester);
    expect(panel.fetches, before);
  });

  testWidgets('coming back to a list over six hours old fetches it again', (
    tester,
  ) async {
    await pump(tester);
    final before = panel.fetches;
    xtreamChannelsFetchedAt['a'] = DateTime.now().subtract(
      const Duration(hours: 7),
    );
    panel.lineUp = {
      '10': ['Channel One', 'Channel New'],
      '20': ['Channel Two'],
    };
    await resume(tester);
    expect(panel.fetches, greaterThan(before));
    expect(find.text('Channel New'), findsOneWidget);
    // Nobody asked, so a quiet refresh says nothing either way.
    expect(find.byType(SnackBar), findsNothing);
  });

  // On the Google TV emulator a button beside the search box could not be
  // reached: Right in the field moves its caret. On a TV it is the last row
  // of the category column, which Down reaches.
  group('TV', () {
    setUp(() => DeviceKind.debugSetTelevision(true));
    tearDown(() => DeviceKind.debugSetTelevision(false));

    testWidgets('Down from the last category reaches Refresh; OK refreshes', (
      tester,
    ) async {
      await pump(tester, size: const Size(960, 540));
      expect(find.byTooltip('Refresh channels'), findsNothing);
      Focus.of(
        tester.element(
          find.ancestor(
            of: find.text('Sport'),
            matching: find.byType(RelayFocusRing),
          ),
        ),
      ).requestFocus();
      await tester.pumpAndSettle();
      panel.lineUp = {
        '10': ['Channel One', 'Channel New'],
        '20': ['Channel Two'],
      };
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.select);
      await tester.pumpAndSettle();
      expect(find.text('Channel New'), findsOneWidget);
    });
  });
}
