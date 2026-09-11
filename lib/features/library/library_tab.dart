import 'package:flutter/material.dart';

/// The Home tabs (§12 screen 3).
///
/// Movies and Series are fed by Plex libraries, but *which* libraries is a user
/// decision rather than a property of the tab — see [LibraryMapping]. Local &
/// Network and Live TV are different source shapes entirely and draw from Plex
/// not at all.
enum LibraryTab {
  movies('Movies', drawsFromPlex: true),
  series('Series', drawsFromPlex: true),
  localNetwork('Local & Network', drawsFromPlex: false),
  liveTv('Live TV', drawsFromPlex: false);

  const LibraryTab(this.label, {required this.drawsFromPlex});

  final String label;
  final bool drawsFromPlex;

  /// §8.2: Live TV exists only while Advanced Sources is on. The tab is absent
  /// from the tree rather than disabled, so there is nothing to discover when
  /// the gate is off.
  static List<LibraryTab> visible({required bool advancedSources}) => [
        movies,
        series,
        localNetwork,
        if (advancedSources) liveTv,
      ];

  IconData get emptyIcon => switch (this) {
        movies => Icons.movie_outlined,
        series => Icons.tv_outlined,
        localNetwork => Icons.folder_outlined,
        liveTv => Icons.live_tv_outlined,
      };

  String get emptyMessage => switch (this) {
        movies => 'No movies on this server.',
        series => 'No series on this server.',
        localNetwork =>
          'No folders or network shares yet.\nDevice storage and SMB shares '
              'are not connectable in this build.',
        liveTv =>
          'No playlist or panel configured.\nAdd one from Settings once '
              'Advanced sources is on.',
      };
}
