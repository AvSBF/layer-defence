"""AvSGames branding assets: game icon, boot splash and logo.

Everything is drawn with the same pixel toolkit as the game, so the icon uses
the actual knight helmet and portal swirl - no separate art pipeline.
"""
from __future__ import annotations

import math
import os

from px import C, Img, alpha, mix
from chars import P
import itch_assets

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
GEN = os.path.join(ROOT, "Aseprites", "Generated", "Branding")
DOCS = os.path.join(ROOT, "docs", "itch")

ICON_SIZE = 64          # pixel grid of the icon, upscaled by ICON_SCALE
ICON_SCALE = 8          # -> 512x512
SPLASH_W, SPLASH_H = 1280, 720
STUDIO = "AvSGames"
GAME = "Layer Defence"
VERSION = "1.0.0"


def _rounded_tile(size : int, top, bottom, corner : int = 6) -> Img:
    img = Img(size, size)
    for y in range(size):
        t = y / max(1, size - 1)
        c = mix(top, bottom, t)
        for x in range(size):
            # clip the corners for a rounded-square app icon
            ex = min(x, size - 1 - x)
            ey = min(y, size - 1 - y)
            if ex + ey < corner:
                continue
            if ex < 2 and ey < corner - 2:
                continue
            if ey < 2 and ex < corner - 2:
                continue
            img.set(x, y, c)
    return img


def icon_grid() -> Img:
    """64x64 pixel-art icon: portal swirl + knight helmet + gold frame."""
    s = ICON_SIZE
    img = _rounded_tile(s, C("#2b2260"), C("#171240"), corner=8)

    # --- portal swirl behind the helmet ---
    cx, cy = s / 2, s / 2 + 2
    for y in range(s):
        for x in range(s):
            dx = (x - cx) / 26.0
            dy = (y - cy) / 26.0
            d = dx * dx + dy * dy
            if d > 1.0:
                continue
            swirl = math.sin((math.atan2(dy, dx) * 3.0 + d * 7.0) * 1.5)
            t = (swirl + 1.0) * 0.5
            col = mix(C("#4a2f8c"), C("#a06fe0"), t)
            if d > 0.78:
                col = mix(col, C("#e0c8ff"), (d - 0.78) * 3.0)
            img.set(x, y, col)
    for _ in range(26):
        pass

    # --- knight helmet, facing the viewer (front view reads better small) ---
    steel = C("#96a9c4")
    steel_lit = C("#d6e3f5")
    steel_drk = C("#5d6c85")
    out = C("#140f1d")
    hx, hy = 18, 20
    img.rect(hx + 2, hy, 24, 4, steel_lit)
    img.rect(hx, hy + 2, 28, 18, steel)
    img.rect(hx, hy + 2, 28, 2, steel_lit)
    img.rect(hx, hy + 18, 28, 2, steel_drk)
    img.rect(hx, hy + 8, 28, 7, out)              # visor band
    img.rect(hx + 4, hy + 10, 6, 3, P["cyan"])    # glowing eyes
    img.rect(hx + 18, hy + 10, 6, 3, P["cyan"])
    img.rect(hx + 2, hy + 21, 24, 4, steel_drk)   # chin
    img.rect(hx + 10, hy + 20, 8, 2, out)         # mouth grille
    # gold plume ridge
    img.rect(hx + 4, hy - 3, 20, 3, C("#ffd34d"))
    img.rect(hx + 4, hy - 3, 20, 1, C("#fff3a0"))
    img.rect(hx + 11, hy - 6, 6, 3, C("#e05a4a"))
    img.rect(hx + 11, hy - 6, 6, 1, C("#ff7a6f"))
    img.outline(out, diagonals=False)

    # --- gold frame ---
    img.border(0, 0, s, s, C("#ffd34d"), 2)
    img.border(2, 2, s - 4, s - 4, alpha(C("#ffd34d"), 110), 1)
    return img


def _upscale(src : Img, scale : int) -> Img:
    out = Img(src.w * scale, src.h * scale)
    for y in range(src.h):
        for x in range(src.w):
            c = src.get(x, y)
            if c[3] == 0:
                continue
            for sy in range(scale):
                for sx in range(scale):
                    out.set(x * scale + sx, y * scale + sy, c)
    return out


def icon() -> Img:
    return _upscale(icon_grid(), ICON_SCALE)


def splash() -> Img:
    """Boot splash: logo + studio name on a dark backdrop the same shade the
    game fades in from."""
    img = Img(SPLASH_W, SPLASH_H)
    for y in range(SPLASH_H):
        t = y / (SPLASH_H - 1)
        c = mix(C("#171240"), C("#0a0714"), t * 0.8)
        for x in range(SPLASH_W):
            img.set(x, y, c)
    # vignette-ish side glow
    for x in range(SPLASH_W):
        edge = min(x, SPLASH_W - 1 - x) / (SPLASH_W * 0.5)
        if edge < 0.25:
            for y in range(SPLASH_H):
                img.blend(x, y, alpha(C("#2b2260"), int(70 * (1.0 - edge / 0.25))))
    # emblem
    emblem = _upscale(icon_grid(), 3)
    img.paste(emblem, (SPLASH_W - emblem.w) // 2, 96)
    title = "LAYER DEFENCE"
    itch_assets.draw_text(img, title, (SPLASH_W - itch_assets.text_width(title, 6)) // 2, 330, 6,
                          C("#ffd34d"), C("#120e1c"))
    tag = "A PIXEL ROGUELIKE ARENA"
    itch_assets.draw_text(img, tag, (SPLASH_W - itch_assets.text_width(tag, 2)) // 2, 410, 2,
                          C("#9fe8d6"), C("#120e1c"))
    studio = "BY " + STUDIO.upper()
    itch_assets.draw_text(img, studio, (SPLASH_W - itch_assets.text_width(studio, 3)) // 2, 470, 3,
                          C("#cfc7e4"), C("#120e1c"))
    small = "V" + VERSION
    itch_assets.draw_text(img, small, (SPLASH_W - itch_assets.text_width(small, 2)) // 2, 540, 2,
                          C("#6f6889"), C("#120e1c"))
    return img


def logo(width=1024, height=256) -> Img:
    """Transparent logo strip for the repo / docs."""
    img = Img(width, height)
    title = "LAYER DEFENCE"
    itch_assets.draw_text(img, title, (width - itch_assets.text_width(title, 7)) // 2, 56, 7,
                          C("#ffd34d"), C("#120e1c"))
    tag = "A PIXEL ROGUELIKE ARENA BY " + STUDIO.upper()
    itch_assets.draw_text(img, tag, (width - itch_assets.text_width(tag, 2)) // 2, 168, 2,
                          C("#9fe8d6"), C("#120e1c"))
    return img


def build():
    os.makedirs(GEN, exist_ok=True)
    os.makedirs(DOCS, exist_ok=True)
    itch_assets._save(icon(), os.path.join(GEN, "icon_512.png"))
    itch_assets._save(_upscale(icon_grid(), 4), os.path.join(GEN, "icon_256.png"))
    itch_assets._save(splash(), os.path.join(GEN, "splash_1280x720.png"))
    itch_assets._save(logo(), os.path.join(GEN, "logo_1024x256.png"))
    itch_assets._save(icon(), os.path.join(DOCS, "icon-512.png"))
    print("[branding] icon, splash and logo ->", GEN)


if __name__ == "__main__":
    build()
