import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/relay_theme.dart';
import '../../core/theme/relay_widgets.dart';
import '../../data/xtream/xtream_account_store.dart';
import '../../data/xtream/xtream_client.dart';
import 'setup_steps.dart';
import 'xtream_controller.dart';
import '../../i18n/strings.g.dart';

/// Step 2 of 3: what the provider said about the subscription, in plain
/// words, before the choosing (2026-11-03).
///
/// Everything here was already in the `authenticate` answer and none of it was
/// shown: the end date was parsed and never displayed, and the screen count
/// appeared as "1 concurrent stream allowed" for the instant before the form
/// was replaced by the category list. The one-screen limit is the fact most
/// worth saying out loud, because §4's `max_connections` of 1 is the common
/// case and the failure it causes (a channel that will not start because a
/// phone elsewhere is playing) otherwise looks like a broken app.
///
/// The count shown is of channel *categories*, from one small call. A channel
/// count would mean fetching every stream list, which is what §4.1 exists to
/// avoid; the screen says so by moving on to choosing.
class ConnectedScreen extends ConsumerWidget {
  const ConnectedScreen({super.key, required this.accountId, this.info});

  final String accountId;

  /// From the form's check. Null when the route is opened without it (a
  /// restored route after the app was killed): the screen then says what it
  /// can without it rather than checking again.
  final XtreamAccountInfo? info;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = RelayTheme.of(context);
    final f = RelayLayout.of(context);
    XtreamAccount? account;
    for (final a in ref.watch(xtreamAccountsProvider)) {
      if (a.id == accountId) account = a;
    }

    if (account == null) {
      return Scaffold(
        backgroundColor: t.bg,
        appBar: AppBar(backgroundColor: t.bg, foregroundColor: t.ink),
        body: Center(child: Text(tr.xtream.lineGone)),
      );
    }

    final categories = ref.watch(
      xtreamCategoriesProvider((account, XtreamCatalogue.live)),
    );
    final info = this.info;
    final ends = info?.expiresAt;

    return Scaffold(
      backgroundColor: t.bg,
      appBar: AppBar(
        backgroundColor: t.bg,
        surfaceTintColor: Colors.transparent,
        foregroundColor: t.ink,
        automaticallyImplyLeading: false,
        toolbarHeight: f == RelayFormFactor.tv ? 32 : 16,
      ),
      body: ListView(
        padding: RelayLayout.pagePadding(f).copyWith(top: 4, bottom: 32),
        children: [
          const SetupSteps(step: 2),
          const SizedBox(height: 24),
          Row(
            children: [
              Icon(Icons.check_circle, color: t.accent, size: 36),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr.xtream.connected.title,
                      style: TextStyle(
                        color: t.ink,
                        fontSize: RelayLayout.titleSize(f) - 4,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      account.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: t.inkDim, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          RelaySurface(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              children: [
                if (info != null)
                  _Fact(
                    label: tr.xtream.connected.status,
                    value: info.isTrial
                        ? tr.xtream.connected.trial
                        : tr.xtream.connected.active,
                  ),
                if (info != null)
                  _Fact(
                    label: tr.xtream.connected.ends,
                    value: ends == null
                        ? tr.xtream.connected.noEnd
                        : MaterialLocalizations.of(context)
                              .formatMediumDate(ends.toLocal()),
                  ),
                if (info != null)
                  _Fact(
                    label: tr.xtream.connected.screens,
                    value: '${info.maxConnections}',
                  ),
                _Fact(
                  label: tr.xtream.connected.available,
                  value: categories.when(
                    data: (list) =>
                        tr.xtream.connected.liveCategories(n: list.length),
                    loading: () => '…',
                    // Not worth an error here: the next step fetches the same
                    // list and says what went wrong, with a way to retry.
                    error: (_, _) => '–',
                  ),
                  last: true,
                ),
              ],
            ),
          ),
          if (info != null && info.maxConnections <= 1) ...[
            const SizedBox(height: 12),
            RelaySurface(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: t.accent, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      tr.xtream.connected.oneScreen,
                      style: TextStyle(
                        color: t.ink,
                        fontSize: 13,
                        height: 1.55,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),
          Text(
            tr.xtream.connected.next,
            style: TextStyle(color: t.inkDim, fontSize: 14, height: 1.55),
          ),
        ],
      ),
      // Fixed below the facts, not at the end of the list: on a 540 dp TV the
      // list ran past the screen, the button was never built, and a remote had
      // nothing at all to focus (the D-pad audit, 2026-11-03).
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: RelayLayout.pagePadding(f).copyWith(top: 10, bottom: 16),
          child: RelayButton(
            label: tr.xtream.connected.choose,
            autofocus: true,
            onPressed: () => context.pushReplacement(
              '/advanced/xtream/$accountId/categories/live?setup=1',
            ),
          ),
        ),
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value, this.last = false});

  final String label;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: last ? null : Border(bottom: BorderSide(color: t.line)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: TextStyle(color: t.inkDim, fontSize: 14)),
          ),
          Text(
            value,
            style: TextStyle(
              color: t.ink,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
