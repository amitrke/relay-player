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
- **"Your credentials stay in encrypted storage"** is a real claim resting on
  §3 and on §15's request to verify by inspection that no secret material
  reaches the Hive files. Do that check before this text is public.

## Drafted console answers

Read off the console on 2026-09-13. **These are drafts for you to review and
submit.** Content rating, Data safety and Target audience are binding
declarations to Google, and a wrong answer is an app suspension rather than a
correction, so none of them should be submitted on someone else's reading.

| Form | Draft answer |
|---|---|
| Set privacy policy | `https://amitrke.github.io/relay-player/privacy.html`. Served from `site/` by `.github/workflows/pages.yml`. Live once this reaches `main` (#9) |
| Sign in details | **Needs a real demo account.** The app shows nothing useful without a connected source, and Plex needs an account. Create a Plex account for review with a small library of openly licensed content, and give the reviewer those credentials plus a note that Advanced Sources is off by default and not required to use the app (§8.4). Keep the credentials out of this public repo |
| Ads | No ads. The app contains no advertising and no ad SDK |
| Content rating | See the note below. Do not rush this one |
| Target audience | **18 and over**, not directed at children. The app has no child-appropriate content of its own and no content filtering, so a lower band would pull it into the Families policy programme for no benefit |
| Data safety | **Today: no data collected and none shared.** No backend, no analytics, no SDKs that phone home. Revisit when #6 lands, at which point the answer becomes crash logs and diagnostics, collected optionally, not shared, with the opt-in toggle named. §15 asks for this to be filled as a dry run before submission rather than during it |
| Government apps | No |
| Financial features | None |
| Health | No health features |
| App category and contact details | Category **Video Players & Editors**. Contact email plus `https://github.com/amitrke/relay-player` as the website |
| Store listing | The three files in `fastlane/metadata/android/en-US/`, plus a 1024x500 feature graphic and phone screenshots (#7) |

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

- [ ] Feature graphic, 1024x500. Not a screenshot, and required
- [ ] Phone screenshots, 2 to 8 (#7)
- [ ] TV screenshots at 1920x1080, required only when opting into TV
      distribution, so `v1.1.0` rather than now. The 1280x720 banner already
      exists from `tool/tv_banner.py`
