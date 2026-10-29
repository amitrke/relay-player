import 'package:flutter_test/flutter_test.dart';
import 'package:relay_player/features/library/library_mapping.dart';
import 'package:relay_player/domain/models/media_server.dart';

MediaSection _section(String id, MediaSectionType type) =>
    MediaSection(id: id, title: 'Library $id', type: type);

void main() {
  final films = _section('1', MediaSectionType.movies);
  final shows = _section('2', MediaSectionType.shows);
  final courses = _section('3', MediaSectionType.movies);

  test('search covers every library that is not hidden', () {
    final mapping = const LibraryMapping.empty()
        .withPlacement('s', courses, LibraryPlacement.hidden);
    final visible = mapping.visibleSections('s', [films, shows, courses]);
    expect(visible.map((s) => s.id), ['1', '2']);
  });

  test('a library moved between tabs is still searched', () {
    final mapping = const LibraryMapping.empty()
        .withPlacement('s', films, LibraryPlacement.series);
    expect(mapping.visibleSections('s', [films]).map((s) => s.id), ['1']);
  });

  test('hiding applies per server, not to a section id shared by two servers',
      () {
    final mapping = const LibraryMapping.empty()
        .withPlacement('a', courses, LibraryPlacement.hidden);
    expect(mapping.visibleSections('a', [courses]), isEmpty);
    expect(mapping.visibleSections('b', [courses]).map((s) => s.id), ['3']);
  });
}
