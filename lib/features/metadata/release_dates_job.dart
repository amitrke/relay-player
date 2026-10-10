import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/tmdb/tmdb_enricher.dart';
import '../../domain/models/catalog_item.dart';
import '../library/library_screen.dart' show libraryItemsProvider;
import '../library/library_tab.dart';
import 'release_dates.dart';
import 'tmdb_controller.dart';

/// How the job paces itself. A provider so a test can run it at full speed.
class ReleaseDatesConfig {
  const ReleaseDatesConfig({
    this.startDelay = const Duration(seconds: 4),
    this.pause = const Duration(milliseconds: 200),
    this.concurrency = 3,
    this.limitPerRun = 600,
    this.giveUpAfter = 6,
    this.flushEvery = 40,
  });

  /// Waited before the first request, so launch is not also a burst of
  /// requests while the library is still loading.
  final Duration startDelay;

  /// Waited by each worker between requests: about 15 a second at most, a long
  /// way under what TMDB allows, and slow enough to be a background task.
  final Duration pause;
  final int concurrency;

  /// Titles asked about per run. A bigger library fills over several launches
  /// instead of in one long burst.
  final int limitPerRun;

  /// Consecutive failures that end the run (a rate limit, or no network). One
  /// flaky request is not a reason to stop; a streak is.
  final int giveUpAfter;

  /// Dates are handed to the sort in batches of this many, so the list does not
  /// reorder under someone browsing after every single lookup.
  final int flushEvery;
}

final releaseDatesConfigProvider = Provider<ReleaseDatesConfig>(
  (ref) => const ReleaseDatesConfig(),
);

/// Looks up when each title in the library was released, in the background
/// (architecture.md section 12), once the person has agreed to it.
///
/// Watched from the app root, like the AI prefetch. It does nothing without a
/// TMDB key, without that agreement, or with nothing in the library. Everything
/// it learns goes into the TMDB cache, so a later launch starts from what is
/// kept and only asks about what is new, and what it finds for the sort goes to
/// [releaseDatesProvider].
final releaseDatesJobProvider = Provider<void>((ref) {
  final enabled = ref.watch(releaseDatesEnabledProvider);
  final enricher = ref.watch(tmdbEnricherProvider).value;
  final hasKey = ref.watch(tmdbKeyProvider.select((k) => k.value != null));

  // The agreement was to look titles up *with that key*. A removed key takes it
  // with it, so adding another later asks again. "Removed" means the key has
  // finished loading from secure storage and is empty: while it is still
  // loading at launch `value` is null too, and treating that as removal wiped
  // the saved agreement on every start.
  final keyLoaded = ref.watch(tmdbKeyProvider.select((k) => k.hasValue));
  if (keyLoaded && !hasKey && enabled) {
    unawaited(Future.microtask(() {
      if (ref.exists(releaseDatesEnabledProvider)) {
        ref.read(releaseDatesEnabledProvider.notifier).disable();
      }
    }));
  }

  final dates = ref.read(releaseDatesProvider.notifier);
  if (!enabled || !hasKey || enricher == null) {
    Future.microtask(dates.reset);
    return;
  }

  final items = [
    for (final tab in [LibraryTab.movies, LibraryTab.series])
      ...?ref.watch(libraryItemsProvider(tab)).value,
  ];
  if (items.isEmpty) return;

  final job = ReleaseDatesJob(
    enricher: enricher,
    items: items,
    sink: dates,
    config: ref.read(releaseDatesConfigProvider),
  );
  ref.onDispose(job.cancel);
  unawaited(job.run());
});

/// One pass over the library. Separate from the provider so it can be run, and
/// stopped, on its own.
class ReleaseDatesJob {
  ReleaseDatesJob({
    required this.enricher,
    required this.items,
    required this.sink,
    this.config = const ReleaseDatesConfig(),
  });

  final TmdbEnricher enricher;
  final List<CatalogItem> items;
  final ReleaseDatesController sink;
  final ReleaseDatesConfig config;

  bool _cancelled = false;

  void cancel() => _cancelled = true;

  Future<void> run() async {
    if (config.startDelay > Duration.zero) {
      await Future<void>.delayed(config.startDelay);
    }
    if (_cancelled) return;

    // One entry per distinct title: the same film on Plex and on a panel is one
    // lookup, and one answer for both.
    final byKey = <String, CatalogItem>{};
    for (final item in items) {
      byKey.putIfAbsent(TmdbEnricher.cacheKey(item), () => item);
    }

    // What is kept already answers most of it, and costs no request.
    final known = <String, DateTime>{};
    final pending = <MapEntry<String, CatalogItem>>[];
    for (final entry in byKey.entries) {
      if (_cancelled) return;
      final peek = await enricher.peekRelease(entry.value);
      final date = peek.date;
      if (date != null) known[entry.key] = date;
      if (!peek.settled) pending.add(entry);
    }
    var settled = byKey.length - pending.length;
    sink.merge(known);
    sink.progress(
      total: byKey.length,
      settled: settled,
      running: pending.isNotEmpty,
      stoppedEarly: false,
    );
    if (pending.isEmpty) return;

    // The titles with no year first: a year is all the sort has for the others,
    // and these have nothing, so a date is worth most here.
    pending.sort((a, b) {
      final noYearA = a.value.year == null ? 0 : 1;
      final noYearB = b.value.year == null ? 0 : 1;
      return noYearA.compareTo(noYearB);
    });
    final queue = pending.take(config.limitPerRun).toList();

    var next = 0;
    var streak = 0;
    var gaveUp = false;
    final batch = <String, DateTime>{};
    var sinceFlush = 0;

    void flush() {
      sink.merge({...batch});
      batch.clear();
      sinceFlush = 0;
      sink.progress(settled: settled);
    }

    Future<void> worker() async {
      while (!_cancelled && !gaveUp && next < queue.length) {
        final entry = queue[next++];
        final result = await enricher.fetchRelease(entry.value);
        if (_cancelled) return;
        if (result.failed) {
          if (++streak >= config.giveUpAfter) gaveUp = true;
        } else {
          streak = 0;
          settled++;
          final date = result.date;
          if (date != null) batch[entry.key] = date;
          if (++sinceFlush >= config.flushEvery) flush();
        }
        if (config.pause > Duration.zero) {
          await Future<void>.delayed(config.pause);
        }
      }
    }

    await Future.wait([for (var i = 0; i < config.concurrency; i++) worker()]);
    if (_cancelled) return;
    flush();
    sink.progress(
      running: false,
      // Not "finished short of the limit": reaching the cap is an ordinary end,
      // the rest comes next launch. Only a streak of failures is a stop.
      stoppedEarly: gaveUp,
    );
  }
}
