"""Procedural sound effects - "cozy 8-bit" edition.

Design rules that keep the mix soft instead of stressful:
  * only sine / triangle oscillators - no square, no saw, no growls;
  * noise is used as a quiet transient, never as the body of a sound;
  * every sound is low-passed, so nothing has harsh high harmonics;
  * intervals are major and consonant (C-E-G arpeggios, fourths, fifths);
  * short attack ramps (5-15 ms) + exponential release = no clicks;
  * peak level is kept around 0.6 so stacking 10 hits never clips.
"""
from __future__ import annotations

import math
import os
import random
import struct
import wave

from px import OUT

SR = 22050
TAU = math.pi * 2.0


# ------------------------------------------------------------------ oscillators
def sine(t, freq):
    return math.sin(t * freq * TAU)


def triangle(t, freq):
    return 4.0 * abs(((t * freq) % 1.0) - 0.5) - 1.0


def noise(rnd):
    return rnd.uniform(-1.0, 1.0)


def marimba(t, freq, decay=9.0):
    """Sine + soft octave partial with an exponential body - warm and wooden."""
    env = math.exp(-t * decay)
    return (sine(t, freq) + 0.28 * sine(t, freq * 2.0) * math.exp(-t * decay * 1.8)) * env


def bell(t, freq, decay=5.0):
    """Struck bell: fundamental + a quiet musical partial (a fifth, no clang)."""
    env = math.exp(-t * decay)
    return (sine(t, freq) * 0.8 + sine(t, freq * 1.5) * 0.22 * math.exp(-t * decay * 1.5)) * env


def pluck(t, freq, decay=7.0):
    return (sine(t, freq) + 0.18 * triangle(t, freq * 2.0)) * math.exp(-t * decay)


# ------------------------------------------------------------------- envelopes
def envelope(t, attack=0.012, decay=0.08, sustain=0.7, release=0.12, dur=0.2):
    if t < attack:
        return (t / max(1e-5, attack)) ** 0.7
    if t < attack + decay:
        return 1.0 - (1.0 - sustain) * ((t - attack) / max(1e-5, decay))
    if t < dur - release:
        return sustain
    return max(0.0, sustain * ((dur - t) / max(1e-5, release)) ** 1.4)


def smooth_edges(samples, ms=6):
    """Fade the first/last few milliseconds - removes the click of a hard cut."""
    n = len(samples)
    k = max(2, int(SR * ms / 1000.0))
    k = min(k, n // 2)
    for i in range(k):
        f = i / k
        samples[i] *= f
        samples[n - 1 - i] *= f
    return samples


def lowpass(samples, cutoff_hz=3200.0, order=2):
    """One-pole (x2) low-pass: kills the brittle top end of raw synthesis."""
    alpha = 1.0 - math.exp(-TAU * cutoff_hz / SR)
    out = samples
    for _ in range(order):
        prev = 0.0
        buf = []
        for s in out:
            prev += alpha * (s - prev)
            buf.append(prev)
        out = buf
    return out


def normalize(samples, peak=0.6):
    top = max(1e-6, max(abs(s) for s in samples))
    k = peak / top
    return [math.tanh(s * k * 1.08) * 0.94 for s in samples]


def render(duration, fn, sr=SR):
    return [fn(i / sr, i / max(1, int(duration * sr) - 1)) for i in range(int(duration * sr))]


def finish(samples, cutoff=3000.0, peak=0.6):
    return smooth_edges(lowpass(normalize(samples, peak), cutoff))


def chord_arp(t, p, notes, note_len=0.13, decay=8.0):
    idx = min(len(notes) - 1, int(p / note_len))
    local = (p - idx * note_len) * note_len / max(1e-5, note_len)
    return marimba(t, notes[idx], decay) if local >= 0 else 0.0


def save(samples, name):
    path = os.path.normpath(os.path.join(OUT, "..", "Sound", name))
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1.0, min(1.0, s)) * 26000)) for s in samples))
    return path


# --------------------------------------------------------------------- recipes
C5, D5, E5, G5, A5, C6, E6, G6, C7 = 523.25, 587.33, 659.25, 783.99, 880.0, 1046.5, 1318.5, 1568.0, 2093.0


def sfx_swing(dur=0.16):
    """Soft air sweep - a brush of wind, not a blade."""
    rnd = random.Random(1)
    def fn(t, p):
        gust = (noise(rnd) * 0.5 + sine(t, 340 + p * 260) * 0.35)
        return gust * envelope(t, 0.02, 0.06, 0.4, dur - 0.09, dur) * (1 - p) ** 1.2 * 0.7
    return finish(render(dur, fn), cutoff=2400.0, peak=0.42)


def sfx_hit(dur=0.1):
    """Wooden 'toc' - short, warm, satisfying."""
    rnd = random.Random(2)
    def fn(t, p):
        body = marimba(t, 300 - p * 70, 16.0) * 0.85
        tap = noise(rnd) * math.exp(-t * 60.0) * 0.18
        return (body + tap) * envelope(t, 0.002, 0.02, 0.35, dur - 0.04, dur)
    return finish(render(dur, fn), cutoff=2600.0, peak=0.55)


def sfx_hit_crit(dur=0.26):
    """A bright little bell for critical hits."""
    def fn(t, p):
        return bell(t, E6 * (1.0 + p * 0.1), 6.5) * 0.8 + sine(t, C7) * math.exp(-t * 12.0) * 0.15
    return finish(render(dur, fn), cutoff=4200.0, peak=0.55)


def sfx_shoot(dur=0.14):
    """Friendly 'pop' with a rising pitch."""
    def fn(t, p):
        return (triangle(t, 420 + p * 520) * 0.6 + sine(t, 840 + p * 900) * 0.25) \
            * envelope(t, 0.004, 0.04, 0.45, dur - 0.05, dur)
    return finish(render(dur, fn), cutoff=3200.0, peak=0.5)


def sfx_magic(dur=0.42):
    """Sparkly ascending arpeggio (C-E-G-C)."""
    def fn(t, p):
        i = min(3, int(p * 4))
        f = [C6, E6, G6, C7][i]
        return (marimba(t, f, 5.5) * 0.6 + sine(t, f * 2.0) * math.exp(-t * 14.0) * 0.12)
    return finish(render(dur, fn), cutoff=4600.0, peak=0.5)


def sfx_explode(dur=0.5):
    """A cushiony 'poof' - no rumble, no shrapnel."""
    rnd = random.Random(4)
    def fn(t, p):
        puff = noise(rnd) * math.exp(-t * 9.0) * (1.0 - p * 0.5)
        body = sine(t, 150 - p * 60) * math.exp(-t * 6.0) * 0.5
        return puff * 0.45 + body
    return finish(render(dur, fn), cutoff=1500.0, peak=0.55)


def sfx_coin(dur=0.24):
    """Two-note marimba 'ching' (G5 -> D6), soft and bright."""
    def fn(t, p):
        f = G5 if p < 0.42 else 1174.66
        return marimba(t, f, 9.0) * 0.75 + sine(t, f * 2.0) * math.exp(-t * 18.0) * 0.1
    return finish(render(dur, fn), cutoff=5200.0, peak=0.5)


def sfx_heal(dur=0.55):
    """Gentle ascending C-major arpeggio: 'you are safe'."""
    notes = [C5, E5, G5, C6]
    def fn(t, p):
        i = min(3, int(p * 4))
        f = notes[i]
        return (marimba(t, f, 4.0) * 0.6 + sine(t, f * 1.5) * math.exp(-t * 6.0) * 0.12)
    return finish(render(dur, fn), cutoff=4200.0, peak=0.5)


def sfx_pot(dur=0.26):
    """Hollow clay 'tock'."""
    rnd = random.Random(5)
    def fn(t, p):
        return (marimba(t, 260 - p * 60, 13.0) * 0.7 + noise(rnd) * math.exp(-t * 45.0) * 0.22)
    return finish(render(dur, fn), cutoff=2200.0, peak=0.5)


def sfx_jump(dur=0.18):
    """Soft upward 'boing'."""
    def fn(t, p):
        return triangle(t, 300 + p * 420) * 0.55 * envelope(t, 0.006, 0.05, 0.5, 0.06, dur)
    return finish(render(dur, fn), cutoff=2600.0, peak=0.45)


def sfx_hurt(dur=0.3):
    """A cartoon 'aw' - two soft descending notes, no buzz."""
    def fn(t, p):
        f = 660.0 if p < 0.45 else 523.25
        wob = 1.0 + math.sin(t * 42.0) * 0.012
        return (triangle(t, f * wob) * 0.55 + sine(t, f * 0.5) * 0.2) \
            * envelope(t, 0.01, 0.06, 0.65, 0.1, dur)
    return finish(render(dur, fn), cutoff=2600.0, peak=0.5)


def sfx_enemy_die(dur=0.32):
    """Cute descending 'poof'."""
    def fn(t, p):
        f = 700 - p * 320
        return (marimba(t, f, 7.0) * 0.6 + sine(t, f * 0.5) * math.exp(-t * 10.0) * 0.15)
    return finish(render(dur, fn), cutoff=3200.0, peak=0.45)


def sfx_wave_start(dur=0.9):
    """Warm major fanfare (C-E-G-C), soft triangle + sine."""
    notes = [C5, E5, G5, C6]
    def fn(t, p):
        i = min(3, int(p * 4))
        f = notes[i]
        return (triangle(t, f) * 0.34 + sine(t, f * 2.0) * 0.12) \
            * envelope(t, 0.02, 0.06, 0.7, 0.1, dur)
    return finish(render(dur, fn), cutoff=3400.0, peak=0.5)


def sfx_gate(dur=0.6):
    """Warm chime that says 'come in'."""
    def fn(t, p):
        return (bell(t, G5 * (1.0 + p * 0.25), 3.2) * 0.6 + sine(t, C6) * math.exp(-t * 4.0) * 0.15)
    return finish(render(dur, fn), cutoff=4200.0, peak=0.45)


def sfx_buy(dur=0.34):
    """Soft 'cha-ching'."""
    def fn(t, p):
        f = E5 if p < 0.35 else (A5 if p < 0.65 else C6)
        return marimba(t, f, 8.0) * 0.65 + sine(t, f * 2.0) * math.exp(-t * 16.0) * 0.1
    return finish(render(dur, fn), cutoff=5200.0, peak=0.5)


def sfx_reroll(dur=0.4):
    """Gentle card shuffle."""
    rnd = random.Random(8)
    def fn(t, p):
        swish = noise(rnd) * 0.35 * math.sin(p * math.pi) ** 2
        return swish + triangle(t, 400 + p * 300) * 0.12
    return finish(render(dur, fn), cutoff=2200.0, peak=0.4)


def sfx_boss(dur=1.5):
    """Deep but warm horn - 'a big creature arrived', not a scare sting."""
    def fn(t, p):
        base = 82.0 + math.sin(p * 6.0) * 4.0
        swell = math.sin(min(1.0, p * 3.0) * math.pi * 0.5)
        return (sine(t, base) * 0.6 + sine(t, base * 1.5) * 0.22 + sine(t, base * 2.0) * 0.1) * swell \
            * envelope(t, 0.18, 0.4, 0.85, 0.5, dur)
    return finish(render(dur, fn), cutoff=1400.0, peak=0.6)


def sfx_game_over(dur=1.8):
    """Soft lullaby cadence (C-A-F-C), gentle landing instead of doom."""
    notes = [C5, A5 / 2.0, 349.23, C5 / 2.0]
    def fn(t, p):
        i = min(3, int(p * 4))
        f = notes[i]
        return (marimba(t, f, 2.2) * 0.6 + sine(t, f * 0.5) * math.exp(-t * 3.0) * 0.18) \
            * envelope(t, 0.03, 0.1, 0.8, 0.3, dur)
    return finish(render(dur, fn), cutoff=2600.0, peak=0.5)


def sfx_click(dur=0.07):
    def fn(t, p):
        return marimba(t, 1400, 60.0) * 0.5
    return finish(render(dur, fn), cutoff=4000.0, peak=0.35)


def sfx_dash(dur=0.22):
    """Airy whoosh."""
    rnd = random.Random(10)
    def fn(t, p):
        return (noise(rnd) * 0.45 + sine(t, 260 + p * 500) * 0.25) \
            * math.sin(p * math.pi) * 0.8
    return finish(render(dur, fn), cutoff=2000.0, peak=0.42)


def sfx_level_up(dur=0.85):
    """Rising major pentatonic sparkle."""
    notes = [C5, D5, E5, G5, A5, C6]
    def fn(t, p):
        i = min(5, int(p * 6))
        f = notes[i]
        return (marimba(t, f, 4.5) * 0.6 + sine(t, f * 2.0) * math.exp(-t * 12.0) * 0.1)
    return finish(render(dur, fn), cutoff=4600.0, peak=0.5)


def sfx_web(dur=0.24):
    """Soft sticky 'splat'."""
    rnd = random.Random(11)
    def fn(t, p):
        return (noise(rnd) * math.exp(-t * 14.0) * 0.35 + marimba(t, 220, 12.0) * 0.35)
    return finish(render(dur, fn), cutoff=1800.0, peak=0.42)


def sfx_freeze(dur=0.55):
    """Glass chime, cold but pretty."""
    def fn(t, p):
        f = 1568.0 * (1.0 + p * 0.35)
        return (sine(t, f) * math.exp(-t * 3.4) * 0.5 + sine(t, f * 1.5) * math.exp(-t * 5.0) * 0.2)
    return finish(render(dur, fn), cutoff=6000.0, peak=0.42)


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
    print("[sfx] generated %d cozy sounds" % len(RECIPES))
