#!/usr/bin/env python3
"""
Builds the site's phone screenshots from the raw captures in the app repo.

    python3 tools/make-screens.py [--src ../habit_tracker/tools/screenshots-raw/en]

Writes assets/img/screens/<name>-{360,720}.webp.

WHY NOT JUST REUSE THE PLAY STORE IMAGES

Two candidate sources exist in the app repo, and neither works as-is:

  tools/store-art/screenshots/  All exactly 1080x1920, so they tile perfectly —
                                but each carries a marketing headline burnt into a
                                saturated colour panel ("START SMALL. TODAY
                                COUNTS."). On a page that already has its own
                                headings and captions, that is the same words
                                twice and six loud backgrounds fighting the layout.

  tools/store-art/screens/      Clean app UI, no headlines — but cropped to
                                whatever each frame needed for the Play carousel,
                                so the heights run 2210, 2020, 2210, 2210, 2210,
                                1674. Laid out in a row they end at different
                                points and the captions sit at different heights.

So this goes back to the 1080x2460 captures and crops every one to the SAME box.

PICKING THE BOX

Each frame has a top offset that exists for a reason, carried over from
make-screenshots.py in the app repo:

  100   clears the status bar, which holds a carrier label, a data-usage readout
        and a clock frozen at 8:16 by SystemUI demo mode
  636   on the start frame, drops the "0 / 0 habits - 0%" card, which is honest
        for a fresh install but argues with a caption about not starting over

and a floor it must not cross: the widgets frame has to stay above the dock of
personal apps at y=2160, everything else above the nav bar at y=2310.

That leaves 1674px of usable height on the start frame and more on the others, so
1674 is the height they can all share. It also happens to be a good shape for the
page: at a 360px-wide grid cell that is a 558px-tall card, where the 2210 crop
would have been 737px and dominated the screen.
"""

import argparse
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets/img/screens"

HEIGHT = 1674
WIDTHS = (360, 720)

# capture stem -> (output name, top offset)
SHOTS = [
    ("home-timer",            "01-home",         100),
    ("widgets",               "02-widgets",      100),
    ("stats",                 "03-stats",        100),
    ("detail",                "04-detail",       100),
    ("achievements",          "05-achievements", 100),
    ("template-updated-loop", "06-start",        636),
]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--src", default="../habit_tracker/tools/screenshots-raw/en",
                    help="directory of raw 1080x2460 captures (gitignored in the app repo)")
    args = ap.parse_args()

    src = Path(args.src)
    if not src.is_dir():
        raise SystemExit(f"No such directory: {src}\n"
                         f"The raw captures live in the app repo and are gitignored; "
                         f"see docs/store-screenshots.md there for how to retake them.")

    OUT.mkdir(parents=True, exist_ok=True)
    for f in OUT.glob("*.webp"):
        f.unlink()

    total = 0
    for stem, name, top in SHOTS:
        matches = sorted(src.glob(stem + ".*"))
        if not matches:
            raise SystemExit(f"Missing capture: {src}/{stem}.*")
        im = Image.open(matches[0]).convert("RGB")
        if top + HEIGHT > im.height:
            raise SystemExit(f"{stem}: crop runs past the bottom of a {im.height}px capture")
        box = im.crop((0, top, im.width, top + HEIGHT))
        for w in WIDTHS:
            out = OUT / f"{name}-{w}.webp"
            box.resize((w, round(HEIGHT * w / im.width)), Image.LANCZOS) \
               .save(out, "WEBP", quality=82, method=6)
            total += out.stat().st_size

    print(f"  {len(SHOTS) * len(WIDTHS)} files, {total // 1024} KB total")
    print(f"  every image {1080}x{HEIGHT} before resize — "
          f"use width=\"360\" height=\"{round(HEIGHT * 360 / 1080)}\" on all six")


if __name__ == "__main__":
    main()
