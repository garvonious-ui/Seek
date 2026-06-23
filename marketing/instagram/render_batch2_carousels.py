#!/usr/bin/env python3
"""
Batch-2 "Scriptures for ___" carousels — DEEP FOREST theme.
4:5 (1080x1350). Cover + 5 verse slides + CTA. Real Georgia, gold accents,
cream wordmark. Verse text pulled from supabase/seed-nlt.sql (accurate NLT).

Output: marketing/instagram/carousels/scr_<theme>/scr_<theme>_<n>.png
"""
import os, re
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
SEED = os.path.join(ROOT, "supabase", "seed-nlt.sql")
FONTS = os.path.join(ROOT, "Seek Design System", "fonts")
WORDMARK = os.path.join(ROOT, "Seek Design System", "exports", "wordmark_light.png")
OUT = os.path.join(os.path.dirname(__file__), "carousels")

W, H = 1080, 1350
MARGIN = 120
GOLD = (205, 163, 73)
WHITE = (250, 250, 244)
# Deep forest gradient (top -> bottom)
BG_TOP = (15, 28, 12)
BG_BOT = (46, 72, 32)

G   = lambda s: ImageFont.truetype(os.path.join(FONTS, "Georgia.ttf"), s)
GB  = lambda s: ImageFont.truetype(os.path.join(FONTS, "Georgia_Bold.ttf"), s)

# ---------- seed parse ----------
def load_seed():
    txt = open(SEED, encoding="utf-8").read()
    rows = re.findall(r"\('((?:[^']|'')*)',\s*'((?:[^']|'')*)',\s*'([^']*)',\s*'([^']*)'\)", txt)
    by_ref, by_theme = {}, {}
    for ref, text, theme, _tr in rows:
        ref = ref.replace("''", "'"); text = text.replace("''", "'")
        by_ref[ref] = (text, theme)
        by_theme.setdefault(theme, []).append(ref)
    return by_ref, by_theme

BY_REF, BY_THEME = load_seed()

def verses_for(theme, picks):
    out = []
    for r in picks:
        if r in BY_REF:
            out.append((r, BY_REF[r][0]))
        else:
            print(f"  ! missing '{r}' — filling from theme '{theme}'")
    # backfill from theme pool if any pick missing
    if len(out) < len(picks):
        for r in BY_THEME.get(theme, []):
            if r not in [o[0] for o in out]:
                out.append((r, BY_REF[r][0]))
            if len(out) >= len(picks): break
    return out[:len(picks)]

# ---------- drawing helpers ----------
def gradient_bg():
    img = Image.new("RGB", (W, H))
    px = img.load()
    for y in range(H):
        t = y / (H - 1)
        r = int(BG_TOP[0] + (BG_BOT[0]-BG_TOP[0])*t)
        g = int(BG_TOP[1] + (BG_BOT[1]-BG_TOP[1])*t)
        b = int(BG_TOP[2] + (BG_BOT[2]-BG_TOP[2])*t)
        for x in range(W): px[x, y] = (r, g, b)
    return img

def text_w(d, s, f): return d.textbbox((0,0), s, font=f)[2]

def draw_centered(d, y, s, f, fill):
    d.text(((W - text_w(d, s, f))//2, y), s, font=f, fill=fill)

def draw_tracked(d, y, s, f, fill, track):
    """centered, with letter-spacing (gold kicker)."""
    total = sum(text_w(d, ch, f) + track for ch in s) - track
    x = (W - total)//2
    for ch in s:
        d.text((x, y), ch, font=f, fill=fill)
        x += text_w(d, ch, f) + track

def draw_save_this(d, y, label="SAVE THIS", f=None, track=4):
    """centered 'SAVE THIS' + a hand-drawn gold arrow (Georgia lacks →)."""
    f = f or G(28)
    tw = sum(text_w(d, ch, f) + track for ch in label) - track
    gap, alen = 22, 40
    total = tw + gap + alen
    x = (W - total)//2
    for ch in label:
        d.text((x, y), ch, font=f, fill=GOLD); x += text_w(d, ch, f) + track
    cy = y + (d.textbbox((0,0), "H", font=f)[3])//2 + 2
    ax = x - track + gap
    d.line([(ax, cy), (ax+alen, cy)], fill=GOLD, width=3)
    d.line([(ax+alen, cy), (ax+alen-12, cy-9)], fill=GOLD, width=3)
    d.line([(ax+alen, cy), (ax+alen-12, cy+9)], fill=GOLD, width=3)

def wrap(d, s, f, maxw):
    words, lines, cur = s.split(), [], ""
    for w in words:
        t = (cur + " " + w).strip()
        if text_w(d, t, f) <= maxw: cur = t
        else: lines.append(cur); cur = w
    if cur: lines.append(cur)
    return lines

def fit_block(d, s, font_fn, maxw, max_h, start, lo=40, lh=1.34):
    """shrink font until wrapped text fits max_h."""
    size = start
    while size >= lo:
        f = font_fn(size)
        lines = wrap(d, s, f, maxw)
        h = len(lines) * int(size*lh)
        if h <= max_h: return f, lines, int(size*lh)
        size -= 2
    f = font_fn(lo); return f, wrap(d, s, f, maxw), int(lo*lh)

_WM = Image.open(WORDMARK).convert("RGBA")
def paste_wordmark(img, target_w=250, bottom_pad=92):
    w0, h0 = _WM.size
    h = int(h0 * target_w / w0)
    wm = _WM.resize((target_w, h), Image.LANCZOS)
    img.paste(wm, ((W - target_w)//2, H - bottom_pad - h), wm)

# ---------- slide builders ----------
def cover(theme_key, kicker, title):
    img = gradient_bg(); d = ImageDraw.Draw(img)
    draw_tracked(d, 372, kicker.upper(), G(30), GOLD, 7)
    f, lines, step = fit_block(d, title, GB, W-2*MARGIN, 360, 92, lo=64)
    y = (H - len(lines)*step)//2 - 40
    for ln in lines:
        draw_centered(d, y, ln, f, WHITE); y += step
    draw_save_this(d, 1052)
    paste_wordmark(img)
    return img

def verse_slide(ref, text):
    img = gradient_bg(); d = ImageDraw.Draw(img)
    f, lines, step = fit_block(d, text, G, W-2*MARGIN, 640, 66, lo=40)
    block_h = len(lines)*step
    y = (H - block_h)//2 - 70
    for ln in lines:
        draw_centered(d, y, ln, f, WHITE); y += step
    ry = y + 30
    d.line([(W//2-46, ry), (W//2+46, ry)], fill=GOLD, width=3)
    draw_centered(d, ry+28, f"{ref}  ·  NLT", G(34), GOLD)
    paste_wordmark(img)
    return img

def cta():
    img = gradient_bg(); d = ImageDraw.Draw(img)
    f, lines, step = fit_block(d, "Stop searching. Start seeking.", GB, W-2*MARGIN, 260, 78, lo=58)
    y = 470
    for ln in lines:
        draw_centered(d, y, ln, f, WHITE); y += step
    draw_centered(d, y+34, "Type how you feel — Seek finds the verse,", G(38), WHITE)
    draw_centered(d, y+86, "writes a prayer, even cues a worship song.", G(38), WHITE)
    draw_tracked(d, y+184, "FREE ON IPHONE & ANDROID", G(30), GOLD, 4)
    paste_wordmark(img)
    return img

# ---------- carousels ----------
CAROUSELS = [
    ("peace",    "For an anxious mind", "When anxiety\nwon't quiet down",
        ["Philippians 4:6-7", "John 14:27", "Isaiah 26:3", "Psalm 4:8", "Colossians 3:15"]),
    ("comfort",  "Verses to hold onto", "When your heart\nis breaking",
        ["Psalm 34:18", "Matthew 11:28", "Psalm 147:3", "Revelation 21:4", "Psalm 23:4"]),
    ("strength", "For the weary", "When you feel\nlike you can't",
        ["Isaiah 40:31", "Philippians 4:13", "Isaiah 41:10", "2 Corinthians 12:9", "Psalm 46:1"]),
    ("hope",     "Keep going", "When hope\nfeels far off",
        ["Jeremiah 29:11", "Romans 15:13", "Psalm 62:5", "Hebrews 6:19", "Romans 5:5"]),
    ("trust",    "One step at a time", "When you can't see\nthe way forward",
        ["Proverbs 3:5", "Psalm 56:3-4", "Psalm 37:5", "Psalm 62:8", "Nahum 1:7"]),
]

def title_lines(img_cover_title):  # cover supports a manual newline
    return img_cover_title

if __name__ == "__main__":
    for theme_key, kicker, title, picks in CAROUSELS:
        d = os.path.join(OUT, f"scr_{theme_key}")
        os.makedirs(d, exist_ok=True)
        print(f"== {theme_key} ==")
        # cover (title may carry an explicit \n for a 2-line headline)
        cov = cover(theme_key, kicker, title)
        # re-render the headline honoring explicit newlines:
        if "\n" in title:
            cov = gradient_bg(); dd = ImageDraw.Draw(cov)
            draw_tracked(dd, 372, kicker.upper(), G(30), GOLD, 7)
            parts = title.split("\n")
            f = GB(92); step = int(92*1.18)
            y = (H - len(parts)*step)//2 - 40
            for ln in parts:
                draw_centered(dd, y, ln, f, WHITE); y += step
            draw_save_this(dd, 1052)
            paste_wordmark(cov)
        cov.save(os.path.join(d, f"scr_{theme_key}_0.png"))
        vs = verses_for(theme_key, picks)
        for i, (ref, text) in enumerate(vs, start=1):
            verse_slide(ref, text).save(os.path.join(d, f"scr_{theme_key}_{i}.png"))
            print(f"   slide {i}: {ref}")
        cta().save(os.path.join(d, f"scr_{theme_key}_{len(vs)+1}.png"))
        print(f"   -> {len(vs)+2} slides")
    print("done.")
