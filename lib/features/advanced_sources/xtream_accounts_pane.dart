import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/relay_theme.dart';
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
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account.name,
                        style: TextStyle(
                          color: t.ink,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        account.selectedCategoryIds.isEmpty
                            ? 'No categories chosen'
                            : '${account.selectedCategoryIds.length} '
                                'categories',
                        style: TextStyle(color: t.inkDim, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => context.push(
                    '/advanced/xtream/${account.id}/categories',
                  ),
                  child: Text('Categories',
                      style: TextStyle(color: t.accent, fontSize: 13)),
                ),
                IconButton(
                  tooltip: 'Remove',
                  icon: Icon(Icons.delete_outline, color: t.inkDim, size: 20),
                  onPressed: () => ref
                      .read(xtreamAccountsProvider.notifier)
                      .remove(account.id),
                ),
              ],
            ),
          ),
        TextButton.icon(
          onPressed: () => context.push('/advanced/xtream/new'),
          icon: Icon(Icons.add, size: 18, color: t.accent),
          label: Text(
            'Add a playlist or panel',
            style: TextStyle(color: t.accent),
          ),
        ),
      ],
    );
  }
}
