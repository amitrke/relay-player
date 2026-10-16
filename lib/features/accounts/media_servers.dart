import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/media_server.dart';
import 'plex_session.dart';

/// One connected personal media server, whichever kind (§6.2).
///
/// The rest of the app holds this and nothing more specific: the library
/// tabs, search, show pages, the player, downloads, offline sync and the
/// watch trackers all ask [service], and never need to know whether it is
/// Plex, Jellyfin or Emby. Signing in and out is each kind's own controller.
class ConnectedServer {
  const ConnectedServer({required this.service});

  final MediaServer service;

  String get id => service.id;
  String get name => service.name;
  ServerKind get kind => service.kind;
}

/// The Jellyfin and Emby servers, set by their session controller. A seam of
/// its own so this file does not depend on that controller.
final mediaBrowserServersProvider = Provider<List<MediaServer>>(
  (ref) => const [],
);

/// Every connected server, Plex first, each kind in connection order.
final connectedServersProvider = Provider<List<ConnectedServer>>((ref) {
  final plex = ref.watch(plexSessionProvider.select((s) => s.servers));
  final others = ref.watch(mediaBrowserServersProvider);
  return [
    for (final p in plex) ConnectedServer(service: p.service),
    for (final s in others) ConnectedServer(service: s),
  ];
});

/// The client for one server. Throws rather than returning null: a caller
/// holding a server id for a server that is gone has a bug, and a silent null
/// would surface as an empty screen instead.
MediaServer mediaServerFor(WidgetRef ref, String serverId) {
  for (final server in ref.read(connectedServersProvider)) {
    if (server.id == serverId) return server.service;
  }
  throw StateError('No connected server with id "$serverId".');
}

/// Removes [server] through the controller that owns its kind.
Future<void> disconnectServer(WidgetRef ref, ConnectedServer server) =>
    switch (server.kind) {
      ServerKind.plex =>
        ref.read(plexSessionProvider.notifier).disconnect(server.id),
      ServerKind.jellyfin ||
      ServerKind.emby => Future<void>.value(),
    };

/// The same lookup for a provider body.
MediaServer? mediaServerIn(Ref ref, String serverId) {
  for (final server in ref.watch(connectedServersProvider)) {
    if (server.id == serverId) return server.service;
  }
  return null;
}
