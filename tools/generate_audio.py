"""Generate the procedural soundtrack and sound effects for Circulo.

Everything here is synthesized from sine waves and filtered noise, so the
whole audio layer can be rebuilt without external samples. Run from the
repository root:

    python tools/generate_audio.py

The script writes 16-bit mono WAV files to assets/audio/.
"""

from __future__ import annotations

import math
import wave
from pathlib import Path

import numpy as np

SR = 22050
OUT = Path(__file__).resolve().parent.parent / "assets" / "audio"


# ------------------------------------------------------------------ helpers
def t_axis(duration: float) -> np.ndarray:
    return np.arange(int(duration * SR), dtype=np.float64) / SR


def write_wav(name: str, samples: np.ndarray) -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    data = np.asarray(samples, dtype=np.float64)
    peak = float(np.max(np.abs(data))) if data.size else 0.0
    if peak > 0.92:
        data = data * (0.92 / peak)
    data = np.clip(data, -1.0, 1.0)
    pcm = (data * 32767.0).astype("<i2")
    path = OUT / name
    with wave.open(str(path), "wb") as handle:
        handle.setnchannels(1)
        handle.setsampwidth(2)
        handle.setframerate(SR)
        handle.writeframes(pcm.tobytes())
    print("wrote %s (%d samples)" % (path.name, data.size))


def tone(freq: float, t: np.ndarray, phase: float = 0.0) -> np.ndarray:
    return np.sin(2.0 * math.pi * freq * t + phase)


def bell(freq: float, duration: float, decay: float, amp: float = 1.0) -> np.ndarray:
    t = t_axis(duration)
    env = (1.0 - np.exp(-t / 0.006)) * np.exp(-t / decay)
    body = (
        tone(freq, t)
        + 0.42 * tone(freq * 2.005, t) * np.exp(-t / (decay * 0.55))
        + 0.18 * tone(freq * 3.01, t) * np.exp(-t / (decay * 0.35))
    )
    return amp * body * env


def periodic_noise(n: int, seed: int, low: float, high: float, slope: float = 1.0) -> np.ndarray:
    """Noise built in the frequency domain, so it loops perfectly."""
    rng = np.random.default_rng(seed)
    bins = n // 2 + 1
    spectrum = rng.normal(size=bins) + 1j * rng.normal(size=bins)
    freqs = np.fft.rfftfreq(n, 1.0 / SR)
    mask = np.ones_like(freqs)
    mask[freqs < low] = 0.0
    mask[freqs > high] = 0.0
    # Soften the band edges to avoid metallic ringing.
    edge = (freqs >= low) & (freqs <= low * 1.6)
    mask[edge] *= 0.5 - 0.5 * np.cos(np.pi * (freqs[edge] - low) / (low * 0.6))
    edge = (freqs >= high * 0.65) & (freqs <= high)
    mask[edge] *= 0.5 + 0.5 * np.cos(np.pi * (freqs[edge] - high * 0.65) / (high * 0.35))
    spectrum *= mask / np.maximum(freqs, 1.0) ** slope
    signal = np.fft.irfft(spectrum, n)
    peak = float(np.max(np.abs(signal)))
    return signal / peak if peak > 0.0 else signal


def bandpass(signal: np.ndarray, low: float, high: float) -> np.ndarray:
    spectrum = np.fft.rfft(signal)
    freqs = np.fft.rfftfreq(signal.size, 1.0 / SR)
    mask = ((freqs >= low) & (freqs <= high)).astype(np.float64)
    filtered = np.fft.irfft(spectrum * mask, signal.size)
    peak = float(np.max(np.abs(filtered)))
    return filtered / peak if peak > 0.0 else filtered


def place_at(mix: np.ndarray, sound: np.ndarray, at: float) -> None:
    start = int(at * SR)
    end = min(mix.size, start + sound.size)
    if start < mix.size:
        mix[start:end] += sound[: end - start]


def aligned(freq: float, duration: float) -> float:
    """Nudge a frequency so the loop contains a whole number of cycles."""
    return round(freq * duration) / duration


# ------------------------------------------------------------------ music
def menu_theme() -> np.ndarray:
    duration = 40.0
    n = int(duration * SR)
    t = np.arange(n, dtype=np.float64) / SR
    mix = np.zeros(n)

    # Low, slow organ-like drone in D minor.
    voices = [
        (73.42, 0.20, 1, 0.0),
        (146.83, 0.10, 2, 0.4),
        (174.61, 0.060, 1, 1.2),
        (220.00, 0.045, 2, 2.1),
        (293.66, 0.020, 3, 0.7),
    ]
    for freq, amp, lfo_cycles, phase in voices:
        f = aligned(freq, duration)
        lfo = 0.68 + 0.32 * np.cos(2.0 * math.pi * (lfo_cycles / duration) * t + phase)
        mix += amp * lfo * tone(f, t, phase)

    # A distant tide, breathing four times across the loop.
    wash = periodic_noise(n, 71, 90.0, 1500.0, 1.0)
    wash_env = 0.45 + 0.45 * np.cos(2.0 * math.pi * (4.0 / duration) * t - 0.8)
    mix += 0.030 * wash * wash_env

    # Four sparse bell notes, one every ten seconds.
    for index, freq in enumerate((293.66, 349.23, 440.00, 523.25)):
        place_at(mix, bell(freq, 6.0, 1.5, 0.045), index * 10.0)

    return mix


def game_ambience() -> np.ndarray:
    duration = 48.0
    n = int(duration * SR)
    t = np.arange(n, dtype=np.float64) / SR
    mix = np.zeros(n)

    # Deeper drone, with a slow pulse like something breathing under the floor.
    voices = [
        (36.71, 0.085, 1, 0.0),
        (73.42, 0.150, 2, 0.5),
        (110.00, 0.060, 1, 1.4),
        (146.83, 0.045, 2, 2.2),
        (174.61, 0.025, 3, 0.3),
    ]
    for freq, amp, lfo_cycles, phase in voices:
        f = aligned(freq, duration)
        lfo = 0.58 + 0.42 * np.cos(2.0 * math.pi * (lfo_cycles / duration) * t + phase)
        mix += amp * lfo * tone(f, t, phase)

    # Restless sea wash.
    wash = periodic_noise(n, 913, 60.0, 2600.0, 0.95)
    wash_env = 0.34 + 0.34 * np.cos(2.0 * math.pi * (4.0 / duration) * t - 0.4)
    wash_env += 0.14 * np.cos(2.0 * math.pi * (13.0 / duration) * t + 1.1)
    mix += 0.070 * wash * np.maximum(wash_env, 0.0)

    # A very quiet pulse every twelve seconds, like a heartbeat in the walls.
    for index in range(4):
        at = index * 12.0 + 2.0
        length = 2.2
        tt = t_axis(length)
        env = (1.0 - np.exp(-tt / 0.05)) * np.exp(-tt / 0.35)
        thump = 0.030 * tone(49.0, tt) * env
        place_at(mix, thump, at)

    return mix


# ------------------------------------------------------------------ effects
def sfx_click() -> np.ndarray:
    duration = 0.07
    t = t_axis(duration)
    env = np.exp(-t / 0.010)
    noise = np.random.default_rng(1).normal(size=t.size)
    return (0.62 * tone(1180.0, t) + 0.24 * tone(2360.0, t) + 0.18 * noise) * env


def sfx_dial() -> np.ndarray:
    duration = 0.11
    t = t_axis(duration)
    env = np.exp(-t / 0.016)
    noise = np.random.default_rng(2).normal(size=t.size)
    return (
        0.58 * tone(520.0, t)
        + 0.30 * tone(1040.0, t)
        + 0.16 * tone(1560.0, t)
        + 0.20 * noise * np.exp(-t / 0.005)
    ) * env


def sfx_pickup() -> np.ndarray:
    duration = 0.65
    out = np.zeros(int(duration * SR))
    place_at(out, bell(587.33, 0.55, 0.22, 0.55), 0.0)
    place_at(out, bell(880.00, 0.55, 0.25, 0.40), 0.09)
    return out


def sfx_place() -> np.ndarray:
    duration = 0.24
    t = t_axis(duration)
    freq = 70.0 + 120.0 * np.exp(-t / 0.045)
    phase = 2.0 * math.pi * np.cumsum(freq) / SR
    env = np.exp(-t / 0.085)
    noise = np.random.default_rng(3).normal(size=t.size)
    return (0.75 * np.sin(phase) + 0.20 * noise * np.exp(-t / 0.012)) * env


def sfx_page() -> np.ndarray:
    duration = 0.34
    t = t_axis(duration)
    noise = np.random.default_rng(4).normal(size=t.size)
    paper = bandpass(noise, 450.0, 5200.0)
    env = (
        0.9 * np.exp(-((t - 0.07) / 0.045) ** 2)
        + 0.6 * np.exp(-((t - 0.17) / 0.060) ** 2)
        + 0.35 * np.exp(-((t - 0.26) / 0.050) ** 2)
    )
    body = 0.10 * tone(180.0, t) * np.exp(-t / 0.08)
    return (0.55 * paper * env + body)


def sfx_unlock() -> np.ndarray:
    duration = 1.15
    out = np.zeros(int(duration * SR))
    place_at(out, sfx_dial() * 0.9, 0.00)
    place_at(out, sfx_dial() * 0.7, 0.11)
    place_at(out, bell(659.25, 0.85, 0.42, 0.38), 0.20)
    place_at(out, bell(987.77, 0.80, 0.38, 0.22), 0.23)
    return out


def sfx_summon() -> np.ndarray:
    duration = 2.4
    t = t_axis(duration)
    u = t / duration
    freq = 52.0 + 78.0 * u ** 1.6
    phase = 2.0 * math.pi * np.cumsum(freq) / SR
    env = np.sin(np.pi * np.clip(u, 0.0, 1.0)) ** 1.4
    voices = (
        0.48 * np.sin(phase)
        + 0.20 * np.sin(phase * 1.505 + 0.7)
        + 0.10 * np.sin(phase * 2.01 + 1.4)
    )
    noise = np.random.default_rng(5).normal(size=t.size)
    air = bandpass(noise, 300.0, 5200.0) * (0.20 + 0.30 * u)
    shimmer = 0.13 * tone(880.0, t) * (0.5 + 0.5 * np.sin(2.0 * math.pi * 1.7 * t))
    return (voices + air + shimmer) * env


def sfx_ending() -> np.ndarray:
    duration = 3.4
    t = t_axis(duration)
    u = t / duration
    freq = 62.0 - 28.0 * u
    phase = 2.0 * math.pi * np.cumsum(freq) / SR
    swell = np.sin(np.pi * np.clip(u * 1.1, 0.0, 1.0)) ** 1.2
    sub = 0.62 * np.sin(phase) * swell
    noise = np.random.default_rng(6).normal(size=t.size)
    wash = bandpass(noise, 80.0, 1800.0) * 0.18 * swell
    high = bell(783.99, 2.6, 1.2, 0.16)
    out = np.zeros(t.size)
    out += sub + wash
    place_at(out, high, 0.6)
    return out


def sfx_error() -> np.ndarray:
    duration = 0.38
    t = t_axis(duration)
    env = (1.0 - np.exp(-t / 0.01)) * np.exp(-t / 0.16)
    buzz = np.tanh(1.6 * (tone(92.0, t) + 0.6 * tone(138.0, t, 0.5)))
    return 0.45 * buzz * env


def sfx_dialog() -> np.ndarray:
    duration = 0.13
    t = t_axis(duration)
    env = (1.0 - np.exp(-t / 0.004)) * np.exp(-t / 0.035)
    return (0.35 * tone(460.0, t) + 0.16 * tone(690.0, t)) * env


def sfx_door() -> np.ndarray:
    duration = 1.05
    t = t_axis(duration)
    noise = np.random.default_rng(7).normal(size=t.size)
    creak = bandpass(noise, 220.0, 1900.0)
    wobble = 0.55 + 0.45 * np.sin(2.0 * math.pi * 7.5 * t + 0.4)
    env = (1.0 - np.exp(-t / 0.03)) * np.exp(-t / 0.55)
    low = 0.18 * tone(64.0, t) * np.exp(-t / 0.20)
    return 0.55 * creak * wobble * env + low


# ------------------------------------------------------------------ main
def main() -> None:
    write_wav("menu_theme.wav", menu_theme())
    write_wav("game_ambience.wav", game_ambience())
    write_wav("click.wav", sfx_click())
    write_wav("dial.wav", sfx_dial())
    write_wav("pickup.wav", sfx_pickup())
    write_wav("place.wav", sfx_place())
    write_wav("page.wav", sfx_page())
    write_wav("unlock.wav", sfx_unlock())
    write_wav("summon.wav", sfx_summon())
    write_wav("ending.wav", sfx_ending())
    write_wav("error.wav", sfx_error())
    write_wav("dialog.wav", sfx_dialog())
    write_wav("door.wav", sfx_door())


if __name__ == "__main__":
    main()
