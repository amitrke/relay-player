#!/usr/bin/env python3
"""Sets up the problem-report relay (architecture.md section 16.4).

What it does, in order:

  1. asks you to paste the GitHub token (hidden, never echoed, never put on a
     command line, never written to a file);
  2. checks the token is a fine-grained one and can file issues on the
     repository;
  3. creates the `app-report` label if it is missing;
  4. stores the token in the Cloudflare Worker as the secret GITHUB_TOKEN,
     passing it to `wrangler` on standard input;
  5. deploys the Worker and prints its address;
  6. optionally files one test report and closes it again.

What it cannot do: **create the token.** GitHub has no API for personal access
tokens, so that is a web form, shown below. Run `wrangler login` once first.

Standard library only. Run from anywhere:

    python3 tool/report-relay/deploy_relay.py
"""

from __future__ import annotations

import argparse
import getpass
import json
import re
import shutil
import subprocess
import sys
import urllib.error
import urllib.request
from pathlib import Path

HERE = Path(__file__).resolve().parent
LABEL = "app-report"
TOKEN_HELP = """\
Create the token (about a minute, in the browser):

  GitHub > Settings > Developer settings > Personal access tokens >
  Fine-grained tokens > Generate new token

    Resource owner:       you
    Repository access:    Only select repositories -> {repo}
    Repository permissions:  Issues = Read and write   (nothing else)
    Expiration:           your choice; set a reminder to renew it

Copy the token (it starts with github_pat_). It is shown once."""


def repo_from_wrangler(path: Path = HERE / "wrangler.toml") -> str | None:
    """REPORT_REPO from wrangler.toml, or None."""
    m = re.search(r'^REPORT_REPO\s*=\s*"([^"]+)"', path.read_text(), re.M)
    return m.group(1) if m else None


def token_problem(token: str) -> str | None:
    """Why [token] should not be used, or None. A classic token is refused:
    it can have far more reach than this relay needs."""
    if not token:
        return "no token entered"
    if token.startswith("github_pat_"):
        return None
    if token.startswith(("ghp_", "gho_", "ghu_", "ghs_", "ghr_")):
        return (
            "that is a classic or app token. Use a fine-grained one limited to "
            "this repository with Issues read and write only"
        )
    return "that does not look like a GitHub token (expected github_pat_...)"


def find_worker_url(output: str) -> str | None:
    """The workers.dev address in `wrangler deploy` output."""
    m = re.search(r"https://[\w.-]+\.workers\.dev", output)
    return m.group(0) if m else None


def github(token: str, method: str, path: str, body: dict | None = None):
    """One GitHub call. Returns (status, parsed json or None, headers). The
    token is never included in anything this raises or prints."""
    req = urllib.request.Request(
        f"https://api.github.com{path}",
        method=method,
        data=json.dumps(body).encode() if body is not None else None,
        headers={
            "Accept": "application/vnd.github+json",
            "Authorization": f"Bearer {token}",
            "User-Agent": "subnext-report-relay-setup",
            "X-GitHub-Api-Version": "2022-11-28",
            **({"Content-Type": "application/json"} if body is not None else {}),
        },
    )
    try:
        with urllib.request.urlopen(req, timeout=20) as res:
            raw = res.read()
            return res.status, (json.loads(raw) if raw else None), res.headers
    except urllib.error.HTTPError as e:
        raw = e.read()
        try:
            return e.code, json.loads(raw), e.headers
        except ValueError:
            return e.code, None, e.headers


def run(cmd: list[str], **kw) -> subprocess.CompletedProcess:
    return subprocess.run(cmd, cwd=HERE, text=True, **kw)


def smoke_test(url: str, repo: str) -> None:
    """Posts one minimal report to [url]. Sets its own User-Agent: Cloudflare's
    bot filter answers 403 ("error code: 1010") to Python's default one, which
    is the script failing, not the relay."""
    body = json.dumps(
        {"v": 1, "app_version": "0.0.0", "platform": "other", "error": "relay setup test"}
    ).encode()
    req = urllib.request.Request(
        f"{url.rstrip('/')}/report",
        data=body,
        headers={
            "Content-Type": "application/json",
            "User-Agent": "subnext-report-relay-setup",
        },
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=30) as r:
            print(f"  relay answered {r.status}")
    except urllib.error.HTTPError as e:
        print(f"  relay answered {e.code}: {e.read().decode(errors='replace')[:300]}")
    except urllib.error.URLError as e:
        print(f"  could not reach the relay: {e.reason}")
    print(f"  Close the test issue in {repo} (label '{LABEL}', title mentions 'relay setup test').")


def step(text: str) -> None:
    print(f"\n== {text}")


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--repo", help="owner/name (default: REPORT_REPO in wrangler.toml)")
    ap.add_argument("--skip-test", action="store_true", help="do not file a test report")
    ap.add_argument(
        "--test-only",
        metavar="URL",
        help="only post the test report to an already deployed relay (no token needed)",
    )
    args = ap.parse_args()

    repo = args.repo or repo_from_wrangler()
    if not repo:
        print("No repository: pass --repo owner/name or set REPORT_REPO in wrangler.toml.")
        return 2

    if args.test_only:
        smoke_test(args.test_only, repo)
        return 0

    wrangler = shutil.which("wrangler")
    if not wrangler:
        print("`wrangler` is not installed. Run: npm i -g wrangler   then: wrangler login")
        return 2

    print(f"Relay for {repo}\n")
    print(TOKEN_HELP.format(repo=repo))
    token = getpass.getpass("\nPaste the token (hidden): ").strip()
    problem = token_problem(token)
    if problem:
        print(f"\nStopped: {problem}.")
        return 1

    step("Checking the token on GitHub")
    status, data, _ = github(token, "GET", f"/repos/{repo}")
    if status == 401:
        print("GitHub says the token is invalid or expired.")
        return 1
    if status == 404:
        print(f"The token cannot see {repo}. Was the repository selected for it?")
        return 1
    if status != 200:
        print(f"Unexpected answer from GitHub ({status}).")
        return 1
    print(f"  can see {data.get('full_name')}")

    step(f"Creating the '{LABEL}' label (this also proves the token can write issues)")
    status, data, _ = github(
        token,
        "POST",
        f"/repos/{repo}/labels",
        {"name": LABEL, "color": "5319e7", "description": "Filed by the in-app problem report"},
    )
    if status == 201:
        print("  created")
    elif status == 422:
        print("  already exists")
    elif status == 403:
        print("  The token cannot write issues. Give it Issues: Read and write.")
        return 1
    else:
        print(f"  unexpected answer ({status}); stopping before anything is stored.")
        return 1

    step("Storing the token in Cloudflare as GITHUB_TOKEN")
    # On standard input, so it never appears in `ps` or shell history.
    res = run([wrangler, "secret", "put", "GITHUB_TOKEN"], input=token + "\n")
    token = ""  # not needed again
    if res.returncode != 0:
        print("\nwrangler could not store the secret. Run `wrangler login` and retry.")
        return 1

    step("Deploying the Worker")
    res = run([wrangler, "deploy"], capture_output=True)
    sys.stdout.write(res.stdout)
    sys.stderr.write(res.stderr)
    if res.returncode != 0:
        print("\nDeploy failed; see the output above.")
        return 1
    url = find_worker_url(res.stdout + res.stderr)
    if not url:
        print("\nDeployed, but the address was not in the output. Find it in the Cloudflare dashboard.")
        return 0
    print(f"\n  Worker address: {url}")

    if not args.skip_test:
        step("Optional: file one test report")
        if input("File a test report and close it again? [y/N] ").strip().lower() == "y":
            smoke_test(url, repo)

    print(
        "\nDone. To use it in a build:\n"
        f"  flutter build ... --dart-define=REPORT_RELAY_URL={url}\n"
        "Before shipping that build, change the privacy policy and the store\n"
        "declarations (tool/report-relay/README.md, 'Before the app uses it')."
    )
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        print("\nCancelled. Nothing further was changed.")
        sys.exit(130)
