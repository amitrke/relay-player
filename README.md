# Relay Player

A general-purpose media player that relays a stream from whatever source you
point it at — a Plex server, a NAS or local files, or an optional IPTV
provider — across Android phone/tablet, iOS, and Android TV/Fire TV.

**Status: Android, in Play internal testing, not published.** Phase 0 closed
on 2026-09-11. The app plays from Plex, device storage, folders you pick and
SMB shares, with Advanced sources present but off by default. Builds go to
Play's internal track, which reaches named testers only and is not reviewed.
Nothing has been through store review, and iOS has never been built.

Video has not yet been confirmed on a real Android device, and much else is
built but unverified. [docs/MANUAL_TESTING.md](docs/MANUAL_TESTING.md) is the
honest list. What each release contains, and what gates a wider audience, is
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
  the Play internal-testing pipeline
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
