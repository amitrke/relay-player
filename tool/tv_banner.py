"""Draws the Android TV / Fire TV launcher banners.

The TV launcher ignores android:icon entirely and shows a 16:9 banner instead,
which by convention carries the app name -- so unlike the launcher icon this
asset needs type, and cannot just be a scaled square mark.

Run from the repo root:

    python tool/tv_banner.py

Outputs assets/icon/tv_banner_320x180.png (the xhdpi drawable Android wants)
and assets/icon/tv_banner_1280x720.png (the Play Store TV listing asset).

The mark is taken from assets/icon/relay_icon_foreground.png rather than
redrawn, so it cannot drift from the launcher icon. Type is Roboto, which ships
in the Flutter SDK under Apache-2.0 and is Android's own UI font, so the
wordmark looks native on a TV rather than like a foreign brand font.
"""

import os
import shutil
import subprocess
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

GROUND = (0x14, 0x12, 0x1C, 255)
WORDMARK = "Relay Player"
REPO = Path(__file__).resolve().parent.parent
FOREGROUND = REPO / "assets" / "icon" / "relay_icon_foreground.png"


def find_font() -> Path:
    """Locate Roboto Medium in the Flutter SDK's bundled material fonts."""
    roots = []
    if os.environ.get("FLUTTER_ROOT"):
        roots.append(Path(os.environ["FLUTTER_ROOT"]))
    which = shutil.which("flutter")
    if which:
        # .../flutter/bin/flutter -> .../flutter
        roots.append(Path(which).resolve().parent.parent)
    try:
        out = subprocess.run(
            ["flutter", "--version", "--machine"],
            capture_output=True, text=True, timeout=120, check=False,
        ).stdout
        for line in out.splitlines():
            if '"flutterRoot"' in line:
                roots.append(Path(line.split('"')[3]))
    except Exception:
        pass

    for root in roots:
        candidate = root / "bin" / "cache" / "artifacts" / "material_fonts" / "roboto-medium.ttf"
        if candidate.is_file():
            return candidate
    raise SystemExit(
        "Could not find roboto-medium.ttf in the Flutter SDK. Set FLUTTER_ROOT "
        "or put Flutter on PATH."
    )


def banner(width: int, height: int, font_path: Path) -> Image.Image:
    img = Image.new("RGBA", (width, height), GROUND)

    # Crop the mark to its ink so the layout is driven by the artwork rather
    # than by the transparent padding the adaptive-icon canvas needs.
    source = Image.open(FOREGROUND).convert("RGBA")
    bbox = source.getchannel("A").getbbox()
    mark = source.crop(bbox)

    # The arc is open at the top right, so its ink is taller below the circle
    # centre than above it. Centring the ink box would therefore leave the
    # circle -- which is what the eye reads as the centre -- off the banner's
    # centre line, and the wordmark misaligned with it. Work out where the
    # circle centre actually falls, as a fraction of the cropped height.
    centre = source.width / 2
    circle_fy = (centre - bbox[1]) / (bbox[3] - bbox[1])

    # Keep everything inside a margin: TV panels and launcher rows crop edges,
    # and text hard against the frame reads as a mistake at viewing distance.
    margin = round(height * 0.14)
    mark_h = height - margin * 2
    mark_w = round(mark.width * mark_h / mark.height)
    mark = mark.resize((mark_w, mark_h), Image.LANCZOS)

    gap = round(height * 0.10)
    avail = width - margin * 2 - mark_w - gap

    # Largest type that fits the space left over, rather than a guessed size
    # that happens to work at one of the two resolutions.
    size = height
    while size > 8:
        font = ImageFont.truetype(str(font_path), size)
        box = font.getbbox(WORDMARK)
        if box[2] - box[0] <= avail and box[3] - box[1] <= mark_h * 0.5:
            break
        size -= 1
    font = ImageFont.truetype(str(font_path), size)
    box = font.getbbox(WORDMARK)
    text_w, text_h = box[2] - box[0], box[3] - box[1]

    group_w = mark_w + gap + text_w
    x = (width - group_w) // 2

    # Put the mark's circle centre on the banner's centre line, and the
    # wordmark on the same line, so the two read as aligned.
    mark_y = round(height / 2 - circle_fy * mark_h)
    img.alpha_composite(mark, (x, mark_y))

    draw = ImageDraw.Draw(img)
    draw.text(
        (x + mark_w + gap - box[0], (height - text_h) // 2 - box[1]),
        WORDMARK, font=font, fill=(0xFF, 0xFF, 0xFF, 255),
    )
    return img


def main() -> int:
    if not FOREGROUND.is_file():
        raise SystemExit(f"missing {FOREGROUND}")
    font_path = find_font()
    print(f"type: {font_path}")
    out_dir = REPO / "assets" / "icon"
    for w, h in ((320, 180), (1280, 720)):
        path = out_dir / f"tv_banner_{w}x{h}.png"
        # The banner is opaque by design, so flatten to RGB -- an alpha channel
        # here would only invite the same App Store complaint the icon gets.
        banner(w, h, font_path).convert("RGB").save(path)
        print(f"wrote {path.relative_to(REPO)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
