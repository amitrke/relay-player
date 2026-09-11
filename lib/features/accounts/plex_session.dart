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

  /// No usable link.
  signedOut,

  /// A code is on screen and we are polling plex.tv.
  awaitingApproval,

  /// Linked, but the account has more than one server to choose from.
  choosingServer,

  /// Connected and ready to browse.
  ready,
}

class PlexState {
  const PlexState({
    this.stage = PlexStage.restoring,
    this.linkCode,
    this.servers = const [],
    this.serverName,
    this.error,
    this.busy = false,
  });

  final PlexStage stage;
  final PlexLinkCode? linkCode;
  final List<PlexResource> servers;
  final String? serverName;
  final String? error;
  final bool busy;

  PlexState copyWith({
    PlexStage? stage,
    PlexLinkCode? linkCode,
    List<PlexResource>? servers,
    String? serverName,
    String? error,
    bool? busy,
    bool clearError = false,
  }) {
    return PlexState(
      stage: stage ?? this.stage,
      linkCode: linkCode ?? this.linkCode,
      servers: servers ?? this.servers,
      serverName: serverName ?? this.serverName,
      error: clearError ? null : (error ?? this.error),
      busy: busy ?? this.busy,
    );
  }
}

final plexSessionStoreProvider =
    Provider<PlexSessionStore>((ref) => PlexSessionStore());

/// The connected [PlexService]. Only valid once [PlexState.stage] is
/// [PlexStage.ready].
final plexServiceProvider = Provider<PlexService>((ref) {
  // Watch the state, not just the notifier: the notifier instance is stable, so
  // watching it alone would cache a null service from before the link resolved.
  ref.watch(plexSessionProvider);
  final service = ref.read(plexSessionProvider.notifier).service;
  if (service == null) {
    throw StateError('Plex service read before the session was ready.');
  }
  return service;
});

final plexSessionProvider =
    NotifierProvider<PlexSessionController, PlexState>(
  PlexSessionController.new,
);

class PlexSessionController extends Notifier<PlexState> {
  PlexService? _service;
  Timer? _poll;

  PlexService? get service => _service;

  @override
  PlexState build() {
    ref.onDispose(() => _poll?.cancel());
    unawaited(_restore());
    return const PlexState();
  }

  PlexSessionStore get _store => ref.read(plexSessionStoreProvider);

  Future<PlexService> _ensureService() async {
    return _service ??= PlexService(clientId: await _store.clientId());
  }

  /// Reconnects a stored link without making the user re-approve.
  Future<void> _restore() async {
    final stored = await _store.read();
    if (stored == null) {
      state = state.copyWith(stage: PlexStage.signedOut);
      return;
    }
    final service = await _ensureService();
    service.reconnect(baseUrl: stored.baseUrl, token: stored.token);

    // Prove the stored link still works before claiming to be ready — a
    // revoked token or a server that moved should land the user on sign-in
    // with a reason, not on an empty library that looks broken.
    try {
      await service.sections();
      state = state.copyWith(
        stage: PlexStage.ready,
        serverName: stored.serverName,
      );
    } catch (_) {
      await _store.clear();
      state = state.copyWith(
        stage: PlexStage.signedOut,
        error: 'That Plex link expired. Please connect again.',
      );
    }
  }

  Future<void> startLink() async {
    state = state.copyWith(busy: true, clearError: true);
    try {
      final service = await _ensureService();
      final code = await service.startLink();
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
        final token = await _service?.pollLink(code.pinId);
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
    final service = await _ensureService();
    service.useToken(token);
    try {
      final servers = await service.servers();
      if (servers.isEmpty) {
        state = state.copyWith(
          stage: PlexStage.signedOut,
          busy: false,
          error: 'That account has no Plex servers.',
        );
        return;
      }
      if (servers.length == 1) {
        await chooseServer(servers.first);
        return;
      }
      state = state.copyWith(
        stage: PlexStage.choosingServer,
        servers: servers,
        busy: false,
      );
    } catch (e) {
      state = state.copyWith(
        stage: PlexStage.signedOut,
        busy: false,
        error: '$e',
      );
    }
  }

  Future<void> chooseServer(PlexResource server) async {
    state = state.copyWith(busy: true, clearError: true);
    try {
      final service = await _ensureService();
      final baseUrl = service.connectTo(server);
      await _store.write(StoredPlexSession(
        token: server.accessToken,
        baseUrl: baseUrl,
        serverName: server.name,
      ));
      state = state.copyWith(
        stage: PlexStage.ready,
        serverName: server.name,
        busy: false,
      );
    } catch (e) {
      state = state.copyWith(
        stage: PlexStage.choosingServer,
        busy: false,
        error: '$e',
      );
    }
  }

  Future<void> signOut() async {
    _poll?.cancel();
    await _store.clear();
    _service = null;
    state = const PlexState(stage: PlexStage.signedOut);
  }
}
