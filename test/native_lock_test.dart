import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relay_player/core/native_licenses.dart';

/// `native-libs.lock.json` is the one place that says which libmpv this app
/// ships (architecture.md §10.1). These tests make a media_kit upgrade fail
/// until that file, and the licence list that depends on it, are updated in
/// the same change.
///
/// The binaries themselves are checked after a build by `tool/native_lock.py`,
/// because a unit test has no APK to open.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final lock =
      jsonDecode(File('native-libs.lock.json').readAsStringSync())
          as Map<String, dynamic>;
  const platforms = ['android', 'ios', 'windows'];

  test('the lock names the media_kit library versions pubspec.lock resolves',
      () {
    final resolved = _resolvedVersions(File('pubspec.lock').readAsStringSync());
    for (final p in platforms) {
      final entry = lock[p] as Map<String, dynamic>;
      expect(resolved[entry['package']], entry['version'],
          reason: '${entry['package']} changed version. Re-read the binary, '
              'update native-libs.lock.json and native_licenses.dart together');
    }
  });

  test('each package still fetches exactly the locked artifacts', () {
    final roots = _packageRoots();
    for (final p in platforms) {
      final entry = lock[p] as Map<String, dynamic>;
      final root = roots[entry['package']];
      expect(root, isNotNull, reason: '${entry['package']} is not resolved');
      final build = File('$root/${entry['buildFile']}').readAsStringSync();

      for (final pin in (entry['pins'] as List).cast<String>()) {
        expect(build, contains(pin), reason: '$p: $pin');
      }
      for (final a in (entry['artifacts'] as List).cast<Map>()) {
        expect(build, contains(a['url']), reason: '$p fetches a new URL');
        // The checksum the package itself verifies with. md5 is weak, which
        // is part of why tool/native_lock.py hashes the shipped .so too.
        final declared = a['md5'] ?? a['sha256'];
        expect(build, contains(declared), reason: '$p artifact checksum');
      }
    }
  });

  test('the licence page points at the locked builds', () async {
    for (final (platform, key) in [
      (TargetPlatform.android, 'android'),
      (TargetPlatform.iOS, 'ios'),
      (TargetPlatform.windows, 'windows'),
    ]) {
      debugDefaultTargetPlatformOverride = platform;
      registerNativeLicenses();
      final text = (await LicenseRegistry.licenses.toList())
          .expand((e) => e.paragraphs)
          .map((p) => p.text)
          .join('\n');
      expect(text, contains('Corresponding source: ${lock[key]['buildSource']}'),
          reason: key);
      LicenseRegistry.reset();
    }
    debugDefaultTargetPlatformOverride = null;
  });

  test('every shipped Android ABI has a pinned hash', () {
    final shipped = (lock['android']['shipped'] as Map).cast<String, String>();
    // The three ABIs a release APK and AAB carry; flutter does not ship x86.
    expect(shipped.keys.toSet(), {'arm64-v8a', 'armeabi-v7a', 'x86_64'});
    for (final h in shipped.values) {
      expect(h, matches(RegExp(r'^[0-9a-f]{64}$')));
    }
  });
}

/// Reads `name: x` / `version: "y"` pairs out of pubspec.lock. It is YAML, but
/// regular enough that pulling in a YAML parser for a test is not worth it.
Map<String, String> _resolvedVersions(String lock) {
  final out = <String, String>{};
  final re = RegExp(r'^  (\S+):\n(?:    .*\n)*?    version: "([^"]+)"',
      multiLine: true);
  for (final m in re.allMatches(lock.replaceAll('\r\n', '\n'))) {
    out[m[1]!] = m[2]!;
  }
  return out;
}

Map<String, String> _packageRoots() {
  final config = jsonDecode(
          File('.dart_tool/package_config.json').readAsStringSync())
      as Map<String, dynamic>;
  final base = Uri.file('${Directory.current.path}/.dart_tool/');
  return {
    for (final p in (config['packages'] as List).cast<Map>())
      p['name'] as String:
          base.resolve(p['rootUri'] as String).toFilePath(),
  };
}
