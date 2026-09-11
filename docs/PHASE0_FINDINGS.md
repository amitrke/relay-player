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

> **Recording rule — this repo is public.**
>
> Never write a real provider host, username, password, token, server
> identifier or LAN address into this file, into a test fixture, or into a
> commit message. Use `<panel-host>`, `<lan-ip>`, `<redacted>`.
>
> This is not only credential hygiene. §1 and §8.3 turn on the project not
> looking like it points at, curates, or is associated with any particular IPTV
> provider — naming one in a public repo undercuts the same primary-purpose
> argument that §8.3 refuses a provider directory to protect.
>
> Numbers, timings, response shapes and failure modes are the valuable part of
> a finding, and none of them require naming the source.

---

## Q1 — Does media_kit/libmpv tolerate real IPTV streams? (§10)

**Status:** 🟡 live Xtream playback confirmed working; more panels needed

**Result 2026-09-11 (a real Xtream panel, Tab 5):** ✅ libmpv plays this panel's
live `.ts` reliably.

| Channel | Stream id | Result |
|---|---|---|
| `US: GOLF CHANNEL` | 244978 | ✅ first frame **1824 ms**, 1280×720 |
| `US: GOLF CHANNEL` (replay) | 244978 | ✅ first frame **1856 ms** — consistent |
| `\|SE\| C MORE GOLF HD` | 244987 | ❌ no frame after 10 s |

API timings on the same run: `get_live_categories` 965 ms (466 categories),
`get_live_streams` **2317 ms** (15,951 streams, 5.3 MB).

### Dead channels are normal, and the UI has to say so

One of two channels tried simply did not respond. That is routine for IPTV
panels — listings outrun reality — but it is a **UX requirement, not a
curiosity**: a channel that never yields a frame must reach a clear "not
responding, try again" state rather than spinning forever. With
`max_connections: 1` (Q6) the app must also *release the connection* on that
timeout, or a dead channel burns the user's only slot.

Pick a timeout deliberately. 10 s was enough to distinguish the two cases here;
first frame on a working channel landed at ~1.8 s, so a 10 s ceiling has ample
headroom.

### What is still unevidenced

§10's central claim is that libmpv tolerates **malformed** TS where ExoPlayer
fails. This panel emits *clean* TS (Q6: 100/100 sync bytes), so it does not
test that claim at all — it only shows libmpv handles a well-formed stream,
which ExoPlayer would too. To actually settle Q1, either:

- test a second, worse panel, or
- accept that the tolerance argument is unproven and re-justify media_kit on
  the grounds that *are* evidenced here — one engine across Plex direct-play,
  Plex HLS transcode, SMB-via-bridge and IPTV, plus container breadth.

The second is a perfectly good argument. It is just a different one from what
§10 currently says.

### 🔴 The Android emulator cannot show video at all — do not test playback there

**Found 2026-09-11.** On the `Pixel_Tablet` AVD (API 34, x86_64), Plex direct
play decodes correctly and the position clock advances, but the picture stays
black. The cause is in the emulator, not the app:

```
media_kit: Emulator detected.
media_kit: Enforcing S/W rendering.
VideoOutput: onSurfaceAvailable            <- surface obtained, sized 1920x816
E EGL_emulation: eglCreateContext(1755): error 0x3004 (EGL_BAD_ATTRIBUTE)
```

media_kit gets its surface but cannot create a GL context to draw into, so
decoded frames have nowhere to go. This is a known upstream bug
([media-kit#1343](https://github.com/media-kit/media-kit/issues/1343),
[#462](https://github.com/media-kit/media-kit/issues/462),
[#1255](https://github.com/media-kit/media-kit/issues/1255)), reported as **not**
affecting real devices.

Ruled out by experiment, so nobody repeats them:

| Hypothesis | Test | Result |
|---|---|---|
| Missing Android video libs | `media_kit_libs_android_video` in lockfile | present — not the cause |
| Flutter's Impeller backend | Disabled via manifest `EnableImpeller=false` | **identical failure** — not the cause |
| media_kit's emulator heuristic | `enableHardwareAcceleration: true` | ineffective; that flag only sets `hwdec`, and S/W *decoding* still produces frames |
| Emulator using a software GL path | `hw.gpu.mode` `auto` → `host`, AVD restarted | **identical failure** — not the cause |

**Consequence for the workflow:** test video on Windows or a real Android
device. The emulator is fine for everything else, and remains useful for UI,
navigation and API work.

### 🟡 An advancing clock proves playback, but NOT a visible picture

A refinement of the instrumentation lesson below, which this bug found the hard
way. §Q1 concluded that "the clock moving is the only trustworthy signal" for
*is it playing* — and that is still right. But this failure has the position
advancing normally while nothing is on screen, because the failure is in the
**render** path rather than the decode path.

So the player's stall guard, which watches for the position to advance, cannot
catch a black picture and should not be expected to. Anything claiming to verify
"the user can see video" needs evidence from the render path — or a human eye.

### Still to test on this question

- [ ] `.m3u8` variant of a working channel (button present, not yet run)
- [ ] VOD `.mp4` playback and seeking
- [ ] A second panel, ideally a worse one
- [ ] Playback on a real Android device / Fire TV, not just desktop —
      **blocked on hardware; the emulator cannot answer this one**

**Decision — media_kit or better_player as primary?**

> _(record here — see "What is still unevidenced" above before deciding)_

---

## Q2 — Is `dart_plex` 0.1.2 viable? (§6)

**Status:** 🟡 direct play confirmed working; two package defects found and worked around; transcode lifecycle re-run pending

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
| `library.item()` + direct play by Part key | ✅ | 244 ms to header, position advances, 3 audio + 3 video tracks, correct duration |
| `decisionUniversal` | ⚠️ needs `hasMDE=1` | 400 without it. Probe passed an incomplete param set *and* the package omits `hasMDE` — both fixed |
| Playback of transcode URL | ⚠️ needs `hasMDE=1` | 400 was the server rejecting the URL the package builds. Workaround in place, re-run pending |
| `pingUniversal` — survives 60s+ | ⏳ re-run | The 404s were a symptom: no session existed because the transcode never started |
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

#### 🔴 BLOCKING finding — `universalVideoUrl` omits `hasMDE=1`, so transcode never works

**Status:** ✅ root-caused 2026-09-11 by bisection against PMS 1.43.3.

`dart_plex`'s `universalVideoUrl` builds a URL that **Plex rejects with a bare
`HTTP 400 Bad Request`**. The missing parameter is `hasMDE=1`, which tells the
server the client speaks the Media Decision Engine protocol. Modern PMS refuses
the universal transcode endpoint without it.

Bisected with curl against the real server — identical URL, one parameter apart:

| Request | Result |
|---|---|
| `start.m3u8?path=…&mediaIndex=0&partIndex=0&protocol=hls&…` | **400** |
| …plus full `X-Plex-*` client identification | **400** |
| …plus **`hasMDE=1`** | **200**, valid `#EXTM3U` master playlist |
| `decision?…&hasMDE=1` | **200**, `generalDecisionCode 1001` |

**The package contains no occurrence of the string `hasMDE` anywhere**, so
nothing it builds can drive the transcoder. This is not a wrong default like
the `createPin` issue — it is a feature that cannot work as shipped.

- **Workaround (in the probe now):** append `&hasMDE=1` to the returned URL and
  add `'hasMDE': '1'` to the decision params.
- **Weight for the Q2 decision:** this is the second defect found in the
  package's two most important flows, and the more serious one. Both were found
  within an hour of first use. That is a strong signal about how much of this
  package has been exercised against a real server. It does not force
  hand-rolling — the workaround is one string — but it means **every dart_plex
  call path must be verified against a real server before Phase 1 relies on
  it**, and the ~1 week hand-rolled fallback in §6 should stay costed and ready.

#### Transport is fine — the TLS hypothesis was wrong

The earlier guess that libmpv might be failing TLS against `*.plex.direct` was
**wrong**, and worth recording so nobody re-opens it:

| Check | Result |
|---|---|
| DNS `<lan-ip-dashed>.<hash>.plex.direct` | resolves to `<lan-ip>` |
| HTTPS `/identity` | **200**, TLS handshake 146 ms |
| Plain-HTTP LAN `/identity` | **200**, 63 ms |
| Direct file via Part key, `Range: 0-65535` | **206**, `video/mp4`, valid `ftyp`, **81 ms TTFB** |

Every failure was the server returning 400 to a malformed request. The 109 ms
"failure" was not a timeout — it was a fast, correct rejection.

#### Probe bug — "direct play" was not direct play

Step 3.5 originally called `universalVideoUrl(directPlay: true)`, which still
goes through `/video/:/transcode/universal/`. The server said so itself once
the decision call worked:

> `directPlayDecisionText: App cannot direct play this item. Direct play is
> disabled.`

**Real direct play is the media Part key** — `/library/parts/{id}/{ts}/file.mp4`
— a plain file with byte ranges, which is what §6 describes and what media_kit
treats like any progressive source. Step 3.5 now fetches the item, walks
`media → parts`, and streams that. It is also the correct isolation test, since
it touches no transcoder machinery at all.

#### ✅ RESOLVED — Plex direct play works; the probe was hiding it

**Status:** ✅ answered 2026-09-11. Direct play is fine.

Instrumenting `position` settled it immediately:

```
position samples 500, 1000, 1501, 2001, 2502, 3003 ms
playing=true  buffering=false  duration=5781s  audioTracks=3  videoTracks=3
ACTUALLY PLAYING — position advanced 2503 ms over 3s (header at 244ms)
```

The clock advances in real time, three audio and three video tracks decode, and
`duration=5781s` is 96 minutes — correct for the test film. **Transport, TLS and
direct play are all working.** The TLS hypothesis is dead; no CA-bundle work is
needed.

Nothing was visible on screen for two compounding reasons, both in the probe:

1. It called `_player.stop()` the instant verification passed, so playback
   lasted exactly the three-second sampling window.
2. Those three seconds were the **black opening leader of a 1957 film**. Correct
   playback that looked precisely like a failure.

Fixed: on success the probe now seeks to 15% (past the titles) and leaves
playback running until "Stop session", and the video area is larger.

**The lesson is about instrumentation, not Plex.** Two probe bugs in a row
produced confident, wrong conclusions — "OK (141 ms)" before an async error, and
"PLAYING" from a parsed header. Both were cases of measuring something
*adjacent* to the thing that mattered. In Phase 1, "is it playing?" must mean
the position advanced, and any success message should be traceable to evidence
that specific.

#### (superseded) Earlier hypothesis — libmpv TLS against `*.plex.direct`

**Status:** 🟡 instrumented 2026-09-11, awaiting a re-run.

Direct play via the Part key reported success and showed **a black picture**.
The probe was wrong, not the report: it treated `videoParams` (libmpv having
parsed the stream header and learned the dimensions) as proof of playback.
**It is not.** libmpv populates that after reading the header even when
decoding then stalls.

`_openAndAwait` now samples `Player.state.position` six times over three
seconds and requires it to actually advance, logging the samples plus
`playing`, `buffering`, `duration` and track counts. "Opened" and "playing"
are now distinguishable in the transcript.

**Carry this into Phase 1:** neither `await player.open(...)` returning nor
`videoParams` arriving means anything played. The clock moving is the only
trustworthy signal, and any "is it playing?" check in the real app needs to use
it too.

**Ruled out by the result above.** Kept for the record, and because the
bundled-binary observations remain relevant to §10.

curl reaches this server over HTTPS without difficulty, but curl uses the
Windows certificate store and libmpv ships its own TLS stack. Inspecting the
bundled binary:

| Property | Value |
|---|---|
| `libmpv-2.dll` | 28 MB, **dated 2023-09-24** — over two years old |
| TLS backend | **GnuTLS** (no OpenSSL strings present) |
| Options present | `tls-ca-file`, `tls-verify` |
| CA bundle shipped with the app | **none** |

GnuTLS on Windows does not read the OS certificate store; it expects a CA file
at a compile-time path that does not exist on Windows. That is a plausible
mechanism for a silent stall — though not proven, since `schannel` strings are
also present (ffmpeg may fall back to it) and mpv's `tls-verify` has
historically defaulted to off.

**Step 3.5 now settles it automatically.** If HTTPS does not progress, the probe
retries the *identical* file over `http://<lan-ip>:32400` and reports:

- plain HTTP plays, HTTPS does not → **libmpv TLS**. That affects every Plex
  stream, is a media_kit/libmpv issue rather than a `dart_plex` one, and bears
  on §10. Fixes: ship a CA bundle, set `tls-ca-file`, or prefer the plain-HTTP
  LAN connection for local servers.
- neither plays → not TLS; look at byte-range serving and the file itself.

**Incidental:** the bundled libmpv being two years stale is worth noting on its
own for §10 — it bounds codec support and carries whatever CVEs 2023 had.

#### Open — does transcode playback actually run end to end?

**Status:** 🟡 workaround in place, needs a re-run.

Two candidate causes, and the run so far cannot tell them apart:

1. **The transcoder** — plausible, since the decision call had failed, so no
   session had been negotiated.
2. **The transport** — `bestConnection()` selected
   `https://<lan-ip-dashed>.<hash>.plex.direct:32400`. That hostname resolves to
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

**Status:** ✅ **answered 2026-09-11. The bridge is needed, and it works.**

### Step 1 — native `smb://` does not work

Predicted outcome, but not for the predicted reason. libmpv did not report a
missing `libsmbclient`; it refused the URL outright:

```
player error: Refusing to load potentially unsafe URL from a playlist.
player error: Use the --load-unsafe-playlists option to load it anyway.
```

So the blocker is an mpv safety policy, not a missing protocol handler. In
principle `--load-unsafe-playlists` might get past it — **do not do this.** It
relaxes a safety check globally for every source the app ever opens, including
untrusted IPTV playlists, to avoid work the bridge does properly. Treat native
`smb://` as unavailable and move on.

### Step 2 — `smb_connect` 0.0.9 works, including random access

Despite the version number, every operation succeeded first try:

| Operation | Result | Timing |
|---|---|---|
| `connectAuth` | ✅ | 177 ms |
| `listShares` | ✅ 17 shares | 124 ms |
| `listFiles /media` | ✅ 24 entries | 134 ms |
| **Random-access read** (seek to 50%, read 64 KB) | ✅ full 65,536 bytes from offset 121,929,919 | 142 ms |

The random-access row is the make-or-break one — without working seeks the
bridge could only stream start-to-finish and scrubbing would be impossible.

§7.2's scepticism about this package is now **partly discharged**: the happy
path is solid. What remains untested is failure behaviour — see below.

### Step 3 — the loopback bridge works, and libmpv seeks through it

```
bridge listening on http://127.0.0.1:53278/stream
media_kit open via bridge OK (54 ms)
  bridge: bytes=0-           -> serving 0-243859838 (243859839 bytes)
  bridge: bytes=243843788-   -> serving 243843788-243859838 (16051 bytes)
  bridge: bytes=5963-        -> serving 5963-243859838 (243853876 bytes)
```

**Three distinct ranges, and the middle one is the proof.** libmpv jumped to
the last 16 KB of the file — that is it reading the MKV/MP4 index at the end of
the container — then came back to 5,963 to start playing. A bridge that ignored
`Range` would have looked fine on the first request and failed exactly here.
Video played with subtitles rendering correctly.

**Conclusion:** §7.2's design is correct as written. Implement the
`smb_connect` + `shelf` loopback bridge, and it becomes reusable infrastructure
for FTP/WebDAV later as §7.2 anticipates.

### Still untested — failure behaviour, not the happy path

The remaining risk in `smb_connect` is not whether it reads a file, but what it
does when the network misbehaves. §7.2 calls the connection lifecycle "real
state to manage". Untested:

- [ ] NAS goes away mid-playback (unplug, or sleep the drive)
- [ ] Wi-Fi drop and reconnect
- [ ] Whether a dropped connection surfaces an error or hangs
- [ ] Long playback — does the connection survive a full episode?

These are Phase 2 concerns rather than Phase 0 blockers: they change how much
error handling Phase 2 needs, not whether the design is right.

---

## Q6 — Xtream panel reality check (§4)

**Status:** ✅ answered 2026-09-11 against a real panel (a real Xtream panel).

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
that requirement to the Xtream client itself**. **Addressed by §4.1
(category filtering), added 2026-09-11**: fetch categories only, let the user
select, then fetch streams per selected category — so the 26 MB is never
transferred at all. Decoding 26 MB of JSON into Dart objects on the main isolate will
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
Location: http://<different-host>:8080/live/play/<opaque-token>/<id>
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

**Status:** ✅ answered 2026-09-11. Both parsers work. One result contradicts
§5's prescription and is the most useful finding here.

### Measurements

**M3U** (`get.php?type=m3u_plus`):

| Metric | Value |
|---|---|
| Download | **40.07 MB** (42,011,924 bytes) in 7,079 ms |
| Entries parsed | **167,862** |
| Parse on **main isolate** | **422 ms** |
| Parse via **`compute()`** | **1,033 ms** |
| Missing `tvg-id` | **166,402 / 167,862 (99.1%)** |
| Missing `group-title` | 9 / 167,862 (0.005%) |
| Missing `tvg-logo` | 72,878 |
| Distinct groups | 706 |

**XMLTV** (`xmltv.php`):

| Metric | Value |
|---|---|
| Download | 0.24 MB in 1,406 ms |
| Parse on main isolate | 57 ms |
| Parse via `compute()` | 37 ms |
| Channels / programmes | **1,544 / 0** |

### 🔴 `compute()` made the M3U parse 2.4× *slower* — §5's advice needs refining

This is the finding worth keeping. §5 (and my own note in §11) says to parse in
a background isolate. Measured, naive `compute()` is **worse**: 1,033 ms versus
422 ms on the main isolate.

The reason is that `compute()` spawns an isolate and **copies data across the
boundary** — a 40 MB string in, and a 167,862-element list of objects back.
That copy dominates; the parse itself is comparatively cheap.

**Both numbers are bad, for different reasons:**

- 422 ms on the main isolate is roughly **25 dropped frames** at 60 Hz — a
  visible, janky freeze. So "just parse on the main isolate" is not the answer
  either.
- 1,033 ms in an isolate is worse in total, even though the UI stays smooth.

**What the architecture should actually say:** the goal is not "use an isolate",
it is **don't move bulk data across an isolate boundary**. Concretely:

- Stream the download *into* a long-lived isolate rather than materialising a
  40 MB string and handing it over.
- Parse there and send back only what the UI needs — compact records, or better,
  write straight into the on-disk cache from the isolate and return a count.
- Never `compute()` a large payload. `compute()` suits CPU-heavy work on small
  inputs, which is the opposite of this shape.

§5 and §11 should both be amended: the current wording would lead a developer
to the slower implementation and call it the fix.

*(Note the XMLTV row shows the opposite — `compute()` was faster, 37 ms vs
57 ms. That file is 0.24 MB. The crossover is about payload size, which is
exactly the point.)*

### 🔴 99.1% of M3U entries have no `tvg-id`

Worse than the API's 91% (Q6), on the same provider. Combined with an XMLTV
export containing **zero programmes**, the EPG is not merely sparse for this
provider — it cannot function at all. §12 screen 7 needs an honest empty state.

`group-title`, by contrast, is present on all but 9 of 167,862 entries, so
**category navigation is viable even though the guide is not**.

### 🟡 The M3U is the whole catalogue, not just live

167,862 entries against the API's 15,951 live streams. `m3u_plus` includes VOD
and series episodes too. Two consequences: the 40 MB figure is what a real
import costs, and §5's "treat M3U as Live only" default would hide the large
majority of what this playlist contains.

90 of the 706 groups look like VOD/series. §5 says not to guess, and that
remains right — but "Live only" is clearly the wrong default *for this
playlist*, so the UI needs to let the user decide rather than pick for them.

### 🔴 Store-policy hazard: group names are streaming-service brands

The largest groups are, in order: **NETFLIX (19,611)**, **NETFLIX (MULTI
LANGUAGE) (8,720)**, `PAK: GEO ENTERTAINMENT`, `PAK: HUM TV`, `GERMANY MOVIES`,
… and **AMAZON PRIME (2,491)**.

These are user-supplied strings, so rendering them is no different from any
other player showing a playlist's own labels — that is not the risk. The risk
is §1.6: *"Don't use real broadcaster/channel names, logos, or sports branding
anywhere in your own marketing, screenshots, or app icon."*

**A single App Store or Play screenshot showing a category list reading
"NETFLIX" would be exactly the trigger §1 warns about.** This is a concrete,
easily-made mistake that no amount of careful architecture prevents.

**Action:** add to the §13 Phase 6 store checklist — every screenshot must come
from Plex, local files or SMB content, never from an IPTV playlist, and the
Advanced-sources UI must never appear in store assets at all. Worth writing
down now rather than discovering it at submission.

## Q5 — Platform questions (Android device required)

Not answerable on desktop. Deferred from the probes above but still Phase 0.

- [ ] **SAF persisted folder permission survives app restart AND device
      reboot** (§15 calls this out specifically — the reboot case is the one
      that fails)
- [ ] `MediaStore` scan returns expected video without `MANAGE_EXTERNAL_STORAGE`
      (§7.1 — the Play-policy-compliant path)
- [ ] Hardware decode actually engages on device (compare CPU use vs desktop)
- [x] **App size impact of bundling libmpv — measured 2026-09-11.**

      | Build | Size |
      |---|---|
      | `arm64-v8a` release | **30.8 MB** |
      | `armeabi-v7a` release | 27.8 MB |
      | `x86_64` release | 35.5 MB |
      | universal release | 89.9 MB |

      So libmpv costs roughly **25 MB per ABI**, and the universal APK is 3×
      an arm64 one purely from carrying three copies. Ship split APKs or an
      AAB; a 90 MB universal binary is a bad first impression and, on a Fire
      TV stick (§11), a real storage cost.

      Not alarming for §10's engine choice — a media player that bundles its
      own decoder pays this, and 31 MB is unremarkable for the category.

---

## Incidental findings

Things learned during scaffolding that aren't among the four questions:

- **`flutter_secure_storage` does not build on Windows** without Visual Studio's
  C++ ATL component (`atlstr.h` missing). It was removed from `pubspec.yaml`
  because Phase 0 doesn't use it, and re-added in Phase 1 where §3 requires it
  for the Plex token.

  **Resolved 2026-09-11 by installing ATL**, not by dropping the dependency.
  Two corrections to the original note, both of which cost time to rediscover:

  - The component is **not** the "v143 build tools" one. This machine runs
    **Visual Studio Build Tools 2019 (v142, MSVC 14.29.30133)**, so the fix is
    `Microsoft.VisualStudio.Component.VC.ATL` applied to the *2019 BuildTools*
    install path. Looking for a VS 2022 component finds nothing.
  - `vs_installer.exe modify --quiet` (or `--passive`) **fails with exit code
    5007 when not elevated**, and the failure does not say so on stdout — only
    the log in `%TEMP%\dd_installer_*.log` names the cause: *"Commands with
    --quiet or --passive should be run elevated from the beginning."* Run it
    elevated from the start.

  Upgrading is not an alternative: `flutter_secure_storage_windows` 4.2.2 is
  current, and its `windows/CMakeLists.txt` still compiles a C++ plugin that
  includes `atlstr.h` despite the 3.0.0 changelog claiming a migration to the
  `win32` package.

  The standing point still holds for anyone setting up a fresh machine, and it
  is the concrete cost behind §14's "media_kit supports desktop too, which costs
  nothing now": desktop support has a toolchain cost, just a one-time one.
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
