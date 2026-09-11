import 'package:dart_plex/dart_plex.dart';

import 'library_tab.dart';

/// Where a single Plex library's contents appear.
enum LibraryPlacement {
  movies('Movies'),
  series('Series'),
  hidden('Hidden');

  const LibraryPlacement(this.label);

  final String label;

  LibraryTab? get tab => switch (this) {
        movies => LibraryTab.movies,
        series => LibraryTab.series,
        hidden => null,
      };

  static LibraryPlacement? fromName(String? name) {
    for (final p in values) {
      if (p.name == name) return p;
    }
    return null;
  }
}

/// User overrides for which tab each Plex library feeds.
///
/// Plex's own library type is only a *default*, not an answer. A library typed
/// `movie` may hold anything its owner put there — course recordings, home
/// video, concert films — so merging every `movie` library into Movies and
/// throwing the library name away produces a tab whose contents make no sense
/// to the person who built the server. Plex's own UI never merges; it lists
/// libraries by name.
///
/// So: default from the type, let the user correct it, and keep the library
/// name visible either way.
class LibraryMapping {
  const LibraryMapping(this._overrides);

  const LibraryMapping.empty() : _overrides = const {};

  /// Section id → placement. Only user-chosen entries are stored, so a library
  /// the user never touched keeps following its Plex type even if that type
  /// changes on the server.
  final Map<String, LibraryPlacement> _overrides;

  Map<String, String> toStorage() =>
      {for (final e in _overrides.entries) e.key: e.value.name};

  static LibraryMapping fromStorage(Map<String, String> raw) {
    return LibraryMapping({
      for (final entry in raw.entries)
        entry.key: ?LibraryPlacement.fromName(entry.value),
    });
  }

  static LibraryPlacement defaultFor(PlexLibrarySection section) =>
      section.type == PlexLibraryType.show
          ? LibraryPlacement.series
          : LibraryPlacement.movies;

  LibraryPlacement placementOf(PlexLibrarySection section) =>
      _overrides[section.id] ?? defaultFor(section);

  bool isOverridden(PlexLibrarySection section) =>
      _overrides.containsKey(section.id);

  /// The sections feeding [tab], in the server's own order.
  List<PlexLibrarySection> sectionsFor(
    LibraryTab tab,
    List<PlexLibrarySection> all,
  ) =>
      all.where((s) => placementOf(s).tab == tab).toList();

  LibraryMapping withPlacement(
    PlexLibrarySection section,
    LibraryPlacement placement,
  ) {
    return LibraryMapping({..._overrides, section.id: placement});
  }
}
