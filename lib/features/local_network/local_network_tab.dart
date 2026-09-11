import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/relay_theme.dart';
import '../../core/theme/relay_widgets.dart';
import '../../data/filesystem/device_video_source.dart';
import '../library/poster_grid.dart';

final deviceVideoSourceProvider =
    Provider<DeviceVideoSource>((ref) => const DeviceVideoSource());

/// Whether the user has granted media access yet (§7.1).
final deviceAccessProvider =
    NotifierProvider<DeviceAccessController, bool?>(
  DeviceAccessController.new,
);

class DeviceAccessController extends Notifier<bool?> {
  /// Null means "not asked yet" — distinct from denied, because the tab shows
  /// a prompt in one case and an explanation in the other.
  @override
  bool? build() => null;

  Future<void> request() async {
    state = await ref.read(deviceVideoSourceProvider).requestAccess();
  }
}

final _foldersProvider =
    FutureProvider<List<DeviceVideoFolder>>((ref) async {
  if (ref.watch(deviceAccessProvider) != true) return const [];
  return ref.watch(deviceVideoSourceProvider).folders();
});

/// Local & Network (§12 screen 3).
///
/// Tree-shaped, not catalogue-shaped: §2 keeps this off the `ContentRepository`
/// interface because a folder of files has no movie/series structure to merge
/// into Movies or Series. So it browses folders rather than showing a poster
/// grid.
class LocalNetworkTab extends ConsumerWidget {
  const LocalNetworkTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = RelayTheme.of(context);
    final f = RelayLayout.of(context);
    final access = ref.watch(deviceAccessProvider);

    if (access != true) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.folder_outlined, color: t.inkDim, size: 34),
              const SizedBox(height: 14),
              Text(
                access == false
                    ? 'Relay Player cannot see your videos without media '
                        'access. You can grant it in Android settings.'
                    : 'Play videos stored on this device.\nRelay Player only '
                        'asks for video access, never full file access.',
                textAlign: TextAlign.center,
                style: TextStyle(color: t.inkDim, height: 1.5),
              ),
              const SizedBox(height: 18),
              RelayButton(
                label: access == false ? 'Try again' : 'Allow video access',
                onPressed: () =>
                    ref.read(deviceAccessProvider.notifier).request(),
              ),
              const SizedBox(height: 26),
              Text(
                'Network shares are not connectable in this build.',
                textAlign: TextAlign.center,
                style: TextStyle(color: t.inkDim, fontSize: 12.5),
              ),
            ],
          ),
        ),
      );
    }

    final folders = ref.watch(_foldersProvider);

    return folders.when(
      loading: () => Center(child: CircularProgressIndicator(color: t.accent)),
      error: (e, _) => LibraryEmptyState(
        icon: Icons.cloud_off_outlined,
        message: '$e',
        onRetry: () => ref.invalidate(_foldersProvider),
      ),
      data: (list) {
        if (list.isEmpty) {
          return const LibraryEmptyState(
            icon: Icons.folder_outlined,
            message: 'No videos found on this device.',
          );
        }
        return ListView.builder(
          padding: RelayLayout.pagePadding(f).copyWith(top: 12, bottom: 28),
          itemCount: list.length,
          itemBuilder: (context, i) {
            final folder = list[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: t.surface,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => context.push('/local/${folder.id}'),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Icon(Icons.folder_outlined, color: t.inkDim),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            folder.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: t.ink,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          '${folder.count}',
                          style: TextStyle(color: t.inkDim, fontSize: 13),
                        ),
                        const SizedBox(width: 10),
                        Icon(Icons.chevron_right, color: t.inkDim),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

final _videosProvider =
    FutureProvider.family<List<DeviceVideo>, String>((ref, folderId) {
  return ref.watch(deviceVideoSourceProvider).videosIn(folderId);
});

/// The files inside one device folder.
class LocalFolderScreen extends ConsumerWidget {
  const LocalFolderScreen({super.key, required this.folderId});

  final String folderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = RelayTheme.of(context);
    final f = RelayLayout.of(context);
    final videos = ref.watch(_videosProvider(folderId));

    return Scaffold(
      backgroundColor: t.bg,
      appBar: AppBar(
        backgroundColor: t.bg,
        surfaceTintColor: Colors.transparent,
        foregroundColor: t.ink,
        title: const Text('Folder'),
      ),
      body: videos.when(
        loading: () => Center(child: CircularProgressIndicator(color: t.accent)),
        error: (e, _) => LibraryEmptyState(
          icon: Icons.cloud_off_outlined,
          message: '$e',
          onRetry: () => ref.invalidate(_videosProvider(folderId)),
        ),
        data: (list) => ListView.builder(
          padding: RelayLayout.pagePadding(f).copyWith(top: 12, bottom: 28),
          itemCount: list.length,
          itemBuilder: (context, i) {
            final video = list[i];
            final minutes = video.duration.inMinutes;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: t.surface,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => context.push('/localplay/${video.id}'),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Icon(Icons.movie_outlined, color: t.inkDim),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            video.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: t.ink,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (minutes > 0)
                          Text(
                            '$minutes min',
                            style: TextStyle(color: t.inkDim, fontSize: 12.5),
                          ),
                        const SizedBox(width: 10),
                        Icon(Icons.play_arrow, color: t.inkDim),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
