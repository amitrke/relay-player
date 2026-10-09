import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/relay_theme.dart';
import '../../core/theme/relay_widgets.dart';

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
          'Copy your sources, keys and preferences to another device on the '
          'same Wi-Fi, so you do not have to type them again. It goes straight '
          'from one device to the other, encrypted with a code that only the '
          'two screens share, and the receiving device asks before it saves '
          'anything.',
          style: style,
        ),
        const SizedBox(height: 14),
        Text(
          'Not copied: Plex (link it on the other device with its own code), '
          'watch history, favourites, and the consent you gave for Advanced '
          'sources and AI features, which each device asks for itself.',
          style: style,
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 12,
          runSpacing: 10,
          children: [
            RelayButton(
              label: 'Receive from another device',
              onPressed: () => context.push('/transfer/receive'),
            ),
            RelayButton(
              label: 'Send to another device',
              onPressed: () => context.push('/transfer/send'),
            ),
          ],
        ),
      ],
    );
  }
}
