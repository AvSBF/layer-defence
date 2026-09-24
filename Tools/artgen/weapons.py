"""Held weapon sheets: 6-frame swing arcs drawn around a pivot."""
from __future__ import annotations

import math

from px import C, Img, alpha, mix, sheet, single
from chars import P

FW, FH = 40, 40
PIVOT = (20.0, 34.0)


def _px(img, x, y, color):
    img.set(round(x), round(y), color)


def _line_rot(img, cx, cy, angle, length, color, width=1.0):
    """Draw a line from the pivot rotated by `angle` (radians)."""
    steps = max(2, int(length * 2))
    for i in range(steps):
        t = i / (steps - 1)
        x = cx + math.cos(angle) * length * t
        y = cy + math.sin(angle) * length * t
        if width <= 1.0:
            _px(img, x, y, color)
        else:
            for o in range(int(width)):
                off = o - width * 0.5
                _px(img, x + math.cos(angle + math.pi / 2) * off,
                    y + math.sin(angle + math.pi / 2) * off, color)


def _blade(img, cx, cy, angle, start, length, inner, outer, edge, tip_color=None):
    for i in range(int(start), int(start + length)):
        for w in (-1, 0, 1):
            x = cx + math.cos(angle) * i + math.cos(angle + math.pi / 2) * w
            y = cy + math.sin(angle) * i + math.sin(angle + math.pi / 2) * w
            col = inner if w == -1 else (outer if w == 1 else edge)
            _px(img, x, y, col)
    tx = cx + math.cos(angle) * (start + length)
    ty = cy + math.sin(angle) * (start + length)
    _px(img, tx, ty, tip_color or edge)


def _arc_angles(frames=6, start=-1.35, end=1.35):
    return [start + (end - start) * (i / (frames - 1)) for i in range(frames)]


# ------------------------------------------------------------------ weapons
def sword_frames():
    frames = []
    for k, a in enumerate(_arc_angles()):
        img = Img(FW, FH)
        cx, cy = PIVOT
        # grip + guard first
        _line_rot(img, cx, cy, a, 5, P["wood_drk"], 2)
        gx = cx + math.cos(a) * 5
        gy = cy + math.sin(a) * 5
        for w in (-3, -2, 2, 3):
            _px(img, gx + math.cos(a + math.pi / 2) * w, gy + math.sin(a + math.pi / 2) * w, P["gold"])
        _blade(img, cx, cy, a, 6, 21, P["steel"], P["steel_drk"], P["steel_lit"], P["white"])
        _blade(img, cx, cy, a, 24, 4, P["steel_lit"], P["steel"], P["white"], P["white"])
        frames.append(img)
    return frames


def dagger_frames():
    frames = []
    for k, a in enumerate(_arc_angles(6, -1.2, 1.2)):
        img = Img(FW, FH)
        cx, cy = PIVOT
        _line_rot(img, cx, cy, a, 4, P["wood_drk"], 2)
        _blade(img, cx, cy, a, 5, 11, P["steel"], P["steel_drk"], P["steel_lit"], P["white"])
        _blade(img, cx, cy, a, 14, 3, P["steel_lit"], P["steel"], P["white"], P["white"])
        # off-hand dagger
        _blade(img, cx, cy, a - 0.5, 5, 9, P["steel_drk"], P["steel_drk"], P["steel"], P["white"])
        frames.append(img)
    return frames


def spear_frames():
    frames = []
    for k, a in enumerate(_arc_angles(6, -1.1, 1.1)):
        img = Img(FW, FH)
        cx, cy = PIVOT
        _line_rot(img, cx, cy, a, 24, P["wood"], 2)
        _line_rot(img, cx, cy, a - 0.04, 24, P["wood_drk"], 1)
        for i in range(24, 31):
            w = 1.5 - (i - 24) * 0.22
            for o in (-w, 0, w):
                x = cx + math.cos(a) * i + math.cos(a + math.pi / 2) * o
                y = cy + math.sin(a) * i + math.sin(a + math.pi / 2) * o
                _px(img, x, y, P["steel_lit"] if o == 0 else P["steel"])
        _px(img, cx + math.cos(a) * 32, cy + math.sin(a) * 32, P["white"])
        # tassel
        gx = cx + math.cos(a) * 22
        gy = cy + math.sin(a) * 22
        for o in range(-2, 3):
            _px(img, gx + math.cos(a + math.pi / 2) * o, gy + math.sin(a + math.pi / 2) * o + 1, P["red"])
        frames.append(img)
    return frames


def hammer_frames():
    frames = []
    for k, a in enumerate(_arc_angles(6, -1.5, 0.9)):
        img = Img(FW, FH)
        cx, cy = PIVOT
        _line_rot(img, cx, cy, a, 17, P["wood"], 3)
        hx = cx + math.cos(a) * 18
        hy = cy + math.sin(a) * 18
        for dy in range(-5, 6):
            for dx in range(-5, 6):
                if abs(dx) + abs(dy) <= 6:
                    rx = hx + math.cos(a) * dx + math.cos(a + math.pi / 2) * dy
                    ry = hy + math.sin(a) * dx + math.sin(a + math.pi / 2) * dy
                    col = P["steel"]
                    if dx < -2:
                        col = P["steel_lit"]
                    elif dx > 2:
                        col = P["steel_drk"]
                    if abs(dx) + abs(dy) >= 5:
                        col = C("#2a2432")
                    _px(img, rx, ry, col)
        _px(img, hx, hy, P["gold"])
        frames.append(img)
    return frames


def scythe_frames():
    frames = []
    for k, a in enumerate(_arc_angles(6, -1.4, 1.2)):
        img = Img(FW, FH)
        cx, cy = PIVOT
        _line_rot(img, cx, cy, a, 22, C("#2b2340"), 2)
        # curved blade
        for i in range(12):
            t = i / 11.0
            ang = a + 0.9 - t * 1.5
            dist = 22 + t * 7
            x = cx + math.cos(ang) * dist
            y = cy + math.sin(ang) * dist
            _px(img, x, y, P["steel_lit"] if t < 0.5 else P["steel"])
            _px(img, x, y + 1, P["steel_drk"])
        _px(img, cx + math.cos(a) * 22, cy + math.sin(a) * 22, P["slime_lit"])
        frames.append(img)
    return frames


def bow_frames():
    """Grip sits ON the pivot (20,34) so the bow lands in the knight's hand."""
    frames = []
    for k in range(6):
        img = Img(FW, FH)
        cx, cy = 19, 30
        draw = [0.0, 0.4, 0.8, 1.0, 0.3, 0.0][k]
        # bow limbs (upper + lower), bulging forward
        for i in range(-8, 9):
            y = cy + i
            x = cx + int(3 * (1 - (abs(i) / 8.0) ** 2))
            _px(img, x, y, P["wood"])
            _px(img, x + 1, y, P["wood_drk"])
            if abs(i) > 6:
                _px(img, x - 1, y, P["wood_drk"])
        # string, pulled back as the shot charges
        sx = cx + 2 - int(draw * 5)
        for i in range(-8, 9):
            y = cy + i
            t = 1 - abs(i) / 8.0
            _px(img, sx + (1 - t) * 2, y, P["web"])
        # nocked arrow pointing along +x
        ax = sx + 1 if draw > 0.05 else cx + 3
        for i in range(int(draw * 5) + 6):
            _px(img, ax + i, cy, P["wood"])
        _px(img, ax + int(draw * 5) + 7, cy, P["steel_lit"])
        if draw >= 0.99:
            _px(img, ax, cy - 1, P["white"])
            _px(img, ax, cy + 1, P["white"])
        _px(img, cx, cy, P["wood_drk"])
        frames.append(img)
    return frames


def staff_frames():
    """Held leaning forward: the crystal ends up beside the head, not above it."""
    frames = []
    for k in range(6):
        img = Img(FW, FH)
        cx, cy = PIVOT
        charge = [0.0, 0.35, 0.7, 1.0, 0.6, 0.2][k]
        a = -1.15 + k * 0.09
        _line_rot(img, cx, cy, a, 17, P["wood"], 2)
        _line_rot(img, cx, cy, a + 0.06, 17, P["wood_drk"], 1)
        tx = cx + math.cos(a) * 18
        ty = cy + math.sin(a) * 18
        if charge > 0:
            r = 2 + charge * 2.6
            img.ellipse(tx, ty, r + 1, r + 1, alpha(P["cyan"], int(90 * charge) + 40))
            img.ellipse(tx, ty, r, r, alpha(P["robe_lit"], 180))
            img.ellipse(tx, ty, max(1.0, r - 2), max(1.0, r - 2), P["white"])
        else:
            img.ellipse(tx, ty, 2, 2, P["teal"])
        for s_i in range(3):
            ang = a + s_i * 2.0 + charge * 3.0
            _px(img, tx + math.cos(ang) * (4 + charge * 3), ty + math.sin(ang) * (4 + charge * 3), P["cyan"])
        frames.append(img)
    return frames


# -------------------------------------------------------------------- icons
def weapon_icon(kind):
    img = Img(16, 16)
    if kind == "sword":
        img.rect(7, 1, 2, 10, P["steel_lit"])
        img.rect(5, 11, 6, 2, P["gold"])
        img.rect(7, 13, 2, 3, P["wood_drk"])
    elif kind == "dagger":
        img.rect(5, 3, 2, 7, P["steel_lit"])
        img.rect(4, 10, 4, 1, P["gold"])
        img.rect(5, 11, 2, 3, P["wood_drk"])
        img.rect(9, 6, 2, 5, P["steel"])
        img.rect(9, 11, 2, 2, P["wood_drk"])
    elif kind == "spear":
        img.rect(2, 13, 11, 2, P["wood"])
        img.rect(11, 2, 2, 11, P["steel_lit"])
        img.rect(12, 3, 2, 2, P["steel"])
        img.rect(9, 4, 4, 3, P["steel"])
    elif kind == "hammer":
        img.rect(7, 6, 2, 10, P["wood"])
        img.rect(3, 2, 10, 6, P["steel"])
        img.rect(3, 2, 10, 2, P["steel_lit"])
        img.border(3, 2, 10, 6, C("#2a2432"), 1)
    elif kind == "scythe":
        img.rect(3, 3, 2, 13, C("#2b2340"))
        for i in range(8):
            img.set(5 + i, 3 + int(i * 0.6), P["steel_lit"])
            img.set(5 + i, 4 + int(i * 0.6), P["steel"])
        img.set(11, 8, P["steel_lit"])
    elif kind == "bow":
        for i in range(-6, 7):
            img.set(4 + int(3 * (1 - (abs(i) / 6.0) ** 2)), 8 + i, P["wood"])
            img.set(5 + int(3 * (1 - (abs(i) / 6.0) ** 2)), 8 + i, P["wood_drk"])
        img.rect(4, 2, 1, 13, P["web"])
        img.rect(6, 8, 8, 1, P["wood"])
        img.rect(13, 7, 2, 3, P["steel_lit"])
    elif kind == "staff":
        img.rect(6, 5, 2, 11, P["wood"])
        img.circle(7, 4, 3, P["robe_lit"])
        img.circle(7, 4, 2, P["cyan"])
        img.circle(7, 4, 1, P["white"])
    img.outline(P["out"], diagonals=False)
    return img


def build():
    sheet(sword_frames(), "Weapons/sword_swing.png")
    sheet(dagger_frames(), "Weapons/dagger_swing.png")
    sheet(spear_frames(), "Weapons/spear_swing.png")
    sheet(hammer_frames(), "Weapons/hammer_swing.png")
    sheet(scythe_frames(), "Weapons/scythe_swing.png")
    sheet(bow_frames(), "Weapons/bow_swing.png")
    sheet(staff_frames(), "Weapons/staff_swing.png")
    for kind in ("sword", "dagger", "spear", "hammer", "scythe", "bow", "staff"):
        single(weapon_icon(kind), "Weapons/icon_%s.png" % kind)
