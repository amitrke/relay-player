import '../../domain/models/catalog_item.dart';
import 'library_cache.dart';

/// What one source returned, and what that answer depended on.
class LibraryFetch {
  const LibraryFetch(this.items, this.signature);

  final List<CatalogItem> items;

  /// The library sections or categories the answer was made for. Stored with it,
  /// so an answer made for other choices is not mistaken for the current one.
  final String signature;
}

/// One place titles come from: a Plex server's libraries for a tab, or a
/// panel's chosen categories.
class LibrarySource {
  const LibrarySource({
    required this.key,
    required this.fetch,
    this.expectedSignature,
    this.revive,
  });

  /// Stable across launches; the cache key.
  final String key;

  /// Asks the source. **Throws on failure.** Returning an empty list for a
  /// failure was how a source that timed out used to vanish for the session: the
  /// loader cannot tell "the user has nothing there" from "it did not answer",
  /// and only the second should fall back to what was kept.
  final Future<LibraryFetch> Function() fetch;

  /// The signature a kept answer must have to stand in for this source, when it
  /// is known without asking (a panel's chosen categories). Null when it is not
  /// (a Plex server's sections need the server), and any kept answer is used.
  final String? expectedSignature;

  /// Applied to items read back from the cache. A Plex item comes back without a
  /// signed poster URL (the cache never holds one), and this signs it against
  /// the live connection.
  final CatalogItem Function(CatalogItem)? revive;
}

/// The library for a tab, from every source, as a stream: what was kept first,
/// then what the sources say now.
///
/// Stale while revalidate. The kept answer shows at once, so opening the app
/// never waits on a slow server, and the fresh answers replace it when they
/// land. A source that fails or times out keeps its kept answer in the merge
/// instead of dropping out, which is what used to leave a session with 982 items
/// on one launch and 1124 on the next. With nothing kept the first emission is
/// the fresh one, as before.
///
/// Sources are asked together. The timeout is longer when there is something
/// kept to show meanwhile, since nobody is waiting on it then.
Stream<List<CatalogItem>> loadLibrary(
  List<LibrarySource> sources, {
  required LibraryCache? cache,
  Duration timeout = const Duration(seconds: 10),
  Duration timeoutWithCache = const Duration(seconds: 25),
  DateTime Function()? now,
}) async* {
  final clock = now ?? DateTime.now;

  final kept = <String, List<CatalogItem>>{};
  if (cache != null) {
    for (final s in sources) {
      CachedSource? hit;
      try {
        hit = await cache.read(s.key);
      } catch (_) {
        hit = null;
      }
      if (hit == null) continue;
      final expected = s.expectedSignature;
      if (expected != null && hit.signature != expected) continue;
      kept[s.key] = [
        for (final i in hit.items) s.revive == null ? i : s.revive!(i),
      ];
    }
  }

  if (kept.values.any((items) => items.isNotEmpty)) yield _merge(kept.values);

  final fresh = await Future.wait(
    sources.map((s) async {
      final fallback = kept[s.key] ?? const <CatalogItem>[];
      final limit = fallback.isEmpty ? timeout : timeoutWithCache;
      try {
        final got = await s.fetch().timeout(limit);
        if (cache != null) {
          try {
            await cache.write(
              s.key,
              CachedSource(
                items: got.items,
                signature: got.signature,
                at: clock(),
              ),
            );
          } catch (_) {
            // Failing to keep an answer must not cost the user the answer.
          }
        }
        return got.items;
      } catch (_) {
        return fallback;
      }
    }),
  );

  yield _merge(fresh);
}

List<CatalogItem> _merge(Iterable<List<CatalogItem>> lists) =>
    [for (final l in lists) ...l]
      ..sort((a, b) => a.sortKey.compareTo(b.sortKey));
