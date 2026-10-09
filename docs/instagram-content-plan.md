# Seek — Instagram Content + Automation Plan

> 30 days of daily content (mostly app verse cards + ~9 Claude Design video Reels), plus a Supabase-native auto-posting pipeline on the Instagram Graph API.
> Brand: gold `#CDA349` + sage `#5B7B5E`, warm off-white `#FAFAF6`, serif scripture (Georgia/Playfair/Lora). Tone: reverent but modern, denominationally neutral, matches the reader's emotional energy.

---

## 1. Strategy at a glance

- **Cadence:** 1 post/day for 30 days.
- **Mix:** 21 verse cards (from the in-app Card Creator) + 9 video Reels (Claude Design). ~70/30.
- **Why this split:** Cards are free to produce (the app already makes them) and reinforce the product. Reels carry organic reach in 2026 and show the app in motion. Two Reels/week is sustainable solo.
- **Posting time (ET, you're in Miami):** 7:00 AM for daily devotional energy + a 6:30 PM secondary slot you can test later. Faith content over-indexes early morning and Sunday.
- **Account requirement:** Convert IG to a **Business** account and link it to a Facebook Page — both are mandatory for the Graph API and for Reels publishing.

### Weekly rhythm (repeats 4x + 2 bonus days)

| Day | Slot theme | Format | Emotional register |
|-----|-----------|--------|--------------------|
| Mon | Monday Reset — verse for the week | Card | Strength / resolve |
| Tue | How Seek works / feature in motion | **Reel** | Curious / inviting |
| Wed | Wisdom Wednesday — guidance | Card | Seeking |
| Thu | Real life — anxiety, doubt, gratitude | **Reel** | Relatable / honest |
| Fri | Faith Friday — gratitude & joy | Card | Celebration |
| Sat | Worship Saturday — song + verse | Card | Uplift |
| Sun | Sunday reflection / prayer | Card | Rest / peace |

This keeps the audience oriented (they learn the rhythm) and lets you batch-produce by slot type.

---

## 2. The 30-day calendar

Notes:
- **Verse refs** are chosen for emotional range (not all "comfort" — per the app's tone rule). **Translation: NLT** on every card and caption, matching the app default (`UserProfile.preferredTranslation = "NLT"`). Show "NLT" with the reference (see §5).
- **Template** = the exact Card Creator template ID to pick.
- **Caption** = the hook line; pair it with the reusable caption framework in §3.

| # | Day | Format | Theme | Verse | Template | Caption hook |
|---|-----|--------|-------|-------|----------|--------------|
| 1 | Mon | Card | Fresh start | Lamentations 3:22-23 | `nature_sunrise` | "New week. New mercies. They show up every morning whether you feel them or not." |
| 2 | Tue | **Reel** | App intro | John 1:1 | *(video)* | "What if you could just say what's on your heart and get scripture back? Meet Seek." |
| 3 | Wed | Card | Decisions | Proverbs 3:5-6 | `minimal_sage` | "Stop trying to map the whole road. Trust the next step." |
| 4 | Thu | **Reel** | Anxiety | Philippians 4:6-7 | *(video)* | "For the 2am spiral. Read this slowly." |
| 5 | Fri | Card | Gratitude | 1 Thessalonians 5:18 | `watercolor_peach` | "Name one thing. Out loud. Right now." |
| 6 | Sat | Card | Worship | Psalm 95:1 | `bold_royal` | "Saturday song: pair this verse with something loud in your headphones." |
| 7 | Sun | Card | Rest | Matthew 11:28 | `minimal_cream` | "You're allowed to put it down today." |
| 8 | Mon | Card | Courage | Joshua 1:9 | `nature_mountain` | "Whatever this week asks of you — you don't walk in alone." |
| 9 | Tue | **Reel** | Card Creator | Psalm 46:10 | *(video)* | "Turn any verse into a card you'll actually want to share. 15 seconds." |
| 10 | Wed | Card | Wisdom | James 1:5 | `minimal_navy` | "Don't have the answer? You're allowed to ask for it." |
| 11 | Thu | **Reel** | Doubt | Mark 9:24 | *(video)* | "'I believe — help my unbelief.' The most honest prayer in the Bible." |
| 12 | Fri | Card | Joy | Psalm 16:11 | `watercolor_rose` | "Joy isn't the absence of hard things. It's a presence." |
| 13 | Sat | Card | Worship | Psalm 100:1-2 | `bold_gold` | "Saturday song rec ↓ + a verse to sit with." |
| 14 | Sun | Card | Peace | John 14:27 | `minimal_sage` | "A different kind of peace than the world hands out." |
| 15 | Mon | Card | Perseverance | Galatians 6:9 | `nature_forest` | "Don't quit in the season right before it grows." |
| 16 | Tue | **Reel** | Streaks/daily verse | Psalm 143:8 | *(video)* | "A daily verse + a streak that actually builds a habit. Here's day 30." |
| 17 | Wed | Card | Identity | Psalm 139:14 | `watercolor_lavender` | "Read it like it's about you. Because it is." |
| 18 | Thu | **Reel** | Loneliness | Deuteronomy 31:8 | *(video)* | "For when the room is full and you still feel alone." |
| 19 | Fri | Card | Thankfulness | Psalm 118:24 | `nature_sky` | "This day. This one. It counts." |
| 20 | Sat | Card | Worship | Zephaniah 3:17 | `bold_royal` | "He's singing over you. Let that reframe your Saturday." |
| 21 | Sun | Card | Surrender | 1 Peter 5:7 | `minimal_cream` | "Hand it over. You were never meant to carry it." |
| 22 | Mon | Card | Hope | Jeremiah 29:11 | `nature_sunrise` | "Plans you can't see yet are still plans." |
| 23 | Tue | **Reel** | Prayer feature | Matthew 6:6 | *(video)* | "Seek writes you a prayer when you don't have the words. Watch." |
| 24 | Wed | Card | Patience | Isaiah 40:31 | `minimal_navy` | "Waiting isn't wasted. It's where strength gets rebuilt." |
| 25 | Thu | **Reel** | Comparison | Galatians 1:10 | *(video)* | "The scroll wants you anxious. Here's the antidote." |
| 26 | Fri | Card | Love | 1 Corinthians 13:4-7 | `watercolor_rose` | "The definition we keep forgetting." |
| 27 | Sat | Card | Worship | Psalm 150:6 | `bold_gold` | "Saturday: one song, full volume, no skipping." |
| 28 | Sun | Card | Stillness | Psalm 23:1-3 | `minimal_sage` | "Let yourself be led somewhere quiet today." |
| 29 | Mon | Card | Strength | Isaiah 41:10 | `nature_mountain` | "Whatever Monday brings — fear doesn't get the final word." |
| 30 | Tue | **Reel** | Recap / CTA | Psalm 19:14 | *(video)* | "30 days of showing up. If one of these met you where you are — Seek is free. Link in bio." |

**Video count:** Days 2, 4, 9, 11, 16, 18, 23, 25, 30 = **9 Reels**. Cards = 21.

---

## 3. Reusable caption framework

Most captions follow this shape so you're never staring at a blank box:

```
[Hook line — the one from the calendar]

[2–4 short lines unpacking the verse in plain, human language.
No churchy jargon. Talk like a friend who happens to believe this.]

[Verse reference + translation, e.g. "— Philippians 4:6-7, NLT"]

[Soft CTA — rotate these:]
• "Made this in Seek. It's free → link in bio."
• "Save this for the day you'll need it."
• "Send it to someone who's carrying a lot right now."
• "What verse is carrying you this week? 👇"

.
.
[Hashtags — see set below]
```

**Hashtag sets** (rotate 2 sets, ~12–15 tags, mix sizes; don't reuse the identical block daily):

- **Set A (devotional):** #dailyverse #biblescripture #scriptureoftheday #faithoverfear #christianquotes #verseoftheday #bibleverse #godisgood #christianliving #dailydevotional #walkbyfaith #scripturecards
- **Set B (app/product):** #bibleapp #faithtech #christianapp #scriptureart #versecard #prayerlife #quiettime #morningdevotion #faithjourney #seekapp #digitaldiscipleship #christiancreators

Put hashtags in the **caption** (not first comment) — current reach data slightly favors in-caption. Keep to ~12–15; more looks spammy in 2026.

---

## 4. Claude Design video prompts (9 Reels)

Paste these into Claude Design. Each targets a **1080×1920 (9:16), 7–15 second** animated video, brand-matched. Export as MP4, H.264, then it drops into the auto-poster as a Reel.

**Shared brand block — prepend this to every prompt:**
```
Brand: "Seek" — a scripture companion app. Colors: warm gold #CDA349, light gold #EDD99A,
sage green #5B7B5E, mid-sage #8AAF8D, warm off-white background #FAFAF6, near-black text #1A1A1A.
Scripture text must use an elegant serif (Playfair Display or Lora). UI/label text uses a clean
sans-serif. Mood: reverent but modern, calm, premium, gentle motion (soft fades, slow drifts —
no aggressive bounces). Format: vertical 9:16, 1080x1920. Keep it uncluttered with generous space.
Add a small semi-transparent "Seek" wordmark in a bottom corner.
```

### Reel 1 — Day 2 · "Meet Seek"
```
[Brand block] Make a 12-second intro Reel. Open on a warm off-white screen with the typed words
"what's on your heart?" appearing letter by letter in sage. They fade, replaced by a short
hand-typed phrase like "I'm anxious about money." Then 3 verse cards gently fan in (gold-edged,
serif text), suggesting the app surfaced scripture. End on the Seek wordmark + tagline
"Say what's on your heart. Get scripture back." Soft gold particle drift throughout.
```

### Reel 2 — Day 4 · "For the 2am spiral" (Philippians 4:6-7)
```
[Brand block] Make a 10-second calming Reel for anxiety. Dark sage-to-navy gradient background,
slow breathing-rhythm pulse (4s in, 4s out) with a faint "inhale / exhale" cue. Philippians 4:6-7
reveals one line at a time in serif gold, timed to the breath. End on stillness and the reference
"Philippians 4:6-7". Very slow, meditative pacing.
```

### Reel 3 — Day 9 · "Make a card in 15 seconds" (Card Creator demo)
```
[Brand block] Make a 15-second screen-style product Reel. Simulate the Seek Card Creator: a verse
(Psalm 46:10 "Be still, and know that I am God") appears, then show template swatches changing the
card background — cream, sage, royal-purple-gold, watercolor peach — each transition snappy but
smooth. End with the finished card "shared" and text "Made in Seek — free." Use the real template
palette (cream #FAF7F0, sage #D4DDD2, royal #1E0A3C→#4A1A7A, peach #FDDCBD).
```

### Reel 4 — Day 11 · "Help my unbelief" (Mark 9:24)
```
[Brand block] Make a 9-second honest, raw-but-warm Reel about doubt. Off-white background, a single
serif line types out: "I believe — help my unbelief." Let the word "unbelief" linger. Then a soft
gold underline draws under the whole phrase, as if affirming it's okay. Reference "Mark 9:24" fades in.
Minimal, no busy motion.
```

### Reel 5 — Day 16 · "30-day streak" (daily verse + streaks)
```
[Brand block] Make a 12-second Reel showing habit-building. Animate a daily-verse card flipping
through days 1 → 30 in a calendar-style stack, a small flame/streak counter ticking up alongside.
Land on "Day 30" with a gentle gold celebration glow. Text: "A verse a day. A habit that holds."
Then Seek wordmark. Keep it satisfying and rhythmic.
```

### Reel 6 — Day 18 · "Full room, still alone" (Deuteronomy 31:8)
```
[Brand block] Make a 10-second Reel about loneliness. Start with many faint grey silhouettes
drifting past (a crowd), one figure in warm gold standing still among them. Text rises in serif:
"He goes ahead of you. He will not leave you." The grey fades, the gold figure is no longer alone —
a second warm presence appears beside it. Reference "Deuteronomy 31:8". Tender, not sad.
```

### Reel 7 — Day 23 · "When you don't have the words" (prayer feature)
```
[Brand block] Make a 13-second Reel for the prayer feature. Show an empty text field with a blinking
cursor and the prompt "I don't know how to pray right now." Then watch a short, gentle prayer appear
line by line in serif, as if Seek wrote it. End: "Seek writes the prayer when you can't. Matthew 6:6."
Calm typing motion, soft gold cursor.
```

### Reel 8 — Day 25 · "The scroll wants you anxious" (comparison)
```
[Brand block] Make an 11-second Reel contrasting social media vs. stillness. First 4s: fast,
jittery mock feed scrolling (greys, harsh), slightly overwhelming. Then a hand-swipe wipes it away
to calm off-white. Serif text: "Am I trying to please people, or God?" settles in. Reference
"Galatians 1:10". The contrast in motion speed is the whole point — frantic → still.
```

### Reel 9 — Day 30 · "30 days" (recap / CTA)
```
[Brand block] Make a 14-second recap Reel. Quick warm montage: ~8 verse cards from the month fan
past in a gentle gold-lit stack (use the brand template colors). Slow on the last one. Text:
"30 days of showing up." Then: "If one of these met you where you are…" Final frame: Seek wordmark,
"Free on the App Store. Link in bio." Hopeful, momentum-building, ends on stillness.
```

> **Tip:** Generate all 9 in one Claude Design session by batching — keep the brand block constant and only swap the per-Reel body. Export each as `reel_02.mp4`, `reel_04.mp4`, etc. (named by calendar day) so the auto-poster picks the right file.

---

## 5. Producing the 21 cards

You already have the Card Creator. Workflow:
1. In the app, for each card-day, enter the verse, pick the template from the calendar's `Template` column.
2. Export the 1080×1920 PNG.
3. Name it by day: `card_01.png`, `card_03.png`, etc.
4. Drop all PNGs + the 9 MP4s into a single asset folder that the auto-poster reads from (Supabase Storage bucket, §6).

**Translation — locked to NLT** (matches the app default, so social reads exactly like the product). Tyndale's license permits quoting up to 500 NLT verses without written permission as long as a credit appears — 30 posts is well under that. To satisfy it:
- **On each card:** show the abbreviation with the reference, e.g. `— Philippians 4:6-7, NLT`.
- **On the account once (bio or pinned post):** the full notice — "Scripture quotations are taken from the Holy Bible, New Living Translation, copyright © 1996, 2004, 2015 by Tyndale House Foundation. Used by permission."
- **In captions:** keep the `, NLT` tag after the reference; no need to repeat the full block per post.

---

## 6. Auto-posting build (Supabase + Instagram Graph API)

This fits your existing stack: a new table, a Storage bucket, one Edge Function, and a `pg_cron` schedule. No third-party scheduler.

### 6.1 Prerequisites (one-time, ~30 min)
1. Convert the IG account to **Business** and link it to a **Facebook Page**.
2. Create a Meta app at developers.facebook.com → add **Instagram Graph API** product.
3. Grant scopes: `instagram_basic`, `instagram_content_publish`, `pages_show_list`, `business_management`.
4. Generate a **long-lived access token** (60 days) and capture your `IG_USER_ID`.
5. Store `META_LONG_LIVED_TOKEN` and `IG_USER_ID` as Supabase secrets (Edge Function env). Never put them in the client.

### 6.2 Hard constraints from the API (verified June 2026)
- **Publicly reachable media URL required.** The API can't take an upload — it fetches `image_url`/`video_url` from a public HTTPS URL. → Use a Supabase Storage **public** bucket (`ig-media`).
- **Two-step publish:** `POST /{IG_USER_ID}/media` (create container) → `POST /{IG_USER_ID}/media_publish` (publish the returned container ID).
- **Reels need polling.** Video containers process asynchronously — poll `GET /{container_id}?fields=status_code` until `FINISHED` before publishing (can take 30s–a few min).
- **Reel specs:** 9:16, 5–90s, H.264/HEVC, AAC audio, MP4/MOV. Business account only.
- **Rate limits:** 100 published posts / rolling 24h (carousel = 1). You're doing 1/day — no risk.

### 6.3 Schema

```sql
create table public.ig_post_queue (
  id            uuid primary key default gen_random_uuid(),
  day_index     int not null,                  -- 1..30
  scheduled_for timestamptz not null,          -- when to publish (ET 7am → store UTC)
  media_type    text not null check (media_type in ('IMAGE','REELS')),
  media_path    text not null,                 -- path in ig-media bucket, e.g. 'card_01.png'
  caption       text not null,
  status        text not null default 'pending'
                 check (status in ('pending','approved','publishing','posted','failed')),
  container_id  text,                          -- IG media container id (set during run)
  ig_media_id   text,                          -- final published id
  error         text,
  posted_at     timestamptz,
  created_at    timestamptz default now()
);
-- RLS: service_role only. No anon/auth access — this is server-side ops data.
alter table public.ig_post_queue enable row level security;
```

Add an **approval gate**: rows start `pending`; you flip the day's row to `approved` (one tap in a tiny admin view, or a SQL update) and only `approved` rows post. Prevents a typo from going live unattended. If you'd rather full auto, default status to `approved`.

### 6.4 Edge Function `ig-publish` (runs on cron)

Pseudocode of the core loop:

```ts
// 1. Find due, approved rows
const { data: due } = await supabase.from('ig_post_queue')
  .select('*').eq('status','approved')
  .lte('scheduled_for', new Date().toISOString())
  .order('scheduled_for').limit(1);
if (!due?.length) return;
const post = due[0];
await mark(post.id, 'publishing');

// 2. Public URL for the media
const mediaUrl = supabase.storage.from('ig-media').getPublicUrl(post.media_path).data.publicUrl;

// 3. Create container
const base = `https://graph.facebook.com/v21.0/${IG_USER_ID}`;
const containerParams = post.media_type === 'REELS'
  ? { media_type:'REELS', video_url: mediaUrl, caption: post.caption }
  : { image_url: mediaUrl, caption: post.caption };
const container = await fbPost(`${base}/media`, containerParams);   // -> { id }

// 4. Reels: poll status until FINISHED (images skip this)
if (post.media_type === 'REELS') await pollUntilFinished(container.id); // status_code === 'FINISHED'

// 5. Publish
const published = await fbPost(`${base}/media_publish`, { creation_id: container.id });

// 6. Record
await supabase.from('ig_post_queue').update({
  status:'posted', container_id: container.id, ig_media_id: published.id, posted_at: new Date()
}).eq('id', post.id);
```

Wrap every Graph call in try/catch; on failure set `status='failed'` + `error=errBody`, and **log `endpoint + status + body`** to Supabase logs (same discipline as your Claude chat function — so a future API version bump surfaces in logs instead of silent failure). Pin the Graph version (`v21.0`) explicitly and keep a fallback constant.

### 6.5 Schedule it

```sql
-- run every 15 min; the function self-selects the one due/approved post
select cron.schedule(
  'ig-autopost',
  '*/15 * * * *',
  $$ select net.http_post(
       url := 'https://hxfiaowayrhuhzhhbaix.supabase.co/functions/v1/ig-publish',
       headers := jsonb_build_object('Authorization','Bearer ' || current_setting('app.cron_secret'))
     ); $$
);
```
(Requires `pg_cron` + `pg_net` extensions — enable in the Supabase dashboard. I can wire the actual function + migration when you're ready.)

### 6.6 Token refresh (don't get caught at day 60)
Long-lived tokens expire in 60 days. Add a tiny second cron (weekly) that calls the refresh endpoint and overwrites the stored secret, or set a calendar reminder for day ~50. I'd build the auto-refresh — it's ~15 lines.

### 6.7 Seeding the queue
Once cards/Reels are in the bucket, one script inserts all 30 rows (day_index, scheduled_for at 7am ET, media_type, media_path, caption). I can generate that INSERT from this calendar directly.

---

## 7. Rollout checklist

- [x] ~~Produce 21 cards~~ → done (`marketing/instagram/cards/`)
- [x] ~~Write 30 captions~~ → done (`captions.md`)
- [x] ~~Migration, Edge Functions, queue seed, admin page~~ → done
- [ ] Convert IG → Business, link Facebook Page
- [ ] Create Meta app, add Instagram Graph API, request scopes (`instagram_basic`, `instagram_content_publish`, `pages_show_list`, `business_management`)
- [ ] Generate long-lived token + IG_USER_ID
- [ ] Generate 9 Reels in Claude Design → export MP4s named `reel_NN.mp4`
- [ ] Create `ig-media` **public** Storage bucket; upload `cards/` and `reels/`
- [ ] Run the migration (`pg_cron` + `pg_net` are created by it)
- [ ] Deploy `ig-publish` + `ig-token-refresh`; set secrets (`IG_CRON_SECRET`, `META_APP_ID`, `META_APP_SECRET`, optional `GRAPH_VERSION`/`IG_MEDIA_BUCKET`)
- [ ] Run `seed-ig-queue.sql`; `insert into ig_config (id, ig_user_id, access_token) values (1, …, …)`
- [ ] Set the 3 DB settings: `app.ig_publish_url`, `app.ig_token_refresh_url`, `app.ig_cron_secret`
- [ ] **Smoke test:** set one row `scheduled_for = now()`, approve it in `admin.html`, confirm it posts
- [x] ~~Decide approval gate~~ → **ON** (rows start `pending`; approve in admin page)

---

## 8. What's already built (in `marketing/instagram/` + repo)

Locked decisions: **tap-to-approve gate ON**, **7:00 AM ET**, **auto token-refresh ON**, campaign **starts Day 1 = 2026-06-17** (edit + regenerate to change).

| Asset | Location | Status |
|-------|----------|--------|
| 21 verse cards (PNG, 1080×1920, NLT, brand-matched) | `marketing/instagram/cards/card_NN.png` | ✅ Done — ready to upload |
| All 30 full captions (hook + body + CTA + hashtags) | `marketing/instagram/captions.md` | ✅ Done |
| Queue seed (30-row INSERT, 7am ET schedule) | `marketing/instagram/seed-ig-queue.sql` | ✅ Done |
| `ig_post_queue` + `ig_config` migration (+ pg_cron) | `supabase/migrations/20260616120000_create_ig_post_queue.sql` | ✅ Done |
| `ig-publish` Edge Function | `supabase/functions/ig-publish/index.ts` | ✅ Done |
| `ig-token-refresh` Edge Function | `supabase/functions/ig-token-refresh/index.ts` | ✅ Done |
| Approve/preview admin page (local-only) | `marketing/instagram/admin.html` | ✅ Done |
| Card regen script | `outputs/render_cards.py` (scratch) | ✅ Done |
| 9 motion Reels | `marketing/instagram/reels/reel_NN.mp4` → bucket `ig-media/reels/` | ✅ Done — rendered from the Seek Design System engine (not Claude Design). §4 prompts kept for reference. |

### ✅ DEPLOYED (June 16, 2026) — live on Supabase project `hxfiaowayrhuhzhhbaix`
- Migration applied: `ig_post_queue`, `ig_config`, `app_config` tables (RLS, service-role only).
- Public `ig-media` bucket created; **21 cards uploaded** to `ig-media/cards/`.
- Edge Functions `ig-publish` + `ig-token-refresh` deployed (`verify_jwt=false`; auth via `app_config.ig_cron_secret`).
- `pg_cron`: `ig-autopost` every 15 min, `ig-token-refresh` Mondays 08:00 UTC. Config in `app_config`.
- Queue seeded: 30 rows, all `pending`, Day 1 = 2026-06-17 11:00Z (7am EDT).
- Verified: public card URL 200; function rejects unauthorized (401); returns `idle` with correct secret.
- Config note: cron secret is stored in `app_config` (key `ig_cron_secret`). Functions read it from there, so no Edge secret needed for it.

### What's left (only these)
1. ~~Produce the 9 Reels~~ → **done** — rendered from the Seek Design System engine + uploaded (`docs/instagram-automation.md` §5).
2. ~~Meta credentials + token~~ → **done** — token in `ig_config` (expires ~Aug 15 2026).
3. **Set Edge secrets** for the weekly token auto-refresh: `META_APP_ID`, `META_APP_SECRET`. Not blocking — current token covers the campaign.
4. **Run it:** open the `seek-instagram-schedule` dashboard, approve Day 1 before 7am ET on launch day. (Optional: live smoke-test one post first.)
