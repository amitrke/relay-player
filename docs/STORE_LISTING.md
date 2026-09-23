# Store listing and submission answers

The source of truth for every piece of public text about this app, and the
drafted answer to every Play Console form that gates a reviewed release.

**Why this is a document and not a console text box.** The listing is where
[architecture.md](architecture.md) §1's primary-purpose argument actually meets
a reviewer. They form their view of what this app is for from the description,
not from the architecture doc. Keeping the text here makes a change to it
diffable, reviewable, and visible in `git log` alongside the reasoning, the
same as any other §1-relevant decision. Issue #8 makes this argument for
fastlane; the argument holds without fastlane, which is why the text lives here
now and the tooling question stays open.

The copy itself is in `fastlane/metadata/android/en-US/`, in the layout
fastlane `supply` expects, so adopting it later is a no-op rather than a
migration. **fastlane is not set up.** Those are plain text files today, pasted
into the console by hand. See #8 for when that should change.

Progress against these forms is tracked in issue #11.

## The constraints that shape the copy

1. **No provider names, and no IPTV framing** (`CLAUDE.md` §1, §8.3). Describe
   source *types*: a Plex server, a network share, files on the device.
2. **Advanced Sources is not advertised** (§8). It is an opt-in the user turns
   on deliberately, disclosed in review notes, and absent from the listing and
   from every store screenshot.
3. **Claim nothing that is not shipped.** See the honesty notes below, which
   are the part most likely to rot.
4. **Screenshots come from Plex, local files or SMB only** (§13 Phase 6, #7).

## Honesty notes, revisit at every release

The copy deliberately omits things that exist in the code but are not ready:

- **No Android TV or Fire TV claim.** The manifest makes the app launchable on
  a TV, but the leanback UI is Phase 4 and the D-pad walk has only been checked
  on an emulator ([MANUAL_TESTING.md](MANUAL_TESTING.md) §6). Add this at
  `v1.1.0`, not before, and add the TV screenshots at the same time.
- **No background playback claim.** There is no media session and no foreground
  service (#12).
- **No subtitle features claimed.** There is no track selector yet.
- **No transcoding claim.** Plex direct play only, deliberately, while the
  transcode session lifecycle is unproven.
- **"Your credentials stay in encrypted storage"** rests on §3 and on §15's
  request to verify by inspection that no secret material reaches the Hive
  files. **That check was run for the first time on 2026-09-22 and it failed.**
  `settings.hive`, pulled off a real phone, held a live `X-Plex-Token` in
  plaintext: `PlexService.posterUrl` returns an *image transcode* URL, Plex's
  image transcoder is authenticated, and `HistoryItem` persisted that signed
  URL as its `poster`. The sentence above was false for as long as anyone had
  watched anything.

  Fixed the same day: history stores the unsigned artwork path and the
  continue-watching row re-signs it at render time, a versioned one-time purge
  rewrites boxes written by the old code, and
  `test/history_no_credentials_test.dart` pins it with controls. Re-verified by
  pulling the box again: 3,406 bytes with nine copies of the token, down to 252
  bytes with none. **The claim is true as of that fix and not before it.**

  Two things this cost, worth not relearning. Hive is an append-only log, so
  rewriting the value left every superseded record — token included — in the
  file until `compact()`; the unit test passed while the token was still on
  disk. And the first purge keyed off "does the stored value contain a token",
  which disarmed itself: run one cleaned the value, run two saw a clean value
  and skipped the compaction, and the stale records would have survived
  forever. The pass is now driven by a marker recording whether it has *run*.

## Drafted console answers

Read off the console on 2026-09-13. **These are drafts for you to review and
submit.** Content rating, Data safety and Target audience are binding
declarations to Google, and a wrong answer is an app suspension rather than a
correction, so none of them should be submitted on someone else's reading.

| Form | Draft answer |
|---|---|
| Set privacy policy | `https://amitrke.github.io/relay-player/privacy.html`. Served from `site/` by `.github/workflows/pages.yml`. Live once this reaches `main` (#9) |
| Sign in details | **Submitted 2026-09-22: no part of the app is restricted.** The app itself has no sign-in: local files, chosen folders and SMB shares all work without an account, and Plex uses the user's own Plex account rather than one of ours. *Superseded draft:* this row used to call for a Plex demo account for the reviewer. That is still the fallback if review comes back unable to exercise the Plex path, which the listing leads with, and a reviewer device with no video on it will show an empty library. Keep any such credentials out of this public repo |
| Ads | No ads. The app contains no advertising and no ad SDK |
| Content rating | **Submitted 2026-09-22**, reasoning in the note below. Result: ESRB Everyone, PEGI 3, ClassInd all ages |
| Target audience | **Submitted 2026-09-22: 18 and over**, not directed at children. The app has no child-appropriate content of its own and no content filtering, so a lower band would pull it into the Families policy programme for no benefit |
| Data safety | **Submitted 2026-09-22: no data collected and none shared.** The judgement call: Plex tokens go to plex.tv and SMB credentials to the user's NAS, both only because the user connected that service themselves, and never to us. That is the position generic players and mail clients declare as "no data collected"; if Google reads "a third party" as covering a service the user chose, this is the answer that changes. No backend, no analytics, no SDKs that phone home. Revisit when #6 lands, at which point the answer becomes crash logs and diagnostics, collected optionally, not shared, with the opt-in toggle named. §15 asks for this to be filled as a dry run before submission rather than during it |
| Government apps | No |
| Financial features | None |
| Health | No health features |
| App category and contact details | Category **Video Players & Editors**. Contact email plus `https://github.com/amitrke/relay-player` as the website |
| Store listing | The three files in `fastlane/metadata/android/en-US/`, plus a 1024x500 feature graphic and phone screenshots (#7) |

**Entered in the console on 2026-09-22**, all saved to Publishing overview and
not yet sent for review: every row above except the contact details and the
store listing, plus two forms the 2026-09-13 reading did not show:

- **Advertising ID: not used.** The merged release manifest carries no `AD_ID`
  permission.
- **Photo and video permissions**, which asks why `READ_MEDIA_VIDEO` is not
  replaced by the photo picker. Answer: a core feature is a browsable library
  of every video on the device, grouped by folder (`DeviceVideoSource`, §7.1),
  which a one-shot picker cannot provide; no photos are read and all-files
  access is never requested. The wording says the library is read "whenever it
  is opened", not "on every launch", because that is what the code does.

The binding declarations were submitted by the assistant at the account
owner's explicit instruction, on the readings recorded in this table.

The listing text, 512px icon and feature graphic are saved as a listing draft.
Still open: the contact email, which Play publishes immediately on save, and
the tablet screenshots (#7). The phone screenshots were captured on 2026-09-22
and are in the repo; what they are, and what could not be photographed, is
below.

### Content rating deserves real thought

The IARC questionnaire asks about the app's *own* content, and this app has
none of its own, which makes most answers straightforwardly "no". The question
that is not straightforward is the one about whether users can reach unfiltered
or uncurated content through the app.

A player that connects to a user's own Plex server and their own NAS is not
obviously that. A player that can also be pointed at an arbitrary playlist,
even behind an off-by-default gate, is arguably closer to it. Answer it
deliberately, and **write down the answer and the reasoning here** when it is
settled, because it is exactly the kind of declaration that will be revisited
if a complaint ever arrives (§1.5).

**Settled 2026-09-22.** The question as the questionnaire actually words it is
whether the app *features or promotes* content outside the download, with
Netflix, Spotify and AI output as the examples, and its follow-ups ask only
about content "sellers create as part of the app catalog". This app has no
catalog and features or promotes nothing; it plays what the user connects,
which is VLC's position. So the answer is **No**, and every other answer was
No as well (no rating-relevant bundled content, no user-to-user interaction,
no age-restricted promotion, no location sharing, no purchases or rewards, not
a browser, not news or education). Answering Yes and then Yes to every content
question would have claimed a catalog that does not exist, and the resulting
adult rating would have been a misrepresentation in the other direction.
Advanced Sources does not change this: it is still user-supplied content, and
§1.2 keeps it out of everything the app itself presents.

## The published site

`site/` is served at `https://amitrke.github.io/relay-player/` by
`.github/workflows/pages.yml`, which publishes that directory and nothing
else. `/docs` is deliberately not the Pages source: it holds working documents
rather than anything meant to be presented as a website.

Two of its pages are public statements about the app and should be changed with
the same care as the listing copy:

- `privacy.html`, which Play requires and links from the listing.
- `index.html`, which repeats the source framing from the listing, and so is
  bound by the same §1 constraints.

**The policy makes claims that must stay true.** It says no crash reports are
sent, which stops being true when #6 ships. It says nothing about AI data
sharing, which §9.3 will require when §9 ships. Update the policy in the same
change that ships either feature, never after.

## Assets still missing

- [x] Feature graphic, 1024x500. Not a screenshot, and required. Drawn by
      `tool/tv_banner.py` as `assets/icon/feature_graphic_1024x500.png`, the
      same lockup as the TV banner, and uploaded 2026-09-22
- [x] Phone screenshots, 2 to 8 (#7). Four, captured 2026-09-22, in
      `fastlane/metadata/android/en-US/images/phoneScreenshots/`
- [x] **10-inch tablet screenshots, which the console marks required.** The
      field carries the same `*` as the phone field, while 7-inch does not.
      The listing saved with the phone shots alone and the dashboard ticked
      "Set up your store listing", so the asterisk did not block the draft;
      whether it blocks review is still untested. Two shots captured
      2026-09-22 in `images/tenInchScreenshots/`, with the caveat below
- [ ] TV screenshots at 1920x1080, required only when opting into TV
      distribution, so `v1.1.0` rather than now. The 1280x720 banner already
      exists from `tool/tv_banner.py`

### The phone screenshots, and the four shots that could not be taken

Captured 2026-09-22 by hand from a Pixel 10a on Android 17, running the
release APK of `com.subnext.relay` built from `native-licences`. Not automated:
#7's `integration_test` plan still stands, and none of this replaces it.

| File | Screen |
|---|---|
| `1.png` | Library, Movies tab, three Plex titles |
| `2.png` | Player, landscape, controls over a decoded frame |
| `3.png` | Search, query "bunny", one result |
| `4.png` | Settings, Appearance: the five theme chips and the accent swatches |

Three details worth not rediscovering:

- **The device's native resolution is an illegal Play asset.** Play's rule is
  that the long side may not exceed twice the short side, and the Pixel's
  1080x2424 breaks it. Capture went through `adb shell wm size 1080x1920` with
  `wm density 420`, which renders natively at exactly 9:16 and needs no
  cropping. 1080x1920 is also the bar for large-format feature placement,
  which wants four or more at that size. Four is what there is, with no margin:
  losing one shot loses the eligibility.
- **`font_scale` was 1.3 on the device** and was set to 1.0 for capture, since
  the listing should show the layout most users see. SystemUI demo mode
  (`sysui_demo_allowed`) gives the clean 9:00 status bar. Every one of these
  was restored afterwards.
- **`adb shell input text` is not usable for screenshots.** It injects a
  synthetic keyboard event, after which Android draws a green focus border
  around the app and keeps drawing it until the process restarts. The search
  query was typed by tapping the on-screen keyboard instead. Taps do not
  trigger it.

**What could not be photographed**, all for reasons that outlive this session:

- **Series, and the season and episode detail screen.** The Plex account used
  reports `0 series`, so `ShowDetailScreen` has never been on camera. The
  full description claims browsing shows down to seasons and episodes, and
  that claim is still true, just unillustrated. Anyone with TV content on a
  Plex server can close this.
- **Privacy and data.** The card itself is the best argument the app has
  ("Off by default. Reports contain no library or account data. Subnext
  Player has no backend and no analytics"), but §12.1 puts it directly below
  Advanced sources, whose card reads "IPTV provider or playlist" with the
  subtitle "Adds Live TV and Xtream Codes logins", and directly above About,
  which repeats the IPTV sentence. Constraint 2 above bars both from a store
  screenshot, and no scroll position isolates the privacy card between them.
  Worth revisiting only if §12.1's section order changes.
- **Local & Network.** The capture device's media library is the owner's own
  camera roll and messaging videos. #7's "no real user data" rule rules it
  out, and staging openly licensed files on an emulator was considered and
  declined rather than ship a composed shot.
- **Onboarding and Add a source.** Both carry the §8.2 Advanced Sources
  disclosure in body copy. Correct in the app, barred from the listing.

**The console does not preserve upload order.** The four went up as `1.png`
to `4.png` in the order library, player, search, settings, and the listing
came back ordered settings, library, search, player. The first screenshot is
the one the store card and search results show, so the order has to be fixed
by dragging in the console after any upload. Re-uploading in a different order
is not a fix, because the order it lands in is not the order it was sent.

Two further notes on what is in frame. `4.png` shows the Plex server name
"Main", kept deliberately: it is generic, names no provider and identifies
nobody, which is what §1 is actually protecting against. And About was a
candidate until it rendered `Version 0.0.0 (1)`, which is what a local build
without CI's tag-derived build name shows; any future shot of that pane needs
`--build-name` set.


### The tablet screenshots, and why there are only two

Captured 2026-09-22 from the 10-inch emulator at `wm size 1440x2560` with
`wm density 320`, in dark mode to match the phone set. The console wants each
side between 1,080 and 7,680 px at 16:9 or 9:16 for this field, which
1440x2560 satisfies exactly; the emulator's own 2560x1600 is 16:10 and would
not. `1.png` is the library, `2.png` is search.

**Settings cannot be shot on a tablet at all.** 1440x2560 at 320 dpi is 720 dp
wide, which `RelayLayout.of` calls `tablet`: below the 1100 dp desktop
breakpoint, so no rail, but tall enough that the entire settings page fits on
one screen. Appearance, the Advanced sources card reading "IPTV provider or
playlist / Adds Live TV and Xtream Codes logins", the second server's real
name and `Version 0.0.0 (1)` are therefore all in frame together, and unlike
the phone there is no scroll position that separates them. Going wider does
not help: past 1100 dp the desktop rail lists "Advanced sources" as a
permanent nav label. Constraint 2 rules out every variant.

**Both shots look sparse, and that is a content problem rather than a layout
one.** Three movies on a 720 dp grid fill about a fifth of the height, and the
search result is a single poster. Adding more openly licensed titles to the
Plex library used for capture (Sintel, Cosmos Laundromat, Spring, Caminandes)
would fix the phone grid and these at the same time, and is the single highest
-value thing anyone can do before re-shooting.

Two capture notes specific to the emulator. It reports a hardware keyboard, so
the soft keyboard is suppressed and `adb shell input text` is the only way to
type, which triggers the same green focus border described above;
`settings put secure show_ime_with_hard_keyboard 1` brings the on-screen
keyboard back so the query can be tapped instead. And a screenshot taken too
soon after `am force-stop` catches the splash rather than the library, which
passes every dimension check and is nearly all black, so check what a capture
actually contains rather than only that it is the right size.
