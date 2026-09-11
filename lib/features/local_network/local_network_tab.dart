import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/relay_theme.dart';
import '../../core/theme/relay_widgets.dart';
import '../../data/filesystem/device_video_source.dart';
import '../../data/filesystem/saf_folder_source.dart';
import '../settings/settings_controller.dart';
import '../library/poster_grid.dart';

final deviceVideoSourceProvider =
    Provider<DeviceVideoSource>((ref) => const DeviceVideoSource());

final safFolderSourceProvider = Provider<SafFolderSource>((ref) {
  return SafFolderSource(ref.watch(appSettingsStoreProvider));
});

/// Folders the user granted through SAF.
final safFoldersProvider =
    NotifierProvider<SafFoldersController, List<SafFolder>>(
  SafFoldersController.new,
);

class SafFoldersController extends Notifier<List<SafFolder>> {
  SafFolderSource get _source => ref.read(safFolderSourceProvider);

  @override
  List<SafFolder> build() => _source.folders();

  Future<void> pick() async {
    await _source.pickFolder();
    state = _source.folders();
  }

  Future<void> forget(String uri) async {
    await _source.forget(uri);
    state = _source.folders();
  }
}

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

    final picked = ref.watch(safFoldersProvider);

    // A picked folder is independent of the MediaStore permission: SAF grants
    // access to that folder specifically, so someone who declined the media
    // prompt can still use a folder they chose themselves.
    if (access != true && picked.isEmpty) {
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
              const SizedBox(height: 14),
              RelayTextButton(
                label: 'Or pick a folder instead',
                onPressed: () => ref.read(safFoldersProvider.notifier).pick(),
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

    final deviceFolders = ref.watch(_foldersProvider);

    return ListView(
      padding: RelayLayout.pagePadding(f).copyWith(top: 12, bottom: 28),
      children: [
        if (picked.isNotEmpty) ...[
          _Heading(label: 'Folders you picked'),
          for (final folder in picked)
            _FolderRow(
              label: folder.name,
              onTap: () => context.push(
                '/saf/${Uri.encodeComponent(folder.uri)}',
                extra: folder.name,
              ),
              onForget: () =>
                  ref.read(safFoldersProvider.notifier).forget(folder.uri),
            ),
          const SizedBox(height: 18),
        ],
        if (access == true) ...[
          _Heading(label: 'On this device'),
          ...switch (deviceFolders) {
            AsyncData(:final value) when value.isEmpty => [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'No videos found on this device.',
                    style: TextStyle(color: t.inkDim, fontSize: 13),
                  ),
                ),
              ],
            AsyncData(:final value) => [
                for (final folder in value)
                  _FolderRow(
                    label: folder.name,
                    trailing: '${folder.count}',
                    onTap: () => context.push('/local/${folder.id}'),
                  ),
              ],
            AsyncError(:final error) => [
                Text('$error', style: TextStyle(color: t.inkDim)),
              ],
            _ => [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: CircularProgressIndicator(color: t.accent),
                  ),
                ),
              ],
          },
          const SizedBox(height: 18),
        ],
        Row(
          children: [
            TextButton.icon(
              onPressed: () => ref.read(safFoldersProvider.notifier).pick(),
              icon: Icon(Icons.create_new_folder_outlined,
                  size: 18, color: t.accent),
              label: Text('Add a folder', style: TextStyle(color: t.accent)),
            ),
            if (access != true)
              TextButton.icon(
                onPressed: () =>
                    ref.read(deviceAccessProvider.notifier).request(),
                icon: Icon(Icons.smartphone_outlined,
                    size: 18, color: t.accent),
                label: Text('Scan this device',
                    style: TextStyle(color: t.accent)),
              ),
          ],
        ),
      ],
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        label,
        style: TextStyle(
          color: t.inkDim,
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _FolderRow extends StatelessWidget {
  const _FolderRow({
    required this.label,
    required this.onTap,
    this.trailing,
    this.onForget,
  });

  final String label;
  final VoidCallback onTap;
  final String? trailing;
  final VoidCallback? onForget;

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
            padding: const EdgeInsets.fromLTRB(14, 14, 6, 14),
            child: Row(
              children: [
                Icon(Icons.folder_outlined, color: t.inkDim),
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
                  Text(trailing!,
                      style: TextStyle(color: t.inkDim, fontSize: 13)),
                if (onForget != null)
                  IconButton(
                    tooltip: 'Forget this folder',
                    icon: Icon(Icons.close, color: t.inkDim, size: 18),
                    onPressed: onForget,
                  )
                else
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
