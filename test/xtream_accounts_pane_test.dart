import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relay_player/core/theme/relay_theme.dart';
import 'package:relay_player/core/theme/relay_tokens.dart';
import 'package:relay_player/data/xtream/xtream_account_store.dart';
import 'package:relay_player/features/advanced_sources/xtream_accounts_pane.dart';
import 'package:relay_player/features/advanced_sources/xtream_controller.dart';

/// Stands in for the real controller so the pane can be pumped without the
/// settings store behind it.
class _FixedAccounts extends XtreamAccountsController {
  _FixedAccounts(this._accounts);
  final List<XtreamAccount> _accounts;

  @override
  List<XtreamAccount> build() => _accounts;
}

/// The account row under Settings → Advanced sources, at phone width.
///
/// Found on a phone 2026-09-28: the name shared one Row with three category
/// buttons and a remove button, and was left about one glyph wide, so a name
/// that defaulted to the server address ran one character per line down the
/// screen. Release builds draw that without complaint; this measures it.
void main() {
  // A long name, shaped like the server-address default. Placeholder host, per
  // the no-provider rule in CLAUDE.md.
  const name = 'http://panel-host.example.invalid:8080';

  Future<void> pump(WidgetTester tester, {double width = 390}) async {
    tester.view.physicalSize = Size(width, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        xtreamAccountsProvider.overrideWith(() => _FixedAccounts(const [
              XtreamAccount(
                id: '1',
                name: name,
                host: 'http://panel-host.example.invalid:8080',
                username: 'user',
              ),
            ])),
      ],
      child: MaterialApp(
        home: RelayTheme(
          tokens: RelayPalettes.midnight,
          palette: RelayPalette.midnight,
          child: const Scaffold(
            body: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: XtreamAccountsPane(),
            ),
          ),
        ),
      ),
    ));
  }

  testWidgets('the name keeps one line at phone width', (tester) async {
    await pump(tester);

    final nameBox = tester.getSize(find.text(name));
    // Under two lines of its 14.5 px type. Not measured against the counts
    // line beneath it: in the broken layout that was squeezed into the same
    // sliver and wrapped too, so it made a poor ruler. The broken name was
    // 798 px tall.
    expect(nameBox.height, lessThan(14.5 * 2));
    // And it has real width to use, not the sliver left beside the buttons.
    expect(nameBox.width, greaterThan(200));
    expect(tester.takeException(), isNull);
  });

  testWidgets('every action stays reachable', (tester) async {
    await pump(tester);
    for (final label in ['Live TV', 'Movies', 'Series']) {
      expect(find.widgetWithText(TextButton, label), findsOneWidget);
    }
    expect(find.byTooltip('Remove'), findsOneWidget);
  });

  testWidgets('a narrow phone at a large text scale does not overflow',
      (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pump(tester, width: 320);
    expect(tester.takeException(), isNull);
  });
}
