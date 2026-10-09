# Seek feature reels (non-card)

App-feature reels built on the `Seek Design System` video engine (not just verse cards).

- **seek_chat_reel.mp4** — 15s, 9:16. Polished app-demo: a real feeling is typed into the
  chat bar, then the AI streams in the intro, two verses, the gold prayer card, and the sage
  worship-song card (Apple Music + Spotify). Shows the core product moment.
- **seek_cardflip_reel.mp4** — 12s, 9:16. Punchy: one verse (Philippians 4:13) snapping through
  all 19 card templates (Nature / Minimal / Watercolor / Bold), settling on Ocean.

Both 1080x1920 H.264 + AAC with an original ambient music bed (synthesized — shows as
"Original audio", no licensing).

## Re-render
Engine + scenes in `_render/`. Needs Node + Playwright Chromium (arm64) + ffmpeg.
`scenes.jsx` defines `ChatReel` and `CardFlipReel`; `frame.html` hosts a deterministic
playhead; `render_pw.js --scene chat|cardflip --dur N --fps 30 --from A --to B` screenshots
frames; `bed.py` makes the music; ffmpeg muxes. Template palette is ported from
`Seek/CardTemplates/CardTemplate.swift` — keep in sync if templates change.
