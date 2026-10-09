import 'dart:async';

import '../../domain/models/catalog_item.dart';
import 'title_match.dart';
import 'tmdb_cache.dart';
import 'tmdb_client.dart';

/// Looks titles up on TMDB, remembering what it finds.
///
/// Lookups are for what is on screen, never for a whole catalogue: a panel can
/// hold tens of thousands of titles and each lookup is two requests.
class TmdbEnricher {
  TmdbEnricher(this._api, this._cache, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final TmdbApi _api;
  final TmdbCache _cache;
  final DateTime Function() _now;

  static String cacheKey(CatalogItem item) {
    final cleaned = cleanTitle(item.title);
    final year = item.year ?? cleaned.year;
    final tv = item.kind == CatalogKind.show;
    return '${tv ? 't' : 'm'}|${normalizeTitle(cleaned.title)}|${year ?? ''}';
  }

  /// What TMDB says about [item], or null when nothing convincing matched.
  ///
  /// Network failures are neither cached nor thrown: a lookup that failed says
  /// nothing about the title, and one flaky request should cost that title its
  /// metadata for now, not the whole result list.
  Future<TmdbInfo?> infoFor(CatalogItem item) async {
    final key = cacheKey(item);
    final cached = await _cache.get(key);
    if (cached != null) {
      if (cached.info != null) return cached.info;
      if (_now().difference(cached.at) < tmdbMissLifetime) return null;
    }

    final cleaned = cleanTitle(item.title);
    if (cleaned.title.isEmpty) return null;
    final year = item.year ?? cleaned.year;
    final tv = item.kind == CatalogKind.show;

    try {
      final hits = await _api.search(cleaned.title, tv: tv, year: year);
      final best = pickBest(hits, cleaned.title, year);
      final info = best == null ? null : await _api.details(best.id, tv: tv);
      await _cache.put(key, TmdbLookup(info, _now()));
      return info;
    } on TmdbException {
      return null;
    }
  }

  /// TMDB's recommendations for [seed], best first, with whether they are
  /// series. Empty when the seed itself cannot be matched or TMDB fails.
  ///
  /// These are only ever candidates: what the user does not have is dropped by
  /// `matchRecommendations` before anything is shown.
  Future<({List<TmdbCandidate> candidates, bool tv})> recommendationsFor(
    CatalogItem seed,
  ) async {
    final tv = seed.kind == CatalogKind.show;
    final info = await infoFor(seed);
    if (info == null) return (candidates: const <TmdbCandidate>[], tv: tv);
    try {
      return (candidates: await _api.recommendations(info.id, tv: tv), tv: tv);
    } on TmdbException {
      return (candidates: const <TmdbCandidate>[], tv: tv);
    }
  }

  /// [items] with whatever TMDB metadata could be found, in the same order.
  ///
  /// At most [limit] are looked up, [concurrency] at a time. The rest come back
  /// untouched, which a filter reads as "unknown".
  Future<List<CatalogItem>> enrich(
    List<CatalogItem> items, {
    int limit = 120,
    int concurrency = 6,
  }) async {
    final targets = items.take(limit).toList();
    final infos = List<TmdbInfo?>.filled(targets.length, null);

    var next = 0;
    Future<void> worker() async {
      while (next < targets.length) {
        final i = next++;
        infos[i] = await infoFor(targets[i]);
      }
    }

    await Future.wait([for (var w = 0; w < concurrency; w++) worker()]);

    return [
      for (var i = 0; i < items.length; i++)
        if (i < infos.length && infos[i] != null)
          items[i].withMetadata(
            genres: infos[i]!.genres,
            rating: infos[i]!.rating,
            originalLanguage: infos[i]!.originalLanguage == null
                ? null
                : languageNameOfIso(infos[i]!.originalLanguage!),
          )
        else
          items[i],
    ];
  }
}
