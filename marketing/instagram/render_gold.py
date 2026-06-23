#!/usr/bin/env python3
"""
WARM GOLD / CLAY theme — Android launch carousel + "Verse for when you're ___" cards.
Light bg → dark ink text, sage accents, dark wordmark. 4:5 (1080x1350).
Verse text reused from the NLT seed via render_batch2_carousels.BY_REF.
"""
import os
from PIL import Image, ImageDraw, ImageFont
from render_batch2_carousels import BY_REF, FONTS, ROOT, OUT, W, H, MARGIN

WORDMARK_DARK = os.path.join(ROOT, "Seek Design System", "exports", "wordmark_dark.png")

# warm gold / clay gradient (light top -> gold bottom)
BG_TOP = (246, 237, 214)
BG_BOT = (210, 174, 92)
INK    = (31, 26, 16)      # headline + verse
SAGE   = (74, 104, 78)     # accents: kicker, rule, ref, arrow, tagline
SUB    = (74, 64, 40)      # muted sub-copy

G  = lambda s: ImageFont.truetype(os.path.join(FONTS, "Georgia.ttf"), s)
GB = lambda s: ImageFont.truetype(os.path.join(FONTS, "Georgia_Bold.ttf"), s)

def gradient_bg():
    img = Image.new("RGB", (W, H)); px = img.load()
    for y in range(H):
        t = y/(H-1)
        px_row = (int(BG_TOP[0]+(BG_BOT[0]-BG_TOP[0])*t),
                  int(BG_TOP[1]+(BG_BOT[1]-BG_TOP[1])*t),
                  int(BG_TOP[2]+(BG_BOT[2]-BG_TOP[2])*t))
        for x in range(W): px[x, y] = px_row
    return img

def tw(d, s, f): return d.textbbox((0,0), s, font=f)[2]
def center(d, y, s, f, fill): d.text(((W-tw(d,s,f))//2, y), s, font=f, fill=fill)

def tracked(d, y, s, f, fill, track):
    total = sum(tw(d,ch,f)+track for ch in s)-track
    x = (W-total)//2
    for ch in s:
        d.text((x,y), ch, font=f, fill=fill); x += tw(d,ch,f)+track

def swipe(d, y, label="SWIPE", track=4):
    f = G(28)
    twid = sum(tw(d,ch,f)+track for ch in label)-track
    gap, alen = 22, 40
    x = (W-(twid+gap+alen))//2
    for ch in label:
        d.text((x,y), ch, font=f, fill=SAGE); x += tw(d,ch,f)+track
    cy = y + d.textbbox((0,0),"H",font=f)[3]//2 + 2
    ax = x - track + gap
    d.line([(ax,cy),(ax+alen,cy)], fill=SAGE, width=3)
    d.line([(ax+alen,cy),(ax+alen-12,cy-9)], fill=SAGE, width=3)
    d.line([(ax+alen,cy),(ax+alen-12,cy+9)], fill=SAGE, width=3)

def wrap(d, s, f, maxw):
    out, cur = [], ""
    for w in s.split():
        t = (cur+" "+w).strip()
        if tw(d,t,f) <= maxw: cur = t
        else: out.append(cur); cur = w
    if cur: out.append(cur)
    return out

def fit(d, s, fn, maxw, max_h, start, lo=40, lh=1.34):
    size = start
    while size >= lo:
        f = fn(size); lines = wrap(d,s,f,maxw); h = len(lines)*int(size*lh)
        if h <= max_h: return f, lines, int(size*lh)
        size -= 2
    f = fn(lo); return f, wrap(d,s,f,maxw), int(lo*lh)

_WM = Image.open(WORDMARK_DARK).convert("RGBA")
def wordmark(img, target_w=250, bottom_pad=92):
    w0,h0 = _WM.size; h = int(h0*target_w/w0)
    wm = _WM.resize((target_w,h), Image.LANCZOS)
    img.paste(wm, ((W-target_w)//2, H-bottom_pad-h), wm)

# ---------------- Android launch (gold) ----------------
def al_cover(kicker, lines):
    img = gradient_bg(); d = ImageDraw.Draw(img)
    tracked(d, 372, kicker.upper(), G(30), SAGE, 7)
    f = GB(96); step = int(96*1.16); y = (H-len(lines)*step)//2 - 40
    for ln in lines: center(d, y, ln, f, INK); y += step
    swipe(d, 1052); wordmark(img); return img

def al_feature(head, sub):
    img = gradient_bg(); d = ImageDraw.Draw(img)
    f = GB(74); step = int(74*1.2); y = 430
    for ln in head: center(d, y, ln, f, INK); y += step
    y += 26
    for ln in sub: center(d, y, ln, G(40), SUB); y += 60
    wordmark(img); return img

def al_cta(head, tag):
    img = gradient_bg(); d = ImageDraw.Draw(img)
    f = GB(82); step = int(82*1.18); y = 470
    for ln in head: center(d, y, ln, f, INK); y += step
    tracked(d, y+40, tag, G(30), SAGE, 4); wordmark(img); return img

ANDROID = [
    al_cover("Just launched", ["Seek is now", "on Android"]),
    al_feature(["Tell it what's", "on your heart."], ["The AI finds 3–5 verses", "for your exact moment."]),
    al_feature(["A verse, a prayer,", "even a worship song."], ["Apple Music & Spotify —", "ready to play."]),
    al_cta(["On iPhone.", "Now on Android too."], "FREE  ·  NO ADS  ·  LINK IN BIO"),
]

# ---------------- "Verse for when you're ___" cards (gold) ----------------
VERSE_FOR = [
    ("anxious",     "Philippians 4:6-7"),
    ("overwhelmed", "Matthew 11:28"),
    ("afraid",      "Isaiah 41:10"),
    ("grieving",    "Psalm 34:18"),
    ("discouraged", "Isaiah 40:31"),
    ("restless",    "Psalm 4:8"),
]

def verse_for_card(emotion, ref):
    text = BY_REF.get(ref, (None,))[0]
    if not text:
        print(f"  ! missing verse {ref}"); return None
    img = gradient_bg(); d = ImageDraw.Draw(img)
    tracked(d, 250, "A VERSE FOR WHEN YOU'RE", G(30), SAGE, 6)
    # auto-fit the single emotion word to width
    es = 110
    while tw(d, emotion.upper(), GB(es)) > W-2*MARGIN and es > 68: es -= 2
    center(d, 326, emotion.upper(), GB(es), INK)
    # verse centered in a fixed band that clears the ref + wordmark
    band_top, band_bot = 545, 1000
    f, lines, step = fit(d, text, G, W-2*MARGIN, band_bot-band_top, 58, lo=34)
    block_h = len(lines)*step
    y = band_top + (band_bot-band_top-block_h)//2
    for ln in lines: center(d, y, ln, f, INK); y += step
    ry = 1040
    d.line([(W//2-46, ry),(W//2+46, ry)], fill=SAGE, width=3)
    center(d, ry+26, f"{ref}  ·  NLT", G(33), SAGE)
    wordmark(img); return img

if __name__ == "__main__":
    # Android launch (overwrite forest version in gold)
    ald = os.path.join(OUT, "android_launch"); os.makedirs(ald, exist_ok=True)
    for i, im in enumerate(ANDROID):
        im.save(os.path.join(ald, f"android_launch_{i}.png"))
    print(f"android_launch: {len(ANDROID)} gold slides")
    # verse-for cards
    vfd = os.path.join(os.path.dirname(OUT), "instagram", "verse-for")
    vfd = os.path.join(os.path.dirname(__file__), "verse-for"); os.makedirs(vfd, exist_ok=True)
    n = 0
    for emo, ref in VERSE_FOR:
        im = verse_for_card(emo, ref)
        if im: im.save(os.path.join(vfd, f"vfw_{emo}.png")); n += 1; print(f"   vfw_{emo}: {ref}")
    print(f"verse-for: {n} gold cards -> {vfd}")
