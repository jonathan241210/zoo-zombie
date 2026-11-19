"""Synthesizes the placeholder weapon/pickup sound effects (spec 001 RF-53, RF-5C, RF-56).

The project has no recorded SFX yet, so these are generated procedurally (original work,
no third-party license). Re-run to regenerate:

    python3 tools/generate_sfx.py

Output: godot_zoo-zombie/zoo-zombie-godot/assets/audio/sfx/*.wav (mono, 16-bit, 44.1 kHz).
Uses only the standard library and a fixed seed, so the result is reproducible.
"""

import math
import random
import struct
import wave
from pathlib import Path

RATE = 44100
OUT_DIR = Path(__file__).resolve().parent.parent / "godot_zoo-zombie/zoo-zombie-godot/assets/audio/sfx"


def lowpass(samples, cutoff_hz):
    """One-pole low-pass filter."""
    alpha = 1.0 - math.exp(-2.0 * math.pi * cutoff_hz / RATE)
    out, state = [], 0.0
    for s in samples:
        state += alpha * (s - state)
        out.append(state)
    return out


def highpass(samples, cutoff_hz):
    low = lowpass(samples, cutoff_hz)
    return [s - l for s, l in zip(samples, low)]


def noise(rng, seconds):
    return [rng.uniform(-1.0, 1.0) for _ in range(int(RATE * seconds))]


def normalize(samples, peak=0.9):
    top = max(abs(s) for s in samples) or 1.0
    return [s / top * peak for s in samples]


def write(name, samples):
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    path = OUT_DIR / f"{name}.wav"
    with wave.open(str(path), "wb") as wav:
        wav.setnchannels(1)
        wav.setsampwidth(2)
        wav.setframerate(RATE)
        wav.writeframes(b"".join(struct.pack("<h", int(max(-1.0, min(1.0, s)) * 32767)) for s in samples))
    print(f"[sfx] {path.name}: {len(samples) / RATE:.2f} s")


def shotgun_fire(rng):
    """Sharp crack + filtered noise tail + low thump."""
    seconds = 0.9
    raw = noise(rng, seconds)
    body = lowpass(raw, 2200.0)
    crack = highpass(raw, 3000.0)
    out = []
    for i, (b, c) in enumerate(zip(body, crack)):
        t = i / RATE
        attack = min(t / 0.002, 1.0)
        thump = math.sin(2.0 * math.pi * (70.0 - 30.0 * t) * t) * math.exp(-t * 14.0)
        out.append(attack * (b * math.exp(-t * 7.0) * 1.6 + c * math.exp(-t * 40.0) * 0.8 + thump * 0.9))
    return normalize(out)


def axe_swing(rng):
    """Air whoosh: band-limited noise with a rising-falling envelope."""
    seconds = 0.35
    raw = highpass(lowpass(noise(rng, seconds), 1800.0), 300.0)
    out = []
    for i, s in enumerate(raw):
        t = i / seconds / RATE
        out.append(s * math.sin(math.pi * t) ** 2)
    return normalize(out, 0.6)


def axe_hit(rng):
    """Dull impact: short noise burst over a low decaying tone."""
    seconds = 0.3
    raw = lowpass(noise(rng, seconds), 1400.0)
    out = []
    for i, s in enumerate(raw):
        t = i / RATE
        tone = math.sin(2.0 * math.pi * 115.0 * t) * math.exp(-t * 22.0)
        out.append(s * math.exp(-t * 35.0) * 1.4 + tone)
    return normalize(out, 0.85)


def ammo_pickup(rng):
    """Two quick metallic clicks."""
    seconds = 0.28
    out = [0.0] * int(RATE * seconds)
    for start, freq in ((0.0, 1900.0), (0.09, 2600.0)):
        offset = int(start * RATE)
        for i in range(int(0.12 * RATE)):
            t = i / RATE
            ring = math.sin(2.0 * math.pi * freq * t) + 0.5 * math.sin(2.0 * math.pi * freq * 2.7 * t)
            out[offset + i] += (ring + rng.uniform(-0.3, 0.3)) * math.exp(-t * 60.0)
    return normalize(out, 0.55)


def main():
    rng = random.Random(1729)
    write("shotgun_fire", shotgun_fire(rng))
    write("axe_swing", axe_swing(rng))
    write("axe_hit", axe_hit(rng))
    write("ammo_pickup", ammo_pickup(rng))


if __name__ == "__main__":
    main()
