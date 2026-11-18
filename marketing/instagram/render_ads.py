#!/usr/bin/env python3
"""
Paid-ad creative for the Seek Ads test (docs/seek-ads-plan.md).

Each ad: hook card on frame 1 (same system as render_hook_reels.py) ->
real app screens in a phone frame with one sans caption per screen ->
end card (wordmark, line, "Free on iPhone & Android"). Meta adds the
Install button, so the end card carries no store badges.

Screens are real iPhone screenshots dropped into ads/screens/ios/ as
home.png, chat.png, card.png (portrait, straight from the device or the
simulator, no marketing frame). Ads whose screens are missing are skipped
with a message; the verse-first ad (ad04) needs none. The campaign is
iOS-only (docs/seek-ads-plan.md), so the end card says "Free on iPhone".

Outputs marketing/instagram/ads/<id>_9x16.mp4 and <id>_4x5.mp4.

Usage: python3 render_ads.py [id ...]
"""
import os, sys, subprocess
from PIL import Image, ImageDraw
import render_hook_reels as R
from refresh_slate import ADS

OUT = os.path.join(R.HERE, "ads")
SHOTS = os.path.join(R.HERE, "ads", "screens", "ios")
END_TAG = "FREE ON IPHONE"
FPS = 30
HOOK_END, DEMO_END, TOTAL = 2.6, 9.4, 12.4

def comp(fr, layer, a, xy=(0, 0)):
    """alpha_composite with an opacity; skips fully transparent layers."""
    l = R.faded(layer, a)
    if l is not None: fr.alpha_composite(l, xy)

def rounded_mask(size, r):
    m = Image.new("L", size, 0); ImageDraw.Draw(m).rounded_rectangle([0, 0, size[0] - 1, size[1] - 1], r, fill=255); return m

def missing_screens(ad):
    return [s for s in ad["demo"] if not os.path.exists(os.path.join(SHOTS, f"{s}.png"))]

def phone(shot, width):
    """iPhone-style body: thin bezel, large corner radius, Dynamic Island."""
    src = Image.open(os.path.join(SHOTS, f"{shot}.png")).convert("RGBA")
    bez = max(10, width // 48)
    sw = width - 2 * bez; sh = int(src.height * sw / src.width)
    screen = src.resize((sw, sh), Image.LANCZOS)
    body = Image.new("RGBA", (width, sh + 2 * bez), (0, 0, 0, 0)); d = ImageDraw.Draw(body)
    r = int(width * 0.15)
    d.rounded_rectangle([0, 0, width - 1, sh + 2 * bez - 1], r, fill=(18, 18, 20, 255))
    body.paste(screen, (bez, bez), rounded_mask((sw, sh), r - bez))
    iw, ih = int(sw * 0.30), int(sw * 0.085)
    iy = bez + int(sw * 0.03)
    d.rounded_rectangle([(width - iw) // 2, iy, (width + iw) // 2, iy + ih], ih // 2, fill=(0, 0, 0, 255))
    return body

def shadow(img, blur=30, alpha=90):
    from PIL import ImageFilter
    s = Image.new("RGBA", (img.width + 120, img.height + 120), (0, 0, 0, 0))
    a = img.getchannel("A").point(lambda p: alpha if p else 0)
    s.paste((0, 0, 0, 255), (60, 80), a)
    return s.filter(ImageFilter.GaussianBlur(blur))

def ad_frames(ad, Wd, Hd):
    pal = R.PALETTES[ad["palette"]]
    R_H = R.H
    # hook card layer (reuse reel layout, centered for this canvas height)
    item = dict(id=ad["id"], palette=ad["palette"], kicker=ad["kicker"], hook=ad["hook"], ref=None, line="")
    base = R.gradient(pal, Hd)
    hook_layer = Image.new("RGBA", (Wd, Hd), (0, 0, 0, 0)); d = ImageDraw.Draw(hook_layer)
    f, lines, step = R.fit_block(ad["hook"], lambda s: R.lora(s, 700), Wd - 180, int(Hd * 0.42), 132, 70, 1.12)
    y = (Hd - len(lines) * step) // 2 - int(Hd * 0.04)
    R.tracked(d, y - 90, ad["kicker"], R.inter(32), (*pal["accent"], 255), 0.16)
    for ln in lines: d.text(((Wd - R.tw(ln, f)) / 2, y), ln, font=f, fill=(*pal["ink"], 255)); y += step
    wm = R.wordmark(pal, 190)
    lock = Image.new("RGBA", (Wd, Hd), (0, 0, 0, 0)); lock.alpha_composite(wm, ((Wd - wm.width) // 2, Hd - 150 - wm.height))
    # demo phones + captions
    pw = 640 if Hd > 1500 else 470
    phones = [phone(s, pw) for s in ad["demo"]]
    shadows = [shadow(p) for p in phones]
    caps = []
    for c in ad["captions"]:
        cl = Image.new("RGBA", (Wd, Hd), (0, 0, 0, 0)); cd = ImageDraw.Draw(cl)
        cf, cls, cs = R.fit_block(c, lambda s: R.inter(s, True), Wd - 160, 160, 52, 36, 1.25)
        cy = 200 if Hd > 1500 else 60
        for ln in cls: cd.text(((Wd - R.tw(ln, cf)) / 2, cy), ln, font=cf, fill=(*pal["ink"], 255)); cy += cs
        caps.append(cl)
    # end card
    end = Image.new("RGBA", (Wd, Hd), (0, 0, 0, 0)); ed = ImageDraw.Draw(end)
    big = R.wordmark(pal, 420); end.alpha_composite(big, ((Wd - big.width) // 2, Hd // 2 - big.height - 60))
    ef, els, es = R.fit_block("Scripture for whatever\nyou're carrying.", lambda s: R.lora(s, 400, italic=True), Wd - 200, 200, 58, 40, 1.3)
    ey = Hd // 2 + 20
    for ln in els: ed.text(((Wd - R.tw(ln, ef)) / 2, ey), ln, font=ef, fill=(*pal["soft"], 255)); ey += es
    R.tracked(ed, ey + 40, END_TAG, R.inter(30), (*pal["accent"], 255), 0.18)

    n = int(TOTAL * FPS)
    for fi in range(n):
        t = fi / FPS
        fr = base.copy()
        hook_a = 1.0 if t < HOOK_END else max(0.0, 1 - (t - HOOK_END) / 0.3)
        end_a = R.ease((t - DEMO_END) / 0.4)
        comp(fr, hook_layer, hook_a)
        if phones and HOOK_END - 0.2 < t < DEMO_END + 0.4:
            seg = (DEMO_END - HOOK_END) / len(phones)
            k = min(len(phones) - 1, int((t - HOOK_END) / seg)) if t >= HOOK_END else 0
            rise = R.ease((t - (HOOK_END - 0.2)) / 0.5)
            y0 = (330 if Hd > 1500 else 250) + int((1 - rise) * 500) - int(18 * (t - HOOK_END) / (DEMO_END - HOOK_END))
            out_a = 1 - R.ease((t - DEMO_END) / 0.3)
            for j in (k - 1, k):
                if j < 0: continue
                a = 1.0 if j == k else 0.0
                if j == k and k > 0: a = R.ease((t - (HOOK_END + k * seg)) / 0.35)
                if j == k - 1: a = 1 - R.ease((t - (HOOK_END + k * seg)) / 0.35)
                a *= out_a
                if a <= 0: continue
                x = (Wd - phones[j].width) // 2
                comp(fr, shadows[j], a * rise, (x - 60, y0 - 60))
                comp(fr, phones[j], a * rise, (x, y0))
                comp(fr, caps[j], a * R.ease((t - HOOK_END) / 0.4))
        if end_a > 0: comp(fr, end, end_a)
        elif t < HOOK_END + 0.3: fr.alpha_composite(lock)
        yield fr.convert("RGB")

def verse_ad_frames(ad, Wd, Hd):
    """Verse-first ad: the organic hook reel, then the same end card."""
    item = dict(id=ad["id"], palette=ad["palette"], kicker=ad["kicker"], hook=ad["hook"], ref=ad["verse"], line="")
    pal = R.PALETTES[ad["palette"]]
    top = 260  # 4:5: crop the band that holds kicker -> reference
    def crop(g): return g if Hd == R.H else g.crop((0, top, Wd, top + Hd))
    end = Image.new("RGBA", (Wd, Hd), (0, 0, 0, 0)); ed = ImageDraw.Draw(end)
    big = R.wordmark(pal, 420); end.alpha_composite(big, ((Wd - big.width) // 2, Hd // 2 - big.height - 60))
    ef, els, es = R.fit_block("Scripture for whatever\nyou're carrying.", lambda s: R.lora(s, 400, italic=True), Wd - 200, 200, 58, 40, 1.3)
    ey = Hd // 2 + 20
    for ln in els: ed.text(((Wd - R.tw(ln, ef)) / 2, ey), ln, font=ef, fill=(*pal["soft"], 255)); ey += es
    R.tracked(ed, ey + 40, END_TAG, R.inter(30), (*pal["accent"], 255), 0.18)
    bg = R.gradient(pal, Hd)
    last = None
    for g, _ in R.frames(item, with_grain=False, tag=END_TAG):
        last = crop(g); yield last
    last = last.convert("RGBA")
    for fi in range(int(3.0 * FPS)):
        a = R.ease(fi / (0.5 * FPS))
        fr = Image.blend(last, bg, a); comp(fr, end, a); yield fr.convert("RGB")

def render(ad, fmt):
    Wd, Hd = (1080, 1920) if fmt == "9x16" else (1080, 1350)
    os.makedirs(OUT, exist_ok=True)
    out = os.path.join(OUT, f"{ad['id']}_{fmt}.mp4")
    if ad.get("verse"):
        item = dict(id=ad["id"], palette=ad["palette"], kicker=ad["kicker"], hook=ad["hook"], ref=ad["verse"], line="")
        dur = round(R.layout(item, R.PALETTES[ad["palette"]])["dur"] * FPS) / FPS + 3.0
        frames = verse_ad_frames(ad, Wd, Hd)
    else:
        dur = TOTAL; frames = ad_frames(ad, Wd, Hd)
    bed = os.path.join(R.BEDS, R.BED_FOR[ad["palette"]])
    cmd = ["ffmpeg", "-y", "-loglevel", "error", "-f", "rawvideo", "-pix_fmt", "rgb24", "-s", f"{Wd}x{Hd}",
           "-r", str(FPS), "-i", "-", "-i", bed, "-map", "0:v", "-map", "1:a", "-t", f"{dur:.2f}",
           "-c:v", "libx264", "-pix_fmt", "yuv420p", "-preset", "slow", "-crf", "24", "-maxrate", "3M", "-bufsize", "6M",
           "-af", f"loudnorm=I=-18:TP=-2:LRA=7,afade=t=in:st=0:d=0.6,afade=t=out:st={dur-1.0:.2f}:d=1.0",
           "-c:a", "aac", "-b:a", "128k", "-ar", "44100", "-movflags", "+faststart", out]
    p = subprocess.Popen(cmd, stdin=subprocess.PIPE)
    for fr in frames: p.stdin.write(fr.tobytes())
    p.stdin.close(); rc = p.wait()
    print(f"  {os.path.basename(out)}  {dur:.1f}s  rc={rc}", flush=True)

if __name__ == "__main__":
    ids = set(sys.argv[1:])
    for ad in ADS:
        if ids and ad["id"] not in ids: continue
        miss = missing_screens(ad)
        if miss:
            print(f"  skip {ad['id']}: add {', '.join(m + '.png' for m in miss)} to {os.path.relpath(SHOTS, R.HERE)}/")
            continue
        for fmt in ("9x16", "4x5"): render(ad, fmt)
