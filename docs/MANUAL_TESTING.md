# Pending manual verification

Companion to [architecture.md](architecture.md) §15, which describes the testing
*plan*. This file tracks the gap between it and reality: **what has been built
but not yet proven to work**, and why.

Most of it has one cause. The Android emulator cannot render video at all —
media_kit obtains its surface and then fails `eglCreateContext` with
`EGL_BAD_ATTRIBUTE`, a known upstream bug reported as not affecting real
devices (see [PHASE0_FINDINGS.md](PHASE0_FINDINGS.md) Q1). Everything downstream
of "a frame reaches the screen" is therefore unverified, no matter how much of
it is written.

Keep this honest. An item moves to **Verified** only when someone watched it
work, not when the code looks right.

Status: ⬜ not tested · 🟡 partially · ✅ verified · ❌ known broken

---

## 1. Blocked on a real Android device

The emulator cannot answer any of these. They need the tablet.

| # | What | Why it matters |
|---|---|---|
| ⬜ | Video renders at all | Everything below depends on it |
| ⬜ | Plex direct play on device | Proven on Windows in Phase 0, never on Android |
| ⬜ | **Panel VOD playback** | The `/movie/` URL and its container extension have *never been exercised*. Extensions vary per title (mkv as often as mp4) and are not recoverable from the panel afterwards — most likely place for a real failure |
| ⬜ | **Panel series episode playback** | Same, for the `/series/` path |
| ⬜ | Live channel playback | §4's `max_connections: 1` makes the failure mode look like a flaky provider rather than a client bug |
| ⬜ | **Stop-before-open when zapping** | The player stops before opening, never the reverse. On a one-connection line the natural ordering fails confusingly — this is the thing that behaviour exists to prevent |
| ⬜ | **Dead channel releases the connection** | A channel that never yields a frame must free the slot on timeout, or it burns the user's only connection until the panel times it out server-side |
| ⬜ | Resume actually seeks on open | The stored position is demonstrably correct, but the only observation so far ("117 → 116 min left") is equally consistent with restarting from zero |
| ⬜ | Hardware decode engages | Q5. Compare CPU against desktop |

## 2. Q5 — the rest of the deferred Android questions

From [PHASE0_FINDINGS.md](PHASE0_FINDINGS.md) Q5. Deferred out of Phase 0 for
lack of hardware and still waiting.

| # | What | Note |
|---|---|---|
| ⬜ | **SAF persisted folder permission survives a reboot** | §15 singles this out as *the one that fails*. Restart is not enough — reboot specifically |
| ⬜ | `MediaStore` returns video without `MANAGE_EXTERNAL_STORAGE` | §7.1's Play-policy-compliant path. Play lists that permission under invalid uses for generic media playback, so there is no fallback if this does not work |
| ⬜ | Hardware decode on device | Also listed above |
| ✅ | Release APK size | 30.8 MB arm64. Measured 2026-09-11 |

## 3. Plex transcode lifecycle

Open since Phase 0 and the single highest-consequence item here.

| # | What | Note |
|---|---|---|
| ⬜ | `decision → ping → stop` with `hasMDE=1` | The workaround is written but the full lifecycle never ran |
| ⬜ | **Session actually gone from the Plex dashboard after stop** | The named risk is leaking a transcode session on *every user's server*. Checking the dashboard is the only real proof |

The app currently exposes direct play only, precisely so nothing is built on
this while it is unproven.

## 4. Unexplained, worth resolving before relying on it

| # | What |
|---|---|
| ❌ | **Plex `art` renders empty.** Used for the landscape continue-watching tile, it returned something that renders blank rather than erroring, so the image error fallback never fired. Reverted to a letterboxed poster. Cause unknown |
| ⬜ | A second, worse Xtream panel — §10's malformed-TS claim is still unevidenced, and the one panel tested emits clean TS |

## 5. Not started at all

| # | What |
|---|---|
| ⬜ | iOS — nothing has ever been built or run |
| ⬜ | Android TV / Fire TV — no leanback tree yet (Phase 4) |
| ⬜ | The §15 device matrix — one Android TV box, one Fire TV, two phones, two iOS devices |
| ⬜ | Kill-switch drill (§16) — Remote Config is not adopted yet |

---

## Verified, so nobody re-tests it

Recorded to stop this becoming a list of everything.

- **Plex**: PIN link, server discovery, multi-server merge, library mapping,
  section browse, direct play (Windows), server-side search, series → seasons →
  episodes, session restore across restart
- **Xtream**: authentication against a real panel, live/VOD/series categories
  (466/156/83-scale confirmed), per-category channel and VOD fetch, channel
  search over 692 channels
- **App**: Advanced Sources gate including the §8.2 acknowledgement, Live TV tab
  appearing and disappearing with it, favourites persisting, watch history
  surviving an emulator cold boot, settings persistence
- **Build**: debug-only surfaces absent from the release binary across all three
  ABIs, with a control string present to prove the check was meaningful

---

## Automated coverage is thin, and that is separate

15 tests, all covering theme tokens and probe-log scrubbing. §15 asks for unit
tests on Xtream response parsing, the Plex PIN state machine, M3U parser edge
cases and Advanced Sources toggle state; none exist. The Xtream client in
particular parses defensively against exactly one panel's JSON, so a second
panel is as likely to break it as to confirm it.

Manual verification on hardware does not substitute for that, and neither
substitutes for the other.
