# Relay Player — Architecture & Delivery Plan

*Working title: **Relay Player** (a name that reflects what the app is: a general-purpose player that relays a stream from whatever source you point it at — Plex, a NAS, local files, or an optional IPTV provider — rather than an IPTV app specifically). Alternates if you want options: Vantage Player, Nomad Cast, Beacon Player, Wayfarer, Harbor Player, Junction Player, Kestrel, Anyplay, Waypoint Player. Verify namespace availability on both stores and a quick trademark check before finalizing.*

Scope for this plan: Plex (personal library) + local device storage + SMB/CIFS network shares as the flagship, always-visible sources, with Xtream Codes API + M3U/XMLTV support built in but gated behind an opt-in "Advanced sources" toggle (§8), plus optional AI features powered by a user's own AI provider key (§9). Targeting Android phone/tablet, iOS, and Android TV/Fire TV, intended for public app store release.

---

## 1. Read this first: store policy risk

This is the part most likely to sink the project if skipped, so it comes before architecture.

**The technical category is legal.** A "bring your own playlist/credentials" IPTV client is the same category as VLC, Kodi, Perfect Player, or TiviMate — a generic media player. Neither Apple nor Google prohibits media players, and neither requires you to vet what URL a user types into a login field.

**The practical risk is real, independent of how clean your code is.** IPTV-category apps — even ones that are pure, content-neutral tools that merely play whatever URL a user supplies — have historically faced elevated review scrutiny and occasional removal from both stores following rights-holder complaints, sports-event-driven enforcement sweeps, and platform policy judgment calls about an app's primary purpose. Apple's App Store Review Guidelines don't have an "IPTV" clause specifically, but several existing rules bite: **2.3.1** (an app can be removed for promoting content/services it doesn't actually offer, if review deems the primary use case is unauthorized streaming), **5.0 "Legal"** (apps must comply with law everywhere they're distributed and won't be approved if they facilitate clearly illegal activity), and generic **4.2 minimum-functionality** scrutiny that Apple applies more aggressively to "just a player" apps than Google does.

**Decisions made to manage this risk (detailed in their own sections below):**

1. **Lead with Plex, local storage, and SMB — not IPTV.** Onboarding, the home screen, and store screenshots/description default to the general media-player experience. This gives the app a genuine, defensible "primary purpose" that isn't IPTV, the same way VLC is judged as a neutral tool rather than a piracy vector even though it can play anything.
2. **IPTV (Xtream/M3U) ships in the binary but is opt-in and hidden by default** (§8) — absent from onboarding, navigation, and marketing until a user explicitly enables "Advanced sources" in Settings. This is real, bounded risk reduction: it improves the primary-purpose framing, reduces the odds of being swept up in keyword-based automated triage or "best IPTV apps" discovery, and — most practically — keeps the feature architecturally decoupled enough that it could be disabled via an update without touching the core app if it ever draws a complaint.
3. **This does not exempt the app from disclosure to Apple's human reviewers.** Apple requires full functionality disclosure and working demo credentials for any account-gated feature (standard App Review Information / demo-account requirement under Guideline 2.1) — the IPTV feature and a working Xtream test account must be described in App Review submission notes regardless of how deep it's buried in Settings. Concealing it from the reviewer would be a worse violation than disclosing it.
4. **A "Provider Profile" import feature (§8.3) is data-only, never code** — a URL points to a JSON manifest the built-in Xtream/M3U client reads to pre-fill a connection form. It is explicitly not a downloadable plugin: apps that fetch and execute remote code are barred on iOS (Guideline 2.5.2, "may not download, install, or execute code which introduces or changes features or functionality") and flagged under Google Play's Device and Network Abuse policy ("downloading executable code from unauthorized sources") — and structurally resemble malware loader patterns that both platforms' automated scanning is built to catch. Treat this as a hard boundary, not a gray area.
5. Expect Play Store review and occasional post-publish DMCA-style takedown requests as an ongoing operational reality even with the above mitigations, not a one-time review gate. Budget for a fast counter-notice / reinstatement process.
6. Don't use real broadcaster/channel names, logos, or sports branding anywhere in your own marketing, screenshots, or app icon — that remains the single biggest trigger for both platforms' review, independent of the gating decision.
7. **Don't request Android's "All files access."** Google Play explicitly lists generic media playback under *invalid* uses of `MANAGE_EXTERNAL_STORAGE` ([Play Console Help](https://support.google.com/googleplay/android-developer/answer/10467955?hl=en)) — §7.1 covers the compliant alternative (`MediaStore` + Storage Access Framework).
8. **AI features (§9) carry their own, separate disclosure obligations if a cloud AI provider is used** — Apple's Guideline 5.1.2(i) requires naming the provider and getting explicit pre-transmission consent. This is unrelated to the IPTV risk above; treat it as its own compliance checklist item, not something the Advanced Sources gating covers.

None of this blocks building the app — it just means "publish to app stores" needs its own checklist alongside the engineering one. Section 13 (roadmap) and Section 15 (testing) turn this into concrete backlog items.

---

## 2. High-level architecture

**Foundational decision: this app has no backend.** Every source is user-supplied, every credential is device-local, every AI call goes directly from the device to the user's own provider. There is no server of ours in any data path. This is a deliberate architectural commitment, not a gap to be filled in later, and it pays for itself several times over: no server costs, no data-controller obligations under GDPR, nothing to subpoena or seize when a rights-holder complaint arrives (§1.5), and a genuine privacy story that reinforces the neutral-tool framing the whole store-policy strategy rests on. §16 covers the one narrow, deliberately-bounded exception (crash reporting and a remote kill switch) and lists what must never be added.

Layered, feature-first structure — standard for a Flutter app this size:

```
lib/
  core/            # theming, routing, error handling, env config
  data/
    xtream/         # Xtream Codes API client + DTOs (compiled in, gated by feature flag)
    m3u/             # M3U/M3U8 + XMLTV parser (gated by feature flag)
    provider_profiles/ # Provider Profile fetch + schema validation (data-only importer, §8.3)
    plex/            # Plex auth (PIN flow), server/library discovery, playback sessions
    filesystem/      # MediaStore/SAF local access, SMB client, local HTTP proxy bridge
    ai/              # AiProvider clients: text generation + transcription, per provider (§9)
    local/           # Hive/Isar boxes: accounts, favorites, history, EPG cache, feature-flag/consent state
  domain/
    models/          # Account, Channel, Movie, Series, Episode, EpgProgram, FsEntry, AiProvider
    repositories/     # ContentRepository (Xtream, M3U, Plex) + FileSystemRepository (local, SMB)
  features/
    accounts/         # add/switch/remove sources across all protocols
    advanced_sources/  # the opt-in gate: toggle + Xtream/M3U account UI + Provider Profile import (§8)
    live_tv/            # only reachable when Advanced Sources is enabled
    movies/
    series/
    local_network/       # folder-tree browsing UI for local storage + SMB shares
    epg/                  # only reachable when Advanced Sources is enabled
    ai_assistant/          # AI provider settings, consent dialogs, search/recommendations UI (§9)
    player/                 # playback screen + controls, subtitle generation/translation entry points
    favorites_history/
    search/                  # extended with AI-assisted natural-language mode when a provider is configured
    settings/
  platform/
    mobile/                  # phone/tablet layouts
    tv/                       # Android TV / Fire TV leanback layouts, D-pad focus handling
```

**State management:** Riverpod (or Bloc if your team already standardizes on it) — either works fine here; Riverpod tends to reduce boilerplate for a content-repository-driven app like this. A simple `advancedSourcesEnabledProvider` boolean (persisted in local storage) gates route visibility and Home tab composition — straightforward to implement, no build-time flavoring needed since it's a runtime toggle, not a compile-time one.

**Two repository shapes, not one.** Xtream, M3U, and Plex all fit a `ContentRepository` interface — `getLiveChannels()`, `getMovies()`, `getSeries()` — because they're all fundamentally category/item catalogs. Local storage and SMB shares are a *tree*, not a catalog: folders containing files and other folders, with no inherent "movie" vs "series" categorization. That gets its own `FileSystemRepository` interface (`listDirectory(path) -> List<FsEntry>`) and its own UI surface (§12) rather than being merged into the Movies/Series tabs the way Plex is.

---

## 3. Data model (core entities)

| Entity | Key fields | Notes |
|---|---|---|
| `Account` | id, name, protocol (`xtream` \| `m3u` \| `plex`), host, username, password, m3uUrl, epgUrl, plexToken, plexServerId | Catalog-shaped sources; stored encrypted at rest (see §14). Xtream/M3U accounts only creatable when Advanced Sources is enabled (§8) |
| `NetworkShare` | id, name, protocol (`smb`), host, shareName, username, password, domain | SMB connection profile — separate from `Account` since it's tree-shaped, not catalog-shaped |
| `Category` | id, name, type (live/vod/series) | From Xtream categories, inferred M3U group-title, or Plex library section |
| `Channel` (live) | streamId, name, logoUrl, categoryId, epgChannelId | Xtream/M3U only — stream URL built as `{host}/live/{user}/{pass}/{streamId}.{ext}` |
| `Movie` (VOD) | streamId, name, posterUrl, plot, year, rating, containerExt | Xtream: `get_vod_streams`/`get_vod_info`. Plex: library item of type `movie` |
| `Series` | seriesId, name, posterUrl, plot, cast, genre | Xtream: `get_series_info` seasons/episodes. Plex: library item of type `show` |
| `Episode` | id, seriesId, season, episode, streamId | |
| `EpgProgram` | channelId, title, start, end, description | Xtream `get_short_epg` or parsed XMLTV — not applicable to Plex or filesystem sources |
| `FsEntry` | path, name, isDirectory, sizeBytes, mimeType, sourceId | A file or folder under a `NetworkShare` or local device root |
| `ProviderProfile` | name, protocol, hostTemplate, portTemplate, iconUrl, notes | Ephemeral import shape (§8.3) — parsed from a fetched JSON manifest and used to pre-fill an `Account` form; not persisted itself |
| `AiProvider` | id, name, kind (`anthropic` \| `openai` \| `gemini` \| `openai_compatible` \| `local`), apiKey, baseUrl, model, capabilities (textGeneration/transcription) | Stored encrypted at rest like other credentials; `apiKey` nullable for `local` (§9) |
| `AiConsentRecord` | providerId, dataCategory, grantedAt | One row per (provider, data-category) the user has explicitly consented to, per Apple 5.1.2(i) (§9.3) |
| `FavoriteItem` | itemType, itemId, accountId (or sourceId) | |
| `HistoryItem` | itemType, itemId, positionSeconds, lastWatchedAt | Plex can additionally sync this server-side (§6); filesystem items keyed by path |

Local persistence: **Isar** or **Hive** for these (fast, no native SQL needed); avoid `sqflite` unless you specifically want relational queries — this data is document-shaped.

**Credential storage rule — be precise about this, it's an easy and serious mistake.** The secret-bearing fields above (`password`, `plexToken`, SMB `password`, `apiKey`) are shown in the entity tables to describe the *logical* model. They must never be written into the Isar/Hive record. **Neither Isar nor Hive is encrypted at rest by default** — a Hive box is a plain file on disk, and enabling Hive's AES option still leaves you holding the key. The rule:

- Secrets live **only** in `flutter_secure_storage` (Keychain on iOS, EncryptedSharedPreferences/Keystore on Android), keyed by the owning entity's `id`.
- The Isar/Hive record persists everything else (id, name, protocol, host, username, server id) and holds *no* secret material — the repository layer joins the two on read.
- This also makes credential deletion atomic and auditable, which matters for the consent-revocation flow in §9.3.

---

## 4. Xtream Codes API integration

Core endpoints you'll call against `{host}/player_api.php`:

- `?username=&password=` — auth + account/server info (expiry, status, `is_trial`, `allowed_output_formats`)

**🔴 `max_connections` is a player-lifecycle constraint, not a Settings detail.**
Phase 0 measured a real line with `max_connections: 1`, which is the common
case. One concurrent stream, total. The player must therefore guarantee it
never holds two open at once:

- **Channel zapping must stop the current stream before opening the next**, not
  open-then-stop. The natural implementation — start the new one, then tear the
  old one down — is the wrong one here, and fails in a way that looks like a
  flaky provider rather than a client bug.
- No preview-while-playing, no second window on desktop, no picture-in-picture
  of a *different* channel.
- A dead channel that never yields a frame must **release the connection on
  timeout** (§10), or it burns the user's only slot.
- A crash or force-quit can leave the connection held server-side until it
  times out, so the next launch fails with no visible cause. Surface
  `active_cons` and `max_connections` in Settings so the user can see this
  rather than guess.
- `&action=get_live_categories` / `get_live_streams&category_id=`
- `&action=get_vod_categories` / `get_vod_streams&category_id=` / `get_vod_info&vod_id=`
- `&action=get_series_categories` / `get_series&category_id=` / `get_series_info&series_id=`
- `&action=get_short_epg&stream_id=&limit=` (rolling EPG) — full-guide EPG is usually a separate XMLTV export endpoint (`{host}/xmltv.php?username=&password=`)

Stream URLs are constructed client-side, not returned by the API:
- Live: `{host}/live/{username}/{password}/{stream_id}.{ext}` (ext typically `ts` or `m3u8`)
- VOD: `{host}/movie/{username}/{password}/{stream_id}.{ext}`
- Series episode: `{host}/series/{username}/{password}/{episode_id}.{ext}`

Wrap all of this in `XtreamClient` with typed response models (`json_serializable` or manual `fromJson`), timeouts, and retry-once-on-5xx logic — IPTV panels are frequently flaky. This entire client is only reachable through the Advanced Sources gate (§8).

### 4.1 Catalogue scale and category filtering

Phase 0 measured a real panel and the numbers are far past what a naive
implementation survives (see PHASE0_FINDINGS.md Q6):

| Call | Items | Payload |
|---|---|---|
| `get_live_streams` | 15,951 | 5.3 MB |
| `get_vod_streams` | 69,397 | **26.2 MB** |
| `get_series` | 7,375 | — |
| categories (live / vod / series) | 466 / 156 / 83 | small |

Fetching, decoding and holding ~100,000 catalogue items is not viable on a
phone and is hostile on a Fire TV stick (§11). **The user does not want most of
it either** — 706 distinct groups, of which any given person cares about a
handful.

**The design: filter at the category level, and never fetch the rest.**

The ordering matters, because it is what turns this from a storage optimisation
into a bandwidth one:

1. Fetch **categories only** — `get_live_categories` / `get_vod_categories` /
   `get_series_categories`. Small, fast, and enough to show the user what
   exists.
2. Let the user choose which categories to keep.
3. Fetch streams **per selected category** — `get_vod_streams&category_id=N`,
   which §4 already lists — and never call the unfiltered endpoint at all.

This is strictly better than fetching everything and filtering afterwards: the
26 MB is never transferred, so the saving is in network, memory *and* storage
rather than storage alone.

**Selection UI — checkboxes first, patterns as a power tool.** A list of
categories with checkboxes is usable by everyone; a regex box is not, and this
app's primary-purpose framing (§1) is a general media player, not a developer
tool. So:

- The primary control is a searchable, checkable category list.
- A **pattern field is offered alongside it as a bulk selector** — type
  `^(NL|DE):` or `4K` to toggle many at once. It acts on the selection, it does
  not replace it, and the user always sees the resulting checkbox state before
  committing. Support plain substring matching as well as regex, and never let
  an invalid pattern fail anything — just match nothing and say so.
- Selection is **opt-in, not opt-out**. Default to nothing selected with a
  prompt to choose, rather than everything selected with a prompt to prune.
  With 706 groups, opt-out means a first run that downloads everything, which
  is the case being avoided. It also avoids a first-launch screen full of
  brand-named categories (PHASE0_FINDINGS.md Q4 — a real store-screenshot
  hazard under §1.6).
- Re-openable from Settings → Sources; changing it re-syncs only the delta.

**Even filtered, parse off the main isolate** — but see §5's revised guidance,
which Phase 0 also corrected: the rule is *don't move bulk data across an
isolate boundary*, not *always use `compute()`*.

This applies to Live and Series as much as VOD, and it lives behind the
Advanced Sources gate (§8) like the rest of the Xtream client.

## 5. M3U / XMLTV fallback

- Parse M3U with `#EXTINF` tag attributes (`tvg-id`, `tvg-logo`, `group-title`) to reconstruct categories and EPG linkage; a small hand-rolled parser is plenty (playlists are simple line-based text) — no need for a heavy package.
- Parse XMLTV (`.xml`/`.xml.gz`) for EPG; `xml` package + manual gzip decode covers it. Use the event/streaming parser, never a full DOM.

**Parsing rule — corrected by Phase 0 measurement. Read this before reaching for `compute()`.**

An earlier version of this plan said "always parse in a background isolate via
`compute()`". Measured against a real 40 MB playlist (167,862 entries), that
advice produces the *slower* implementation:

| | Main isolate | `compute()` |
|---|---|---|
| M3U, 40 MB | **422 ms** | **1,033 ms** ← 2.4× slower |
| XMLTV, 0.24 MB | 57 ms | 37 ms |

`compute()` spawns an isolate and **copies data across the boundary** — the
whole payload in, the whole result list back. On a large payload that copy
dominates and the parse itself is comparatively cheap. The crossover is payload
size, which is why the small XMLTV file shows the opposite result.

Both figures above are unacceptable for different reasons: 422 ms on the main
isolate is ~25 dropped frames, a visible freeze, so staying on the main isolate
is not the answer either.

**The actual rule is: don't move bulk data across an isolate boundary.**

- Stream the download *into* a long-lived isolate rather than materialising a
  40 MB string and handing it over.
- Parse there, and return only what the UI needs — compact records, or better,
  write straight into the on-disk cache from inside the isolate and return a
  count.
- Reserve `compute()` for CPU-heavy work on *small* inputs, which is the
  opposite of this shape.
- Combine with §4.1 category filtering so the bulk payload is never fetched at
  all — the cheapest parse is the one you skip.

This lands hardest on Fire TV (§11), the weakest hardware in the matrix, so
treat it as a correctness requirement rather than an optimisation to revisit.
- Because M3U carries no VOD/series structure, treat M3U-sourced content as "Live only" in the UI unless `group-title` conventions clearly separate Movies/Series (common but not guaranteed) — set expectations in onboarding copy rather than guessing wrong.

**🔴 EPG data quality: plan for an empty guide, because it is the likely case.**

Phase 0 measured one real provider and the guide could not function at all:

| Measure | Result |
|---|---|
| Live channels with no `tvg-id` (M3U) | **166,402 / 167,862 — 99.1%** |
| Live channels with no `epg_channel_id` (API) | 14,491 / 15,951 — 91% |
| XMLTV export | 1,544 `<channel>`, **0 `<programme>`** |
| Channel id quality | `AMC.us` reused for every "ESPN+ EVENT" entry |

Two independent failures — almost nothing is linkable, and there is no schedule
data to link it to. This is a provider-data problem rather than an app bug, but
the app owns the consequence:

- The EPG guide (§12 screen 7) **must have an explicit, explained empty state**.
  An empty grid with no explanation reads as broken software, and this will be
  many users' first impression of the feature.
- Say which of the two failed — "this provider supplies no guide data" is
  different from "none of your channels carry a guide id", and only the first
  is worth contacting the provider about.
- Do not gate access to channels on guide data. Category navigation is
  independent and *does* work: `group-title` was present on all but 9 of
  167,862 entries.
- Treat a populated guide as the exception when estimating the value of EPG
  work in §13.
- Also gated behind Advanced Sources (§8).

## 6. Plex integration (personal library)

Scope decision: **personal library only** (Movies/TV Shows/Music from a user's own Plex server or servers shared with them) — not Plex's Live TV/DVR feature, which is Plex Pass– and tuner-gated and would add scope for a small slice of users. It can be revisited as a later phase if there's demand.

**Status of the API:** Plex exposes a developer portal (`developer.plex.tv`) but is explicit that it is "not officially reviewing, approving, or endorsing community developer-built tools at this time" — so there's no certification gate blocking basic access with a user's own token (same trust model as Xtream credentials), but also no official support guarantee or SLA. Treat it like a well-documented community API, not a formal partner integration.

**✅ Phase 0 verdict: adopt `dart_plex`, with two mandatory workarounds and standing caution.**

Validated against a real server: PIN flow, server discovery, library browse and
direct play all work, and quickly (PIN 347 ms, resources 444 ms, sections
956 ms, direct play to first frame 244 ms). Two defects were found within an
hour of first use, **both of which silently produce a broken flow rather than
an error**:

1. **`createPin()` must be called with `strong: false`.** The default
   (`strong: true`) yields a 25-character code, but `plex.tv/link` accepts only
   the 4-character form — so the default hands the user a code they cannot
   enter anywhere. The package's own docstring promises a 4-character code,
   contradicting its own default.
2. **`universalVideoUrl()` omits `hasMDE=1`, so transcode cannot work at all.**
   PMS 1.43 rejects the universal endpoint with a bare `HTTP 400` without it.
   Append `&hasMDE=1` to the returned URL and add `'hasMDE': '1'` to the
   decision params. The string `hasMDE` appears nowhere in the package.

**Also: "direct play" is not the universal endpoint.** `universalVideoUrl(directPlay: true)` still routes through `/video/:/transcode/universal/`; the server reports *"App cannot direct play this item. Direct play is disabled."* Real direct play is the media **Part key** (`/library/parts/{id}/{ts}/file.mp4`) — a plain byte-range file, which is what this section describes and what media_kit handles like any progressive source. Walk `metadata → media → parts` to get it.

**Standing caution:** two defects in the two most important flows, found
immediately, says how little of this package has been exercised against a real
server. Verify every `dart_plex` call path against a real server before relying
on it, do not treat the docstrings as load-bearing, and keep the ~1 week
hand-rolled fallback costed and ready.

**Original assessment, retained for context:** [`dart_plex`](https://pub.dev/packages/dart_plex) is a pure-Dart client (no native plugins, so it works across all target platforms) whose documented surface covers PIN-flow auth, server discovery, library browsing/search/filtering, streaming URLs, transcode session management, playback reporting, and playlists. On paper it's exactly the right shape and would avoid re-implementing the protocol from scratch.

**But apply the same skepticism here that §7.2 applies to `smb_connect` — more, in fact, because this is the flagship integration.** As of this writing `dart_plex` is at **v0.1.2, first published only days ago, with 4 likes and ~118 downloads**. It is pre-1.0, essentially unproven in the field, and has no track record of responding to breaking changes in Plex's API. A well-documented README is not evidence that the transcode-session lifecycle works against a real server under real conditions. Concretely:

- Treat it as a **Phase 0 spike item on equal footing with media_kit and SMB** (§13), tested against a real server for both direct play and forced transcode — not as a settled dependency.
- **Have the fallback costed before you start.** Plex's HTTP API is well enough documented publicly that hand-rolling the subset this app actually needs (PIN auth, `/resources`, library sections, item metadata, transcode start/ping/stop, scrobble) is a bounded piece of work — roughly a week — not a research project. The `dart_plex` decision is therefore reversible; just decide it deliberately in Phase 0 rather than discovering it in Phase 1.
- Whichever way it goes, keep all Plex protocol detail behind the `ContentRepository` implementation so swapping the client later touches one directory.

**Auth flow (materially different from Xtream/M3U — needs its own "Add account" UI variant):**
1. App requests a PIN from plex.tv, gets a code + a link.
2. User opens the link (in-app webview or system browser) and approves the app via their existing Plex account login.
3. App polls plex.tv until the PIN resolves to an `X-Plex-Token`.
4. Standard headers (`X-Plex-Client-Identifier`, `X-Plex-Product`, `X-Plex-Version`, `X-Plex-Device`, `X-Plex-Device-Name`) are sent on every request — worth centralizing in one interceptor.
5. App calls plex.tv's resources endpoint to list the user's accessible server(s) — their own plus anything shared with them — and lets them pick one (or auto-pick if there's only one).

**Content mapping into the domain model:** Plex library *sections* (Movies, TV Shows, Music, etc., user-defined per server) map to `Category`; items within map to `Movie`/`Series`/`Episode` per §3. Metadata (poster art, plot, cast, year, rating) comes directly off each item's payload — richer than what Xtream typically provides.

**Playback — the one place Plex is more complex than Xtream:**
- *Direct play*: Plex serves the original file via HTTP range requests when the format/codec is compatible with the requesting device — simple, media_kit handles this like any progressive/byte-range source.
- *Transcode*: when direct play isn't viable, the server starts a transcode session and serves HLS output. Your player layer needs to: start the session, send periodic keep-alive pings while playing (Plex sessions time out without them), and explicitly stop the session on pause/exit — this is real lifecycle logic that Xtream/M3U don't need at all. Build this as a `PlaybackSessionController` used only by the Plex repository implementation, so it doesn't leak complexity into the Xtream/M3U paths.
- Progress reporting: Plex supports scrobble/progress-update calls so "continue watching" state can live server-side (synced across the user's other Plex apps too) in addition to your local `HistoryItem` cache — a nice differentiator worth doing since it's cheap once the session controller exists.

**UX implication:** a Plex account effectively contributes its own Movies/Series categories to the always-visible Movies/Series tabs — this is flagship functionality, not gated behind Advanced Sources.

## 7. Local device storage and SMB/CIFS network shares

This is the VLC-style feature: playing whatever's already on the device or on a home NAS/Windows share, no account/login model at all beyond (for SMB) server credentials. Also flagship, always-visible functionality — not gated. Scoped to **local storage + SMB** for this phase; FTP, WebDAV, and UPnP/DLNA discovery follow the same patterns below and can be added later as separate `FileSystemRepository` implementations if there's demand.

### 7.1 Local device storage — compliant approach

Per §1.7, this must avoid `MANAGE_EXTERNAL_STORAGE`. Two complementary pieces, both standard for compliant media players:

- **Library scan**: query Android's `MediaStore` API (`MediaStore.Video`, `MediaStore.Audio`) for a "everything on this device" view — this is the privacy-friendly, Play-policy-approved way to enumerate media files without broad storage access. Needs a small platform channel or a maintained plugin wrapping `MediaStore` queries.
- **Folder browsing**: Storage Access Framework via `file_picker`'s directory picker (`getDirectoryPath`), which returns a persistable URI you keep permission to across app restarts (`takePersistableUriPermission` under the hood) — lets a user point at "my Videos folder" once and have it stick, without ever granting the app broad filesystem access.
- **iOS equivalent**: `UIDocumentPickerViewController` in folder mode, with a security-scoped bookmark persisted for repeat access. Worth validating during the spike whether a folder the user added as a network location inside iOS's Files app (iOS supports adding SMB/WebDAV shares since iOS 13) is reachable this way — if so, iOS may not need your own SMB client at all, only Android and desktop would.
- **iOS also needs a second, separate path for video already in Photos.** The document picker does not see the Photos library, which on iOS is where a large share of a user's own video actually lives — so "play what's on my device" is half-broken without it. Use `PHPickerViewController` (the modern, permission-free picker: the user selects, and you receive only what they picked, with no library-wide authorization prompt). This is the closest iOS analogue to Android's `MediaStore` scan and should be treated as a required piece of §7.1 rather than an extra.

### 7.2 SMB/CIFS — the harder case

**✅ Phase 0 verdict: the design below is correct. Build it as written.**

- **Native `smb://` does not work** — but not for the reason predicted. libmpv
  does not report a missing `libsmbclient`; it refuses the URL as a safety
  policy: *"Refusing to load potentially unsafe URL from a playlist."*
  `--load-unsafe-playlists` would bypass that and **must not be used** (§10).
- **`smb_connect` 0.0.9 works**, first try, on every operation: `connectAuth`
  177 ms, 17 shares in 124 ms, `listFiles` 134 ms, and — the make-or-break case
  — a random-access read returning the full 64 KB from offset 121,929,919 in
  142 ms. Without working seeks the bridge could only stream start-to-finish.
- **The loopback bridge works and libmpv seeks through it.** Three distinct
  range requests were observed, and the middle one is the proof: libmpv jumped
  to the final 16 KB to read the container index, then returned to byte 5,963
  to begin playback. A bridge that ignored `Range` would have looked correct on
  the first request and failed precisely there. **Implementing `Range` is not
  optional.**

**Still untested — failure behaviour, not the happy path.** The remaining risk
is what `smb_connect` does when the network misbehaves, which is Phase 2 scope:
NAS disappearing mid-playback, Wi-Fi drop and reconnect, whether a dropped
connection surfaces an error or hangs, and whether a connection survives a full
episode. Budget error-handling time for these rather than assuming the clean
results above generalise.

- media_kit/libmpv documents local file and HTTP/HTTPS support; it does **not** document SMB support, and prebuilt libmpv binaries typically aren't compiled with `libsmbclient`. Treat "does `smb://` just work" as unvalidated, not assumed — test it directly in the Phase 0 spike before building anything else around it, since the answer changes the design.
- If direct support isn't there (likely outcome): implement the SMB client in Dart with [`smb_connect`](https://pub.dev/packages/smb_connect) (cross-platform, SMB 1.0/CIFS/2.0/2.1 — but lightly maintained: 15 likes, ~750 downloads, last published ~19 months ago as of this writing, so budget spike time to confirm it actually works reliably rather than trusting the package description outright), and bridge playback through a **local loopback HTTP server**: spin up a tiny server on `127.0.0.1` (the `shelf` package is enough) that reads bytes from the SMB client and re-serves them as a normal HTTP byte-range stream; media_kit then just opens `http://127.0.0.1:PORT/...` like any other HTTP source. This is the same pattern VLC itself uses internally, and it means every non-catalog protocol you add later (FTP, WebDAV if it also turns out to need it) reuses the same bridge instead of teaching the player engine new protocols one at a time.
- SMB connection lifecycle (connect, handle drops/reconnects, close) is real state to manage — model it the same way as the Plex `PlaybackSessionController` from §6 rather than inventing a second pattern.
- Credentials (host, share name, username, password, domain) go in `NetworkShare` (§3), stored via `flutter_secure_storage` like every other credential in the app.

### 7.3 UX implication

Local/SMB content doesn't get merged into Movies/Series the way Plex does — it's shown as its own "Local & Network" section with breadcrumb folder-tree navigation (§12), since an arbitrary folder has no inherent movie/series categorization. Favorites and continue-watching still work at the individual file level.

## 8. Advanced Sources: gating IPTV and importing Provider Profiles

This section is the answer to "IPTV shouldn't be a feature that ships front-and-center by default." It's built, tested, and shipped with the rest of the app — just not exposed until a user opts in.

### 8.1 Why an opt-in toggle over the alternatives

Two other approaches were considered and set aside for this version:

- A true on-demand *download* of the IPTV feature (Android's Play Feature Delivery via Flutter's [deferred components](https://docs.flutter.dev/perf/deferred-components)) is real and store-sanctioned, but Android-only — Flutter deferred components have no iOS equivalent — so it can't be the whole-app answer, only a possible future Android-specific enhancement.
- A fully separate companion app (IPTV as its own listing, talking to the core app via inter-app communication) gives genuine risk isolation but roughly doubles store-ops overhead (two listings, two review pipelines) and has a much weaker inter-app mechanism on iOS. Worth revisiting later if the single-toggle approach proves insufficient, but not the starting point.

The opt-in toggle is the cheapest option that still captures the main benefit: it controls what onboarding, the home screen, and store marketing look like, which is what the "primary purpose" judgment calls in §1 actually hinge on. It doesn't hide the feature from Apple's reviewers (§8.4) or from static analysis of the binary — see §1's honest accounting of what this does and doesn't buy you.

### 8.2 Behavior

- Settings gains an "Advanced sources" section containing a single toggle, off by default on first install.
- While off: no Live TV tab, no Xtream/M3U entries in "Add source," no EPG guide screen — they simply don't exist in the navigable app.
- Turning it on surfaces a short, specific disclaimer ("you're about to connect a third-party IPTV provider or playlist using credentials you supply; the app does not provide, host, or endorse any content or provider") that must be acknowledged before the Xtream/M3U account forms become reachable — separate from, and in addition to, the general onboarding disclaimer in §1.3, since this is a materially different consent moment.
- The toggle is freely reversible; turning it back off hides the tab/entries again but doesn't delete configured Xtream/M3U accounts, so re-enabling restores them.

### 8.3 Provider Profile import (data-only)

A convenience for adding a provider without hand-typing host/username/password: paste a URL to a small JSON manifest, the app fetches and parses it, and pre-fills the Xtream or M3U account form. This is explicitly **not** a plugin-loading mechanism — see §1.4 for why that distinction is a hard line, not a style choice.

- Fetch over HTTPS only; parse against a strict schema (`ProviderProfile` in §3: name, protocol, host/port template, icon URL, free-text notes) and reject anything with unexpected fields or malformed values.
- Never interpret any field as code or a template that executes — every field is a plain string or number consumed as form-fill data, nothing more.
- Cap what a profile can influence: it can only pre-fill *your* existing Xtream/M3U account form fields, never reach outside that (no local file paths, no arbitrary network destinations beyond the one host field, no app-behavior changes).
- **We do not host, curate, or link a directory of provider profiles — explicitly and permanently out of scope.** Maintaining a public repo of profile JSON files (or an index listing several) was considered and rejected: publishing a list of IPTV providers moves the project from "neutral tool the user points wherever they like" to "curator of provider sources," which is exactly the primary-purpose framing §1 spends its entire risk analysis defending. It would be the single most legally exposed asset in the project, it would be the first thing cited in a rights-holder complaint, and it buys only a small typing convenience. The importer accepts any HTTPS URL the user already has; where that URL came from is not our concern and must not become our concern.
- Lives in `data/provider_profiles/` (§2) and is only reachable once Advanced Sources is enabled, alongside the manual Xtream/M3U forms it feeds into.

### 8.4 Store submission checklist item

Regardless of the toggle, Apple's App Review Information must disclose the IPTV feature and include working Xtream demo credentials so the reviewer can test it directly — this is a hard requirement (§1.3), not optional even though the feature is hidden from casual users. Prepare a standing demo/trial Xtream account for this purpose well before submission.

## 9. AI Features (bring-your-own AI provider key)

Same ethos as the rest of the app: no built-in paid AI service, users connect their own provider. Scope for this version: natural-language library search, recommendations drawn from the user's own library and history, auto-generated subtitles for files that lack them, and subtitle translation.

### 9.1 Two different technical shapes, one settings surface

- **Text generation** (search, recommendations, translation): a prompt/context in, text out. Anthropic (Messages API), OpenAI (Chat Completions), Google Gemini (`generateContent`), a generic OpenAI-compatible endpoint (covers most self-hosted or third-party OpenAI-API-shaped services in one config), and a local/self-hosted option (e.g. Ollama on the user's own LAN) all fit one `TextGenerationClient` interface, implemented per provider — the generic-compatible and local options can share one implementation class parameterized by base URL and optional key, since they speak the same wire format.
- **Transcription** (auto-generated subtitles): audio in, timestamped text out. Not every provider above offers this — initially only OpenAI's Whisper-style endpoint is planned; Anthropic and Gemini don't currently expose a comparable endpoint, so the UI for this specific feature should only list transcription-capable providers, not every configured provider. Reconfirm provider capabilities at build time since this changes.

`AiProvider` (§3) stores provider kind, key (nullable for local), base URL, model, and which capabilities it supports; credentials go through `flutter_secure_storage` like every other credential in the app. No provider configured means no AI UI surfaces anywhere — each AI-touched feature independently checks for a capable provider before showing itself.

### 9.2 Feature designs

- **Natural-language search**: the user's query plus a compact index of library metadata (titles, years, genres, short plot text — not full file paths or anything beyond what's already shown in the UI) goes to the configured text-generation provider, which returns ranked matches the app resolves back to real library items.
- **Recommendations**: same client, prompted with a summarized view of library contents plus recent `HistoryItem` entries, explicitly scoped to "recommend from what's already in your connected sources" rather than suggesting content to acquire — keeps this clearly a library-navigation aid, not something that reads as sourcing content.
- **Auto-generated subtitles**: extract the audio track from a local/SMB/VOD file, send to a transcription-capable provider, cache the result as a standard `.srt`/`.vtt` alongside the played item (or in local storage keyed by file, since write access back to the source isn't guaranteed). This is a long-running job with progress UI, not an instant round trip — plan the player screen's "generate subtitles" entry point accordingly. **Two hard constraints shape this feature and neither is optional:**

  - **The 25 MB request cap.** OpenAI's transcription endpoint rejects uploads over 25 MB, and the newer `gpt-4o-transcribe` models keep that cap (and add their own audio-duration limits). A feature-length film's audio track exceeds this even as compressed mono — so the pipeline is necessarily *extract → downmix to mono, low-bitrate → **split into chunks** → transcribe each → re-stitch with corrected timestamps*. Chunk on silence boundaries where possible and overlap adjacent chunks by a few seconds so words aren't cut mid-utterance, then de-duplicate across the overlap. Budget for this explicitly: chunking and timestamp re-stitching is the majority of the work in this feature, not a detail, and the §13 Phase 3.5 estimate should reflect that.
  - **iOS will kill this job in the background.** iOS does not grant arbitrary long-running background execution for an upload-and-poll loop; a 90-minute movie's transcription will be suspended if the user leaves the app. Either scope it as foreground-only with explicit "keep this screen open" UX and a resumable job (checkpoint completed chunks so an interrupted run resumes rather than restarts), or drive the uploads through a background `URLSession` transfer, which the system *will* continue — but which constrains you to plain file uploads and callback handling. Decide which before building; retrofitting resumability is painful. Android is far more permissive here (a foreground service covers it), so this is an iOS-specific design constraint, not a shared one.
- **Subtitle translation**: send existing subtitle text (already segmented, small payload) to the text-generation provider with a target-language instruction; cache the translated track the same way as generated subtitles.

### 9.3 Apple Guideline 5.1.2(i) — data-sharing disclosure (cloud providers only)

Apple's guideline (effective November 2025) requires naming the specific third-party AI provider and getting explicit, pre-transmission, per-category consent before any user data is sent to it — this is now a concrete, current requirement, not a general best practice:

- Settings → "AI Features" lists each configured provider by its real name (OpenAI, Anthropic, Google), never generic "AI service" language.
- The first time a specific feature is about to send data to a specific cloud provider, show a consent dialog naming both the provider and the data category (e.g., "Your search text and library titles will be sent to OpenAI" / "Audio from this file will be sent to OpenAI for transcription") — a separate consent moment per feature × provider pairing, not one blanket AI opt-in. Record each grant in `AiConsentRecord` (§3).
- Settings retains a per-integration on/off control so users can review and revoke consent later without deleting the stored key.
- **The local/Ollama and generic-compatible-pointed-at-localhost paths don't trigger this flow at all**, since no data leaves the device/local network to a third party — worth defaulting new users toward this option in the UI copy, since it also sidesteps this entire consent-flow requirement for that path.

### 9.4 Google Play considerations

Play's AI-Generated Content policy is comparatively light for this use case: it centers on not producing offensive/prohibited output, and appears to give lighter treatment to apps using AI to enhance an existing feature (search, recommendations, subtitles) rather than standalone generative-AI apps. Still worth building in basic guardrails — a system prompt scoping responses to library-search/recommendation/subtitle tasks, and a simple way for a user to flag unexpected AI output. This is an actively evolving policy area (Google has signaled further AI-app policy tightening through 2026) — re-verify current requirements shortly before submission rather than relying on this snapshot.

### 9.5 UX note

AI features are independent of Advanced Sources (§8) — they apply across Plex/local/SMB just as much as Xtream/M3U, so they're not part of that gate and remain available (once a provider is configured) regardless of whether IPTV is enabled.

## 10. Video playback engine

**Recommendation: [`media_kit`](https://github.com/media-kit/media-kit)** (libmpv-backed) over `video_player`/`better_player` (ExoPlayer/AVPlayer-backed) as the primary engine, specifically *because* this is a multi-source app:

- IPTV streams are frequently raw MPEG-TS over HTTP with inconsistent muxing, non-standard HLS variants, and mid-stream codec/bitrate hiccups from cheap panels. `libmpv` (via media_kit) is *reported* to tolerate this better than ExoPlayer/AVFoundation. **⚠️ Phase 0 did not evidence this claim** — the panel tested emitted clean, well-formed TS (100/100 packets carried the `0x47` sync byte), so it exercised nothing ExoPlayer would have failed. Either test a worse panel before relying on this argument, or drop it and stand on the evidenced reasons below, which are sufficient on their own.
- It also handles Plex's two playback modes (direct-play byte-range files in almost any container, and HLS transcode output), arbitrary local files, and the local-proxy HTTP streams from §7 without needing a second engine — one player pipeline for every source type in this plan.
- media_kit supports desktop too, which costs nothing now and is useful if you ever want a companion desktop build.
- Trade-off: slightly bigger binary size (bundles libmpv) and you lose iOS/tvOS's native hardware-decode-everywhere guarantees that AVPlayer gives you — worth a short spike (3–5 days, covering Plex and SMB as well as Xtream) against 2–3 real provider streams, a real Plex server, and a real SMB share before committing, since this is the one architectural decision worth validating empirically before building the rest.
- Fallback plan if media_kit underperforms on a specific source: `better_player` (ExoPlayer-based) as a per-stream fallback engine, selected automatically on playback error.
- **The ffmpeg licensing decision belongs here, in Phase 0 — not in Phase 3.5.** §14 flags the LGPL-vs-GPL choice against the transcription pipeline, but that framing is wrong on sequencing: **media_kit bundles libmpv, which bundles ffmpeg**, so you take on the dependency and its license the moment you pick the player engine — before any AI feature exists. Resolve it once, at engine selection, and let the transcription pipeline inherit that decision rather than re-litigating it later. The practical rule: use an **LGPL** build and link it **dynamically**, keeping any GPL-only components (notably `libx264`/`libx265` encoders, which this app has no reason to need — it decodes, it doesn't encode) out of the build entirely. A statically-linked GPL build would impose GPL terms on the whole app, which is incompatible both with a permissively-licensed public repo and with App Store distribution.

**DRM is explicitly out of scope.** No Widevine, no FairPlay, no PlayReady. This bounds what "plays anything" means and should be stated plainly in onboarding copy and the store description: the app plays unencrypted media from sources the user connects. It cannot play protected commercial catalogs (Netflix, Disney+, and similar), and no amount of configuration will change that. Worth saying out loud because it is a recurring support question, and because it is quietly helpful to the §1 primary-purpose argument — an app with no DRM stack is transparently not attempting to be a commercial-catalog substitute.

**Phase 0 outcome: media_kit confirmed, on evidenced grounds.** It played, in
one pipeline: Xtream live MPEG-TS (first frame ~1.8 s, consistent across runs),
Plex direct play by Part key over HTTPS, and an SMB file through the §7.2
loopback bridge with correct byte-range seeking. That breadth — one engine for
every source in this plan — is the argument that survived contact with reality.

Two caveats recorded from the same work:

- **The bundled `libmpv-2.dll` is dated 2023-09-24** — over two years stale as
  of this writing. It bounds codec support and carries whatever CVEs that
  vintage has. Check for a newer media_kit before Phase 1 and re-check before
  release.
- **`smb://` is refused by libmpv** ("Refusing to load potentially unsafe URL
  from a playlist"), which is a safety policy rather than a missing protocol.
  `--load-unsafe-playlists` would bypass it and **must not be used** — it
  relaxes the check globally, for every source including untrusted IPTV
  playlists. Use the bridge (§7.2).

**🔴 Detecting playback: only the position counts.** Phase 0 produced two
confidently wrong conclusions from bad signals, and both are easy to repeat:

- `await player.open(url)` returning means the command was *queued*, not that
  anything opened. Errors arrive later on a separate stream.
- `videoParams` arriving means libmpv parsed the header and knows the
  dimensions. It fires even when decoding then stalls and the surface stays
  black.

The only trustworthy evidence that playback is happening is
**`player.state.position` advancing**. Any "is it playing", buffering
indicator, dead-channel timeout (§4) or error state in the app must be built on
that, not on the two signals above.

Player screen needs: play/pause/seek (VOD/series/Plex/local/SMB — Xtream/M3U live has no seek), audio/subtitle track selection (including AI-generated/translated tracks from §9), aspect ratio toggle, PiP (both platforms support it), background audio continuation, resume-from-history prompt, and the transcode/SMB session keep-alive/stop lifecycle from §6/§7.

## 11. Platform-specific notes

**Android phone/tablet** — baseline target: Movies/Series (Plex-merged)/Local & Network as the default flagship experience, with Live TV and EPG appearing only once Advanced Sources is enabled.

**Android TV / Fire TV** — not a resize of the phone UI. Needs: D-pad focus traversal (`FocusNode`/`FocusTraversalGroup` wiring throughout), 10-foot-UI sized text/tap targets, a leanback-style row-based home screen, and a separate `AndroidManifest` `<intent-filter>` + banner asset for the TV launcher. Plan this as its own feature-flagged layout tree under `platform/tv/`, sharing the domain/data layers (Xtream, M3U, Plex, filesystem, AI) but not the widgets. A folder-tree browser (§7.3) is more awkward with a D-pad than a grid — budget extra design time for it specifically on TV.

**Fire TV specifically — treat it as its own target, not a synonym for Android TV.** Three differences matter architecturally:

- **No Google Play Services.** Fire OS ships without GMS, so any dependency that requires it silently does nothing on your Fire TV users' devices. This directly constrains §16: Crashlytics and Remote Config work without Play Services and are therefore safe, while Firebase Cloud Messaging requires it and Firebase Analytics degrades without it. Verify this on real hardware rather than assuming — a crash reporter that reports nothing is worse than no crash reporter, because it makes you believe the build is stable.
- **It is the weakest hardware in the matrix.** A Fire TV stick has substantially less CPU and RAM than the phones you'll develop on. This is the device that makes the XMLTV isolate requirement (§5) non-negotiable, that will expose any main-isolate JSON parsing of large Xtream category responses, and where libmpv's software-decode fallback paths will hurt most. Profile here, not on a flagship phone.
- **Separate store, separate submission.** The Amazon Appstore is its own listing, its own review process, and its own policy surface — distinct from the Play Console work in §13 Phase 6. It is also, usefully, a third distribution channel that is not affected by a Play or App Store takedown, which is worth something given §1.5.

**iOS** — background audio entitlement + PiP entitlement need explicit setup; App Store review risk is the main iOS-specific item (§1, §8.4, §15).

**🔴 App Transport Security will block cleartext providers — decide the position before submission, not during.**

Phase 0 measured a real Xtream panel that is **HTTP-only** (`server_protocol:
http`, no `https_port`), and whose stream URLs **302-redirect to a second
cleartext host**. iOS ATS blocks cleartext HTTP by default, so a provider like
this simply will not load on iOS.

The available responses are all uncomfortable:

- **`NSAllowsArbitraryLoads`** — works, but Apple scrutinises it at review and
  expects written justification, and it weakens transport security for *every*
  connection the app makes, not just IPTV.
- **Per-domain exceptions** — impossible here, because the user supplies the
  domain at runtime and the stream redirects to a host neither they nor we knew
  in advance.
- **Refuse cleartext on iOS** — clean, defensible, and means some providers
  simply do not work on iOS while working on Android.

The awkward part is the justification itself: "users connect arbitrary
self-hosted servers, many of which are HTTP-only" is true, and it draws a
reviewer's attention to exactly the feature §8 is structured not to lead with.
Note that **Plex (`*.plex.direct`) and most NAS devices are HTTPS**, so the
flagship sources need no exception at all — this is almost entirely an
Advanced-sources problem, which is itself an argument for the third option.

Whichever is chosen, write the reasoning down before the iOS submission (§8.4,
§15) rather than improvising it in a review reply. Also the one platform where the Files-app SMB integration from §7.1 might let you skip a custom SMB client entirely — validate this early since it changes iOS scope meaningfully. tvOS is a natural follow-on later but is *not* the same codebase as Android TV's Flutter view — treat it as a future phase, not part of this build.

## 12. Screens (phone reference)

1. Onboarding / disclaimer — general framing only ("this app streams from sources you connect yourself — a Plex server, a home NAS or local files, or optionally an IPTV provider/playlist; we host no content"); no IPTV-specific language up front
2. Add source — Plex (PIN-link flow, §6) and Local & Network (device scan, folder picker, or SMB share, §7) always available; Xtream/M3U/Provider-Profile-import only appear once Advanced Sources is enabled (§8)
3. Home — Movies / Series / Local & Network tabs by default (Movies/Series merge across Plex accounts); Live TV tab appears only when Advanced Sources is on; continue-watching row, favorites row; search bar offers an AI natural-language mode once a text-generation provider is configured (§9.2)
4. Category → grid/list of movies/series, **or** breadcrumb folder browser for Local & Network
5. Detail (movie/series: poster, plot, seasons/episodes — richer metadata when sourced from Plex; live: EPG strip, Advanced Sources only; local/SMB file: filename, size, format, no metadata lookup by default; "Generate subtitles" / "Translate subtitles" actions appear when a capable AI provider is configured)
6. Player (full-screen, gesture + remote-friendly controls, subtitle track selector including AI-generated tracks)
7. EPG guide (grid: channels × time, "now/next") — Advanced Sources only
8. Search (cross Movies/Series/Local & Network always; Live TV included once enabled; AI natural-language mode per §9.2)
9. Settings — see §12.1 for the section breakdown

### 12.1 Settings sections

Reconciled against the Settings design canvas (artboards "09 · Settings ·
Phone" and "09 · Settings · Windows desktop"), which is the source of truth for
layout and copy; this list is the source of truth for *what exists*.

| Section | Contents | Ref |
|---|---|---|
| **Sources** | Connected Plex servers, network shares, and local folders, each with a one-line status (e.g. "Plex · 412 movies, 38 series", "SMB · connected", "Two folders · 94 files"). Add/remove/reconnect. Xtream/M3U accounts appear here **only** when Advanced sources is on | §6, §7 |
| **Appearance** | Theme (System / Midnight / Slate / Daylight / Amber) and accent colour | §12.2 |
| **Playback** | Engine preference, buffer sizes, resume behaviour, hardware-decode toggle | §10 |
| **Subtitles** | Default track language, styling, and where generated/translated tracks are cached | §9.2 |
| **AI features** | Configured providers (name, model, key status), and the per-feature × per-provider consent list | §9.3 |
| **Advanced sources** | The opt-in toggle plus its acknowledgement dialog; reversible, and turning it off preserves configured accounts | §8.2 |
| **Privacy and data** | Crash-reporting opt-in (§16), clear cache, clear history, and a plain statement that the app has no backend and no analytics | §16 |
| **About** | Version, licences, the general disclaimer, and links to the privacy policy | §1 |

Two structural points the design gets right and that are easy to lose later:

- **Advanced sources and AI features are independent switches.** Enabling one
  does nothing to the other. §9.5 says this in prose; the Settings layout has
  to keep them visually separate so it isn't read as one "power user" bundle.
- **Consent is listed per feature × provider, never as a single AI opt-in** —
  a row per pairing, each independently revocable while the key stays saved,
  exactly matching `AiConsentRecord` (§3). The design shows one feature
  deliberately *not* granted, which is the state that proves the granularity
  is real rather than decorative.

### 12.2 Theming

Not previously in this plan; added from the design canvas, which argues the
point correctly: **theme is a runtime setting, not a build-time palette.**

- Five options (System / Midnight / Slate / Daylight / Amber) plus an accent
  colour, applied via CSS-custom-property-style design tokens rather than
  hardcoded colours, so the TV layout tree (§11) inherits the same tokens
  without duplicating a palette.
- "System" must genuinely follow the OS light/dark setting, including changes
  made while the app is running.
- Appearance sits near the top of Settings because it is the section users
  actually visit; the compliance-shaped sections sit lower.

**Still to design (§13 gates on these, and they are the harder half):**

- **A TV artboard for Settings.** §11 is explicit that TV "is not a resize of
  the phone UI." The consent list is the specific problem: a multi-column
  table of feature × provider × data × date, navigated with a D-pad, is
  exactly the kind of surface §11 says to budget extra design time for. It
  likely becomes a vertical list of focusable cards rather than a table.
- Screens 1–8 above, none of which have artboards yet.
- Desktop is **not** a shipping target (§10 treats it as a possible future
  companion build, and Phase 0 found it carries a real toolchain cost) — treat
  the existing desktop artboard as a layout study, not a commitment.

## 13. Phased roadmap

**Timeline caveat — read before planning against these numbers.** The per-phase estimates below describe focused engineering time for someone already fluent in Flutter, and they sum to roughly 11–14 weeks. They do **not** include: the rework implied if a Phase 0 spike comes back negative (a hand-rolled Plex client, or the SMB proxy bridge, each add ~1 week); the rejection-and-resubmit cycle Phase 5 itself predicts; Amazon Appstore submission (§11); or the ordinary drag of TV focus-traversal debugging on real hardware. **If this is solo or part-time work, plan for roughly double the stated figures** and treat the phase boundaries — not the day counts — as the useful structure.

**Phase 0 — Validation — ✅ CLOSED 2026-09-11.** Full results in
[PHASE0_FINDINGS.md](PHASE0_FINDINGS.md); the consequences are folded into the
sections above. Outcome in one line: **every major technology choice held**, and
the phase paid for itself in the corrections it forced — the isolate rule (§5)
was backwards, `max_connections` (§4) is a lifecycle constraint rather than a
Settings detail, `dart_plex` needs two workarounds without which PIN and
transcode silently break (§6), iOS ATS blocks cleartext providers with no clean
answer (§11), and the EPG is likely to be empty for real users (§5).

Deferred to Phase 1, deliberately: **Q5, the Android-device questions** — SAF
persisted permissions surviving a reboot, `MediaStore` scanning, hardware
decode, and release APK/AAB size. These change implementation detail rather than
architecture, and need hardware that was not to hand.

Also still open: the transcode lifecycle end-to-end (`decision → ping → stop`,
with the `hasMDE=1` fix in place) — the specific risk being a leaked transcode
session on every user's server — and a second, worse Xtream panel to settle
§10's tolerance claim.

*Original Phase 0 plan (7–10 days):*
- media_kit playback spike against real Xtream test accounts, at least one M3U/XMLTV source, a real Plex server (direct play + forced-transcode), and a real SMB share (confirm whether `smb://` works natively before committing to the proxy-bridge design)
- **Validate `dart_plex` against a real server (§6)** — PIN auth, library browse, and specifically the transcode start/keep-alive/stop lifecycle. It is a days-old pre-1.0 package; decide deliberately here whether to adopt it or hand-roll the needed subset, because discovering this in Phase 1 is expensive
- **Settle the ffmpeg licensing and build choice now (§10, §14)** — media_kit brings ffmpeg in with the player engine, so this decision is made in Phase 0 whether or not it's made consciously. Confirm an LGPL, dynamically-linked, no-GPL-encoder configuration
- **Pick the ffmpeg binding for audio extraction (§14)** — `ffmpeg_kit_flutter` is discontinued and its upstream repo archived; evaluate the community successor and have a fallback position before Phase 3.5 depends on it
- Confirm Play/App Store developer accounts are set up; draft the disclaimer copy (both the general one and the Advanced Sources-specific one, §8.2) and App Review notes now, not at submission time
- Line up a standing demo Xtream account for App Review (§8.4)

**Phase 1 — Core Android app: flagship sources (2–3 weeks)**
- Plex integration, local device storage, favorites/history, search, player — phone/tablet only. Home/onboarding built from day one around the Plex/local/network framing, with the Advanced Sources gate present but off (§8.2), not retrofitted later

**Phase 2 — SMB/CIFS network shares (1–1.5 weeks)**
- SMB client + local proxy bridge if the Phase 0 spike shows it's needed; folder-tree browsing UI

**Phase 3 — Advanced Sources: Xtream, M3U/XMLTV, Provider Profiles (2–2.5 weeks)**
- Xtream client, M3U/XMLTV parser + EPG guide, the toggle/disclaimer flow (§8.2), Provider Profile import (§8.3) — all gated behind Advanced Sources

**Phase 3.5 — AI Features (3–3.5 weeks)**
- `AiProvider` settings UI + per-provider clients including the shared generic/local implementation (~1 week); natural-language search + recommendations (~0.5 week); Apple 5.1.2(i) consent-dialog flow and `AiConsentRecord` tracking (§9.3)
- Transcription pipeline (~1.5–2 weeks, revised upward from the original 1-week figure): audio extraction, **chunking under the 25 MB request cap with overlap and timestamp re-stitching**, resumable checkpointed jobs, **the iOS foreground-only-or-background-URLSession decision from §9.2**, caching, plus subtitle translation. The chunk-and-restitch work is the bulk of this and was previously unaccounted for

**Phase 4 — Android TV layout (1–2 weeks)**
- Separate leanback UI tree, D-pad focus (including the folder-tree browser), TV manifest/banner, test on real Fire TV/Android TV hardware (emulators miss remote-input quirks)

**Phase 5 — iOS port (1 week dev + review buffer)**
- Background audio/PiP entitlements, App Store submission with careful review notes including Advanced Sources disclosure and demo Xtream credentials (§8.4); budget for at least one rejection-and-resubmit cycle

**Phase 6 — Store compliance hardening**
- Encrypted local credential/token storage (`flutter_secure_storage`), no analytics/tracking that could be read as fingerprinting without disclosure, privacy policy page (now needs to cover AI data sharing per §9.3 as well as account credentials), in-app disclaimer screens, takedown/appeal process documented for yourself
- **🔴 Store screenshots must never come from an IPTV source.** Phase 0 found
  the largest categories on a real playlist are `NETFLIX` (19,611), `NETFLIX
  (MULTI LANGUAGE)` (8,720) and `AMAZON PRIME` (2,491). Rendering
  user-supplied labels in the app is fine — that is what every player does —
  but §1.6 forbids real brand names in *our own* store assets, and a single
  screenshot of a category list reading "NETFLIX" is exactly the trigger §1
  spends its entire risk budget avoiding. **Every store screenshot comes from
  Plex, local files or SMB, and the Advanced Sources UI must not appear in
  store assets at all.** This is a mistake no amount of careful architecture
  prevents, so it belongs on the checklist.
- **iOS ATS decision must be made and written down** before submission (§11) —
  which of arbitrary-loads, per-domain exceptions, or refusing cleartext on iOS,
  and why.

## 14. Suggested tech stack summary

| Concern | Choice |
|---|---|
| State management | Riverpod |
| Video playback | media_kit (primary), better_player fallback |
| Local storage | Isar or Hive (content cache, favorites, history, feature-flag/consent state) — **not encrypted by default, never put secrets here**; flutter_secure_storage for all credentials/tokens/API keys, keyed by entity id (§3) |
| Networking | dio (interceptors for retry/timeout) |
| JSON models | freezed + json_serializable |
| Routing | go_router (needed for TV back-stack + deep-linkish nav between leanback rows, and to keep gated routes out of the tree entirely when Advanced Sources is off) |
| M3U/XMLTV parsing | hand-rolled (no solid maintained package covers both well) |
| Plex client | dart_plex **(candidate only — v0.1.2, days old, ~118 downloads; validate in Phase 0 or hand-roll the needed subset, §6)** |
| Local media scan | `MediaStore` platform channel/plugin (Android), `UIDocumentPickerViewController` + `PHPickerViewController` for Photos-library video (iOS, §7.1) |
| Folder access | file_picker (SAF directory picker with persisted permission) |
| SMB client | smb_connect (validate reliability in Phase 0 spike) |
| Local proxy bridge | shelf (loopback HTTP server for SMB → media_kit) |
| AI text generation | Custom dio-based clients per provider (Anthropic Messages API, OpenAI Chat Completions, Gemini `generateContent`); one shared client for generic-OpenAI-compatible + local endpoints |
| AI transcription | OpenAI Whisper-style endpoint initially, **chunked under its 25 MB request cap** (§9.2). Audio extraction needs an ffmpeg binding — **`ffmpeg_kit_flutter` is discontinued and upstream `arthenica/ffmpeg-kit` is archived**; the community successor is `ffmpeg_kit_flutter_new`, but the post-retirement fork landscape is fragmented with no consensus winner, so pin a specific fork, vendor it if necessary, and have a platform-channel fallback in mind (§13 Phase 0) |
| ffmpeg licensing | **Decided in Phase 0, not Phase 3.5** — media_kit bundles libmpv/ffmpeg, so the choice is made at engine selection (§10). Target an LGPL build, dynamically linked, with GPL-only encoders (x264/x265) excluded — this app decodes, it never encodes |
| Crash reporting / kill switch | Firebase Crashlytics + Remote Config only — both work without Google Play Services, which Fire TV lacks (§11, §16). No Analytics, no FCM, no Auth, no Firestore |
| CI/build | Codemagic or GitHub Actions + fastlane for both stores (plus Amazon Appstore for Fire TV, §11) |

## 15. Testing plan

**What is actually outstanding lives in
[MANUAL_TESTING.md](MANUAL_TESTING.md).** This section is the plan; that file is
the gap between the plan and reality, and it is the one to read before assuming
a feature works. The short version: the Android emulator cannot render video at
all, so everything downstream of a frame reaching the screen is unverified
regardless of how finished it looks.

- Unit tests: Xtream client response parsing, M3U parser edge cases (missing attributes, malformed lines), Plex PIN-flow state machine and transcode-session lifecycle, SMB connection/reconnect handling, Provider Profile schema validation (including malformed/hostile input), Advanced Sources toggle state (routes/tabs correctly appear and disappear), AI provider client parsing/error handling per provider, consent-flow state (correct dialog shown exactly once per provider × feature, revocation works), repository layer against all source types
- Widget tests: category grid, folder-tree browser, player controls, TV focus traversal
- Manual device matrix: 1 real Android TV box, 1 Fire TV stick, 2 Android phones (different Android versions), 1–2 iOS devices, against at least 2 different real Xtream panels, one M3U source, one real Plex server (direct-play and forced-transcode content), one real SMB share (NAS or Windows PC), and each of the AI provider configurations (Anthropic, OpenAI, Gemini, a generic-compatible endpoint pointed at a real self-hosted server, and local Ollama) — behavior varies enough across all of these that "works on the emulator" tells you very little
- Specifically verify SAF persisted folder permissions survive an app restart and a device reboot, not just the current session
- Store-submission dry run: full App Store review-notes writeup (including Advanced Sources disclosure + demo Xtream credentials, §8.4, and AI data-sharing disclosure per §9.3) and Play Console data-safety form filled out before the real submission, not during
- **Kill-switch drill (§16)**: verify that flipping the remote Advanced Sources flag actually removes the Live TV tab, EPG screen, and Xtream/M3U account entries on a running install, and that the app behaves correctly when Remote Config is unreachable (fails to the last cached value, and to *enabled* on a fresh install that has never fetched — never trapping a paying user in a broken state because of a network blip)
- **Transcription chunking (§9.2)**: verify chunk-boundary word handling and timestamp re-stitching against a file long enough to require many chunks, and that an interrupted job resumes from its checkpoint rather than restarting
- **Credential storage (§3)**: assert by inspection that no secret material appears in the Hive/Isar files on disk

---

## 16. Backend posture: what we run, and what we deliberately don't

§2 states the foundational decision: **this app has no backend.** That is a feature. It should be defended actively, because "just add a small server for X" is the kind of suggestion that arrives reasonably and compounds badly.

### 16.1 The only two exceptions, and why they earn it

Two managed services are worth adopting. Both are free at this app's scale, both are Firebase, and both — critically — [work without Google Play Services](https://firebase.google.com/docs/android/android-play-services), which Fire TV lacks (§11).

**Remote Config — a server-side kill switch for Advanced Sources.** This is the strongest backend argument in the entire document and the reason this section exists. §1.2 claims the IPTV feature "could be disabled via an update without touching the core app," but an App Store update is a multi-day review cycle. If a rights-holder complaint or a review threat arrives (§1.5 says to expect this as an operational reality, not a one-time gate), days is the wrong unit of response time. A remote flag gating an already-shipped feature flips in minutes.

Implementation notes that matter:
- The remote flag **ANDs with** the user's local toggle (§8.2) — it can force the feature off globally, but it never forces it *on* for a user who hasn't opted in.
- Fail safe and fail *quiet*: cache the last fetched value, and on a fresh install that has never reached the network, default to the user's local setting. A network blip must not silently disable a working app.
- **This does not touch Guideline 2.5.2.** That rule bars downloading and executing *code*; this is a boolean toggling a feature already present and disclosed in the reviewed binary. Remote configuration of shipped features is ordinary and universal. Worth stating explicitly since §1.4 draws a hard line on the code-download question and the distinction should not blur.

**Crashlytics — field crash reporting.** The app ships libmpv across phone, tablet, Android TV, Fire TV, and iOS, pointed at deliberately malformed streams from cheap panels. Field crashes here will not reproduce locally. Make it **opt-in** at first run to stay consistent with the privacy posture below, and declare it in Play Data Safety and Apple's privacy labels either way. The toggle lives in Settings → **Privacy and data** (§12.1), alongside the statement that the app has no backend — one screen where a user can see everything that does and does not leave the device.

### 16.2 Why not AWS

Nothing here argues for it. There is no free Crashlytics equivalent, materially more setup and ops overhead for a small team, and the only plausible use — hosting static JSON — is a need that §8.3 has now removed entirely. If a genuine backend requirement appears later, revisit then; today it would be infrastructure in search of a purpose.

### 16.3 What must never be added

Each of these looks locally reasonable and each would spend something the no-backend decision is currently buying:

- **An AI proxy.** Routing AI calls through our servers breaks the bring-your-own-key ethos, makes us a data processor for user content, and converts Apple's 5.1.2(i) obligation (§9.3) from "we name the provider the user chose" into "we are an intermediary handling your data." The consent story is dramatically cleaner when the device talks to the user's provider directly.
- **Accounts and cross-device sync of favorites/history.** Adding auth triggers Apple's Sign in with Apple requirement, the in-app account-deletion requirement on both stores, and real GDPR data-controller scope — for a feature Plex already provides server-side for the one source that has a server (§6). The cost/benefit is bad and it is not close.
- **Analytics.** §13 Phase 6 commits to "no analytics/tracking that could be read as fingerprinting without disclosure." Adding it contradicts a stated goal and expands both stores' privacy declarations. Crashlytics is the bounded exception; general product analytics is not.
- **Hosting content, catalogs, or provider directories of any kind.** See §8.3 — this is the line that protects the primary-purpose argument the entire §1 strategy depends on.

The test for any future proposal: *does this put our server in the path of user content or credentials?* Crash reports and a config flag do not. Almost everything else does.

---

## Open items

### ✅ Closed by Phase 0 (2026-09-11)

- ~~Whether the spike should precede scaffolding~~ — it ran, and it was worth
  it. See §13 for the summary of what it changed.
- ~~media_kit vs. better_player~~ — **media_kit confirmed** (§10), on evidenced
  breadth rather than the unproven malformed-TS argument.
- ~~Does SMB need the loopback bridge~~ — **yes**, and it works (§7.2).
- ~~Validate or replace `dart_plex`~~ — **adopted with two mandatory
  workarounds** and standing caution (§6).

### Open — decide before or during Phase 1

- **Confirm your own legal comfort with the operational risk in §1** — a
  business decision, not a technical one, and worth deciding explicitly rather
  than discovering after building Phases 1–5.
- **Riverpod vs. Bloc** — this plan assumes Riverpod.
- **ffmpeg licensing (§10, §14)** — media_kit pulls ffmpeg in at engine
  selection, so this is already decided implicitly. Target LGPL, dynamically
  linked, no GPL encoders, and confirm it.
- **Check for a newer media_kit** (§10) — the bundled `libmpv-2.dll` is dated
  2023-09-24, over two years stale.
- **Q5, the Android-device questions** (PHASE0_FINDINGS.md) — SAF persisted
  permissions across a reboot, `MediaStore` scanning, hardware decode, release
  binary size. Deferred from Phase 0 for lack of hardware; do them as Phase 1
  starts, since §15 singles out the SAF-after-reboot case as the one that fails.
- **Finish the Plex transcode lifecycle test** — `decision → ping → stop` with
  the `hasMDE=1` fix in place. The specific risk is a leaked transcode session
  on every user's server.
- **Finalise the app name** — "Relay Player" is the working title throughout.

### Open — decide before the relevant phase

- **§16 backend exceptions** — adopt Firebase Remote Config as the Advanced
  Sources kill switch (recommended: the difference between a minutes-long and a
  multi-day response to a takedown threat), and whether Crashlytics ships
  opt-in. Everything else backend-shaped stays out; §16.3 is the standing
  answer.
- **iOS ATS position (§11)** — arbitrary loads, per-domain exceptions, or
  refusing cleartext on iOS. Needed before the Phase 5 submission, and the
  reasoning must be written down, not improvised in a review reply.
- **Pick an ffmpeg binding (§14)** — `ffmpeg_kit_flutter` is discontinued and
  upstream archived. Evaluate `ffmpeg_kit_flutter_new`, pin a fork, know the
  fallback. Needed before Phase 3.5.
- **iOS transcription background strategy (§9.2)** — foreground-only with
  resumable checkpoints, or background `URLSession` transfers. Retrofitting
  resumability is painful, so decide before Phase 3.5.
- **Amazon Appstore for Fire TV (§11)** — a third store pipeline not costed in
  §13. In scope for the initial release, or a follow-on?
- **A second, worse Xtream panel** — to settle §10's malformed-TS claim, or
  else formally drop that argument.

### Scoped out, revisitable

- Plex Live TV/DVR, and FTP/WebDAV/UPnP-DLNA for Local & Network (§6, §7) —
  these reuse existing plumbing rather than needing new architecture. The §7.2
  bridge in particular is built to be reused by FTP/WebDAV.
- AI transcription beyond OpenAI (§9.1) — reconfirm provider capabilities at
  build time; this space moves quickly.
