#!/usr/bin/env python3
"""Android launch announcement — 4-slide carousel, deep forest theme.
Reuses the batch-2 renderer helpers."""
import os
from PIL import ImageDraw
from render_batch2_carousels import (
    gradient_bg, draw_centered, draw_tracked, draw_save_this, fit_block,
    paste_wordmark, GB, G, GOLD, WHITE, W, H, MARGIN, OUT,
)

def cover(kicker, lines):
    img = gradient_bg(); d = ImageDraw.Draw(img)
    draw_tracked(d, 372, kicker.upper(), G(30), GOLD, 7)
    f = GB(96); step = int(96*1.16)
    y = (H - len(lines)*step)//2 - 40
    for ln in lines:
        draw_centered(d, y, ln, f, WHITE); y += step
    draw_save_this(d, 1052, label="SWIPE")
    paste_wordmark(img)
    return img

def feature(headline_lines, sub_lines):
    img = gradient_bg(); d = ImageDraw.Draw(img)
    f = GB(74); step = int(74*1.2)
    y = 430
    for ln in headline_lines:
        draw_centered(d, y, ln, f, WHITE); y += step
    y += 26
    for ln in sub_lines:
        draw_centered(d, y, ln, G(40), (228, 232, 222)); y += 60
    paste_wordmark(img)
    return img

def cta(headline_lines, tagline):
    img = gradient_bg(); d = ImageDraw.Draw(img)
    f = GB(82); step = int(82*1.18)
    y = 470
    for ln in headline_lines:
        draw_centered(d, y, ln, f, WHITE); y += step
    draw_tracked(d, y+40, tagline, G(30), GOLD, 4)
    paste_wordmark(img)
    return img

SLIDES = [
    cover("Just launched", ["Seek is now", "on Android"]),
    feature(["Tell it what's", "on your heart."],
            ["The AI finds 3–5 verses", "for your exact moment."]),
    feature(["A verse, a prayer,", "even a worship song."],
            ["Apple Music & Spotify —", "ready to play."]),
    cta(["On iPhone.", "Now on Android too."], "FREE  ·  NO ADS  ·  LINK IN BIO"),
]

if __name__ == "__main__":
    d = os.path.join(OUT, "android_launch")
    os.makedirs(d, exist_ok=True)
    for i, img in enumerate(SLIDES):
        img.save(os.path.join(d, f"android_launch_{i}.png"))
    print(f"saved {len(SLIDES)} slides -> {d}")
