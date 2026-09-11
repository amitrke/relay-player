import 'package:photo_manager/photo_manager.dart';

/// A folder of videos on the device, as MediaStore groups them.
class DeviceVideoFolder {
  const DeviceVideoFolder({
    required this.id,
    required this.name,
    required this.count,
  });

  final String id;
  final String name;
  final int count;
}

/// One video file on the device.
class DeviceVideo {
  const DeviceVideo({
    required this.id,
    required this.title,
    required this.duration,
    this.sizeBytes,
  });

  final String id;
  final String title;
  final Duration duration;
  final int? sizeBytes;
}

/// Videos on the device, via MediaStore (§7.1).
///
/// **This deliberately does not request `MANAGE_EXTERNAL_STORAGE`.** Google Play
/// lists that permission under invalid uses for generic media playback, so it is
/// not a fallback we can reach for if MediaStore proves awkward — §7.1 chose
/// this path precisely because it is the compliant one. On Android 13+ the
/// permission asked for is the scoped `READ_MEDIA_VIDEO`.
class DeviceVideoSource {
  const DeviceVideoSource();

  /// Asks for media access, returning whether we may read.
  ///
  /// Android 14+ can grant *partial* access — the user picks specific items.
  /// That counts as authorised: the correct response is to show what we were
  /// given, not to refuse and demand everything.
  Future<bool> requestAccess() async {
    final state = await PhotoManager.requestPermissionExtend();
    return state.isAuth || state.hasAccess;
  }

  Future<List<DeviceVideoFolder>> folders() async {
    final paths = await PhotoManager.getAssetPathList(
      type: RequestType.video,
      // `hasAll: false`, not `onlyAll: false`. The latter only says "do not
      // return *just* the all-album" and still includes it, so every video
      // appeared twice — once under its real folder and once under "Recent".
      hasAll: false,
    );

    final folders = <DeviceVideoFolder>[];
    for (final path in paths) {
      final count = await path.assetCountAsync;
      if (count == 0) continue;
      folders.add(DeviceVideoFolder(
        id: path.id,
        name: path.name,
        count: count,
      ));
    }
    folders.sort((a, b) => b.count.compareTo(a.count));
    return folders;
  }

  Future<List<DeviceVideo>> videosIn(String folderId, {int limit = 200}) async {
    final paths = await PhotoManager.getAssetPathList(
      type: RequestType.video,
      hasAll: false,
    );
    final folder = paths.where((p) => p.id == folderId).firstOrNull;
    if (folder == null) return const [];

    final assets = await folder.getAssetListRange(start: 0, end: limit);
    return [
      for (final asset in assets)
        DeviceVideo(
          id: asset.id,
          title: asset.title ?? 'Video',
          duration: Duration(seconds: asset.duration),
        ),
    ];
  }

  /// The on-disk path media_kit can open.
  ///
  /// MediaStore hands back an id, not a path — the file may not even be local
  /// until it is materialised — so this has to be resolved at play time rather
  /// than stored in the list.
  Future<String?> filePathOf(String assetId) async {
    final asset = await AssetEntity.fromId(assetId);
    final file = await asset?.originFile;
    return file?.path;
  }

  Future<DeviceVideo?> videoById(String assetId) async {
    final asset = await AssetEntity.fromId(assetId);
    if (asset == null) return null;
    return DeviceVideo(
      id: asset.id,
      title: asset.title ?? 'Video',
      duration: Duration(seconds: asset.duration),
    );
  }
}
