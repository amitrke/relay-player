# Phase 0 — Validation Findings

Companion to [architecture.md](architecture.md) §13 Phase 0. **This document is
the deliverable of Phase 0**, not the spike code — the code exists to produce
the answers recorded here and is deleted afterward.

Fill each section in as you run the probes. **Negative results are the point.**
A "no" here is worth more than a week of Phase 1 rework, and three of the four
questions below have a specific expected-failure mode that would change the
architecture.

Run the harness with:

```
cp lib/features/_spike/spike_config.example.dart lib/features/_spike/spike_config.dart
# fill in your real hosts/credentials -- spike_config.dart is gitignored
flutter run -d windows          # fastest loop; answers protocol questions
flutter run -d <android-device> # required for the platform questions
```

Status legend: ⬜ not started · 🟡 in progress · ✅ answered · ❌ blocked

---

## Q1 — Does media_kit/libmpv tolerate real IPTV streams? (§10)

**Status:** ⬜

**Why it matters:** §10 picks media_kit over `video_player`/`better_player`
*specifically* because libmpv is claimed to be more tolerant of malformed
MPEG-TS from cheap panels. If that tolerance doesn't materialize, the primary
argument for the heavier dependency collapses and `better_player` becomes the
default rather than the fallback.

**Probe:** Tab 1. Feed it, in order: an Xtream live `.ts` URL, an Xtream VOD
`.mp4`, a raw `.m3u8`, and 2–3 channels pulled from the M3U dump in Tab 4.

| Stream | Type | First frame (ms) | Codec (v/a) | mpv warnings | Verdict |
|---|---|---|---|---|---|
| | live .ts | | | | |
| | VOD .mp4 | | | | |
| | .m3u8 | | | | |
| | M3U ch. | | | | |

**Seek behaviour on live:** _(§10 assumes live has no seek — confirm rather
than assume; some panels do serve seekable TS)_

**Decision — media_kit or better_player as primary?**

> _(record here)_

---

## Q2 — Is `dart_plex` 0.1.2 viable? (§6)

**Status:** 🟡 in progress — PIN flow reached; one defect found (below)

**Why it matters:** This is the flagship integration sitting on a package that
was days old and at ~118 downloads when chosen. §6 costs the fallback
(hand-rolling the needed subset) at roughly a week — cheap if decided now,
expensive if discovered in Phase 1.

**Probe:** Tab 2, steps 1a → 4 in order.

| Step | Works? | Notes / exceptions verbatim |
|---|---|---|
| `createPin` / `pollPin` | partly — see below | Works, but the default argument is wrong for this flow |
| `fetchResources` + `bestConnection()` | | |
| `library.sections()` | | |
| `library.allByType()` | | |
| `decisionUniversal` | | |
| Playback of transcode URL | | |
| `pingUniversal` — survives 60s+ | | |
| `stopUniversal` — session actually gone | | |

#### Confirmed finding — `createPin` default produces an unusable code

**Status:** ✅ found and worked around, 2026-09-10.

`dart_plex`'s `createPin({bool strong = true})` defaults to `strong: true`,
which makes Plex issue a JWT-grade token whose `code` is a long opaque string
(observed: `zygvhan6tvjbi3psfq9sl865m`, 25 characters). **plex.tv/link only
accepts the 4-character code**, so the default silently yields a PIN the user
cannot enter anywhere. The flow does not error — it just hands you a code that
does not work.

The package's own docstring on that method reads *"Plex returns a `PlexPin`
with a 4-character `code` that the user must enter at https://plex.tv/link"* —
directly contradicted by its own default parameter.

- **Fix:** call `createPin(strong: false)` for the link flow.
- The probe now also asserts the code is exactly 4 characters and logs loudly
  if not, so a future version changing this cannot regress silently.
- **Weight for the Q2 decision:** not disqualifying on its own — one wrong
  default, easily worked around. But it is evidence about maturity: a
  days-old package whose documentation and defaults disagree on its
  best-known flow has not had many users through that path. Treat the
  transcode lifecycle below with matching suspicion, and do not assume the
  docstrings are load-bearing.

**The decisive one is the last row.** After pressing "Stop session", check the
Plex server dashboard directly. A session still listed means teardown is
broken, which is a blocking finding — the app would leak transcode sessions on
every user's server.

**Direct play vs transcode:** did direct play work for compatible files, and
did forcing `directPlay: false` genuinely produce a transcode?

> _(record here)_

**Decision — adopt `dart_plex`, or hand-roll?**

> _(record here)_

---

## Q3 — Does `smb://` work natively, or is the loopback bridge needed? (§7.2)

**Status:** ⬜

**Why it matters:** §7.2 says this answer *changes the design*. If libmpv opens
SMB directly, the whole bridge disappears. If not, the bridge becomes shared
infrastructure that FTP/WebDAV would later reuse.

**Probe:** Tab 3, steps 1 → 3.

**Step 1 — native `smb://`:** _(expected: fails; prebuilt libmpv rarely bundles
libsmbclient)_

> _(record here)_

**Step 2 — `smb_connect` 0.0.9 reliability.** Note this is an even earlier
version than §7.2 assumed. Record exceptions verbatim.

| Operation | Works? | Timing | Notes |
|---|---|---|---|
| `connectAuth` | | | |
| `listShares` | | | |
| `listFiles` | | | |
| Random-access read at 50% | | | |

**Step 3 — loopback bridge.** The log prints a `bridge:` line per HTTP range
request. **Multiple distinct ranges = libmpv is seeking correctly through the
bridge**, which is the actual success criterion — a bridge that ignores Range
looks fine until a user scrubs.

> _(record here)_

**Reconnect behaviour:** disconnect the NAS / drop wifi mid-playback. What
happens? §7.2 calls this "real state to manage" — characterize it now.

> _(record here)_

**Decision — bridge needed? Is `smb_connect` good enough to ship on?**

> _(record here)_

---

## Q4 — M3U/XMLTV parse cost and data quality (§5)

**Status:** ⬜

**Probe:** Tab 4.

**M3U:**

| Metric | Value |
|---|---|
| Entries parsed | |
| Missing `tvg-id` (cannot be EPG-linked) | |
| Missing `group-title` | |
| Distinct groups | |
| Any movie/series-looking groups? | |

§5 says treat M3U as "Live only" unless `group-title` clearly separates
Movies/Series. Does this playlist support that default?

> _(record here)_

**XMLTV:**

| Metric | Value |
|---|---|
| Download size (compressed / decompressed) | |
| Channels / programmes | |
| Parse on **main isolate** (ms) | |
| Parse via `compute()` (ms) | |
| Did the UI visibly freeze? | |

**Then re-run this same probe on the weakest device you target (Fire TV, §11).**
Desktop timings understate this badly, and §5's isolate requirement stands or
falls on the slow-device number, not the fast one.

> _(record here)_

---

## Q5 — Platform questions (Android device required)

Not answerable on desktop. Deferred from the probes above but still Phase 0.

- [ ] **SAF persisted folder permission survives app restart AND device
      reboot** (§15 calls this out specifically — the reboot case is the one
      that fails)
- [ ] `MediaStore` scan returns expected video without `MANAGE_EXTERNAL_STORAGE`
      (§7.1 — the Play-policy-compliant path)
- [ ] Hardware decode actually engages on device (compare CPU use vs desktop)
- [ ] App size impact of bundling libmpv — measure the release APK/AAB

---

## Incidental findings

Things learned during scaffolding that aren't among the four questions:

- **`flutter_secure_storage` does not build on Windows** without Visual
  Studio's "C++ ATL for v143 build tools" component (`atlstr.h` missing). It
  was removed from `pubspec.yaml` because Phase 0 doesn't use it. It is still
  the right choice for Android/iOS per §3 — re-add it in Phase 1, and either
  install the VS ATL component or accept that desktop builds are Phase-0-only.
  Worth knowing before §14's "media_kit supports desktop too, which costs
  nothing now" is taken at face value: desktop support has a toolchain cost.
- **`smb_connect` resolved to 0.0.9**, not the version implied by §7.2's
  description. Treat the reliability question as correspondingly more open.
- **`dart_plex` 0.1.2 does expose the full transcode lifecycle**
  (`decisionUniversal`, `universalVideoUrl`, `pingUniversal`, `stopUniversal`)
  — the API surface §6 worried about is at least *present*. Whether it works
  is Q2.

---

## Phase 0 exit checklist

Phase 1 should not start until every line here is true:

- [ ] Q1–Q4 each have a recorded decision, not just data
- [ ] Q5 platform items verified on a real Android device
- [ ] ffmpeg build/licensing decision made (§10 — LGPL, dynamic, no GPL
      encoders) and written down
- [ ] ffmpeg binding chosen and pinned (`ffmpeg_kit_flutter` is discontinued,
      upstream archived — §14)
- [ ] Play + App Store developer accounts confirmed active
- [ ] Disclaimer copy drafted (general + Advanced Sources, §8.2)
- [ ] Standing demo Xtream account secured for App Review (§8.4)
- [ ] Decision recorded on Firebase Remote Config kill switch (§16)
- [ ] `lib/features/_spike/` deleted, and the spike deps that Phase 1 doesn't
      need (`shelf`, `smb_connect`) re-justified or removed
