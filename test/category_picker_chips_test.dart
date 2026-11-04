import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:relay_player/core/platform/device_kind.dart';
import 'package:relay_player/core/theme/relay_theme.dart';
import 'package:relay_player/core/theme/relay_tokens.dart';
import 'package:relay_player/data/xtream/xtream_account_store.dart';
import 'package:relay_player/data/xtream/xtream_client.dart';
import 'package:relay_player/features/advanced_sources/category_picker_screen.dart';
import 'package:relay_player/features/advanced_sources/hidden_words_controller.dart';
import 'package:relay_player/features/advanced_sources/xtream_controller.dart';
import 'package:relay_player/i18n/strings.g.dart';

/// "What do you watch?" (category_picker_screen.dart, 2026-11-03): the chips
/// set ticks and Save keeps them, nothing is chosen until one is tapped
/// (§4.1), and Fine-tune is the old list with a way back. Made-up category
/// names (CLAUDE.md §1).
void main() {
  const categories = [
    XtreamCategory(id: '1', name: 'DE | News'),
    XtreamCategory(id: '2', name: 'UK | Sport'),
    XtreamCategory(id: '3', name: 'Germany ➾ Sport'),
    XtreamCategory(id: '4', name: 'DE | Kids'),
    XtreamCategory(id: '5', name: '24/7 Classics'),
  ];

  late List<XtreamAccount> saved;

  Future<void> pump(WidgetTester tester, {List<String> chosen = const []}) async {
    DeviceKind.debugSetTelevision(false);
    // Wide enough for the picker's top row in the test font, which draws every
    // letter as a square and so runs far wider than a real one.
    tester.view.physicalSize = const Size(640, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    saved = [];
    final account = XtreamAccount(
      id: 'a',
      name: 'TV subscription',
      host: 'http://panel-host.example.invalid',
      username: 'user',
      liveCategoryIds: chosen,
    );

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) => Scaffold(
            body: TextButton(
              onPressed: () => context.push('/picker'),
              child: const Text('open'),
            ),
          ),
        ),
        GoRoute(
          path: '/picker',
          builder: (_, _) => const CategoryPickerScreen(
            accountId: 'a',
            catalogue: XtreamCatalogue.live,
          ),
        ),
      ],
    );
    await tester.pumpWidget(ProviderScope(
      overrides: [
        xtreamAccountsProvider.overrideWith(() => _Saving(account, saved)),
        xtreamCategoriesProvider.overrideWith((ref, _) async => categories),
        hiddenWordsProvider.overrideWith(_NoHiddenWords.new),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        builder: (_, child) => RelayTheme(
          tokens: RelayPalettes.midnight,
          palette: RelayPalette.midnight,
          child: child!,
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Finder chip(String label) => find.ancestor(
        of: find.text(label),
        matching: find.byWidgetPredicate((w) => w is Semantics),
      ).first;

  testWidgets('nothing is chosen until a chip is tapped, and a place and a '
      'kind together choose what fits both', (tester) async {
    await pump(tester);

    expect(find.text(tr.xtream.watch.title), findsOneWidget);
    expect(find.text(tr.xtream.watch.none), findsOneWidget);
    // DE and Germany are one place.
    expect(find.text(tr.xtream.regions['de']!), findsOneWidget);
    // The one name that says no place is pointed at Fine-tune, not lost.
    expect(find.text(tr.xtream.watch.unplaced(n: 1)), findsOneWidget);

    await tester.tap(chip(tr.xtream.regions['de']!));
    await tester.pumpAndSettle();
    expect(find.text(tr.xtream.watch.count(n: 3)), findsOneWidget);

    await tester.tap(chip(tr.xtream.kinds['sport']!));
    await tester.pumpAndSettle();
    expect(find.text(tr.xtream.watch.count(n: 1)), findsOneWidget);

    await tester.tap(find.text(tr.xtream.watch.next));
    await tester.pumpAndSettle();
    expect(saved.single.liveCategoryIds, ['3']);
    expect(find.text('open'), findsOneWidget, reason: 'out of setup it pops');
  });

  testWidgets('Fine-tune is the list; Back returns to the chips, and a chip '
      'after a hand edit asks before replacing it', (tester) async {
    await pump(tester);
    await tester.tap(chip(tr.xtream.regions['uk']!));
    await tester.pumpAndSettle();

    await tester.tap(find.text(tr.xtream.watch.fineTune));
    await tester.pumpAndSettle();
    expect(find.text(tr.xtream.watch.title), findsNothing);
    // The group list, as before: DE's two categories make a group.
    expect(find.text('DE'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text(tr.xtream.watch.title), findsOneWidget,
        reason: 'Back leaves Fine-tune, not the screen');

    // A hand edit: into Fine-tune, open a group, tick a category.
    await tester.tap(find.text(tr.xtream.watch.fineTune));
    await tester.pumpAndSettle();
    await tester.tap(find.text('DE'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kids'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(tr.xtream.watch.chips));
    await tester.pumpAndSettle();

    await tester.tap(chip(tr.xtream.regions['de']!));
    await tester.pumpAndSettle();
    expect(find.text(tr.xtream.watch.replaceTitle), findsOneWidget);
    await tester.tap(find.text(tr.xtream.watch.keep));
    await tester.pumpAndSettle();
    // Kept: UK Sport plus the hand-ticked DE Kids.
    expect(find.text(tr.xtream.watch.count(n: 2)), findsOneWidget);
  });

  testWidgets('a choice made earlier opens on the list, as before',
      (tester) async {
    await pump(tester, chosen: const ['1']);
    expect(find.text(tr.xtream.watch.title), findsNothing);
    expect(find.text(tr.xtream.picker.chosen(n: 1)), findsOneWidget);
  });
}

class _Saving extends XtreamAccountsController {
  _Saving(this.account, this.saved);

  final XtreamAccount account;
  final List<XtreamAccount> saved;

  @override
  List<XtreamAccount> build() => [account];

  @override
  Future<void> save(XtreamAccount account, {String? password}) async {
    saved.add(account);
    state = [account];
  }
}

class _NoHiddenWords extends HiddenWordsController {
  @override
  List<String> build() => const [];
}
