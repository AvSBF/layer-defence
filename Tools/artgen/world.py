"""Background, parallax layers and terrain tiles."""
from __future__ import annotations

import math
import random

from px import C, Img, alpha, mix, sheet, single
from chars import P

SKY_TOP = C("#0b0a1e")
SKY_MID = C("#241a4a")
SKY_BOT = C("#4a2a5e")
HILL_FAR = C("#2a2347")
HILL_MID = C("#1e1a35")
TREE = C("#171327")
DIRT = C("#3a2a34")
DIRT_LIT = C("#54404a")
DIRT_DRK = C("#241a24")
GRASS = C("#3f8f6a")
GRASS_LIT = C("#5fc78f")
GRASS_DRK = C("#2a6350")
STONE = C("#5a5266")
STONE_LIT = C("#7d7488")
STONE_DRK = C("#3a3444")


def sky(w=480, h=270):
    img = Img(w, h)
    for y in range(h):
        t = y / (h - 1)
        if t < 0.55:
            c = mix(SKY_TOP, SKY_MID, t / 0.55)
        else:
            c = mix(SKY_MID, SKY_BOT, (t - 0.55) / 0.45)
        for x in range(w):
            img.set(x, y, c)
    rnd = random.Random(2024)
    for _ in range(120):
        x = rnd.randrange(w)
        y = rnd.randrange(int(h * 0.7))
        b = rnd.choice([160, 200, 235, 255])
        img.set(x, y, alpha(C("#dfe6ff"), b))
    # moon
    mx, my = 380, 48
    img.circle(mx, my, 22, alpha(C("#7fe6cf"), 40))
    img.circle(mx, my, 16, C("#e8f4ff"))
    img.circle(mx - 5, my - 4, 4, C("#c9d8ea"))
    img.circle(mx + 6, my + 5, 3, C("#c9d8ea"))
    img.circle(mx + 2, my - 8, 2, C("#c9d8ea"))
    # nebula wisps
    for _ in range(14):
        x = rnd.randrange(w)
        y = rnd.randrange(int(h * 0.5))
        rr = rnd.randrange(20, 60)
        img.ellipse(x, y, rr, rr * 0.25, alpha(C("#6b4fa0"), 14))
    return img


def hills_far(w=480, h=140):
    img = Img(w, h)
    rnd = random.Random(99)
    peaks = []
    x = -20
    while x < w + 40:
        peaks.append((x, rnd.randrange(30, 90), rnd.randrange(40, 90)))
        x += rnd.randrange(50, 90)
    for (px, ph, pw) in peaks:
        for dx in range(-pw, pw + 1):
            t = 1 - abs(dx) / pw
            top = h - ph * t
            for y in range(int(top), h):
                img.set(px + dx, y, mix(HILL_FAR, C("#171233"), y / h))
    for y in range(h):
        for x in range(w):
            if img.px[y][x][3] > 0 and (x + y) % 5 == 0:
                img.px[y][x] = mix(img.px[y][x], C("#3a3560"), 0.5)
    return img


def hills_mid(w=480, h=120):
    img = Img(w, h)
    rnd = random.Random(31337)
    for i in range(6):
        cx = rnd.randrange(0, w)
        r = rnd.randrange(60, 130)
        hh = rnd.randrange(40, 80)
        for dx in range(-r, r + 1):
            t = 1 - abs(dx) / r
            top = h - hh * (t ** 1.6)
            for y in range(int(top), h):
                img.set(cx + dx, y, mix(HILL_MID, C("#0f0c1e"), y / h))
    # trees on the ridge
    for _ in range(26):
        x = rnd.randrange(w)
        y = rnd.randrange(h - 45, h - 8)
        th = rnd.randrange(12, 26)
        _tree(img, x, y, th, rnd)
    return img


def _tree(img, x, y, h, rnd):
    col = TREE
    for i in range(h):
        wdt = max(1, (h - i) // 5 + 1)
        for dx in range(-wdt, wdt):
            img.set(x + dx, y - i, col)
    for (bx, by) in ((x - 4, y - h + 4), (x + 4, y - h + 8), (x, y - h - 2)):
        img.circle(bx, by, 4, col)


def ground_tiles():
    """Returns (top row tile 16x10, filler tile 16x16)."""
    top = Img(16, 10)
    rnd = random.Random(5)
    for x in range(16):
        gh = 3 + (1 if (x % 5 == 0) else 0)
        for y in range(gh):
            top.set(x, y, GRASS_LIT if y == 0 else GRASS if y == 1 else GRASS_DRK)
        for y in range(gh, 10):
            top.set(x, y, DIRT_LIT if y == gh else DIRT)
    for _ in range(10):
        top.set(rnd.randrange(16), rnd.randrange(2, 4), GRASS_DRK)
    filler = Img(16, 16)
    for y in range(16):
        for x in range(16):
            filler.set(x, y, DIRT if (x + y) % 3 else mix(DIRT, DIRT_DRK, 0.5))
    for _ in range(14):
        filler.set(rnd.randrange(16), rnd.randrange(16), rnd.choice([DIRT_LIT, DIRT_DRK, C("#4a3a30")]))
    return top, filler


def platform_img(w=96, h=16):
    img = Img(w, h)
    for y in range(h):
        t = y / (h - 1)
        for x in range(w):
            col = mix(STONE_LIT, STONE_DRK, t)
            img.set(x, y, col)
    # brick lines
    for y in range(0, h, 5):
        for x in range(w):
            img.set(x, y, STONE_DRK)
    for row, y in enumerate(range(0, h, 5)):
        off = (row % 2) * 6
        for x in range(off, w, 12):
            for yy in range(y, min(h, y + 5)):
                img.set(x, yy, STONE_DRK)
    # mossy top
    rnd = random.Random(77)
    for x in range(w):
        if rnd.random() < 0.8:
            img.set(x, 0, GRASS)
            img.set(x, 1, GRASS_DRK if rnd.random() < 0.4 else GRASS)
    img.rect(0, h - 2, w, 2, C("#2a2432"))
    return img


def pillar():
    img = Img(24, 72)
    img.rect(4, 4, 16, 68, STONE)
    img.rect(4, 4, 3, 68, STONE_LIT)
    img.rect(17, 4, 3, 68, STONE_DRK)
    img.rect(0, 0, 24, 6, STONE_LIT)
    img.rect(0, 66, 24, 6, STONE_DRK)
    for i in range(5):
        img.rect(4, 12 + i * 12, 16, 2, STONE_DRK)
    return img


def bush():
    img = Img(20, 14)
    img.ellipse(10, 9, 9, 5, GRASS_DRK)
    img.ellipse(7, 7, 5, 4, GRASS)
    img.ellipse(14, 8, 4, 3, GRASS)
    img.ellipse(6, 6, 2, 1.5, GRASS_LIT)
    return img


def torch_frames():
    frames = []
    for i in range(4):
        img = Img(10, 20)
        img.rect(4, 8, 2, 12, C("#5c3a21"))
        img.rect(3, 6, 4, 3, C("#3a3444"))
        h = 4 + (i % 2)
        img.ellipse(5, 5 - h * 0.2, 2.6, h, P["fire_drk"])
        img.ellipse(5, 4 - h * 0.2, 1.6, h * 0.7, P["fire"])
        img.ellipse(5, 3, 1, 1.4, P["fire_lit"])
        frames.append(img)
    return frames


def build():
    single(sky(), "World/sky.png")
    single(hills_far(), "World/hills_far.png")
    single(hills_mid(), "World/hills_mid.png")
    top, filler = ground_tiles()
    single(top, "World/ground_top.png")
    single(filler, "World/ground_fill.png")
    single(platform_img(96, 16), "World/platform.png")
    single(platform_img(48, 16), "World/platform_small.png")
    single(pillar(), "World/pillar.png")
    single(bush(), "World/bush.png")
    sheet(torch_frames(), "World/torch.png")
