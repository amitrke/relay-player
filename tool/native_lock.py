#!/usr/bin/env python3
"""Check that a built APK or AAB carries exactly the libmpv the lock pins.

media_kit's packages fetch libmpv at build time and verify it with a checksum
they choose (md5 on Android). That proves the download matched what the
package expected, not that it is the binary whose contents
docs/architecture.md and lib/core/native_licenses.dart describe. This hashes
every lib/<abi>/libmpv.so inside the build output against
native-libs.lock.json, so a changed binary fails CI instead of quietly
invalidating the licence list (architecture.md section 10.1).

    python3 tool/native_lock.py build/app/outputs/flutter-apk/*-release.apk
    python3 tool/native_lock.py --print app-release.aab   # show actual hashes

Exit status 1 on any mismatch, an ABI the lock does not know, or an archive
with no libmpv.so at all (which would mean the check is looking at the wrong
file and proving nothing).
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
# APKs keep native code at lib/<abi>/, AABs at base/lib/<abi>/.
_SO = re.compile(r"^(?:base/)?lib/([^/]+)/libmpv\.so$")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("archives", nargs="+", type=Path)
    parser.add_argument("--lock", type=Path, default=ROOT / "native-libs.lock.json")
    parser.add_argument("--print", action="store_true", dest="print_only",
                        help="print the hashes found instead of checking them")
    args = parser.parse_args()

    shipped: dict[str, str] = json.loads(args.lock.read_text("utf-8"))["android"]["shipped"]
    failed = False
    for archive in args.archives:
        found = 0
        with zipfile.ZipFile(archive) as z:
            for name in z.namelist():
                m = _SO.match(name)
                if not m:
                    continue
                found += 1
                abi = m.group(1)
                digest = hashlib.sha256(z.read(name)).hexdigest()
                if args.print_only:
                    print(f"{archive.name}  {abi}  {digest}")
                elif abi not in shipped:
                    print(f"error: {archive.name}: {abi} is not in the lock")
                    failed = True
                elif shipped[abi] != digest:
                    print(f"error: {archive.name}: {abi} libmpv.so is {digest}, "
                          f"locked {shipped[abi]}")
                    failed = True
                else:
                    print(f"ok     {archive.name}  {abi}")
        if found == 0:
            print(f"error: {archive.name}: no libmpv.so inside")
            failed = True
    return 1 if failed and not args.print_only else 0


if __name__ == "__main__":
    sys.exit(main())
