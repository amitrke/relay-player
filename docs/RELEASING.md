# Releasing to Play internal testing

How a build gets from this repo to testers' devices through Google Play, and
the one-time setup that makes it possible. The workflow is
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

1. Runs `flutter analyze` and `flutter test`.
2. Builds `app-release.aab` signed with the **upload key** from repository
   secrets. The `versionCode` is the workflow's run number, and the
   `versionName` comes from the tag if there is one.
3. Refuses to continue if the bundle is unsigned or has a debug certificate.
   `build.gradle.kts` falls back to the debug key when no key is configured,
   because local `flutter run --release` needs that, so this check is the one
   that stops a broken secret from getting through.
4. Keeps the bundle as a workflow artifact for 14 days.
5. Uploads it to the `internal` track, but only if `PLAY_SERVICE_ACCOUNT_JSON`
   is set. Without that secret the upload is skipped with a notice rather than
   failing the run, and that is what makes the first manual upload possible.

Triggers: run it by hand from the Actions tab, or push a tag:

```sh
git tag v1.0.0 && git push origin v1.0.0
```

A tag must look like `vMAJOR.MINOR.PATCH`. Anything else fails the run instead
of shipping a malformed `versionName`. Pushes to `main` do not release.

## Identity

- **Package name: `com.subnext.relay`.** It is permanent from the first upload.
  Sideloaded builds from before 2026-09-13 used `com.relayplayer.relay_player`
  and install alongside new ones, not over them. Their stored sources and
  credentials do not carry across.
- The Kotlin `namespace` is still `com.relayplayer.relay_player`. That is on
  purpose, and the comment in `build.gradle.kts` explains why.
- The iOS bundle identifier is still the generated `com.relayplayer.relayPlayer`
  and has not been decided. Decide it before the first App Store Connect
  record, for the same reason.

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
  identical on the track. The workflow now sets the release name to
  `<versionName> (<run number>)`. Tag real versions to move the first part.
- **No native debug symbols.** Play warns that the bundle contains native code
  without symbols. That is libmpv (PHASE0_FINDINGS.md Q5). It is a warning and
  not a rejection. Symbols start to matter when §16's crash reporting does.
