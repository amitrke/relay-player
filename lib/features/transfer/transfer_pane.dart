import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/relay_theme.dart';
import '../../core/theme/relay_widgets.dart';
import '../../i18n/strings.g.dart';

/// Settings -> Move to another device (§17).
///
/// The way to set up a TV without typing on it: do the setup once on a phone,
/// then send it. Two doors, one for each end of the transfer.
class TransferPane extends StatelessWidget {
  const TransferPane({super.key});

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);
    final style = TextStyle(color: t.inkDim, fontSize: 13.5, height: 1.6);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr.transfer.pane.explain,
          style: style,
        ),
        const SizedBox(height: 14),
        Text(
          tr.transfer.pane.notCopied,
          style: style,
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 12,
          runSpacing: 10,
          children: [
            RelayButton(
              label: tr.transfer.pane.receive,
              onPressed: () => context.push('/transfer/receive'),
            ),
            RelayButton(
              label: tr.transfer.pane.send,
              onPressed: () => context.push('/transfer/send'),
            ),
          ],
        ),
      ],
    );
  }
}
