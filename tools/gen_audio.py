#!/usr/bin/env python3
"""Synthesizes every sound in Midnighty Room: ambience loops, three lofi music
loops and the UI one-shots. Nothing is sampled, so there are no licences to clear.

Run from the project root:  python3 tools/gen_audio.py   (needs numpy, scipy, ffmpeg)
Output: assets/audio/*.ogg (loops) and *.wav (one-shots).
Swap any file for a recorded one with the same name and the game uses it.
"""
import os
import subprocess
import wave
import numpy as np
from scipy import signal

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "audio")
os.makedirs(OUT, exist_ok=True)
SR = 44100


def noise(n, rng):
    return rng.standard_normal(n)


def butter(x, kind, freq, order=2):
    sos = signal.butter(order, freq, btype=kind, fs=SR, output="sos")
    return signal.sosfilt(sos, x, axis=0)


def brown(n, rng):
    x = np.cumsum(noise(n, rng))
    x = butter(x, "highpass", 20)
    return x / np.max(np.abs(x))


def loopify(x, fade=1.0):
    """Crossfades the tail into the head so the clip loops without a click."""
    f = int(fade * SR)
    body = x[:-f].copy()
    ramp = np.linspace(0, 1, f)
    if x.ndim == 2:
        ramp = ramp[:, None]
    body[:f] = body[:f] * ramp + x[-f:] * (1 - ramp)
    return body


def norm(x, peak=0.8):
    return x / (np.max(np.abs(x)) + 1e-9) * peak


def write_wav(path, x):
    x = np.clip(x, -1, 1)
    data = (x * 32767).astype("<i2")
    with wave.open(path, "wb") as w:
        w.setnchannels(1 if x.ndim == 1 else 2)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(data.tobytes())


def write_ogg(name, x, q=4):
    tmp = os.path.join(OUT, name + ".tmp.wav")
    write_wav(tmp, x)
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", tmp, "-c:a", "libvorbis", "-q:a", str(q),
                    os.path.join(OUT, name + ".ogg")], check=True)
    os.remove(tmp)


def stereo(l, r):
    return np.stack([l, r], axis=1)


# ------------------------------------------------------------------ ambience
def rain(rng, secs=22):
    n = SR * secs
    out = []
    for ch in range(2):
        hiss = butter(butter(noise(n, rng), "highpass", 900), "lowpass", 7500)
        body = butter(noise(n, rng), "bandpass", [250, 1200]) * 0.5
        lfo = 0.85 + 0.15 * np.sin(2 * np.pi * (0.07 + 0.02 * ch) * np.arange(n) / SR + ch)
        drops = np.zeros(n)
        for t in rng.integers(0, n - 2000, 900):
            ln = rng.integers(200, 900)
            drops[t:t + ln] += noise(ln, rng) * np.exp(-np.arange(ln) / (ln / 5.0)) * rng.uniform(0.2, 1.0)
        drops = butter(drops, "bandpass", [1500, 6000]) * 0.6
        out.append((hiss + body) * lfo + drops)
    return loopify(norm(stereo(*out), 0.7), 2.0)


def fire(rng, secs=20):
    n = SR * secs
    out = []
    for ch in range(2):
        rumble = butter(brown(n, rng), "lowpass", 350) * 0.7
        flutter = butter(noise(n, rng), "bandpass", [300, 1500]) * 0.12 * (0.6 + 0.4 * np.sin(2 * np.pi * 3.1 * np.arange(n) / SR + ch))
        crack = np.zeros(n)
        for t in rng.integers(0, n - 3000, 260):
            ln = rng.integers(40, 500)
            crack[t:t + ln] += noise(ln, rng) * np.exp(-np.arange(ln) / (ln / 6.0)) * rng.uniform(0.1, 1.0) ** 2
        crack = butter(crack, "highpass", 1200) * 1.6
        out.append(rumble + flutter + crack)
    return loopify(norm(stereo(*out), 0.75), 1.5)


def wind(rng, secs=24):
    n = SR * secs
    t = np.arange(n) / SR
    out = []
    for ch in range(2):
        x = np.zeros(n)
        for i, (lo, hi) in enumerate([(120, 400), (300, 800), (600, 1500)]):
            lfo = 0.5 + 0.5 * np.sin(2 * np.pi * (0.05 + 0.03 * i) * t + i * 2.1 + ch * 0.8)
            x += butter(noise(n, rng), "bandpass", [lo, hi]) * lfo ** 2 * (1.0 - 0.25 * i)
        out.append(x)
    return loopify(norm(stereo(*out), 0.7), 3.0)


def vinyl(rng, secs=18):
    n = SR * secs
    hiss = butter(noise(n, rng), "bandpass", [2000, 9000]) * 0.08
    hum = np.sin(2 * np.pi * 50 * np.arange(n) / SR) * 0.01
    clicks = np.zeros(n)
    for t in rng.integers(0, n - 200, 420):
        ln = rng.integers(4, 60)
        clicks[t:t + ln] += noise(ln, rng) * np.exp(-np.arange(ln) / (ln / 4.0)) * rng.uniform(0.1, 1.0) ** 3
    x = hiss + hum + butter(clicks, "highpass", 800) * 0.9
    return loopify(norm(x, 0.6), 1.0)


def city(rng, secs=26):
    n = SR * secs
    t = np.arange(n) / SR
    out = []
    for ch in range(2):
        rumble = butter(brown(n, rng), "lowpass", 180) * 0.8
        air = butter(noise(n, rng), "bandpass", [200, 900]) * 0.06
        cars = np.zeros(n)
        for c in rng.uniform(1, secs - 7, 7):
            env = np.exp(-((t - c - 3) ** 2) / rng.uniform(1.5, 4.0))
            pan = 0.5 + 0.5 * np.tanh((t - c - 3) * (1 if ch else -1) * 0.6)
            cars += butter(noise(n, rng), "bandpass", [150, rng.uniform(700, 1400)]) * env * pan * 0.35
        out.append(rumble + air + cars)
    return loopify(norm(stereo(*out), 0.7), 3.0)


def crickets(rng, secs=20):
    n = SR * secs
    t = np.arange(n) / SR
    out = []
    for ch in range(2):
        x = np.zeros(n)
        for k in range(5):
            f = rng.uniform(3800, 5200)
            rate = rng.uniform(2.2, 3.6)
            phase = rng.uniform(0, 1)
            gate = ((t * rate + phase) % 1.0) < 0.45
            trill = 0.5 + 0.5 * np.sign(np.sin(2 * np.pi * rng.uniform(28, 40) * t))
            swell = 0.5 + 0.5 * np.sin(2 * np.pi * rng.uniform(0.03, 0.09) * t + k)
            x += np.sin(2 * np.pi * f * t) * gate * trill * swell * rng.uniform(0.3, 1.0)
        x = butter(x, "lowpass", 7000) + butter(noise(n, rng), "bandpass", [300, 1500]) * 0.03
        out.append(x)
    return loopify(norm(stereo(*out), 0.45), 2.0)


def brown_loop(rng, secs=20):
    n = SR * secs
    x = stereo(butter(brown(n, rng), "lowpass", 900), butter(brown(n, rng), "lowpass", 900))
    return loopify(norm(x, 0.7), 2.0)


# --------------------------------------------------------------------- music
def midi(n):
    return 440.0 * 2 ** ((n - 69) / 12.0)


def epiano(freq, dur, vel=1.0):
    n = int(dur * SR)
    t = np.arange(n) / SR
    env = np.exp(-t * 2.2) * (1 - np.exp(-t * 300))
    trem = 1 + 0.12 * np.sin(2 * np.pi * 4.3 * t)
    mod = np.sin(2 * np.pi * freq * 2 * t) * np.exp(-t * 6) * 1.4          # FM bell bite
    x = np.sin(2 * np.pi * freq * t + mod) + 0.3 * np.sin(2 * np.pi * freq * 2.001 * t) * np.exp(-t * 4)
    return x * env * trem * vel


def bass(freq, dur):
    n = int(dur * SR)
    t = np.arange(n) / SR
    env = np.exp(-t * 2.5) * (1 - np.exp(-t * 200))
    return np.tanh(np.sin(2 * np.pi * freq * t) * 1.8) * env


def kick():
    t = np.arange(int(0.32 * SR)) / SR
    f = 45 + 90 * np.exp(-t * 28)
    return np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t * 11)


def snare(rng):
    n = int(0.22 * SR)
    t = np.arange(n) / SR
    body = np.sin(2 * np.pi * 185 * t) * np.exp(-t * 22) * 0.5
    return body + butter(noise(n, rng), "bandpass", [900, 5000]) * np.exp(-t * 20)


def hat(rng, open_=False):
    n = int((0.16 if open_ else 0.05) * SR)
    t = np.arange(n) / SR
    return butter(noise(n, rng), "highpass", 6500) * np.exp(-t * (18 if open_ else 70))


def lead(freq, dur):
    n = int(dur * SR)
    t = np.arange(n) / SR
    vib = 1 + 0.004 * np.sin(2 * np.pi * 5 * t)
    env = np.exp(-t * 1.6) * (1 - np.exp(-t * 60))
    return (np.sin(2 * np.pi * freq * vib * t) + 0.2 * signal.sawtooth(2 * np.pi * freq * t, 0.5)) * env


def add(buf, x, at):
    """Adds x at sample `at`, wrapping around the loop end so tails stay seamless."""
    n = len(buf)
    idx = (at + np.arange(len(x))) % n
    np.add.at(buf, idx, x)


def track(seed, bpm, chords, scale, name):
    rng = np.random.default_rng(seed)
    beat = 60.0 / bpm
    bars = len(chords) * 2
    n = int(bars * 4 * beat * SR)
    keys, low, drums, mel = np.zeros(n), np.zeros(n), np.zeros(n), np.zeros(n)
    swing = 0.14 * beat
    for rep in range(2):
        for ci, (root, notes) in enumerate(chords):
            bar = rep * len(chords) + ci
            t0 = bar * 4 * beat
            for hit, vel in ((0, 1.0), (2.5, 0.6)):
                for j, nn in enumerate(notes):
                    add(keys, epiano(midi(nn), beat * 3.5, vel * rng.uniform(0.8, 1.0)) * 0.22,
                        int((t0 + hit * beat + j * 0.018 + rng.uniform(0, 0.012)) * SR))
            add(low, bass(midi(root), beat * 1.8) * 0.5, int(t0 * SR))
            add(low, bass(midi(root), beat * 0.9) * 0.4, int((t0 + 2.5 * beat) * SR))
            if rng.random() < 0.5:
                add(low, bass(midi(root + 7), beat * 0.6) * 0.3, int((t0 + 3.5 * beat) * SR))
            for b in range(4):
                tb = t0 + b * beat
                if b in (0, 2):
                    add(drums, kick() * 0.9, int(tb * SR))
                if b == 2 and rng.random() < 0.4:
                    add(drums, kick() * 0.5, int((tb + 0.5 * beat + swing) * SR))
                if b in (1, 3):
                    add(drums, snare(rng) * 0.45, int((tb + rng.uniform(0.004, 0.02)) * SR))
                add(drums, hat(rng) * 0.16 * rng.uniform(0.6, 1.0), int(tb * SR))
                add(drums, hat(rng, rng.random() < 0.12) * 0.11 * rng.uniform(0.5, 1.0), int((tb + 0.5 * beat + swing) * SR))
            if rep == 1 or ci % 2 == 1:                                        # sparse melody
                pos = 0.0
                while pos < 3.5:
                    if rng.random() < 0.55:
                        nn = notes[-1] + 12 + rng.choice(scale) - scale[0] if rng.random() < 0.3 else 72 + rng.choice(scale)
                        add(mel, lead(midi(nn), beat * rng.choice([1.0, 1.5, 2.0])) * 0.16, int((t0 + pos * beat + (swing if pos % 1 else 0)) * SR))
                    pos += rng.choice([0.5, 1.0, 1.0, 1.5])
    duck = np.ones(n)                                                           # sidechain pump
    k = np.exp(-np.arange(int(0.3 * SR)) / (0.09 * SR))
    for bar in range(bars):
        for b in (0, 2):
            add(duck, -0.35 * k, int((bar * 4 + b) * beat * SR))
    keys = butter(keys, "lowpass", 2600) * duck
    mel = butter(mel, "lowpass", 3200) * duck
    drums = butter(drums, "lowpass", 6500)
    low = butter(low, "lowpass", 400)
    ir = noise(int(1.1 * SR), rng) * np.exp(-np.arange(int(1.1 * SR)) / (0.28 * SR))
    wet_src = np.concatenate([keys + mel * 1.3, np.zeros(len(ir))])
    wet = signal.fftconvolve(wet_src, ir)[:len(wet_src)]
    wet[:len(ir)] += wet[n:n + len(ir)]                                         # wrap the tail
    wet = norm(wet[:n], 1.0) * 0.12
    wet2 = np.roll(wet, int(0.013 * SR))
    hiss = butter(noise(n, rng), "bandpass", [1500, 8000]) * 0.006
    dry = keys + mel + low * 0.9 + drums * 0.8
    lch, rch = dry + wet + hiss, dry + wet2 + np.roll(hiss, 999)
    wob = 1 + 0.0016 * np.sin(2 * np.pi * np.arange(n) / n * 3)                 # tape wobble, whole cycles
    src = np.cumsum(wob)
    src = src / src[-1] * (n - 1)
    lch, rch = np.interp(src, np.arange(n), lch), np.interp(src, np.arange(n), rch)
    mix = np.tanh(stereo(lch, rch) * 1.5)
    write_ogg(name, norm(mix, 0.85), q=5)
    return n / SR


def music():
    pent_c = [0, 2, 4, 7, 9]
    a = [(38, [53, 57, 60, 64]), (43, [53, 59, 62, 64]), (36, [52, 55, 59, 62]), (45, [52, 55, 61, 64])]
    b = [(41, [57, 60, 64, 67]), (40, [55, 59, 62, 66]), (38, [53, 57, 60, 65]), (36, [52, 55, 59, 64])]
    c = [(45, [55, 59, 60, 64]), (41, [57, 60, 64, 67]), (36, [55, 59, 62, 64]), (43, [53, 57, 59, 64])]
    print("midnight_tea %.1fs" % track(11, 74, a, pent_c, "music_midnight_tea"))
    print("paper_lanterns %.1fs" % track(23, 82, b, pent_c, "music_paper_lanterns"))
    print("slow_rain %.1fs" % track(37, 68, c, [0, 2, 4, 7, 9], "music_slow_rain"))


# ----------------------------------------------------------------- one-shots
def oneshots(rng):
    t = np.arange(int(1.6 * SR)) / SR
    chime = sum(np.sin(2 * np.pi * f * t) * np.exp(-(t - d).clip(0) * 3.5) * (t >= d) for f, d in ((784, 0), (988, 0.16), (1175, 0.32), (1568, 0.5)))
    write_wav(os.path.join(OUT, "chime.wav"), norm(chime, 0.5))
    t = np.arange(int(0.05 * SR)) / SR
    write_wav(os.path.join(OUT, "click.wav"), norm(np.sin(2 * np.pi * 900 * t) * np.exp(-t * 90), 0.3))
    t = np.arange(int(0.12 * SR)) / SR
    write_wav(os.path.join(OUT, "place.wav"), norm(np.sin(2 * np.pi * (220 + 300 * np.exp(-t * 40)) * t) * np.exp(-t * 30), 0.45))
    t = np.arange(int(0.25 * SR)) / SR
    coin = (np.sin(2 * np.pi * 1318 * t) * (t < 0.07) + np.sin(2 * np.pi * 1760 * t) * (t >= 0.07)) * np.exp(-t * 12)
    write_wav(os.path.join(OUT, "coin.wav"), norm(coin, 0.35))
    t = np.arange(int(1.8 * SR)) / SR
    purr = butter(noise(len(t), rng), "lowpass", 220) * (0.5 + 0.5 * np.sign(np.sin(2 * np.pi * 24 * t))) * np.sin(np.pi * t / 1.8) ** 0.7
    write_wav(os.path.join(OUT, "purr.wav"), norm(purr, 0.7))
    t = np.arange(int(0.08 * SR)) / SR
    write_wav(os.path.join(OUT, "switch.wav"), norm(butter(noise(len(t), rng), "bandpass", [1500, 4000]) * np.exp(-t * 80), 0.35))


if __name__ == "__main__":
    rng = np.random.default_rng(4042)
    for name, fn in (("amb_rain", rain), ("amb_fire", fire), ("amb_wind", wind), ("amb_vinyl", vinyl),
                     ("amb_city", city), ("amb_crickets", crickets), ("amb_brown", brown_loop)):
        write_ogg(name, fn(rng))
        print(name)
    music()
    oneshots(rng)
