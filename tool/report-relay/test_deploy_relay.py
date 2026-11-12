"""Run with: python3 -m unittest tool/report-relay/test_deploy_relay.py  (from the repo root)

Covers the parts that decide what is safe to do with a token. The network and
wrangler steps are not run here; see the README for what is unverified."""
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import deploy_relay as setup  # noqa: E402


class TokenChecks(unittest.TestCase):
    def test_fine_grained_is_accepted(self):
        self.assertIsNone(setup.token_problem("github_pat_11AAAA_xxxx"))

    def test_classic_and_app_tokens_are_refused(self):
        for t in ("ghp_abc", "gho_abc", "ghu_abc", "ghs_abc", "ghr_abc"):
            self.assertIn("fine-grained", setup.token_problem(t))

    def test_empty_or_odd_input_is_refused(self):
        self.assertIn("no token", setup.token_problem(""))
        self.assertIn("does not look like", setup.token_problem("hello"))


class Parsing(unittest.TestCase):
    def test_repo_is_read_from_wrangler_toml(self):
        self.assertEqual(setup.repo_from_wrangler(), "amitrke/relay-player")

    def test_worker_address_is_found_in_deploy_output(self):
        out = "Uploaded subnext-report-relay\n  https://subnext-report-relay.me.workers.dev\nDone"
        self.assertEqual(
            setup.find_worker_url(out), "https://subnext-report-relay.me.workers.dev"
        )
        self.assertIsNone(setup.find_worker_url("nothing here"))


class NoTokenOnCommandLine(unittest.TestCase):
    def test_source_never_passes_the_token_as_an_argument(self):
        src = (Path(__file__).resolve().parent / "deploy_relay.py").read_text()
        # It goes to wrangler on stdin (input=...), never as an argv item.
        self.assertIn('input=token + "\\n"', src)
        self.assertNotIn('"--secret"', src)


if __name__ == "__main__":
    unittest.main()
