# Feature reels — app-demo videos for IG

App-feature reels (not verse cards) built on the **Seek Design System** animation
engine. They show the app *doing things* — the gap in the verse-card-heavy feed.

Files: `marketing/instagram/feature-reels/`. Re-render harness: `feature-reels/_render/`
(Node + Playwright Chromium + ffmpeg; scenes in `scenes.jsx`, host `frame.html`,
`render_pw.js --scene <name> --dur <s> --fps 30 --from A --to B`, music `bed.py`).
All 1080×1920 H.264 + AAC with an original synthesized ambient bed ("Original audio").

## Built (4)

| Reel | Len | What it shows | Calendar slot |
|------|-----|---------------|---------------|
| `seek_chat_reel.mp4` | 15s | Type a real feeling → AI streams in intro, two verses, prayer card, worship song. The core product moment. Enlarged for legibility; full response stays in frame. | Day 1 |
| `seek_cardflip_reel.mp4` | 19s | One verse per template, crossfading through all 18 card templates (Nature/Minimal/Watercolor/Bold), settling on Ocean. | Day 7 |
| `seek_streak_reel.mp4` | 12s | Home screen — greeting, streak ticks 11→12 with a flame pop, daily verse card, prompt chips, "12-day streak" toast. The habit loop. | Day 13 |
| `seek_worship_reel.mp4` | 13s | A verse "paired with a song," cycling 4 worship recs (Oceans, Goodness of God, Build My Life, Gratitude) with Apple Music + Spotify. The unexpected differentiator. | Day 19 |

**Wiring:** `marketing/instagram/seed-feature-reels.sql` UPDATEs the four product
slots in the live `ig_post_queue` (days 1/7/13/19) to these reels + matching
captions. Prereq: upload the 4 mp4s to the `ig-media` bucket under a fresh
`feature-reels/` prefix first (anon overwrite is blocked).

## Idea slate — more reels to build

These reuse the same engine and existing screens (Home, Chat, Worship, Library,
Card Creator), so they're cheap to add.

**Feature spotlights (app-demo, 10–15s)**
1. **Prayer spotlight** — zoom on the gold prayer card writing itself out, "when you don't have the words." Pairs with a prayer-themed product caption.
2. **Library / save** — saving a verse card, then the Library grid filling with saved cards + favorites. "Keep the ones that meet you."
3. **Translation toggle** — same verse flipping NLT ↔ KJV in Settings. Niche but answers a real question.
4. **Quick-prompt tour** — tapping Joy / Struggle / Seeking and each returning a different verse. Shows breadth fast.
5. **Crisis-care moment** — a heavy message returning scripture + a gentle "talk to someone" nudge. Tender, trust-building (handle carefully, no triggering copy).

**Format variety (changes feed texture)**
6. **"3 things you didn't know Seek does"** — fast 3-beat montage (song recs, 18 card styles, streaks).
7. **POV / green-screen** — you talking to camera with the app composited beside you reacting. Most native to current IG.
8. **Before/after** — "When you don't have words to pray" → app surfaces the verse + prayer.
9. **Fake text-thread / testimonial** — a story-style screenshot of someone opening Seek in a hard moment.
10. **Screen-record speed-run** — raw 8s "open → type → verses → card → share," no chrome. Reads authentic.

**Seasonal / evergreen series**
11. **"Verse for when you're ___"** — anxious / grateful / can't sleep / waiting. Same chat mechanic, different emotion each post. Infinitely repeatable, demo + verse in one.
12. **Sunday worship set** — the worship reel re-cut weekly with a fresh 4-song lineup tied to a theme.

**Priority pick:** Prayer spotlight (3) + "Verse for when you're ___" series (11)
— the series alone could carry a recurring product slot indefinitely.
