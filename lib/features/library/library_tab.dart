import 'package:dart_plex/dart_plex.dart';
import 'package:flutter/material.dart';

/// The Home tabs (§12 screen 3).
///
/// Movies and Series map onto Plex library types. Local & Network and Live TV
/// do not — they are separate source shapes, which is why [plexType] is
/// nullable rather than every tab pretending to be a Plex query.
enum LibraryTab {
  movies('Movies', PlexLibraryType.movie),
  series('Series', PlexLibraryType.show),
  localNetwork('Local & Network', null),
  liveTv('Live TV', null);

  const LibraryTab(this.label, this.plexType);

  final String label;
  final PlexLibraryType? plexType;

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
