import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/relay_theme.dart';
import '../../data/filesystem/saf_folder_source.dart';
import '../library/poster_grid.dart';
import 'local_network_tab.dart';

/// What is inside one SAF folder: subfolders first, then videos.
class SafFolderContents {
  const SafFolderContents({required this.folders, required this.videos});

  final List<SafFolder> folders;
  final List<SafVideo> videos;

  bool get isEmpty => folders.isEmpty && videos.isEmpty;
}

final safContentsProvider =
    FutureProvider.family<SafFolderContents, String>((ref, uri) async {
  final source = ref.watch(safFolderSourceProvider);
  return SafFolderContents(
    folders: await source.subfoldersIn(uri),
    videos: await source.videosIn(uri),
  );
});

/// Breadcrumb-style browsing of a granted folder (§12 screen 4).
class SafFolderScreen extends ConsumerWidget {
  const SafFolderScreen({super.key, required this.uri, this.title});

  final String uri;
  final String? title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = RelayTheme.of(context);
    final f = RelayLayout.of(context);
    final contents = ref.watch(safContentsProvider(uri));

    return Scaffold(
      backgroundColor: t.bg,
      appBar: AppBar(
        backgroundColor: t.bg,
        surfaceTintColor: Colors.transparent,
        foregroundColor: t.ink,
        title: Text(title ?? 'Folder'),
      ),
      body: contents.when(
        loading: () => Center(child: CircularProgressIndicator(color: t.accent)),
        error: (e, _) => LibraryEmptyState(
          icon: Icons.folder_off_outlined,
          // A SAF failure is usually a lost grant rather than a missing folder,
          // and saying so points at the fix instead of at the file system.
          message: 'This folder is no longer readable. Android may have '
              'dropped the permission — remove it and pick it again.\n\n$e',
          onRetry: () => ref.invalidate(safContentsProvider(uri)),
        ),
        data: (data) {
          if (data.isEmpty) {
            return const LibraryEmptyState(
              icon: Icons.folder_outlined,
              message: 'No videos or subfolders here.',
            );
          }
          return ListView(
            padding: RelayLayout.pagePadding(f).copyWith(top: 12, bottom: 28),
            children: [
              for (final folder in data.folders)
                _Row(
                  icon: Icons.folder_outlined,
                  label: folder.name,
                  onTap: () => context.push(
                    '/saf/${Uri.encodeComponent(folder.uri)}',
                    extra: folder.name,
                  ),
                ),
              // Played through §7.2's loopback bridge: libmpv cannot open a
              // `content://` URI directly, so the size travels with the route
              // because the bridge must answer Content-Length before any read.
              for (final video in data.videos)
                _Row(
                  icon: Icons.movie_outlined,
                  label: video.name,
                  trailing: _size(video.sizeBytes),
                  onTap: () => context.push(
                    '/safplay/${Uri.encodeComponent(video.uri)}',
                    extra: (video.name, video.sizeBytes),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  static String? _size(int bytes) {
    if (bytes <= 0) return null;
    final mb = bytes / (1024 * 1024);
    return mb >= 1024
        ? '${(mb / 1024).toStringAsFixed(1)} GB'
        : '${mb.round()} MB';
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final String? trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: t.surface,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(icon, color: t.inkDim),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: t.ink,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (trailing != null)
                  Text(
                    trailing!,
                    style: TextStyle(color: t.inkDim, fontSize: 12.5),
                  ),
                const SizedBox(width: 10),
                Icon(Icons.chevron_right, color: t.inkDim),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
