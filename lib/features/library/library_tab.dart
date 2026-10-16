import 'package:flutter/material.dart';
import '../../i18n/strings.g.dart';

/// The Home tabs (§12 screen 3).
///
/// Movies and Series are fed by Plex libraries, but *which* libraries is a user
/// decision rather than a property of the tab — see [LibraryMapping]. Local &
/// Network and Live TV are different source shapes entirely and draw from Plex
/// not at all.
enum LibraryTab {
  movies(drawsFromPlex: true),
  series(drawsFromPlex: true),
  localNetwork(drawsFromPlex: false),
  liveTv(drawsFromPlex: false);

  const LibraryTab({required this.drawsFromPlex});

  final bool drawsFromPlex;

  String get label => switch (this) {
        movies => tr.library.tab.movies,
        series => tr.library.tab.series,
        localNetwork => tr.library.tab.localNetwork,
        liveTv => tr.library.tab.liveTv,
      };

  /// "12 movies", in the app's language; a plural, so not [label] lowercased.
  String count(int n) => switch (this) {
        movies => tr.library.tab.countMovies(n: n),
        series => tr.library.tab.countSeries(n: n),
        localNetwork => tr.library.tab.countItems(n: n),
        liveTv => tr.library.tab.countChannels(n: n),
      };

  /// §8.2: Live TV exists only while Advanced Sources is on. The tab is absent
  /// from the tree rather than disabled, so there is nothing to discover when
  /// the gate is off. Local & Network is absent until it is used
  /// (`localNetworkTabProvider`, 2026-10-16).
  static List<LibraryTab> visible({
    required bool advancedSources,
    bool localNetwork = true,
  }) =>
      [
        movies,
        series,
        if (localNetwork) LibraryTab.localNetwork,
        if (advancedSources) liveTv,
      ];

  IconData get emptyIcon => switch (this) {
        movies => Icons.movie_outlined,
        series => Icons.tv_outlined,
        localNetwork => Icons.folder_outlined,
        liveTv => Icons.live_tv_outlined,
      };

  String get emptyMessage => switch (this) {
        movies => tr.library.tab.emptyMovies,
        series => tr.library.tab.emptySeries,
        localNetwork => tr.library.tab.emptyLocalNetwork,
        liveTv => tr.library.tab.emptyLiveTv,
      };
}
