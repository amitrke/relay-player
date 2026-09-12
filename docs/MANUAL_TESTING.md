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
| ⬜ | **SAF persisted folder permission survives a reboot** | §15 singles this out as *the one that fails*. Restart is not enough — reboot specifically. Picker and persistence now exist so this is testable; pick a folder, reboot the device, and check it still lists |
| ✅ | `MediaStore` returns video without `MANAGE_EXTERNAL_STORAGE` | Verified 2026-09-11: scoped `READ_MEDIA_VIDEO` is sufficient, folders enumerate, and an id resolves to a playable path |
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
| ⬜ | **The Plex link flow end to end** (issue #3 fix). The screen now leaves for the library on the transition into `PlexStage.ready`, with a snackbar naming the server. Only the router behaviour behind it is under test — linking needs a real Plex account, so the navigation itself has never run. Check both branches: one server on the account (auto-connect) and several (server picker) |
| ⬜ | **A server that hangs, in Settings → Sources.** The per-server timeout moved into `plexSectionsProvider`, so an unreachable server should now fail after 10s with its name and a Try again rather than spinning forever. Needs a server that hangs rather than refusing — a relay connection to an offline server is the reproducible case |
| ⬜ | A second, worse Xtream panel — §10's malformed-TS claim is still unevidenced, and the one panel tested emits clean TS |

## 5. SMB — built, never seen a real share

The client, browsing, and playback through §7.2's bridge are written and the
add-share form rejects an unreachable host cleanly. None of it has spoken to an
actual NAS in this app; Phase 0's Q3 numbers came from the spike harness, not
this code.

| # | What | Note |
|---|---|---|
| ⬜ | Connect to a real share and list its shares | Phase 0 saw 17 on a real NAS |
| ⬜ | Browse folders and play a file through the bridge | The bridge is proven over SAF; SMB reuses it unchanged |
| ⬜ | **NAS goes away mid-playback** | §7.2 calls the connection "real state to manage". Connect-time failure is handled; a share that vanishes *during* playback is not |
| ⬜ | Wi-Fi drop and reconnect | Same |
| ⬜ | A full episode without the connection dropping | Phase 0 listed this explicitly and it is still open |

## 6. Not started at all

| # | What |
|---|---|
| ⬜ | iOS — nothing has ever been built or run |
| ⬜ | Android TV / Fire TV — no leanback tree yet (Phase 4) |
| ⬜ | **Google TV sideload.** The manifest is TV-ready and `aapt2 dump badging` confirms `leanback-launchable-activity`, `android:banner` and both features as not-required, but no APK has been installed on a TV. Check: the app appears in the launcher's apps row at all (some Google TV builds hide sideloaded apps), the banner renders legibly at the launcher's own scaling rather than just as a 320×180 image, and how far the phone UI gets on a D-pad before Phase 4 |
| ⬜ | The banner at real launcher scale — it has only been checked as an image file, centre-line aligned, never on a panel at viewing distance |
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
- **Local storage**: media permission flow including Android 14's partial-access
  option, folder enumeration, and playing a device file end to end; SAF folder
  picking with a persistable grant, browsing subfolders and files inside it, and
  playing one through §7.2's loopback bridge — with the same three-range request
  pattern Phase 0 saw over SMB
- **App**: Advanced Sources gate including the §8.2 acknowledgement, Live TV tab
  appearing and disappearing with it, favourites persisting, watch history
  surviving an emulator cold boot, settings persistence
- **Build**: debug-only surfaces absent from the release binary across all three
  ABIs, with a control string present to prove the check was meaningful

---

## Automated coverage is thin, and that is separate

23 tests. The loopback bridge now has real coverage — ranges, suffix ranges, the
unsatisfiable case, HEAD, and path rejection — which is the first piece of this
app tested rather than demonstrated, and it paid for itself immediately by
proving the bridge was correct while the Android path was still broken.

Everything else is still thin. §15 asks for unit tests on Xtream response
parsing, the Plex PIN state machine, M3U parser edge cases and Advanced Sources
toggle state; none exist. The Xtream client in particular parses defensively
against exactly one panel's JSON, so a second panel is as likely to break it as
to confirm it.

Manual verification on hardware does not substitute for that, and neither
substitutes for the other.
