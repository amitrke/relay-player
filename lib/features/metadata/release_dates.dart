import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../settings/settings_controller.dart';

const _kEnabled = 'metadata.releaseDates';
const _kAgreedAt = 'metadata.releaseDatesAt';

/// Whether the person has agreed to the background release-date lookup.
///
/// This is consent, not a preference, and it is why it lives apart from the
/// other switches. Everything else TMDB does here looks up what is on screen;
/// this sends the title (and year, if there is one) of **every** film and
/// series in the library, a few at a time, without being asked each time. So it
/// is off until the person turns it on, from a dialog that says exactly that,
/// and the moment it was agreed to is kept beside it. It is never copied to
/// another device (architecture.md 17.3): the person at *that* device has to
/// agree for themselves.
final releaseDatesEnabledProvider =
    NotifierProvider<ReleaseDatesEnabledController, bool>(
      ReleaseDatesEnabledController.new,
    );

class ReleaseDatesEnabledController extends Notifier<bool> {
  @override
  bool build() =>
      ref.read(appSettingsStoreProvider).getBool(_kEnabled, fallback: false);

  Future<void> enable() async {
    state = true;
    final store = ref.read(appSettingsStoreProvider);
    await store.setBool(_kEnabled, true);
    await store.setString(_kAgreedAt, DateTime.now().toIso8601String());
  }

  Future<void> disable() async {
    state = false;
    await ref.read(appSettingsStoreProvider).setBool(_kEnabled, false);
  }
}

/// What the background job has found, and how far it has got.
class ReleaseDatesState {
  const ReleaseDatesState({
    this.dates = const {},
    this.total = 0,
    this.settled = 0,
    this.running = false,
    this.stoppedEarly = false,
  });

  /// Release dates by `TmdbEnricher.cacheKey`, for the sort to read. Only what
  /// TMDB gave: a title with no entry falls back to its year.
  final Map<String, DateTime> dates;

  /// Distinct titles in the library, and how many of them are answered: a date
  /// found, or TMDB asked and having none.
  final int total;
  final int settled;
  final bool running;

  /// The run gave up because TMDB kept failing (rate limit, no network). It
  /// starts again next launch, and what it found is kept.
  final bool stoppedEarly;

  ReleaseDatesState copyWith({
    Map<String, DateTime>? dates,
    int? total,
    int? settled,
    bool? running,
    bool? stoppedEarly,
  }) => ReleaseDatesState(
    dates: dates ?? this.dates,
    total: total ?? this.total,
    settled: settled ?? this.settled,
    running: running ?? this.running,
    stoppedEarly: stoppedEarly ?? this.stoppedEarly,
  );
}

final releaseDatesProvider =
    NotifierProvider<ReleaseDatesController, ReleaseDatesState>(
      ReleaseDatesController.new,
    );

class ReleaseDatesController extends Notifier<ReleaseDatesState> {
  @override
  ReleaseDatesState build() => const ReleaseDatesState();

  void merge(Map<String, DateTime> more) {
    if (more.isEmpty) return;
    state = state.copyWith(dates: {...state.dates, ...more});
  }

  void progress({
    int? total,
    int? settled,
    bool? running,
    bool? stoppedEarly,
  }) {
    state = state.copyWith(
      total: total,
      settled: settled,
      running: running,
      stoppedEarly: stoppedEarly,
    );
  }

  /// Back to nothing, for when the job is switched off or the key goes. The
  /// dates stay in the TMDB cache, which has its own limits.
  void reset() => state = const ReleaseDatesState();
}
