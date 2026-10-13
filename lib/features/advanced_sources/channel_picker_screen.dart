import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/relay_theme.dart';
import '../../core/theme/relay_widgets.dart';
import '../../data/xtream/hidden_words.dart';
import '../../data/xtream/xtream_account_store.dart';
import '../../data/xtream/xtream_client.dart';
import 'hidden_words_controller.dart';
import 'xtream_controller.dart';

/// What the category screen hands over: which category, and what is already
/// picked from it.
class ChannelPickerArgs {
  const ChannelPickerArgs({required this.name, required this.picked});

  final String name;
  final List<String> picked;
}

/// Pick a few channels from inside one live category.
///
/// A whole category is often more than anyone wants: "USA: News" is the right
/// category and nine of its channels are the wrong ones. This narrows it. It pops
/// a `List<String>` of stream ids to keep, or an empty list for "keep the whole
/// category"; backing out pops nothing and changes nothing. The category screen
/// holds the result until its own Save, so nothing is written from here.
///
/// Live only, because a live category holds a modest number of channels. A movie
/// category can hold thousands of titles and wants a different screen.
class ChannelPickerScreen extends ConsumerStatefulWidget {
  const ChannelPickerScreen({
    super.key,
    required this.accountId,
    required this.categoryId,
    required this.args,
  });

  final String accountId;
  final String categoryId;
  final ChannelPickerArgs args;

  @override
  ConsumerState<ChannelPickerScreen> createState() =>
      _ChannelPickerScreenState();
}

class _ChannelPickerScreenState extends ConsumerState<ChannelPickerScreen> {
  final _search = TextEditingController();
  late Set<String> _picked = {...widget.args.picked};
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  XtreamAccount? get _account {
    for (final a in ref.read(xtreamAccountsProvider)) {
      if (a.id == widget.accountId) return a;
    }
    return null;
  }

  void _toggle(XtreamChannel c) => setState(() {
    final next = {..._picked};
    if (!next.add(c.streamId)) next.remove(c.streamId);
    _picked = next;
  });

  /// Everything picked, or nothing, both mean the whole category. Picking every
  /// channel is stored as "whole" so that a channel the panel adds later is not
  /// silently left out.
  void _done(List<XtreamChannel> all) {
    final everything = all.every((c) => _picked.contains(c.streamId));
    Navigator.of(context)
        .pop<List<String>>(everything ? const [] : _picked.toList());
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

    final channels = ref.watch(
      xtreamCategoryChannelsProvider((account, widget.categoryId)),
    );

    return Scaffold(
      backgroundColor: t.bg,
      appBar: AppBar(
        backgroundColor: t.bg,
        surfaceTintColor: Colors.transparent,
        foregroundColor: t.ink,
        toolbarHeight: f == RelayFormFactor.tv ? 48 : null,
        title: Text(
          widget.args.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          TextButton(
            // With nothing picked there is nothing to keep, which is not what
            // anyone means; "Whole category" is the way to ask for everything.
            onPressed: channels.value == null || _picked.isEmpty
                ? null
                : () => _done(channels.value!),
            child: Text(
              'Done',
              style: TextStyle(color: _picked.isEmpty ? t.inkDim : t.accent),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: channels.when(
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
        data: (everything) {
          // The ones hidden by the user's words are not offered, so the count
          // and "Select all" cover what Live TV would show.
          final all = withoutHidden(
            everything,
            HiddenWords(ref.watch(hiddenWordsProvider)),
          );
          final needle = _query.toLowerCase();
          final shown = _query.isEmpty
              ? all
              : [
                  for (final c in all)
                    if (c.name.toLowerCase().contains(needle)) c,
                ];
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
                          decoration: InputDecoration(
                            hintText: 'Search this category',
                            hintStyle: TextStyle(color: t.inkDim),
                            prefixIcon: Icon(
                              Icons.search,
                              color: t.inkDim,
                              size: 19,
                            ),
                            filled: true,
                            fillColor: t.surface,
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
                    _Chip(
                      label: '${_picked.length} of ${all.length}',
                      onTap: null,
                    ),
                    const SizedBox(width: 8),
                    _Chip(
                      label: 'Whole category',
                      onTap: () =>
                          Navigator.of(context)
                              .pop<List<String>>(const <String>[]),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: RelayLayout.pagePadding(f).copyWith(top: 0, bottom: 4),
                child: Row(
                  children: [
                    _Chip(
                      label: _query.isEmpty ? 'Select all' : 'Select shown',
                      onTap: () => setState(() {
                        _picked = {
                          ..._picked,
                          for (final c in shown) c.streamId,
                        };
                      }),
                    ),
                    const SizedBox(width: 8),
                    _Chip(
                      label: _query.isEmpty ? 'Clear' : 'Clear shown',
                      onTap: () => setState(() {
                        final drop = {for (final c in shown) c.streamId};
                        _picked = _picked
                            .where((id) => !drop.contains(id))
                            .toSet();
                      }),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: shown.isEmpty
                    ? Center(
                        child: Text(
                          all.isEmpty
                              ? 'The panel lists no channels in this category.'
                              : 'Nothing matches "$_query".',
                          style: TextStyle(color: t.inkDim),
                        ),
                      )
                    : ListView.builder(
                        padding: RelayLayout.pagePadding(f)
                            .copyWith(top: 0, bottom: 28),
                        itemCount: shown.length,
                        itemBuilder: (context, i) {
                          final c = shown[i];
                          final on = _picked.contains(c.streamId);
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: RelayTappable(
                              borderRadius: 10,
                              onTap: () => _toggle(c),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      on
                                          ? Icons.check_box
                                          : Icons.check_box_outline_blank,
                                      color: on ? t.accent : t.inkDim,
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Text(
                                        c.name,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: t.ink,
                                          fontSize: RelayLayout.bodySize(f),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.onTap});

  final String label;

  /// Null makes it a plain label: the "3 of 120" count.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);
    final f = RelayLayout.of(context);
    final size = f == RelayFormFactor.tv ? 15.0 : 13.0;
    final body = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: t.line),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: onTap == null ? t.inkDim : t.ink,
          fontSize: size,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
    if (onTap == null) return body;
    return RelayTappable(borderRadius: 20, onTap: onTap!, child: body);
  }
}
