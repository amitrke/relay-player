import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/library_cache.dart';

/// The library cache, opened once. Opening it also prunes anything over
/// [libraryCacheMaxAge] and compacts the file (see [HiveLibraryCache.open]), so
/// the cache cannot grow without bound.
final libraryCacheProvider = FutureProvider<LibraryCache>((ref) async {
  return HiveLibraryCache.open();
});

/// Drops what the cache holds for sources whose key starts with [prefix]
/// (`plex|<server>|`, `xtream|<account>|`). Called when a source is removed, so
/// a title from a server you disconnected does not sit on disk waiting to age
/// out. Never throws: failing to tidy must not fail the removal.
Future<void> forgetSourceCache(Ref ref, String prefix) async {
  try {
    final cache = await ref.read(libraryCacheProvider.future);
    await cache.deletePrefix(prefix);
  } catch (_) {}
}
