# Seek — Instagram marketing assets

This folder holds the **source** for Seek's IG content. Almost everything visual here
is generated, so git tracks the **code + copy** and a **handful of example renders**;
the full ~84MB of PNG/JPEG/MP4/WAV output is gitignored (see `.gitignore`) and
regenerated from the scripts below.

If you're pointing Claude Design (or anything else) at this repo to build **new
templates**, this file is the orientation. The committed examples show the target
look; the render scripts and the `feature-reels/_render` engine show how they're made.

## What's committed vs. ignored

**Tracked (source of truth):**
- Copy: `captions.md`, `captions-rrc.md`, `content-batch2.md`
- Static-render scripts (Pillow): `render_gold.py`, `render_batch2_carousels.py`,
  `render_vfw.py`, `render_reels.py`, `render_android_launch.py`
- DB seeds for the posting calendar/dashboards: `seed-*.sql`, `seed_vfw_calendar.py`
- Video engine source: `feature-reels/scenes.jsx`, `feature-reels/_render/*`
  (`scenes.jsx`, `frame.html`, `render_pw.js`, `lib.js`, `bed.py`, `bedgen.py`)

**Ignored (regenerable output):** all `*.png *.jpg *.jpeg *.mp4 *.wav`, plus
`admin.html` (local tool). The generated audio beds (`_render/*.wav`) are large and
rebuilt by `bedgen.py`.

**Example renders kept for reference:**
| File | Format | Template |
|------|--------|----------|
| `carousels/car01_0..3.png` | 4:5 · 1080×1350 | Deep-forest scripture carousel (4 slides) |
| `verse-for/vfw_anxious.png`, `vfw_at_peace.png` | 4:5 · 1080×1350 | "Verse for when you're ___" (warm gold) |
| `stories/story_01.png` | 9:16 · 1080×1920 | Story card |
| `cards/IMG_4058.jpeg` | square | Photo-style verse card |
| `feature-reels/seek_streak_reel.mp4` | 9:16 · 1080×1920 H.264 | App-feature reel (video engine output) |

## Formats & dimensions
- **Feed cards / carousels:** 4:5, **1080×1350**
- **Stories & reels:** 9:16, **1080×1920**, 30fps
- **Reels:** H.264 + AAC, original synthesized ambient bed (shows as "Original audio", no licensing)

## Design tokens (warm-gold / clay theme — `render_gold.py`)
- Background gradient: top `#F6EDD6` (246,237,214) → bottom `#D2AE5C` (210,174,92)
- Ink (headline + verse): `#1F1A10` (31,26,16)
- Sage accent (kicker, rule, reference, arrow, tagline): `#4A684E` (74,104,78)
- Muted sub-copy: `#4A4028` (74,64,40)
- Type: **Georgia / Georgia Bold** (scripture stays serif — matches app rule).
  Pillow has no letter-spacing param, so tracking is applied glyph-by-glyph.
- Wordmark: `Seek Design System/exports/wordmark_dark.png`
- Scripture is **NLT** throughout (full Tyndale NLT notice lives in the IG bio/pinned post).

## Render pipeline
Static cards/carousels are pure **Pillow** → PNG. Shared text helpers (wrap/fit/tracked
centering) and the verse data (`BY_REF`) live in `render_batch2_carousels.py`;
`render_gold.py` defines the warm-gold palette + the "Verse for when you're ___" set.

`render_reels.py` animates the verse-for cards into 9:16 reels (line-by-line reveal,
fade + rise) — Pillow frames piped to **ffmpeg** with an ambient bed.

### Feature reels (`feature-reels/`)
App-demo reels built on the Seek video engine in `_render/` — **Node + Playwright
(Chromium arm64) + ffmpeg**. `scenes.jsx` defines the scenes (`ChatReel`,
`CardFlipReel`); `frame.html` hosts a deterministic playhead;
`render_pw.js --scene <name> --dur N --fps 30 --from A --to B` screenshots frames;
`bed.py`/`bedgen.py` make the music; ffmpeg muxes. The card palette is ported from
`Seek/CardTemplates/CardTemplate.swift` — **keep in sync if app templates change.**

## Regenerate everything
```bash
cd marketing/instagram
pip install pillow numpy            # static renders
python3 render_gold.py              # warm-gold cards + verse-for set
python3 render_batch2_carousels.py  # scripture carousels
python3 render_vfw.py               # verse-for variants
python3 render_reels.py             # animate verse-for -> reels (needs ffmpeg)
# feature reels (needs Node + Playwright Chromium arm64 + ffmpeg):
cd feature-reels/_render && python3 bedgen.py && node render_pw.js --scene chat --fps 30
```
