"""Tiny pixel-art toolkit built on top of Pillow.

Everything in the game art is produced by these primitives: no external
assets, every sprite is deterministic and reproducible from source.
"""
from __future__ import annotations

import json
import os
from PIL import Image

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(ROOT, "Aseprites", "Generated")
MANIFEST = {}

TRANSPARENT = (0, 0, 0, 0)


def C(hexstr, a=255):
    """hex ('#rrggbb' or 'rrggbb') -> RGBA tuple"""
    hexstr = hexstr.lstrip("#")
    return (int(hexstr[0:2], 16), int(hexstr[2:4], 16), int(hexstr[4:6], 16), a)


def shift(color, amount):
    r, g, b, a = color
    return (
        max(0, min(255, r + amount)),
        max(0, min(255, g + amount)),
        max(0, min(255, b + amount)),
        a,
    )


def mix(c1, c2, t):
    return tuple(int(c1[i] + (c2[i] - c1[i]) * t) for i in range(4))


def alpha(color, a):
    return (color[0], color[1], color[2], int(a))


class Img:
    """A mutable RGBA pixel buffer with friendly drawing helpers."""

    def __init__(self, w, h, fill=TRANSPARENT):
        self.w = w
        self.h = h
        self.px = [[fill for _ in range(w)] for _ in range(h)]

    # ---------------------------------------------------------------- basics
    def set(self, x, y, color):
        x = int(x)
        y = int(y)
        if color is None or x < 0 or y < 0 or x >= self.w or y >= self.h:
            return
        if color[3] == 0:
            return
        self.px[y][x] = color

    def get(self, x, y):
        if x < 0 or y < 0 or x >= self.w or y >= self.h:
            return TRANSPARENT
        return self.px[y][x]

    def opaque(self, x, y):
        return self.get(x, y)[3] > 0

    def blend(self, x, y, color):
        """Alpha-composite `color` over whatever is already there."""
        x = int(x)
        y = int(y)
        if x < 0 or y < 0 or x >= self.w or y >= self.h or color[3] == 0:
            return
        dst = self.px[y][x]
        if dst[3] == 0:
            self.px[y][x] = (color[0], color[1], color[2], color[3])
            return
        sa = color[3] / 255.0
        da = dst[3] / 255.0
        oa = sa + da * (1.0 - sa)
        if oa <= 0.0:
            return
        out = []
        for i in range(3):
            out.append(int(round((color[i] * sa + dst[i] * da * (1.0 - sa)) / oa)))
        self.px[y][x] = (out[0], out[1], out[2], int(round(oa * 255)))

    def blend_ellipse(self, cx, cy, rx, ry, color):
        for yy in range(int(cy - ry) - 1, int(cy + ry) + 2):
            for xx in range(int(cx - rx) - 1, int(cx + rx) + 2):
                dx = (xx - cx) / max(0.001, rx)
                dy = (yy - cy) / max(0.001, ry)
                if dx * dx + dy * dy <= 1.0:
                    self.blend(xx, yy, color)

    def rect(self, x, y, w, h, color):
        x, y, w, h = int(round(x)), int(round(y)), int(round(w)), int(round(h))
        for yy in range(y, y + h):
            for xx in range(x, x + w):
                self.set(xx, yy, color)

    def border(self, x, y, w, h, color, thickness=1):
        for t in range(thickness):
            for xx in range(x, x + w):
                self.set(xx, y + t, color)
                self.set(xx, y + h - 1 - t, color)
            for yy in range(y, y + h):
                self.set(x + t, yy, color)
                self.set(x + w - 1 - t, yy, color)

    def ellipse(self, cx, cy, rx, ry, color, filled=True):
        if rx <= 0 or ry <= 0:
            return
        for yy in range(int(cy - ry) - 1, int(cy + ry) + 2):
            for xx in range(int(cx - rx) - 1, int(cx + rx) + 2):
                dx = (xx - cx) / rx
                dy = (yy - cy) / ry
                d = dx * dx + dy * dy
                if filled:
                    if d <= 1.0:
                        self.set(xx, yy, color)
                else:
                    if 0.45 <= d <= 1.0:
                        self.set(xx, yy, color)

    def circle(self, cx, cy, r, color, filled=True):
        self.ellipse(cx, cy, r, r, color, filled)

    def line(self, x0, y0, x1, y1, color):
        x0, y0, x1, y1 = int(x0), int(y0), int(x1), int(y1)
        dx = abs(x1 - x0)
        dy = -abs(y1 - y0)
        sx = 1 if x0 < x1 else -1
        sy = 1 if y0 < y1 else -1
        err = dx + dy
        while True:
            self.set(x0, y0, color)
            if x0 == x1 and y0 == y1:
                break
            e2 = 2 * err
            if e2 >= dy:
                err += dy
                x0 += sx
            if e2 <= dx:
                err += dx
                y0 += sy

    def paste(self, other, x, y, flip=False):
        for yy in range(other.h):
            for xx in range(other.w):
                sx = other.w - 1 - xx if flip else xx
                self.set(x + xx, y + yy, other.px[yy][sx])

    def flipped(self):
        out = Img(self.w, self.h)
        for y in range(self.h):
            for x in range(self.w):
                out.px[y][x] = self.px[y][self.w - 1 - x]
        return out

    def copy(self):
        out = Img(self.w, self.h)
        out.px = [row[:] for row in self.px]
        return out

    # ------------------------------------------------------------- utilities
    def bbox(self):
        minx, miny, maxx, maxy = self.w, self.h, -1, -1
        for y in range(self.h):
            for x in range(self.w):
                if self.px[y][x][3] > 0:
                    minx = min(minx, x)
                    miny = min(miny, y)
                    maxx = max(maxx, x)
                    maxy = max(maxy, y)
        if maxx < 0:
            return None
        return (minx, miny, maxx, maxy)

    def crop_to(self, w, h, anchor_bottom=True):
        """Crop/pad so the opaque content sits inside a w x h frame."""
        box = self.bbox()
        out = Img(w, h)
        if box is None:
            return out
        bw = box[2] - box[0] + 1
        bh = box[3] - box[1] + 1
        ox = (w - bw) // 2
        oy = h - bh if anchor_bottom else (h - bh) // 2
        for y in range(bh):
            for x in range(bw):
                out.set(ox + x, oy + y, self.get(box[0] + x, box[1] + y))
        return out

    def outline(self, color, diagonals=True, skip=None):
        """Add a 1px outline around the whole silhouette."""
        additions = []
        for y in range(self.h):
            for x in range(self.w):
                if self.opaque(x, y):
                    continue
                near = False
                for dy in (-1, 0, 1):
                    for dx in (-1, 0, 1):
                        if dx == 0 and dy == 0:
                            continue
                        if not diagonals and dx != 0 and dy != 0:
                            continue
                        if self.opaque(x + dx, y + dy):
                            near = True
                if near:
                    if skip and self.get(x, y)[3] > 0:
                        continue
                    additions.append((x, y))
        for (x, y) in additions:
            self.set(x, y, color)
        return self

    def recolor(self, mapping):
        for y in range(self.h):
            for x in range(self.w):
                c = self.px[y][x]
                if c in mapping:
                    self.px[y][x] = mapping[c]
        return self

    def replace_all(self, color):
        for y in range(self.h):
            for x in range(self.w):
                c = self.px[y][x]
                if c[3] > 0:
                    self.px[y][x] = (color[0], color[1], color[2], c[3])
        return self

    def shade_column(self, x0, x1, top, bottom):
        """Vertical gradient replace of opaque pixels between two colors."""
        for y in range(self.h):
            t = y / max(1, self.h - 1)
            for x in range(x0, x1):
                c = self.px[y][x]
                if c[3] > 0:
                    self.px[y][x] = (mix(top, bottom, t)[0], mix(top, bottom, t)[1], mix(top, bottom, t)[2], c[3])
        return self

    def darken_bottom(self, amount=40, rows=6):
        box = self.bbox()
        if not box:
            return self
        for i in range(rows):
            y = box[3] - i
            if y < 0:
                break
            f = amount * (rows - i) / rows
            for x in range(self.w):
                c = self.px[y][x]
                if c[3] > 0:
                    self.px[y][x] = shift(c, -int(f))
        return self

    def dither_shade(self, color, keep_left=2):
        """Diagonal dithering on the right edge for a soft pixel-art look."""
        box = self.bbox()
        if not box:
            return self
        for y in range(box[1], box[3] + 1):
            for x in range(box[2] - keep_left, box[2] + 1):
                if self.opaque(x, y) and (x + y) % 2 == 0:
                    self.set(x, y, color)
        return self

    def glow(self, color, radius=3, strength=110):
        sources = []
        for y in range(self.h):
            for x in range(self.w):
                if self.px[y][x][3] > 0:
                    sources.append((x, y))
        overlay = Img(self.w, self.h)
        for (sx, sy) in sources:
            for dy in range(-radius, radius + 1):
                for dx in range(-radius, radius + 1):
                    d = (dx * dx + dy * dy) ** 0.5
                    if d > radius or d == 0:
                        continue
                    a = int(strength * (1 - d / radius))
                    x, y = sx + dx, sy + dy
                    if self.opaque(x, y):
                        continue
                    prev = overlay.get(x, y)
                    overlay.set(x, y, alpha(color, max(a, prev[3])))
        out = Img(self.w, self.h)
        out.px = overlay.px
        out.paste(self, 0, 0)
        return out

    # -------------------------------------------------------------- exporting
    def save(self, relpath):
        path = os.path.join(OUT, relpath)
        os.makedirs(os.path.dirname(path), exist_ok=True)
        img = Image.new("RGBA", (self.w, self.h))
        img.putdata([self.px[y][x] for y in range(self.h) for x in range(self.w)])
        img.save(path)
        return path


def sheet(frames, name, flip_frames=None):
    """Compose a horizontal strip of equally sized frames into one PNG."""
    if not frames:
        return
    fw, fh = frames[0].w, frames[0].h
    out = Img(fw * len(frames), fh)
    for i, f in enumerate(frames):
        out.paste(f, i * fw, 0)
    out.save(name)
    key = name.replace("\\", "/")
    MANIFEST[key] = {
        "frames": len(frames),
        "frame_w": fw,
        "frame_h": fh,
    }


def single(img, name):
    img.save(name)
    MANIFEST[name.replace("\\", "/")] = {
        "frames": 1,
        "frame_w": img.w,
        "frame_h": img.h,
    }


def write_manifest():
    path = os.path.join(OUT, "manifest.json")
    os.makedirs(OUT, exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        json.dump(MANIFEST, f, indent=1, sort_keys=True)
    print("[artgen] wrote", len(MANIFEST), "sprites ->", OUT)


# --------------------------------------------------------------------- shapes
def blob(w, h, color, squash=0.0, bias=0.5):
    """Soft rounded blob used for slimes, ghosts, clouds."""
    img = Img(w, h)
    rx = (w - 2) / 2
    ry = (h - 2) / 2
    cx = (w - 1) / 2
    cy = (h - 1) / 2 + squash * (h / 3)
    for y in range(h):
        for x in range(w):
            dx = (x - cx) / rx
            dy = (y - cy) / ry
            # squarish bottom like classic slime pixel art
            d = dx * dx + max(0.0, dy) ** 2 * 1.1 + (dy * dy if dy < 0 else 0)
            if d <= 1.0:
                img.set(x, y, color)
    return img


def rounded_rect(w, h, color, r=2):
    img = Img(w, h)
    for y in range(h):
        for x in range(w):
            edge_x = min(x, w - 1 - x)
            edge_y = min(y, h - 1 - y)
            if edge_x == 0 and (edge_y < r or edge_y > h - 1 - r):
                continue
            if edge_y == 0 and (edge_x < r or edge_x > w - 1 - r):
                continue
            img.set(x, y, color)
    return img


def from_art(lines, palette):
    """Build an Img from a list of equal-length strings + palette map."""
    h = len(lines)
    w = max(len(l) for l in lines)
    img = Img(w, h)
    for y, line in enumerate(lines):
        for x, ch in enumerate(line):
            if ch == " " or ch == ".":
                continue
            color = palette.get(ch)
            if color is None:
                raise KeyError("unknown palette char %r" % ch)
            img.set(x, y, color)
    return img
