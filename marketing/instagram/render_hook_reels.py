#!/usr/bin/env python3
"""
Hook-first verse reels + carousels for the Nov 2026 content refresh.

Why this exists: render_vfw.py opens on a blank gradient (kicker fades in at
0.25s, the emotion at 0.65s, the verse at 1.4s), so most of the 3-second
swipe window has nothing on screen. Here the kicker + hook are fully drawn
on frame 1, then the verse fades in line by line underneath.

Spec (docs/instagram-refresh-2026-11.md): 1080x1920, 8-11s, 30fps, slow
100->105% push, subtle film grain + drifting light leak, 0.3s line fades,
ambient bed normalized to -18 LUFS. Scripture stays serif (Lora), UI in
sans (Inter). Verse text comes only from supabase/seed-nlt.sql.

Fonts are bundled in marketing/instagram/fonts (OFL) so renders match on any
machine. Beds come from feature-reels/_render/bedgen.py (run it first if the
bed_*.wav files are missing).

Usage:
  python3 render_hook_reels.py reels [id ...]   # all slate reels, or just these ids
  python3 render_hook_reels.py carousels
  python3 render_hook_reels.py stills           # frame-1 PNG of every reel (review sheet)
"""
import os, re, sys, subprocess
import numpy as np
from PIL import Image, ImageDraw, ImageFont, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
FONTS = os.path.join(HERE, "fonts")
BEDS = os.path.join(HERE, "feature-reels", "_render")
REEL_OUT = os.path.join(HERE, "reels-refresh")
CAR_OUT = os.path.join(HERE, "carousels-refresh")
STILL_OUT = os.path.join(HERE, "reels-refresh", "_frame1")

W, H, FPS = 1080, 1920, 30
MIN_DUR, MAX_DUR = 8.5, 11.0

# ---------- verse source (NLT seed only) ----------
def load_seed():
    txt = open(os.path.join(ROOT, "supabase", "seed-nlt.sql"), encoding="utf-8").read()
    rows = re.findall(r"\('((?:[^']|'')*)',\s*'((?:[^']|'')*)',\s*'([^']*)',\s*'([^']*)'\)", txt)
    return {r.replace("''", "'"): t.replace("''", "'") for r, t, _th, _tr in rows}
NLT = load_seed()

def verse(ref):
    if ref not in NLT:
        raise SystemExit(f"'{ref}' is not in supabase/seed-nlt.sql. Pick a seeded verse; never type NLT text by hand.")
    return NLT[ref]

# ---------- fonts ----------
def lora(size, weight=400, italic=False):
    f = ImageFont.truetype(os.path.join(FONTS, "Lora-Italic[wght].ttf" if italic else "Lora[wght].ttf"), size)
    f.set_variation_by_axes([weight]); return f
def inter(size, semibold=True):
    return ImageFont.truetype(os.path.join(FONTS, "Inter-SemiBold.otf" if semibold else "Inter-Medium.otf"), size)

# ---------- palettes (brief: purple=grief, green=fear/rest, peach=joy, midnight=night/anxious) ----------
PALETTES = {
    "purple":   dict(top=(30, 17, 44),   bot=(78, 48, 96),   ink=(248, 243, 250), soft=(222, 210, 230), accent=(224, 190, 128), leak=(255, 196, 150), wm="light"),
    "green":    dict(top=(11, 28, 20),   bot=(38, 70, 50),   ink=(246, 248, 240), soft=(210, 224, 208), accent=(214, 178, 96),  leak=(255, 220, 160), wm="light"),
    "midnight": dict(top=(6, 12, 30),    bot=(30, 46, 86),   ink=(240, 244, 252), soft=(200, 210, 232), accent=(222, 188, 118), leak=(170, 190, 255), wm="light"),
    "peach":    dict(top=(253, 238, 220), bot=(238, 186, 136), ink=(54, 32, 22),   soft=(96, 62, 44),   accent=(150, 82, 42),  leak=(255, 214, 170), leak_a=14, wm="dark"),
}

# ---------- wordmark ----------
_WM_DARK = Image.open(os.path.join(ROOT, "landing", "assets", "wordmark_dark.png")).convert("RGBA")
def _wm_light():
    a = np.array(_WM_DARK).astype(np.int16)
    dark = (a[..., 0] < 90) & (a[..., 1] < 90) & (a[..., 2] < 90)   # the near-black letters; gold dot untouched
    a[dark, 0], a[dark, 1], a[dark, 2] = 250, 248, 240
    return Image.fromarray(a.astype(np.uint8), "RGBA")
_WM = {"dark": _WM_DARK, "light": _wm_light()}
def wordmark(pal, width):
    src = _WM[pal["wm"]]; bbox = src.getbbox(); src = src.crop(bbox)
    return src.resize((width, int(src.height * width / src.width)), Image.LANCZOS)

# ---------- text helpers ----------
_M = ImageDraw.Draw(Image.new("RGB", (8, 8)))
def tw(s, f): return _M.textlength(s, font=f)
def wrap(s, f, maxw):
    out, cur = [], ""
    for w in s.split():
        t = (cur + " " + w).strip()
        if tw(t, f) <= maxw: cur = t
        else: out.append(cur); cur = w
    if cur: out.append(cur)
    return out
def balance(s, f, maxw):
    """Wrap, then pull words down so the last line isn't a lonely orphan."""
    lines = wrap(s, f, maxw)
    if len(lines) < 2: return lines
    target = tw(s, f) / len(lines) * 1.08
    while True:
        out, cur = [], ""
        for w in s.split():
            t = (cur + " " + w).strip()
            if tw(t, f) <= min(maxw, target) or not cur: cur = t
            else: out.append(cur); cur = w
        if cur: out.append(cur)
        if len(out) <= len(lines): return out
        target *= 1.04
def tracked(draw, xy_center_y, s, f, fill, track=0.14):
    sp = f.size * track
    total = sum(tw(c, f) for c in s) + sp * (len(s) - 1)
    x = (W - total) / 2
    for c in s:
        draw.text((x, xy_center_y), c, font=f, fill=fill); x += tw(c, f) + sp
    return total
def fit_block(s, mk, maxw, maxh, start, lo, lh):
    """Largest size that fits. A "\n" in s forces those exact line breaks."""
    size = start
    while size >= lo:
        f = mk(size); step = int(size * lh)
        if "\n" in s:
            lines = s.split("\n")
            if all(tw(l, f) <= maxw for l in lines) and len(lines) * step <= maxh: return f, lines, step
        else:
            lines = balance(s, f, maxw)
            if len(lines) * step <= maxh: return f, lines, step
        size -= 2
    f = mk(lo); return f, (s.split("\n") if "\n" in s else balance(s, f, maxw)), int(lo * lh)

def gradient(pal, h=H):
    t = np.linspace(0, 1, h)[:, None]
    col = (np.array(pal["top"]) + (np.array(pal["bot"]) - np.array(pal["top"])) * t).astype(np.uint8)
    return Image.fromarray(np.repeat(col[:, None, :], W, axis=1)).convert("RGBA")

def ease(p): p = max(0.0, min(1.0, p)); return 1 - (1 - p) ** 3

# ---------- reel layout ----------
HOOK_TOP, HOOK_H = 360, 560        # big serif hook ~30-40% of frame (with kicker)
VERSE_TOP, VERSE_H = 1000, 430
TAG_Y, WM_Y = 1612, 1676           # lockup sits in the bottom band

def layout(item, pal):
    hook_f, hook_lines, hook_step = fit_block(item["hook"], lambda s: lora(s, 700), W - 180, HOOK_H, 150, 84, 1.12)
    hook_h = len(hook_lines) * hook_step
    hook_y0 = HOOK_TOP + (HOOK_H - hook_h) // 2 + 30
    L = dict(kicker=item["kicker"], kicker_y=hook_y0 - 92, hook=(hook_f, hook_lines, hook_step, hook_y0))
    if item.get("ref"):
        text = verse(item["ref"])
        vf, vlines, vstep = fit_block(text, lambda s: lora(s, 400), W - 200, VERSE_H, 54, 36, 1.4)
        vy0 = VERSE_TOP + (VERSE_H - len(vlines) * vstep) // 2
        L["verse"] = [(ln, vy0 + i * vstep) for i, ln in enumerate(vlines)]
        L["vfont"] = vf; L["ref_y"] = vy0 + len(vlines) * vstep + 34
        words = len(text.split())
        L["dur"] = max(MIN_DUR, min(MAX_DUR, 1.5 + words / 3.1 + 2.2))
    else:
        L["verse"] = []; L["dur"] = MIN_DUR
        L["sub"] = item["line"]
    return L

def draw_static(item, pal, L):
    """Everything visible on frame 1: kicker + hook. Returned as its own layer."""
    lay = Image.new("RGBA", (W, H), (0, 0, 0, 0)); d = ImageDraw.Draw(lay)
    tracked(d, L["kicker_y"], L["kicker"], inter(32), (*pal["accent"], 255), 0.16)
    f, lines, step, y = L["hook"]
    for ln in lines:
        d.text(((W - tw(ln, f)) / 2, y), ln, font=f, fill=(*pal["ink"], 255)); y += step
    return lay

def line_layer(text, font, rgb, y):
    lay = Image.new("RGBA", (W, H), (0, 0, 0, 0)); d = ImageDraw.Draw(lay)
    d.text(((W - tw(text, font)) / 2, y), text, font=font, fill=(*rgb, 255))
    return lay

def ref_layer(ref, pal, y):
    lay = Image.new("RGBA", (W, H), (0, 0, 0, 0)); d = ImageDraw.Draw(lay)
    d.line([(W // 2 - 40, y), (W // 2 + 40, y)], fill=(*pal["accent"], 255), width=3)
    tracked(d, y + 22, f"{ref.upper()}  ·  NLT", inter(28, False), (*pal["accent"], 255), 0.08)
    return lay

def faded(layer, a, dy=0):
    if a <= 0: return None
    l = layer if a >= 1 else layer.copy()
    if a < 1:
        l.putalpha(l.getchannel("A").point(lambda p: int(p * a)))
    if dy: l = l.transform(l.size, Image.AFFINE, (1, 0, 0, 0, 1, -dy))
    return l

def grain_tiles(n=6, strength=10, seed=7):
    rng = np.random.default_rng(seed); tiles = []
    for _ in range(n):
        g = rng.normal(0, 1, (H // 2, W // 2))
        g = np.clip(128 + g * 60, 0, 255).astype(np.uint8)
        im = Image.fromarray(g, "L").resize((W, H), Image.BILINEAR)
        a = Image.new("L", (W, H), strength)
        tiles.append(Image.merge("RGBA", (im, im, im, a)))
    return tiles

def leak(pal, t, dur):
    """Soft warm glow drifting slowly left->right across the upper third."""
    lay = Image.new("RGBA", (W // 4, H // 4), (0, 0, 0, 0)); d = ImageDraw.Draw(lay)
    cx = int((0.15 + 0.7 * t / dur) * W / 4); cy = int(0.22 * H / 4)
    d.ellipse([cx - 90, cy - 70, cx + 90, cy + 70], fill=(*pal["leak"], pal.get("leak_a", 26)))
    return lay.filter(ImageFilter.GaussianBlur(26)).resize((W, H), Image.BILINEAR)

def zoom(img, z):
    if z <= 1.0001: return img
    nw, nh = int(W * z), int(H * z)
    big = img.resize((nw, nh), Image.BICUBIC)
    x, y = (nw - W) // 2, (nh - H) // 2
    return big.crop((x, y, x + W, y + H))

def frames(item, with_grain=True, only=None):
    pal = PALETTES[item["palette"]]; L = layout(item, pal); dur = L["dur"]
    base = gradient(pal); static = draw_static(item, pal, L)
    vlayers = [line_layer(ln, L["vfont"], pal["ink"], y) for ln, y in L["verse"]]
    rlayer = ref_layer(item["ref"], pal, L["ref_y"]) if item.get("ref") else None
    sub = None
    if not item.get("ref"):
        sf, slines, sstep = fit_block(L["sub"], lambda s: lora(s, 400, italic=True), W - 240, 300, 54, 40, 1.35)
        sub = Image.new("RGBA", (W, H), (0, 0, 0, 0)); sd = ImageDraw.Draw(sub); y = 1080
        for ln in slines: sd.text(((W - tw(ln, sf)) / 2, y), ln, font=sf, fill=(*pal["soft"], 255)); y += sstep
    tag = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    tracked(ImageDraw.Draw(tag), TAG_Y, "FREE ON IPHONE & ANDROID", inter(26), (*pal["accent"], 255), 0.18)
    wm = wordmark(pal, 210); lock = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    lock.alpha_composite(wm, ((W - wm.width) // 2, WM_Y))
    tiles = grain_tiles() if with_grain else None
    n = int(round(dur * FPS))
    for fi in range(n):
        if only is not None and fi not in only and not (fi == n - 1 and -1 in only): continue
        t = fi / FPS
        fr = base.copy()
        fr.alpha_composite(leak(pal, t, dur))
        fr.alpha_composite(static)                              # hook: full opacity from frame 1
        start = 1.5
        for i, vl in enumerate(vlayers):
            st = start + i * 0.32
            p = (t - st) / 0.3; l = faded(vl, ease(p), int((1 - ease(p)) * 14))
            if l: fr.alpha_composite(l)
        if rlayer is not None:
            st = start + len(vlayers) * 0.32 + 0.2; p = (t - st) / 0.3
            l = faded(rlayer, ease(p), int((1 - ease(p)) * 10))
            if l: fr.alpha_composite(l)
        if sub is not None:
            p = (t - 1.2) / 0.3; l = faded(sub, ease(p), int((1 - ease(p)) * 14))
            if l: fr.alpha_composite(l)
        fr = zoom(fr, 1.0 + 0.05 * (t / dur))                    # slow 100->105% push
        p = (t - (dur - 2.0)) / 0.3; l = faded(tag, ease(p))
        if l: fr.alpha_composite(l)
        fr.alpha_composite(lock)                                 # lockup steady, not zoomed
        if tiles: fr.alpha_composite(tiles[(fi // 2) % len(tiles)])
        yield fr.convert("RGB"), dur

BED_FOR = {"purple": "bed_tender.wav", "green": "bed_still.wav", "midnight": "bed_vespers.wav", "peach": "bed_warm.wav"}

def render_reel(item, out_dir=REEL_OUT):
    os.makedirs(out_dir, exist_ok=True)
    pal = PALETTES[item["palette"]]; dur = layout(item, pal)["dur"]
    bed = os.path.join(BEDS, BED_FOR[item["palette"]])
    if not os.path.exists(bed):
        raise SystemExit(f"missing {bed}. Run: cd feature-reels/_render && python3 bedgen.py")
    out = os.path.join(out_dir, f"{item['id']}.mp4")
    cmd = ["ffmpeg", "-y", "-loglevel", "error",
           "-f", "rawvideo", "-pix_fmt", "rgb24", "-s", f"{W}x{H}", "-r", str(FPS), "-i", "-",
           "-i", bed, "-map", "0:v", "-map", "1:a", "-t", f"{dur:.2f}",
           "-c:v", "libx264", "-pix_fmt", "yuv420p", "-preset", "slow", "-crf", "24", "-maxrate", "3M", "-bufsize", "6M",
           "-af", f"loudnorm=I=-18:TP=-2:LRA=7,afade=t=in:st=0:d=0.6,afade=t=out:st={dur-1.0:.2f}:d=1.0",
           "-c:a", "aac", "-b:a", "128k", "-ar", "44100", "-movflags", "+faststart", out]
    p = subprocess.Popen(cmd, stdin=subprocess.PIPE)
    for fr, _ in frames(item): p.stdin.write(fr.tobytes())
    p.stdin.close(); rc = p.wait()
    print(f"  {item['id']}.mp4  {dur:.1f}s  {item['palette']}  rc={rc}", flush=True)
    return out

def still(item, out_dir=STILL_OUT):
    os.makedirs(out_dir, exist_ok=True)
    (first, _), (last, _) = list(frames(item, only={0, -1}))
    first.save(os.path.join(out_dir, f"{item['id']}_f1.png"))      # what the swipe decision sees
    last.save(os.path.join(out_dir, f"{item['id']}_end.png"))      # hook + full verse together

# ---------- carousels (4:5 feed slides + 9:16 story frames) ----------
def carousel(c):
    pal = PALETTES[c["palette"]]; out = os.path.join(CAR_OUT, c["id"]); os.makedirs(out, exist_ok=True)
    for fmt, h in (("feed", 1350), ("story", 1920)):
        top = 0 if fmt == "feed" else 220
        slides = []
        # cover
        im = gradient(pal, h); d = ImageDraw.Draw(im)
        f, lines, step = fit_block(c["cover"], lambda s: lora(s, 700), W - 200, 520, 112, 70, 1.14)
        y = top + (h - top - 300 - len(lines) * step) // 2 + 60
        tracked(d, y - 90, c["cover_kicker"], inter(32), (*pal["accent"], 255), 0.16)
        for ln in lines: d.text(((W - tw(ln, f)) / 2, y), ln, font=f, fill=pal["ink"]); y += step
        tracked(d, y + 40, f"{len(c['refs'])} VERSES  ·  SWIPE  →", inter(26, False), (*pal["soft"], 255), 0.14)
        slides.append(im)
        # verses
        for i, ref in enumerate(c["refs"], 1):
            im = gradient(pal, h); d = ImageDraw.Draw(im)
            tracked(d, top + 120, f"{i:02d}", inter(30), (*pal["accent"], 255), 0.1)
            vf, vl, vs = fit_block(verse(ref), lambda s: lora(s, 400), W - 200, h - top - 520, 64, 40, 1.4)
            y = top + 120 + (h - top - 420 - len(vl) * vs) // 2 + 60
            for ln in vl: d.text(((W - tw(ln, vf)) / 2, y), ln, font=vf, fill=pal["ink"]); y += vs
            d.line([(W // 2 - 40, y + 30), (W // 2 + 40, y + 30)], fill=pal["accent"], width=3)
            tracked(d, y + 52, f"{ref.upper()}  ·  NLT", inter(28, False), (*pal["accent"], 255), 0.08)
            slides.append(im)
        # CTA
        im = gradient(pal, h); d = ImageDraw.Draw(im)
        f, lines, step = fit_block("Seek finds the verse for whatever you're carrying.", lambda s: lora(s, 700), W - 220, 360, 76, 50, 1.2)
        y = top + (h - top - len(lines) * step) // 2 - 120
        for ln in lines: d.text(((W - tw(ln, f)) / 2, y), ln, font=f, fill=pal["ink"]); y += step
        tracked(d, y + 50, "FREE ON IPHONE & ANDROID", inter(28), (*pal["accent"], 255), 0.18)
        slides.append(im)
        for k, im in enumerate(slides):
            wm = wordmark(pal, 180)
            if k: im.alpha_composite(wm, ((W - wm.width) // 2, h - (110 if fmt == "feed" else 300) - wm.height))
            else: im.alpha_composite(wm, ((W - wm.width) // 2, h - (110 if fmt == "feed" else 300) - wm.height))
            im.convert("RGB").save(os.path.join(out, f"{c['id']}_{fmt}_{k}.png"))
    print(f"  {c['id']}: {len(c['refs']) + 2} slides x 2 formats")

if __name__ == "__main__":
    from refresh_slate import SLATE, CAROUSELS
    mode = sys.argv[1] if len(sys.argv) > 1 else "reels"
    ids = set(sys.argv[2:])
    pick = [s for s in SLATE if not ids or s["id"] in ids]
    if mode == "reels":
        for s in pick: render_reel(s)
    elif mode == "stills":
        for s in pick: still(s)
    elif mode == "carousels":
        for c in CAROUSELS: carousel(c)
    else:
        raise SystemExit(__doc__)
