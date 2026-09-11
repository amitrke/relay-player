import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/relay_theme.dart';
import '../../core/theme/relay_tokens.dart';
import '../../core/theme/relay_widgets.dart';
import '../../data/xtream/xtream_account_store.dart';
import '../../data/xtream/xtream_client.dart';
import 'xtream_controller.dart';

/// §4.1 — choose which categories to keep, before any stream list is fetched.
///
/// The ordering is the whole point: categories are small, stream lists are not
/// (Phase 0 measured 5.3 MB live / 26.2 MB VOD on a real panel). Selecting here
/// means the bulk is never transferred, so the saving is bandwidth and memory,
/// not just storage.
///
/// Selection is **opt-in**. With 706 categories on a real panel, defaulting to
/// everything would download the exact payload this design exists to avoid —
/// and would open on a screen full of brand-named categories, which §1.6 calls
/// out as a store-screenshot hazard.
class CategoryPickerScreen extends ConsumerStatefulWidget {
  const CategoryPickerScreen({
    super.key,
    required this.accountId,
    required this.catalogue,
  });

  final String accountId;
  final XtreamCatalogue catalogue;

  @override
  ConsumerState<CategoryPickerScreen> createState() =>
      _CategoryPickerScreenState();
}

class _CategoryPickerScreenState extends ConsumerState<CategoryPickerScreen> {
  final _search = TextEditingController();
  final _pattern = TextEditingController();

  Set<String>? _selected;
  String _query = '';
  String? _patternError;

  @override
  void dispose() {
    _search.dispose();
    _pattern.dispose();
    super.dispose();
  }

  XtreamAccount? get _account {
    for (final account in ref.read(xtreamAccountsProvider)) {
      if (account.id == widget.accountId) return account;
    }
    return null;
  }

  /// Applies [_pattern] to the selection rather than replacing it (§4.1): a
  /// bulk selector acts on what is already chosen, and the user sees the
  /// resulting checkboxes before committing.
  void _applyPattern(List<XtreamCategory> categories, {required bool select}) {
    final raw = _pattern.text.trim();
    if (raw.isEmpty) return;

    bool Function(String) matches;
    try {
      final regex = RegExp(raw, caseSensitive: false);
      matches = (name) => regex.hasMatch(name);
    } on FormatException {
      // An invalid pattern must never fail anything — it matches nothing and
      // says so (§4.1).
      final lower = raw.toLowerCase();
      matches = (name) => name.toLowerCase().contains(lower);
    }

    final next = {..._current};
    var hits = 0;
    for (final category in categories) {
      if (!matches(category.name)) continue;
      hits++;
      if (select) {
        next.add(category.id);
      } else {
        next.remove(category.id);
      }
    }
    setState(() {
      _selected = next;
      _patternError = hits == 0 ? 'That pattern matched nothing.' : null;
    });
  }

  Set<String> get _current =>
      _selected ?? {...?_account?.categoriesFor(widget.catalogue)};

  Future<void> _save() async {
    final account = _account;
    if (account == null) return;
    await ref.read(xtreamAccountsProvider.notifier).save(
          account.withCategories(widget.catalogue, _current.toList()),
        );
    if (mounted) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);
    final f = RelayLayout.of(context);
    final account = _account;

    if (account == null) {
      return Scaffold(
        backgroundColor: t.bg,
        appBar: AppBar(backgroundColor: t.bg, foregroundColor: t.ink),
        body: const Center(child: Text('That line is no longer configured.')),
      );
    }

    final categories = ref.watch(xtreamCategoriesProvider((account, widget.catalogue)));

    return Scaffold(
      backgroundColor: t.bg,
      appBar: AppBar(
        backgroundColor: t.bg,
        surfaceTintColor: Colors.transparent,
        foregroundColor: t.ink,
        title: Text('${widget.catalogue.label} categories'),
        actions: [
          TextButton(
            onPressed: _save,
            child: Text('Save', style: TextStyle(color: t.accent)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: categories.when(
        loading: () => Center(child: CircularProgressIndicator(color: t.accent)),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              '$e',
              textAlign: TextAlign.center,
              style: TextStyle(color: t.inkDim, height: 1.5),
            ),
          ),
        ),
        data: (list) {
          final visible = _query.isEmpty
              ? list
              : list
                  .where((c) =>
                      c.name.toLowerCase().contains(_query.toLowerCase()))
                  .toList();

          return Column(
            children: [
              Padding(
                padding: RelayLayout.pagePadding(f).copyWith(top: 8),
                child: Column(
                  children: [
                    TextField(
                      controller: _search,
                      onChanged: (v) => setState(() => _query = v),
                      style: TextStyle(color: t.ink),
                      decoration: _decoration(t, 'Search categories',
                          icon: Icons.search),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _pattern,
                            style: TextStyle(color: t.ink),
                            decoration: _decoration(
                              t,
                              'Bulk select by pattern or text',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: 'Select matching',
                          icon: Icon(Icons.done_all, color: t.accent),
                          onPressed: () =>
                              _applyPattern(list, select: true),
                        ),
                        IconButton(
                          tooltip: 'Deselect matching',
                          icon: Icon(Icons.remove_done, color: t.inkDim),
                          onPressed: () =>
                              _applyPattern(list, select: false),
                        ),
                      ],
                    ),
                    if (_patternError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _patternError!,
                            style: TextStyle(color: t.inkDim, fontSize: 12),
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${_current.length} of ${list.length} selected',
                        style: TextStyle(color: t.inkDim, fontSize: 12.5),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: ListView.builder(
                  padding:
                      RelayLayout.pagePadding(f).copyWith(bottom: 28),
                  itemCount: visible.length,
                  itemBuilder: (context, i) {
                    final category = visible[i];
                    final checked = _current.contains(category.id);
                    return CheckboxListTile(
                      value: checked,
                      activeColor: t.accent,
                      checkColor: t.accentInk,
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        category.name,
                        style: TextStyle(color: t.ink, fontSize: 14),
                      ),
                      onChanged: (value) => setState(() {
                        final next = {..._current};
                        if (value == true) {
                          next.add(category.id);
                        } else {
                          next.remove(category.id);
                        }
                        _selected = next;
                      }),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: RelayLayout.pagePadding(f).copyWith(top: 8, bottom: 16),
        child: RelayButton(label: 'Save selection', onPressed: _save),
      ),
    );
  }

  InputDecoration _decoration(RelayTokens t, String hint, {IconData? icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: t.inkDim),
      prefixIcon: icon == null ? null : Icon(icon, color: t.inkDim, size: 19),
      filled: true,
      fillColor: t.surface,
      isDense: true,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
    );
  }
}
