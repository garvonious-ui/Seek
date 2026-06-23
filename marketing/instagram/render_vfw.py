#!/usr/bin/env python3
"""
"Verse for when you're ___" — palette-driven static cards (4:5) + animated reels (9:16).
8 backgrounds: deep (navy/forest/ocean/plum) for heavy emotions, bright
(gold/sunrise/sage/blush) for joyful ones. Verse text from the NLT seed.

Usage:
  python3 render_vfw.py            # static cards + reels (all)
  python3 render_vfw.py cards      # static cards only
  python3 render_vfw.py reels      # reels only
"""
import os, sys, subprocess
from PIL import Image, ImageDraw, ImageFont
import numpy as np
from render_batch2_carousels import BY_REF, FONTS, ROOT

W, H_CARD, H_REEL, MARGIN = 1080, 1350, 1920, 110
FPS, DUR = 30, 8.5
BEDS_DIR = os.path.join(os.path.dirname(__file__), "feature-reels", "_render")
BEDS = ["bed_warm.wav", "bed_tender.wav", "bed_hopeful.wav", "bed_still.wav", "bed_vespers.wav"]
CARD_OUT = os.path.join(os.path.dirname(__file__), "verse-for")
REEL_OUT = os.path.join(os.path.dirname(__file__), "reels-vfw")

WM = {"light": Image.open(os.path.join(ROOT, "Seek Design System", "exports", "wordmark_light.png")).convert("RGBA"),
      "dark":  Image.open(os.path.join(ROOT, "Seek Design System", "exports", "wordmark_dark.png")).convert("RGBA")}
G  = lambda s: ImageFont.truetype(os.path.join(FONTS, "Georgia.ttf"), s)
GB = lambda s: ImageFont.truetype(os.path.join(FONTS, "Georgia_Bold.ttf"), s)

PALETTES = {
    "navy":    dict(top=(14, 27, 48),  bot=(58, 82, 110),  ink=(244, 246, 250), accent=(205, 163, 73),  wm="light"),
    "forest":  dict(top=(15, 28, 12),  bot=(46, 72, 32),   ink=(250, 250, 244), accent=(205, 163, 73),  wm="light"),
    "ocean":   dict(top=(9, 38, 44),   bot=(30, 84, 90),   ink=(240, 248, 248), accent=(216, 180, 112), wm="light"),
    "plum":    dict(top=(36, 20, 42),  bot=(80, 50, 84),   ink=(248, 244, 250), accent=(216, 180, 124), wm="light"),
    "gold":    dict(top=(246, 237, 214), bot=(210, 174, 92),  ink=(31, 26, 16),  accent=(74, 104, 78),  wm="dark"),
    "sunrise": dict(top=(250, 228, 206), bot=(236, 176, 138), ink=(58, 32, 26),  accent=(122, 62, 48),  wm="dark"),
    "sage":    dict(top=(226, 236, 224), bot=(140, 176, 143), ink=(26, 42, 26),  accent=(96, 78, 32),   wm="dark"),
    "blush":   dict(top=(250, 232, 232), bot=(228, 184, 186), ink=(54, 28, 34),  accent=(124, 66, 76),  wm="dark"),
}

# emotion, verse ref (NLT, from seed), palette
EMOTIONS = [
    # — heavy / seeking (deep palettes) —
    ("anxious",     "Philippians 4:6-7",   "navy"),
    ("overwhelmed", "Matthew 11:28",       "forest"),
    ("afraid",      "Isaiah 41:10",        "ocean"),
    ("grieving",    "Psalm 34:18",         "plum"),
    ("discouraged", "Isaiah 40:31",        "navy"),
    ("restless",    "Psalm 4:8",           "forest"),
    ("weak",        "2 Corinthians 12:9",  "ocean"),
    ("lonely",      "Deuteronomy 31:6",    "plum"),
    ("heartbroken", "Psalm 147:3",         "navy"),
    ("guilty",      "1 John 1:9",          "forest"),
    ("lost",        "Proverbs 3:5-6",      "ocean"),
    ("doubting",    "Hebrews 11:1",        "plum"),
    ("worried",     "Isaiah 26:3",         "navy"),
    ("hopeless",    "Jeremiah 29:11",      "forest"),
    ("unsteady",    "Psalm 46:1",          "ocean"),
    ("fearful",     "Joshua 1:9",          "plum"),
    ("hurting",     "Psalm 103:2-3",       "navy"),
    # — grateful / joyful (bright palettes) —
    ("grateful",    "Psalm 107:1",         "gold"),
    ("joyful",      "Psalm 16:11",         "sunrise"),
    ("thankful",    "1 Thessalonians 5:18","sage"),
    ("hopeful",     "Romans 15:13",        "blush"),
    ("blessed",     "James 1:17",          "gold"),
    ("celebrating", "Psalm 118:24",        "sunrise"),
    ("at peace",    "John 14:27",          "sage"),
    ("loved",       "1 John 4:19",         "blush"),
    ("rejoicing",   "Philippians 4:4",     "gold"),
    ("praising",    "Psalm 34:1",          "sunrise"),
]

# ---------- shared helpers ----------
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
def emotion_font(s):
    es = 116
    while tw(s, GB(es)) > W - 200 and es > 66: es -= 2
    return GB(es)
def gradient(h, pal):
    t = np.linspace(0, 1, h)[:, None]
    col = (np.array(pal["top"]) + (np.array(pal["bot"]) - np.array(pal["top"])) * t).astype(np.uint8)
    return Image.fromarray(np.repeat(col[:, None, :], W, axis=1)).convert("RGBA")
def wm_img(pal, target_w):
    src = WM[pal["wm"]]; w0, h0 = src.size
    return src.resize((target_w, int(h0 * target_w / w0)), Image.LANCZOS)

# ---------- static card (4:5) ----------
def static_card(emotion, ref, pal):
    text = BY_REF.get(ref, (None,))[0]
    if not text: print(f"  ! {emotion}: no verse {ref}"); return None
    img = gradient(H_CARD, pal); d = ImageDraw.Draw(img)
    ink, acc = pal["ink"], pal["accent"]
    # kicker
    s = "A VERSE FOR WHEN YOU'RE"; tot = sum(tw(c, G(30)) + 6 for c in s) - 6; x = (W - tot) // 2
    for c in s: d.text((x, 250), c, font=G(30), fill=acc); x += tw(c, G(30)) + 6
    ef = emotion_font(emotion.upper()); d.text(((W - tw(emotion.upper(), ef)) // 2, 326), emotion.upper(), font=ef, fill=ink)
    f, lines, step = fit(text, G, W - 2 * MARGIN, 455, 58, lo=34)
    y = 545 + (455 - len(lines) * step) // 2
    for ln in lines: d.text(((W - tw(ln, f)) // 2, y), ln, font=f, fill=ink); y += step
    ry = 1040
    d.line([(W // 2 - 46, ry), (W // 2 + 46, ry)], fill=acc, width=3)
    r = f"{ref}  ·  NLT"; d.text(((W - tw(r, G(33))) // 2, ry + 26), r, font=G(33), fill=acc)
    wm = wm_img(pal, 250); img.alpha_composite(wm, ((W - wm.width) // 2, H_CARD - 92 - wm.height))
    return img.convert("RGB")

# ---------- animated reel (9:16) ----------
def ease(p): p = max(0.0, min(1.0, p)); return 1 - (1 - p) ** 3
def anim(t, start, fade=0.55, rise=18):
    p = (t - start) / fade
    return max(0.0, min(1.0, p)), (1 - ease(p)) * rise

def reel_layout(emotion, ref):
    text = BY_REF.get(ref, (None,))[0]
    if not text: return None
    ef = emotion_font(emotion.upper())
    f, lines, step = fit(text, G, W - 2 * MARGIN, 600, 58, lo=34)
    vy0 = 800 + (600 - len(lines) * step) // 2
    verse = [(ln, vy0 + i * step, f) for i, ln in enumerate(lines)]
    last_y = vy0 + (len(lines) - 1) * step
    ry = max(last_y + step + 30, 1350)
    return dict(emotion=emotion.upper(), ef=ef, ref=ref, verse=verse, ry=ry)

def render_reel(emotion, ref, pal, bed):
    L = reel_layout(emotion, ref)
    if not L: print(f"  ! skip {emotion}"); return False
    ink, acc = pal["ink"], pal["accent"]
    base = gradient(H_REEL, pal)
    wm = wm_img(pal, 240)
    os.makedirs(REEL_OUT, exist_ok=True)
    out = os.path.join(REEL_OUT, f"vfw_{emotion.replace(' ', '_')}.mp4")
    cmd = ["ffmpeg", "-y", "-loglevel", "error",
           "-f", "rawvideo", "-pix_fmt", "rgb24", "-s", f"{W}x{H_REEL}", "-r", str(FPS), "-i", "-",
           "-i", os.path.join(BEDS_DIR, bed), "-map", "0:v", "-map", "1:a", "-t", str(DUR),
           "-c:v", "libx264", "-pix_fmt", "yuv420p", "-preset", "medium", "-crf", "19",
           "-c:a", "aac", "-b:a", "128k",
           "-af", f"afade=t=in:st=0:d=1,afade=t=out:st={DUR-1.4}:d=1.4,volume=0.55",
           "-movflags", "+faststart", out]
    p = subprocess.Popen(cmd, stdin=subprocess.PIPE)
    nframes = int(FPS * DUR)
    for fi in range(nframes):
        t = fi / FPS
        ov = Image.new("RGBA", (W, H_REEL), (0, 0, 0, 0)); od = ImageDraw.Draw(ov)
        def ctext(y, s, f, rgb, a, dy=0.0):
            od.text(((W - tw(s, f)) // 2, int(y - dy)), s, font=f, fill=(*rgb, int(255 * a)))
        # kicker
        a, dy = anim(t, 0.25)
        s = "A VERSE FOR WHEN YOU'RE"; tot = sum(tw(c, G(30)) + 6 for c in s) - 6; x = (W - tot) // 2
        for c in s: od.text((x, int(490 - dy)), c, font=G(30), fill=(*acc, int(255 * a))); x += tw(c, G(30)) + 6
        # emotion
        a, dy = anim(t, 0.65, 0.6, 22); ctext(560, L["emotion"], L["ef"], ink, a, dy)
        # verse lines
        last = 1.4
        for i, (ln, y, f) in enumerate(L["verse"]):
            st = 1.4 + i * 0.42; last = st
            a, dy = anim(t, st); ctext(y, ln, f, ink, a, dy)
        # rule + ref
        a, dy = anim(t, last + 0.5)
        if a > 0:
            ry = L["ry"]
            od.line([(W // 2 - 46, int(ry - dy)), (W // 2 + 46, int(ry - dy))], fill=(*acc, int(255 * a)), width=3)
            ctext(ry + 26, f"{L['ref']}  ·  NLT", G(33), acc, a, dy)
        # tagline
        a, dy = anim(t, DUR - 2.0, 0.7, 14)
        s = "FREE ON IPHONE & ANDROID"; tot = sum(tw(c, G(30)) + 4 for c in s) - 4; x = (W - tot) // 2
        for c in s: od.text((x, int(1640 - dy)), c, font=G(30), fill=(*acc, int(255 * a))); x += tw(c, G(30)) + 4
        # wordmark
        a, _ = anim(t, 0.4, 0.7, 0)
        if a > 0:
            w2 = wm.copy(); w2.putalpha(w2.split()[3].point(lambda px: int(px * a)))
            ov.alpha_composite(w2, ((W - wm.width) // 2, 1740))
        frame = Image.alpha_composite(base, ov).convert("RGB")
        p.stdin.write(frame.tobytes())
    p.stdin.close(); rc = p.wait()
    print(f"   reel vfw_{emotion}.mp4  ({ref}, {pal['wm']}/{bed.replace('bed_','').replace('.wav','')})  rc={rc}")
    return rc == 0

if __name__ == "__main__":
    mode = sys.argv[1] if len(sys.argv) > 1 else "all"
    if mode in ("all", "cards"):
        os.makedirs(CARD_OUT, exist_ok=True); n = 0
        for emo, ref, pal in EMOTIONS:
            im = static_card(emo, ref, PALETTES[pal])
            if im: im.save(os.path.join(CARD_OUT, f"vfw_{emo.replace(' ', '_')}.png")); n += 1
        print(f"cards: {n} -> {CARD_OUT}")
    if mode in ("all", "reels"):
        n = 0
        for i, (emo, ref, pal) in enumerate(EMOTIONS):
            if render_reel(emo, ref, PALETTES[pal], BEDS[i % len(BEDS)]): n += 1
        print(f"reels: {n} -> {REEL_OUT}")
    print("done.")
