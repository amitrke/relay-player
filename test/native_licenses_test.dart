import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relay_player/core/native_licenses.dart';

/// The LGPL requires its text to travel with the app. A missing asset or a
/// typo in a filename would only surface when someone opened the licence page
/// on an Android device, so this loads every entry the way that page does.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    LicenseRegistry.reset();
  });

  Future<List<LicenseEntry>> ours() async {
    final all = await LicenseRegistry.licenses.toList();
    return all.where((e) => e.packages.any(_names.contains)).toList();
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

  // The control: the finder above would pass vacuously if it matched nothing.
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
