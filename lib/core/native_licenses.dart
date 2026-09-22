import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Adds the native libraries media_kit bundles on Android to Flutter's licence
/// page (Settings → About → Open-source licences, §12.1).
///
/// Flutter's page collects the LICENSE of every Dart package automatically,
/// but `libmpv.so` is a prebuilt binary that arrives inside
/// `media_kit_libs_android_video`, so nothing it contains was listed. Most of
/// it is LGPL, and the LGPL is a distribution condition, not a courtesy: the
/// licence text has to travel with the app, and the user has to be told where
/// the corresponding source is.
///
/// What is in the binary was read out of it rather than taken from media_kit's
/// README (architecture.md, ffmpeg item under Open items, 2026-09-21): mpv
/// built with `-Dgpl=false`, FFmpeg 6.0 with `--disable-gpl --disable-nonfree
/// --enable-version3`, identical in the arm64 and armeabi-v7a release builds.
/// The versions below are `buildscripts/include/depinfo.sh` at the
/// `libmpv-android-video-build` tag that `media_kit_libs_android_video` pins.
/// **Upgrading media_kit can change all of it** — re-read the binary and update
/// this list in the same change.
///
/// Android only. Windows development builds load a different libmpv, and iOS
/// has never been built (§13 Phase 5); both need their own list when they
/// ship.
void registerNativeLicenses() {
  if (defaultTargetPlatform != TargetPlatform.android) return;
  LicenseRegistry.addLicense(_entries);
}

/// The build every library below came from, and so the answer to "where is
/// the source". It pins each upstream version and fetches that exact source.
/// Pointing at it rather than hosting tarballs ourselves is the usual
/// practice for LGPL libraries used unmodified, but it depends on that
/// repository staying up; see the ffmpeg item under architecture.md Open items.
const _buildSource =
    'https://github.com/media-kit/libmpv-android-video-build/tree/v1.1.7';

const _libraries = [
  (
    name: 'mpv (libmpv)',
    version: 'v0.36.0-549-g78d43740f5',
    licence: 'LGPL-2.1-or-later (built with -Dgpl=false)',
    files: ['mpv-copyright.txt', 'lgpl-2.1.txt'],
  ),
  (
    name: 'FFmpeg',
    version: '6.0',
    licence: 'LGPL-3.0-or-later (built with --disable-gpl --disable-nonfree '
        '--enable-version3)',
    // LGPL v3 is a set of additional permissions on top of GPL v3, and its
    // section 4 requires both texts to accompany the work.
    files: ['ffmpeg-license.txt', 'lgpl-3.0.txt', 'gpl-3.0.txt'],
  ),
  (
    name: 'FriBidi',
    version: '1.0.12',
    licence: 'LGPL-2.1-or-later',
    files: ['lgpl-2.1.txt'],
  ),
  (
    name: 'Mbed TLS',
    version: '3.4.0',
    licence: 'Apache-2.0',
    files: ['LICENSE-2.0.txt'],
  ),
  (
    name: 'FreeType',
    version: '2.13.0',
    licence: 'FreeType License (FTL). Portions of this software are copyright '
        '© 2023 The FreeType Project (www.freetype.org). All rights reserved.',
    files: ['freetype.txt'],
  ),
  (
    name: 'HarfBuzz',
    version: '7.2.0',
    licence: 'MIT ("Old MIT")',
    files: ['harfbuzz.txt'],
  ),
  (
    name: 'libass',
    version: '0.17.1',
    licence: 'ISC',
    files: ['libass.txt'],
  ),
  (
    name: 'dav1d',
    version: '1.2.0',
    licence: 'BSD-2-Clause',
    files: ['dav1d.txt'],
  ),
  (
    name: 'libxml2',
    version: '2.10.3',
    licence: 'MIT',
    files: ['libxml2.txt'],
  ),
];

Stream<LicenseEntry> _entries() async* {
  for (final lib in _libraries) {
    final texts = [
      for (final f in lib.files) await rootBundle.loadString('assets/licenses/$f'),
    ];
    yield LicenseEntryWithLineBreaks(
      [lib.name],
      [
        '${lib.name} ${lib.version}, bundled in libmpv.so on Android.\n'
            'Licence: ${lib.licence}.\n'
            'Corresponding source: $_buildSource, which fetches this exact '
            'version from upstream. Used unmodified, and dynamically linked: '
            'libmpv.so is a separate file inside the app package.',
        ...texts,
      ].join('\n\n'),
    );
  }
}
