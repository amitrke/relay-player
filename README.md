# Subnext Player

A general-purpose media player that relays a stream from whatever source you
point it at — a Plex server, a NAS or local files, or an optional IPTV
provider — across Android phone/tablet, iOS, and Android TV/Fire TV.

[![Download on the App Store](https://img.shields.io/badge/App_Store-Download-000000?style=for-the-badge&logo=apple&logoColor=white)](https://apps.apple.com/app/id6815342410)
[![Get it on Google Play](https://img.shields.io/badge/Google_Play-Get_it-000000?style=for-the-badge&logo=googleplay&logoColor=white)](https://play.google.com/store/apps/details?id=com.subnext.relay)

**Status: published on Google Play and the App Store**, checked 2026-10-13.
Both public listings load: Play at `com.subnext.relay`, and the App Store at
id6815342410 (iPhone and iPad, iOS 15 or later). Phase 0 closed on 2026-09-11.
The app plays from Plex, device storage, folders you pick and SMB shares, with
Advanced sources present but off by default.

Being on a store is not the same as being verified. Much of the app is built
but has not been confirmed on real hardware, and
[docs/MANUAL_TESTING.md](docs/MANUAL_TESTING.md) is the honest list. What each
release contains, and how a build moves from a test track to the public, is
the ladder in [docs/RELEASING.md](docs/RELEASING.md).

## Documentation

Read [CLAUDE.md](CLAUDE.md) before the first change; it is short and points at
the rest.

- [docs/architecture.md](docs/architecture.md) - architecture, store-policy
  risk analysis, the phased roadmap, and the open decisions
- [docs/PHASE0_FINDINGS.md](docs/PHASE0_FINDINGS.md) - measured evidence from
  the validation phase, including the hypotheses it ruled out
- [docs/MANUAL_TESTING.md](docs/MANUAL_TESTING.md) - what has and has not been
  verified on real hardware
- [docs/RELEASING.md](docs/RELEASING.md) - versioning, the release ladder, and
  the Play and TestFlight pipeline
- [docs/STORE_LISTING.md](docs/STORE_LISTING.md) - listing copy and drafted
  answers for the Play Console forms

## Running it

```sh
flutter pub get
flutter run -d windows            # fastest loop for protocol and API work
flutter run -d <android-device>   # anything platform-specific, and video
```

Video cannot be tested on the Android emulator: media_kit fails to create a GL
context there, so the clock runs while the picture stays black. Use Windows or
real hardware. See `CLAUDE.md` §6.

## Developer tools

In debug builds, long-press the Relay mark on the Plex link screen for a menu
with the design gallery and the Phase 0 spike harness. Neither exists in a
release build.

The spike harness still answers open questions, so it stays. It needs real
credentials:

```sh
cp lib/features/_spike/spike_config.example.dart \
   lib/features/_spike/spike_config.dart
# fill in real hosts/credentials -- spike_config.dart is gitignored
```

## Credentials

Never commit real provider credentials, hosts or names. `spike_config.dart` is
gitignored; the tracked `.example` file is the template. This is a public repo,
and `CLAUDE.md` §1 explains why this matters beyond credential hygiene.

## License

See [LICENSE](LICENSE).
