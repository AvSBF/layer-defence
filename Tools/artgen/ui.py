"""UI sprites + a generated 5x7 bitmap font (BMFont .fnt + atlas)."""
from __future__ import annotations

import os

from px import C, Img, OUT, alpha, mix, sheet, single, shift
from chars import P

PANEL = C("#241d33")
PANEL_LIT = C("#3a3050")
PANEL_DRK = C("#151022")
BORDER = C("#6b5480")
BORDER_LIT = C("#a189c9")
SHOP_BG = C("#1b1528")

# ------------------------------------------------------------------ 5x7 font
G = {
    " ": "...../...../...../...../...../...../.....",
    "A": ".###./#...#/#...#/#####/#...#/#...#/#...#",
    "B": "####./#...#/#...#/####./#...#/#...#/####.",
    "C": ".###./#...#/#..../#..../#..../#...#/.###.",
    "D": "####./#...#/#...#/#...#/#...#/#...#/####.",
    "E": "#####/#..../#..../####./#..../#..../#####",
    "F": "#####/#..../#..../####./#..../#..../#....",
    "G": ".###./#...#/#..../#.###/#...#/#...#/.###.",
    "H": "#...#/#...#/#...#/#####/#...#/#...#/#...#",
    "I": ".###./..#../..#../..#../..#../..#../.###.",
    "J": "..###/...#./...#./...#./...#./#..#./.##..",
    "K": "#...#/#..#./#.#../##.../#.#../#..#./#...#",
    "L": "#..../#..../#..../#..../#..../#..../#####",
    "M": "#...#/##.##/#.#.#/#...#/#...#/#...#/#...#",
    "N": "#...#/##..#/#.#.#/#..##/#...#/#...#/#...#",
    "O": ".###./#...#/#...#/#...#/#...#/#...#/.###.",
    "P": "####./#...#/#...#/####./#..../#..../#....",
    "Q": ".###./#...#/#...#/#...#/#.#.#/#..#./.##.#",
    "R": "####./#...#/#...#/####./#.#../#..#./#...#",
    "S": ".####/#..../#..../.###./....#/....#/####.",
    "T": "#####/..#../..#../..#../..#../..#../..#..",
    "U": "#...#/#...#/#...#/#...#/#...#/#...#/.###.",
    "V": "#...#/#...#/#...#/#...#/#...#/.#.#./..#..",
    "W": "#...#/#...#/#...#/#.#.#/#.#.#/##.##/#...#",
    "X": "#...#/#...#/.#.#./..#../.#.#./#...#/#...#",
    "Y": "#...#/#...#/.#.#./..#../..#../..#../..#..",
    "Z": "#####/....#/...#./..#../.#.../#..../#####",
    "0": ".###./#...#/#..##/#.#.#/##..#/#...#/.###.",
    "1": "..#../.##../..#../..#../..#../..#../.###.",
    "2": ".###./#...#/....#/...#./..#../.#.../#####",
    "3": "####./....#/....#/.###./....#/....#/####.",
    "4": "...#./..##./.#.#./#..#./#####/...#./...#.",
    "5": "#####/#..../####./....#/....#/#...#/.###.",
    "6": ".###./#..../#..../####./#...#/#...#/.###.",
    "7": "#####/....#/...#./..#../.#.../.#.../.#...",
    "8": ".###./#...#/#...#/.###./#...#/#...#/.###.",
    "9": ".###./#...#/#...#/.####/....#/....#/.###.",
    ".": "...../...../...../...../...../.##../.##..",
    ",": "...../...../...../...../.##../.##../.#...",
    ":": "...../..#../..#../...../..#../..#../.....",
    ";": "...../..#../..#../...../..#../..#../.#...",
    "!": "..#../..#../..#../..#../..#../...../..#..",
    "?": ".###./#...#/....#/...#./..#../...../..#..",
    "'": "..#../..#../...../...../...../...../.....",
    '"': ".#.#./.#.#./...../...../...../...../.....",
    "(": "...#./..#../.#.../.#.../.#.../..#../...#.",
    ")": ".#.../..#../...#./...#./...#./..#../.#...",
    "[": "..##./..#../..#../..#../..#../..#../..##.",
    "]": ".##../..#../..#../..#../..#../..#../.##..",
    "<": "...#./..#../.#.../#..../.#.../..#../...#.",
    ">": ".#.../..#../...#./....#/...#./..#../.#...",
    "+": "...../..#../..#../#####/..#../..#../.....",
    "-": "...../...../...../#####/...../...../.....",
    "=": "...../...../#####/...../#####/...../.....",
    "/": "....#/...#./...#./..#../.#.../.#.../#....",
    "\\": "#..../.#.../.#.../..#../...#./...#./....#",
    "*": "...../#.#.#/.###./#####/.###./#.#.#/.....",
    "%": "##..#/##..#/...#./..#../.#.../#..##/#..##",
    "#": ".#.#./.#.#./#####/.#.#./#####/.#.#./.#.#.",
    "@": ".###./#...#/#.###/#.#.#/#.###/#..../.###.",
    "&": ".##../#..#./#.#../.#.../#.#.#/#..#./.##.#",
    "_": "...../...../...../...../...../...../#####",
    "|": "..#../..#../..#../..#../..#../..#../..#..",
    "~": "...../.#..#/#.#.#/#..#./...../...../.....",
    "^": "..#../.#.#./#...#/...../...../...../.....",
    "$": "..#../.####/#.#../.###./..#.#/####./..#..",
    "=": "...../...../#####/...../#####/...../.....",
    "«": "...../.#..#/#..#./#..../.#..#/..#.#/.....",
    "»": "...../#..#./.#..#/....#/#..#./.#.#./.....",
}

GLYPH_W, GLYPH_H = 5, 7
PAD = 1


def _glyph_rows(ch):
    raw = G.get(ch)
    if raw is None:
        raw = G["?"]
    return raw.split("/")


def _draw_glyph(canvas, ch, gx, gy, scale):
    for ry, row in enumerate(_glyph_rows(ch)):
        for rx, c in enumerate(row):
            if c == "#":
                for sy in range(scale):
                    for sx in range(scale):
                        canvas.set(gx + rx * scale + sx, gy + ry * scale + sy, (255, 255, 255, 255))


def build_font(scale=2):
    """Export a BMFont pair: atlas png + descriptor .fnt"""
    chars = sorted(G.keys())
    cell = (GLYPH_W + PAD) * scale
    cell_h = (GLYPH_H + PAD) * scale
    cols = 16
    rows = (len(chars) + cols - 1) // cols
    atlas = Img(cols * cell, rows * cell_h)
    lines = []
    for i, ch in enumerate(chars):
        cx = (i % cols) * cell
        cy = (i // cols) * cell_h
        _draw_glyph(atlas, ch, cx, cy, scale)
        lines.append("char id=%d x=%d y=%d width=%d height=%d xoffset=0 yoffset=0 xadvance=%d page=0 chnl=15"
                     % (ord(ch), cx, cy, GLYPH_W * scale, GLYPH_H * scale, (GLYPH_W + 1) * scale))
    name = "UI/font/pixel_font"
    atlas.save(name + ".png")
    path = os.path.join(OUT, name + ".fnt")
    os.makedirs(os.path.dirname(path), exist_ok=True)
    info = ('info face="PixelDefence" size=%d bold=0 italic=0 charset="" unicode=1 stretchH=100 '
            'smooth=0 aa=0 padding=0,0,0,0 spacing=0,0' % (GLYPH_H * scale))
    common = "common lineHeight=%d base=%d scaleW=%d scaleH=%d pages=1 packed=0" % (
        (GLYPH_H + PAD + 2) * scale, GLYPH_H * scale, atlas.w, atlas.h)
    with open(path, "w", encoding="utf-8") as f:
        f.write(info + "\n")
        f.write(common + "\n")
        f.write('page id=0 file="pixel_font.png"\n')
        f.write("chars count=%d\n" % len(chars))
        f.write("\n".join(lines) + "\n")
        f.write("kernings count=0\n")
    return atlas


# ------------------------------------------------------------------- widgets
def panel_ninepatch():
    img = Img(24, 24)
    img.rect(0, 0, 24, 24, PANEL)
    img.border(0, 0, 24, 24, BORDER, 1)
    img.border(1, 1, 22, 22, PANEL_LIT, 1)
    # corner rivets
    for (x, y) in ((2, 2), (21, 2), (2, 21), (21, 21)):
        img.set(x, y, BORDER_LIT)
    return img


def card_ninepatch():
    img = Img(24, 24)
    img.rect(0, 0, 24, 24, SHOP_BG)
    img.border(0, 0, 24, 24, C("#3d3358"), 1)
    img.rect(1, 1, 22, 1, C("#4d4170"))
    return img


def button_frames():
    frames = []
    for state in range(3):
        img = Img(32, 16)
        top = [PANEL_LIT, C("#5b4d7d"), C("#2b2440")][state]
        bot = [PANEL_DRK, C("#3a3050"), C("#151022")][state]
        img.rect(0, 0, 32, 16, mix(top, bot, 0.4))
        for y in range(16):
            t = y / 15.0
            c = mix(top, bot, t)
            for x in range(32):
                img.set(x, y, c)
        img.border(0, 0, 32, 16, BORDER, 1)
        img.rect(1, 1, 30, 1, BORDER_LIT if state == 0 else BORDER)
        img.rect(1, 14, 30, 1, PANEL_DRK)
        if state == 1:
            img.border(0, 0, 32, 16, P["gold"], 1)
        frames.append(img)
    return frames


def heart_ui_frames():
    frames = []
    for filled in (1.0, 0.5, 0.0):
        img = Img(11, 10)
        c = P["red"] if filled > 0 else C("#3a2b33")
        lit = P["red_lit"] if filled > 0 else C("#4a3844")
        drk = P["red_drk"] if filled > 0 else C("#2a1f26")
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
        img.rect(1, 5, 8, 1, drk)
        if filled == 0.5:
            for y in range(10):
                for x in range(6, 11):
                    cc = img.px[y][x]
                    if cc[3] > 0:
                        img.px[y][x] = mix(cc, C("#3a2b33"), 0.75)
        img.outline(C("#120e1c"), diagonals=False)
        frames.append(img)
    return frames


def icon_set():
    """16x16 shop/HUD icons. Returns dict name -> Img."""
    icons = {}

    def base():
        return Img(16, 16)

    # sword / damage
    i = base()
    i.rect(7, 2, 2, 9, P["steel_lit"])
    i.rect(7, 2, 1, 9, P["white"])
    i.rect(5, 11, 6, 2, P["gold"])
    i.rect(7, 13, 2, 2, P["wood_drk"])
    icons["damage"] = i

    # speed boots
    i = base()
    i.rect(3, 3, 4, 7, P["teal"])
    i.rect(3, 10, 8, 3, P["teal_drk"])
    i.rect(3, 3, 4, 1, P["teal_lit"])
    i.rect(10, 5, 2, 2, P["cyan"])
    i.rect(12, 2, 2, 2, alpha(P["cyan"], 170))
    icons["speed"] = i

    # heart / hp
    i = base()
    i.rect(2, 4, 5, 4, P["red"])
    i.rect(9, 4, 5, 4, P["red"])
    i.rect(2, 3, 3, 2, P["red"])
    i.rect(11, 3, 3, 2, P["red"])
    i.rect(2, 7, 12, 3, P["red"])
    i.rect(4, 10, 8, 2, P["red"])
    i.rect(6, 12, 4, 2, P["red"])
    i.rect(4, 4, 3, 2, P["red_lit"])
    icons["health"] = i

    # attack speed - clock
    i = base()
    i.circle(8, 8, 6, P["gold"])
    i.circle(8, 8, 4, PANEL_DRK)
    i.rect(7, 4, 2, 5, P["gold_lit"])
    i.rect(8, 8, 5, 2, P["gold_lit"])
    icons["attack_speed"] = i

    # magnet
    i = base()
    i.rect(2, 3, 4, 7, P["red"])
    i.rect(10, 3, 4, 7, P["red"])
    i.rect(2, 3, 4, 2, P["red_lit"])
    i.rect(10, 3, 4, 2, P["red_lit"])
    i.rect(6, 9, 4, 3, P["steel"])
    i.rect(2, 10, 4, 3, P["steel_lit"])
    i.rect(10, 10, 4, 3, P["steel_lit"])
    icons["magnet"] = i

    # crit
    i = base()
    i.circle(8, 8, 5, P["gold"])
    i.circle(8, 8, 3.4, PANEL_DRK)
    i.rect(7, 3, 2, 10, P["gold_drk"])
    i.rect(3, 7, 10, 2, P["gold_drk"])
    i.circle(8, 8, 2, P["red_lit"])
    icons["crit"] = i

    # lifesteal fang
    i = base()
    i.rect(3, 3, 2, 5, P["white"])
    i.rect(7, 3, 2, 5, P["white"])
    i.rect(11, 3, 2, 5, P["white"])
    i.rect(3, 8, 2, 3, P["bone_drk"])
    i.rect(11, 8, 2, 3, P["bone_drk"])
    i.rect(7, 8, 2, 4, P["bone_drk"])
    icons["lifesteal"] = i

    # dash
    i = base()
    i.rect(2, 6, 8, 3, P["cyan"])
    i.rect(4, 9, 6, 3, alpha(P["cyan"], 180))
    i.rect(6, 12, 4, 2, alpha(P["cyan"], 120))
    i.rect(10, 4, 4, 4, P["white"])
    icons["dash"] = i

    # armor
    i = base()
    i.rect(4, 2, 8, 3, P["steel"])
    i.rect(3, 5, 10, 5, P["steel"])
    i.rect(5, 10, 6, 3, P["steel_drk"])
    i.rect(3, 5, 10, 1, P["steel_lit"])
    i.rect(7, 6, 2, 5, P["white"])
    icons["armor"] = i

    # luck clover
    i = base()
    for (cx, cy) in ((6, 5), (10, 5), (6, 9), (10, 9)):
        i.circle(cx, cy, 2.4, P["slime"])
    i.circle(6, 5, 1.2, P["slime_lit"])
    i.rect(7, 10, 2, 4, P["slime_drk"])
    icons["luck"] = i

    # reroll dice
    i = base()
    i.rect(2, 2, 12, 12, P["white"])
    i.border(2, 2, 12, 12, PANEL_DRK, 1)
    for (dx, dy) in ((5, 5), (10, 5), (7, 7), (5, 10), (10, 10)):
        i.rect(dx, dy, 2, 2, PANEL_DRK)
    icons["reroll"] = i

    # potion
    i = base()
    i.rect(6, 2, 4, 2, P["bone_drk"])
    i.rect(5, 4, 6, 2, alpha(P["white"], 180))
    i.rect(4, 6, 8, 8, P["red"])
    i.rect(4, 6, 8, 2, P["red_lit"])
    i.rect(6, 9, 2, 3, alpha(P["white"], 120))
    icons["potion"] = i

    # weapon crate
    i = base()
    i.rect(2, 5, 12, 9, P["wood"])
    i.rect(2, 5, 12, 2, P["wood_drk"])
    i.rect(7, 5, 2, 9, P["gold_drk"])
    i.rect(4, 9, 2, 2, P["gold"])
    icons["weapon"] = i

    # coin
    icons["coin"] = coin_icon()

    # pot
    i = base()
    i.rect(5, 3, 6, 2, C("#7a3722"))
    i.rect(3, 5, 10, 6, C("#b5613f"))
    i.rect(4, 11, 8, 3, C("#7a3722"))
    i.rect(4, 6, 8, 1, C("#e0895c"))
    i.rect(5, 8, 6, 1, P["gold_drk"])
    icons["pot"] = i

    # skull (danger)
    i = base()
    i.circle(8, 7, 5, P["bone"])
    i.rect(4, 10, 8, 3, P["bone"])
    i.rect(5, 5, 3, 3, C("#1a1424"))
    i.rect(8, 5, 3, 3, C("#1a1424"))
    i.rect(7, 10, 2, 2, C("#1a1424"))
    icons["skull"] = i

    # star (rarity)
    i = base()
    pts = [(8, 1), (10, 6), (15, 6), (11, 9), (13, 14), (8, 11), (3, 14), (5, 9), (1, 6), (6, 6)]
    for k in range(len(pts)):
        x0, y0 = pts[k]
        x1, y1 = pts[(k + 1) % len(pts)]
        i.line(x0, y0, x1, y1, P["gold"])
    i.rect(6, 6, 5, 4, P["gold_lit"])
    icons["star"] = i

    # boss crown
    i = base()
    for k, (cx, ch) in enumerate(((2, 6), (5, 3), (8, 1), (11, 3), (13, 6))):
        i.rect(cx, 4, 2, ch + 3, P["gold"])
        i.set(cx, 4, P["gold_lit"])
    i.rect(2, 10, 12, 4, P["gold"])
    i.rect(2, 13, 12, 1, P["gold_drk"])
    i.set(7, 11, P["red"])
    icons["boss"] = i

    # shield
    i = base()
    i.rect(4, 2, 8, 7, P["teal"])
    i.rect(5, 9, 6, 3, P["teal"])
    i.rect(6, 12, 4, 2, P["teal_drk"])
    i.rect(4, 2, 8, 1, P["teal_lit"])
    i.rect(7, 4, 2, 6, P["teal_lit"])
    icons["shield"] = i

    # fire (burn)
    i = base()
    i.circle(8, 10, 4.5, P["fire_drk"])
    i.circle(8, 9, 3.2, P["fire"])
    i.circle(8, 8, 1.6, P["fire_lit"])
    i.rect(8, 2, 2, 5, P["fire_lit"])
    icons["fire"] = i

    # ice
    i = base()
    i.rect(7, 1, 2, 14, P["cyan"])
    i.rect(1, 7, 14, 2, P["cyan"])
    i.rect(3, 3, 10, 10, alpha(P["cyan"], 90))
    i.circle(8, 8, 2, P["white"])
    icons["ice"] = i

    return icons


def coin_icon():
    img = Img(16, 16)
    img.circle(8, 8, 6, P["gold_drk"])
    img.circle(8, 8, 5, P["gold"])
    img.circle(7.5, 7.5, 3, P["gold_lit"])
    img.rect(7, 4, 2, 7, P["gold_drk"])
    img.rect(6, 5, 4, 1, P["gold_drk"])
    img.rect(6, 9, 4, 1, P["gold_drk"])
    img.outline(C("#3a2508"), diagonals=False)
    return img


def banner():
    """Wide decorative strip used behind wave titles."""
    img = Img(160, 40)
    for y in range(40):
        t = y / 39.0
        c = mix(alpha(PANEL_LIT, 235), alpha(PANEL_DRK, 245), t)
        for x in range(160):
            img.set(x, y, c)
    img.rect(0, 0, 160, 2, BORDER_LIT)
    img.rect(0, 38, 160, 2, BORDER_LIT)
    for x in range(0, 160, 8):
        img.set(x, 2, BORDER)
        img.set(x, 37, BORDER)
    # side spikes
    for sx in (0, 152):
        for y in range(40):
            img.set(sx, y, PANEL_DRK)
            img.set(sx + 1 if sx == 0 else sx + 6, y, PANEL_DRK)
    for (cx, cy) in ((8, 20), (152, 20)):
        img.circle(cx, cy, 5, BORDER)
        img.circle(cx, cy, 3, BORDER_LIT)
        img.circle(cx, cy, 1.5, P["gold"])
    return img


def arrow_indicator():
    frames = []
    for i in range(2):
        img = Img(16, 16)
        off = i * 2
        for y in range(7):
            w = 12 - y * 2
            if w <= 0:
                break
            for x in range((16 - w) // 2, (16 + w) // 2):
                img.set(x, y + off - 2, P["slime_lit"])
        frames.append(img)
    return frames


def boss_bar_frame():
    img = Img(8, 12)
    img.rect(0, 0, 8, 12, PANEL_DRK)
    img.rect(0, 0, 8, 1, BORDER)
    img.rect(0, 11, 8, 1, BORDER)
    return img


def cursor_img():
    img = Img(16, 16)
    # pixel crosshair with a tiny sword
    img.rect(7, 1, 2, 5, P["white"])
    img.rect(6, 6, 4, 4, P["white"])
    img.rect(7, 10, 2, 5, P["white"])
    img.rect(1, 7, 5, 2, P["white"])
    img.rect(10, 7, 5, 2, P["white"])
    img.rect(7, 7, 2, 2, P["red"])
    img.outline(C("#120e1c"), diagonals=False)
    return img


def crosshair():
    img = Img(20, 20)
    img.rect(9, 0, 2, 6, alpha(P["white"], 220))
    img.rect(9, 14, 2, 6, alpha(P["white"], 220))
    img.rect(0, 9, 6, 2, alpha(P["white"], 220))
    img.rect(14, 9, 6, 2, alpha(P["white"], 220))
    img.rect(9, 9, 2, 2, P["red"])
    return img


def slot_frame():
    img = Img(40, 40)
    img.rect(0, 0, 40, 40, alpha(SHOP_BG, 220))
    img.border(0, 0, 40, 40, C("#3d3358"), 1)
    img.border(2, 2, 36, 36, C("#2a2340"), 1)
    for (x, y) in ((1, 1), (38, 1), (1, 38), (38, 38)):
        img.set(x, y, BORDER)
    return img


def build():
    single(panel_ninepatch(), "UI/panel.png")
    single(card_ninepatch(), "UI/card.png")
    sheet(button_frames(), "UI/button.png")
    sheet(heart_ui_frames(), "UI/heart.png")
    for name, img in icon_set().items():
        single(img, "UI/icons/%s.png" % name)
    single(banner(), "UI/banner.png")
    sheet(arrow_indicator(), "UI/arrow.png")
    single(boss_bar_frame(), "UI/boss_bar_frame.png")
    single(cursor_img(), "UI/cursor.png")
    single(crosshair(), "UI/crosshair.png")
    single(slot_frame(), "UI/slot.png")
    build_font(2)
