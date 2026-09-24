"""ASCII previews for eyeballing generated sprites in the terminal."""
from __future__ import annotations

import sys
import os

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import px  # noqa: E402


def show(img, label="", chars=" .:-=+*#%@"):
    """Print an image using luminance ramps (works for RGBA buffers)."""
    if label:
        print("--- %s (%dx%d) ---" % (label, img.w, img.h))
    for y in range(img.h):
        row = ""
        for x in range(img.w):
            r, g, b, a = img.px[y][x]
            if a == 0:
                row += "."
                continue
            lum = (r * 0.3 + g * 0.6 + b * 0.1) / 255.0
            if a < 200:
                lum *= 0.6
            idx = min(len(chars) - 1, max(1, int(lum * len(chars))))
            row += chars[idx]
        print(row)
    print()


def silhouette(img, label=""):
    if label:
        print("--- %s (%dx%d) ---" % (label, img.w, img.h))
    for y in range(img.h):
        print("".join("#" if img.px[y][x][3] > 0 else "." for x in range(img.w)))
    print()


if __name__ == "__main__":
    import chars

    if len(sys.argv) > 1 and sys.argv[1] == "all":
        for name, anims in chars.__dict__.items():
            pass
    pal = {"out": chars.P["out"], "body": chars.P["steel"], "body_lit": chars.P["steel_lit"],
           "body_drk": chars.P["steel_drk"], "cloth": chars.P["teal"], "cloth_lit": chars.P["teal_lit"],
           "cloth_drk": chars.P["teal_drk"], "skin": chars.P["skin"], "skin_drk": chars.P["skin_drk"],
           "eye": chars.P["cyan"]}
    show(chars._knight(pal, bob=0, leg=(0, 0)), "knight idle")
    show(chars._slime({"body": chars.P["slime"], "lit": chars.P["slime_lit"], "drk": chars.P["slime_drk"]}, 16, 14), "slime")
    show(chars._spider(), "spider")
    show(chars._ghost(), "ghost")
