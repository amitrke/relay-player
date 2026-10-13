import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Adds the native libraries media_kit bundles on Android and iOS to Flutter's
/// licence page (Settings → About → Open-source licences, §12.1).
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
/// **iOS has its own list**, added 2026-09-23 when the first TestFlight builds
/// shipped with no native notices at all. It is not the Android list relabelled:
/// `media_kit_libs_ios_video` pulls prebuilt xcframeworks from a different
/// repository (`libmpv-darwin-build`), so versions differ, and the set differs
/// too: iOS also bundles libpng and uchardet. It was read from the binaries the
/// same way: mpv 0.36.0 with `-Dgpl=false`; FFmpeg 6.0 reporting "LGPL version 3
/// or later", configured `--disable-autodetect --disable-all --enable-version3`
/// with exactly three external libraries (mbedTLS, libxml2, dav1d) and no
/// `--enable-gpl`. That repository's lock file also lists libx264, libvpx and
/// libvorbis, for other variants; the shipped frameworks were checked and
/// contain none of them (only FFmpeg's own Vorbis decoder and code that
/// recognises x264-encoded files). zlib and iconv come from iOS itself.
///
/// Windows development builds load a different libmpv again and are not
/// distributed, so they register nothing.
void registerNativeLicenses() {
  final set = switch (defaultTargetPlatform) {
    TargetPlatform.android => _android,
    TargetPlatform.iOS => _ios,
    _ => null,
  };
  if (set == null) return;
  LicenseRegistry.addLicense(() => _entries(set));
}

typedef _Library = ({
  String name,
  String version,
  String licence,
  List<String> files,
});

typedef _Set = ({
  String buildSource,
  String bundledAs,
  List<_Library> libraries,
});

/// The build every library below came from, and so the answer to "where is
/// the source". It pins each upstream version and fetches that exact source.
/// Pointing at it rather than hosting tarballs ourselves is the usual
/// practice for LGPL libraries used unmodified, but it depends on that
/// repository staying up; see the ffmpeg item under architecture.md Open items.
const _android = (
  buildSource:
      'https://github.com/media-kit/libmpv-android-video-build/tree/v1.1.7',
  bundledAs: 'bundled in libmpv.so on Android',
  libraries: _androidLibraries,
);

const _androidLibraries = <_Library>[
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

/// The iOS build: `media_kit_libs_ios_video` 1.1.4 fetches release v0.6.0,
/// `ios-universal-video-default`. Versions are that tag's `downloads.lock`,
/// cross-checked against the binaries where they print one (FFmpeg, mpv,
/// HarfBuzz, libpng). Mbed TLS ships as three frameworks (Mbedtls, Mbedcrypto,
/// Mbedx509) and is listed once.
const _ios = (
  buildSource: 'https://github.com/media-kit/libmpv-darwin-build/tree/v0.6.0',
  bundledAs: 'bundled as a framework in the iOS app',
  libraries: <_Library>[
    (
      name: 'mpv (libmpv)',
      version: '0.36.0',
      licence: 'LGPL-2.1-or-later (built with -Dgpl=false)',
      files: ['mpv-copyright.txt', 'lgpl-2.1.txt'],
    ),
    (
      name: 'FFmpeg',
      version: '6.0',
      licence: 'LGPL-3.0-or-later (built with --disable-autodetect '
          '--disable-all --enable-version3, no --enable-gpl)',
      files: ['ffmpeg-license.txt', 'lgpl-3.0.txt', 'gpl-3.0.txt'],
    ),
    (
      name: 'FriBidi',
      version: '1.0.13',
      licence: 'LGPL-2.1-or-later',
      files: ['lgpl-2.1.txt'],
    ),
    (
      name: 'uchardet',
      version: '0.0.8',
      // Tri-licensed MPL-1.1 / GPL-2.0-or-later / LGPL-2.1-or-later; the LGPL
      // is the option that fits a dynamically linked library in this app.
      licence: 'LGPL-2.1-or-later (one of its MPL-1.1 / GPL-2.0 / LGPL-2.1 '
          'options)',
      files: ['lgpl-2.1.txt'],
    ),
    (
      name: 'Mbed TLS',
      version: '3.4.1',
      licence: 'Apache-2.0',
      files: ['LICENSE-2.0.txt'],
    ),
    (
      name: 'FreeType',
      version: '2.13.2',
      licence: 'FreeType License (FTL). Portions of this software are '
          'copyright © 2023 The FreeType Project (www.freetype.org). All '
          'rights reserved.',
      files: ['freetype.txt'],
    ),
    (
      name: 'HarfBuzz',
      version: '8.1.1',
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
      version: '1.2.1',
      licence: 'BSD-2-Clause',
      files: ['dav1d.txt'],
    ),
    (
      name: 'libxml2',
      version: '2.11.5',
      licence: 'MIT',
      files: ['libxml2.txt'],
    ),
    (
      name: 'libpng',
      version: '1.6.40',
      licence: 'PNG Reference Library License version 2',
      files: ['libpng.txt'],
    ),
  ],
);

Stream<LicenseEntry> _entries(_Set set) async* {
  for (final lib in set.libraries) {
    final texts = [
      for (final f in lib.files) await rootBundle.loadString('assets/licenses/$f'),
    ];
    yield LicenseEntryWithLineBreaks(
      [lib.name],
      [
        '${lib.name} ${lib.version}, ${set.bundledAs}.\n'
            'Licence: ${lib.licence}.\n'
            'Corresponding source: ${set.buildSource}, which fetches this '
            'exact version from upstream. Used unmodified, and dynamically '
            'linked: it is a separate file inside the app package.',
        ...texts,
      ].join('\n\n'),
    );
  }
}
