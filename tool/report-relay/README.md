# Problem-report relay

Receives a diagnostics-only report from the app and files it as a GitHub issue,
so a person can report a failure with one tap and no account. The argument for
running it at all is `docs/architecture.md` section 16.4. **Not deployed.
The app side is built but sends nothing until `REPORT_RELAY_URL` is set at
build time** (`--dart-define=REPORT_RELAY_URL=https://...`).

It stores nothing, never logs the request body, and accepts only a fixed
schema. The repository and its issues are public, so a report is public the
moment it is filed.

## Test it (no account needed)

```sh
node --test tool/report-relay/worker.test.mjs
```

The tests use a fake GitHub. They do not prove the Worker runs on Cloudflare or
that GitHub accepts the calls; nothing has been run against either.

## Deploy it (needs the repository owner)

One script does everything except the two things only you can: creating the
token, and logging in to Cloudflare.

1. **Create the GitHub token** (a web form; GitHub has no API for it).
   Settings, Developer settings, Fine-grained tokens. Resource owner: you.
   Repository access: **only this repository**. Permissions: **Issues: Read and
   write**, nothing else. Pick an expiry and set a reminder to renew it.
2. **Cloudflare, once:** a free account, then `npm i -g wrangler` and
   `wrangler login`.
3. **Run the script:** `python3 tool/report-relay/deploy_relay.py`. It asks you
   to paste the token (hidden), refuses a classic token, checks it can see the
   repository, creates the `app-report` label, stores the token in the Worker as
   the secret `GITHUB_TOKEN` (on standard input, so it never appears in a
   process list, shell history or a file), deploys, and prints the
   `*.workers.dev` address. It can then file one test report and tell you to
   close it. That address is public and not a secret.

The script's checks of what to refuse are tested
(`python3 -m unittest tool/report-relay/test_deploy_relay.py`). The script's own network steps are only partly exercised. Its test request
must send its own User-Agent: Cloudflare answers 403 (`error code: 1010`) to
Python's default one. To rerun just the test: `python3
tool/report-relay/deploy_relay.py --test-only https://<worker>.workers.dev`.

By hand instead: `wrangler secret put GITHUB_TOKEN`, create the `app-report`
label, `wrangler deploy`, then `curl -X POST <url>/report -H 'content-type:
application/json' -d '{"v":1,"app_version":"1.0.8","platform":"android","error":"relay test"}'`
should answer `202`.

## Limits

- 4 KB body, and one request shape; anything else is refused.
- 5 requests a minute per caller (`RATE_LIMITER`): per Cloudflare location and
  approximate, and everyone behind one address shares it.
- At most **20 new issues an hour** (`MAX_NEW_ISSUES_PER_HOUR`, a Worker
  variable) and **40 comments per issue**, both counted from GitHub, so the
  relay keeps no state. Over the hourly limit the answer is 429; over the
  comment limit it is a normal 202, so a sender cannot tell.
- If GitHub cannot be searched, the report is filed anyway.

None of this tells one sender from another beyond their address.

## Before the app uses it

Per section 16.4, in the same release as the button: the privacy policy
(`site/privacy.html`) stops saying no reports are sent, and the Play Data
Safety and Apple privacy declarations list diagnostics, not linked to the
person.

## If it is abused

Disable the Worker in the Cloudflare dashboard and revoke the token. Do not add
moderation here; the app falls back to Copy when the relay is unreachable.
