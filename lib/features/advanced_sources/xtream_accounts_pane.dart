import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/relay_theme.dart';
import '../../core/theme/relay_widgets.dart';
import '../../data/xtream/xtream_account_store.dart';
import 'xtream_controller.dart';

/// The configured lines, shown under Settings → Advanced sources.
///
/// §12.1: turning the gate off preserves configured accounts. This renders
/// nothing when the gate is off — it does not delete anything, and the accounts
/// reappear intact if the user turns it back on.
class XtreamAccountsPane extends ConsumerWidget {
  const XtreamAccountsPane({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = RelayTheme.of(context);
    final accounts = ref.watch(xtreamAccountsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final account in accounts)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
            decoration: BoxDecoration(
              color: t.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: t.line),
            ),
            // Two lines, not one Row. Until 2026-09-28 the name shared a Row
            // with the three category buttons and the remove button, all at
            // their natural width. On a phone they left the name's Expanded
            // about one glyph wide, so a name that defaulted to the server
            // address wrapped one character per line down the whole screen.
            // The buttons now get their own line, in a Wrap so a large text
            // scale pushes one down rather than overflowing, and the name
            // keeps the full width, cut to one line.
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            account.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: t.ink,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            [
                              for (final c in XtreamCatalogue.values)
                                '${c.label} ${account.categoriesFor(c).length}',
                            ].join(' · '),
                            style: TextStyle(color: t.inkDim, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    // The halos on this pane's Material buttons are their focus rings on a TV;
                    // without them focus was invisible here (D-pad audit, test/dpad, 2026-09-28).
                    RelayFocusHalo(
                      borderRadius: BorderRadius.circular(10),
                      child: IconButton(
                        tooltip: 'Remove',
                        icon: Icon(Icons.delete_outline,
                            color: t.inkDim, size: 20),
                        onPressed: () => ref
                            .read(xtreamAccountsProvider.notifier)
                            .remove(account.id),
                      ),
                    ),
                  ],
                ),
                Wrap(
                  children: [
                    for (final c in XtreamCatalogue.values)
                      RelayFocusHalo(
                        borderRadius: BorderRadius.circular(10),
                        child: TextButton(
                          onPressed: () => context.push(
                            '/advanced/xtream/${account.id}/categories/${c.name}',
                          ),
                          child: Text(c.label,
                              style: TextStyle(color: t.accent, fontSize: 13)),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        RelayFocusHalo(
          borderRadius: BorderRadius.circular(10),
          child: TextButton.icon(
            onPressed: () => context.push('/advanced/xtream/new'),
            icon: Icon(Icons.add, size: 18, color: t.accent),
            label: Text(
              'Add a playlist or panel',
              style: TextStyle(color: t.accent),
            ),
          ),
        ),
      ],
    );
  }
}
