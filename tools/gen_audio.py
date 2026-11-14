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


# ============================================================ more music
# Thirteen more loops in different moods. Each style is a small arranger that
# writes notes into buses (keys, bass, drums, lead, pad) which are then mixed.
QUALITIES = {
    "maj7": [0, 4, 7, 11], "m7": [0, 3, 7, 10], "7": [0, 4, 7, 10], "m9": [0, 3, 7, 10, 14],
    "maj9": [0, 4, 7, 11, 14], "6": [0, 4, 7, 9], "add9": [0, 4, 7, 14], "m": [0, 3, 7], "M": [0, 4, 7],
    "sus2": [0, 2, 7], "m6": [0, 3, 7, 9], "9": [0, 4, 7, 10, 14],
}
NOTE = {"C": 0, "C#": 1, "D": 2, "Eb": 3, "E": 4, "F": 5, "F#": 6, "G": 7, "Ab": 8, "A": 9, "Bb": 10, "B": 11}


def ch(name):
    """'Dm9' -> (bass note, [chord notes around middle C])."""
    root = name[:2] if len(name) > 1 and name[1] in "#b" else name[:1]
    quality = name[len(root):] or "M"
    base = 48 + NOTE[root]
    return base - 12, [base + i for i in QUALITIES[quality]]


def pad(freq, dur):
    n = int(dur * SR)
    t = np.arange(n) / SR
    x = sum(signal.sawtooth(2 * np.pi * freq * d * t + i) for i, d in enumerate((0.996, 1.0, 1.004))) / 3.0
    env = np.minimum(t / 0.9, 1.0) * np.minimum((dur - t) / 1.2, 1.0).clip(0)
    return butter(x, "lowpass", 900) * env


def piano(freq, dur, vel=1.0):
    n = int(dur * SR)
    t = np.arange(n) / SR
    x = np.zeros(n)
    for k in range(1, 7):
        x += np.sin(2 * np.pi * freq * k * np.sqrt(1 + 0.0004 * k * k) * t) * np.exp(-t * (1.1 + 0.7 * k)) / k ** 1.4
    return x * (1 - np.exp(-t * 400)) * vel


def musicbox(freq, dur):
    t = np.arange(int(dur * SR)) / SR
    return (np.sin(2 * np.pi * freq * t) * np.exp(-t * 3.0) + 0.4 * np.sin(2 * np.pi * freq * 4.0 * t) * np.exp(-t * 9.0)
            + 0.2 * np.sin(2 * np.pi * freq * 6.3 * t) * np.exp(-t * 15.0)) * (1 - np.exp(-t * 800))


def chip(freq, dur, duty=0.5, decay=5.0, vibrato=0.0):
    t = np.arange(int(dur * SR)) / SR
    phase = 2 * np.pi * freq * (t + vibrato * np.sin(2 * np.pi * 5.5 * t) / (2 * np.pi * 5.5))
    return signal.square(phase, duty) * np.exp(-t * decay) * (1 - np.exp(-t * 600))


def triangle(freq, dur, decay=3.0):
    t = np.arange(int(dur * SR)) / SR
    return signal.sawtooth(2 * np.pi * freq * t, 0.5) * np.exp(-t * decay) * (1 - np.exp(-t * 300))


def pluck(freq, dur, vel=1.0):
    t = np.arange(int(dur * SR)) / SR
    x = sum(np.sin(2 * np.pi * freq * k * t) * np.exp(-t * (2.0 + 1.6 * k)) / k for k in range(1, 9))
    return x * (1 - np.exp(-t * 900)) * vel


def sawbass(freq, dur):
    t = np.arange(int(dur * SR)) / SR
    x = signal.sawtooth(2 * np.pi * freq * t) + 0.5 * np.sin(2 * np.pi * freq * t)
    return butter(x, "lowpass", 420) * np.exp(-t * 6.0) * (1 - np.exp(-t * 300))


def ride(rng, accent=1.0):
    t = np.arange(int(0.35 * SR)) / SR
    return butter(noise(len(t), rng), "bandpass", [5500, 11000]) * np.exp(-t * 11) * accent


def shaker(rng):
    t = np.arange(int(0.07 * SR)) / SR
    return butter(noise(len(t), rng), "bandpass", [4000, 9000]) * np.sin(np.pi * t / 0.07) ** 2


def rim():
    t = np.arange(int(0.05 * SR)) / SR
    return (np.sin(2 * np.pi * 1700 * t) + 0.5 * np.sin(2 * np.pi * 2600 * t)) * np.exp(-t * 110)


def flute(freq, dur):
    t = np.arange(int(dur * SR)) / SR
    vib = 1 + 0.005 * np.sin(2 * np.pi * 5 * t) * np.minimum(t / 0.3, 1)
    env = np.minimum(t / 0.06, 1.0) * np.minimum((dur - t) / 0.12, 1.0).clip(0)
    return (np.sin(2 * np.pi * freq * vib * t) + 0.25 * np.sin(4 * np.pi * freq * vib * t)) * env


def reverb(x, n, rng, secs=1.1, decay=0.28):
    """Convolution reverb whose tail wraps round the loop point."""
    ir = noise(int(secs * SR), rng) * np.exp(-np.arange(int(secs * SR)) / (decay * SR))
    src = np.concatenate([x, np.zeros(len(ir))])
    wet = signal.fftconvolve(src, ir)[:len(src)]
    wet[:len(ir)] += wet[n:n + len(ir)]
    return norm(wet[:n], 1.0)


def loop_filter(x, kind, freq):
    """Filters a loop as if it had already been playing, so the seam stays continuous."""
    lead_in = min(len(x), SR)
    return butter(np.concatenate([x[-lead_in:], x]), kind, freq)[lead_in:]


def melody_notes(rng, key, chord_notes, beats, density=0.5, steps=(0.5, 1.0, 1.0, 1.5)):
    """Sparse pentatonic line that leans on chord tones: [(beat, midi note, length in beats)]."""
    pent = [72 + key + i for i in (0, 2, 4, 7, 9, 12)]
    out, pos = [], 0.0
    while pos < beats - 0.5:
        if rng.random() < density:
            note = int(rng.choice(chord_notes)) + 12 if rng.random() < 0.45 else int(rng.choice(pent))
            out.append((pos, note, float(rng.choice([1.0, 1.5, 2.0]))))
        pos += float(rng.choice(steps))
    return out


def song(name, seed, bpm, prog, style, key="C", bars_per_chord=1, reps=2):
    rng = np.random.default_rng(seed)
    beat = 60.0 / bpm
    chords = [ch(c) for c in prog]
    bars = len(chords) * bars_per_chord * reps
    n = int(bars * 4 * beat * SR)
    k = NOTE[key]
    bus = {b: np.zeros(n) for b in ("keys", "bass", "drums", "lead", "pad")}
    at = lambda beats: int(beats * beat * SR)
    swing = 0.0

    for bar in range(bars):
        ci = (bar // bars_per_chord) % len(chords)
        root, notes = chords[ci]
        nxt = chords[(ci + 1) % len(chords)][0]
        b0 = bar * 4
        first = bar % bars_per_chord == 0
        second_half = bar >= bars // 2

        if style == "ambient":
            if first:
                for nn in notes:
                    add(bus["pad"], pad(midi(nn), bars_per_chord * 4 * beat + 2.0) * 0.16, at(b0))
                add(bus["bass"], np.sin(2 * np.pi * midi(root) * np.arange(int(bars_per_chord * 4 * beat * SR)) / SR)
                    * np.hanning(int(bars_per_chord * 4 * beat * SR)) * 0.3, at(b0))
            for pos, nn, ln in melody_notes(rng, k, notes, 4, 0.4, (1.0, 1.5, 2.0)):
                add(bus["keys"], piano(midi(nn), 4.0, rng.uniform(0.5, 0.9)) * 0.22, at(b0 + pos))

        elif style == "piano":
            ladder = sorted(notes + [notes[0] + 12, notes[1] + 12])
            for i, idx in enumerate([0, 2, 1, 3, 2, 4, 3, 5] if len(ladder) > 5 else [0, 2, 1, 3, 2, 4, 3, 4]):
                add(bus["keys"], piano(midi(ladder[idx]), 2.2, (0.8 if i % 4 == 0 else 0.5) * rng.uniform(0.85, 1.0)) * 0.2,
                    at(b0 + i * 0.5) + int(rng.uniform(0, 0.012) * SR))
            add(bus["bass"], piano(midi(root), 3.5, 0.9) * 0.3, at(b0))
            if second_half or bar % 2 == 1:
                for pos, nn, ln in melody_notes(rng, k, notes, 4, 0.5, (1.0, 1.0, 2.0)):
                    add(bus["lead"], piano(midi(nn), 3.0, 0.9) * 0.24, at(b0 + pos))

        elif style == "musicbox":
            ladder = sorted(notes + [notes[0] + 12])
            for i in range(8):
                add(bus["keys"], musicbox(midi(ladder[(i * 2) % len(ladder)] + 12), 1.5) * 0.12, at(b0 + i * 0.5))
            add(bus["bass"], musicbox(midi(root + 12), 3.0) * 0.2, at(b0))
            for pos, nn, ln in melody_notes(rng, k, notes, 4, 0.7, (1.0, 1.0, 0.5, 2.0)):
                add(bus["lead"], musicbox(midi(nn + 12), 2.5) * 0.2, at(b0 + pos))

        elif style == "chip":
            for i in range(16):
                add(bus["keys"], chip(midi(notes[i % len(notes)] + (12 if (i // len(notes)) % 2 else 0)), 0.2, 0.25, 14) * 0.07, at(b0 + i * 0.25))
            for i, nn in enumerate([root, root + 12, root + 7, root + 12]):
                add(bus["bass"], triangle(midi(nn), beat * 0.9) * 0.3, at(b0 + i))
            for i in range(8):
                add(bus["drums"], hat(rng) * (0.10 if i % 2 else 0.06), at(b0 + i * 0.5))
            for i in (0, 2):
                add(bus["drums"], kick() * 0.28, at(b0 + i))
            add(bus["drums"], snare(rng) * 0.22, at(b0 + 1)); add(bus["drums"], snare(rng) * 0.22, at(b0 + 3))
            if second_half or bar % 4 >= 2:
                for pos, nn, ln in melody_notes(rng, k, notes, 4, 0.65, (0.5, 0.5, 1.0, 1.0)):
                    add(bus["lead"], chip(midi(nn), ln * beat, 0.5, 2.5, 0.004) * 0.09, at(b0 + pos))

        elif style == "jazz":
            swing = beat * 0.17
            for i in range(4):
                add(bus["drums"], ride(rng, 1.0 if i % 2 == 0 else 0.7) * 0.2, at(b0 + i))
                if i % 2 == 1 or rng.random() < 0.35:
                    add(bus["drums"], ride(rng, 0.5) * 0.14, at(b0 + i + 0.5) + int(swing * SR))
                if i in (1, 3):
                    add(bus["drums"], hat(rng) * 0.16, at(b0 + i))
            if rng.random() < 0.5:
                add(bus["drums"], snare(rng) * 0.12, at(b0 + float(rng.choice([1.5, 2.5, 3.5]))) + int(swing * SR))
            walk = [root, root + int(rng.choice([3, 4, 7])), root + 7, nxt + int(rng.choice([-1, 1, 2]))]
            for i, nn in enumerate(walk):
                add(bus["bass"], bass(midi(nn), beat * 0.95) * 0.5, at(b0 + i))
            for hit in ([0.0, 1.5] if bar % 2 == 0 else [0.5, 2.5]):
                for j, nn in enumerate(notes):
                    add(bus["keys"], epiano(midi(nn), beat * 1.6, rng.uniform(0.6, 0.9)) * 0.17, at(b0 + hit) + int((swing if hit % 1 else 0) * SR) + j * 400)
            if second_half or bar % 4 == 3:
                for pos, nn, ln in melody_notes(rng, k, notes, 4, 0.55, (0.5, 1.0, 1.0, 1.5)):
                    add(bus["lead"], epiano(midi(nn), ln * beat * 1.2, 0.9) * 0.24, at(b0 + pos) + int((swing if pos % 1 else 0) * SR))

        elif style == "synth":
            if first:
                for nn in notes:
                    add(bus["pad"], pad(midi(nn + 12), bars_per_chord * 4 * beat + 1.0) * 0.12, at(b0))
            for i in range(8):
                add(bus["bass"], sawbass(midi(root), beat * 0.45) * (0.5 if i % 2 == 0 else 0.35), at(b0 + i * 0.5))
            for i in range(4):
                add(bus["drums"], kick() * 0.7, at(b0 + i))
                if i in (1, 3):
                    add(bus["lead"], snare(rng) * 0.3, at(b0 + i))      # snare goes through the reverb
            for i in range(16):
                add(bus["drums"], hat(rng) * (0.07 if i % 4 == 2 else 0.035), at(b0 + i * 0.25))
            if second_half or bar % 4 >= 2:
                for pos, nn, ln in melody_notes(rng, k, notes, 4, 0.45, (1.0, 1.5, 2.0)):
                    tone = lead(midi(nn), ln * beat * 1.5) * 0.2
                    add(bus["lead"], tone, at(b0 + pos))
                    add(bus["lead"], tone * 0.4, at(b0 + pos + 0.75))       # dotted-eighth echo

        elif style == "bossa":
            pattern = [0.0, 1.5, 3.0] if bar % 2 == 0 else [0.5, 2.0, 3.5]
            for hit in pattern:
                for j, nn in enumerate(notes):
                    add(bus["keys"], pluck(midi(nn), 1.4, rng.uniform(0.6, 0.9)) * 0.14, at(b0 + hit) + j * 500)
                add(bus["drums"], rim() * 0.16, at(b0 + hit))
            for pos, nn in ((0.0, root), (1.5, root), (2.0, root + 7), (3.5, root + 7)):
                add(bus["bass"], bass(midi(nn), beat * 0.9) * 0.45, at(b0 + pos))
            for i in range(8):
                add(bus["drums"], shaker(rng) * (0.11 if i % 2 == 0 else 0.07), at(b0 + i * 0.5))
            if second_half or bar % 4 >= 2:
                for pos, nn, ln in melody_notes(rng, k, notes, 4, 0.55, (0.5, 1.0, 1.5)):
                    add(bus["lead"], flute(midi(nn), ln * beat) * 0.13, at(b0 + pos))

    mix_spec = {  # reverb send, reverb length, master lowpass, tape wobble, hiss
        "ambient": (0.30, 2.4, 5000, 0.0010, 0.004), "piano": (0.22, 1.8, 6000, 0.0012, 0.004),
        "musicbox": (0.25, 1.6, 7000, 0.0016, 0.006), "chip": (0.10, 0.8, 4500, 0.0, 0.0),
        "jazz": (0.14, 1.0, 6500, 0.0010, 0.006), "synth": (0.22, 1.6, 7500, 0.0, 0.0),
        "bossa": (0.14, 1.0, 7000, 0.0008, 0.004),
    }
    send, length, cutoff, wobble, hiss_level = mix_spec[style]
    bus["bass"] = loop_filter(bus["bass"], "lowpass", 500)
    bass_gain = {"ambient": 0.5, "chip": 0.5, "jazz": 0.55, "bossa": 0.55, "synth": 0.7}.get(style, 0.9)
    dry = bus["keys"] + bus["lead"] + bus["pad"] + bus["bass"] * bass_gain + bus["drums"] * 0.8
    wet = reverb(bus["keys"] + bus["lead"] * 1.2 + bus["pad"] * 0.6, n, rng, length, length * 0.25) * send
    hiss = loop_filter(noise(n, rng), "bandpass", [1500, 8000]) * hiss_level
    lch = loop_filter(dry + wet + hiss, "lowpass", cutoff)
    rch = loop_filter(dry + np.roll(wet, int(0.017 * SR)) + np.roll(hiss, 999), "lowpass", cutoff)
    if wobble:
        src = np.cumsum(1 + wobble * np.sin(2 * np.pi * np.arange(n) / n * 3))
        src = src / src[-1] * (n - 1)
        lch, rch = np.interp(src, np.arange(n), lch), np.interp(src, np.arange(n), rch)
    write_ogg(name, norm(np.tanh(stereo(lch, rch) * 1.4), 0.85), q=5)
    print("%-28s %-9s %5.1fs" % (name, style, n / SR))


def more_music(lofi_too=True):
    pent = [0, 2, 4, 7, 9]
    lofi = lambda prog: [ch(c) for c in prog]
    if lofi_too:
        track(51, 78, lofi(["Fmaj7", "Em7", "Am9", "G6"]), pent, "music_window_seat")
        track(63, 70, lofi(["Dm9", "Bbmaj7", "Fmaj9", "C6"]), [5, 7, 9, 12, 14], "music_cocoa_steam")
        track(77, 86, lofi(["Am9", "Dm9", "G9", "Cmaj9"]), pent, "music_night_bus")
    song("music_moonlit_dust", 101, 60, ["Cmaj9", "Am9", "Fmaj9", "Gsus2"], "ambient", "C", bars_per_chord=2, reps=1)
    song("music_before_sunrise", 113, 56, ["Dm9", "Bbmaj9", "Fadd9", "C6"], "ambient", "F", bars_per_chord=2, reps=1)
    song("music_paper_planes", 127, 66, ["Cadd9", "Am7", "Fmaj7", "G6"], "piano", "C")
    song("music_letters_unsent", 131, 60, ["Am9", "Fmaj7", "Cmaj7", "Em7"], "piano", "C")
    song("music_sleepy_miso", 149, 72, ["F", "Dm", "Bb", "C"], "musicbox", "F")
    song("music_pixel_lullaby", 157, 88, ["Cmaj7", "Am7", "Fmaj7", "G"], "chip", "C")
    song("music_save_point", 163, 96, ["Am", "F", "C", "G"], "chip", "C")
    song("music_rooftop_jazz", 173, 104, ["Dm9", "G9", "Cmaj9", "A7"], "jazz", "C")
    song("music_neon_rain", 181, 84, ["Am9", "Fmaj9", "Cmaj9", "G6"], "synth", "C", bars_per_chord=2, reps=1)
    song("music_sunday_bossa", 191, 108, ["Fmaj7", "Gm7", "Am7", "Bbmaj7"], "bossa", "F")


if __name__ == "__main__":
    import sys
    rng = np.random.default_rng(4042)
    if "more" not in sys.argv:              # `python3 tools/gen_audio.py more` skips the original set
        for name, fn in (("amb_rain", rain), ("amb_fire", fire), ("amb_wind", wind), ("amb_vinyl", vinyl),
                         ("amb_city", city), ("amb_crickets", crickets), ("amb_brown", brown_loop)):
            write_ogg(name, fn(rng))
            print(name)
        music()
        oneshots(rng)
    more_music("songs" not in sys.argv)
