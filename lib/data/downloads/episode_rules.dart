import 'dart:convert';

import '../local/app_settings_store.dart';
import 'download_record.dart';

/// "Keep the next N unwatched episodes of this show on this device"
/// (architecture.md §18.7).
///
/// §18.1 refuses to download a whole show on one press, because that is a
/// decision about gigabytes. A rule is the bounded version of the same wish:
/// the person picks N, and the device holds at most N episodes of that show
/// that it fetched for the rule, topping up as they are watched.
class EpisodeRule {
  const EpisodeRule({
    required this.serverId,
    required this.showRatingKey,
    required this.showTitle,
    required this.keep,
  });

  final String serverId;
  final String showRatingKey;
  final String showTitle;

  /// How many unwatched episodes to hold. Always one of [ruleSizes].
  final int keep;

  String get key => 'plex:$serverId:$showRatingKey';

  EpisodeRule withKeep(int keep) => EpisodeRule(
    serverId: serverId,
    showRatingKey: showRatingKey,
    showTitle: showTitle,
    keep: keep,
  );

  Map<String, Object?> toJson() => {
    'serverId': serverId,
    'show': showRatingKey,
    'title': showTitle,
    'keep': keep,
  };

  static EpisodeRule? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final serverId = raw['serverId'];
    final show = raw['show'];
    final title = raw['title'];
    final keep = raw['keep'];
    if (serverId is! String ||
        show is! String ||
        title is! String ||
        keep is! int ||
        !ruleSizes.contains(keep)) {
      return null;
    }
    return EpisodeRule(
      serverId: serverId,
      showRatingKey: show,
      showTitle: title,
      keep: keep,
    );
  }
}

/// The sizes offered. A short list, so a remote can pick one in a press or
/// two, and capped at 10 so a rule cannot quietly become "the whole show".
const ruleSizes = [1, 3, 5, 10];

/// One episode as the planner sees it.
class RuleEpisode {
  const RuleEpisode({
    required this.ratingKey,
    required this.title,
    required this.season,
    required this.index,
    required this.watched,
  });

  final String ratingKey;
  final String title;

  /// Plex's `parentIndex` and `index`. Specials are season 0 and sort first,
  /// which is wrong for "next", so they are left out of a rule entirely.
  final int season;
  final int index;

  final bool watched;
}

class TopUpPlan {
  const TopUpPlan({required this.download, required this.remove});

  /// Episodes to queue, in viewing order.
  final List<RuleEpisode> download;

  /// Rating keys of finished, rule-fetched episodes now watched.
  final List<String> remove;
}

/// What a rule wants done, given the show's episodes and what is on the
/// device.
///
/// - **The next N are the first N unwatched episodes in order**, not the N
///   after the last one watched: an episode skipped and never watched is
///   still "next", which matches Plex's own On Deck.
/// - **Only the rule's own downloads are ever removed**, and only once
///   finished and watched. An episode the person downloaded by hand stays
///   theirs, and counts towards N so the rule does not fetch a duplicate.
/// - An episode in progress is not watched, so it is kept.
TopUpPlan planTopUp(
  EpisodeRule rule,
  List<RuleEpisode> episodes,
  List<DownloadRecord> downloads,
) {
  final ordered = [
    for (final e in episodes)
      if (e.season > 0) e,
  ]..sort((a, b) {
      final s = a.season.compareTo(b.season);
      return s != 0 ? s : a.index.compareTo(b.index);
    });

  final onDevice = {
    for (final d in downloads)
      if (d.serverId == rule.serverId) d.ratingKey: d,
  };
  final wanted = ordered.where((e) => !e.watched).take(rule.keep).toList();
  final watched = {
    for (final e in ordered)
      if (e.watched) e.ratingKey,
  };

  return TopUpPlan(
    download: [
      for (final e in wanted)
        if (!onDevice.containsKey(e.ratingKey) ||
            onDevice[e.ratingKey]!.state == DownloadState.failed)
          e,
    ],
    remove: [
      for (final d in onDevice.values)
        if (d.rule == rule.showRatingKey &&
            d.isComplete &&
            watched.contains(d.ratingKey))
          d.ratingKey,
    ],
  );
}

/// The rules, in the settings box. Not secret: ids and a title.
class EpisodeRuleStore {
  EpisodeRuleStore(this._settings);

  final AppSettingsStore _settings;

  static const _key = 'downloads.rules';

  List<EpisodeRule> load() {
    final raw = _settings.getString(_key);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return [for (final e in decoded) ?EpisodeRule.fromJson(e)];
    } on FormatException {
      return const [];
    }
  }

  Future<void> save(List<EpisodeRule> rules) => _settings.setString(
    _key,
    jsonEncode([for (final r in rules) r.toJson()]),
  );
}
