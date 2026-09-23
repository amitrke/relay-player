import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relay_player/core/native_licenses.dart';

/// The LGPL requires its text to travel with the app. A missing asset or a
/// typo in a filename would only surface when someone opened the licence page
/// on a device, so this loads every entry the way that page does, on both
/// platforms that ship native code.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    LicenseRegistry.reset();
  });

  Future<List<LicenseEntry>> ours() async {
    final all = await LicenseRegistry.licenses.toList();
    return all
        .where((e) => e.packages.any({..._names, ..._iosOnly}.contains))
        .toList();
  }

  test('Android lists every bundled native library with its full text',
      () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    registerNativeLicenses();

    final entries = await ours();
    expect(entries.map((e) => e.packages.single).toSet(), _names);

    String text(String name) => entries
        .firstWhere((e) => e.packages.single == name)
        .paragraphs
        .map((p) => p.text)
        .join('\n');

    // FFmpeg's LGPL v3 needs the GPL v3 text beside it (LGPL v3 section 4).
    expect(text('FFmpeg'), contains('GNU LESSER GENERAL PUBLIC LICENSE'));
    expect(text('FFmpeg'), contains('GNU GENERAL PUBLIC LICENSE'));
    expect(text('mpv (libmpv)'), contains('Version 2.1'));
    expect(text('FreeType'), contains('The FreeType Project'));
    for (final name in _names) {
      expect(text(name), contains('libmpv-android-video-build'),
          reason: '$name must say where its source is');
    }
  });

  test('iOS lists its own set, pointing at the darwin build', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    registerNativeLicenses();

    final entries = await ours();
    expect(entries.map((e) => e.packages.single).toSet(),
        {..._names, ..._iosOnly});

    String text(String name) => entries
        .firstWhere((e) => e.packages.single == name)
        .paragraphs
        .map((p) => p.text)
        .join('\n');

    expect(text('FFmpeg'), contains('GNU LESSER GENERAL PUBLIC LICENSE'));
    expect(text('FFmpeg'), contains('GNU GENERAL PUBLIC LICENSE'));
    expect(text('libpng'), contains('PNG Reference Library License'));
    expect(text('uchardet'), contains('Version 2.1'));
    for (final name in {..._names, ..._iosOnly}) {
      expect(text(name), contains('libmpv-darwin-build'),
          reason: '$name must say where its iOS source is');
      expect(text(name), isNot(contains('libmpv-android-video-build')),
          reason: '$name must not point iOS users at the Android build');
    }
  });

  test('Android does not pick up the iOS-only libraries', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    registerNativeLicenses();

    final names = (await ours()).map((e) => e.packages.single).toSet();
    expect(names.intersection(_iosOnly), isEmpty);
  });

  // The control: the finders above would pass vacuously if they matched
  // nothing.
  test('other platforms register none of them', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    registerNativeLicenses();

    expect(await ours(), isEmpty);
  });
}

const _names = {
  'mpv (libmpv)',
  'FFmpeg',
  'FriBidi',
  'Mbed TLS',
  'FreeType',
  'HarfBuzz',
  'libass',
  'dav1d',
  'libxml2',
};

/// Bundled on iOS but not in the Android libmpv.so.
const _iosOnly = {'libpng', 'uchardet'};
