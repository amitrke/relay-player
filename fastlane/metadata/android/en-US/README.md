# Play listing copy

Plain text files in the layout fastlane `supply` expects. ~~fastlane is not
set up; these are pasted into Play Console by hand.~~ Since 2026-10-29
`.github/workflows/promote.yml` uploads this text to Play with every production
release and with its `listing` action, so **an edit here overwrites the live
listing** the next time either runs. Run its `check` action first if anyone may
have edited the listing in Play Console. See docs/RELEASING.md, "Production".
Images are still not uploaded; the screenshots from #7 land here for when they
are.

`changelogs/v<version>.txt` holds the notes for one version, at most 500
characters, and is the only copy: release.yml sends it to testers, and
promote.yml sends the same text to Play production and to the App Store as
"What's New". The older `3.txt` is named after a versionCode, the convention
before 2026-09-23.

The reasoning behind the copy, the drafted answers to the Play Console forms,
and the constraints that shape all of it are in
[docs/STORE_LISTING.md](../../../../docs/STORE_LISTING.md). Read that before
editing anything here: this text is where `docs/architecture.md` §1's
primary-purpose argument meets a reviewer.

Limits Play enforces, which are why the files look the way they do:

| File | Limit | Current |
|---|---|---|
| `title.txt` | 30 characters | 14 |
| `short_description.txt` | 80 characters | 62 |
| `full_description.txt` | 4000 characters | 1516 |

`images/phoneScreenshots/` is where #7's output goes. No image goes in it that
has not been checked against §1: nothing from an IPTV source, no Advanced
Sources UI, no real server or account names.

It holds four shots as of 2026-09-22, captured by hand rather than by #7's
still-unbuilt harness. `docs/STORE_LISTING.md` records what each one is, the
capture settings that make them legal Play assets, and the four screens that
could not be photographed and why.
