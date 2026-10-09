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
| ✅ | Video renders at all | **Verified 2026-09-21** on a Chromecast with Google TV (Android TV OS 14), playing from Plex. The first time a frame has been seen on real Android hardware; the emulator's `EGL_BAD_ATTRIBUTE` failure does not occur there, as upstream said. **Also verified 2026-09-22 on a Pixel 10a (Android 17)**, arm64 release build, Plex direct play, decoded frames in both portrait and landscape while capturing the store screenshots. Still not seen on a tablet |
| ✅ | Plex direct play on device | **Verified 2026-09-21** on the same Chromecast. Which APK was installed was not recorded; the ABI row in §6 says it has to be armeabi-v7a or universal on this device |
| ⬜ | **Panel VOD playback** | The `/movie/` URL and its container extension have *never been exercised*. Extensions vary per title (mkv as often as mp4) and are not recoverable from the panel afterwards — most likely place for a real failure |
| ⬜ | **Panel series episode playback** | Same, for the `/series/` path |
| ⬜ | Live channel playback | §4's `max_connections: 1` makes the failure mode look like a flaky provider rather than a client bug |
| ⬜ | **Stop-before-open when zapping** | The player stops before opening, never the reverse. On a one-connection line the natural ordering fails confusingly — this is the thing that behaviour exists to prevent |
| ⬜ | **Dead channel releases the connection** | A channel that never yields a frame must free the slot on timeout, or it burns the user's only connection until the panel times it out server-side |
| ⬜ | Resume actually seeks on open | The stored position is demonstrably correct, but the only observation so far ("117 → 116 min left") is equally consistent with restarting from zero |
| ⬜ | Hardware decode engages | Q5. Compare CPU against desktop |
| ⬜ | **Audio focus and backgrounding** (#17, added 2026-09-22) | Built to the table in architecture.md §10, which `playback_focus_test.dart` pins row by row against a fake player. Whether Android delivers the events is the open part. On the Pixel: music from another app pauses ours and ours stays paused; a phone call pauses and resumes when it ends; a notification ducks without pausing; unplugging headphones pauses; home, recents and screen-off pause, and playback stays paused on return. For a live channel, each of those stops the stream and offers *Rejoin*, and the panel should show the connection freed. Also check that *Rejoin* takes focus on a TV |
| ⬜ | **Library sort and source labels** (added 2026-09-22) | Sort by title, recently added or year, remembered across restarts; *Plex* / *IPTV* labels only when a grid mixes both. Rules pinned by `library_sort_test.dart`. Unchecked: whether Plex's `addedAt` gives the order people expect, whether a real panel sends `added` for films and `last_modified` for series at all (read from the Xtream API's usual shape, not observed), and the sort sheet with a D-pad |
| ⬜ | **Live TV grouped by category** (added 2026-09-28). Channels now sit under Favourites and each chosen category, with All as the old flat list: chips on a phone, a category column on a TV (architecture.md §4.1). Pinned by `channel_groups_test.dart` and `live_tv_groups_test.dart` against fake channels, including Right from the category column reaching a channel; not yet run against a real panel on any device. Check: on the phone, an existing line shows its real category names (fetched once, since it was saved before names were stored) and not "Category 1"; reopening and saving the picker keeps them; on the Chromecast, Up/Down walks the column with a visible ring, OK shows that category, Right enters the channels and Left comes back, and Left from the column still reaches the rail; searching while a category is chosen finds channels in other categories; a large category scrolls smoothly on the Chromecast |
| ⬜ | **Advanced sources account row on a phone** (added 2026-09-28). Found on an Android phone: under Settings → Advanced sources the line's name, which defaults to the server address, ran one character per line down the screen, because it shared one row with the Live TV / Movies / Series buttons and the remove button and was left about one glyph wide. Now the name and counts take the full width on one line and the buttons sit on a second line. Pinned at 390 and 320 px (the latter at 2x text) by `xtream_accounts_pane_test.dart`, whose control against the old layout fails all three cases; not yet re-seen on the phone. Check there, and that the three buttons are reachable with the D-pad on the TV |
| ⬜ | **Continue watching split between Movies and Series** (added 2026-09-28). Found on the Chromecast: a show in progress appeared in the row above Movies. Now films resume above Movies and episodes above Series (architecture.md §12). Rules pinned by `watch_state_test.dart`; not yet seen in the app. Check: a half-watched Plex episode appears above Series and not Movies; a half-watched film the other way round; an episode that was already in the row before this build moves to Series, either at once (if Plex's On Deck lists it) or after it is played again; the Series row is reachable with the D-pad |
| ⬜ | **Plex watch state and On Deck** (added 2026-09-22) | Needs a real account with history. Check: films and episodes watched in another Plex app show a tick; one half-watched there shows a bar and appears in Continue watching; a show part-way through offers its next episode as "Up next"; finishing something here drops it from the row straight away; closing a Plex tile keeps it closed until it is watched further. Also whether On Deck returns anything at all (architecture.md §6 explains why the hub endpoint was avoided). Rules pinned by `watch_state_test.dart`; the fixtures are shaped from the API, not captured from a server |
| ⬜ | **Mark watched / unwatched, and "Unwatched only"** (added 2026-09-23) | Long-press a Plex poster or episode row, or hold the centre button on a remote, for the sheet. Check: the Plex app agrees afterwards; marking a whole show reaches every episode; marking works on a server *shared with you*, not only your own; a held centre button on the Chromecast opens the sheet without first playing the title (the rule assumes the remote auto-repeats a held key, as Android TV remotes do); "Unwatched only" on Movies hides what the ticks say is watched. Rules pinned by `watch_actions_test.dart` against a fake Plex |
| ⬜ | **Audio and subtitle tracks, and the Playback and Subtitles settings** (added 2026-09-23) | Needs a file with several audio tracks and embedded subtitles (an MKV is the usual case). Check: the picker button appears only when there is a choice; switching audio and subtitles works mid-playback; with a preferred language set, a new file opens on it; "Show subtitles" off opens with none; subtitle size changes the text; the skip length changes the buttons and the remote's fast-forward. Unknown: how media_kit shows picture-based subtitles (PGS, VobSub) and whether size affects them; whether Plex direct play exposes Plex's *sidecar* subtitle files at all (they are separate streams, not in the file, so probably not); how real files tag languages beyond the forms `playback_prefs_test.dart` covers |

## 1a. Verified on a phone, 2026-09-22

Found while capturing store screenshots on a Pixel 10a (Android 17), and worth
separating from §1 because neither needed a TV.

| # | What | Result |
|---|---|---|
| ✅ | Plex playback on a phone | Decoded frames in portrait and landscape, arm64 release build, direct play |
| ✅ | No credential material in the Hive box (§15) | **Failed first, then fixed.** `settings.hive` held a live `X-Plex-Token` per continue-watching row; see STORE_LISTING.md. Re-verified by pulling the box: 3,406 bytes with nine copies, 252 bytes with none |
| ✅ | Continue-watching tile across text scales | Overflowed its row at every scale above 1.0, clipped silently in release. Fixed by letting the poster absorb the remainder; re-checked at 1.0, 1.5 and 2.0 |

**The debug build is the only one that tells you.** A `RenderFlex` overflow
draws its banner in debug and clips without a word in release, so the tile had
been cutting off "5 min left" for anyone with larger text and no screenshot
would have shown it. Every prior capture here was a release build, which is
why this took until now to see.

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
| ⬜ | **The Plex link flow end to end** (issue #3 fix). The screen now leaves for the library on the transition into `PlexStage.ready`, with a snackbar naming the server. Only the router behaviour behind it is under test — linking needs a real Plex account, so the navigation itself has never run. Check both branches: one server on the account (auto-connect) and several (server picker). Since 2026-09-22 (#5) the picker groups *Your servers* above *Shared with you*, sorts online first then by name, dims offline servers, leaves out servers already connected, and shows progress on the tapped row only; `plex_link_screen_test.dart` pins the grouping and order but not a real account's response |
| ⬜ | **The 10s `plexSectionsProvider` timeout has still never fired.** It was added for a server that hangs, but the hang turned out to be connection selection, now fixed — so the case that motivated it no longer reproduces. It remains the guard for a server that goes away *after* connecting (NAS asleep, friend's server offline). Needs a server that hangs rather than refuses |
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
| ⬜ | **Live channel freezes mid-watch, then recovers** | Written 2026-10-06 (§10 "Live reconnect"): 10s of no position movement stops and reopens, 3 tries at 2/4/6s. Untested. Needs a real freeze, e.g. Wi-Fi off for 15s mid-channel, then on. Check the spinner shows, picture returns, and that a one-connection line is not refused on reopen |

## 6. Not started at all

| # | What |
|---|---|
| 🟡 | iOS — built and run on the simulator 2026-09-23 (§6a below); never on a real iPhone or iPad |
| ⬜ | Android TV / Fire TV — no leanback tree yet (Phase 4) |
| 🟡 | **D-pad navigation — fixed on the emulator, unverified on the Chromecast.** Was: a D-pad press scrolled the page instead of moving focus, library content could not be selected, and the rail could not be reached at all. Five causes now, all in shipped code rather than missing Phase 4 work; all five fixed (four on 2026-09-11, a fifth on 2026-09-12) and verified by driving the Google TV emulator with `adb shell input keyevent` — Left reaches the rail, Down moves within it with a visible ring, the centre button opens Settings, Right returns to the page, and going Settings → Sources → back to Library no longer strands focus on a hidden branch. See architecture.md §11. **Still to do on real hardware**, since the emulator's remote is synthetic: the same walk on the Chromecast with Google TV |
| ✅ | **Focus was invisible on Material-drawn surfaces — fixed 2026-09-12 for the Settings sub-list.** The rail's own defect (§11 defect 3) and the Settings sub-list (Sources, Appearance, Playback…) shared the same cause; both now go through `RelayTappable`. Any other Material-drawn surface not yet checked on a TV should still be assumed guilty until proven otherwise |
| ✅ | **On-screen keyboard with a D-pad on the Chromecast** (added 2026-09-28; **typing confirmed on the Chromecast the same day**, build 1.0.4 (10), by the account owner. The same test found that focus could not then reach *Verify and add*; see the next row). Found there: the keyboard appeared over a text field but the D-pad moved focus behind it, so nothing could be typed. Engine bug flutter/flutter#177360; worked around with `TvImeProxyView` (architecture.md §11). The Google TV emulator does not reproduce the bug, so it only showed the workaround breaks nothing there. Check on the Chromecast: the D-pad moves across the keys and OK types; *Next* on the Xtream form moves to the following field with the keyboard still up; Back closes the keyboard and a second Back leaves the screen; the D-pad still moves around the app once the keyboard is closed; no keyboard pops up on its own at launch or on returning to the app; the Search, Live TV filter and SMB fields behave the same. Voice input from the remote's mic, if the keyboard offers it, is worth one try |
| ⬜ | **Add-line form with a remote, end to end** (added 2026-09-28). After typing, *Done* on the last field should land on *Verify and add* with a white ring; with the keyboard closed, Up and Down should move between fields and to the button; after a failed check (a wrong address) the ring should still be on the button; Back with anything typed should ask, with *Keep editing* focused. All four seen on the Google TV emulator with made-up text (architecture.md §11); the Chromecast is the real check. Also worth one pass: Up and Down out of the Search and Live TV filter fields, which got the same traversal fix |
| ⬜ | **Install the right ABI on Google TV.** A Chromecast with Google TV (Android TV OS 14) refused `app-arm64-v8a-release.apk` with "app isn't compatible with your device": it runs a **32-bit userspace** on a 64-bit chip, so it needs `app-armeabi-v7a-release.apk` or the universal APK. Nothing else in the manifest gates it — minSdk is 24, no feature is required, all screen sizes are supported — so on Android TV, "not compatible" means the ABI. Confirm with `adb shell getprop ro.product.cpu.abi` |
| ⬜ | **The banner in a real launcher row.** The system resolves it — `cmd package resolve-activity -c LEANBACK_LAUNCHER` returns our activity with `nonLocalizedLabel=Relay Player` and a bound `banner=` resource, and the package appears in a `LEANBACK_LAUNCHER` query — but the Google TV emulator image gates its home screen behind Google account setup, so the row itself has never been seen. Check on the Chromecast: whether sideloaded apps appear in the apps row at all, and whether the banner reads at the launcher's own scaling |
| ⬜ | The banner at real launcher scale — it has only been checked as an image file, centre-line aligned, never on a panel at viewing distance |
| ⬜ | The §15 device matrix — one Android TV box, one Fire TV, two phones, two iOS devices |
| ⬜ | **Settings → About on a real TV and phone** (added 2026-09-21). Tested only as a widget at TV size. Check that the version reads the tag rather than `0.0.0` on a tagged Play build, that the D-pad reaches the licences button, and that Flutter's licence page (Material list tiles, never checked on a remote) can be scrolled and left with Back. The phone layout's About has not been rendered by any test |
| ⬜ | **Player controls on a remote** (#10, added 2026-09-22). Rewritten: the chrome auto-hides after 4 s of playback, the first D-pad press only wakes it, the seek bar steps 10 s per press (30 s, then 60 s while held) and seeks once on release, Up and Down leave the bar, ±10 s buttons, media keys, and a focus ring on every control. The rules are pinned by `player_controls_test.dart` against a fake transport, and nothing else: the new chrome has not run on any device or on Windows. Check on the Chromecast: that the waking press is not also acted on, that a held Right accelerates at a usable rate with the real repeat rate (the step table assumes about 20 Hz), that the remote's Back still leaves the player with the chrome hidden, and whether its transport keys arrive as `mediaFastForward` / `mediaRewind` at all. On a phone: tap toggles the chrome and a drag on the bar seeks on release |
| ⬜ | **Library chrome folding on a TV** (added 2026-10-08). Reported: with a continue-watching row showing, Movies and Series left less than two rows of posters on the 540 dp screen. Now the Library title, tab strip and continue-watching row fold away once focus is on poster row 1 or lower, and return on row 0; the shell rail is an icon-only 64 dp strip that opens *over* the content (no reflow) while the remote is on it. The "Library" heading is gone on every form factor; sort and count sit on the tab row (phone: sort only). **Seen on the Google TV emulator 2026-10-08**: Down from row 0 folds the header and shows two full rows plus a third, Up to row 0 restores it, Left opens the rail over the content with labels and a ring, Right returns to the grid. Not seen: a phone or tablet render of the new tab row, or the Series tab. Real remote still to check: Down from the first row folds smoothly and the focused poster stays fully on screen; Up back to row 0 restores the header and a further Up reaches the tabs and the continue row; Left reaches the rail, which opens with labels and a ring; Right returns to the same poster; switching tabs un-folds. Open question: whether folding the tab strip too is right, or only the title and continue row |
| 🟡 | **Exit confirmation on Back** (added 2026-10-08). Back at the bottom of the stack, from any shell tab, now asks "Exit Subnext Player?" with *Stay* focused instead of closing the app (`HomeShell`, Android only). Seen on the Google TV emulator: the dialog appears, a second Back dismisses it and stays in the app, *Exit* returns to the launcher. Not seen: a real remote, or a phone with gesture navigation (predictive back), where the dialog may need a separate look |
| 🟡 | **Search filters and panel search** (added 2026-10-08). Results now say Movie or Series, and Type / Source / Year / Language chips narrow them; panels are searched too. Seen on the Google TV emulator against a Plex library: the labels, the chips, the Type sheet, applying *Series* and *Clear*. **Not seen:** a panel's titles in the results (searching `the` showed Plex only), the Source and Language choosers, a real remote, a phone. Language is guessed from panel category names and has never run against a real panel's categories. Check it against a panel whose categories carry a language prefix, and note what its names actually look like |
| 🟡 | **TMDB enrichment** (added 2026-10-08). Settings → Metadata takes a TMDB key; with one, search results gain Genre, Rating and Original language chips. Seen on the Google TV emulator: the pane, and a made-up key being rejected by the real TMDB (so the network path and the error message work). **Seen with a real key on the emulator, 2026-10-08:** the key saves, Genre, Rating and Original language chips appear a few seconds after the results, and searching `man` then filtering to Horror returned only real horror films (Friday the 13th, Hellboy, Hollow Man 2, Ice Cream Man from both Plex and a panel) with none of the unrelated Plex course videos in the same result set. One query only. **Still to check:** how many of a panel's titles match overall, whether any match wrongly, Rating and Original language applied, that Remove key clears the chips, and that a panel title with its year inside ("Ice Cream Man (2026)") shows that year on the tile, which it does not yet. Also unchecked: typing a key with a remote on a real TV |
| 🟡 | **Search respects hidden libraries** (added 2026-10-08). Seen on the Google TV emulator: with a course library set to Hidden in Settings → Sources, searching `man` no longer returns its items (they filled the second row before), only films. Not seen: a server with several visible libraries of one type, a very large library (the per-library title filter caps at 20 hits each), and ranking on a real remote. Searching is now "contains", so short queries match inside words |
| 🟡 | **"Because you watched" suggestions** (added 2026-10-09). Seen on the Google TV emulator with a real TMDB key: 12 Angry Men gave Juror #2, Alien: Romulus gave Alien Covenant, Alien and Aliens, all titles in the library. Not seen: a seed from this device's own history (the emulator's history was empty, so every seed came from Plex's watch state), a panel title among the suggestions, a phone, a remote scrolling a row, or how slowly the rows appear on a large library (they arrive after TMDB and the library both answer, and the plain prompt shows until then). Series are never seeds yet |
| 🟡 | **AI provider and Ask AI** (added 2026-10-09). Seen on the Google TV emulator against a **mock** OpenAI-format server on the host (so no model judged anything): Settings → AI features, the Other preset, Test and save (the mock saw the app's request), the local-provider path that skips consent, the Ask AI chip appearing for "alien films" where ordinary search found nothing, and the picks resolving to the Alien films. **Then seen with a real OpenRouter key, 2026-10-09, model `openrouter/free`:** Test and save accepted it, the consent dialog appeared and was accepted (the row reads "Allowed on 2026-10-09"), and "scary movies with space aliens" returned twelve picks, mostly the Alien and Predator films, with a few weaker ones (Alita, Aliens in the Attic). **The first identical attempt returned no valid picks and was not logged**, so a reply the app cannot use does happen: that model id is an automatic router that picks a different free model per request, so quality and format will vary. Still to check: a fixed model for consistency, the error text on a 401, 402 and 429, and how a free tier copes with the ~24 KB list over many searches. Also unchecked: typing a key with a remote on a TV, and the phone layout of the pane |
| 🟡 | **AI recommendations** (added 2026-10-09). The *What should I watch?* button leads the empty Search screen once a provider is set up (seen on the Google TV emulator, naming OpenRouter). The prompt, the unwatched-only list and the parsing are unit tested. Since changed (same day): once allowed, picks are **prepared in the background** shortly after launch and kept, so Search shows them at once. The controller is covered by unit tests (cached picks shown first, nothing sent when nothing changed, a failure not retried, nothing without consent, *Again* differing). **Seen on the emulator with a real OpenRouter key (2026-10-09):** the background request after launch produced six picks (10 Cloverfield Lane, Alien, Aliens, 1917, Captain America: Civil War, Dune: Part Two), and 14 seconds after a relaunch Search showed the same picks at once with no "Updating", i.e. from the cache. Getting there needed a fix: the first background attempts failed because the router chose a reasoning model that spent its reply budget thinking (see architecture.md section 12). **Not seen:** the consent dialog wording (the user had already allowed it), the "Updating" state, a refresh after watching something new, or a fixed model rather than the `openrouter/free` router. **That open problem (the library not being cached, so a slow source's items could be missing for the whole session: 982 against 1124 items on consecutive launches) was fixed the same day; see the library cache row.** Check on the emulator with a real key: allow it, relaunch, and open Search after about ten seconds; watch a film and relaunch to see it refresh; and confirm a relaunch with nothing new makes no request (the provider's own usage page is the control)|
| 🟡 | **Library cache** (added 2026-10-09). Each tab's library is kept between launches and refreshed in the background. Seen on the Google TV emulator: after a relaunch the full 825-movie Movies tab was on screen within about five seconds, and Plex and IPTV posters, the Continue watching row and the rest filled in afterwards. The cache file was pulled off the device and held **no `X-Plex-Token` and no transcode URL**, only unsigned `/library/metadata/...` paths. The loader is unit tested (kept shown first, a failed or hung source keeping its kept answer, an answer for other categories refused, an empty fresh answer replacing a kept one). **Not seen:** a source that really times out on a relaunch (the case it exists for; only forced in tests), a panel's cached catalogue, the Series tab, a phone, how the first launch after an update behaves on a very slow network, or whether watching something is reflected before the next refresh. Also unchecked: that Plex posters sign correctly when the server is not yet connected at launch (they showed blank for a few seconds then loaded, which is consistent with either slow images or a null URL until the refresh)|
| 🟡 | **Cached data stays bounded** (added 2026-10-09). Settings → Privacy and data → *Clear cached data* (built that day; the section had been hidden since 2026-09-22 and now has this one real control, with the fake crash-report switch still out). Seen on the Google TV emulator: pressing it took the library cache from 472 KB to 0 and the TMDB cache from 48 KB to 0 with settings intact, the library then reloaded to 825 movies and the cache refilled, and the settings file compacted from 3074 to 1839 bytes at launch. Unit tested: the 30 day limit (a stale entry is neither shown nor used as a fallback, a day-old one is), pruning, deleting one source's entries by prefix, and signing out clearing every Plex entry. **Not seen:** removing a real server or panel deleting its entry (only the key matching is tested), pruning of an entry that is really 30 days old on a device, how big the files get over weeks, or the button on a phone or with a remote|
| 🟡 | **Category picker: groups, and channels inside a category** (added 2026-10-09). Seen on the Google TV emulator against a real panel: Live TV opens on groups with counts (CineMania 37, VIBE 30, 24/7 21, France 11, ... USA 11 with "3 chosen") and about seven rows fit where three did; a group shows short names ("Documentary", not "USA ➾ Documentary") with a *Channels* button; the channel picker listed the 22 channels of a category, picking two chose the category and showed "2 channels", and after Save Live TV showed that category as exactly those two (694 channels in total, 692 once restored). Movies went from 156 categories to about 15 groups. **Series do not group** (83 categories became 6 rows, 68 of them in "Everything else", since each is named after a different service), so a group over 20 is sorted A to Z with a letter chip row; seen on the emulator, the chips render and tapping P landed on PAKISTAN, Paramount+, PBS, Peacock, PUNJABI. Not seen: the letter row with a remote (each chip should be focusable) or on a phone. The 555-channel "USA ➾ News" category loaded and filtered instantly by typing, two stations kept out of it, and Live TV then showed that category as exactly 2 (139 channels in all). Unit tested: grouping on the observed name shapes, the stored picks (round trip, an old account reading as whole, dropping with the category, empty meaning whole), and `pickChannels`. **Not seen:** a real remote moving between a row and its *Channels* button (they are siblings so Right should work), a phone, how the grouping fares on a second panel with a different naming scheme, or *Chosen* and Back stepping out of a group on a remote. A name this cannot make sense of lands in *Everything else*, which is the thing to look for on another panel|
| 🟡 | **Hidden words** (added 2026-10-09). A *Hide words* chip in the category picker opens a sheet to add and remove words. Seen on the Google TV emulator: adding "France" took its group out ("11 hidden by your words", a *Show them* switch), adding "UK" made it 23, the list survived leaving and reopening the picker, and adding "USA" un-ticked the 3 chosen USA categories with "Un-ticked 3 chosen categories that "USA" hides. Save to keep that." (Chosen 0). I removed the test words afterwards and did not save. Unit tested: whole-word matching (UK against Ukraine), phrases in order, case, other scripts, the stored list, and `withoutHidden`. **Not seen:** a hidden word actually removing channels from Live TV or the channel picker (only unit tested), the sheet with a remote, or a phone. Typing the word needs the on-screen keyboard on a TV, as everywhere else|
| ⬜ | **Plex link screen on a TV** (#5, added 2026-09-22). Now two columns on TV, with the waiting state inside the code panel, a 28 dp spinner, and focus on a new Cancel button. The issue's acceptance is fit: from *Add a source* with the AppBar present, the code, the spinner and Cancel all on screen without scrolling. A widget test cannot settle that (§11, the test font wraps prose to twice its height), so it is unverified until seen on a TV or TV emulator |

## 6a. iOS simulator, first run, 2026-09-23

iPhone 18 Pro simulator, iOS 27.0, Xcode 27.0, arm64 debug build. The first
time the app had been built for iOS at all. `flutter build ios --simulator`
succeeded without changes; CocoaPods is required alongside SwiftPM because
`media_kit_video` and `media_kit_libs_ios_video` do not support SwiftPM yet.

| | What | Evidence |
|---|---|---|
| ✅ | **Video renders on the simulator** — unlike the Android emulator's `EGL_BAD_ATTRIBUTE` black picture. The control matters here: the test clip is a generated pattern whose bars scroll and whose progress band fills over its 20 s, and two screenshots seconds apart showed the band at ~1% then ~27% with the bars shifted, so frames were being decoded and presented, not just a clock advancing. So the simulator *is* a usable playback loop for iOS, which the emulator never was for Android. H.264 from the Photos library only; nothing network-sourced has been played |
| ✅ | Onboarding, Add a source, Library tabs, Photos permission prompt, folder listing, player chrome auto-hide | Seen on screen |
| ✅ | **Fixed: crash on "Allow video access."** No `NSPhotoLibraryUsageDescription`, so iOS killed the app the moment photo_manager asked (tccd: "attempted to access privacy-sensitive data without a usage description"). Added to Info.plist |
| ✅ | **Fixed: "no routes for location" opening a device folder.** PHAsset ids contain slashes (`<uuid>/L0/040`); Android's numeric MediaStore ids never exposed the unencoded route. Now `Uri.encodeComponent`, as `/saf/` already did |
| ✅ | **Fixed: every device video listed with a blank name.** iOS leaves `AssetEntity.title` empty unless the query sets `needTitle` |
| ✅ | **Fixed: "Or pick a folder instead" / "Add a folder" on iOS.** `saf_util` and `saf_stream` are Android-only, so these would throw `MissingPluginException`. Hidden off Android until the §7.1 document-picker source exists |
| ✅ | **Plex on iOS** (2026-09-23, store-screenshot session). Linked by code on an iPhone 14 Plus simulator (iOS 18.6) and an iPad Pro 13" simulator (iOS 27), library and continue-watching loaded, search worked, and direct play of an open-licensed film decoded frames; the resume position carried from one device to the other through Plex. **On a real iPhone** the account owner played the same film from TestFlight `1.0.4 (8)` without error |
| ✅ | **Fixed: an audio warning shown as a fatal error.** On the iOS 18.6 simulator mpv logged "Could not open/initialize audio device -> no sound." and the player drew its error overlay over a picture that was still playing: media_kit forwards mpv error-level *log lines* as errors. Now filtered by `player_errors.dart`, an allow-list of known-benign messages, pinned by `test/player_errors_test.dart`. Not seen on the real iPhone, so simulator-specific in practice |
| ✅ | **Fixed: "Add a source" promised folder picking on iOS.** The "Video on this device" subtitle now reads "Play the videos in your photo library." there |
| ⬜ | **SMB on iOS** — not attempted: it needs a real share. The Plex half of this row was closed above. `NSLocalNetworkUsageDescription` is added, but the simulator does not enforce the Local Network prompt, so whether LAN connections work on a device is open |
| ⬜ | **Anything on a real device** — needs an Apple signing team; the project has none set |
| ⬜ | **The iOS libmpv/ffmpeg licence check** (architecture.md, Open items). The simulator build links a different binary from Android's; nobody has read its contents yet |
| ⬜ | **Known, not fixed:** (a) the "Local & Network" tab label runs off the edge at phone widths. Android phones clip it too (the 2026-09-22 Play shot shows "Local & Netw"): the tabs are a horizontal scroller whose underline fixes each tab at 100 dp, so it is a layout choice, not an iOS bug. It fits on iPad; (b) iOS lists the same video under several smart albums (Recents, Videos, Recently Saved); (c) the copy says the app "only asks for video access", but iOS asks for the whole photo library; (d) a debug build launched outside `flutter run` shows a white screen for 2–3 s before the first frame — a JIT debug build, so not representative of release |

---

## Verified, so nobody re-tests it

Recorded to stop this becoming a list of everything.

- **Plex**: PIN link, server discovery, multi-server merge, library mapping,
  section browse, direct play (Windows), server-side search, series → seasons →
  episodes, session restore across restart, **connecting a server shared by
  someone else** (relay-only, no direct path — connected with its libraries
  listed in under four seconds on an Android phone emulator)
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

104 tests (count updated 2026-09-23; it read 40 before the player-control,
Plex link, audio-focus, library-sort, watch-state, watch-action and
playback-settings tests landed). `player_controls_test.dart` pins the #10 remote rules
(wake-only first press, time-based seeking, Up never seeks, hide takes focus
with it) against a fake transport, so it proves the rules and not how a real
remote feels. `native_licenses_test.dart` loads every native licence entry the
way the About licence page does, so a missing asset fails here rather than on a device. `settings_sections_test.dart` pins that
the release Settings never lists an unbuilt section (architecture.md §12.1),
with the gallery as its control. The loopback bridge now has real coverage — ranges, suffix ranges, the
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
