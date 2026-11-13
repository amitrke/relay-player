import 'package:flutter/material.dart';

import '../../core/theme/relay_theme.dart';
import '../../i18n/strings.g.dart';

/// "Step n of 3" and a thin bar, across the three screens of setting up an
/// IPTV subscription: connect, check, choose (2026-11-03).
///
/// It exists because the three screens were not visibly one task: the form
/// ended in a category list with no sense of how much was left, and leaving
/// it looked like finishing. Three, and not a count of screens, because Fine-
/// tune and the review are optional detours, not steps.
class SetupSteps extends StatelessWidget {
  const SetupSteps({super.key, required this.step});

  /// 1 to 3.
  final int step;

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr.xtream.setup.step(n: step),
          style: TextStyle(color: t.inkDim, fontSize: 12.5),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (var i = 1; i <= 3; i++) ...[
              if (i > 1) const SizedBox(width: 6),
              Expanded(
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: i <= step ? t.accent : t.line,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
