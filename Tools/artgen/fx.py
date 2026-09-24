"""Effects, pickups, props and projectiles."""
from __future__ import annotations

import math
import random

from px import C, Img, alpha, mix, sheet, single, shift  # noqa: F401
from chars import P


def rng(seed):
    return random.Random(seed)


# --------------------------------------------------------------- generic bits
def ring(img, cx, cy, r, color, thickness=1.0, t=1.0):
    steps = max(12, int(r * 8))
    for i in range(steps):
        a = (i / steps) * math.tau
        rr = r
        for k in range(int(thickness) + 1):
            x = cx + math.cos(a) * (rr - k * 0.6)
            y = cy + math.sin(a) * (rr - k * 0.6) * 0.55
            img.set(x, y, color)
    return img


def star_burst(size, color_a, color_b, spikes=6, r_inner=1.5, r_outer=None, offset=0.0, seed=1):
    img = Img(size, size)
    cx = cy = (size - 1) / 2
    r_outer = r_outer or size / 2 - 1
    r = rng(seed)
    for i in range(spikes):
        a = (i / spikes) * math.tau + offset
        length = r_outer * r.uniform(0.75, 1.0)
        steps = int(length * 3)
        for s in range(steps):
            t = s / max(1, steps - 1)
            x = cx + math.cos(a) * length * t
            y = cy + math.sin(a) * length * t * 0.85
            img.set(round(x), round(y), color_b if t > 0.6 else color_a)
            if t < 0.35:
                img.set(round(x), round(y) + 1, color_a)
    return img


# --------------------------------------------------------------------- hit fx
def hit_fx():
    frames = []
    for i in range(4):
        img = star_burst(16, P["white"], P["gold"], spikes=5 + i, r_outer=2 + i * 2.2,
                         offset=i * 0.5, seed=10 + i)
        if i >= 2:
            img = _fade(img, 255 - (i - 1) * 60)
        frames.append(img)
    return frames


def death_fx():
    frames = []
    r = rng(7)
    for i in range(5):
        img = Img(20, 20)
        for p in range(10):
            ang = r.random() * math.tau
            dist = (i + 1) * 1.6
            x = 10 + math.cos(ang) * dist
            y = 10 + math.sin(ang) * dist * 0.7
            col = [P["white"], P["gold"], P["fire"], P["fire_drk"]][min(3, i)]
            img.circle(x, y, max(0.6, 2.2 - i * 0.35), col)
        frames.append(img)
    return frames


def slash_fx(color_a, color_b, seed=3):
    frames = []
    for i in range(4):
        img = Img(36, 36)
        r1 = 6 + i * 3.5
        for a_i in range(30):
            a = -1.1 + (a_i / 29.0) * 2.2
            x = 18 + math.cos(a) * r1
            y = 18 + math.sin(a) * r1 * 0.75
            img.set(x, y, color_a)
            img.set(x, y + 1, color_b)
            if i < 2:
                img.set(x + math.cos(a), y + math.sin(a) * 0.5, P["white"])
        if i >= 2:
            img = _fade(img, 255 - (i - 1) * 70)
        frames.append(img)
    return frames


def explosion_fx():
    frames = []
    r = rng(21)
    for i in range(6):
        img = Img(36, 36)
        rr = 3 + i * 3.0
        for a_i in range(64):
            a = r.uniform(0, math.tau)
            d = rr * r.uniform(0.5, 1.0)
            x = 18 + math.cos(a) * d
            y = 18 + math.sin(a) * d * 0.8
            t = d / max(1, rr)
            col = P["fire_lit"] if t < 0.4 else (P["fire"] if t < 0.75 else P["fire_drk"])
            img.circle(x, y, max(0.7, 2.6 - i * 0.35), col)
        if i >= 4:
            img = _fade(img, 255 - (i - 4) * 90)
        frames.append(img)
    return frames


def dust_fx(scale=1.0):
    frames = []
    r = rng(33)
    for i in range(4):
        img = Img(16, 16)
        for p in range(7):
            ang = r.uniform(0, math.pi * 2)
            d = (i + 1) * 1.7 * scale
            x = 8 + math.cos(ang) * d
            y = 12 + math.sin(ang) * d * 0.35 - i * 0.6
            img.circle(x, y, max(0.6, 2.0 - i * 0.4) * scale, alpha(P["bone_drk"], 200 - i * 40))
        frames.append(img)
    return frames


def shockwave_fx():
    frames = []
    for i in range(4):
        img = Img(48, 24)
        rr = 6 + i * 6
        ring(img, 24, 18, rr, alpha(P["gold"], 230 - i * 50), thickness=2 - i * 0.3)
        frames.append(img)
    return frames


# ----------------------------------------------------------------- effects
def teleport_fx():
    frames = []
    for i in range(4):
        img = Img(24, 26)
        h = 26 - i * 4
        for y in range(h):
            t = y / max(1, h)
            wdt = (1 - t) * 6 + 1
            for x in range(int(12 - wdt), int(12 + wdt)):
                if (x + y) % 2 == 0:
                    img.set(x, y + i * 4, alpha(P["robe_lit"], 220 - i * 30))
        frames.append(img)
    return frames


def spawn_fx():
    frames = []
    for i in range(4):
        img = Img(26, 26)
        rr = 12 - i * 2.5
        ring(img, 13, 13, rr, alpha(P["robe_lit"], 230 - i * 40), thickness=2)
        for a_i in range(8):
            a = a_i / 8 * math.tau + i * 0.4
            img.circle(13 + math.cos(a) * rr, 13 + math.sin(a) * rr * 0.6, 1.4,
                       alpha(P["white"], 200 - i * 40))
        frames.append(img)
    return frames


def heal_fx():
    frames = []
    for i in range(4):
        img = Img(16, 18)
        y = 14 - i * 3
        img.rect(7, y - 4, 2, 8, P["slime_lit"])
        img.rect(4, y - 1, 8, 2, P["slime_lit"])
        img.circle(4, y - 6, 1, alpha(P["white"], 220 - i * 40))
        img.circle(12, y - 3, 1, alpha(P["white"], 200 - i * 40))
        frames.append(img)
    return frames


def coin_pop_fx():
    frames = []
    for i in range(4):
        img = Img(12, 12)
        rr = 1.5 + i * 1.6
        ring(img, 6, 6, rr, alpha(P["gold_lit"], 230 - i * 55), thickness=1.2)
        frames.append(img)
    return frames


def freeze_spark(seed=5):
    frames = []
    r = rng(seed)
    for i in range(4):
        img = Img(18, 18)
        for p in range(6):
            a = r.uniform(0, math.tau)
            d = i * 2.0
            img.set(9 + math.cos(a) * d, 9 + math.sin(a) * d, alpha(P["cyan"], 230 - i * 50))
        frames.append(img)
    return frames


def telegraph_fx():
    frames = []
    for i in range(3):
        img = Img(56, 20)
        a = 120 + i * 60
        ring(img, 28, 14, 22, alpha(P["red"], a), thickness=1.5)
        for k in range(6):
            ang = k / 6 * math.tau
            img.set(28 + math.cos(ang) * 22, 14 + math.sin(ang) * 22 * 0.5, alpha(P["red_lit"], a))
        frames.append(img)
    return frames


# ------------------------------------------------------------------- portal
def portal_frames():
    frames = []
    for i in range(6):
        img = Img(48, 64)
        # outer stone arch
        img.rect(4, 8, 40, 8, P["stone_drk"])
        img.rect(4, 8, 40, 2, P["stone"])
        img.rect(0, 16, 8, 48, P["stone_drk"])
        img.rect(40, 16, 8, 48, P["stone_drk"])
        img.rect(0, 16, 2, 48, P["stone"])
        img.rect(46, 16, 2, 48, P["stone"])
        for s in range(4):
            img.rect(2, 20 + s * 11, 4, 6, P["stone"])
            img.rect(42, 20 + s * 11, 4, 6, P["stone"])
        # glowing swirl inside
        cx, cy = 24, 40
        for y in range(12, 64):
            for x in range(6, 42):
                dx = (x - cx) / 18.0
                dy = (y - cy) / 26.0
                d = dx * dx + dy * dy
                if d <= 1.0:
                    swirl = math.sin((math.atan2(dy, dx) * 3 + d * 6 - i * 1.1) * 1.6)
                    t = (swirl + 1) / 2
                    col = mix(P["robe_drk"], P["robe_lit"], t)
                    if d > 0.72:
                        col = mix(col, P["white"], (d - 0.72) * 2)
                    img.set(x, y, col)
                    if (x + y + i * 3) % 7 == 0 and d < 0.5:
                        img.set(x, y, P["white"])
        frames.append(img)
    return frames


def portal_base():
    img = Img(64, 16)
    img.rect(0, 6, 64, 10, P["stone_drk"])
    img.rect(0, 6, 64, 2, P["stone"])
    for i in range(6):
        img.rect(4 + i * 10, 2, 6, 6, P["stone"])
        img.set(4 + i * 10, 2, P["stone_lit"])
    return img


# ---------------------------------------------------------------- wave gate
def wave_gate_frames():
    frames = []
    for i in range(6):
        img = Img(64, 56)
        pulse = 0.5 + 0.5 * math.sin(i / 6.0 * math.tau)
        # floor glow ellipse
        for y in range(28, 52):
            for x in range(4, 60):
                dx = (x - 32) / 28.0
                dy = (y - 40) / 12.0
                d = dx * dx + dy * dy
                if d <= 1.0:
                    a = int(150 * (1 - d) * (0.6 + 0.4 * pulse))
                    img.set(x, y, alpha(P["slime"], a))
        # pillar of light
        for y in range(0, 40):
            wdt = int(6 + 10 * pulse * (y / 40.0))
            a = int(120 * (y / 40.0) ** 1.5 * (0.7 + 0.3 * pulse))
            for x in range(int(32 - wdt), int(32 + wdt)):
                img.set(x, y, alpha(P["slime_lit"], a))
        # ground ring
        ring(img, 32, 40, 26 - pulse * 2, alpha(P["slime_lit"], 200), thickness=2)
        # arrow above
        ay = 6 + int(pulse * 3)
        img.rect(28, ay, 9, 6, P["slime_lit"])
        img.rect(26, ay + 6, 13, 3, P["slime_lit"])
        img.rect(24, ay + 9, 17, 3, P["slime_lit"])
        img.rect(28, ay, 9, 2, P["white"])
        frames.append(img)
    return frames


# --------------------------------------------------------------------- pots
def pot():
    img = Img(16, 16)
    body = C("#b5613f")
    lit = C("#e0895c")
    drk = C("#7a3722")
    img.rect(4, 3, 8, 2, drk)
    img.rect(3, 5, 10, 2, body)
    img.rect(3, 5, 10, 1, lit)
    img.rect(2, 7, 12, 6, body)
    img.rect(2, 7, 12, 1, lit)
    img.rect(3, 13, 10, 2, drk)
    img.rect(1, 6, 2, 4, lit)
    img.rect(13, 6, 2, 4, drk)
    # decorative band
    img.rect(2, 9, 12, 1, P["gold_drk"])
    img.set(7, 9, P["gold"])
    img.set(8, 9, P["gold"])
    img.outline(P["out"], diagonals=False)
    return img


def pot_break_frames():
    frames = []
    r = rng(11)
    shards = [(r.uniform(-1, 1), r.uniform(-1, 0.4)) for _ in range(8)]
    for i in range(5):
        img = Img(32, 24)
        for si, (sx, sy) in enumerate(shards):
            x = 16 + sx * (2 + i * 3.2)
            y = 14 + sy * (2 + i * 2.6) + i * 1.6
            if y > 22:
                continue
            col = [C("#e0895c"), C("#b5613f"), C("#7a3722")][si % 3]
            w = max(1, 3 - i // 2)
            img.rect(x, y, w, w, col)
        if i >= 3:
            img = _fade(img, 255 - (i - 3) * 100)
        frames.append(img)
    return frames



def chest_frames():
    """Closed wooden chest with a gold band - 2 frame idle (sparkle pulse)."""
    wood = C("#b06a34")
    wood_lit = C("#d9924f")
    wood_drk = C("#6f3c1c")
    frames = []
    for i in range(2):
        img = Img(18, 17)
        # body
        img.rect(1, 7, 16, 9, wood)
        img.rect(1, 7, 16, 1, wood_lit)
        img.rect(1, 15, 16, 1, wood_drk)
        img.rect(1, 7, 1, 9, wood_lit)
        img.rect(16, 7, 1, 9, wood_drk)
        # lid
        img.rect(1, 2, 16, 5, wood_lit)
        img.rect(1, 2, 16, 1, C("#f0b06a"))
        img.rect(1, 6, 16, 1, wood_drk)
        img.rect(1, 2, 1, 5, C("#f0b06a"))
        # metal corners + bands
        img.rect(4, 2, 2, 14, P["gold_drk"])
        img.rect(12, 2, 2, 14, P["gold_drk"])
        img.rect(4, 2, 2, 1, P["gold"])
        img.rect(12, 2, 2, 1, P["gold"])
        # lock
        img.rect(8, 7, 3, 3, P["gold"])
        img.rect(8, 7, 3, 1, P["gold_lit"])
        img.set(9, 9, C("#6f3c1c"))
        if i == 1:
            img.set(0, 0, alpha(P["white"], 200))
            img.set(17, 2, alpha(P["white"], 160))
            img.set(2, 0, alpha(P["white"], 120))
        img.outline(P["out"], diagonals=False)
        frames.append(img)
    return frames


def chest_break_frames():
    """Lid pops open, coins fountain out."""
    frames = []
    rnd = rng(23)
    for i in range(6):
        img = Img(34, 28)
        # body sits on the ground, lid flies up
        img.rect(6, 16, 22, 11, C("#b06a34"))
        img.rect(6, 16, 22, 1, C("#d9924f"))
        img.rect(6, 26, 22, 1, C("#6f3c1c"))
        img.rect(9, 16, 2, 11, P["gold_drk"])
        img.rect(23, 16, 2, 11, P["gold_drk"])
        lid_y = 16 - i * 2 - max(0, i - 2)
        if lid_y > -6:
            img.rect(4, lid_y, 26, 5, C("#d9924f"))
            img.rect(4, lid_y, 26, 1, C("#f0b06a"))
            img.rect(6, lid_y, 2, 5, P["gold_drk"])
            img.rect(26, lid_y, 2, 5, P["gold_drk"])
        # coin fountain
        for k in range(min(8, 2 + i)):
            ang = -1.6 + rnd.uniform(-0.7, 0.7)
            d = 3 + i * 3.4
            cx = 17 + math.cos(ang) * d * 0.7
            cy = 15 + math.sin(ang) * d
            img.circle(cx, cy, 1.6, P["gold"])
            img.set(cx, cy - 1, P["gold_lit"])
        if i >= 4:
            img = _fade(img, 255 - (i - 4) * 90)
        frames.append(img)
    return frames


# ----------------------------------------------------------------- pickups
def coin_frames():
    frames = []
    for i in range(8):
        img = Img(12, 12)
        # spin squash: cos of phase
        w = [5, 4, 2, 1, 1, 2, 4, 5][i]
        x0 = 6 - w / 2.0
        img.ellipse(5.5, 5.5, max(1, w / 2.0), 5, P["gold"])
        img.ellipse(5.5, 5.5, max(0.7, w / 2.0 - 1), 3.6, P["gold_lit"])
        if w >= 2:
            img.rect(5.5, 3, max(1, w - 2), 5, P["gold_lit"])
        if w <= 2:
            img.rect(x0 + 0.5, 3, 1, 5, P["gold_drk"])
        img.outline(P["out"], diagonals=False)
        # sparkle
        if i in (1, 5):
            img.set(9, 2, P["white"])
        frames.append(img)
    return frames


def heart_frames():
    frames = []
    for i in range(2):
        img = Img(11, 10)
        c = P["red"]
        lit = P["red_lit"]
        img.rect(1, 2, 3, 3, c)
        img.rect(6, 2, 3, 3, c)
        img.rect(2, 1, 2, 2, c)
        img.rect(6, 1, 2, 2, c)
        img.rect(1, 4, 8, 2, c)
        img.rect(2, 6, 6, 1, c)
        img.rect(3, 7, 4, 1, c)
        img.rect(4, 8, 2, 1, c)
        img.rect(2, 2, 2, 1, lit)
        img.rect(2, 3, 1, 1, lit)
        if i == 1:
            img.rect(1, 2, 8, 6, alpha(P["white"], 0))
            img.circle(1, 1, 1, alpha(P["white"], 150))
            img.circle(8, 1, 1, alpha(P["white"], 150))
        img.outline(P["out"], diagonals=False)
        frames.append(img)
    return frames


def gem_frames():
    frames = []
    for i in range(4):
        img = Img(12, 12)
        base = P["teal"]
        lit = P["teal_lit"]
        img.rect(3, 2, 6, 2, lit)
        img.rect(2, 4, 8, 3, base)
        img.rect(3, 7, 6, 2, P["teal_drk"])
        img.rect(4, 9, 4, 1, P["teal_drk"])
        img.set(4, 3, P["white"])
        if i % 2 == 1:
            img.set(2, 1, alpha(P["white"], 160))
            img.set(9, 2, alpha(P["white"], 140))
        img.outline(P["out"], diagonals=False)
        frames.append(img)
    return frames


# --------------------------------------------------------------- projectiles
def arrow():
    img = Img(16, 6)
    img.rect(2, 2, 11, 2, P["wood"])
    img.rect(2, 2, 11, 1, P["wood_drk"])
    img.rect(12, 1, 3, 4, P["steel_lit"])
    img.set(15, 2, P["steel_lit"])
    img.set(15, 3, P["steel_lit"])
    img.rect(0, 1, 2, 1, P["web"])
    img.rect(0, 4, 2, 1, P["web"])
    img.rect(1, 2, 1, 2, P["web"])
    img.outline(P["out"], diagonals=False)
    return img


def fireball_frames():
    frames = []
    for i in range(4):
        img = Img(12, 12)
        flick = (i % 2) * 0.6
        img.circle(6, 6, 4 + flick, P["fire_drk"])
        img.circle(6, 6, 3, P["fire"])
        img.circle(5.5, 5.5, 1.6, P["fire_lit"])
        # tail
        img.set(0, 6 + (i % 2), alpha(P["fire"], 160))
        img.set(1, 5, alpha(P["fire"], 120))
        frames.append(img)
    return frames


def orb_frames():
    frames = []
    for i in range(4):
        img = Img(12, 12)
        rr = 3 + (i % 2) * 0.5
        img.circle(6, 6, rr, P["robe_lit"])
        img.circle(6, 6, rr - 1.2, P["cyan"])
        img.circle(5.5, 5.5, 1, P["white"])
        for k in range(4):
            a = k / 4 * math.tau + i * 0.5
            img.set(6 + math.cos(a) * (rr + 1), 6 + math.sin(a) * (rr + 1), alpha(P["cyan"], 170))
        frames.append(img)
    return frames


def bone_frames():
    frames = []
    for i in range(4):
        img = Img(12, 8)
        img.rect(2, 3, 8, 2, P["bone"])
        img.rect(2, 3, 8, 1, P["white"])
        img.circle(1.5, 2.5, 1.6, P["bone"])
        img.circle(1.5, 5.5, 1.6, P["bone"])
        img.circle(10.5, 2.5, 1.6, P["bone"])
        img.circle(10.5, 5.5, 1.6, P["bone"])
        if i % 2:
            img.set(6, 3, P["bone_drk"])
            img.set(8, 4, P["bone_drk"])
        img.outline(P["out"], diagonals=False)
        frames.append(img)
    return frames


def skull_frames():
    frames = []
    for i in range(4):
        img = Img(12, 12)
        img.circle(6, 6, 4, P["bone"])
        img.rect(4, 8, 5, 2, P["bone"])
        img.rect(4, 5, 2, 2, P["black"])
        img.rect(7, 5, 2, 2, P["black"])
        img.set(5, 5, P["slime_lit"] if i % 2 else P["red_lit"])
        img.set(8, 5, P["slime_lit"] if i % 2 else P["red_lit"])
        img.outline(P["out"], diagonals=False)
        frames.append(img)
    return frames


def bomb_frames():
    frames = []
    for i in range(4):
        img = Img(14, 14)
        img.circle(7, 8, 4.5, P["black"])
        img.circle(6, 7, 2.2, shift(P["black"], 35))
        img.rect(6, 3, 2, 2, P["wood_drk"])
        img.set(8, 2, P["wood_drk"])
        spark = [P["fire"], P["fire_lit"], P["white"], P["fire_lit"]][i]
        img.set(9, 1, spark)
        img.set(10, 0, alpha(spark, 180))
        img.outline(P["out"], diagonals=False)
        frames.append(img)
    return frames


def web():
    img = Img(24, 12)
    col = alpha(P["web"], 210)
    for i in range(5):
        img.line(i * 6, 0, i * 6, 11, col)
    for j in range(3):
        img.line(0, j * 5 + 1, 23, j * 5 + 1, col)
    img.line(0, 0, 23, 11, col)
    img.line(23, 0, 0, 11, col)
    return img


def shard():
    img = Img(10, 10)
    img.rect(5, 0, 2, 4, P["stone"])
    img.rect(3, 4, 6, 4, P["stone_lit"])
    img.rect(4, 8, 4, 2, P["stone_drk"])
    img.outline(P["out"], diagonals=False)
    return img


def ice_shard():
    img = Img(12, 12)
    img.rect(5, 0, 2, 12, P["cyan"])
    img.rect(2, 3, 8, 6, P["cyan"])
    img.rect(4, 2, 4, 8, alpha(P["white"], 200))
    return img


# -------------------------------------------------------------------- exports
def _fade(img, a):
    out = img.copy()
    for y in range(out.h):
        for x in range(out.w):
            c = out.px[y][x]
            if c[3] > 0:
                out.px[y][x] = (c[0], c[1], c[2], min(c[3], a))
    return out


def build():
    sheet(hit_fx(), "FX/hit.png")
    sheet(death_fx(), "FX/death.png")
    sheet(slash_fx(P["white"], P["steel_lit"], 1), "FX/slash_steel.png")
    sheet(slash_fx(P["gold_lit"], P["gold"], 2), "FX/slash_gold.png")
    sheet(slash_fx(P["cyan"], P["robe_lit"], 3), "FX/slash_magic.png")
    sheet(explosion_fx(), "FX/explosion.png")
    sheet(dust_fx(), "FX/dust.png")
    sheet(dust_fx(1.4), "FX/dust_big.png")
    sheet(shockwave_fx(), "FX/shockwave.png")
    sheet(teleport_fx(), "FX/teleport.png")
    sheet(spawn_fx(), "FX/spawn.png")
    sheet(heal_fx(), "FX/heal.png")
    sheet(coin_pop_fx(), "FX/coin_pop.png")
    sheet(freeze_spark(), "FX/freeze_spark.png")
    sheet(telegraph_fx(), "FX/telegraph.png")
    sheet(portal_frames(), "Props/portal.png")
    single(portal_base(), "Props/portal_base.png")
    sheet(wave_gate_frames(), "Props/wave_gate.png")
    single(pot(), "Props/pot.png")
    sheet(chest_frames(), "Props/chest.png")
    sheet(chest_break_frames(), "Props/chest_break.png")
    sheet(pot_break_frames(), "Props/pot_break.png")
    sheet(coin_frames(), "Pickups/coin.png")
    sheet(heart_frames(), "Pickups/heart.png")
    sheet(gem_frames(), "Pickups/gem.png")
    single(arrow(), "Projectiles/arrow.png")
    sheet(fireball_frames(), "Projectiles/fireball.png")
    sheet(orb_frames(), "Projectiles/orb.png")
    sheet(bone_frames(), "Projectiles/bone.png")
    sheet(skull_frames(), "Projectiles/skull.png")
    sheet(bomb_frames(), "Projectiles/bomb.png")
    single(web(), "Projectiles/web.png")
    single(shard(), "Projectiles/shard.png")
    single(ice_shard(), "Projectiles/ice_shard.png")
