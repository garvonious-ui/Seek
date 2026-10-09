#!/usr/bin/env python3
# Ambient bed: soft detuned pads on C-G-Am-F, sparse music-box melody, light reverb.
# Original synthesis -> no licensing issues (shows as "Original audio").
import numpy as np, wave, sys

SR = 44100
DUR = 21.0
n = int(SR * DUR)
t = np.arange(n) / SR

def note(freq, t0, dur, amp=0.2, detune=0.004, partials=(1, 2, 3)):
    """Soft detuned pad voice with slow attack/release."""
    seg = np.zeros(n)
    i0, i1 = int(t0 * SR), int((t0 + dur) * SR)
    i1 = min(i1, n)
    if i1 <= i0:
        return seg
    L = i1 - i0
    lt = np.arange(L) / SR
    env = np.ones(L)
    a = int(0.6 * SR); r = int(1.2 * SR)
    a = min(a, L // 2); r = min(r, L // 2)
    if a > 0: env[:a] = np.linspace(0, 1, a) ** 2
    if r > 0: env[-r:] = np.linspace(1, 0, r) ** 2
    wave_ = np.zeros(L)
    for k, p in enumerate(partials):
        for d in (-detune, detune):
            wave_ += np.sin(2 * np.pi * freq * p * (1 + d) * lt) / (p * 1.7)
    # gentle vibrato
    wave_ *= 1 + 0.015 * np.sin(2 * np.pi * 0.2 * lt)
    seg[i0:i1] = amp * env * wave_
    return seg

def bell(freq, t0, amp=0.12):
    """Sparse music-box / bell pluck."""
    seg = np.zeros(n)
    i0 = int(t0 * SR)
    L = int(2.2 * SR)
    i1 = min(i0 + L, n)
    if i1 <= i0: return seg
    L = i1 - i0
    lt = np.arange(L) / SR
    env = np.exp(-lt * 2.6)
    w = (np.sin(2 * np.pi * freq * lt)
         + 0.5 * np.sin(2 * np.pi * freq * 2 * lt)
         + 0.25 * np.sin(2 * np.pi * freq * 3.01 * lt))
    seg[i0:i1] = amp * env * w
    return seg

NOTE = {'C3':130.81,'E3':164.81,'G3':196.00,'A3':220.00,'C4':261.63,'D4':293.66,
        'E4':329.63,'G4':392.00,'A4':440.00,'C5':523.25,'E5':659.25,'G5':783.99}

mix = np.zeros(n)
# Pad progression C - G - Am - F, 4.5s each (two bars over 18s)
chords = [
    (0.0,  ['C3','E3','G4','C5']),
    (4.5,  ['G3','D4','G4','A4']),
    (9.0,  ['A3','C4','E4','A4']),
    (13.5, ['C4','E4','G4','C5']),  # resolve back toward C/F warmth
    (18.0, ['C3','G3','C4','E4']),  # gentle tail so longer reels stay scored
]
for t0, names in chords:
    for nm in names:
        mix += note(NOTE[nm], t0, 5.2, amp=0.16)

# Sparse music-box melody floating above
melody = [(1.5,'E5'),(3.0,'G5'),(5.6,'D4'),(7.4,'G4'),(10.2,'E5'),(12.0,'C5'),(14.4,'G5'),(16.0,'E5')]
for t0, nm in melody:
    f = NOTE.get(nm, NOTE['E5'])
    mix += bell(f, t0)

# Light reverb: a few decaying delay taps
rev = np.zeros(n)
for delay, g in [(0.07, 0.35), (0.13, 0.25), (0.21, 0.18), (0.33, 0.12)]:
    d = int(delay * SR)
    rev[d:] += g * mix[:n - d]
out = mix + 0.5 * rev

# soft master: normalize, gentle tanh, fades
out = out / (np.max(np.abs(out)) + 1e-9)
out = np.tanh(out * 1.1) * 0.82
fi = int(0.8 * SR); fo = int(1.5 * SR)
out[:fi] *= np.linspace(0, 1, fi)
out[-fo:] *= np.linspace(1, 0, fo)

stereo = np.stack([out, np.concatenate([[0,0], out[:-2]])], axis=1)  # tiny width
stereo = (stereo / (np.max(np.abs(stereo)) + 1e-9) * 0.9 * 32767).astype('<i2')

with wave.open('bed.wav', 'wb') as w:
    w.setnchannels(2); w.setsampwidth(2); w.setframerate(SR)
    w.writeframes(stereo.tobytes())
print('wrote bed.wav', round(DUR,1), 's')
