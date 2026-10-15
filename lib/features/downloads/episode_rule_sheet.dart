import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/relay_theme.dart';
import '../../core/theme/relay_widgets.dart';
import '../../data/downloads/episode_rules.dart';
import 'offline_sync.dart';

/// One line saying what a rule does, for the show page and Downloads.
String describeRule(EpisodeRule? rule) => switch (rule?.keep) {
  null => 'Keep episodes downloaded',
  1 => 'Keeping the next episode downloaded',
  final n => 'Keeping the next $n episodes downloaded',
};

/// The show page's entry to its rule (§18.7). A row rather than a toggle,
/// because the choice is a number, and a toggle with a hidden number is the
/// kind of setting that quietly fills a phone.
class EpisodeRuleButton extends ConsumerWidget {
  const EpisodeRuleButton({
    super.key,
    required this.serverId,
    required this.showRatingKey,
    required this.showTitle,
  });

  final String serverId;
  final String showRatingKey;
  final String showTitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = RelayTheme.of(context);
    final rule = ref.watch(
      episodeRulesProvider.select(
        (all) => all
            .where((r) => r.key == 'plex:$serverId:$showRatingKey')
            .firstOrNull,
      ),
    );
    return RelayTappable(
      borderRadius: 10,
      onTap: () => showEpisodeRuleSheet(
        context,
        ref,
        serverId: serverId,
        showRatingKey: showRatingKey,
        showTitle: showTitle,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              rule == null
                  ? Icons.download_outlined
                  : Icons.download_done_outlined,
              color: rule == null ? t.inkDim : t.accent,
              size: 20,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                describeRule(rule),
                style: TextStyle(color: t.ink, fontSize: 13.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Off, or one of [ruleSizes]. Choosing a size starts the top-up at once;
/// choosing Off leaves what is on the device (see [EpisodeRules.remove]).
Future<void> showEpisodeRuleSheet(
  BuildContext context,
  WidgetRef ref, {
  required String serverId,
  required String showRatingKey,
  required String showTitle,
}) async {
  final rules = ref.read(episodeRulesProvider.notifier);
  final current = rules.find(serverId, showRatingKey);
  final picked = await showModalBottomSheet<int>(
    context: context,
    backgroundColor: RelayTheme.of(context).surface,
    isScrollControlled: true,
    builder: (context) {
      final t = RelayTheme.of(context);
      final f = RelayLayout.of(context);
      Widget row(String label, int value) => RelayTappable(
        borderRadius: 10,
        autofocus: (current?.keep ?? 0) == value,
        onTap: () => Navigator.of(context).pop(value),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: t.ink,
                    fontSize: RelayLayout.bodySize(f) + 1,
                  ),
                ),
              ),
              if ((current?.keep ?? 0) == value)
                Icon(Icons.check, color: t.accent),
            ],
          ),
        ),
      );
      return SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
                  child: Text(
                    showTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: t.inkDim,
                      fontSize: RelayLayout.bodySize(f),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  child: Text(
                    'Downloads the next unwatched episodes and replaces them '
                    'as you watch, while the app is open. Watched ones it '
                    'downloaded are removed.',
                    style: TextStyle(
                      color: t.inkDim,
                      fontSize: RelayLayout.bodySize(f) - 1,
                      height: 1.45,
                    ),
                  ),
                ),
                row('Off', 0),
                for (final n in ruleSizes)
                  row(n == 1 ? 'Next episode' : 'Next $n episodes', n),
              ],
            ),
          ),
        ),
      );
    },
  );
  if (picked == null) return;
  if (picked == 0) {
    if (current != null) await rules.remove(current);
    return;
  }
  await rules.set(
    current?.withKeep(picked) ??
        EpisodeRule(
          serverId: serverId,
          showRatingKey: showRatingKey,
          showTitle: showTitle,
          keep: picked,
        ),
  );
}
