import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/relay_theme.dart';
import '../../core/theme/relay_widgets.dart';
import '../../data/xtream/xtream_account_store.dart';
import 'hidden_words_controller.dart';
import 'hidden_words_sheet.dart';
import 'xtream_controller.dart';
import '../../i18n/strings.g.dart';

/// What a subscription will show, in one place: the end of setting one up,
/// and what Settings opens to adjust it (2026-11-03).
///
/// It exists for Movies and Series. Each catalogue has its own category
/// choice (§4.1), and until now only Live TV's was offered after adding a
/// subscription; the other two were small text buttons in Settings that most
/// people never found, so a subscription that carries films looked as if it
/// had none. Here they sit beside Live TV with an Add button each, and Never
/// show (the hidden words) beside them, since it applies to all three.
///
/// Nothing is fetched here. The counts are what is saved on the account; each
/// Add or Change opens that catalogue's own picker, which fetches its
/// categories (and only those) as it always has.
class SetupReviewScreen extends ConsumerWidget {
  const SetupReviewScreen({super.key, required this.accountId});

  final String accountId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = RelayTheme.of(context);
    final f = RelayLayout.of(context);
    XtreamAccount? account;
    for (final a in ref.watch(xtreamAccountsProvider)) {
      if (a.id == accountId) account = a;
    }
    final words = ref.watch(hiddenWordsProvider);

    if (account == null) {
      return Scaffold(
        backgroundColor: t.bg,
        appBar: AppBar(backgroundColor: t.bg, foregroundColor: t.ink),
        body: Center(child: Text(tr.xtream.lineGone)),
      );
    }

    void open(XtreamCatalogue c) =>
        context.push('/advanced/xtream/$accountId/categories/${c.name}');

    Widget catalogue(XtreamCatalogue c, IconData icon, String title) {
      final n = account!.categoriesFor(c).length;
      return _ReviewCard(
        icon: icon,
        title: title,
        subtitle: n == 0
            ? tr.xtream.review.notAdded
            : tr.xtream.review.chosen(n: n),
        action: n == 0 ? tr.xtream.review.add : tr.xtream.review.change,
        primary: n == 0,
        onTap: () => open(c),
      );
    }

    return Scaffold(
      backgroundColor: t.bg,
      appBar: AppBar(
        backgroundColor: t.bg,
        surfaceTintColor: Colors.transparent,
        foregroundColor: t.ink,
        title: Text(account.name),
      ),
      body: ListView(
        padding: RelayLayout.pagePadding(f).copyWith(top: 4, bottom: 32),
        children: [
          Text(
            tr.xtream.review.title,
            style: TextStyle(
              color: t.ink,
              fontSize: RelayLayout.bodySize(f) + 7,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          catalogue(
            XtreamCatalogue.live,
            Icons.live_tv_outlined,
            tr.xtream.review.live,
          ),
          catalogue(
            XtreamCatalogue.vod,
            Icons.movie_outlined,
            tr.xtream.review.movies,
          ),
          catalogue(
            XtreamCatalogue.series,
            Icons.tv_outlined,
            tr.xtream.review.series,
          ),
          _ReviewCard(
            icon: Icons.block_outlined,
            title: tr.xtream.review.neverShow,
            subtitle: words.isEmpty
                ? tr.xtream.review.neverShowNone
                : words.join(', '),
            action: tr.xtream.review.edit,
            primary: false,
            onTap: () => showHiddenWordsSheet(context),
          ),
          const SizedBox(height: 8),
          Text(
            tr.xtream.review.later,
            style: TextStyle(color: t.inkDim, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 22),
          RelayButton(
            label: tr.xtream.review.open,
            autofocus: true,
            onPressed: () => context.go('/library?tab=live'),
          ),
        ],
      ),
    );
  }
}

/// A row with one action. The whole row is the button, so a remote has one
/// stop per row, and the action word on the right says what it does.
class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.action,
    required this.primary,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String action;
  final bool primary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      // RelayTappable and not RelaySurface(onTap:): the surface draws its own focus
      // shadow, which the D-pad audit does not count as a ring, and its
      // InkWell adds a second stop with no ring at all (test/dpad, 2026-11-03).
      child: RelayTappable(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: t.line),
          ),
          child: Row(
            children: [
              Icon(icon, size: 22, color: t.accent),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: t.ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: t.inkDim, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: primary ? t.accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: primary ? t.accent : t.line),
                ),
                child: Text(
                  action,
                  style: TextStyle(
                    color: primary ? t.accentInk : t.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
