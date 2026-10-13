import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/relay_theme.dart';
import '../../core/theme/relay_widgets.dart';
import '../../data/downloads/download_record.dart';
import '../library/poster_grid.dart' show LibraryEmptyState;
import 'downloads_controller.dart';

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
  if (h == 0) return '$m min';
  return m == 0 ? '$h h' : '$h h $m min';
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
    final used = ref.read(downloadsProvider.notifier).bytesUsed;
    final unfinished = items.any((r) => !r.isComplete);

    return Scaffold(
      backgroundColor: t.bg,
      body: SafeArea(
        child: items.isEmpty
            ? const LibraryEmptyState(
                icon: Icons.download_outlined,
                message:
                    'Nothing downloaded yet. Press and hold a movie or episode '
                    'from your Plex library and choose Download, then watch it '
                    'here with no network.',
              )
            : ListView(
                padding: RelayLayout.pagePadding(
                  f,
                ).copyWith(top: 20, bottom: 40),
                children: [
                  Text(
                    'Downloads',
                    style: TextStyle(
                      color: t.ink,
                      fontSize: RelayLayout.titleSize(f),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${items.length} ${items.length == 1 ? 'item' : 'items'}'
                    ' · ${formatBytes(used)} on this device',
                    style: TextStyle(
                      color: t.inkDim,
                      fontSize: RelayLayout.bodySize(f),
                    ),
                  ),
                  if (unfinished) ...[
                    const SizedBox(height: 6),
                    Text(
                      // Honest about the limit (§18.3): there is no background
                      // service, so closing the app stops them.
                      'Downloads continue while the app is open. Closing it '
                      'pauses them, and nothing already saved is lost.',
                      style: TextStyle(
                        color: t.inkDim,
                        fontSize: RelayLayout.bodySize(f) - 1,
                        height: 1.5,
                      ),
                    ),
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
            ? 'Downloading, ${formatBytes(record.receivedBytes)}'
            : 'Downloading $percent% · ${formatBytes(record.receivedBytes)}'
                  ' of ${formatBytes(size!)}',
      DownloadState.queued => 'Waiting for its turn',
      DownloadState.paused =>
        percent == null ? 'Paused' : 'Paused at $percent% · select to resume',
      DownloadState.failed =>
        '${record.error ?? 'It did not finish.'} Select to try again.',
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
              Icon(
                icon,
                color: record.isComplete ? t.accent : t.inkDim,
                size: 26,
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
          record.isComplete ? 'Delete this download?' : 'Cancel this download?',
          style: TextStyle(
            color: t.ink,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          '"${record.title}" will be removed from this device'
          '${size > 0 ? ', freeing ${formatBytes(size)}' : ''}. It stays on '
          'your Plex server.',
          style: TextStyle(color: t.inkDim, fontSize: 14, height: 1.55),
        ),
        actions: [
          TextButton(
            // Focused first: removing is the one thing here that cannot be
            // undone, so a stray select does the safe thing.
            autofocus: true,
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(foregroundColor: t.inkDim),
            child: const Text('Keep it'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: t.accent,
              foregroundColor: t.accentInk,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (yes == true) {
      await controller.remove(record.serverId, record.ratingKey);
    }
  }
}
