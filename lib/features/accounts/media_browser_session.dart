import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/jellyfin/media_browser_service.dart';
import '../../data/jellyfin/media_browser_store.dart';
import '../library/library_cache_provider.dart';

final mediaBrowserStoreProvider = Provider<MediaBrowserStore>(
  (ref) => MediaBrowserStore(),
);

/// Who this install is to a Jellyfin or Emby server. Read once from secure
/// storage; the sign-in screen and the restored sessions share it.
final mediaBrowserClientProvider = FutureProvider<MediaBrowserClientInfo>((
  ref,
) async {
  final id = await ref.watch(mediaBrowserStoreProvider).deviceId();
  String device;
  try {
    device = Platform.localHostname;
  } catch (_) {
    device = Platform.operatingSystem;
  }
  return MediaBrowserClientInfo(deviceId: id, device: device);
});

/// The Jellyfin and Emby servers this device is signed in to (§6.2).
///
/// Restored from secure storage without probing, as Plex servers are: a
/// sleeping NAS stays in the list and fails per request, rather than
/// disappearing from Sources until it is added again.
final mediaBrowserSessionProvider =
    NotifierProvider<MediaBrowserSession, List<MediaBrowserService>>(
      MediaBrowserSession.new,
    );

class MediaBrowserSession extends Notifier<List<MediaBrowserService>> {
  MediaBrowserStore get _store => ref.read(mediaBrowserStoreProvider);

  @override
  List<MediaBrowserService> build() {
    unawaited(_restore());
    return const [];
  }

  Future<void> _restore() async {
    final stored = await _store.servers();
    if (stored.isEmpty || !ref.mounted) return;
    final client = await ref.read(mediaBrowserClientProvider.future);
    if (!ref.mounted) return;
    state = [
      for (final s in stored)
        MediaBrowserService(info: s.info, auth: s.auth, client: client),
    ];
  }

  /// Keeps a successful sign-in. Signing in to the same server again (as
  /// someone else, or after a password change) replaces the old one.
  Future<void> add(MediaBrowserServerInfo info, MediaBrowserAuth auth) async {
    final client = await ref.read(mediaBrowserClientProvider.future);
    final next = [
      for (final s in state)
        if (s.id != info.id) s,
      MediaBrowserService(info: info, auth: auth, client: client),
    ];
    await _persist(next);
    state = next;
  }

  /// Signs this device out of [serverId], here only. The token stays valid on
  /// the server until its owner revokes the device there; there is no call
  /// that ends just this session on both products alike.
  Future<void> disconnect(String serverId) async {
    final next = [
      for (final s in state)
        if (s.id != serverId) s,
    ];
    await _persist(next);
    await forgetSourceCache(ref, 'plex|$serverId|');
    state = next;
  }

  Future<void> _persist(List<MediaBrowserService> servers) => _store.setServers([
    for (final s in servers)
      StoredMediaBrowserServer(info: s.info, auth: s.auth),
  ]);
}
