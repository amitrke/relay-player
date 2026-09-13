# Play listing copy

Plain text files in the layout fastlane `supply` expects. **fastlane is not set
up**; these are pasted into Play Console by hand today. The layout is used
anyway so that adopting `supply` later is a no-op rather than a migration, and
so the screenshots from #7 land where they are already expected to.

The reasoning behind the copy, the drafted answers to the Play Console forms,
and the constraints that shape all of it are in
[docs/STORE_LISTING.md](../../../../docs/STORE_LISTING.md). Read that before
editing anything here: this text is where `docs/architecture.md` §1's
primary-purpose argument meets a reviewer.

Limits Play enforces, which are why the files look the way they do:

| File | Limit | Current |
|---|---|---|
| `title.txt` | 30 characters | 12 |
| `short_description.txt` | 80 characters | 62 |
| `full_description.txt` | 4000 characters | 1511 |

`images/phoneScreenshots/` is where #7's output goes. It is empty, and no image
goes in it that has not been checked against §1: nothing from an IPTV source,
no Advanced Sources UI, no real server or account names.
