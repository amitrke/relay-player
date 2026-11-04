import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/relay_theme.dart';
import '../../core/theme/relay_widgets.dart';
import '../../data/xtream/hidden_words.dart';
import '../../data/xtream/xtream_account_store.dart';
import '../../data/xtream/xtream_client.dart';
import 'hidden_words_controller.dart';
import 'xtream_controller.dart';
import '../../i18n/strings.g.dart';

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
///
/// **The two choices are said out loud (2026-11-03).** "Whole category" was a
/// chip beside the search box that left the screen when pressed, and a count
/// such as "3 of 120" sat next to it; what the difference meant was nowhere.
/// It matters, because a narrowed category is a fixed list: a channel the
/// provider adds later does not appear until it is ticked here. So the screen
/// now opens on the two choices with that sentence under each, and the list
/// shows a whole category as everything ticked; unticking one there starts a
/// narrowed list from all the others, which is what someone doing it means.
/// The model is unchanged: an empty list is still the whole category.
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

  /// Keep the whole category: what an empty [ChannelPickerArgs.picked] meant
  /// all along, now a choice of its own on screen.
  late bool _whole = widget.args.picked.isEmpty;
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

  void _toggle(XtreamChannel c, List<XtreamChannel> all) => setState(() {
    if (_whole) {
      // Every channel was in; unticking one keeps the rest.
      _whole = false;
      _picked = {for (final x in all) x.streamId}..remove(c.streamId);
      return;
    }
    final next = {..._picked};
    if (!next.add(c.streamId)) next.remove(c.streamId);
    _picked = next;
  });

  /// Everything picked, or nothing, both mean the whole category. Picking every
  /// channel is stored as "whole" so that a channel the panel adds later is not
  /// silently left out.
  void _done(List<XtreamChannel> all) {
    final everything = _whole || all.every((c) => _picked.contains(c.streamId));
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
        body: Center(child: Text(tr.xtream.lineGone)),
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
            onPressed: channels.value == null || (!_whole && _picked.isEmpty)
                ? null
                : () => _done(channels.value!),
            child: Text(
              tr.xtream.channels.done,
              style: TextStyle(
                color: !_whole && _picked.isEmpty ? t.inkDim : t.accent,
              ),
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
                padding: RelayLayout.pagePadding(f).copyWith(top: 4, bottom: 8),
                child: Column(
                  children: [
                    _Choice(
                      title: tr.xtream.channels.wholeTitle(n: all.length),
                      subtitle: tr.xtream.channels.wholeSub,
                      on: _whole,
                      onTap: () => setState(() => _whole = true),
                    ),
                    const SizedBox(height: 8),
                    _Choice(
                      title: tr.xtream.channels.someTitle(
                        picked: _whole ? all.length : _picked.length,
                        total: all.length,
                      ),
                      subtitle: tr.xtream.channels.someSub,
                      on: !_whole,
                      onTap: () => setState(() {
                        if (_whole) {
                          _whole = false;
                          _picked = {for (final c in all) c.streamId};
                        }
                      }),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: RelayLayout.pagePadding(f).copyWith(top: 4, bottom: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: RelayTypeOnSelect(
                        builder: (context, readOnly, onTap) => TextField(
                          readOnly: readOnly,
                          onTap: onTap,
                          controller: _search,
                          onChanged: (v) => setState(() => _query = v),
                          style: TextStyle(color: t.ink),
                          decoration: InputDecoration(
                            hintText: tr.xtream.channels.search,
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
                  ],
                ),
              ),
              Padding(
                padding: RelayLayout.pagePadding(f).copyWith(top: 0, bottom: 4),
                child: Row(
                  children: [
                    _Chip(
                      label: _query.isEmpty
                          ? tr.xtream.picker.selectAll
                          : tr.xtream.channels.selectShown,
                      onTap: () => setState(() {
                        _picked = {
                          if (!_whole) ..._picked,
                          if (_whole)
                            for (final c in all) c.streamId,
                          for (final c in shown) c.streamId,
                        };
                        _whole = false;
                      }),
                    ),
                    const SizedBox(width: 8),
                    _Chip(
                      label: _query.isEmpty
                          ? tr.xtream.channels.clear
                          : tr.xtream.channels.clearShown,
                      onTap: () => setState(() {
                        final drop = {for (final c in shown) c.streamId};
                        final from = _whole
                            ? {for (final c in all) c.streamId}
                            : _picked;
                        _picked = from
                            .where((id) => !drop.contains(id))
                            .toSet();
                        _whole = false;
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
                              ? tr.xtream.channels.none
                              : tr.xtream.picker.noMatch(query: _query),
                          style: TextStyle(color: t.inkDim),
                        ),
                      )
                    : ListView.builder(
                        padding: RelayLayout.pagePadding(f)
                            .copyWith(top: 0, bottom: 28),
                        itemCount: shown.length,
                        itemBuilder: (context, i) {
                          final c = shown[i];
                          final on = _whole || _picked.contains(c.streamId);
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: RelayTappable(
                              borderRadius: 10,
                              onTap: () => _toggle(c, all),
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

/// One of the two ways to keep a category, with what it means underneath.
class _Choice extends StatelessWidget {
  const _Choice({
    required this.title,
    required this.subtitle,
    required this.on,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);
    return Semantics(
      selected: on,
      // RelayTappable and not RelaySurface(onTap:): the surface draws its own focus
      // shadow, which the D-pad audit does not count as a ring, and its
      // InkWell adds a second stop with no ring at all (test/dpad, 2026-11-03).
      child: RelayTappable(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: on ? t.accent : t.line),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                on ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                size: 20,
                color: on ? t.accent : t.inkDim,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: t.ink,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: t.inkDim,
                        fontSize: 12.5,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
