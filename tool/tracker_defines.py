#!/usr/bin/env python3
"""Write the watch-tracker app credentials for `--dart-define-from-file`.

CI reads TRAKT_CLIENT_ID, TRAKT_CLIENT_SECRET, SIMKL_CLIENT_ID,
ANILIST_CLIENT_ID and MAL_CLIENT_ID from repository secrets into the
environment, and this writes them to a JSON file outside the checkout, so
none of them is ever in the repository or a command line (architecture.md
§19.2, RELEASING.md "Tracker credentials").

A secret that is not set is written as an empty string, and the app then
leaves that tracker out of the build entirely. That keeps forks and local
builds working with no secrets at all.

    python3 tool/tracker_defines.py "$RUNNER_TEMP/trackers.json"
"""

import json
import os
import sys

KEYS = [
    'TRAKT_CLIENT_ID',
    'TRAKT_CLIENT_SECRET',
    'SIMKL_CLIENT_ID',
    'ANILIST_CLIENT_ID',
    'MAL_CLIENT_ID',
]


def main() -> int:
    if len(sys.argv) != 2:
        print(__doc__)
        return 2
    values = {k: os.environ.get(k, '').strip() for k in KEYS}
    with open(sys.argv[1], 'w', encoding='utf-8') as f:
        json.dump(values, f)
    # Which are present, never what they are.
    present = [k for k, v in values.items() if v]
    print(f'tracker credentials present: {", ".join(present) or "none"}')
    return 0


if __name__ == '__main__':
    sys.exit(main())
