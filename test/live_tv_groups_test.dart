import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relay_player/core/platform/device_kind.dart';
import 'package:relay_player/core/theme/relay_theme.dart';
import 'package:relay_player/core/theme/relay_tokens.dart';
import 'package:relay_player/core/theme/relay_widgets.dart';
import 'package:relay_player/data/local/favorites_store.dart';
import 'package:relay_player/data/xtream/xtream_account_store.dart';
import 'package:relay_player/data/xtream/xtream_client.dart';
import 'package:relay_player/features/advanced_sources/xtream_controller.dart';
import 'package:relay_player/features/favorites_history/favorites_controller.dart';
import 'package:relay_player/features/live_tv/live_tv_tab.dart';

class _Accounts extends XtreamAccountsController {
  _Accounts(this._accounts);
  final List<XtreamAccount> _accounts;
  @override
  List<XtreamAccount> build() => _accounts;
}

class _Favourites extends FavoritesController {
  _Favourites(this._keys);
  final Set<String> _keys;
  @override
  Set<String> build() => _keys;
}

/// The Live TV tab's category grouping, on a phone and on a TV.
///
/// Placeholder names throughout (CLAUDE.md §1). The rules of grouping itself
/// are in channel_groups_test.dart; this covers what the viewer sees and
/// reaches.
void main() {
  const named = XtreamAccount(
    id: 'a',
    name: 'Line',
    host: 'http://panel-host.example.invalid',
    username: 'user',
    liveCategoryIds: ['10', '20'],
    liveCategoryNames: {'10': 'News', '20': 'Sport'},
  );

  const channels = [
    XtreamChannel(streamId: '1', name: 'Channel One', categoryId: '10'),
    XtreamChannel(streamId: '2', name: 'Channel Two', categoryId: '10'),
    XtreamChannel(streamId: '3', name: 'Channel Three', categoryId: '20'),
  ];

  var categoryFetches = 0;

  Future<void> pump(
    WidgetTester tester, {
    XtreamAccount account = named,
    Set<String> favourites = const {},
    Size size = const Size(390, 844),
  }) async {
    categoryFetches = 0;
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        xtreamAccountsProvider.overrideWith(() => _Accounts([account])),
        xtreamChannelsProvider.overrideWith((ref, _) async => channels),
        xtreamCategoriesProvider.overrideWith((ref, _) async {
          categoryFetches++;
          return const [
            XtreamCategory(id: '10', name: 'Fetched News'),
            XtreamCategory(id: '20', name: 'Fetched Sport'),
          ];
        }),
        favoritesProvider.overrideWith(() => _Favourites(favourites)),
      ],
      child: MaterialApp(
        home: RelayTheme(
          tokens: RelayPalettes.midnight,
          palette: RelayPalette.midnight,
          child: const Scaffold(body: LiveTvTab()),
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  group('phone', () {
    testWidgets('a chip per chosen category, and choosing one filters',
        (tester) async {
      await pump(tester);
      for (final label in ['All', 'News', 'Sport']) {
        expect(find.text(label), findsOneWidget);
      }
      expect(find.text('Channel Three'), findsOneWidget);

      await tester.tap(find.text('News'));
      await tester.pumpAndSettle();
      expect(find.text('Channel One'), findsOneWidget);
      expect(find.text('Channel Three'), findsNothing);

      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();
      expect(find.text('Channel Three'), findsOneWidget);
    });

    testWidgets('a search looks in every category, not just the chosen one',
        (tester) async {
      await pump(tester);
      await tester.tap(find.text('News'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'three');
      await tester.pumpAndSettle();
      expect(find.text('Channel Three'), findsOneWidget);
    });

    testWidgets('favourites get the first group', (tester) async {
      const star = FavoriteItem(
        kind: FavoriteKind.channel,
        sourceId: 'a',
        itemId: '3',
      );
      await pump(tester, favourites: {star.key});

      final all = tester.getTopLeft(find.text('All')).dx;
      final favs = tester.getTopLeft(find.text('Favourites')).dx;
      final news = tester.getTopLeft(find.text('News')).dx;
      expect(all < favs && favs < news, isTrue);

      await tester.tap(find.text('Favourites'));
      await tester.pumpAndSettle();
      expect(find.text('Channel Three'), findsOneWidget);
      expect(find.text('Channel One'), findsNothing);
    });

    testWidgets('saved names are used without asking the panel',
        (tester) async {
      await pump(tester);
      expect(categoryFetches, 0);
    });

    testWidgets('a line saved before names existed fetches them once',
        (tester) async {
      await pump(
        tester,
        account: const XtreamAccount(
          id: 'a',
          name: 'Line',
          host: 'http://panel-host.example.invalid',
          username: 'user',
          liveCategoryIds: ['10', '20'],
        ),
      );
      expect(categoryFetches, 1);
      expect(find.text('Fetched News'), findsOneWidget);
      expect(find.text('Category 1'), findsNothing);
    });
  });

  group('TV', () {
    setUp(() => DeviceKind.debugSetTelevision(true));
    tearDown(() => DeviceKind.debugSetTelevision(false));

    /// Whether focus is in the channel pane, which starts where the 260 px
    /// category column ends.
    bool focusIsRightOf(double x) {
      final ctx = FocusManager.instance.primaryFocus?.context;
      final box = ctx?.findRenderObject() as RenderBox?;
      return box != null && box.localToGlobal(Offset.zero).dx >= x;
    }

    testWidgets('categories in a column with counts; OK picks, Right enters',
        (tester) async {
      // A 1080p TV's real logical size (tv_navigation_test.dart).
      await pump(tester, size: const Size(960, 540));

      // Counts sit beside each name in the column: All 3, News 2, Sport 1.
      expect(find.text('3'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      final column = tester.getTopRight(find.text('Sport')).dx;
      expect(tester.getTopLeft(find.text('Channel One')).dx,
          greaterThan(column));

      // Walk down to Sport from All, as a remote would. A tap would not do to
      // start from: it activates without moving focus.
      // The row's own stop, RelayFocusable's, which sits above its ring; the
      // InkWell below it is deliberately not focusable.
      Focus.of(tester.element(find.ancestor(
              of: find.text('All'), matching: find.byType(RelayFocusRing))))
          .requestFocus();
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.select);
      await tester.pumpAndSettle();
      expect(find.text('Channel Three'), findsOneWidget);
      expect(find.text('Channel One'), findsNothing);

      // Right leaves the column for the channel list.
      expect(focusIsRightOf(260), isFalse);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(focusIsRightOf(260), isTrue,
          reason: 'Right from a category should land on a channel');
    });
  });
}
