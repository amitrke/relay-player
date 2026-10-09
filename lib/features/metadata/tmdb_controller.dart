import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../data/tmdb/tmdb_cache.dart';
import '../../data/tmdb/tmdb_client.dart';
import '../../data/tmdb/tmdb_enricher.dart';

const _kTmdbKey = 'tmdb.key';

/// The user's own TMDB key, or null.
///
/// In secure storage and nowhere else (§3). The settings box is not encrypted
/// and nothing secret may go in it. No key means no TMDB feature anywhere in the
/// app, the same rule §9.1 sets for AI: each feature checks, none is shown
/// half-working.
final tmdbKeyProvider = AsyncNotifierProvider<TmdbKeyController, String?>(
  TmdbKeyController.new,
);

class TmdbKeyController extends AsyncNotifier<String?> {
  static const _storage = FlutterSecureStorage();

  @override
  Future<String?> build() async {
    final key = await _storage.read(key: _kTmdbKey);
    return key == null || key.trim().isEmpty ? null : key.trim();
  }

  /// Checks [key] against TMDB first, so a typo is reported here and not later
  /// as filters that quietly never appear. Throws [TmdbException] on a bad key.
  Future<void> save(String key) async {
    final trimmed = key.trim();
    await TmdbClient(key: trimmed).verify();
    await _storage.write(key: _kTmdbKey, value: trimmed);
    state = AsyncData(trimmed);
  }

  /// Forgets the key and everything looked up with it.
  Future<void> remove() async {
    await _storage.delete(key: _kTmdbKey);
    await (await ref.read(tmdbCacheProvider.future)).clear();
    state = const AsyncData(null);
  }
}

final tmdbCacheProvider = FutureProvider<TmdbCache>((ref) async {
  return HiveTmdbCache.open();
});

/// Null until a key is saved.
final tmdbEnricherProvider = FutureProvider<TmdbEnricher?>((ref) async {
  final key = await ref.watch(tmdbKeyProvider.future);
  if (key == null) return null;
  return TmdbEnricher(
    TmdbClient(key: key),
    await ref.watch(tmdbCacheProvider.future),
  );
});
