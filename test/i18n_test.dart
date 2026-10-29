import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:relay_player/core/i18n/app_locale.dart';
import 'package:relay_player/i18n/strings.g.dart';

/// Localisation (architecture.md §12.3), held to what can be checked without
/// a speaker of the language: that no UI text bypasses the string files, that
/// every translation has the same keys and placeholders as the English base,
/// that the generated code is current, and that a draft never reaches a
/// release build.
///
/// Whether a translation is *right* is not something this can know; that is
/// what [reviewedLocales] is for.
void main() {
  final dir = Directory('lib/i18n');
  Map<String, dynamic> load(String name) =>
      jsonDecode(File('${dir.path}/$name').readAsStringSync())
          as Map<String, dynamic>;

  final base = load('en.i18n.json');
  final drafts = [
    for (final f in dir.listSync().whereType<File>())
      if (f.path.endsWith('.i18n.json') && !f.path.endsWith('en.i18n.json'))
        f.uri.pathSegments.last,
  ]..sort();

  test('there are drafts, and none of them counts as reviewed', () {
    expect(drafts, isNotEmpty);
    expect(reviewedLocales, {AppLocale.en},
        reason: 'add a locale to reviewedLocales only with a recorded review');
  });

  for (final name in drafts) {
    test('$name has exactly the base keys and placeholders', () {
      final problems = <String>[];
      _compare(base, load(name), '', problems);
      expect(problems, isEmpty, reason: problems.join('\n'));
    });
  }

  test('the generated code matches the string files', () {
    final generated = File('${dir.path}/strings_en.g.dart').readAsStringSync();
    final stale = <String>[];
    void walk(Object? node, String path) {
      if (node is Map) {
        node.forEach((k, v) => walk(v, '$path.$k'));
      } else if (node is String &&
          !node.contains('{') &&
          !node.contains('\n') &&
          !node.contains("'") &&
          !node.contains(r'$')) {
        if (!generated.contains("'$node'")) stale.add(path);
      }
    }

    walk(base, '');
    expect(stale, isEmpty,
        reason: 'run `dart run slang` after editing lib/i18n: $stale');
    for (final name in drafts) {
      final locale = name.replaceAll('.i18n.json', '').replaceAll('-', '_');
      expect(File('${dir.path}/strings_$locale.g.dart').existsSync(), isTrue,
          reason: '$name has no generated code; run `dart run slang`');
    }
  });

  test('a draft shows in debug builds and never in release ones', () {
    for (final locale in AppLocale.values) {
      expect(localeFor(locale, release: false), locale);
      expect(
        localeFor(locale, release: true),
        reviewedLocales.contains(locale) ? locale : AppLocale.en,
      );
    }
  });

  test('UI text goes through the string files', () {
    // A literal starting with a letter, as the argument a widget shows. Brand
    // and product names stay as they are in every language, and the TMDB
    // attribution is required wording (§12.3).
    final ui = RegExp(
      r'''(?:\bText\(|\b(?:tooltip|label|title|message|hintText|labelText|subtitle|semanticsLabel|semanticLabel|actionLabel|helperText|errorText)\s*:)\s*(?:const\s+)?'([A-Za-z][^']*)''',
    );
    // 'S' is the letter in the app's mark (RelayMark), a glyph rather than a
    // word.
    const exact = {'S', 'Subnext Player'};
    const prefixes = {'This product uses the TMDB API'};
    final found = <String>[];
    for (final f in Directory('lib').listSync(recursive: true).whereType<File>()) {
      final path = f.path.replaceAll(r'\', '/');
      if (!path.endsWith('.dart') ||
          path.contains('/i18n/') ||
          path.contains('/_spike/') ||
          path.contains('/_gallery/') ||
          path.contains('/_debug/')) {
        continue;
      }
      for (final m in ui.allMatches(f.readAsStringSync())) {
        final text = m[1]!;
        if (exact.contains(text) || prefixes.any(text.startsWith)) continue;
        found.add('$path: $text');
      }
    }
    expect(found, isEmpty,
        reason: 'move these into lib/i18n/en.i18n.json:\n${found.join('\n')}');
  });
}

const _pluralForms = {'zero', 'one', 'two', 'few', 'many', 'other'};

bool _isPlural(Map<dynamic, dynamic> m) =>
    m.isNotEmpty && m.keys.every(_pluralForms.contains);

Set<String> _placeholders(String s) =>
    {for (final m in RegExp(r'\{(\w+)\}').allMatches(s)) m[1]!};

void _compare(Object? base, Object? draft, String path, List<String> out) {
  if (base is Map && _isPlural(base)) {
    if (draft is! Map || !draft.containsKey('other')) {
      out.add('$path: plural needs at least "other"');
      return;
    }
    final want = _placeholders(base['other'] as String);
    for (final MapEntry(:key, :value) in draft.entries) {
      if (!_pluralForms.contains(key) || value is! String) {
        out.add('$path.$key: not a plural form');
        continue;
      }
      final got = _placeholders(value);
      // "one" may spell the number out, as the base does for pending watches.
      final ok = key == 'other' ? got.containsAll(want) && want.containsAll(got)
          : want.containsAll(got);
      if (!ok) out.add('$path.$key: placeholders $got, base has $want');
    }
    return;
  }
  if (base is Map) {
    if (draft is! Map) {
      out.add('$path: should be an object');
      return;
    }
    for (final k in base.keys) {
      if (!draft.containsKey(k)) out.add('$path.$k: missing');
    }
    for (final k in draft.keys) {
      if (!base.containsKey(k)) out.add('$path.$k: not in the base');
    }
    for (final k in base.keys) {
      if (draft.containsKey(k)) _compare(base[k], draft[k], '$path.$k', out);
    }
    return;
  }
  if (draft is! String) {
    out.add('$path: should be a string');
    return;
  }
  final want = _placeholders(base as String);
  final got = _placeholders(draft);
  if (want.length != got.length || !want.containsAll(got)) {
    out.add('$path: placeholders $got, base has $want');
  }
  if (draft.trim().isEmpty) out.add('$path: empty');
}
