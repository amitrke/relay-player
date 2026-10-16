import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../data/seerr/seerr_client.dart';
import '../accounts/plex_session.dart';

/// The Seerr connection, in secure storage (§3): it holds an API key or a
/// session cookie.
class SeerrStore {
  SeerrStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  static const _key = 'seerr.connection';

  Future<SeerrClient?> load() async {
    final raw = await _storage.read(key: _key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final d = jsonDecode(raw);
      if (d is! Map) return null;
      final session = SeerrSession.fromJson(d['session']);
      final base = d['baseUrl'];
      if (session == null || base is! String) return null;
      return SeerrClient(
        SeerrServerInfo(
          baseUrl: base,
          title: '${d['title'] ?? 'Seerr'}',
          mediaServer: (d['mediaServer'] as num?)?.toInt() ?? 1,
          localLogin: d['localLogin'] == true,
        ),
        session,
      );
    } on FormatException {
      return null;
    }
  }

  Future<void> save(SeerrClient? client) async {
    if (client == null) {
      await _storage.delete(key: _key);
      return;
    }
    await _storage.write(
      key: _key,
      value: jsonEncode({
        'baseUrl': client.info.baseUrl,
        'title': client.info.title,
        'mediaServer': client.info.mediaServer,
        'localLogin': client.info.localLogin,
        'session': client.session.toJson(),
      }),
    );
  }
}

final seerrStoreProvider = Provider<SeerrStore>((ref) => SeerrStore());

/// The connected Seerr server, or null (§20).
final seerrProvider = NotifierProvider<SeerrController, SeerrClient?>(
  SeerrController.new,
);

class SeerrController extends Notifier<SeerrClient?> {
  SeerrStore get _store => ref.read(seerrStoreProvider);

  @override
  SeerrClient? build() {
    unawaited(_load());
    return null;
  }

  Future<void> _load() async {
    final client = await _store.load();
    if (ref.mounted) state = client;
  }

  /// The Plex account token, for "sign in with Plex" on a Plex-backed Seerr.
  /// Null when Plex is not linked on this device.
  Future<String?> plexAccountToken() =>
      ref.read(plexSessionStoreProvider).accountToken();

  Future<void> connect(SeerrServerInfo info, SeerrSession session) async {
    final client = SeerrClient(info, session);
    await _store.save(client);
    state = client;
  }

  /// Forgets the server here. A session cookie lapses on the server by
  /// itself; an API key stays valid until its owner regenerates it there.
  Future<void> disconnect() async {
    await _store.save(null);
    state = null;
  }
}

/// Seerr's results for a search, with what the library already has left out
/// (§20): a title on the server already is in the results above, playable.
final seerrSearchProvider = FutureProvider.autoDispose
    .family<List<SeerrTitle>, String>((ref, query) async {
      final client = ref.watch(seerrProvider);
      if (client == null || query.trim().length < 2) return const [];
      // Typing is not a request per keystroke.
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (!ref.mounted) return const [];
      final all = await client.search(query);
      return [
        for (final t in all)
          if (t.availability != SeerrAvailability.available) t,
      ];
    });

/// The person's recent requests, for Settings.
final seerrRequestsProvider = FutureProvider.autoDispose<List<SeerrRequest>>((
  ref,
) async {
  final client = ref.watch(seerrProvider);
  if (client == null) return const [];
  return client.myRequests();
});
