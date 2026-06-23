# Instagram content — Batch 2 (@askseekpray)

Drafted 2026-06-23. Four lanes, all buildable on the **existing** engines:
- **Reels** → `marketing/instagram/feature-reels/_render/` (Node + Playwright + ffmpeg; `render_pw.js --scene BigChatScreen --dur <s> --fps 30`, ambient bed via `bed.py`). 1080×1920.
- **Carousels** → `outputs/render_carousels.py` (Pillow, real Georgia, 4:5 1080×1350) → `marketing/instagram/carousels/`.
- **Verse text** is pulled from `supabase/seed-nlt.sql` at render time (NLT, "NLT" shown, Tyndale ≤500-verse allowance). This doc lists **references + original copy only** — never paste long NLT text here.
- Captions follow the framework in `docs/instagram-content-plan.md` §3 (hook → 2–4 human lines → CTA → hashtags).
- **New CTA across all lanes (Android is now live):** *"Free on iPhone & Android — link in bio."*

---

## Lane 1 — "Verse for when you're ___" (Reel series)

**Format:** reuse the chat reel (`BigChatScreen`) — type the emotion → AI streams the intro + verse + (sometimes) the gold prayer card. One emotion per reel, ~10–14s, ambient bed. On-screen kicker = the hook. Infinitely repeatable; this is the recurring product slot.

| # | Emotion (typed) | Verse (NLT) | On-screen hook | Caption hook |
|---|-----------------|-------------|----------------|--------------|
| 1 | anxious | Philippians 4:6-7 | "a verse for when you're anxious" | "You don't have to carry tomorrow's weight today." |
| 2 | can't sleep | Psalm 4:8 | "…for when you can't sleep" | "Lie down. You're not the one holding the world together tonight." |
| 3 | waiting on an answer | Psalm 27:14 | "…for when you're still waiting" | "Waiting isn't wasted. It's where trust grows." |
| 4 | grieving | Psalm 34:18 | "…for when you're grieving" | "He's closest to the brokenhearted — not furthest." |
| 5 | overwhelmed | Matthew 11:28-30 | "…for when it's too much" | "The invitation isn't 'try harder.' It's 'come and rest.'" |
| 6 | doubting | Mark 9:24 | "…for when your faith feels thin" | "'Help my unbelief' is still a prayer He answers." |
| 7 | grateful | 1 Thessalonians 5:18 | "…for when your heart is full" | "Gratitude isn't for the good days only — it's the practice that carries us." |
| 8 | starting over | Lamentations 3:22-23 | "…for when you're starting over" | "New mercies. Every morning. Whether you feel them or not." |
| 9 | lonely | Isaiah 41:10 | "…for when you feel alone" | "Alone is a feeling. 'I am with you' is a fact." |
| 10 | tempted to quit | Galatians 6:9 | "…for when you want to give up" | "Don't quit before the harvest." |

**CTA (all):** *"Seek finds the verse for whatever you're carrying — type it, get scripture + a prayer in seconds. Free on iPhone & Android."*
**Hashtags:** rotate the verse-set from `captions.md` (#bibleverse #faith #scripture #prayer #christianliving + 2 emotion-specific, e.g. #anxietyrelief / #grief / #hope).

**Build:** one `render_pw.js` pass per row (scene `BigChatScreen`, the typed feeling = the emotion), mux a rotating bed, upload to `ig-media/reelsa/vfw_<emotion>.mp4`, seed into `ig_post_queue` as the recurring reel slot.

---

## Lane 2 — "Scriptures for ___" (Carousel series — save-bait)

**Format:** 4:5 carousel via `render_carousels.py`. **Slide 1 = cover** (theme + "save this 🔖"), **slides 2–6 = one verse each** (verse text + ref, app card look), **last slide = CTA** ("Seek finds these for you — free, iPhone & Android"). Highest-saved format on faith IG.

| Theme | Cover line | Verse slides (NLT refs) |
|-------|-----------|--------------------------|
| **Anxiety** | "Scriptures for when anxiety won't quiet down" | Philippians 4:6-7 · 1 Peter 5:7 · Isaiah 41:10 · Matthew 6:34 · John 14:27 |
| **Grief** | "Verses for when your heart is broken" | Psalm 34:18 · Matthew 5:4 · Psalm 147:3 · Revelation 21:4 · Psalm 73:26 |
| **New beginnings** | "Scriptures for a fresh start" | Isaiah 43:19 · Lamentations 3:22-23 · 2 Corinthians 5:17 · Jeremiah 29:11 · Philippians 1:6 |
| **Forgiveness** | "When you need to forgive (or be forgiven)" | 1 John 1:9 · Ephesians 4:32 · Colossians 3:13 · Psalm 103:12 · Micah 7:18-19 |
| **Waiting / God's timing** | "For when you're tired of waiting" | Psalm 27:14 · Isaiah 40:31 · Ecclesiastes 3:11 · Habakkuk 2:3 · Lamentations 3:25 |
| **Rest** | "Scriptures for when you can't switch off" | Psalm 4:8 · Matthew 11:28 · Psalm 127:2 · Psalm 23:1-3 · Exodus 33:14 |
| **Financial stress** | "When the numbers don't add up" | Matthew 6:31-33 · Philippians 4:19 · Proverbs 3:9-10 · Psalm 37:25 · Hebrews 13:5 |

**Caption pattern:** hook ("Save this for the next anxious night.") → 2 lines → "Which one do you need today? 👇" (comment-driver) → CTA + hashtags.
**Build:** add these as configs in `render_carousels.py`, render to `carousels/scr_<theme>/`, upload, seed as the carousel slot (every 3rd day, per the R-R-C rhythm).

---

## Lane 3 — Android launch announcement (timely — NOT in the old plan)

Seek went **live on Google Play** today. Real, postable news that reaches a whole new audience.

**Option A — Reel (recommended):** the existing **cardflip** or **chat** reel, recut with a kicker: *"Seek is now on Android 🎉"* → ends on *"Free on iPhone & Android."* Cheapest (reuse a built reel, swap the text overlay + caption).
- Caption: *"It's here. 🎉 Seek — scripture for whatever's on your heart — is now on **Android**, free, no ads. Tell the Android friend who's been waiting. 💛"* → CTA + #android #googleplay #bibleapp.

**Option B — Carousel:** Slide 1 "Now on Android" → 2–4 feature slides (AI verse match / 18 card styles / worship song recs / streaks) → last slide "Free on iPhone & Android, link in bio."

**Option C — Story set:** "We have news 👀" → "Seek is on Android now" → swipe-up/link sticker to the Play listing → "tag someone with an Android 📲."

**Do once, pin it.** Then weave *"free on iPhone & Android"* into every future CTA.

---

## Lane 4 — Engagement + Stories plays (comments + shares = reach)

**A. "Comment a word" (feed post — biggest comment-driver):**
> Caption: **"One word. What are you carrying today? Comment it below 👇 and I'll send you a verse for it."**
> *Reply playbook:* for each comment, reply with a ref + one line (or literally paste what Seek returns). Mirrors the app's core loop; every reply is more engagement. Pin the post for a day.

**B. Save-bait (over the gold prayer card):**
> **"Save this for the next time you don't have the words to pray."** → 2 lines → "Seek will write one with you. Free, iPhone & Android."

**C. Tag-someone:**
> **"Tag someone who needs Psalm 34:18 today."** (rotate the verse weekly) — shares = reach.

**D. Story poll/quiz set (hand-post — the API can't attach interactive stickers):**
- Poll: **"NLT or KJV?"** (shows the app switches both)
- This-or-that: **"Which card style?"** — 2 of the 18 templates side by side
- Poll: **"Morning verse ☀️ or night verse 🌙?"**
- Quiz: **"Guess the verse"** — first line, tap to reveal — then "Seek would've found it in 2 seconds 😉"
- Question sticker: **"What do you need prayer for? (anonymous)"** → screenshot answers (no names) + reply with a verse-card Story.

**Cadence:** 1 engagement feed post + 1 Story play per week, layered onto the existing R-R-C feed.

---

## Build priority (cheapest → highest-leverage)
1. **Android launch reel** (Option A) — reuse a built reel + new overlay/caption. ~15 min. Timely.
2. **"Verse for when you're ___"** rows 1–4 — render 4, seed the recurring slot.
3. **"Scriptures for ___"** carousels (Anxiety + Grief first) — render via `render_carousels.py`.
4. **"Comment a word"** + Story polls — copy is ready above; hand-post.
