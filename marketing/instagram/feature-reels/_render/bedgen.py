#!/usr/bin/env python3
# Generate several distinct ambient beds (same calm/reverent family, different
# key + progression + register) so scheduled posts don't all share one song.
# Original synthesis -> "Original audio", no licensing. Outraw: bed_<name>.wav
import numpy as np, wave

SR = 44100
DUR = 16.0
n = int(SR * DUR)

NOTE = {
 'C3':130.81,'C#3':138.59,'D3':146.83,'D#3':155.56,'E3':164.81,'F3':174.61,'F#3':185.00,
 'G3':196.00,'G#3':207.65,'A3':220.00,'A#3':233.08,'B3':246.94,
 'C4':261.63,'C#4':277.18,'D4':293.66,'D#4':311.13,'E4':329.63,'F4':349.23,'F#4':369.99,
 'G4':392.00,'G#4':415.30,'A4':440.00,'A#4':466.16,'B4':493.88,
 'C5':523.25,'C#5':554.37,'D5':587.33,'E5':659.25,'F5':698.46,'G5':783.99,'A5':880.00,'B5':987.77,
}

def pad(freq, t0, dur, amp, detune=0.004):
    seg = np.zeros(n); i0, i1 = int(t0*SR), min(int((t0+dur)*SR), n)
    if i1 <= i0: return seg
    L = i1-i0; lt = np.arange(L)/SR; env = np.ones(L)
    a = min(int(0.6*SR), L//2); r = min(int(1.2*SR), L//2)
    if a>0: env[:a] = np.linspace(0,1,a)**2
    if r>0: env[-r:] = np.linspace(1,0,r)**2
    w = np.zeros(L)
    for p in (1,2,3):
        for d in (-detune, detune):
            w += np.sin(2*np.pi*freq*p*(1+d)*lt)/(p*1.7)
    w *= 1 + 0.015*np.sin(2*np.pi*0.2*lt)
    seg[i0:i1] = amp*env*w
    return seg

def bell(freq, t0, amp=0.11):
    seg = np.zeros(n); i0 = int(t0*SR); i1 = min(i0+int(2.2*SR), n)
    if i1 <= i0: return seg
    L = i1-i0; lt = np.arange(L)/SR; env = np.exp(-lt*2.6)
    w = np.sin(2*np.pi*freq*lt) + 0.5*np.sin(2*np.pi*freq*2*lt) + 0.25*np.sin(2*np.pi*freq*3.01*lt)
    seg[i0:i1] = amp*env*w
    return seg

# presets: 4 chords (note-name lists) + a sparse melody (note names)
PRESETS = {
 'warm':    {'chords': [['C3','E3','G4','C5'], ['G3','D4','G4','B4'], ['A3','C4','E4','A4'], ['F3','A3','C4','F4']],
             'mel': ['E5','G5','D5','G4','E5','C5']},
 'tender':  {'chords': [['A3','C4','E4','A4'], ['F3','A3','C4','F4'], ['C4','E4','G4','C5'], ['G3','B3','D4','G4']],
             'mel': ['A4','C5','E5','C5','A4','G4']},
 'hopeful': {'chords': [['D3','F#3','A4','D5'], ['A3','E4','A4','C#5'], ['B3','D4','F#4','B4'], ['G3','B3','D4','G4']],
             'mel': ['F#5' if False else 'D5','A4','D5','F#4','A4','D5']},
 'still':   {'chords': [['F3','A3','C4','F4'], ['D3','F3','A3','D4'], ['A#3','D4','F4','A#4'], ['C4','E4','G4','C5']],
             'mel': ['C5','F5','A4','C5','F4','A4']},
 'vespers': {'chords': [['E3','G3','B3','E4'], ['C3','E3','G3','C4'], ['G3','B3','D4','G4'], ['D3','F#3','A3','D4']],
             'mel': ['B4','E5','G4','B4','E5','D5']},
}

CH_T = [0.0, 4.0, 8.0, 12.0]
MEL_T = [1.5, 3.6, 6.0, 8.6, 11.0, 13.6]

def render(preset):
    mix = np.zeros(n)
    for t0, chord in zip(CH_T, preset['chords']):
        for nm in chord:
            mix += pad(NOTE[nm], t0, 4.8, amp=0.16)
    for t0, nm in zip(MEL_T, preset['mel']):
        mix += bell(NOTE.get(nm, NOTE['E5']), t0)
    rev = np.zeros(n)
    for delay, g in [(0.07,0.35),(0.13,0.25),(0.21,0.18),(0.33,0.12)]:
        d = int(delay*SR); rev[d:] += g*mix[:n-d]
    out = mix + 0.5*rev
    out = out/(np.max(np.abs(out))+1e-9); out = np.tanh(out*1.1)*0.82
    fi, fo = int(0.8*SR), int(1.4*SR)
    out[:fi] *= np.linspace(0,1,fi); out[-fo:] *= np.linspace(1,0,fo)
    st = np.stack([out, np.concatenate([[0,0], out[:-2]])], axis=1)
    return (st/(np.max(np.abs(st))+1e-9)*0.9*32767).astype('<i2')

for name, preset in PRESETS.items():
    data = render(preset)
    with wave.open(f'bed_{name}.wav', 'wb') as w:
        w.setnchannels(2); w.setsampwidth(2); w.setframerate(SR); w.writeframes(data.tobytes())
    print('wrote bed_%s.wav' % name)
