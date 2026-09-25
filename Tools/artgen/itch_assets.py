"""Store assets for the itch.io page: cover art rendered with the game's own
pixel font and sprites, plus a title banner. Screenshots are captured from the
real build (see the --shots flag of the demo bot)."""
from __future__ import annotations

import math
import os
import random

from px import C, Img, alpha, mix, single
from chars import P
import world as world_art
import ui as ui_mod

OUT_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "docs", "itch"))

DPI_SCALE = 1


def _load_sheet(name : str) -> Img:
    """Load one of the previously generated PNGs back as an Img."""
    from PIL import Image
    root = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "Aseprites", "Generated"))
    img = Image.open(os.path.join(root, name)).convert("RGBA")
    out = Img(img.width, img.height)
    px = img.load()
    for y in range(img.height):
        for x in range(img.width):
            out.set(x, y, px[x, y])
    return out


def _frame(sheet_path : str, frame_w : int, index : int, frame_h : int = 0) -> Img:
    sheet = _load_sheet(sheet_path)
    fh = frame_h if frame_h > 0 else sheet.h
    out = Img(frame_w, fh)
    for y in range(fh):
        for x in range(frame_w):
            out.set(x, y, sheet.get(index * frame_w + x, y))
    return out


def draw_text(img : Img, text : str, x : int, y : int, scale : int, color, outline=None) -> int:
    """Render with the game's own 5x7 bitmap font. Returns the end x.

    Two passes (all outlines first, then all pixels) - drawing pixel-by-pixel
    lets a later glyph's outline eat an earlier glyph's fill at large scales.
    """
    lit = []
    cx = x
    for ch in text.upper():
        rows = ui_mod.G.get(ch, ui_mod.G["?"]).split("/")
        for ry, row in enumerate(rows):
            for rx, c in enumerate(row):
                if c == "#":
                    lit.append((cx + rx * scale, y + ry * scale))
        cx += 6 * scale
    if outline is not None:
        for (lx, ly) in lit:
            for oy in (-1, 0, 1):
                for ox in (-1, 0, 1):
                    if ox == 0 and oy == 0:
                        continue
                    for sy in range(scale):
                        for sx in range(scale):
                            img.set(lx + sx + ox * scale, ly + sy + oy * scale, outline)
    for (lx, ly) in lit:
        for sy in range(scale):
            for sx in range(scale):
                img.set(lx + sx, ly + sy, color)
    return cx


def blit_scaled(img : Img, src : Img, x : int, y : int, scale : int) -> None:
    for sy_ in range(src.h):
        for sx_ in range(src.w):
            c = src.get(sx_, sy_)
            if c[3] == 0:
                continue
            for yy in range(scale):
                for xx in range(scale):
                    img.set(x + sx_ * scale + xx, y + sy_ * scale + yy, c)


def text_width(text : str, scale : int) -> int:
    return len(text) * 6 * scale


def cover(width=630, height=500) -> Img:
    rnd = random.Random(7)
    img = Img(width, height)

    # --- sky gradient (matches the in-game one) ---
    top = C("#241c52")
    mid = C("#4a3488")
    bot = C("#b06a8a")
    for y in range(height):
        t = y / (height - 1)
        if t < 0.55:
            c = mix(top, mid, t / 0.55)
        else:
            c = mix(mid, bot, (t - 0.55) / 0.45)
        for x in range(width):
            img.set(x, y, c)
    for _ in range(90):
        img.blend(rnd.randrange(width), rnd.randrange(int(height * 0.62)),
                  alpha(C("#eaf0ff"), rnd.choice([150, 200, 240])))

    # --- moon ---
    moon = _load_sheet("World/moon.png")
    moon_big = Img(moon.w * 2, moon.h * 2)
    for y in range(moon.h):
        for x in range(moon.w):
            for sy in range(2):
                for sx in range(2):
                    moon_big.set(x * 2 + sx, y * 2 + sy, moon.get(x, y))
    img.paste(moon_big, width - 150, 34)

    # --- hills (stretched to the cover width) ---
    hills = _load_sheet("World/hills_mid.png")
    hill_w = width
    hill_h = int(hills.h * (width / float(hills.w)) * 0.62)
    for y in range(hill_h):
        sy = int(y / hill_h * (hills.h - 1))
        for x in range(hill_w):
            sx = int(x / hill_w * (hills.w - 1))
            c = hills.get(sx, sy)
            if c[3] > 0:
                img.set(x, 210 + y, c)

    # --- ground strip ---
    gtop = _load_sheet("World/ground_top.png")
    gfill = _load_sheet("World/ground_fill.png")
    ground_y = height - 96
    for x in range(width):
        for y in range(10):
            img.set(x, ground_y + y, gtop.get(x % gtop.w, y))
    for y in range(ground_y + 10, height):
        for x in range(width):
            img.set(x, y, gfill.get(x % gfill.w, (y - ground_y) % gfill.h))

    # --- portal + a falling bat ---
    portal = _frame("Props/portal.png", 48, 3, 64)
    pscale = 2
    portal_big = Img(portal.w * pscale, portal.h * pscale)
    for y in range(portal.h):
        for x in range(portal.w):
            for sy in range(pscale):
                for sx in range(pscale):
                    portal_big.set(x * pscale + sx, y * pscale + sy, portal.get(x, y))
    img.paste(portal_big, 58, 26)
    bat = _frame("Enemies/bat_run.png", 16, 1, 12)
    img.paste(bat, 118, 96)

    # --- the knight, mid-swing, with friends at the game's true proportions ---
    hero = _frame("Characters/player_run.png", 16, 3, 24)
    hero_x = 168
    hero_y = ground_y - 24 * 2 + 2
    blit_scaled(img, hero, hero_x, hero_y, 2)
    # sword sheet pivot is (20,34) of a 40x40 frame -> line the grip up with
    # the knight's hand (HAND_OFFSET = 4,2 at 1x, so 8,4 at 2x)
    sword = _frame("Weapons/sword_swing.png", 40, 2, 40)
    blit_scaled(img, sword, hero_x + 8 - 40, hero_y + 4 - 68, 2)

    blit_scaled(img, _frame("Enemies/slime_idle.png", 16, 0, 14), 96, ground_y - 14 * 2, 2)
    blit_scaled(img, _frame("Enemies/slime_idle.png", 16, 2, 14), 372, ground_y - 14 * 2, 2)
    blit_scaled(img, _frame("Enemies/skeleton_run.png", 16, 1, 24), 306, ground_y - 24 * 2, 2)
    blit_scaled(img, _frame("Enemies/bomber_run.png", 16, 1, 22), 430, ground_y - 22 * 2, 2)
    blit_scaled(img, _frame("Enemies/imp_attack.png", 16, 1, 22), 246, ground_y - 22 * 2, 2)
    # a bat swooping in from the portal, plus its drop trail
    blit_scaled(img, _frame("Enemies/bat_run.png", 16, 1, 12), 112, 104, 2)
    for i in range(4):
        img.set(126 + i, 96 + i * 6, alpha(P["robe_lit"], 150 - i * 30))

    # --- loot on the floor ---
    for (cx, cy) in ((92, ground_y + 20), (146, ground_y + 30), (402, ground_y + 22)):
        blit_scaled(img, _frame("Pickups/coin.png", 12, 2, 12), cx, cy, 2)
    blit_scaled(img, _load_sheet("Props/pot.png"), 466, ground_y + 18, 2)
    blit_scaled(img, _frame("Pickups/heart.png", 11, 0, 10), 522, ground_y + 24, 2)

    # --- combat numbers, right where they belong ---
    draw_text(img, "36", 336, 252, 2, P["gold_lit"], C("#120e1c"))
    draw_text(img, "12", 112, 296, 2, P["white"], C("#120e1c"))

    # --- title block ---
    title = "LAYER"
    title2 = "DEFENCE"
    tx = (width - text_width(title, 6)) // 2
    draw_text(img, title, tx, 40, 6, C("#ffd34d"), C("#120e1c"))
    tx2 = (width - text_width(title2, 6)) // 2
    draw_text(img, title2, tx2, 104, 6, C("#ffd34d"), C("#120e1c"))
    tag = "PIXEL ROGUELIKE ARENA"
    draw_text(img, tag, (width - text_width(tag, 2)) // 2, 178, 2, C("#9fe8d6"), C("#120e1c"))

    # --- frame ---
    img.border(0, 0, width, height, C("#ffd34d"), 2)
    img.border(3, 3, width - 6, height - 6, alpha(C("#ffd34d"), 90), 1)
    return img


def build():
    os.makedirs(OUT_DIR, exist_ok=True)
    c = cover()
    path = os.path.join(OUT_DIR, "cover-630x500.png")
    c.save_png(path) if hasattr(c, "save_png") else None
    _save(c, path)
    # itch also likes a wide banner for the project header (optional)
    print("[itch] cover ->", path)


def _save(img : Img, path : str):
    from PIL import Image
    out = Image.new("RGBA", (img.w, img.h))
    out.putdata([img.px[y][x] for y in range(img.h) for x in range(img.w)])
    out.save(path)


if __name__ == "__main__":
    build()
