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
| `createPin` / `pollPin` | ✅ with `strong: false` | 4-char code (`9SRW`), 347 ms. Poll returned a 20-char token, 243 ms |
| `fetchResources` + `bestConnection()` | ✅ | 444 ms, 5 servers found (2 owned, 3 shared). Picked the local-https `*.plex.direct` URI |
| `library.sections()` | ✅ | 956 ms, 13 sections, types correctly mapped (movie/show/music/photo) |
| `library.allByType()` | ✅ | Returned items with usable `ratingKey`/`title`/`year` |
| `decisionUniversal` | ❌ HTTP 400 | **Probe bug, now fixed** — see below |
| Playback of transcode URL | ❌ | "Failed to open" `start.m3u8` — cause not yet isolated |
| `pingUniversal` — survives 60s+ | ❌ HTTP 404 | Likely a *symptom* of the two above, not an independent defect |
| `stopUniversal` — session actually gone | not reached | |

**Reading of the 2026-09-10 run:** everything up to and including library
browsing works, and works quickly. That is most of the package's surface, and
it is genuine evidence *for* `dart_plex`. The failures are clustered entirely
in the transcode lifecycle, and at least one of them was mine.

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

#### Probe bug — `decisionUniversal` needs the *same* params as the start URL

**Status:** ✅ fixed 2026-09-10, needs a re-run.

The decision call returned **HTTP 400**. Cause was in the probe, not the
package: it passed a hand-written subset (`path`, `session`, `directPlay`,
`directStream`, `videoResolution`, `maxVideoBitrate`) while
`universalVideoUrl` sends considerably more — `mediaIndex`, `partIndex`,
`protocol`, `container`, `fastSeek`, `offset`, `audioBoost`.

Plex rejects the decision endpoint outright without `mediaIndex`/`partIndex`.
**The general rule, which matters for Phase 1:** the decision request must
mirror the start request exactly. An incomplete set does not just risk a 400 —
it makes the server decide about a *different* request than the one you are
about to issue, which is worse than not asking at all.

#### Open — `start.m3u8` "Failed to open"

**Status:** 🟡 not yet isolated.

Two candidate causes, and the run so far cannot tell them apart:

1. **The transcoder** — plausible, since the decision call had failed, so no
   session had been negotiated.
2. **The transport** — `bestConnection()` selected
   `https://192-168-1-253.<hash>.plex.direct:32400`. That hostname resolves to
   the LAN IP and serves a real certificate, but **libmpv validates TLS with
   its own CA store**, not the OS one. If that fails, *every* Plex stream fails
   and nothing about the transcoder is wrong. This would be a much more serious
   finding, and it would also apply to §10's engine choice.

A **Step 3.5 · Direct play** button now splits these: direct play exercises the
same connection with no transcoder involved.

- Direct play works, transcode fails → transcoder problem.
- Both fail → transport problem. The probe then prints every connection
  candidate, including the plain-HTTP LAN equivalent (`http://<ip>:32400`) to
  try as a control.

#### The `pingUniversal` 404 is probably a symptom, not a defect

Plex has no session to keep alive if the transcode never started, so a 404
after a failed decision *and* a failed open is expected fallout. Only a 404
**while playback is actually running** would indict the package. The probe now
says so inline rather than logging three identical red stack traces.

#### Probe reporting bug — "OK" before the failure

The transcript read `media_kit open transcode HLS OK (141 ms)` immediately
followed by `player error: Failed to open`. `player.open()` returns as soon as
the command is queued, so timing it measures nothing useful; the error arrives
later on a separate stream. Replaced with a helper that waits for whichever
comes first — a frame or an error — and reports that. Worth remembering in
Phase 1: **`await player.open(...)` completing is not evidence that anything
played.**

**The decisive test is still `stopUniversal`.** After pressing "Stop session",
check the Plex server dashboard directly. A session still listed means teardown
is broken, which is a blocking finding — the app would leak transcode sessions
on every user's server.

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

## Q6 — Xtream panel reality check (§4)

**Status:** ✅ answered 2026-09-11 against a real panel (`ogold.org:8080`).

Not one of the original four questions, but it produced the most consequential
findings of Phase 0 so far. Measured directly against the API, not inferred.

### Account shape

| Field | Value | Why it matters |
|---|---|---|
| `auth` / `status` | `1` / `Active` | Credentials valid |
| `is_trial` | `0` | Full line, expires 2027-06-12 |
| **`max_connections`** | **`1`** | **See below — this is a design constraint** |
| `allowed_output_formats` | `m3u8`, `ts` | Both available |
| `server_protocol` / `https_port` | `http` / *(empty)* | **Cleartext only — see iOS note** |

### 🔴 `max_connections: 1` constrains the player design

One concurrent stream, total. The app must therefore guarantee it **never**
holds two streams open at once:

- Channel zapping must **stop the current stream before opening the next**, not
  open-then-stop. The natural implementation is the wrong one here.
- No preview-while-playing, no picture-in-picture of a *second* channel, no
  second window on desktop.
- A crash or force-quit may leave the connection held server-side until it
  times out, so the next launch can fail with no obvious cause. Worth surfacing
  `active_cons` in Settings so a user can see this rather than guess.

This is not exotic — single-connection lines are the common case. §4 currently
says `max_connections` is "worth surfacing in Settings"; it is more than that,
it is a constraint the player lifecycle has to be built around.

### 🔴 Catalogue payloads are far larger than §4 assumes

| Call | Items | Payload |
|---|---|---|
| `get_live_streams` | 15,951 | **5.3 MB** |
| `get_vod_streams` | 69,397 | **26.2 MB** |
| `get_series` | 7,375 | — |
| categories (live/vod/series) | 466 / 156 / 83 | — |

Single JSON responses. §5 requires isolate parsing for XMLTV; **this extends
that requirement to the Xtream client itself**, which §4 does not currently
mention. Decoding 26 MB of JSON into Dart objects on the main isolate will
freeze the UI outright, and on a Fire TV stick (§11) memory is a real risk, not
just latency. Plan for streaming/paged parsing and on-disk caching rather than
holding the whole catalogue in memory.

### 🔴 The EPG is effectively empty on this panel

Two independent failures, either of which alone would cripple the guide:

- **91% of live channels have no `epg_channel_id`** — 14,491 of 15,951. Those
  can never be linked to guide data, whatever the guide contains.
- **The XMLTV export contains zero `<programme>` elements.** 252 KB, 1,544
  `<channel>` definitions, and nothing else. There is no schedule data at all.
- The channel IDs that do exist are unreliable: `<channel id="AMC.us">` is
  reused verbatim for "ESPN+ EVENT 00", "01", "02"… — one ID mapping to many
  unrelated channels.

**Implication for §12 screen 7 (EPG guide):** for this provider the guide would
render empty. That is a provider-data problem, not an app bug, but the app has
to handle it gracefully and say so — an empty grid with no explanation reads as
broken software. §5 already says to "set expectations in onboarding copy rather
than guessing wrong"; this is the concrete case.

### 🟡 Streams 302-redirect to a different host

`/live/{user}/{pass}/{id}.ts` returns **HTTP 302** to a *different* server with
a tokenised path:

```
Location: http://94.26.105.59:8080/live/play/<opaque-token>/3
```

The player must follow redirects (libmpv does by default — confirm the same for
any fallback engine). Two consequences: the host actually serving video is not
the host the user configured, and it is also cleartext HTTP.

### 🟡 This panel's MPEG-TS is clean — which weakens one §10 argument

After following the redirect: `HTTP 200`, `content-type: video/mp2t`, ~1.1 s to
first byte, and **100 of 100 sampled packets start with the `0x47` sync byte**.
Well-formed transport stream.

§10 picks media_kit/libmpv over ExoPlayer *specifically* because panels emit
malformed TS that ExoPlayer rejects. This panel does not. That does not
invalidate the choice — one clean panel is not evidence about the population,
and libmpv still wins on container breadth and the Plex/SMB paths — but it does
mean **the tolerance argument is currently unevidenced**. Either test a second,
worse panel, or downgrade the claim in §10 to reflect what is actually known.

### 🔴 iOS App Transport Security will block this panel

The panel is HTTP-only (no `https_port`), and the redirect target is HTTP too.
**iOS ATS blocks cleartext HTTP by default**, so this provider simply will not
load on iOS unless the app declares an ATS exception
(`NSAllowsArbitraryLoads`), which Apple scrutinises at review and expects
justification for — and doing so weakens the security posture for *every*
connection, not just IPTV.

This is a new §11/§1 item that no section currently covers, and it is
awkwardly shaped: the justification for the exception is "users connect
arbitrary self-hosted servers, many of which are HTTP-only", which is true and
also draws attention to exactly the feature §8 is trying not to lead with.
Note that Plex's `*.plex.direct` and most NAS devices are HTTPS, so this
exception exists *mainly* for the Advanced-sources path. **Decide the position
before the iOS submission, not during it.**

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
