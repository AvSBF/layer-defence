"""Procedural 8-bit style sound effects (16-bit mono WAV, 22050 Hz)."""
from __future__ import annotations

import math
import os
import random
import struct
import wave

from px import OUT

SR = 22050


def _clamp(v, lo=-1.0, hi=1.0):
    return max(lo, min(hi, v))


def square(t, freq):
    return 1.0 if (t * freq) % 1.0 < 0.5 else -1.0


def triangle(t, freq):
    return 4 * abs(((t * freq) % 1.0) - 0.5) - 1


def saw(t, freq):
    return 2 * ((t * freq) % 1.0) - 1


def noise(rnd):
    return rnd.uniform(-1, 1)


def render(duration, fn, sr=SR):
    n = int(duration * sr)
    out = []
    for i in range(n):
        t = i / sr
        out.append(_clamp(fn(t, i / n)))
    return out


def envelope(t, attack=0.01, decay=0.1, sustain=0.6, release=0.2, dur=0.2):
    if t < attack:
        return t / max(1e-5, attack)
    if t < attack + decay:
        return 1.0 - (1.0 - sustain) * ((t - attack) / max(1e-5, decay))
    if t < dur - release:
        return sustain
    return max(0.0, sustain * (dur - t) / max(1e-5, release))


def save(samples, name):
    path = os.path.join(OUT, "..", "Sound", name)
    path = os.path.normpath(path)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(b"".join(struct.pack("<h", int(s * 26000)) for s in samples))
    return path


# ------------------------------------------------------------------ recipes
def sfx_swing(dur=0.18):
    rnd = random.Random(1)
    return render(dur, lambda t, p: (noise(rnd) * 0.5 + triangle(t, 420 - p * 300) * 0.3)
                  * envelope(t, 0.005, 0.05, 0.3, dur - 0.1, dur) * (1 - p) ** 1.5)


def sfx_hit(dur=0.12):
    rnd = random.Random(2)
    return render(dur, lambda t, p: (noise(rnd) * 0.7 + square(t, 160 - p * 90) * 0.5)
                  * envelope(t, 0.002, 0.02, 0.4, dur - 0.05, dur) * (1 - p) ** 2)


def sfx_hit_crit(dur=0.22):
    rnd = random.Random(3)
    return render(dur, lambda t, p: (square(t, 900 - p * 700) * 0.5 + noise(rnd) * 0.5)
                  * envelope(t, 0.002, 0.03, 0.5, dur - 0.06, dur) * (1 - p) ** 1.4)


def sfx_shoot(dur=0.14):
    return render(dur, lambda t, p: (triangle(t, 900 - p * 700) * 0.6 + square(t, 1400 - p * 1200) * 0.25)
                  * envelope(t, 0.002, 0.04, 0.35, dur - 0.05, dur))


def sfx_magic(dur=0.35):
    return render(dur, lambda t, p: (triangle(t, 300 + math.sin(p * 12) * 260 + p * 500) * 0.5
                                     + square(t, 600 + p * 900) * 0.2)
                  * envelope(t, 0.01, 0.1, 0.5, 0.15, dur))


def sfx_explode(dur=0.55):
    rnd = random.Random(4)
    return render(dur, lambda t, p: (noise(rnd) * 0.85 + square(t, 90 - p * 70) * 0.5)
                  * envelope(t, 0.002, 0.08, 0.35, dur - 0.15, dur) * (1 - p * 0.6))


def sfx_coin(dur=0.22):
    return render(dur, lambda t, p: (square(t, 1180 if p < 0.45 else 1560) * 0.35
                                     + triangle(t, 2360) * 0.15)
                  * envelope(t, 0.002, 0.03, 0.5, 0.08, dur))


def sfx_heal(dur=0.45):
    notes = [523, 659, 784, 1046]
    return render(dur, lambda t, p: triangle(t, notes[min(3, int(p * 4))] ) * 0.4
                  * envelope(t, 0.01, 0.05, 0.7, 0.1, dur))


def sfx_pot(dur=0.3):
    rnd = random.Random(5)
    return render(dur, lambda t, p: (noise(rnd) * 0.75 + triangle(t, 340 - p * 240) * 0.3)
                  * envelope(t, 0.002, 0.05, 0.25, 0.15, dur) * (1 - p) ** 1.2)


def sfx_jump(dur=0.16):
    return render(dur, lambda t, p: triangle(t, 300 + p * 500) * 0.35
                  * envelope(t, 0.002, 0.04, 0.5, 0.06, dur))


def sfx_hurt(dur=0.35):
    rnd = random.Random(6)
    return render(dur, lambda t, p: (square(t, 420 - p * 260) * 0.5 + noise(rnd) * 0.25)
                  * envelope(t, 0.005, 0.08, 0.4, 0.15, dur))


def sfx_enemy_die(dur=0.4):
    rnd = random.Random(7)
    return render(dur, lambda t, p: (square(t, 330 - p * 280) * 0.45 + noise(rnd) * 0.3)
                  * envelope(t, 0.005, 0.1, 0.3, 0.2, dur) * (1 - p * 0.5))


def sfx_wave_start(dur=1.1):
    notes = [392, 523, 659, 784]
    def fn(t, p):
        idx = min(3, int(p * 4))
        freq = notes[idx]
        return (square(t, freq) * 0.28 + triangle(t, freq * 2) * 0.12) \
            * envelope(t, 0.01, 0.05, 0.7, 0.08, dur)
    return render(dur, fn)


def sfx_gate(dur=0.5):
    return render(dur, lambda t, p: triangle(t, 440 + p * 660) * 0.3
                  * envelope(t, 0.01, 0.1, 0.6, 0.15, dur))


def sfx_buy(dur=0.3):
    def fn(t, p):
        f = 700 if p < 0.4 else (950 if p < 0.7 else 1300)
        return square(t, f) * 0.3 * envelope(t, 0.002, 0.04, 0.5, 0.1, dur)
    return render(dur, fn)


def sfx_reroll(dur=0.4):
    rnd = random.Random(8)
    return render(dur, lambda t, p: (square(t, 200 + p * 900) * 0.25 + noise(rnd) * 0.2)
                  * envelope(t, 0.005, 0.06, 0.4, 0.1, dur))


def sfx_boss(dur=1.4):
    rnd = random.Random(9)
    def fn(t, p):
        base = 70 + math.sin(p * 20) * 12
        return (square(t, base) * 0.5 + saw(t, base * 1.5) * 0.25 + noise(rnd) * 0.18) \
            * envelope(t, 0.05, 0.3, 0.75, 0.4, dur)
    return render(dur, fn)


def sfx_game_over(dur=1.6):
    notes = [392, 330, 262, 196]
    def fn(t, p):
        idx = min(3, int(p * 4))
        f = notes[idx]
        return (triangle(t, f) * 0.35 + square(t, f / 2) * 0.15) \
            * envelope(t, 0.02, 0.1, 0.6, 0.2, dur)
    return render(dur, fn)


def sfx_click(dur=0.08):
    return render(dur, lambda t, p: square(t, 900) * 0.3 * envelope(t, 0.001, 0.02, 0.4, 0.03, dur))


def sfx_dash(dur=0.25):
    rnd = random.Random(10)
    return render(dur, lambda t, p: (noise(rnd) * 0.4 + triangle(t, 220 + p * 700) * 0.35)
                  * envelope(t, 0.002, 0.05, 0.4, 0.1, dur))


def sfx_level_up(dur=0.8):
    notes = [523, 659, 784, 1046, 1318]
    def fn(t, p):
        idx = min(4, int(p * 5))
        f = notes[idx]
        return (square(t, f) * 0.25 + triangle(t, f * 1.5) * 0.15) \
            * envelope(t, 0.005, 0.04, 0.6, 0.06, dur)
    return render(dur, fn)


def sfx_web(dur=0.25):
    rnd = random.Random(11)
    return render(dur, lambda t, p: (noise(rnd) * 0.3 + triangle(t, 600 - p * 400) * 0.3)
                  * envelope(t, 0.005, 0.05, 0.3, 0.1, dur))


def sfx_freeze(dur=0.5):
    return render(dur, lambda t, p: (triangle(t, 1200 - p * 800) * 0.3 + square(t, 1800 - p * 900) * 0.15)
                  * envelope(t, 0.005, 0.1, 0.4, 0.2, dur))


RECIPES = {
    "swing.wav": sfx_swing,
    "hit.wav": sfx_hit,
    "hit_crit.wav": sfx_hit_crit,
    "shoot.wav": sfx_shoot,
    "magic.wav": sfx_magic,
    "explode.wav": sfx_explode,
    "coin.wav": sfx_coin,
    "heal.wav": sfx_heal,
    "pot.wav": sfx_pot,
    "jump.wav": sfx_jump,
    "hurt.wav": sfx_hurt,
    "enemy_die.wav": sfx_enemy_die,
    "wave_start.wav": sfx_wave_start,
    "gate.wav": sfx_gate,
    "buy.wav": sfx_buy,
    "reroll.wav": sfx_reroll,
    "boss.wav": sfx_boss,
    "game_over.wav": sfx_game_over,
    "click.wav": sfx_click,
    "dash.wav": sfx_dash,
    "level_up.wav": sfx_level_up,
    "web.wav": sfx_web,
    "freeze.wav": sfx_freeze,
}


def build():
    for name, fn in RECIPES.items():
        save(fn(), name)
    print("[sfx] generated %d sounds" % len(RECIPES))
