import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/relay_theme.dart';
import '../../core/theme/relay_widgets.dart';
import '../../data/downloads/download_record.dart';
import '../../data/downloads/episode_rules.dart';
import '../library/poster_grid.dart' show LibraryEmptyState;
import 'downloads_controller.dart';
import 'episode_rule_sheet.dart';
import 'offline_sync.dart';
import '../../i18n/strings.g.dart';

/// "1.4 GB", "850 MB", "12 KB". Decimal units, as storage and Plex both quote.
String formatBytes(int bytes) {
  if (bytes < 1000) return '$bytes B';
  const units = ['KB', 'MB', 'GB', 'TB'];
  var value = bytes / 1000;
  var i = 0;
  while (value >= 1000 && i < units.length - 1) {
    value /= 1000;
    i++;
  }
  // One decimal for a gigabyte or more, where it tells you something, and none
  // below, where it is noise.
  return '${value.toStringAsFixed(i >= 2 ? 1 : 0)} ${units[i]}';
}

/// "1 h 30 min", "45 min". Empty when the length is not known.
String formatRuntime(Duration d) {
  final minutes = d.inMinutes;
  if (minutes <= 0) return '';
  final h = minutes ~/ 60;
  final m = minutes % 60;
  if (h == 0) return tr.units.minutes(m: m);
  return m == 0 ? tr.units.hours(h: h) : tr.units.hoursMinutes(h: h, m: m);
}

/// Downloads (§18): what is saved on this device, and what is still arriving.
///
/// Plays from the saved file with no network, which is the reason it is a tab
/// of its own. Everything else in the app needs a server to be reachable.
class DownloadsScreen extends ConsumerWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = RelayTheme.of(context);
    final f = RelayLayout.of(context);
    final items = ref.watch(downloadsProvider);
    final rules = ref.watch(episodeRulesProvider);
    final pending = ref.watch(offlineWatchProvider).length;
    final used = ref.read(downloadsProvider.notifier).bytesUsed;
    final unfinished = items.any((r) => !r.isComplete);

    return Scaffold(
      backgroundColor: t.bg,
      body: SafeArea(
        child: items.isEmpty && rules.isEmpty
            ? LibraryEmptyState(
                icon: Icons.download_outlined,
                message: tr.downloads.empty,
              )
            : ListView(
                padding: RelayLayout.pagePadding(
                  f,
                ).copyWith(top: 20, bottom: 40),
                children: [
                  Text(
                    tr.downloads.title,
                    style: TextStyle(
                      color: t.ink,
                      fontSize: RelayLayout.titleSize(f),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    tr.downloads.summary(
                      n: items.length,
                      size: formatBytes(used),
                    ),
                    style: TextStyle(
                      color: t.inkDim,
                      fontSize: RelayLayout.bodySize(f),
                    ),
                  ),
                  if (pending > 0) ...[
                    const SizedBox(height: 6),
                    Text(
                      // §18.6: watched offline, told to Plex on reconnect.
                      tr.downloads.pendingWatches(n: pending),
                      style: TextStyle(
                        color: t.inkDim,
                        fontSize: RelayLayout.bodySize(f) - 1,
                        height: 1.5,
                      ),
                    ),
                  ],
                  if (unfinished) ...[
                    const SizedBox(height: 6),
                    Text(
                      // Honest about the limit (§18.3): there is no background
                      // service, so closing the app stops them.
                      tr.downloads.foregroundOnly,
                      style: TextStyle(
                        color: t.inkDim,
                        fontSize: RelayLayout.bodySize(f) - 1,
                        height: 1.5,
                      ),
                    ),
                  ],
                  if (rules.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    for (final rule in rules) ...[
                      _RuleRow(rule: rule),
                      const SizedBox(height: 10),
                    ],
                  ],
                  const SizedBox(height: 18),
                  for (final (i, record) in items.indexed) ...[
                    _DownloadRow(record: record, autofocus: i == 0),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
      ),
    );
  }
}

/// A show being kept topped up (§18.7). Selecting it changes or stops it.
class _RuleRow extends ConsumerWidget {
  const _RuleRow({required this.rule});

  final EpisodeRule rule;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = RelayTheme.of(context);
    final f = RelayLayout.of(context);
    return RelaySurface(
      onTap: () => showEpisodeRuleSheet(
        context,
        ref,
        serverId: rule.serverId,
        showRatingKey: rule.showRatingKey,
        showTitle: rule.showTitle,
      ),
      child: Row(
        children: [
          Icon(Icons.download_done_outlined, color: t.accent, size: 26),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rule.showTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: t.ink,
                    fontSize: RelayLayout.bodySize(f) + 1,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  describeRule(rule),
                  style: TextStyle(
                    color: t.inkDim,
                    fontSize: RelayLayout.bodySize(f) - 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The poster saved with a download (§18.8), or the state icon when there is
/// none: saved before posters were, or the server would not give one.
class _Artwork extends ConsumerWidget {
  const _Artwork({required this.record, required this.fallback});

  final DownloadRecord record;
  final Widget fallback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (record.artworkFile == null) return fallback;
    return FutureBuilder(
      future: ref.read(downloadsProvider.notifier).artworkFor(record),
      builder: (context, snap) {
        final file = snap.data;
        if (file == null) return fallback;
        return ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image.file(
            file,
            width: 40,
            height: 60,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => fallback,
          ),
        );
      },
    );
  }
}

class _DownloadRow extends ConsumerWidget {
  const _DownloadRow({required this.record, required this.autofocus});

  final DownloadRecord record;
  final bool autofocus;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = RelayTheme.of(context);
    final f = RelayLayout.of(context);
    final controller = ref.read(downloadsProvider.notifier);

    final primary = switch (record.state) {
      DownloadState.complete => () => context.push(
        '/play/${record.serverId}/${record.ratingKey}',
      ),
      DownloadState.downloading =>
        () => controller.pause(record.serverId, record.ratingKey),
      DownloadState.queued ||
      DownloadState.paused ||
      DownloadState.failed => () =>
          controller.resume(record.serverId, record.ratingKey),
    };

    final icon = switch (record.state) {
      DownloadState.complete => Icons.play_circle_outline,
      DownloadState.downloading => Icons.pause_circle_outline,
      DownloadState.queued => Icons.schedule,
      DownloadState.paused => Icons.download_for_offline_outlined,
      DownloadState.failed => Icons.error_outline,
    };

    final percent = record.fraction == null
        ? null
        : (record.fraction! * 100).floor();
    final size = record.totalBytes;
    final detail = switch (record.state) {
      DownloadState.complete => [
        if (size != null) formatBytes(size),
        formatRuntime(record.duration),
      ].where((s) => s.isNotEmpty).join(' · '),
      DownloadState.downloading =>
        percent == null
            ? tr.downloads.downloadingBytes(
                received: formatBytes(record.receivedBytes),
              )
            : tr.downloads.downloadingPercent(
                percent: percent,
                received: formatBytes(record.receivedBytes),
                total: formatBytes(size!),
              ),
      DownloadState.queued => tr.downloads.queued,
      DownloadState.paused =>
        percent == null
            ? tr.downloads.paused
            : tr.downloads.pausedAt(percent: percent),
      DownloadState.failed => tr.downloads.failed(
        error: record.error ?? tr.downloads.failedUnknown,
      ),
    };

    return RelaySurface(
      autofocus: autofocus,
      onTap: primary,
      borderColor: record.state == DownloadState.failed
          ? const Color(0xFFB8574E)
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _Artwork(
                record: record,
                fallback: Icon(
                  icon,
                  color: record.isComplete ? t.accent : t.inkDim,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: t.ink,
                        fontSize: RelayLayout.bodySize(f) + 1,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      detail,
                      style: TextStyle(
                        color: t.inkDim,
                        fontSize: RelayLayout.bodySize(f) - 1,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // A second focus target on the row, so a remote can reach Remove
              // with Right instead of needing a long press.
              RelayTappable(
                borderRadius: 999,
                onTap: () => _confirmRemove(context, ref),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Icon(Icons.delete_outline, color: t.inkDim, size: 22),
                ),
              ),
            ],
          ),
          if (record.state == DownloadState.downloading ||
              record.state == DownloadState.paused) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: record.fraction,
                minHeight: 4,
                color: t.accent,
                backgroundColor: t.line,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmRemove(BuildContext context, WidgetRef ref) async {
    final controller = ref.read(downloadsProvider.notifier);
    final t = RelayTheme.of(context);
    final size = record.isComplete
        ? (record.totalBytes ?? 0)
        : record.receivedBytes;
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: t.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          record.isComplete
              ? tr.downloads.deleteTitle
              : tr.downloads.cancelTitle,
          style: TextStyle(
            color: t.ink,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          size > 0
              ? tr.downloads.removeBodyFreeing(
                  title: record.title,
                  size: formatBytes(size),
                )
              : tr.downloads.removeBody(title: record.title),
          style: TextStyle(color: t.inkDim, fontSize: 14, height: 1.55),
        ),
        actions: [
          TextButton(
            // Focused first: removing is the one thing here that cannot be
            // undone, so a stray select does the safe thing.
            autofocus: true,
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(foregroundColor: t.inkDim),
            child: Text(tr.downloads.keepIt),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: t.accent,
              foregroundColor: t.accentInk,
            ),
            child: Text(tr.downloads.delete),
          ),
        ],
      ),
    );
    if (yes == true) {
      await controller.remove(record.serverId, record.ratingKey);
    }
  }
}
