import 'xtream_client.dart';

/// A set of categories that share a leading name: a country, a language, a
/// platform, a kind of programme.
class CategoryGroup {
  const CategoryGroup(this.label, this.categories, {this.isRemainder = false});

  final String label;

  /// In the panel's own order.
  final List<XtreamCategory> categories;

  /// The catch-all for categories that share a name with nothing else.
  final bool isRemainder;
}

/// Groups a panel's categories by what they start with, so a list of hundreds
/// can be browsed a handful of groups at a time.
///
/// **There is no scheme to rely on.** Panels name categories however their
/// owner likes, and one real panel used all of these at once: a bare country
/// ("Germany"), a country and a genre ("Germany ➾ News"), a prefix and a bar
/// ("IND | ORIYA"), a year bucket ("BOLLYWOOD (2016-2018)", "(2024) HOLLYWOOD"),
/// a "24/7 ..." prefix, and bare one-offs. So nothing is configured and nothing
/// is assumed: the leading part of each name, with years and quality tags taken
/// off, is its key, and categories with the same key form a group.
///
/// Every category lands in exactly one group. Ones that share their start with
/// nothing go in a final "Everything else" group, so a name this cannot make
/// sense of is still there to find, never dropped.
List<CategoryGroup> groupCategories(List<XtreamCategory> categories) {
  final buckets = <String, _Bucket>{};
  for (final c in categories) {
    final head = _head(c.name);
    final key = _key(head);
    final bucket = buckets.putIfAbsent(key, () => _Bucket(key));
    bucket.members.add(c);
    bucket.heads.add(head);
  }

  // Singletons first try to join a larger group they extend ("HINDI DUBBED
  // HOLLYWOOD" under "HINDI DUBBED"), then to cluster with other singletons
  // that open with the same word ("24/7 ...", a channel brand).
  final groups = <_Bucket>[
    for (final b in buckets.values)
      if (b.members.length > 1) b,
  ];
  final singles = [
    for (final b in buckets.values)
      if (b.members.length == 1) b,
  ];

  final remainder = <XtreamCategory>[];
  final byFirstWord = <String, List<_Bucket>>{};
  for (final s in singles) {
    final parent = groups
        .where((g) => s.key.startsWith('${g.key} '))
        .fold<_Bucket?>(
          null,
          (best, g) =>
              best == null || g.key.length > best.key.length ? g : best,
        );
    if (parent != null) {
      parent.members.addAll(s.members);
      parent.heads.addAll(s.heads);
      continue;
    }
    final word = s.key.split(' ').first;
    if (word.length >= 3 && !_stopWords.contains(word)) {
      byFirstWord.putIfAbsent(word, () => []).add(s);
    } else {
      remainder.addAll(s.members);
    }
  }
  for (final entry in byFirstWord.entries) {
    if (entry.value.length >= 2) {
      final merged = _Bucket(entry.key);
      for (final b in entry.value) {
        merged.members.addAll(b.members);
        merged.heads.add(entry.key);
        merged.originalWord = _firstWord(b.heads.first);
      }
      groups.add(merged);
    } else {
      remainder.addAll(entry.value.single.members);
    }
  }

  // Panel order inside a group, whatever order the passes added them in.
  final order = {for (final (i, c) in categories.indexed) c.id: i};
  int byPanel(XtreamCategory a, XtreamCategory b) =>
      order[a.id]!.compareTo(order[b.id]!);

  final out =
      [
        for (final g in groups)
          CategoryGroup(g.label, [...g.members]..sort(byPanel)),
      ]..sort((a, b) {
        final bySize = b.categories.length.compareTo(a.categories.length);
        return bySize != 0 ? bySize : a.label.compareTo(b.label);
      });
  if (remainder.isNotEmpty) {
    out.add(
      CategoryGroup(
        'Everything else',
        [...remainder]..sort(byPanel),
        isRemainder: true,
      ),
    );
  }
  return out;
}

/// What to call [name] once it is shown under its group: the part after the
/// group's own name, so "USA ➾ Documentary" reads "Documentary" under USA. A
/// name with nothing after its head (a bare "USA", or a year bucket such as
/// "BOLLYWOOD (2016-2018)") has nothing shorter to say and keeps its full name.
String categoryLabelInGroup(String name) {
  final protectedName = name.replaceAll('24/7', '24_7');
  final bare = protectedName
      .replaceAll(_decoration, ' ')
      .replaceAll(_quality, ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  final parts = bare
      .split(_separators)
      .where((p) => p.trim().isNotEmpty)
      .toList();
  if (parts.length < 2) return name.trim();
  return parts.skip(1).join(' · ').replaceAll('_', '/');
}

class _Bucket {
  _Bucket(this.key);

  final String key;
  final members = <XtreamCategory>[];
  final heads = <String>[];

  /// The first word as written, for a group made by clustering singletons.
  String? originalWord;

  /// The name as most members write it: "Germany", not "GERMANY", when that is
  /// how the panel does it. Ties go to the first seen.
  String get label {
    if (originalWord != null) return originalWord!.replaceAll('_', '/');
    final counts = <String, int>{};
    for (final h in heads) {
      counts[h] = (counts[h] ?? 0) + 1;
    }
    var best = heads.first;
    for (final e in counts.entries) {
      if (e.value > (counts[best] ?? 0)) best = e.key;
    }
    return best.replaceAll('_', '/');
  }
}

// A year, or a range of them, with or without brackets.
final _years = RegExp(
  r'\(?\s*\b(?:19|20)\d{2}(?:\s*[-–]\s*(?:19|20)\d{2})?\s*\)?',
);

// What panels put between the parts of a name. "/" is not here, since it is
// inside "24/7"; a bare "-" is, but only with spaces, so "Hip-Hop" survives.
final _separators = RegExp(
  // Any arrow glyph (the plain arrows, the dingbat arrows panels like, and the
  // supplemental ones), a bar, a colon, a bullet, `>>`, or a spaced dash.
  // Matching the ranges and not one glyph matters: the real panel used U+27BE
  // and a list of the arrows seen would miss the next panel's.
  r'\s*(?:[←-⇿➔-➿⟰-⟿⤀-⥿]|»|>|\||:|•|\s[-–]\s)\s*',
);

final _decoration = RegExp(r'[\[\](){}]');

final _quality = RegExp(
  r'\b(?:FHD|UHD|HD|SD|4K|VIP|HEVC)\b',
  caseSensitive: false,
);

const _stopWords = {
  'THE',
  'NEW',
  'TOP',
  'BEST',
  'LIVE',
  'ALL',
  'MIX',
  'OTHER',
  'MORE',
  'AND',
  'FOR',
  'WITH',
};

/// The leading part of a name, as written, with years and brackets removed.
String _head(String name) {
  final protectedName = name.replaceAll('24/7', '24_7');
  final bare = protectedName
      .replaceAll(_years, ' ')
      .replaceAll(_decoration, ' ')
      .replaceAll(_quality, ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  final parts = bare.split(_separators).where((p) => p.trim().isNotEmpty);
  final head = parts.isEmpty ? '' : parts.first.trim();
  // A name that was only years and brackets keeps itself rather than becoming
  // an empty group name.
  return head.isEmpty ? name.trim() : head;
}

String _key(String head) => head
    .toUpperCase()
    .replaceAll(RegExp(r'[^A-Z0-9_ ]'), ' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

String _firstWord(String head) => head.split(' ').first;
