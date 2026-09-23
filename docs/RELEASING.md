# Releasing to testers

How a build gets from this repo to testers' devices through Google Play and,
since 2026-09-23, TestFlight, and the one-time setup that makes it possible.
Android is described first because it came first; iOS has its own section,
[iOS: TestFlight](#ios-testflight), and shares the versioning rules. The workflow is
[`.github/workflows/release.yml`](../.github/workflows/release.yml); this file is
the part of it that cannot live in YAML.

Internal testing goes to at most 100 named testers and **is not reviewed**, so
none of this exercises the store-policy position in architecture.md §1 or §8.3.
That happens at closed, open and production testing, which is §13 Phase 6, and
this pipeline is only the transport for it. Nothing here should be read as
evidence that a build would pass review.

Written 2026-09-13. Steps marked **unverified** have not been run yet; update
them with what actually happened, including the failures, when they are.

## What the workflow does

1. Works out the version once, for both stores (see
   [Test builds and releases](#test-builds-and-releases)), then runs
   `flutter analyze` and `flutter test`.
2. Builds `app-release.aab` signed with the **upload key** from repository
   secrets. The `versionCode` is the workflow's run number, and the
   `versionName` is `pubspec.yaml`'s version.
3. Refuses to continue if the bundle is unsigned or has a debug certificate.
   `build.gradle.kts` falls back to the debug key when no key is configured,
   because local `flutter run --release` needs that, so this check is the one
   that stops a broken secret from getting through.
4. Picks the release notes (added 2026-09-22, first used by the build after
   v1.0.1): `fastlane/metadata/android/en-US/changelogs/<versionCode>.txt`, or
   `v<version>.txt` (`v1.0.4.txt`) in the same folder. The second name exists
   because the versionCode is the run number, which nobody knows before
   pushing; fastlane `supply` ignores that name, so the two do not clash. Every
   test build of a version reads the same `v<version>.txt`, so the notes can
   grow along with the version. (Before 2026-09-23 only a tag run looked for
   it.) Notes over Play's 500 characters fail the run before the build. No
   notes is a warning, not a failure. They are store listing copy, so §8.2
   applies: no Advanced sources, IPTV, Xtream, Live TV or playlists.
   **Verified 2026-09-23** on the v1.0.2 tag (run 5), which logged
   `changelogs/v1.0.2.txt (342 characters)` and uploaded them.
   **A tag's notes file is frozen once that tag has run.** On 2026-09-23
   `v1.0.2.txt` was edited to describe later work after v1.0.2 had already
   shipped, so the repo described a build that never had those features. It
   was restored and the later work went into `v1.0.3.txt`. Check
   `git ls-remote --tags origin` before writing notes for a version.
5. Keeps the bundle as a workflow artifact for 14 days.
6. Uploads it, with the notes, to the `internal` track, but only if `PLAY_SERVICE_ACCOUNT_JSON`
   is set. Without that secret the upload is skipped with a notice rather than
   failing the run, and that is what makes the first manual upload possible.

Triggers: push to `develop` for a test build, push a `v*` tag for a release,
or run it by hand from the Actions tab. Pushes to `main` do not release. See
[Test builds and releases](#test-builds-and-releases).

## Identity

- **Package name: `com.subnext.relay`.** It is permanent from the first upload.
  Sideloaded builds from before 2026-09-13 used `com.relayplayer.relay_player`
  and install alongside new ones, not over them. Their stored sources and
  credentials do not carry across.
- The Kotlin `namespace` is still `com.relayplayer.relay_player`. That is on
  purpose, and the comment in `build.gradle.kts` explains why.
- **iOS bundle identifier: `com.subnext.relay`**, the same as Android, set
  2026-09-23. It is registered as an explicit App ID under team `BTSKP77HML`
  and bound to the App Store Connect record created that day (iOS only;
  macOS and tvOS can be added to the same record once there is a build for
  them). Like the Play package name, it cannot change once a build has been
  uploaded. The team ID is committed in the Xcode project on purpose: it is
  printed in every signed build and is not a secret. No App ID capabilities
  were enabled beyond the default In-App Purchase, because background audio
  and PiP are Info.plist background modes, not capabilities.

## One-time setup

The steps must run in this order: Play's API will not accept a release for an
app that has never had a bundle uploaded, and the first bundle has to be signed
with the upload key it will be held to.

### 1. Make the upload key

*Why there is a key at all, given Play signs the app.* Play App Signing is
used here, and Google holds the key that devices verify. But Play still
authenticates every upload by its signature. It rejects an unsigned bundle,
and it rejects one signed with a debug certificate. The upload key is how Play
knows a bundle came from us, not a way to sign the app for users. That is why
losing it can be fixed by a reset while losing the app signing key could not.

Run this somewhere outside the repository. `*.jks` and `android/key.properties`
are gitignored, but outside the repo is the safer place for it:

```sh
keytool -genkeypair -v -keystore upload-keystore.jks \
  -storetype PKCS12 -keyalg RSA -keysize 4096 -validity 10000 -alias upload
```

- Use **one password for both the store and the key**. A PKCS12 keystore
  ignores a separate key password, so two different values only produce a
  secret that looks right and fails to sign.
- **Back up the `.jks` file and its password** somewhere that is not this
  machine. Losing them is recoverable, because Play Console can reset an upload
  key after a support request, but that takes days and blocks every upload in
  the meantime. The app signing key is the one that cannot be lost, and Play
  holds it (step 3).

### 2. Add the signing secrets

From the repository root, logged in with `gh`:

```sh
base64 -w0 /path/to/upload-keystore.jks | gh secret set ANDROID_UPLOAD_KEYSTORE_BASE64
gh secret set ANDROID_UPLOAD_KEYSTORE_PASSWORD   # prompts; nothing lands in shell history
gh secret set ANDROID_UPLOAD_KEY_PASSWORD        # the same value, see above
gh variable set ANDROID_UPLOAD_KEY_ALIAS --body upload   # a variable, not a secret
```

The alias is a repository *variable* because GitHub replaces every occurrence
of a secret's value in the logs with `***`. With the alias set to the word
`upload`, every log line about an upload came out masked (run 1). The alias
was never the sensitive part: the keystore and its password are.

On Windows PowerShell there is no `base64`, so replace the first line with the
lines below. Two details matter. `Resolve-Path` is needed because .NET resolves
a relative path against the process's working directory, not PowerShell's
current location. `--body` is used instead of a pipe because Windows PowerShell
5.1 adds a newline to text it pipes to a program.

```powershell
$b64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes((Resolve-Path path\to\upload-keystore.jks)))
gh secret set ANDROID_UPLOAD_KEYSTORE_BASE64 --body $b64
Remove-Variable b64
```

### 3. Build once, and upload that bundle by hand — done 2026-09-13

1. Actions → *Release to Play internal testing* → *Run workflow*. With no Play
   credentials it builds, checks the signature, stores the artifact and skips
   the upload.
2. Download the `android-aab-<run number>` artifact.
3. In Play Console open **Test and release → Testing → Internal testing** and
   create a tester list (email addresses, at most 100). Email lists belong to
   the developer account and are shared across all its apps. Tick only this
   app's list on the track.
4. **Create new release** and upload the `.aab`. The bundle's certificate
   becomes the registered upload key, so it has to be the step 1 key and not a
   debug build. The workflow's signature check exists for exactly this.
5. Add release notes, then save, review and roll out.
6. Open the opt-in link on the Testers tab with each tester's account. Until a
   tester opts in, Play shows them the store listing as "not available".

What was observed on 2026-09-13, doing this with run 1:

- **There was no Play App Signing prompt.** An earlier draft of this section
  said to accept one. New apps are enrolled automatically, and afterwards
  *Protected with Play → App signing* showed a Google-held app signing key
  already "In use".
- **The upload key certificate registered on that page matched the SHA-256
  fingerprint the workflow logged.** That confirms the chain from secret to
  bundle to registration end to end.
- **Play allowed a full rollout while the app was still a draft.** The track
  went *Active*, the release was "Available to internal testers · Not
  reviewed", and the store name showed as the placeholder
  "com.subnext.relay (unreviewed)". None of the *Set up your app* forms were
  filled in first.

### 4. Give the workflow a service account — done 2026-09-13

1. In the app's Google Cloud project (`relay-player`, the same project as
   Firebase), enable the **Google Play Android Developer API**
   (`gcloud services enable androidpublisher.googleapis.com --project relay-player`).
   Play Console no longer needs a project linked to the developer account.
   Inviting the service account (step 3) is enough.
2. Create a service account there. It needs no Cloud roles. It was created as
   `play-release`, with a **JSON key**. Do not reuse the Firebase Admin SDK
   service account: it carries broad Firebase rights, and this key lives in a
   GitHub secret. Pass `--project` explicitly, because a machine's `gcloud`
   default project may be a different one.
3. In Play Console open **Users and permissions → Invite new users**, enter the
   service account's email, and add this app with only **Release apps to
   testing tracks**. Do not grant account-wide admin: the key sits in a GitHub
   secret and should be able to do as little as possible.
4. `gh secret set PLAY_SERVICE_ACCOUNT_JSON < /path/to/key.json`, then delete
   the downloaded file. In PowerShell, which has no `<`:
   `Get-Content -Raw key.json | gh secret set PLAY_SERVICE_ACCOUNT_JSON`.

The first automated upload (run 2, 2026-09-13) succeeded a few minutes after
the invite, with no 403 in between.

Permissions granted in Play Console can take a while to reach the API. A 403
straight after inviting the account is not yet a sign anything is wrong.

## iOS: TestFlight

Added 2026-09-23. The `ios` job in the same `release.yml` runs beside the
Android job after `check`, so one tag ships both, and a failure on one side
does not hold the other back.

### What the job does

1. Picks the newest stable Xcode on the `macos-latest` image. App Store Connect
   rejects builds made with an SDK older than Apple's current minimum, and the
   image's default Xcode is often not its newest.
2. Uses the same numbers as Android: `CFBundleVersion` is the run number and
   `CFBundleShortVersionString` is `pubspec.yaml`'s version. So TestFlight's
   `1.0.4 (7)` and Play's `1.0.4 (7)` are the same commit.
3. Uploads on every run, like Android. Until 2026-09-23 it uploaded only from
   a tag, because an untagged run would have been named `0.0.0` and opened an
   App Store *version* of that name in App Store Connect. The version step now
   refuses `0.0.0` outright, so that cannot happen.
4. Without the API key it compiles with `--no-codesign` and stops with a
   notice. Nothing else in CI builds for iOS, so this at least catches an iOS
   build that no longer compiles.
5. Archives with `xcodebuild`, not `flutter build ipa`, because only
   `xcodebuild` accepts an API key. The key plus `-allowProvisioningUpdates`
   lets Apple's **cloud-managed signing** supply the certificate and profile,
   so none of them sit in secrets. Flutter only generates the Xcode config
   (`--config-only`).
6. Exports with [`ios/ExportOptions.plist`](../ios/ExportOptions.plist),
   whose `destination: upload` makes the export also send the build to Apple.
   The step's exit status is the result.

**Unverified: signing with the API key on a clean runner.** The export path is
the one that worked from Organizer on 2026-09-23, and the exact
`xcodebuild archive` / `-exportArchive` commands were rehearsed locally that
day. That rehearsal signed with the Xcode account on this Mac, not with the API
key, so it proves the commands and the export options, not cloud signing.
Update this paragraph after the first tagged run.

### One-time setup

**Done 2026-09-23 by hand:**

- The explicit App ID `com.subnext.relay`, with no capabilities beyond the
  default In-App Purchase (see Identity above).
- The App Store Connect record, iOS only.
- The first upload, `1.0.0 (1)`, from Xcode's Organizer. It installed from
  TestFlight onto a phone the same day. **Build 1 of 1.0.0 is therefore used.**
  The workflow's run numbers were already past it (the last Android run was 6),
  so the first CI build is 7 or later and cannot collide.

**Still to do before the job can upload:**

1. In App Store Connect → Users and Access → Integrations → **Team Keys**,
   generate a key with the **Admin** role. Cloud-managed signing refuses keys
   with lower roles; App Manager is enough to upload but not to sign. Apple
   lets you download the `.p8` file **once**.
2. Repository **secret** `APP_STORE_CONNECT_API_KEY_P8`: the whole `.p8` file,
   including the `BEGIN`/`END` lines.
3. Repository **variables** (not secrets, for the masking reason given for
   `ANDROID_UPLOAD_KEY_ALIAS`): `APP_STORE_CONNECT_API_KEY_ID` (the key's ID)
   and `APP_STORE_CONNECT_ISSUER_ID` (shown above the key list).

An Admin key can do nearly anything to the account. It is exposed to one job,
written to a file outside the checkout, and deleted at the end. Revoke it in
the same screen if it ever leaks.

### Differences from the Play pipeline worth knowing

- **No release notes yet.** TestFlight's "What to Test" text is not set by
  `xcodebuild`. Testers see the build with no notes unless they are typed into
  App Store Connect. The `changelogs/` files are Play's.
- **Processing happens after the job ends.** A green job means Apple accepted
  the upload. The build still spends 10–30 minutes in processing before
  TestFlight offers it, and a rejection at that stage arrives by email, not in
  the run.
- **No log-watching.** On the first, manual upload, a watcher tailing Xcode's
  upload log never saw a line that meant "done", and its first version fired
  on the words "no error" in a progress line. Trust exit statuses.

## Versioning: the number says what is in the build, the track says how ready it is

Decided 2026-09-13, after the first two uploads made the alternative concrete.

**The version number carries contents. The Play track carries readiness.** A
tag is `vMAJOR.MINOR.PATCH` and names a set of features; promotion from
internal to closed to open to production is what claims the build is ready for
a wider audience. These are deliberately separate signals, and conflating them
is what a 0.x scheme would do.

*Why not start at 0.x, which is the obvious instinct for an app this unproven.*
Semver's 0.x convention is about the stability of a published API. This is an
application with no API surface, so 0.x would be spending a version number to
say something Play already says better: an internal-track build reaches at most
100 named testers and **is not reviewed**. The track is the honest signal and
it is the one Play actually acts on. Starting at 1.0.0 also avoids a permanent
oddity in the track history, because two untagged bundles already went up named
"1.0.0" on 2026-09-13 before any tag existed.

Two consequences, named here so they are not discovered later:

- **1.0.0 cannot be saved for the public launch.** There is no second first
  release. The public milestone is a *track promotion*, not a version bump.
- **A `v1.x` tag that never left internal testing still looks like a shipped
  product** to anyone reading the repo's releases page. Release notes must say
  which track a build reached. This is an architecture.md §1 framing matter,
  not just tidiness: the releases page is a public artefact, and it should not
  imply a reviewed, published app that does not exist yet.

### Test builds and releases

Decided 2026-09-23. Tagging every test build had become the most tedious part
of the loop, so the two jobs a tag used to do are now split:

| | How | Named | Goes to |
|---|---|---|---|
| **Test build** | push to `develop` | `pubspec.yaml`'s version + run number, e.g. `1.0.4 (12)` | Play internal testing and TestFlight |
| **Release** | push tag `v1.0.4` | the same | the same, for now. The tag marks which build shipped; promotion to wider tracks and the App Store is still §13 Phase 6 |

The rules, all enforced in the version step so they fail in seconds rather
than after a build:

- **`pubspec.yaml` holds the version being tested.** Bump it straight after a
  release. `1.0.4` from 2026-09-23, since `v1.0.3` had shipped.
- **A tag must match it.** `v1.0.5` on a commit whose pubspec says `1.0.4`
  fails. The tag names the builds testers already had, so it can't be a number
  made up at release time.
- **After a version's tag exists, test builds under that version stop**, with
  an error telling you to bump pubspec. More `1.0.4` builds after `v1.0.4`
  would be ambiguous on Play and rejected by Apple once 1.0.4 is live.
- `0.0.0` and anything not `MAJOR.MINOR.PATCH` fail.

A release is therefore: merge `develop` into `main`, tag that commit with the
version in its pubspec, push the tag, then bump pubspec on `develop`.

**Tradeoff, stated so it is not rediscovered.** A tester's build list now shows
several `1.0.4 (n)` builds before the release, and only the tag says which one
was *the* 1.0.4. That is the TestFlight convention and costs little on internal
tracks. It is the very ambiguity the section below designed out on
2026-09-13, accepted this time because every build now carries its run number
and the tag records the release.

### Choosing the stores

Added 2026-09-23. Both stores ship by default. Two ways to narrow that:

- **Repository variables** `RELEASE_ANDROID` and `RELEASE_IOS` (Settings →
  Secrets and variables → Actions → Variables). Set one to `false` and every
  push and tag skips that store until it is deleted or set to anything else.
  Unset means on. This is for standing situations, such as TestFlight signing
  being broken while Play keeps shipping.
- **The `platforms` input** on a manual run: `both`, `android` or `ios`. It
  narrows one run and cannot re-enable a store a variable has switched off,
  so the variable stays the one place to look.

A skipped store shows as a skipped job, not a failed one. A version that skips
one store for its test builds but not its tag still has only one tag; the tag
says what was released, not where.

### ~~The fallback version is 0.0.0, on purpose~~ — superseded 2026-09-23

Kept for the reasoning, which the section above answers rather than
overturns. `pubspec.yaml` now carries the version being tested.

`pubspec.yaml` says `0.0.0+1` and should stay that way. It is only ever used by
a run with no tag, and it exists to make such a run *unmistakable* on the track
("0.0.0 (7)"). It was 1.0.0 until 2026-09-13, which is exactly how runs 1 and 2
came to share a name with a release that had not happened.

### The planned ladder

Contents, not dates. Phase numbers refer to architecture.md §13.

| Tag | Contents | Earliest track |
|---|---|---|
| `v1.0.0` | Plex, local device storage, SAF folders, SMB shares, favourites/history/continue-watching, search, player, themes, Settings → About with native licence notices. Advanced sources present but gated off (§8.2) | internal |
| `v1.1.0` | Android TV / Fire TV leanback tree (Phase 4), plus the real-hardware items still open in MANUAL_TESTING.md §6 | internal |
| `v1.2.0` | M3U/XMLTV, the EPG guide (§12 screen 7), Provider Profile import (§8.3) — the rest of Phase 3 | internal |
| `v1.3.0` | The Playback and Subtitles Settings sections, and audio focus and pause-on-background (#17). On 2026-09-21 About and the native licence notices moved to `v1.0.0`, the AI features section to `v1.4.0` (§12.1), and Remote Config (#16) and Crashlytics (#6) left the MVP altogether (see the second gate below) | first eligible for closed |
| `v1.4.0` | AI features (§9, Phase 3.5) | — |

Two gates on that table are worth stating separately from it, because they are
the reasons the ladder is ordered this way rather than by §13's phase numbers:

- **`v1.0.0` waits for one hardware check, not a feature.** MANUAL_TESTING.md
  §1 opens with "Video renders at all — not tested", and everything under it is
  downstream. Tagging 1.0.0 before that is verified would attach the number to
  a claim nobody has seen hold. It needs a device and an afternoon, not a
  phase.
- ~~**Nothing is promoted past internal testing until Remote Config ships.**~~
  **Withdrawn 2026-09-21.** The original argument: closed testing is reviewed,
  and §16.1 says a rights-holder complaint against a shipped Advanced Sources
  feature needs a minutes-long response, not a multi-day store-update cycle.
  It was a gate this project imposed on itself, not one Play asks for, and on
  Play it does not hold up well enough to justify adding Firebase to the MVP:
  - Neutral bring-your-own-source IPTV players have stayed on Play for years.
    Removals mostly hit apps that market piracy, bundle or recommend sources,
    or front a single provider, which §1 and §8.3 already rule out.
  - A new app with a handful of testers is the least likely target of a
    complaint, since complaints follow visibility.
  - The slow answer is not that slow on Play: an update removing the feature
    is usually reviewed in hours to a couple of days, and a rollout can be
    halted or the app unpublished from the console in minutes meanwhile.
  - Without it the MVP has no Firebase at all, so the published privacy
    policy's "only connections to services you configure" stays true.

  The argument is strongest for iOS, where review is stricter and slower.
  **Revisit before the Phase 5 submission, or the first time a complaint
  arrives**, whichever comes first. The design in §16.1 and #16 stands; only
  its place on the schedule changed.

This ladder puts AI (§13 Phase 3.5) *after* Phase 4 and the Phase 6
prerequisites, which is a deliberate reordering: it is the largest remaining
block of work and nothing about a store submission depends on it, whereas
§12.1's About section does. (It also said §16's kill switch did, until that
gate was withdrawn above.)

## Failure modes to expect

- **"Only releases with status draft may be created on draft app."** Play
  treats an app as a draft until its setup is complete. The workflow's manual
  run has a `status` input for this. Choose `draft`, then roll the release out
  in Play Console. **Not hit here, as of 2026-09-13.** Once the first release
  had been rolled out by hand (step 3), the API accepted a `completed` upload
  (run 2), even though none of the *Set up your app* forms were done. The
  `draft` input stays for apps that have not had that first manual rollout.
- **"Version code N has already been used."** Re-running a run that reached
  the upload reuses its run number. Start a new run instead. Renaming or
  recreating `release.yml` resets the run count, and every upload fails until
  the count passes the highest code Play has seen.
- **The upload certificate doesn't match.** The log prints the bundle's SHA-256
  fingerprint. Compare it with *Test and release → Setup → App signing → Upload
  key certificate*. A mismatch means the secret holds a different keystore from
  the one registered in step 3.
- **Every build named "1.0.0".** Play names a release after its versionName,
  and untagged runs take that from `pubspec.yaml`, so runs 1 and 2 looked
  identical on the track. Fixed twice over: the workflow sets the release name
  to `<versionName> (<run number>)`, and the `pubspec.yaml` fallback is now
  `0.0.0`, so an untagged run can no longer collide with a tagged release. Tag
  real versions to move the first part.
- **No native debug symbols.** Play warns that the bundle contains native code
  without symbols. That is libmpv (PHASE0_FINDINGS.md Q5). It is a warning and
  not a rejection. Symbols start to matter when §16's crash reporting does.
- **iOS: "The bundle version must be higher than the previously uploaded
  version."** The iOS twin of the versionCode rule, with the same cause (a
  re-run reuses its run number) and the same fix. Remember build 1 of 1.0.0 was
  uploaded by hand.
- **iOS: signing fails in the Archive step** (expected, if anything is, on the
  first tagged run). Check the key's role first: cloud signing needs Admin. If
  the role is right and it still fails, fall back to the Android pattern: an
  Apple Distribution certificate as a base64 `.p12` plus an App Store
  provisioning profile in secrets, imported into a temporary keychain, with
  manual signing. More secrets, but no dependency on cloud signing.
