import 'package:flutter/material.dart';

import '../../core/theme/relay_theme.dart';
import '../../core/theme/relay_widgets.dart';
import '../../data/transfer/transfer_bundle.dart';

/// The frame both transfer screens share: a back arrow, a title, and a column
/// that scrolls on a phone and stays put on a TV.
class TransferScaffold extends StatelessWidget {
  const TransferScaffold({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);
    final f = RelayLayout.of(context);
    return Scaffold(
      backgroundColor: t.bg,
      appBar: AppBar(
        backgroundColor: t.bg,
        surfaceTintColor: Colors.transparent,
        foregroundColor: t.ink,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: RelayLayout.pagePadding(
              f,
            ).add(const EdgeInsets.symmetric(vertical: 16)),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: t.ink,
                      fontSize: RelayLayout.titleSize(f),
                      fontWeight: FontWeight.w700,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ...children,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Body text in the transfer screens' one reading size.
class TransferText extends StatelessWidget {
  const TransferText(this.text, {super.key, this.dim = true, this.bold = false});

  final String text;
  final bool dim;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);
    final f = RelayLayout.of(context);
    return Text(
      text,
      style: TextStyle(
        color: dim ? t.inkDim : t.ink,
        fontSize: RelayLayout.bodySize(f),
        fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
        height: 1.55,
      ),
    );
  }
}

/// One tickable row per kind of thing in a bundle, with what is in it.
///
/// Rows toggle on select, so a remote can untick "Network shares" without a
/// pointer. [describe] must not return anything secret (hosts, usernames,
/// keys): on the receiving side this is on a TV across the room.
class TransferChecklist extends StatelessWidget {
  const TransferChecklist({
    super.key,
    required this.items,
    required this.selected,
    required this.describe,
    required this.onToggle,
  });

  final List<TransferItem> items;
  final Set<TransferItem> selected;
  final String Function(TransferItem) describe;
  final ValueChanged<TransferItem> onToggle;

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);
    final f = RelayLayout.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, item) in items.indexed) ...[
          RelaySurface(
            autofocus: i == 0,
            onTap: () => onToggle(item),
            borderColor: selected.contains(item) ? t.accent : null,
            child: Row(
              children: [
                Icon(
                  selected.contains(item)
                      ? Icons.check_circle
                      : Icons.circle_outlined,
                  color: selected.contains(item) ? t.accent : t.inkDim,
                  size: 22,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${item.label} · ${describe(item)}',
                        style: TextStyle(
                          color: t.ink,
                          fontSize: RelayLayout.bodySize(f) + 1,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.description,
                        style: TextStyle(
                          color: t.inkDim,
                          fontSize: RelayLayout.bodySize(f) - 1,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

/// A message that something went wrong, in the app's one error style.
class TransferError extends StatelessWidget {
  const TransferError(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);
    return RelaySurface(
      borderColor: const Color(0xFFB8574E),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFB8574E), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: t.ink, fontSize: 13.5, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}

/// A line of progress with a spinner, for the waiting states.
class TransferBusy extends StatelessWidget {
  const TransferBusy(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);
    return Row(
      children: [
        SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: t.accent),
        ),
        const SizedBox(width: 14),
        Expanded(child: TransferText(label, dim: false)),
      ],
    );
  }
}
