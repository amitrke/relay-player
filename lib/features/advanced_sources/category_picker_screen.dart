import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/relay_theme.dart';
import '../../core/theme/relay_tokens.dart';
import '../../core/theme/relay_widgets.dart';
import '../../data/xtream/category_groups.dart';
import '../../data/xtream/hidden_words.dart';
import '../../data/xtream/xtream_account_store.dart';
import '../../data/xtream/xtream_client.dart';
import 'channel_picker_screen.dart';
import 'hidden_words_controller.dart';
import 'hidden_words_sheet.dart';
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
///
/// **Browsed by group, not as one list.** Until 2026-10-09 this was a flat list
/// of every category with a text box above it. On a TV that was three visible
/// rows of 466 and a keyboard to get anywhere. It now opens on a short list of
/// groups, found from the names (see [groupCategories]), each of which opens to
/// its own categories, with a switch to show only what is already chosen. Typing
/// a search still works across everything.
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
  final _scroll = ScrollController();

  Set<String>? _selected;

  /// Channels kept from a live category, by category id; see
  /// [XtreamAccount.liveChannelPicks]. Held here until Save, like the selection.
  Map<String, List<String>>? _picks;
  String _query = '';
  String? _patternError;

  /// The group being looked into, or null on the list of groups.
  CategoryGroup? _open;
  bool _selectedOnly = false;
  bool _showPattern = false;

  /// Reveal the categories the hidden words would leave out.
  bool _showHidden = false;

  /// Said once after adding a word, when it un-ticked something.
  String? _note;

  // Grouping is not free on hundreds of names, so it is done once per list.
  List<XtreamCategory>? _groupedFrom;
  String _groupedWords = '';
  bool _groupedShowing = false;
  List<CategoryGroup> _groups = const [];

  @override
  void dispose() {
    _search.dispose();
    _pattern.dispose();
    _scroll.dispose();
    super.dispose();
  }

  XtreamAccount? get _account {
    for (final account in ref.read(xtreamAccountsProvider)) {
      if (account.id == widget.accountId) return account;
    }
    return null;
  }

  List<CategoryGroup> _groupsOf(
    List<XtreamCategory> all,
    List<XtreamCategory> visible,
    String wordsKey,
  ) {
    if (!identical(_groupedFrom, all) ||
        _groupedWords != wordsKey ||
        _groupedShowing != _showHidden) {
      _groupedFrom = all;
      _groupedWords = wordsKey;
      _groupedShowing = _showHidden;
      _groups = groupCategories(visible);
    }
    return _groups;
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

  Map<String, List<String>> get _currentPicks =>
      _picks ?? {...?_account?.liveChannelPicks};

  bool get _isLive => widget.catalogue == XtreamCatalogue.live;

  /// Opens the channels of [category]. Picking any chooses the category as well:
  /// asking for three of its channels is asking for it. "Whole category" in the
  /// picker comes back as an empty list and clears the narrowing.
  Future<void> _pickChannels(XtreamCategory category) async {
    final account = _account;
    if (account == null) return;
    final result = await context.push<List<String>>(
      '/advanced/xtream/${account.id}/channels/${category.id}',
      extra: ChannelPickerArgs(
        name: category.name,
        picked: _currentPicks[category.id] ?? const [],
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      final picks = {..._currentPicks};
      if (result.isEmpty) {
        picks.remove(category.id);
      } else {
        picks[category.id] = result;
      }
      _picks = picks;
      _selected = {..._current, category.id};
    });
  }

  void _toggle(XtreamCategory category) => setState(() {
    final next = {..._current};
    if (!next.add(category.id)) next.remove(category.id);
    _selected = next;
  });

  void _setAll(Iterable<XtreamCategory> categories, {required bool on}) =>
      setState(() {
        final next = {..._current};
        for (final c in categories) {
          if (on) {
            next.add(c.id);
          } else {
            next.remove(c.id);
          }
        }
        _selected = next;
      });

  /// Saves the selection in the panel's own category order, with names.
  ///
  /// The order was the order of ticking until 2026-09-28, which nothing read.
  /// Live TV now groups channels under these categories in saved order, and
  /// the panel's order is the one the viewer has just been scrolling through
  /// here, so it is the least surprising. The names come along because this
  /// screen already has them and Live TV would otherwise have to fetch the
  /// whole category list again to label its groups.
  ///
  /// [categories] is null while the list is loading or failed; the selection
  /// then saves as it stands, which is what Save did before.
  Future<void> _save(List<XtreamCategory>? categories) async {
    final account = _account;
    if (account == null) return;
    final chosen = _current;
    final ids = categories == null
        ? chosen.toList()
        : [
            for (final c in categories)
              if (chosen.contains(c.id)) c.id,
            // Chosen ids the panel no longer lists keep their place at the end
            // rather than being dropped by a save that did not touch them.
            ...chosen.where((id) => !categories.any((c) => c.id == id)),
          ];
    var updated = account.withCategories(
      widget.catalogue,
      ids,
      names: {
        for (final c in categories ?? const <XtreamCategory>[]) c.id: c.name,
      },
    );
    // Picks only for the categories kept, which `withChannelPicks` enforces.
    if (_isLive) updated = updated.withChannelPicks(_currentPicks);
    await ref.read(xtreamAccountsProvider.notifier).save(updated);
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

    final categories = ref.watch(
      xtreamCategoriesProvider((account, widget.catalogue)),
    );

    // Back steps out of a group or the selected-only view before it leaves the
    // screen, so a remote's Back does not throw away a screen of choices.
    return PopScope(
      canPop: _open == null && !_selectedOnly && _query.isEmpty,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        setState(() {
          if (_query.isNotEmpty) {
            _search.clear();
            _query = '';
          } else if (_selectedOnly) {
            _selectedOnly = false;
          } else {
            _open = null;
          }
        });
      },
      child: Scaffold(
        backgroundColor: t.bg,
        appBar: AppBar(
          backgroundColor: t.bg,
          surfaceTintColor: Colors.transparent,
          foregroundColor: t.ink,
          toolbarHeight: f == RelayFormFactor.tv ? 48 : null,
          title: Text('${widget.catalogue.label} categories'),
          actions: [
            TextButton(
              onPressed: () => _save(categories.value),
              child: Text('Save', style: TextStyle(color: t.accent)),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: categories.when(
          loading: () =>
              Center(child: CircularProgressIndicator(color: t.accent)),
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
          data: (list) => _body(context, list),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, List<XtreamCategory> list) {
    final t = RelayTheme.of(context);
    final f = RelayLayout.of(context);
    final words = ref.watch(hiddenWordsProvider);
    final hidden = HiddenWords(words);
    // What the lists show. The hidden ones stay in [list] so the Chosen view can
    // still show something chosen before its word was hidden.
    final visible = _showHidden
        ? list
        : [
            for (final c in list)
              if (!hidden.matches(c.name)) c,
          ];
    final hiddenCount = list.length - visible.length;
    final groups = _groupsOf(list, visible, words.join('\u0001'));
    final chosen = _current;

    final Widget content;
    if (_query.isNotEmpty) {
      final needle = _query.toLowerCase();
      final hits = [
        for (final c in visible)
          if (c.name.toLowerCase().contains(needle)) c,
      ];
      content = _categoryList(hits, empty: 'Nothing matches "$_query".');
    } else if (_selectedOnly) {
      content = _categoryList([
        for (final c in list)
          if (chosen.contains(c.id)) c,
      ], empty: 'Nothing chosen yet.');
    } else if (_open != null) {
      // A big group is browsed by letter: A to Z, with a chip per letter to
      // jump to. A small one keeps the panel's order, which usually means
      // something and is short enough to read through.
      final big = _open!.categories.length > alphabetiseAbove;
      final shown = big
          ? sortedAlphabetically(
              _open!.categories,
              (c) => categoryLabelInGroup(c.name),
            )
          : _open!.categories;
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _groupHeader(_open!),
          if (big) _letterRow(shown),
          // Under its group a name drops the part the group already says.
          Expanded(child: _categoryList(shown, shorten: true, fixedRows: big)),
        ],
      );
    } else {
      content = _groupList(groups, chosen);
    }

    return Column(
      children: [
        Padding(
          padding: RelayLayout.pagePadding(f).copyWith(top: 4, bottom: 6),
          child: Row(
            children: [
              Expanded(
                child: RelayFieldTraversal(
                  child: TextField(
                    controller: _search,
                    onChanged: (v) => setState(() => _query = v),
                    style: TextStyle(color: t.ink),
                    decoration: _decoration(
                      t,
                      'Search all categories',
                      icon: Icons.search,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _ModeChip(
                label: 'Chosen ${chosen.length}',
                on: _selectedOnly,
                onTap: () => setState(() {
                  _selectedOnly = !_selectedOnly;
                  _open = null;
                }),
              ),
              const SizedBox(width: 8),
              _ModeChip(
                label: words.isEmpty ? 'Hide words' : 'Hide ${words.length}',
                on: words.isNotEmpty,
                onTap: () => showHiddenWordsSheet(
                  context,
                  onAdded: (word) => _onWordAdded(word, list),
                ),
              ),
              const SizedBox(width: 8),
              _ModeChip(
                label: 'Pattern',
                on: _showPattern,
                onTap: () => setState(() => _showPattern = !_showPattern),
              ),
            ],
          ),
        ),
        if (_note != null || hiddenCount > 0 || _showHidden)
          _hiddenNote(hiddenCount),
        if (_showPattern) _patternRow(visible),
        Expanded(child: content),
      ],
    );
  }

  /// A word was just hidden: anything already chosen that it matches is
  /// un-ticked, and the screen says so, since an un-ticked category that is also
  /// now out of sight would otherwise just be missing. Nothing is saved until
  /// Save, like every other change here.
  void _onWordAdded(String word, List<XtreamCategory> list) {
    final matcher = HiddenWords([word]);
    final chosen = _current;
    final dropped = [
      for (final c in list)
        if (chosen.contains(c.id) && matcher.matches(c.name)) c,
    ];
    setState(() {
      if (dropped.isNotEmpty) {
        final ids = {for (final c in dropped) c.id};
        _selected = chosen.where((id) => !ids.contains(id)).toSet();
        _picks = {
          for (final e in _currentPicks.entries)
            if (!ids.contains(e.key)) e.key: e.value,
        };
        _note = dropped.length == 1
            ? 'Un-ticked "${dropped.first.name}", which "$word" hides. Save to keep that.'
            : 'Un-ticked ${dropped.length} chosen categories that "$word" hides. Save to keep that.';
      } else {
        _note = null;
      }
      _open = null;
    });
  }

  Widget _hiddenNote(int hiddenCount) {
    final t = RelayTheme.of(context);
    final f = RelayLayout.of(context);
    return Padding(
      padding: RelayLayout.pagePadding(f).copyWith(top: 0, bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _note ??
                  (_showHidden
                      ? 'Showing the categories your hidden words leave out.'
                      : '$hiddenCount hidden by your words.'),
              style: TextStyle(color: t.inkDim, fontSize: 12.5, height: 1.4),
            ),
          ),
          if (hiddenCount > 0 || _showHidden)
            _ModeChip(
              label: _showHidden ? 'Hide again' : 'Show them',
              on: _showHidden,
              onTap: () => setState(() {
                _showHidden = !_showHidden;
                _note = null;
                _open = null;
              }),
            ),
        ],
      ),
    );
  }

  Widget _patternRow(List<XtreamCategory> list) {
    final t = RelayTheme.of(context);
    final f = RelayLayout.of(context);
    return Padding(
      padding: RelayLayout.pagePadding(f).copyWith(top: 0, bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: RelayFieldTraversal(
                  child: TextField(
                    controller: _pattern,
                    style: TextStyle(color: t.ink),
                    decoration: _decoration(
                      t,
                      'Select or clear every category matching a word or pattern',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Select matching',
                icon: Icon(Icons.done_all, color: t.accent),
                onPressed: () => _applyPattern(list, select: true),
              ),
              IconButton(
                tooltip: 'Deselect matching',
                icon: Icon(Icons.remove_done, color: t.inkDim),
                onPressed: () => _applyPattern(list, select: false),
              ),
            ],
          ),
          if (_patternError != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _patternError!,
                style: TextStyle(color: t.inkDim, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _groupList(List<CategoryGroup> groups, Set<String> chosen) {
    final f = RelayLayout.of(context);
    return ListView.builder(
      padding: RelayLayout.pagePadding(f).copyWith(top: 0, bottom: 28),
      itemCount: groups.length,
      itemBuilder: (context, i) {
        final g = groups[i];
        final picked = g.categories.where((c) => chosen.contains(c.id)).length;
        return _GroupRow(
          label: g.label,
          count: g.categories.length,
          picked: picked,
          onTap: () => setState(() => _open = g),
        );
      },
    );
  }

  Widget _groupHeader(CategoryGroup group) {
    final t = RelayTheme.of(context);
    final f = RelayLayout.of(context);
    final allOn = group.categories.every((c) => _current.contains(c.id));
    return Padding(
      padding: RelayLayout.pagePadding(f).copyWith(top: 0, bottom: 6),
      child: Row(
        children: [
          _ModeChip(
            label: 'Groups',
            icon: Icons.arrow_back,
            on: false,
            onTap: () => setState(() => _open = null),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              group.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: t.ink,
                fontSize: RelayLayout.bodySize(f) + 2,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _ModeChip(
            label: allOn ? 'Clear all' : 'Select all',
            on: false,
            onTap: () => _setAll(group.categories, on: !allOn),
          ),
        ],
      ),
    );
  }

  /// The height every row is given when [fixedRows] is set, so a letter chip can
  /// scroll to a row by arithmetic: a lazy list has not built the rows below the
  /// screen, so there is nothing to ask for their position. Scaled with the text
  /// so large type does not overflow it.
  double get _rowExtent {
    final f = RelayLayout.of(context);
    final text = MediaQuery.textScalerOf(context)
        .scale(RelayLayout.bodySize(f));
    return (38 + text * 1.45).clamp(60.0, 104.0);
  }

  Widget _letterRow(List<XtreamCategory> sorted) {
    final f = RelayLayout.of(context);
    // The first row of each letter, in the order the rows are shown.
    final firstOf = <String, int>{};
    for (final (i, c) in sorted.indexed) {
      firstOf.putIfAbsent(letterOf(categoryLabelInGroup(c.name)), () => i);
    }
    return SizedBox(
      height: 54,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: RelayLayout.pagePadding(f).copyWith(top: 0, bottom: 4),
        children: [
          for (final e in firstOf.entries)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: _ModeChip(
                label: e.key,
                on: false,
                onTap: () {
                  if (!_scroll.hasClients) return;
                  final max = _scroll.position.maxScrollExtent;
                  _scroll.animateTo(
                    (e.value * _rowExtent).clamp(0.0, max),
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _categoryList(
    List<XtreamCategory> items, {
    String? empty,
    bool shorten = false,
    bool fixedRows = false,
  }) {
    final t = RelayTheme.of(context);
    final f = RelayLayout.of(context);
    if (items.isEmpty) {
      return Center(
        child: Text(empty ?? '', style: TextStyle(color: t.inkDim)),
      );
    }
    final chosen = _current;
    return ListView.builder(
      controller: fixedRows ? _scroll : null,
      itemExtent: fixedRows ? _rowExtent : null,
      padding: RelayLayout.pagePadding(f).copyWith(top: 0, bottom: 28),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final c = items[i];
        final picked = _currentPicks[c.id]?.length ?? 0;
        return _CategoryRow(
          singleLine: fixedRows,
          name: shorten ? categoryLabelInGroup(c.name) : c.name,
          checked: chosen.contains(c.id),
          onTap: () => _toggle(c),
          note: picked > 0
              ? '$picked ${picked == 1 ? "channel" : "channels"}'
              : null,
          onChannels: _isLive ? () => _pickChannels(c) : null,
        );
      },
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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

/// A small switch-like chip. Built from [RelayTappable] so a remote can reach it
/// with a visible ring (§11), which Material's chips do not give on a TV.
class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.label,
    required this.on,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool on;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);
    final f = RelayLayout.of(context);
    final size = f == RelayFormFactor.tv ? 15.0 : 13.0;
    return RelayTappable(
      borderRadius: 20,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: on ? t.accent.withValues(alpha: 0.18) : t.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: on ? t.accent : t.line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: size + 2, color: t.inkDim),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: on ? t.ink : t.inkDim,
                fontSize: size,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupRow extends StatelessWidget {
  const _GroupRow({
    required this.label,
    required this.count,
    required this.picked,
    required this.onTap,
  });

  final String label;
  final int count;
  final int picked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);
    final f = RelayLayout.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: RelayTappable(
        borderRadius: 10,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: t.ink,
                    fontSize: RelayLayout.bodySize(f) + 1,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (picked > 0) ...[
                Text(
                  '$picked chosen',
                  style: TextStyle(color: t.accent, fontSize: 13),
                ),
                const SizedBox(width: 14),
              ],
              Text(
                count == 1 ? '1 category' : '$count categories',
                style: TextStyle(color: t.inkDim, fontSize: 13),
              ),
              const SizedBox(width: 6),
              Icon(Icons.chevron_right, color: t.inkDim),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.name,
    required this.checked,
    required this.onTap,
    this.note,
    this.onChannels,
    this.singleLine = false,
  });

  final String name;
  final bool checked;
  final VoidCallback onTap;

  /// "3 channels" when only some of the category is kept.
  final String? note;

  /// Opens the channels inside, for a live category; null elsewhere.
  final VoidCallback? onChannels;

  /// One line and no more, for a list whose rows are all the same height.
  final bool singleLine;

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);
    final f = RelayLayout.of(context);
    // The toggle and the channels button are siblings, not nested, so a remote
    // can focus each on its own: Right moves from one to the other.
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: RelayTappable(
              borderRadius: 10,
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Icon(
                      checked ? Icons.check_box : Icons.check_box_outline_blank,
                      color: checked ? t.accent : t.inkDim,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        name,
                        maxLines: singleLine ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: t.ink,
                          fontSize: RelayLayout.bodySize(f),
                        ),
                      ),
                    ),
                    if (note != null)
                      Text(
                        note!,
                        style: TextStyle(color: t.accent, fontSize: 13),
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (onChannels != null) ...[
            const SizedBox(width: 8),
            RelayTappable(
              borderRadius: 20,
              onTap: onChannels!,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Channels',
                      style: TextStyle(
                        color: t.accent,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Icon(Icons.chevron_right, color: t.accent, size: 18),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
