import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relay_player/core/theme/relay_widgets.dart';

import 'dpad_audit.dart';

/// The audit's own controls: each rule fails on a screen built to break it.
///
/// Without these, a rule that could never fail would pass every screen and
/// look like good news. Each broken screen below is a defect this app has
/// actually shipped (architecture.md §11, and the 2026-09-28 Chromecast
/// session), and each good screen shows the rule passes when it should.
void main() {
  Widget column(List<Widget> children) => Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(children: children),
        ),
      );

  group('first press', () {
    testWidgets('fails when nothing can take focus', (tester) async {
      // A GestureDetector has no focus node: the library grid's old defect.
      await DpadAudit.pumpTv(
        tester,
        column([GestureDetector(onTap: () {}, child: const Text('tap only'))]),
      );
      expect(await DpadAudit(tester).firstPressFocuses(), isFalse);
    });

    testWidgets('passes when a press lands on something', (tester) async {
      await DpadAudit.pumpTv(
        tester,
        column([RelayTappable(onTap: () {}, child: const Text('reachable'))]),
      );
      await DpadAudit(tester).expectFirstPressFocuses();
    });
  });

  group('reachability', () {
    testWidgets('fails for a stop nested inside another stop',
        (tester) async {
      // The favourite star inside a channel row, before 2026-09-28.
      await DpadAudit.pumpTv(
        tester,
        column([
          RelayTappable(
            onTap: () {},
            child: Row(children: [
              const Expanded(child: Text('row')),
              IconButton(
                  tooltip: 'star', onPressed: () {}, icon: const Icon(Icons.star)),
            ]),
          ),
        ]),
      );
      expect(await DpadAudit(tester).unreachable(), ['star']);
    });

    testWidgets('passes when the stop sits beside it', (tester) async {
      await DpadAudit.pumpTv(
        tester,
        column([
          Row(children: [
            Expanded(
                child: RelayTappable(onTap: () {}, child: const Text('row'))),
            IconButton(
                tooltip: 'star', onPressed: () {}, icon: const Icon(Icons.star)),
          ]),
        ]),
      );
      await DpadAudit(tester).expectAllReachable();
    });
  });

  group('visible focus', () {
    testWidgets('fails for a bare InkWell', (tester) async {
      // The Add source rows before 2026-09-28.
      await DpadAudit.pumpTv(
        tester,
        column([InkWell(onTap: () {}, child: const Text('invisible'))]),
      );
      expect(await DpadAudit(tester).invisibleFocus(), ['invisible']);
    });

    testWidgets('fails for a FilledButton with this theme', (tester) async {
      // RelayButton before 2026-09-28: Verify and add looked unfocused.
      await DpadAudit.pumpTv(
        tester,
        column([FilledButton(onPressed: () {}, child: const Text('plain'))]),
      );
      expect(await DpadAudit(tester).invisibleFocus(), ['plain']);
    });

    testWidgets('passes for RelayTappable, RelayButton and a halo',
        (tester) async {
      await DpadAudit.pumpTv(
        tester,
        column([
          RelayTappable(onTap: () {}, child: const Text('tappable')),
          RelayButton(label: 'button', onPressed: () {}),
          RelayFocusHalo(
            child: IconButton(
                tooltip: 'star', onPressed: () {}, icon: const Icon(Icons.star)),
          ),
        ]),
      );
      await DpadAudit(tester).expectFocusVisible();
    });
  });

  group('text fields', () {
    testWidgets('fail to let go without RelayFieldTraversal', (tester) async {
      // Every field in the app before 2026-09-28 (flutter/flutter#49335).
      await DpadAudit.pumpTv(
        tester,
        column([
          const TextField(),
          RelayButton(label: 'below', onPressed: () {}),
        ]),
      );
      expect(await DpadAudit(tester).trappingFields(), hasLength(1));
    });

    testWidgets('let go with it', (tester) async {
      await DpadAudit.pumpTv(
        tester,
        column([
          const RelayFieldTraversal(child: TextField()),
          RelayButton(label: 'below', onPressed: () {}),
        ]),
      );
      await DpadAudit(tester).expectFieldsEscapable();
    });
  });
}
