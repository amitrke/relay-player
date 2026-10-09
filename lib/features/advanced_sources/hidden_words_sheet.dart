import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/relay_theme.dart';
import '../../core/theme/relay_widgets.dart';
import 'hidden_words_controller.dart';

/// The editor for the hidden words: add one, take one away.
///
/// A sheet of [RelayTappable]s, like the Library's sort sheet, so a remote can
/// reach every control with a visible ring. [onAdded] is told the entry that was
/// just added, which is how the category screen un-ticks what it now hides.
Future<void> showHiddenWordsSheet(
  BuildContext context, {
  void Function(String added)? onAdded,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: RelayTheme.of(context).surface,
    builder: (_) => _HiddenWordsSheet(onAdded: onAdded),
  );
}

class _HiddenWordsSheet extends ConsumerStatefulWidget {
  const _HiddenWordsSheet({this.onAdded});

  final void Function(String added)? onAdded;

  @override
  ConsumerState<_HiddenWordsSheet> createState() => _HiddenWordsSheetState();
}

class _HiddenWordsSheetState extends ConsumerState<_HiddenWordsSheet> {
  final _field = TextEditingController();

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final added = await ref.read(hiddenWordsProvider.notifier).add(_field.text);
    if (added == null) return;
    _field.clear();
    widget.onAdded?.call(added);
  }

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);
    final f = RelayLayout.of(context);
    final words = ref.watch(hiddenWordsProvider);
    final size = f == RelayFormFactor.tv ? 15.0 : 13.0;

    return SafeArea(
      child: Padding(
        // Lifts the sheet clear of the on-screen keyboard.
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hide words',
                style: TextStyle(
                  color: t.ink,
                  fontSize: RelayLayout.bodySize(f) + 2,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'A category or channel with any of these as a whole word is left '
                'out of the lists. "UK" hides "UK News" and not "Ukraine". Add '
                'a phrase such as "south indian" to hide it as one thing. Case '
                'does not matter.',
                style: TextStyle(color: t.inkDim, fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: RelayFieldTraversal(
                      child: TextField(
                        controller: _field,
                        autocorrect: false,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _add(),
                        style: TextStyle(color: t.ink),
                        decoration: InputDecoration(
                          hintText: 'A country, a language, a word',
                          hintStyle: TextStyle(color: t.inkDim),
                          filled: true,
                          fillColor: t.bg,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: t.line),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: t.line),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: t.accent),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  RelayButton(label: 'Add', onPressed: _add),
                ],
              ),
              const SizedBox(height: 16),
              if (words.isEmpty)
                Text(
                  'Nothing hidden yet.',
                  style: TextStyle(color: t.inkDim, fontSize: 13),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final w in words)
                      RelayTappable(
                        borderRadius: 20,
                        onTap: () =>
                            ref.read(hiddenWordsProvider.notifier).remove(w),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: t.accent.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: t.accent),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                w,
                                style: TextStyle(
                                  color: t.ink,
                                  fontSize: size,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.close,
                                size: size + 2,
                                color: t.inkDim,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              if (words.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Select a word to stop hiding it.',
                  style: TextStyle(color: t.inkDim, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
