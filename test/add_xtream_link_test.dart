import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:relay_player/core/platform/device_kind.dart';
import 'package:relay_player/core/theme/relay_theme.dart';
import 'package:relay_player/core/theme/relay_tokens.dart';
import 'package:relay_player/data/xtream/xtream_account_store.dart';
import 'package:relay_player/data/xtream/xtream_client.dart';
import 'package:relay_player/features/advanced_sources/add_xtream_screen.dart';
import 'package:relay_player/features/advanced_sources/connected_screen.dart';
import 'package:relay_player/features/advanced_sources/xtream_controller.dart';
import 'package:relay_player/i18n/strings.g.dart';

/// Setting up from the one link a provider sends (2026-11-03): the link is
/// taken apart on screen before anything is sent, the check is made with
/// exactly those parts, and step 2 says what the provider answered. Made-up
/// hosts and logins only (CLAUDE.md §1); nothing reaches a network.
void main() {
  late List<(String, String, String)> checked;
  late List<XtreamAccount> saved;

  Future<void> pump(WidgetTester tester, XtreamAccountInfo answer) async {
    DeviceKind.debugSetTelevision(false);
    tester.view.physicalSize = const Size(420, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    checked = [];
    saved = [];

    final router = GoRouter(
      initialLocation: '/advanced/xtream/new',
      routes: [
        GoRoute(
          path: '/advanced/xtream/new',
          builder: (_, _) => const AddXtreamScreen(),
        ),
        GoRoute(
          path: '/advanced/xtream/:id/connected',
          builder: (_, state) => ConnectedScreen(
            accountId: state.pathParameters['id']!,
            info: state.extra as XtreamAccountInfo?,
          ),
        ),
      ],
    );
    await tester.pumpWidget(ProviderScope(
      overrides: [
        xtreamClientFactoryProvider.overrideWithValue(
          ({required host, required username, required password}) {
            checked.add((host, username, password));
            return _Answering(answer);
          },
        ),
        xtreamAccountsProvider.overrideWith(() => _Saving(saved)),
        xtreamCategoriesProvider.overrideWith((ref, _) async => const [
              XtreamCategory(id: '1', name: 'News'),
              XtreamCategory(id: '2', name: 'Sport'),
            ]),
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
    await tester.pumpAndSettle();
  }

  Finder linkField() => find.descendant(
        of: find
            .ancestor(
                of: find.text(tr.xtream.addLine.link),
                matching: find.byType(Column))
            .first,
        matching: find.byType(EditableText),
      );

  const link = 'http://panel-host.example:8080/get.php?username=demo'
      '&password=s3cret&type=m3u_plus';

  testWidgets('a pasted link is shown taken apart, checked with those parts, '
      'and step 2 says what the provider answered', (tester) async {
    await pump(
      tester,
      XtreamAccountInfo(
        status: 'Active',
        isTrial: false,
        maxConnections: 1,
        activeConnections: 0,
        expiresAt: DateTime.utc(2027, 3, 14),
        outputFormats: const ['m3u8', 'ts'],
      ),
    );

    // Off a TV the link is the starting choice.
    expect(linkField(), findsOneWidget);
    await tester.enterText(linkField(), link);
    await tester.pumpAndSettle();

    expect(find.text(tr.xtream.addLine.found), findsOneWidget);
    expect(find.text('http://panel-host.example:8080'), findsOneWidget);
    expect(find.text('demo'), findsOneWidget);
    expect(find.text('s3cret'), findsNothing,
        reason: 'the password stays hidden until asked for');

    await tester.tap(find.text(tr.xtream.addLine.verify));
    await tester.pumpAndSettle();

    expect(checked, [('http://panel-host.example:8080', 'demo', 's3cret')]);
    expect(saved.single.username, 'demo');
    // Not the host: the provider's address never becomes the label (§1).
    expect(saved.single.name, tr.xtream.addLine.defaultName);

    expect(find.text(tr.xtream.connected.title), findsOneWidget);
    expect(find.text(tr.xtream.connected.oneScreen), findsOneWidget);
    expect(find.text(tr.xtream.connected.liveCategories(n: 2)), findsOneWidget);
  });

  testWidgets('a link without a login is said so, and nothing is sent',
      (tester) async {
    await pump(
      tester,
      const XtreamAccountInfo(
        status: 'Active',
        isTrial: false,
        maxConnections: 2,
        activeConnections: 0,
        expiresAt: null,
        outputFormats: [],
      ),
    );
    await tester.enterText(linkField(), 'http://panel-host.example:8080');
    await tester.pumpAndSettle();
    expect(find.text(tr.xtream.addLine.notALink), findsOneWidget);

    await tester.tap(find.text(tr.xtream.addLine.verify));
    await tester.pumpAndSettle();
    expect(checked, isEmpty);
    expect(saved, isEmpty);
  });
}

class _Answering extends XtreamClient {
  _Answering(this.answer)
      : super(host: 'http://panel-host.example', username: '', password: '');

  final XtreamAccountInfo answer;

  @override
  Future<XtreamAccountInfo> authenticate() async => answer;
}

/// Saves in memory: the real store writes to Hive and secure storage.
class _Saving extends XtreamAccountsController {
  _Saving(this.saved);

  final List<XtreamAccount> saved;

  @override
  List<XtreamAccount> build() => const [];

  @override
  Future<void> save(XtreamAccount account, {String? password}) async {
    saved.add(account);
    state = [...state, account];
  }
}
