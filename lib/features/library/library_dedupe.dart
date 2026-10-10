import '../../data/ai/ai_provider.dart' show isPrivateHost;
import '../../data/tmdb/title_match.dart';
import '../../domain/models/catalog_item.dart';

/// One tile per title when more than one source holds it.
///
/// §12 merges every source into one Movies tab and one Series tab, so a film on
/// two Plex servers (an owned one and one shared with you, say) showed twice,
/// side by side, with nothing to tell the copies apart but which plays well.
/// Reported on the Chromecast 2026-10-10.
///
/// The copy kept is the one most likely to play smoothly: a Plex server
/// reached over the LAN, then any other Plex server, then a panel. Between
/// equals the first wins, so the order the sources were merged in still
/// decides. The kept copy takes the place of the first one in the list, so
/// deduplicating never moves a title.
///
/// Matched as [buildLibraryIndex] matches them for the AI search: kind, cleaned
/// title and year. **Only with a year.** Two different films can share a title
/// (remakes), and the year is what tells them apart; without one there is no
/// way to know, and two tiles are better than a wrong one hiding the other.
/// Panel titles often have no year, so they are mostly left alone. This is
/// knowingly a weaker match than Plex's own GUIDs, which `dart_plex` 0.1.2 does
/// not expose.
List<CatalogItem> dedupeLibrary(
  List<CatalogItem> items, {
  required Set<String> localPlexServers,
}) {
  int rank(CatalogItem item) => switch (item.source) {
    CatalogSource.plex => localPlexServers.contains(item.sourceId) ? 0 : 1,
    CatalogSource.xtream => 2,
  };

  final slotOf = <String, int>{};
  final out = <CatalogItem>[];
  for (final item in items) {
    final key = _keyOf(item);
    if (key == null) {
      out.add(item);
      continue;
    }
    final slot = slotOf[key];
    if (slot == null) {
      slotOf[key] = out.length;
      out.add(item);
    } else if (rank(item) < rank(out[slot])) {
      out[slot] = item;
    }
  }
  return out;
}

String? _keyOf(CatalogItem item) {
  final cleaned = cleanTitle(item.title);
  final year = item.year ?? cleaned.year;
  if (year == null) return null;
  final title = normalizeTitle(
    cleaned.title.isEmpty ? item.title : cleaned.title,
  );
  if (title.isEmpty) return null;
  return '${item.kind.name}|$title|$year';
}

/// Whether a Plex server was reached on the local network.
///
/// From the address the session connected to and kept, which `connectTo`
/// chose by probing its LAN candidates first. That is either a private address
/// or a `*.plex.direct` name, which spells the address it resolves to in its
/// first label (`192-168-1-5.<hash>.plex.direct`); a relay or a remote
/// connection spells a public one.
bool plexUrlIsLocal(String baseUrl) {
  final host = Uri.tryParse(baseUrl)?.host ?? '';
  if (host.endsWith('.plex.direct')) {
    return isPrivateHost(host.split('.').first.replaceAll('-', '.'));
  }
  return isPrivateHost(host);
}
