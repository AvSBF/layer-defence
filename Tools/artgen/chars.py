"""Player, enemy and boss sprites - all generated procedurally."""
from __future__ import annotations

from px import C, Img, alpha, blob, mix, rounded_rect, sheet, shift

# --------------------------------------------------------------------- palettes
P = {
    "out": C("#140f1d"),
    "out_soft": C("#241a33"),
    "steel": C("#96a9c4"),
    "steel_lit": C("#d6e3f5"),
    "steel_drk": C("#5d6c85"),
    "teal": C("#3fb8a2"),
    "teal_lit": C("#7fe6cf"),
    "teal_drk": C("#1f7a6d"),
    "cyan": C("#6ff2ff"),
    "skin": C("#e8b088"),
    "skin_lit": C("#ffd6ae"),
    "skin_drk": C("#b87f5c"),
    "bone": C("#e6e2d3"),
    "bone_drk": C("#a9a48d"),
    "slime": C("#5fd15f"),
    "slime_lit": C("#9bf58a"),
    "slime_drk": C("#2f8f42"),
    "bat": C("#8a6ad1"),
    "bat_lit": C("#b79bf0"),
    "bat_drk": C("#523a8c"),
    "orc": C("#6f9e3f"),
    "orc_lit": C("#9ac45c"),
    "orc_drk": C("#3f6323"),
    "ghost": C("#a8e8ef"),
    "ghost_drk": C("#5fa8bf"),
    "spider": C("#6a4fa3"),
    "spider_drk": C("#3a2870"),
    "stone": C("#8a8f9c"),
    "stone_lit": C("#c0c6d1"),
    "stone_drk": C("#565b66"),
    "moss": C("#4f8f4a"),
    "robe": C("#5b3f9c"),
    "robe_lit": C("#8a6ae0"),
    "robe_drk": C("#33245e"),
    "gold": C("#ffd34d"),
    "gold_lit": C("#fff3a0"),
    "gold_drk": C("#c98f1f"),
    "red": C("#d9484f"),
    "red_lit": C("#ff7a6f"),
    "red_drk": C("#8c2430"),
    "white": C("#f7f7f2"),
    "black": C("#221c2b"),
    "wood": C("#8a5a35"),
    "wood_drk": C("#5c3a21"),
    "web": C("#d8d8e8"),
    "fire": C("#ff9a3c"),
    "fire_lit": C("#ffe066"),
    "fire_drk": C("#e04a2f"),
}


def _sparkle_eye(img, x, y, color):
    img.set(x, y, color)


# ----------------------------------------------------------------- data struct
def body_box(pal, x, y, w, h, lit=True, outline=True):
    """Armored torso with a lit top-left and dark bottom-right."""
    img = Img(w, h)
    img.rect(0, 0, w, h, pal["body"])
    if lit:
        for i in range(w):
            img.set(i, 0, pal["body_lit"])
        for i in range(h):
            img.set(0, i, pal["body_lit"])
        for i in range(w):
            img.set(i, h - 1, pal["body_drk"])
        for i in range(h):
            img.set(w - 1, i, pal["body_drk"])
    if outline:
        pass
    return img


# --------------------------------------------------------------------- player
def player_frames():
    pal = {
        "out": P["out"],
        "body": P["steel"],
        "body_lit": P["steel_lit"],
        "body_drk": P["steel_drk"],
        "cloth": P["teal"],
        "cloth_lit": P["teal_lit"],
        "cloth_drk": P["teal_drk"],
        "skin": P["skin"],
        "skin_drk": P["skin_drk"],
        "eye": P["cyan"],
    }
    anims = {}
    anims["idle"] = [_knight(pal, bob=b, arm=0, leg=(0, 0), cape=b // 2) for b in (0, 1, 1, 0)]
    anims["run"] = [
        _knight(pal, bob=b, arm=a, leg=(l1, l2), cape=-(1 if l1 else 0), tilt=t)
        for (b, a, l1, l2, t) in (
            (1, 1, 2, -2, -1),
            (0, 0, 0, 0, 0),
            (1, -1, -2, 2, 1),
            (0, 0, 0, 0, 0),
            (1, 1, 2, -2, -1),
            (0, 0, 0, 0, 0),
        )
    ]
    anims["jump"] = [_knight(pal, bob=-1, arm=-1, leg=(-2, 1), cape=-2)]
    anims["fall"] = [_knight(pal, bob=1, arm=1, leg=(2, -1), cape=2)]
    anims["hurt"] = [_knight(pal, bob=1, arm=2, leg=(1, 1), cape=1, tint=P["red_lit"])]
    anims["dash"] = [
        _knight(pal, bob=0, arm=1, leg=(2, -2), cape=2, tint=P["cyan"]),
        _knight(pal, bob=0, arm=1, leg=(-2, 2), cape=2, tint=P["cyan"]),
    ]
    anims["death"] = []
    for i in range(6):
        img = _knight(pal, bob=1 + i // 2, arm=2, leg=(1, 1), cape=1)
        img = _squash(img, i / 5.0)
        img = _fade(img, 255 - int(i * 42))
        anims["death"].append(img)
    return anims


def _knight(pal, bob=0, arm=0, leg=(0, 0), cape=0, tilt=0, tint=None):
    """16x24 knight. arm/leg are pixel offsets, bob shifts the torso up."""
    img = Img(16, 24)
    base_y = 23
    # --- legs
    for i, off in enumerate(leg):
        lx = 4 + i * 6
        _limb(img, lx + off, base_y - 6, 3, 6, pal["body_drk"], pal["out"])
        img.rect(lx + off - 1, base_y - 1, 5, 1, P["out"])
    # --- cape behind
    if cape != 0:
        img.rect(6 + cape, 7, 5, 12, pal["cloth_drk"])
    # --- torso
    ty = 8 - bob
    tx = 4
    torso = body_box(pal, tx, ty, 8, 9, lit=True)
    img.paste(torso, tx, ty)
    # belt
    img.rect(tx, ty + 7, 8, 1, P["wood_drk"])
    img.rect(tx + 3, ty + 7, 2, 1, P["gold"])
    # chest emblem
    img.set(8, ty + 3, P["cyan"])
    img.set(7, ty + 4, P["cyan"])
    img.set(9, ty + 4, P["cyan"])
    # --- arms
    _limb(img, 2 + arm, ty + 1, 3, 7, pal["body"], pal["out"])
    _limb(img, 11 - arm, ty + 1, 3, 7, pal["body"], pal["out"])
    # --- head
    img.paste(_knight_head(pal), 4 + tilt, ty - 7)
    if tint:
        img = _tint(img, tint)
    img.outline(P["out"], diagonals=False)
    return img


def _knight_head(pal):
    img = Img(8, 8)
    img.rect(1, 1, 6, 6, pal["body"])
    img.rect(1, 1, 6, 1, pal["body_lit"])
    img.rect(0, 2, 8, 3, pal["body"])
    img.rect(0, 2, 8, 1, pal["body_lit"])
    # visor
    img.rect(2, 4, 4, 2, P["out"])
    img.set(3, 4, pal["eye"])
    img.set(4, 4, pal["eye"])
    # cheek/chin
    img.rect(2, 6, 4, 1, pal["body_drk"])
    # plume
    img.set(3, 0, pal["cloth"])
    img.set(4, 0, pal["cloth_lit"])
    img.set(5, 0, pal["cloth"])
    img.set(4, -1 if False else 0, pal["cloth_lit"])
    return img


def _limb(img, x, y, w, h, color, outline):
    img.rect(x, y, w, h, color)
    img.rect(x, y + h - 1, w, 1, shift(color, -45))


def _tint(img, color, amount=0.35):
    out = img.copy()
    for y in range(out.h):
        for x in range(out.w):
            c = out.px[y][x]
            if c[3] > 0:
                out.px[y][x] = mix(c, color, amount)
    return out


def _fade(img, a):
    out = img.copy()
    for y in range(out.h):
        for x in range(out.w):
            c = out.px[y][x]
            if c[3] > 0:
                out.px[y][x] = (c[0], c[1], c[2], min(c[3], a))
    return out


def _squash(img, t):
    """Squash vertically towards the ground (t=0 normal, 1 fully flat)."""
    out = Img(img.w, img.h)
    box = img.bbox()
    if not box:
        return img
    bottom = box[3]
    for y in range(img.h):
        for x in range(img.w):
            c = img.px[y][x]
            if c[3] == 0:
                continue
            ny = bottom - int((bottom - y) * (1 - 0.75 * t))
            out.set(x, ny, c)
    return out


# ---------------------------------------------------------------------- slime
def slime_frames(big=False):
    w, h = (28, 22) if big else (16, 14)
    pal = {"body": P["slime"], "lit": P["slime_lit"], "drk": P["slime_drk"]}
    anims = {}
    idle = []
    for i, s in enumerate((0.0, 0.12, 0.0, -0.1)):
        img = _slime(pal, w, h, squash=s)
        idle.append(img)
    anims["idle"] = idle
    anims["run"] = [_slime(pal, w, h, squash=s, hop=hop) for s, hop in
                    ((0.2, 0), (-0.15, 1), (0.1, 0), (-0.2, 1), (0.2, 0), (-0.05, 0))]
    anims["attack"] = [_slime(pal, w, h, squash=0.3), _slime(pal, w, h, squash=-0.2)]
    anims["death"] = [_squash(_fade(_slime(pal, w, h, squash=0.3 * i), 255 - i * 50), i * 0.2)
                      for i in range(1, 6)] + [Img(w, h)]
    return anims


def _slime(pal, w, h, squash=0.0, hop=0):
    img = blob(w, h, pal["body"], squash=squash)
    hh = img.h
    for y in range(img.h):
        for x in range(img.w):
            c = img.px[y][x]
            if c[3] == 0:
                continue
            t = y / max(1, hh - 1)
            if t < 0.28:
                img.px[y][x] = pal["lit"]
            elif t > 0.72:
                img.px[y][x] = pal["drk"]
    # shading dither
    for y in range(img.h):
        for x in range(img.w):
            if img.px[y][x][3] > 0 and (x + y) % 2 == 0 and x > w * 0.55 and y > h * 0.45:
                img.px[y][x] = pal["drk"]
    # highlight blob
    img.ellipse(w * 0.32, h * 0.3, w * 0.12, h * 0.14, P["white"])
    # eyes
    ex = int(w * 0.36)
    ey = int(h * 0.42) - hop
    img.rect(ex, ey, 2, 3, P["black"])
    img.rect(ex + 4, ey, 2, 3, P["black"])
    img.set(ex + 1, ey, P["white"])
    img.set(ex + 5, ey, P["white"])
    # mouth
    img.rect(ex + 1, ey + 4, 4, 1, P["black"])
    img.outline(P["out"], diagonals=False)
    return img


# ------------------------------------------------------------------------ bat
def bat_frames():
    anims = {}
    frames = []
    for wing in (0, 1, 2, 1):
        frames.append(_bat(wing, bob=0))
    anims["idle"] = frames
    anims["run"] = [_bat(w, bob=b) for w, b in ((0, 0), (1, -1), (2, 0), (1, 1))]
    anims["attack"] = [_bat(0, bob=1, mouth=True), _bat(1, bob=-1, mouth=True)]
    anims["death"] = [_fade(_squash(_bat(i % 3, bob=1), i * 0.15), 255 - i * 50) for i in range(5)] + [Img(16, 12)]
    return anims


def _bat(wing, bob=0, mouth=False):
    img = Img(16, 12)
    body = P["bat"]
    lit = P["bat_lit"]
    drk = P["bat_drk"]
    # wings
    wy = 3 + bob
    for side in (-1, 1):
        for i in range(3):
            x = 7 + side * (2 + i * 2)
            yy = wy + (wing - 1) * i
            img.rect(min(x, x + side), yy, 2, 3, body if i < 2 else drk)
            img.rect(min(x, x + side), yy, 2, 1, lit)
    # body
    img.ellipse(7.5, 5 + bob, 2.5, 3.5, body)
    img.ellipse(7.5, 4 + bob, 2.0, 1.5, lit)
    # ears
    img.set(6, 1 + bob, body)
    img.set(9, 1 + bob, body)
    # eyes
    img.set(6, 5 + bob, P["red_lit"])
    img.set(9, 5 + bob, P["red_lit"])
    if mouth:
        img.set(7, 7 + bob, P["white"])
        img.set(8, 7 + bob, P["white"])
    img.outline(P["out"], diagonals=False)
    return img


# ------------------------------------------------------------------- skeleton
def skeleton_frames():
    pal = {"body": P["bone"], "body_lit": P["white"], "body_drk": P["bone_drk"], "eye": P["red_lit"]}
    anims = {}
    anims["idle"] = [_skeleton(pal, bob=b, arm=a, leg=(0, 0)) for b, a in ((0, 0), (1, 0), (1, 1), (0, 0))]
    anims["run"] = [_skeleton(pal, bob=b, arm=a, leg=(l1, l2))
                    for b, a, l1, l2 in ((1, -1, 2, -2), (0, 0, 0, 0), (1, 1, -2, 2), (0, 0, 0, 0))]
    anims["attack"] = [_skeleton(pal, bob=0, arm=2, leg=(1, -1), throw=True),
                       _skeleton(pal, bob=1, arm=-1, leg=(1, -1))]
    anims["death"] = [_fade(_squash(_skeleton(pal, bob=i % 2, arm=2, leg=(1, 1)), i * 0.2), 255 - i * 50)
                      for i in range(5)] + [Img(16, 24)]
    return anims


def _skeleton(pal, bob=0, arm=0, leg=(0, 0), throw=False):
    img = Img(16, 24)
    base = 23
    for i, off in enumerate(leg):
        lx = 5 + i * 5
        img.rect(lx + off, base - 8, 2, 8, pal["body"])
        img.rect(lx + off - 1, base - 1, 4, 1, pal["body_drk"])
    ty = 8 - bob
    img.rect(5, ty, 6, 9, pal["body"])
    for i in range(3):
        img.rect(6, ty + 2 + i * 3, 4, 1, pal["body_drk"])
    img.rect(5, ty, 6, 1, pal["body_lit"])
    # arms
    img.rect(3 + arm, ty + 1, 2, 7, pal["body"])
    img.rect(11 + arm, ty + 1, 2, 7, pal["body"])
    # skull
    img.rect(4, ty - 7, 8, 7, pal["body"])
    img.rect(4, ty - 7, 8, 1, pal["body_lit"])
    img.rect(5, ty - 3, 2, 2, P["out"])
    img.rect(9, ty - 3, 2, 2, P["out"])
    img.set(5, ty - 3, pal["eye"])
    img.set(9, ty - 3, pal["eye"])
    img.rect(6, ty - 1, 4, 1, P["out"])
    img.rect(6, ty, 1, 1, P["out"])
    img.rect(9, ty, 1, 1, P["out"])
    if throw:
        img.rect(13, ty - 2, 2, 2, pal["body_lit"])
    img.outline(P["out"], diagonals=False)
    return img


# ------------------------------------------------------------------------ orc
def orc_frames():
    pal = {"body": P["orc"], "body_lit": P["orc_lit"], "body_drk": P["orc_drk"], "eye": P["red_lit"],
           "cloth": P["wood_drk"], "metal": P["steel"], "metal_lit": P["steel_lit"], "metal_drk": P["steel_drk"]}
    anims = {}
    anims["idle"] = [_orc(pal, bob=b, arm=a, leg=(0, 0)) for b, a in ((0, 0), (1, 0), (1, 0), (0, 0))]
    anims["run"] = [_orc(pal, bob=b, arm=a, leg=(l1, l2))
                    for b, a, l1, l2 in ((1, -1, 2, -2), (0, 0, 1, -1), (1, 1, -2, 2), (0, 0, 1, -1))]
    anims["attack"] = [_orc(pal, bob=-1, arm=2, leg=(1, -1)), _orc(pal, bob=1, arm=-2, leg=(1, -1))]
    anims["charge"] = [_orc(pal, bob=1, arm=-1, leg=(2, -2), tint=P["red"])]
    anims["death"] = [_fade(_squash(_orc(pal, bob=i % 2, arm=2, leg=(1, 1)), i * 0.2), 255 - i * 50)
                      for i in range(5)] + [Img(18, 24)]
    return anims


def _orc(pal, bob=0, arm=0, leg=(0, 0), tint=None):
    img = Img(18, 24)
    base = 23
    for i, off in enumerate(leg):
        lx = 4 + i * 7
        img.rect(lx + off, base - 6, 3, 6, pal["body_drk"])
        img.rect(lx + off - 1, base - 1, 5, 1, P["out"])
    ty = 8 - bob
    img.rect(4, ty, 10, 10, pal["body"])
    img.rect(4, ty, 10, 1, pal["body_lit"])
    img.rect(4, ty + 9, 10, 1, pal["body_drk"])
    # belly patch
    img.ellipse(9, ty + 6, 3.5, 2.6, pal["body_lit"])
    # shoulder pads
    img.rect(2, ty, 3, 3, pal["metal"])
    img.rect(13, ty, 3, 3, pal["metal"])
    img.rect(2, ty, 3, 1, pal["metal_lit"])
    img.rect(13, ty, 3, 1, pal["metal_lit"])
    # arms
    img.rect(2 + arm, ty + 3, 3, 6, pal["body"])
    img.rect(13 - arm, ty + 3, 3, 6, pal["body"])
    # head
    img.rect(5, ty - 7, 8, 7, pal["body"])
    img.rect(5, ty - 7, 8, 1, pal["body_lit"])
    img.rect(4, ty - 5, 1, 2, pal["body_drk"])
    img.rect(13, ty - 5, 1, 2, pal["body_drk"])
    img.set(6, ty - 4, pal["eye"])
    img.set(11, ty - 4, pal["eye"])
    img.rect(7, ty - 2, 4, 1, P["out"])
    img.set(6, ty - 1, P["white"])
    img.set(11, ty - 1, P["white"])
    img.rect(5, ty - 8, 8, 1, P["wood_drk"])
    if tint:
        img = _tint(img, tint, 0.4)
    img.outline(P["out"], diagonals=False)
    return img


# ---------------------------------------------------------------------- ghost
def ghost_frames():
    anims = {}
    anims["idle"] = [_ghost(bob=b, tail=t) for b, t in ((0, 0), (-1, 1), (0, 2), (1, 1))]
    anims["run"] = [_ghost(bob=b, tail=t, tilt=d) for b, t, d in ((-1, 0, -1), (0, 1, 0), (1, 2, 1), (0, 1, 0))]
    anims["attack"] = [_ghost(bob=0, tail=0, mouth=True), _ghost(bob=-1, tail=1, mouth=True)]
    anims["death"] = [_fade(_ghost(bob=i % 2, tail=i % 3), 255 - i * 55) for i in range(4)] + [Img(16, 20)]
    return anims


def _ghost(bob=0, tail=0, mouth=False, tilt=0):
    img = Img(16, 20)
    body = P["ghost"]
    drk = P["ghost_drk"]
    # main body
    img.ellipse(7.5 + tilt, 7 + bob, 6, 6, body)
    img.rect(2 + tilt, 7 + bob, 12, 6, body)
    # wavy tail
    for i in range(6):
        x = 2 + i * 2
        h = 2 + ((i + tail) % 3)
        img.rect(x + tilt, 13 + bob, 2, h, body)
    # shading
    for y in range(img.h):
        for x in range(img.w):
            if img.px[y][x][3] > 0 and (x > 11 + tilt or (x + y) % 3 == 0 and x > 8 + tilt):
                img.px[y][x] = drk
    # eyes
    img.rect(5 + tilt, 5 + bob, 2, 3, P["black"])
    img.rect(9 + tilt, 5 + bob, 2, 3, P["black"])
    img.set(5 + tilt, 6 + bob, P["cyan"])
    img.set(9 + tilt, 6 + bob, P["cyan"])
    if mouth:
        img.rect(7 + tilt, 9 + bob, 3, 2, P["black"])
    img.outline(alpha(P["out"], 190), diagonals=False)
    return img


# --------------------------------------------------------------------- spider
def spider_frames():
    anims = {}
    anims["idle"] = [_spider(leg=(l, l)) for l in (0, 1)]
    anims["run"] = [_spider(leg=(a, b)) for a, b in ((1, -1), (0, 0), (-1, 1), (0, 0))]
    anims["attack"] = [_spider(leg=(2, -2), mouth=True), _spider(leg=(-2, 2), mouth=True)]
    anims["death"] = [_fade(_spider(leg=(i, -i)), 255 - i * 55) for i in range(4)] + [Img(20, 14)]
    return anims


def _spider(leg=(0, 0), mouth=False):
    img = Img(20, 14)
    body = P["spider"]
    drk = P["spider_drk"]
    # legs
    for side in (-1, 1):
        for i in range(4):
            x = 9 + side * (1) + side * i * 2
            y = 6 - i // 2 + (leg[0] if i % 2 == 0 else leg[1])
            img.line(x, y, x + side * (2 + i), y - 3 + i, drk)
            img.line(x, y + 1, x + side * (2 + i), y - 2 + i, drk)
    # abdomen
    img.ellipse(9, 7, 4.5, 4, body)
    img.ellipse(8, 6, 3, 2, shift(body, 30))
    # head
    img.ellipse(16, 8, 3.2, 2.8, body)
    img.rect(14, 8, 5, 1, drk)
    for i in range(3):
        img.set(15 + i * 2, 7, P["red_lit"])
    if mouth:
        img.rect(18, 9, 2, 1, P["white"])
    img.outline(P["out"], diagonals=False)
    return img


# ---------------------------------------------------------------------- golem
def golem_frames():
    pal = {"body": P["stone"], "body_lit": P["stone_lit"], "body_drk": P["stone_drk"]}
    anims = {}
    anims["idle"] = [_golem(pal, bob=b, arm=a, leg=(0, 0)) for b, a in ((0, 0), (1, 0), (1, 0), (0, 0))]
    anims["run"] = [_golem(pal, bob=b, arm=a, leg=(l1, l2))
                    for b, a, l1, l2 in ((1, -1, 2, -2), (0, 0, 0, 0), (1, 1, -2, 2), (0, 0, 0, 0))]
    anims["attack"] = [_golem(pal, bob=-2, arm=-3, leg=(1, -1)), _golem(pal, bob=2, arm=3, leg=(1, -1))]
    anims["slam"] = [_golem(pal, bob=2, arm=4, leg=(0, 0))]
    anims["death"] = [_fade(_squash(_golem(pal, bob=1, arm=3, leg=(1, 1)), i * 0.2), 255 - i * 55)
                      for i in range(5)] + [Img(24, 28)]
    return anims


def _golem(pal, bob=0, arm=0, leg=(0, 0)):
    img = Img(24, 28)
    base = 27
    for i, off in enumerate(leg):
        lx = 4 + i * 12
        img.rect(lx + off, base - 6, 5, 6, pal["body_drk"])
        img.rect(lx + off - 1, base - 1, 7, 1, P["out"])
    ty = 9 - bob
    img.rect(4, ty, 16, 12, pal["body"])
    img.rect(4, ty, 16, 2, pal["body_lit"])
    img.rect(4, ty + 10, 16, 2, pal["body_drk"])
    # cracks
    img.line(8, ty + 3, 11, ty + 6, pal["body_drk"])
    img.line(15, ty + 2, 13, ty + 8, pal["body_drk"])
    # moss
    img.rect(5, ty + 1, 3, 1, P["moss"])
    img.rect(15, ty + 1, 3, 1, P["moss"])
    img.rect(6, ty + 2, 1, 1, P["moss"])
    # arms
    img.rect(0 + arm, ty + 2, 4, 9, pal["body"])
    img.rect(20 - arm, ty + 2, 4, 9, pal["body"])
    img.rect(0 + arm, ty + 2, 4, 1, pal["body_lit"])
    img.rect(20 - arm, ty + 2, 4, 1, pal["body_lit"])
    # head
    img.rect(6, ty - 7, 12, 7, pal["body"])
    img.rect(6, ty - 7, 12, 1, pal["body_lit"])
    img.rect(8, ty - 4, 3, 2, P["out"])
    img.rect(13, ty - 4, 3, 2, P["out"])
    img.set(9, ty - 4, P["cyan"])
    img.set(14, ty - 4, P["cyan"])
    img.rect(9, ty - 1, 6, 1, pal["body_drk"])
    # rune on chest
    img.set(11, ty + 5, P["cyan"])
    img.set(12, ty + 5, P["cyan"])
    img.set(12, ty + 4, P["cyan"])
    img.set(12, ty + 6, P["cyan"])
    img.outline(P["out"], diagonals=False)
    return img


# ----------------------------------------------------------------------- mage
def mage_frames():
    pal = {"body": P["robe"], "body_lit": P["robe_lit"], "body_drk": P["robe_drk"],
           "eye": P["gold"], "skin": P["skin"]}
    anims = {}
    anims["idle"] = [_mage(pal, bob=b, cast=False) for b in (0, 1, 1, 0)]
    anims["run"] = [_mage(pal, bob=b, cast=False, leg=(l1, l2))
                    for b, l1, l2 in ((1, 1, -1), (0, 0, 0), (1, -1, 1), (0, 0, 0))]
    anims["attack"] = [_mage(pal, bob=-1, cast=True), _mage(pal, bob=1, cast=True, glow=True)]
    anims["death"] = [_fade(_squash(_mage(pal, bob=1, cast=False), i * 0.2), 255 - i * 55)
                      for i in range(5)] + [Img(16, 24)]
    return anims


def _mage(pal, bob=0, cast=False, leg=(0, 0), glow=False):
    img = Img(16, 24)
    base = 23
    for i, off in enumerate(leg):
        img.rect(5 + i * 5 + off, base - 4, 2, 4, P["black"])
        img.rect(4 + i * 5 + off, base - 1, 4, 1, P["black"])
    ty = 8 - bob
    # robe
    img.rect(3, ty + 2, 10, 12, pal["body"])
    img.rect(3, ty + 2, 10, 1, pal["body_lit"])
    img.rect(3, ty + 12, 10, 2, pal["body_drk"])
    img.set(4, ty + 13, pal["body_drk"])
    # runes on robe
    img.set(8, ty + 6, pal["eye"])
    img.set(7, ty + 8, pal["eye"])
    img.set(9, ty + 10, pal["eye"])
    # arms
    if cast:
        img.rect(1, ty + 2, 2, 5, pal["body"])
        img.rect(13, ty + 1, 2, 5, pal["body"])
    else:
        img.rect(2, ty + 3, 2, 6, pal["body_drk"])
        img.rect(12, ty + 3, 2, 6, pal["body_drk"])
    # head + hood
    img.rect(4, ty - 5, 8, 7, pal["body"])
    img.rect(4, ty - 5, 8, 1, pal["body_lit"])
    img.rect(5, ty - 3, 6, 4, P["black"])
    img.set(6, ty - 2, pal["eye"])
    img.set(9, ty - 2, pal["eye"])
    # beard
    img.rect(6, ty + 1, 4, 2, P["white"])
    # staff
    img.rect(14, ty - 6, 1, 16, P["wood"])
    if glow:
        img.ellipse(14.5, ty - 7.5, 2.5, 2.5, P["cyan"])
        img.ellipse(14.5, ty - 7.5, 1.2, 1.2, P["white"])
    else:
        img.ellipse(14.5, ty - 7.5, 1.6, 1.6, P["teal"])
    img.outline(P["out"], diagonals=False)
    return img


# --------------------------------------------------------------------- bomber
def bomber_frames():
    pal = {"body": P["red"], "body_lit": P["red_lit"], "body_drk": P["red_drk"]}
    anims = {}
    anims["idle"] = [_bomber(pal, bob=b, fuse=b % 2) for b in (0, 1, 1, 0)]
    anims["run"] = [_bomber(pal, bob=b, fuse=f, leg=(l1, l2))
                    for b, f, l1, l2 in ((1, 0, 2, -2), (0, 1, 0, 0), (1, 2, -2, 2), (0, 1, 0, 0))]
    anims["attack"] = [_bomber(pal, bob=0, fuse=2, arms_up=True)]
    anims["death"] = [_fade(_bomber(pal, bob=1, fuse=2), 255 - i * 60) for i in range(4)] + [Img(16, 22)]
    return anims


def _bomber(pal, bob=0, fuse=0, leg=(0, 0), arms_up=False):
    img = Img(16, 22)
    base = 21
    for i, off in enumerate(leg):
        img.rect(4 + i * 6 + off, base - 5, 3, 5, pal["body_drk"])
        img.rect(3 + i * 6 + off, base - 1, 5, 1, P["out"])
    ty = 7 - bob
    img.rect(4, ty, 8, 10, pal["body"])
    img.rect(4, ty, 8, 1, pal["body_lit"])
    img.rect(4, ty + 9, 8, 1, pal["body_drk"])
    # bomb in hands
    img.ellipse(8, ty + 8, 3.5, 3.2, P["black"])
    img.ellipse(7, ty + 7, 1.5, 1.2, shift(P["black"], 40))
    img.set(8, ty + 4, P["wood_drk"])
    img.set(9, ty + 3, P["wood_drk"])
    spark = [P["fire_drk"], P["fire"], P["fire_lit"]][fuse % 3]
    img.set(10, ty + 2, spark)
    # arms
    ay = ty - 2 if arms_up else ty + 2
    img.rect(2, ay, 2, 5, pal["body"])
    img.rect(12, ay, 2, 5, pal["body"])
    # head
    img.rect(4, ty - 6, 8, 6, pal["body"])
    img.rect(4, ty - 6, 8, 1, pal["body_lit"])
    img.rect(3, ty - 4, 1, 2, pal["body_drk"])
    img.rect(12, ty - 4, 1, 2, pal["body_drk"])
    # goggles
    img.rect(5, ty - 4, 6, 2, P["steel_drk"])
    img.set(6, ty - 4, P["fire_lit"])
    img.set(9, ty - 4, P["fire_lit"])
    # grin
    img.rect(6, ty - 1, 4, 1, P["out"])
    img.outline(P["out"], diagonals=False)
    return img


# ----------------------------------------------------------------------- imp
def imp_frames():
    pal = {"body": P["red"], "body_lit": P["red_lit"], "body_drk": P["red_drk"], "eye": P["gold"]}
    anims = {}
    anims["idle"] = [_imp(pal, bob=b, draw=0) for b in (0, 1, 1, 0)]
    anims["run"] = [_imp(pal, bob=b, draw=0, leg=(l1, l2), arm=a)
                    for b, l1, l2, a in ((1, 1, -1, -1), (0, 0, 0, 0), (1, -1, 1, 1), (0, 0, 0, 0))]
    anims["attack"] = [_imp(pal, bob=0, draw=1), _imp(pal, bob=-1, draw=2)]
    anims["death"] = [_fade(_squash(_imp(pal, bob=1, draw=0), i * 0.2), 255 - i * 55)
                      for i in range(5)] + [Img(16, 22)]
    return anims


def _imp(pal, bob=0, draw=0, leg=(0, 0), arm=0):
    img = Img(16, 22)
    base = 21
    for i, off in enumerate(leg):
        img.rect(5 + i * 4 + off, base - 5, 2, 5, pal["body_drk"])
        img.rect(4 + i * 4 + off, base - 1, 4, 1, P["out"])
    ty = 7 - bob
    img.rect(4, ty, 8, 9, pal["body"])
    img.rect(4, ty, 8, 1, pal["body_lit"])
    img.rect(4, ty + 8, 8, 1, pal["body_drk"])
    # wings (small)
    img.rect(2, ty + 1, 2, 4, pal["body_drk"])
    img.rect(12, ty + 1, 2, 4, pal["body_drk"])
    # arms
    img.rect(2 - arm, ty + 2, 2, 5, pal["body"])
    img.rect(12 + arm, ty + 2, 2, 5, pal["body"])
    # head
    img.rect(4, ty - 6, 8, 6, pal["body"])
    img.rect(4, ty - 6, 8, 1, pal["body_lit"])
    # horns
    img.set(3, ty - 7, P["bone"])
    img.set(2, ty - 8, P["bone"])
    img.set(12, ty - 7, P["bone"])
    img.set(13, ty - 8, P["bone"])
    img.set(5, ty - 4, pal["eye"])
    img.set(10, ty - 4, pal["eye"])
    img.rect(6, ty - 2, 4, 1, P["out"])
    # bow drawn in 3 states
    if draw > 0:
        bx = 13
        img.line(bx, ty - 1, bx, ty + 5, P["wood"])
        if draw == 1:
            img.line(bx - 1, ty - 1, bx - 1, ty + 5, P["web"])
            img.set(bx - 1, ty + 2, P["wood_drk"])
        else:
            img.line(bx - 2, ty - 1, bx - 2, ty + 5, P["web"])
    img.outline(P["out"], diagonals=False)
    return img


# ------------------------------------------------------------------ boss: king
def slime_king_frames():
    w, h = 40, 32
    pal = {"body": P["slime"], "lit": P["slime_lit"], "drk": P["slime_drk"]}
    anims = {}
    anims["idle"] = [_slime_king(pal, w, h, squash=s) for s in (0.0, 0.1, 0.0, -0.08)]
    anims["run"] = [_slime_king(pal, w, h, squash=s, hop=hp) for s, hp in
                    ((0.25, 0), (-0.15, 1), (0.1, 0), (-0.2, 1))]
    anims["attack"] = [_slime_king(pal, w, h, squash=0.35, mouth=True),
                       _slime_king(pal, w, h, squash=-0.25, mouth=True)]
    anims["death"] = [_fade(_squash(_slime_king(pal, w, h, squash=0.3 * i), i * 0.2), 255 - i * 45)
                      for i in range(6)] + [Img(w, h)]
    return anims


def _slime_king(pal, w, h, squash=0.0, hop=0, mouth=False):
    img = blob(w, h, pal["body"], squash=squash)
    for y in range(img.h):
        for x in range(img.w):
            if img.px[y][x][3] == 0:
                continue
            t = y / (h - 1)
            if t < 0.25:
                img.px[y][x] = pal["lit"]
            elif t > 0.7:
                img.px[y][x] = pal["drk"]
    for y in range(img.h):
        for x in range(img.w):
            if img.px[y][x][3] > 0 and (x + y) % 2 == 0 and x > w * 0.6 and y > h * 0.4:
                img.px[y][x] = pal["drk"]
    img.ellipse(w * 0.3, h * 0.28, w * 0.1, h * 0.12, P["white"])
    # face
    ex = int(w * 0.3)
    ey = int(h * 0.44) - hop
    img.rect(ex, ey, 3, 4, P["black"])
    img.rect(ex + 8, ey, 3, 4, P["black"])
    img.set(ex + 1, ey + 1, P["white"])
    img.set(ex + 9, ey + 1, P["white"])
    if mouth:
        img.rect(ex + 2, ey + 6, 7, 3, P["black"])
        img.rect(ex + 2, ey + 6, 7, 1, P["red_drk"])
    # crown
    crown = [(14, 5), (16, 3), (18, 2), (20, 1), (22, 2), (24, 3), (26, 5)]
    for i, (cx, ch) in enumerate(crown):
        img.rect(cx, 2 - hop, 2, ch + 2, P["gold"])
        img.set(cx, 2 - hop, P["gold_lit"])
    img.rect(14, 7 - hop, 14, 2, P["gold"])
    img.rect(14, 8 - hop, 14, 1, P["gold_drk"])
    img.set(19, 7 - hop, P["red"])
    img.set(23, 7 - hop, P["teal"])
    img.outline(P["out"], diagonals=False)
    return img


# ------------------------------------------------------ boss: necromancer
def necromancer_frames():
    pal = {"robe": C("#2b2340"), "robe_lit": C("#4a3d6e"), "robe_drk": C("#171226"),
           "glow": P["slime"], "bone": P["bone"]}
    anims = {}
    anims["idle"] = [_necro(pal, bob=b, pose=0) for b in (0, 1, 1, 0)]
    anims["run"] = [_necro(pal, bob=b, pose=1, leg=(l1, l2)) for b, l1, l2 in
                    ((1, 1, -1), (0, 0, 0), (1, -1, 1), (0, 0, 0))]
    anims["attack"] = [_necro(pal, bob=-1, pose=2), _necro(pal, bob=0, pose=3)]
    anims["summon"] = [_necro(pal, bob=0, pose=4), _necro(pal, bob=-1, pose=4)]
    anims["death"] = [_fade(_squash(_necro(pal, bob=1, pose=0), i * 0.18), 255 - i * 42)
                      for i in range(6)] + [Img(24, 34)]
    return anims


def _necro(pal, bob=0, pose=0, leg=(0, 0)):
    img = Img(24, 34)
    base = 33
    # robe skirt
    img.rect(4, base - 10, 16, 10, pal["robe"])
    img.rect(4, base - 1, 16, 1, pal["robe_drk"])
    for i in range(3):
        img.rect(6 + i * 5, base - 3, 2, 3, pal["robe_drk"])
    ty = 12 - bob
    img.rect(5, ty, 14, 13, pal["robe"])
    img.rect(5, ty, 14, 1, pal["robe_lit"])
    img.rect(5, ty, 1, 13, pal["robe_lit"])
    img.rect(18, ty, 1, 13, pal["robe_drk"])
    # belt of skulls
    for i in range(3):
        img.rect(7 + i * 4, ty + 9, 3, 3, pal["bone"])
        img.set(8 + i * 4, ty + 10, P["black"])
    # arms
    if pose in (2, 3, 4):
        img.rect(1, ty - 1, 4, 4, pal["robe"])
        img.rect(19, ty - 1, 4, 4, pal["robe"])
        img.rect(0, ty + 2, 4, 3, pal["robe_lit"])
        img.rect(20, ty + 2, 4, 3, pal["robe_lit"])
    else:
        img.rect(2, ty + 1, 3, 9, pal["robe"])
        img.rect(19, ty + 1, 3, 9, pal["robe"])
    # head
    img.rect(7, ty - 8, 10, 8, pal["robe"])
    img.rect(7, ty - 8, 10, 1, pal["robe_lit"])
    img.rect(8, ty - 5, 8, 4, P["black"])
    if pose == 4:
        glow = P["slime_lit"]
    else:
        glow = pal["glow"]
    img.rect(9, ty - 4, 2, 2, glow)
    img.rect(14, ty - 4, 2, 2, glow)
    # staff with skull
    img.rect(21, ty - 12, 2, 30, P["wood_drk"])
    img.rect(20, ty - 16, 4, 4, pal["bone"])
    img.set(21, ty - 15, P["black"])
    img.set(22, ty - 15, P["black"])
    if pose in (2, 3):
        img.ellipse(22, ty - 18, 3, 3, alpha(P["slime"], 160))
        img.ellipse(22, ty - 18, 1.5, 1.5, P["slime_lit"])
    if pose == 4:
        img.ellipse(22, ty - 18, 5, 5, alpha(P["slime"], 120))
    img.outline(P["out"], diagonals=False)
    return img


# --------------------------------------------------------- boss: demon lord
def demon_lord_frames():
    pal = {"body": C("#a02730"), "body_lit": C("#e05a4a"), "body_drk": C("#5e1420"),
           "horn": C("#f0e6d2"), "eye": P["fire_lit"], "armor": C("#3a2b46"), "armor_lit": C("#6b5480")}
    anims = {}
    anims["idle"] = [_demon(pal, bob=b, wing=w, pose=0) for b, w in ((0, 0), (1, 1), (1, 2), (0, 1))]
    anims["run"] = [_demon(pal, bob=b, wing=w, pose=1, leg=(l1, l2))
                    for b, w, l1, l2 in ((1, 0, 2, -2), (0, 1, 0, 0), (1, 2, -2, 2), (0, 1, 0, 0))]
    anims["attack"] = [_demon(pal, bob=-1, wing=0, pose=2, glow=True),
                       _demon(pal, bob=1, wing=0, pose=3, glow=True)]
    anims["slam"] = [_demon(pal, bob=2, wing=1, pose=4)]
    anims["death"] = [_fade(_squash(_demon(pal, bob=1, wing=i % 3, pose=0), i * 0.15), 255 - i * 40)
                      for i in range(6)] + [Img(40, 40)]
    return anims


def _demon(pal, bob=0, wing=0, pose=0, leg=(0, 0), glow=False):
    img = Img(40, 40)
    base = 39
    # wings
    for side in (-1, 1):
        ox = 20 + side * 8
        for i in range(4):
            x = ox + side * i * 3
            y = 12 + i * 3 + wing + bob
            img.rect(min(x, x + side * 2), y, 3, 8 - i, pal["body_drk"])
            img.rect(min(x, x + side * 2), y, 3, 2, pal["body"])
    # legs
    for i, off in enumerate(leg):
        lx = 12 + i * 10 + off
        img.rect(lx, base - 8, 5, 8, pal["body_drk"])
        img.rect(lx - 1, base - 2, 7, 2, pal["armor"])
        img.set(lx - 1, base - 2, pal["armor_lit"])
    ty = 14 - bob
    # torso
    img.rect(12, ty, 16, 16, pal["body"])
    img.rect(12, ty, 16, 2, pal["body_lit"])
    img.rect(12, ty + 14, 16, 2, pal["body_drk"])
    # chest armor
    img.rect(13, ty + 4, 14, 8, pal["armor"])
    img.rect(13, ty + 4, 14, 1, pal["armor_lit"])
    img.set(20, ty + 7, pal["eye"])
    img.set(19, ty + 8, pal["eye"])
    img.set(21, ty + 8, pal["eye"])
    img.set(20, ty + 9, pal["eye"])
    # arms
    arm_y = ty - 3 if pose in (2, 3, 4) else ty + 2
    img.rect(7, arm_y, 5, 10, pal["body"])
    img.rect(28, arm_y, 5, 10, pal["body"])
    img.rect(6, arm_y + 9, 7, 4, pal["body_drk"])
    img.rect(27, arm_y + 9, 7, 4, pal["body_drk"])
    if pose == 3:  # claws forward
        img.rect(2, arm_y + 4, 6, 3, pal["body_lit"])
        img.rect(32, arm_y + 4, 6, 3, pal["body_lit"])
        for i in range(3):
            img.set(2 - 1, arm_y + 3 + i, pal["horn"])
            img.set(37 + 1, arm_y + 3 + i, pal["horn"])
    # head
    img.rect(15, ty - 9, 10, 9, pal["body"])
    img.rect(15, ty - 9, 10, 1, pal["body_lit"])
    # horns
    img.line(15, ty - 9, 11, ty - 14, pal["horn"])
    img.line(11, ty - 14, 10, ty - 16, pal["horn"])
    img.line(24, ty - 9, 28, ty - 14, pal["horn"])
    img.line(28, ty - 14, 29, ty - 16, pal["horn"])
    # eyes
    img.rect(16, ty - 6, 3, 2, pal["eye"])
    img.rect(21, ty - 6, 3, 2, pal["eye"])
    img.rect(17, ty - 1, 6, 1, P["black"])
    img.set(17, ty - 2, pal["horn"])
    img.set(22, ty - 2, pal["horn"])
    if glow:
        img.ellipse(37, arm_y + 5, 4, 4, alpha(P["fire"], 150))
        img.ellipse(37, arm_y + 5, 2, 2, P["fire_lit"])
    img.outline(P["out"], diagonals=False)
    return img


def build():
    """Export every character sheet."""
    for name, data in player_frames().items():
        sheet(data, "Characters/player_%s.png" % name)
    for name, data in slime_frames().items():
        sheet(data, "Enemies/slime_%s.png" % name)
    for name, data in bat_frames().items():
        sheet(data, "Enemies/bat_%s.png" % name)
    for name, data in skeleton_frames().items():
        sheet(data, "Enemies/skeleton_%s.png" % name)
    for name, data in orc_frames().items():
        sheet(data, "Enemies/orc_%s.png" % name)
    for name, data in ghost_frames().items():
        sheet(data, "Enemies/ghost_%s.png" % name)
    for name, data in spider_frames().items():
        sheet(data, "Enemies/spider_%s.png" % name)
    for name, data in golem_frames().items():
        sheet(data, "Enemies/golem_%s.png" % name)
    for name, data in mage_frames().items():
        sheet(data, "Enemies/mage_%s.png" % name)
    for name, data in bomber_frames().items():
        sheet(data, "Enemies/bomber_%s.png" % name)
    for name, data in imp_frames().items():
        sheet(data, "Enemies/imp_%s.png" % name)
    for name, data in slime_king_frames().items():
        sheet(data, "Bosses/slime_king_%s.png" % name)
    for name, data in necromancer_frames().items():
        sheet(data, "Bosses/necromancer_%s.png" % name)
    for name, data in demon_lord_frames().items():
        sheet(data, "Bosses/demon_lord_%s.png" % name)
