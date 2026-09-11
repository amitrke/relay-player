import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/filesystem/smb_source.dart';
import '../settings/settings_controller.dart';

final smbShareStoreProvider = Provider<SmbShareStore>((ref) {
  return SmbShareStore(settings: ref.watch(appSettingsStoreProvider));
});

final smbSharesProvider =
    NotifierProvider<SmbSharesController, List<SmbShare>>(
  SmbSharesController.new,
);

class SmbSharesController extends Notifier<List<SmbShare>> {
  SmbShareStore get _store => ref.read(smbShareStoreProvider);

  @override
  List<SmbShare> build() => _store.shares();

  Future<void> save(SmbShare share, {String? password}) async {
    await _store.save(share, password: password);
    state = _store.shares();
  }

  Future<void> remove(String id) async {
    await _store.remove(id);
    state = _store.shares();
  }
}

/// A live connection for one configured share.
///
/// Kept alive while anything is using it and closed when nothing is, because
/// §7.2 calls the connection real state: an SMB session holds a socket, and
/// leaking one per screen visit would eventually exhaust the server's limit.
final smbSessionProvider =
    FutureProvider.family<SmbSession, SmbShare>((ref, share) async {
  final password = await ref.watch(smbShareStoreProvider).password(share.id);
  final session = await SmbSession.connect(
    host: share.host,
    username: share.username,
    password: password ?? '',
    domain: share.domain,
  );
  ref.onDispose(session.close);
  return session;
});

/// (share, path) — Riverpod families take one argument.
typedef SmbScope = (SmbShare, String);

/// The shares on the server, or the contents of one path within it.
///
/// An empty path means "list the server's shares", which is the entry point:
/// Phase 0 saw 17 of them on a real NAS, and guessing a share name instead of
/// listing would be a worse first run.
final smbListingProvider =
    FutureProvider.family<List<SmbEntry>, SmbScope>((ref, scope) async {
  final (share, path) = scope;
  final session = await ref.watch(smbSessionProvider(share).future);
  return path.isEmpty ? session.shares() : session.list(path);
});
