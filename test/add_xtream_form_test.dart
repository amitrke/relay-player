import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relay_player/core/theme/relay_theme.dart';
import 'package:relay_player/core/theme/relay_tokens.dart';
import 'dart:async';

import 'package:relay_player/data/xtream/xtream_client.dart';
import 'package:relay_player/features/advanced_sources/add_xtream_screen.dart';
import 'package:relay_player/features/advanced_sources/xtream_controller.dart';

/// The add-a-line form with a remote, as found on the Chromecast 2026-09-28:
/// typing worked, but focus could not reach *Verify and add*, and one Back too
/// many threw the form away.
///
/// No text is ever sent anywhere: *Verify and add* is never pressed. The
/// on-screen keyboard is absent in widget tests, which is the state these
/// cases are about: arrows arriving at Flutter because nothing above it took
/// them.
/// A panel check the test finishes when it chooses, so the form's busy state
/// is drawn for real frames. No request is ever made.
class _HeldClient extends XtreamClient {
  _HeldClient(this.result)
      : super(host: 'http://panel-host.example.invalid', username: '', password: '');

  final Completer<XtreamAccountInfo> result;

  @override
  Future<XtreamAccountInfo> authenticate() => result.future;
}

void main() {
  Future<void> pump(WidgetTester tester, {List overrides = const []}) async {
    tester.view.physicalSize = const Size(960, 540);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(ProviderScope(
      overrides: [...overrides],
      child: MaterialApp(
        home: RelayTheme(
          tokens: RelayPalettes.midnight,
          palette: RelayPalette.midnight,
          child: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => RelayTheme(
                        tokens: RelayPalettes.midnight,
                        palette: RelayPalette.midnight,
                        child: const AddXtreamScreen(),
                      ),
                    ),
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Finder field(String label) => find.descendant(
        of: find.ancestor(of: find.text(label), matching: find.byType(Column)).first,
        matching: find.byType(EditableText),
      );

  bool focusIsOn(Finder target) {
    final focused = FocusManager.instance.primaryFocus?.context;
    if (focused == null) return false;
    final targetElement = target.evaluate().single;
    var hit = false;
    focused.visitAncestorElements((e) {
      if (e == targetElement) hit = true;
      return !hit;
    });
    return hit || focused == targetElement;
  }

  final verify = find.widgetWithText(FilledButton, 'Verify and add');

  testWidgets('Down from the last field reaches Verify and add',
      (tester) async {
    await pump(tester);
    await tester.showKeyboard(field('Name (optional)'));
    await tester.enterText(field('Name (optional)'), 'x');
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(focusIsOn(verify), isTrue);
  });

  testWidgets('Up and Down walk between fields', (tester) async {
    await pump(tester);
    await tester.showKeyboard(field('Username'));
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    expect(focusIsOn(field('Server address')), isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(focusIsOn(field('Username')), isTrue);
  });

  testWidgets('Done on the last field lands on Verify and add, not nowhere',
      (tester) async {
    await pump(tester);
    await tester.showKeyboard(field('Name (optional)'));
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(focusIsOn(verify), isTrue);
  });

  // Checked with a control: it fails with the button swapped for a spinner
  // while busy, as it was until 2026-09-28. It does not fail with the
  // button's key removed, although the TV emulator lost focus without the key
  // (architecture.md §11); that half rests on the emulator runs alone.
  testWidgets('focus stays on Verify and add through a failed check',
      (tester) async {
    final check = Completer<XtreamAccountInfo>();
    await pump(tester, overrides: [
      xtreamClientFactoryProvider.overrideWithValue(
          ({required host, required username, required password}) =>
              _HeldClient(check)),
    ]);
    await tester.showKeyboard(field('Name (optional)'));
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(focusIsOn(verify), isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pump();
    expect(find.text('Checking…'), findsOneWidget,
        reason: 'the busy state must be drawn for this to test it');
    expect(focusIsOn(find.widgetWithText(FilledButton, 'Checking…')), isTrue,
        reason: 'busy must not take the button, and its focus, away');

    check.completeError(const XtreamException('The panel refused the login.'));
    await tester.pumpAndSettle();
    expect(find.text('The panel refused the login.'), findsOneWidget);
    expect(focusIsOn(verify), isTrue,
        reason: 'the error box inserted above must not take focus either');
  });

  group('Back', () {
    testWidgets('with nothing typed, leaves', (tester) async {
      await pump(tester);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('open'), findsOneWidget);
    });

    testWidgets('with something typed, asks; Keep editing keeps it',
        (tester) async {
      await pump(tester);
      await tester.enterText(field('Server address'), 'panel-host.example.invalid');
      // One frame, as on a device, so the form has rebuilt with its new
      // canPop before Back arrives.
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.text('Discard this line?'), findsOneWidget);
      // Initial focus is on the safe choice, so a second slip keeps the form.
      expect(focusIsOn(find.widgetWithText(FilledButton, 'Keep editing')),
          isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.select);
      await tester.pumpAndSettle();

      expect(find.text('Discard this line?'), findsNothing);
      expect(find.text('panel-host.example.invalid'), findsOneWidget);
    });

    testWidgets('with something typed, Discard leaves', (tester) async {
      await pump(tester);
      await tester.enterText(field('Username'), 'someone');
      // One frame, as on a device, so the form has rebuilt with its new
      // canPop before Back arrives.
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();
      expect(find.text('open'), findsOneWidget);
    });
  });
}
