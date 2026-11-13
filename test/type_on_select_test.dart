import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relay_player/core/platform/device_kind.dart';
import 'package:relay_player/core/theme/relay_theme.dart';
import 'package:relay_player/core/theme/relay_tokens.dart';
import 'package:relay_player/core/theme/relay_widgets.dart';

/// A search field a remote passes through opens no keyboard on a TV until
/// OK (RelayTypeOnSelect, 2026-11-01). Reported on Live TV: walking from
/// the tabs to the channels with the D-pad landed on the search box, and
/// the keyboard came up over the screen.
///
/// The test text input stands for the keyboard: a field with an input
/// connection is a client of it, and Flutter shows the keyboard when it
/// opens one.
void main() {
  Future<void> pump(WidgetTester tester, {required Size size}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: RelayTheme(
          tokens: RelayPalettes.midnight,
          palette: RelayPalette.midnight,
          child: Scaffold(
            body: Column(
              children: [
                RelayButton(label: 'Above', autofocus: true, onPressed: () {}),
                RelayTypeOnSelect(
                  builder: (context, readOnly, onTap) => TextField(
                    readOnly: readOnly,
                    onTap: onTap,
                    decoration: const InputDecoration(hintText: 'Search'),
                  ),
                ),
                RelayButton(label: 'Below', onPressed: () {}),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  bool fieldFocused(WidgetTester tester) => tester
      .widget<EditableText>(find.byType(EditableText))
      .focusNode
      .hasFocus;

  group('TV', () {
    setUp(() => DeviceKind.debugSetTelevision(true));
    tearDown(() => DeviceKind.debugSetTelevision(false));

    testWidgets('passing over the field opens no keyboard; OK does', (
      tester,
    ) async {
      await pump(tester, size: const Size(960, 540));
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(fieldFocused(tester), isTrue);
      expect(tester.testTextInput.hasAnyClients, isFalse);

      // Down goes on past it, as the remote was trying to.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(fieldFocused(tester), isFalse);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.select);
      await tester.pumpAndSettle();
      expect(tester.testTextInput.hasAnyClients, isTrue);
      expect(tester.testTextInput.isVisible, isTrue);
      await tester.enterText(find.byType(TextField), 'news');
      expect(find.text('news'), findsOneWidget);
    });

    testWidgets('leaving the field makes it pass-through again', (
      tester,
    ) async {
      await pump(tester, size: const Size(960, 540));
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.select);
      await tester.pumpAndSettle();
      expect(tester.testTextInput.hasAnyClients, isTrue);

      tester.testTextInput.hide();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(fieldFocused(tester), isFalse);
      expect(tester.testTextInput.hasAnyClients, isFalse);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
      expect(fieldFocused(tester), isTrue);
      expect(tester.testTextInput.hasAnyClients, isFalse);
    });
  });

  // The control: off a TV a focused field opens its keyboard at once, as it
  // always did; that is the behaviour the TV case removes.
  testWidgets('on a phone, focusing the field opens the keyboard', (
    tester,
  ) async {
    await pump(tester, size: const Size(390, 844));
    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();
    expect(tester.testTextInput.hasAnyClients, isTrue);
  });
}
