import 'dart:async';

import 'package:dart_plex/dart_plex.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/plex/plex_service.dart';
import '../../data/plex/plex_session_store.dart';

/// Where the user is in the link flow.
enum PlexStage {
  /// Reading stored credentials — the app shows a splash, not a sign-in form,
  /// so a returning user never sees a flash of "Connect to Plex".
  restoring,

  /// No servers connected.
  signedOut,

  /// A code is on screen and we are polling plex.tv.
  awaitingApproval,

  /// Linked, and picking which server(s) to connect.
  choosingServer,

  /// At least one server is connected.
  ready,
}

/// A connected server and the client bound to it.
class ConnectedServer {
  const ConnectedServer({required this.stored, required this.service});

  final StoredPlexServer stored;
  final PlexService service;

  String get id => stored.id;
  String get name => stored.name;
}

class PlexState {
  const PlexState({
    this.stage = PlexStage.restoring,
    this.linkCode,
    this.available = const [],
    this.servers = const [],
    this.error,
    this.busy = false,
  });

  final PlexStage stage;
  final PlexLinkCode? linkCode;

  /// Servers the account can reach, from the last discovery.
  final List<PlexResource> available;

  /// Servers actually connected.
  final List<ConnectedServer> servers;

  final String? error;
  final bool busy;

  bool get hasAccount => available.isNotEmpty || servers.isNotEmpty;

  /// Servers discovered but not yet connected — the candidates for "Add".
  List<PlexResource> get connectable {
    final ids = servers.map((s) => s.id).toSet();
    return available
        .where((r) => !ids.contains(r.clientIdentifier))
        .toList();
  }

  PlexState copyWith({
    PlexStage? stage,
    PlexLinkCode? linkCode,
    List<PlexResource>? available,
    List<ConnectedServer>? servers,
    String? error,
    bool? busy,
    bool clearError = false,
  }) {
    return PlexState(
      stage: stage ?? this.stage,
      linkCode: linkCode ?? this.linkCode,
      available: available ?? this.available,
      servers: servers ?? this.servers,
      error: clearError ? null : (error ?? this.error),
      busy: busy ?? this.busy,
    );
  }
}

final plexSessionStoreProvider =
    Provider<PlexSessionStore>((ref) => PlexSessionStore());

/// Every connected server, in connection order.
final connectedServersProvider = Provider<List<ConnectedServer>>((ref) {
  return ref.watch(plexSessionProvider.select((s) => s.servers));
});

/// The client for one server. Throws rather than returning null: a caller
/// holding a server id for a server that is gone has a bug, and a silent null
/// would surface as an empty screen instead.
PlexService plexServiceFor(WidgetRef ref, String serverId) {
  final servers = ref.read(connectedServersProvider);
  for (final server in servers) {
    if (server.id == serverId) return server.service;
  }
  throw StateError('No connected Plex server with id "$serverId".');
}

final plexSessionProvider = NotifierProvider<PlexSessionController, PlexState>(
  PlexSessionController.new,
);

class PlexSessionController extends Notifier<PlexState> {
  /// Account-level client: owns the PIN flow and server discovery. It is never
  /// connected to a server — each server gets its own client with its own token.
  PlexService? _account;
  Timer? _poll;

  @override
  PlexState build() {
    ref.onDispose(() => _poll?.cancel());
    unawaited(_restore());
    return const PlexState();
  }

  PlexSessionStore get _store => ref.read(plexSessionStoreProvider);

  Future<PlexService> _ensureAccount() async {
    return _account ??= PlexService(clientId: await _store.clientId());
  }

  Future<void> _restore() async {
    final stored = await _store.servers();
    if (stored.isEmpty) {
      state = state.copyWith(stage: PlexStage.signedOut);
      return;
    }

    final clientId = await _store.clientId();
    final accountToken = await _store.accountToken();
    if (accountToken != null) {
      (await _ensureAccount()).useToken(accountToken);
    }

    // Restored without probing each server first. An earlier version called
    // `sections()` on every server before declaring it connected and dropped
    // the ones that failed — which meant a sleeping NAS silently disappeared
    // from Sources and had to be re-added by hand, and startup blocked on the
    // slowest server because the checks ran in sequence.
    //
    // A stored server stays in the list. Whether it answers right now is a
    // per-request question, handled by the timeouts in the library and search
    // queries, and surfaced per server in Settings → Sources.
    final connected = [
      for (final server in stored)
        ConnectedServer(
          stored: server,
          service: PlexService(
            clientId: clientId,
            serverId: server.id,
            serverName: server.name,
          )..reconnect(baseUrl: server.baseUrl, token: server.token),
        ),
    ];

    state = state.copyWith(stage: PlexStage.ready, servers: connected);
    unawaited(refreshAvailable());
  }

  /// Re-runs discovery so "Add another server" has something to offer.
  Future<void> refreshAvailable() async {
    final account = _account;
    if (account == null) return;
    try {
      state = state.copyWith(available: await account.servers());
    } catch (_) {
      // Discovery is a convenience here; failing it must not disturb servers
      // that are already connected and working.
    }
  }

  Future<void> startLink() async {
    state = state.copyWith(busy: true, clearError: true);
    try {
      final account = await _ensureAccount();
      final code = await account.startLink();
      state = state.copyWith(
        stage: PlexStage.awaitingApproval,
        linkCode: code,
        busy: false,
      );
      _startPolling(code);
    } catch (e) {
      state = state.copyWith(busy: false, error: '$e');
    }
  }

  void _startPolling(PlexLinkCode code) {
    _poll?.cancel();
    _poll = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (DateTime.now().isAfter(code.expiresAt)) {
        timer.cancel();
        state = state.copyWith(
          stage: PlexStage.signedOut,
          error: 'That code expired. Try again.',
        );
        return;
      }
      try {
        final token = await _account?.pollLink(code.pinId);
        if (token == null) return;
        timer.cancel();
        await _onTokenAcquired(token);
      } catch (e) {
        timer.cancel();
        state = state.copyWith(stage: PlexStage.signedOut, error: '$e');
      }
    });
  }

  Future<void> _onTokenAcquired(String token) async {
    state = state.copyWith(busy: true);
    final account = await _ensureAccount();
    account.useToken(token);
    await _store.setAccountToken(token);
    try {
      final available = await account.servers();
      if (available.isEmpty) {
        state = state.copyWith(
          stage: PlexStage.signedOut,
          busy: false,
          error: 'That account has no Plex servers.',
        );
        return;
      }
      state = state.copyWith(available: available, busy: false);
      if (available.length == 1) {
        await connect(available.first);
        return;
      }
      state = state.copyWith(stage: PlexStage.choosingServer);
    } catch (e) {
      state = state.copyWith(
        stage: PlexStage.signedOut,
        busy: false,
        error: '$e',
      );
    }
  }

  /// Connects [resource] and adds it alongside any already-connected servers.
  Future<void> connect(PlexResource resource) async {
    state = state.copyWith(busy: true, clearError: true);
    try {
      final clientId = await _store.clientId();
      final service = PlexService(
        clientId: clientId,
        serverId: resource.clientIdentifier,
        serverName: resource.name,
      );
      final baseUrl = service.connectTo(resource);

      final stored = StoredPlexServer(
        id: resource.clientIdentifier,
        name: resource.name,
        baseUrl: baseUrl,
        token: resource.accessToken,
      );
      final servers = [
        ...state.servers.where((s) => s.id != stored.id),
        ConnectedServer(stored: stored, service: service),
      ];
      await _store.setServers([for (final s in servers) s.stored]);

      state = state.copyWith(
        stage: PlexStage.ready,
        servers: servers,
        busy: false,
      );
    } catch (e) {
      state = state.copyWith(busy: false, error: '$e');
    }
  }

  /// Disconnects one server, leaving the rest and the account link intact.
  Future<void> disconnect(String serverId) async {
    final servers = state.servers.where((s) => s.id != serverId).toList();
    await _store.setServers([for (final s in servers) s.stored]);
    state = state.copyWith(
      servers: servers,
      stage: servers.isEmpty ? PlexStage.signedOut : PlexStage.ready,
    );
  }

  /// Drops every server and the account token.
  Future<void> signOut() async {
    _poll?.cancel();
    await _store.clear();
    _account = null;
    state = const PlexState(stage: PlexStage.signedOut);
  }
}
