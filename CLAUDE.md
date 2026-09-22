# Working on Subnext Player

Conventions for anyone — human or agent — making changes here. Read this before
the first edit; it is short on purpose, and it points at the documents that are
actually authoritative.

## 1. This repo is public. Never name a provider.

No real provider host, username, password, token, server identifier or LAN
address goes into source, a doc, a test fixture, or a commit message. Use
`<panel-host>`, `<lan-ip>`, `<redacted>`. `lib/features/_spike/spike_config.dart`
is gitignored; only the tracked `.example` file describes its shape.

This is not only credential hygiene. §1 and §8.3 of `docs/architecture.md` rest
on the project not looking like it points at, curates, or is associated with any
particular IPTV provider, and that primary-purpose argument is the app's whole
store-policy position. Numbers, timings, response shapes and failure modes are
the valuable part of any finding, and none of them require naming the source.

Rendering user-supplied labels inside the app is fine — every player does it.
Putting them in *our* artefacts is not: §13 Phase 6 extends this to store
screenshots, which come from Plex, local files or SMB only.

## 2. The docs are the authority, and they are numbered

- `docs/architecture.md` — architecture, store-policy risk analysis, the phased
  roadmap, and a live "Open items" decision queue. Written as numbered
  §sections that code comments and commit messages cite directly.
- `docs/PHASE0_FINDINGS.md` — measured evidence from the validation phase,
  including the hypotheses that were ruled out.
- `docs/MANUAL_TESTING.md` — the honest state of what has and has not been
  verified on real hardware.
- `docs/RELEASING.md` — the Play internal-testing pipeline, the one-time
  setup it depends on, and the failure modes seen while running it.

Read the relevant § before proposing a design change. Several decisions are
deliberately counterintuitive and were corrected by evidence — §5's isolate
rule, §4's `max_connections` as a lifecycle constraint rather than a setting,
§8.3 refusing to ship a provider directory.

## 3. A decision is not finished until it is written down

Findings, negative results, wrong hypotheses and notes that have gone stale all
belong in the docs above, not only in the code that acted on them. When a
finding is resolved or turns out wrong, edit the existing entry to say so with
the date rather than leaving it asserting the old conclusion; superseded
hypotheses stay, labelled, so nobody re-runs them.

Prefer flagging a tradeoff or an uncertainty to asserting a clean result. A
verification whose *control* also fails proves nothing, and saying otherwise is
worse than not checking.

## 4. Conventions

- **Comments carry the why, at length, and cite §sections.** `lib/` is
  deliberately heavier on comment density than a typical Flutter codebase.
  Match the surrounding file.
- **Commit messages explain the reasoning**, not the diff. `git log` is part of
  the written record; read a few before writing one.
- **No hardcoded colours.** Theme is a runtime setting (§12.2) — go through the
  design tokens in `lib/core/theme/` so the TV tree inherits the same palette.
- **Don't remove scaffolding that open questions still depend on**, notably the
  spike harness under `lib/features/_spike/`.

## 5. Layout

```
lib/core/      theme tokens, routing, platform detection
lib/data/      source clients: plex, xtream, m3u, filesystem, local, ai
lib/domain/    models and repository interfaces
lib/features/  one directory per feature area; _spike and _gallery are dev-only
lib/platform/  mobile/ and tv/ layout trees — tv/ is still empty (Phase 4)
```

## 6. Commands

```sh
flutter pub get
flutter analyze
flutter test
flutter run -d windows           # fastest loop for protocol and API work
flutter run -d <android-device>  # required for anything platform-specific
```

**Video cannot be tested on the Android emulator.** media_kit obtains its
surface but fails to create a GL context (`EGL_BAD_ATTRIBUTE`), an upstream bug
that does not affect real devices — the position clock advances while the
picture stays black. Test playback on Windows or real hardware. The emulator is
still fine for UI, navigation and API work. TV focus behaviour needs a real
Android TV / Fire TV device; emulators miss remote-input quirks.

Automated coverage is thin and honest about it — see the end of
`docs/MANUAL_TESTING.md`. Manual verification on hardware does not substitute
for unit tests, and neither substitutes for the other.
