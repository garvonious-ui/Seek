#!/usr/bin/env python3
"""
Animate the "Verse for when you're ___" cards into 9:16 reels (warm gold).
Pure Pillow frames -> ffmpeg (rawvideo pipe) + ambient bed. Line-by-line
verse reveal with fade + rise, matching the existing reel feel.

Usage:  python3 render_reels.py [emotion]   # one emotion, or all if omitted
"""
import os, sys, subprocess
from PIL import Image, ImageDraw
import numpy as np
from render_gold import (INK, SAGE, BG_TOP, BG_BOT, WORDMARK_DARK, G, GB, VERSE_FOR)
from render_batch2_carousels import BY_REF

RW, RH, FPS, DUR, MARGIN = 1080, 1920, 30, 8.5, 110
NF = int(RH)  # placeholder; real frame count below
NFRAMES = int(FPS * DUR)
BEDS_DIR = os.path.join(os.path.dirname(__file__), "feature-reels", "_render")
BEDS = ["bed_warm.wav", "bed_tender.wav", "bed_hopeful.wav", "bed_still.wav", "bed_vespers.wav"]
OUT = os.path.join(os.path.dirname(__file__), "reels-vfw")

# ---- base gradient (numpy, fast) ----
def base_rgba():
    t = np.linspace(0, 1, RH)[:, None]
    col = (np.array(BG_TOP) + (np.array(BG_BOT) - np.array(BG_TOP)) * t).astype(np.uint8)
    row = np.repeat(col[:, None, :], RW, axis=1)
    img = Image.fromarray(row, "RGB").convert("RGBA")
    return img
BASE = base_rgba()

_WM = Image.open(WORDMARK_DARK).convert("RGBA")
def wm_scaled(target_w=240):
    w0, h0 = _WM.size
    return _WM.resize((target_w, int(h0 * target_w / w0)), Image.LANCZOS)
WM = wm_scaled()

MD = ImageDraw.Draw(Image.new("RGB", (10, 10)))
def tw(s, f): return MD.textbbox((0, 0), s, font=f)[2]
def wrap(s, f, maxw):
    out, cur = [], ""
    for w in s.split():
        t = (cur + " " + w).strip()
        if tw(t, f) <= maxw: cur = t
        else: out.append(cur); cur = w
    if cur: out.append(cur)
    return out
def fit(s, fn, maxw, max_h, start, lo=34, lh=1.34):
    sz = start
    while sz >= lo:
        f = fn(sz); lines = wrap(s, f, maxw); h = len(lines) * int(sz * lh)
        if h <= max_h: return f, lines, int(sz * lh)
        sz -= 2
    f = fn(lo); return f, wrap(s, f, maxw), int(lo * lh)

def ease(p):
    p = max(0.0, min(1.0, p)); return 1 - (1 - p) ** 3
def anim(t, start, fade=0.55, rise=18):
    p = (t - start) / fade
    return max(0.0, min(1.0, p)), (1 - ease(p)) * rise

# ---- layout for one reel (positions computed once) ----
def layout(emotion, ref):
    text = BY_REF.get(ref, (None,))[0]
    if not text: return None
    es = 120
    while tw(emotion.upper(), GB(es)) > RW - 200 and es > 72: es -= 2
    vf, vlines, vstep = fit(text, G, RW - 2 * MARGIN, 600, 58, lo=34)
    vblock = len(vlines) * vstep
    band_top = 800
    vy0 = band_top + (600 - vblock) // 2
    verse = [(ln, vy0 + i * vstep, vf) for i, ln in enumerate(vlines)]
    last_y = vy0 + (len(vlines) - 1) * vstep
    ry = max(last_y + vstep + 30, 1350)
    return dict(emotion=emotion.upper(), es=es, ref=ref, verse=verse, ry=ry)

def draw_frame(t, L):
    ov = Image.new("RGBA", (RW, RH), (0, 0, 0, 0))
    od = ImageDraw.Draw(ov)
    def ctext(y, s, f, rgb, a, dy=0.0):
        od.text(((RW - tw(s, f)) // 2, int(y - dy)), s, font=f, fill=(*rgb, int(255 * a)))
    def ttext(y, s, f, rgb, a, track, dy=0.0):
        tot = sum(tw(ch, f) + track for ch in s) - track
        x = (RW - tot) // 2
        for ch in s:
            od.text((x, int(y - dy)), ch, font=f, fill=(*rgb, int(255 * a))); x += tw(ch, f) + track
    # kicker
    a, dy = anim(t, 0.25); ttext(490, "A VERSE FOR WHEN YOU'RE", G(30), SAGE, a, 6, dy)
    # emotion
    a, dy = anim(t, 0.65, 0.6, 22); ctext(560, L["emotion"], GB(L["es"]), INK, a, dy)
    # verse lines, staggered
    last_start = 1.4
    for i, (ln, y, f) in enumerate(L["verse"]):
        st = 1.4 + i * 0.42; last_start = st
        a, dy = anim(t, st); ctext(y, ln, f, INK, a, dy)
    # rule + ref after last line
    a, dy = anim(t, last_start + 0.5)
    if a > 0:
        ry = L["ry"]
        od.line([(RW // 2 - 46, int(ry - dy)), (RW // 2 + 46, int(ry - dy))], fill=(*SAGE, int(255 * a)), width=3)
        ctext(ry + 26, f"{L['ref']}  ·  NLT", G(33), SAGE, a, dy)
    # closing tagline (fades in near end)
    a, dy = anim(t, DUR - 2.0, 0.7, 14); ttext(1640, "FREE ON IPHONE & ANDROID", G(30), SAGE, a, 4, dy)
    # wordmark
    a, _ = anim(t, 0.4, 0.7, 0)
    if a > 0:
        wm = WM.copy()
        wm.putalpha(wm.split()[3].point(lambda p: int(p * a)))
        ov.alpha_composite(wm, ((RW - WM.width) // 2, 1740))
    return Image.alpha_composite(BASE, ov).convert("RGB")

def render_one(emotion, ref, bed):
    L = layout(emotion, ref)
    if not L: print(f"  ! skip {emotion} (no verse {ref})"); return False
    os.makedirs(OUT, exist_ok=True)
    out = os.path.join(OUT, f"vfw_{emotion}.mp4")
    cmd = ["ffmpeg", "-y", "-loglevel", "error",
           "-f", "rawvideo", "-pix_fmt", "rgb24", "-s", f"{RW}x{RH}", "-r", str(FPS), "-i", "-",
           "-i", os.path.join(BEDS_DIR, bed),
           "-map", "0:v", "-map", "1:a", "-t", str(DUR),
           "-c:v", "libx264", "-pix_fmt", "yuv420p", "-preset", "medium", "-crf", "19",
           "-c:a", "aac", "-b:a", "128k",
           "-af", f"afade=t=in:st=0:d=1,afade=t=out:st={DUR-1.4}:d=1.4,volume=0.55",
           "-movflags", "+faststart", out]
    p = subprocess.Popen(cmd, stdin=subprocess.PIPE)
    for fi in range(NFRAMES):
        p.stdin.write(draw_frame(fi / FPS, L).tobytes())
    p.stdin.close(); rc = p.wait()
    print(f"   vfw_{emotion}.mp4  ({ref}, {bed})  rc={rc}")
    return rc == 0

if __name__ == "__main__":
    only = sys.argv[1] if len(sys.argv) > 1 else None
    n = 0
    for i, (emo, ref) in enumerate(VERSE_FOR):
        if only and emo != only: continue
        if render_one(emo, ref, BEDS[i % len(BEDS)]): n += 1
    print(f"done: {n} reel(s) -> {OUT}")
