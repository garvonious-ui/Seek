# Instagram content refresh, Nov 30 to Dec 25 2026

@askseekpray. Goal: cut the early skip, grow accounts reached and views, and turn
reach into saves, shares and installs.

Built on the brief Lou pasted on 2026-11-17 (snapshot below). Source of truth for
the content is `marketing/instagram/refresh_slate.py`. This doc explains it.

## Snapshot (Lou, as of 2026-11-17)

| Metric | Last 30d | Last 90d |
|---|---|---|
| Followers | 38 | |
| Reels published | 28 | 50 |
| Accounts reached | 1,056 | 1,842 |
| Reel views | 1,330 | 2,419 |
| Story views | 475 | 1,535 |

Last 20 reels: 13 to 138 views each, skip rate 61.5% to 95% (most 73-95%), like
rate 0-16.7%, about 90%+ of views from non-followers. Follower-active-time data
is unavailable (too few followers).

Top: "When the future is foggy" (Jeremiah 29:11, 138 views, 73% skip), "A verse for
when you're feeling overwhelmed" (Matthew 11:28, 128 views, 90.6% skip), "He's not
just putting up with you" (Zephaniah 3:17, 118 views, 12.9% like rate), "The scroll
wants you anxious" (Galatians 1:10, 118 views, 9.9% like rate).
Bottom: grateful / thankful / joyful static cards, 35-49 views, 90%+ skip.

## What's actually wrong

**1. The first second is empty.** `render_vfw.py` (the "Verse for when you're ___"
reels) opens on a blank gradient. The kicker fades in at 0.25s, the emotion word at
0.65s, the verse at 1.4s. Viewers decide in the first 1-3 seconds, and for most of
that window there is nothing to read. The new renderer (`render_hook_reels.py`)
draws the kicker and hook fully on frame 1.

**2. Labels lose, claims win.** The top four reels say something with a little
tension in it ("the scroll wants you anxious", "he's not just putting up with you").
The bottom ones just name a feeling ("grateful"). Every new hook makes a claim or
names a tension. The feeling moves to the small kicker above it.

**3. Reach is almost all cold.** With ~90% non-follower views, every reel is
auditioning for strangers. That's why hook quality matters more than posting time
right now, and why the follow-worthy part (the series, the voice) has to be visible
fast.

**4. The auto-refill dilutes the feed.** `ig-replenish` recycles the
least-recently-posted reels every Monday with new captions. That is how 28 reels
went out in 30 days. Volume isn't the constraint; hooks are. It's paused during the
refresh (`refresh-ops.sql`).

**5. Stories barely ran.** 1 story published in 30 days, even though the pipeline
queues 2 a day. Worth checking `ig_post_queue` for failed or stuck STORIES rows once
the Supabase connector can see the project.

## The system

### Pillars (rotate through the week)

| Pillar | What it does | Example hook |
|---|---|---|
| When you're ___ | Names a heavy moment, then pushes back on the lie inside it | "Grief isn't a lack of faith." |
| Honest prayer | Permission to pray messy: doubt, waiting, anger | "Your doubts can come with you." |
| Antidote to the scroll | Calls out the feed, offers the verse instead | "Comparison is a liar with good lighting." |
| Rest / stillness | Night, Sabbath, quiet | "He doesn't sleep. So you can." |

### Visual system

- **Palette by tone:** deep purple = grief/heavy, dark green = fear/rest,
  warm peach = joy/hope, midnight blue = night/anxious.
- **Type:** kicker in small tracked Inter caps. Hook in big Lora Bold, three short
  lines, about 30-40% of the frame. Verse in Lora Regular underneath.
  - *Push-back on the brief:* it asked for sans verse text. The project rule is
    that scripture always renders in serif, so the sans is on the kicker,
    reference and tagline instead.
- **Lockup:** "FREE ON IPHONE & ANDROID" plus the Seek wordmark in the bottom band.
  The wordmark is on screen the whole time and doesn't zoom.
- **Motion:**
  - The hook is static on frame 1.
  - Slow 100% to 105% push over the whole reel.
  - Verse lines fade up at 0.3s with 0.32s stagger, starting at 1.5s.
  - Faint grain, plus a slow light leak drifting across the top third.
- **Specs:** 1080x1920, 30fps, 8.5-11s (sized to verse length), H.264, AAC.
- **Audio:** the original ambient beds from `bedgen.py`, normalized to -18 LUFS.
  Bed by palette: tender for purple, still for green, vespers for midnight, warm
  for peach.
- **Fonts:** bundled in `marketing/instagram/fonts/` (Lora OFL, Inter OFL), so
  renders look the same on any machine.
  - Georgia stays the in-app font. It isn't redistributable, so the repo uses
    Lora, which is already the Android card font.
- **Verse text:** only from `supabase/seed-nlt.sql`. The renderer refuses any
  reference that isn't in the seed.
  - That's why Galatians 1:10, Mark 9:24, 1 Kings 19:12 and Psalm 46:10 from the
    brief aren't used. None of them are in the seed. Add them to the seed from a
    verified NLT source first, then they're usable.

### Cadence

- 5 reels a week, Mon-Fri. Friday is the repurpose slot: re-cut a top performer
  with a new hook.
- Optional Saturday community prompt ("One word for your week?").
- **Media mix ramps toward the brief's 60/20/20 target:**
  - Weeks 1-2: all animated cards, so the time test only changes one thing.
  - Weeks 3-4: 3 cards, 1 face-to-camera and 1 carousel each week.
- **Carousels:** 5 reach per post vs 67 for reels over the last cycle (Session 27).
  They come back as save-bait only, with a Story nudge 30 minutes after. If they
  stay under ~20 reach, drop them for good.

## Calendar

Times are ET. Weeks 1-2 test the posting time. Weeks 3-4 use the winner.

| Date | Pillar | Format | Hook (kicker) | Verse | Palette |
|---|---|---|---|---|---|
| Thu Nov 26 | When you're | Card (bridge, outside test) | Grateful and grieving at the same table. (FOR THE EMPTY CHAIR) | Psalm 30:5 | purple |
| **Week 1, 7:30am** | | | | | |
| Mon Nov 30 | When you're | Card | You're not too much for Him. (FOR THE OVERWHELMED) | Matthew 11:28 | green |
| Tue Dec 1 | Scroll | Card | Your feed isn't your future. (BEFORE YOU OPEN THE APP) | Proverbs 16:9 | midnight |
| Wed Dec 2 | Honest prayer | Card | Your doubts can come with you. (HONEST PRAYER) | Psalm 94:19 | purple |
| Thu Dec 3 | Rest | Card | Rest isn't something you earn. (FOR THE TIRED) | Psalm 23:2-3 | green |
| Fri Dec 4 | When you're | Repurpose of "Foggy" | You don't need the whole map. (WHEN THE FUTURE IS FOGGY) | Jeremiah 29:11 | peach |
| Sat Dec 5, 10am | Prompt | Card, no verse | One word for your week? | | green |
| **Week 2, 7:30pm** | | | | | |
| Mon Dec 7 | When you're | Card | Grief isn't a lack of faith. (FOR THE GRIEVING) | Psalm 34:18 | purple |
| Tue Dec 8 | Scroll | Card | Comparison is a liar with good lighting. (FOR THE COMPARISON SPIRAL) | Ephesians 2:10 | peach |
| Wed Dec 9 | Honest prayer | Card | Waiting isn't wasted. (FOR THE WAITING) | Psalm 40:1 | green |
| Thu Dec 10 | Rest | Card | He doesn't sleep. So you can. (FOR 2AM) | Psalm 121:3-4 | midnight |
| Fri Dec 11 | Scroll | Repurpose of "The scroll wants you anxious" | Close the app. Open your hands. (THE SCROLL WANTS YOU ANXIOUS) | 1 Peter 5:7 | midnight |
| Sat Dec 12, 10am | Prompt | Card, no verse | One word for your week? | | green |
| **Week 3, winning time** | | | | | |
| Mon Dec 14 | When you're | Card | Alone isn't the same as abandoned. (FOR THE LONELY) | Isaiah 41:13 | purple |
| Tue Dec 15 | Honest prayer | **Face-to-camera** + card tail | Ask again. He's not annoyed. | Matthew 7:7 | peach |
| Wed Dec 16 | Scroll | Card | Not every headline is yours to carry. (AFTER THE DOOMSCROLL) | John 16:33 | midnight |
| Thu Dec 17 | Rest | **Carousel** + Story | Verses for when your mind won't slow down. (SAVE THIS FOR TONIGHT) | Ps 4:8, Ps 121:3-4, Isa 26:3, Matt 11:28, John 14:27 | midnight |
| Fri Dec 18 | When you're | Repurpose of "Not just putting up with you" | You're not a burden to Him. | Zephaniah 3:17 | peach |
| **Week 4, Christmas** | | | | | |
| Mon Dec 21 | Rest | Card | Christmas is loud. He came quietly. (CHRISTMAS WEEK) | Isaiah 9:6 | midnight |
| Tue Dec 22 | When you're | **Face-to-camera** + card tail | Grief gets louder at Christmas. | Psalm 147:3 | purple |
| Wed Dec 23 | Honest prayer | Card | Tell Him the real version. (HONEST PRAYER) | Psalm 62:8 | green |
| Thu Dec 24 | Honest prayer | **Carousel** + Story | For the one who's still waiting. (SEND THIS TO SOMEONE) | Ps 40:1, Ps 27:14, Lam 3:25, Rom 12:12, Mic 7:7 | green |
| Fri Dec 25 | When you're | Repurpose slot | Joy is allowed today. (CHRISTMAS DAY). If a week 1-3 reel clearly won, re-cut that one instead. | Psalm 118:24 | peach |

**Thanksgiving week (Nov 23-27).** Leave whatever is already queued and use the
week to upload media and approve week 1. The Nov 26 bridge reel is optional. Grief
around holiday tables is a real, under-served moment, and it's a good early read on
the new hook style.

**Christmas week** carries more grief and loneliness than people post about.
Dec 21-25 leans into that with "quietly" and "real version" framing rather than
festive content. Festive content would also put us back in the "grateful card"
bucket that underperforms.

### Captions (fixed template)

```
<hook, one line>

<one human line>

<Reference> · NLT

<save/send ask>

Seek finds scripture for whatever you're carrying. Free on iPhone & Android, link in bio.

#dailyverse #verseoftheday #bibleverse #scriptureoftheday #faithoverfear #christianquotes #godisgood #christianliving #dailydevotional #walkbyfaith #scripturecards #biblescripture
```

Every slate row carries its own `line` and `ask`; `seed_refresh_calendar.py`
assembles them. The hashtag set and CTA stay identical through the test so time is
the only variable that moves (the reel itself changes daily, which is unavoidable).

## Posting-time test

- **Week 1:** Mon-Fri reels at 7:30am ET (12:30 UTC).
- **Week 2:** Mon-Fri reels at 7:30pm ET (00:30 UTC the next day).
- Saturday prompts and the Nov 26 bridge are excluded from the read.
- No other feed posts or auto Stories go out in weeks 1-2. `refresh-ops.sql`
  cancels the old queue and pauses the refill.

Log each reel 48 hours after posting (Instagram > Insights > the reel):

| Reel | Posted (ET) | Views | Accounts reached | Skip rate | Avg watch | Likes | Saves | Shares | Follows |
|---|---|---|---|---|---|---|---|---|---|
| r01 | Mon 7:30am | | | | | | | | |
| ... | | | | | | | | | |

The results query at the bottom of `refresh-ops.sql` pulls what `ig-insights`
already stores (reach, views, saves, shares). Skip rate and average watch time
still come from the app.

**Decision rule.** Compare the **medians** of the two weeks, not the averages. One
outlier reel would swing an average at n=5. Switch to PM only if median accounts
reached is at least 20% higher at 7:30pm and 4 of 5 PM reels beat their AM
pair-mates. Otherwise stay on 7:30am, which matches the history the account
already has. Then run `python3 seed_refresh_calendar.py am|pm` and apply weeks 3-4.

## Targets for the 4 weeks

These are set relative to the snapshot above, not industry benchmarks.

- **Median skip rate under 70%** (currently most reels are 73-95%). This is the
  number that tells us the frame-1 hook works.
- **Median views per reel over 100** (current range 13-138).
- **Saves + shares per reel at 2+** (Session 27 found 8 saves and 1 share across
  31 reels).
- **Followers: 38 to 60+.**

If skip rate doesn't move by the end of week 2, the problem is the hook copy, not
the layout. Next test would be the 2-second face opener on every reel.

## Face-to-camera scripts (Lou, 15s max)

How to shoot:
- Phone at eye level, natural window light, quiet room.
- First word on frame 1. No "hey guys", no intro.
- Say the opener, cut to the card tail at about 2s.
- Turn on IG auto-captions. No music under the voice. The card tail already has
  the bed.

1. **Dec 15, "Ask again. He's not annoyed."** Matthew 7:7.
   - **Face (2s):** "If you've prayed the same prayer a hundred times..."
   - **Cut to card:** `reels-refresh/r12_ask_again.mp4`.
   - **Optional VO over the card:** "...ask again. Keep on asking is the
     instruction."
2. **Dec 22, "Grief gets louder at Christmas."** Psalm 147:3.
   - **Face (2s):** "If this is your first Christmas without someone..."
   - **Cut to card:** `reels-refresh/r16_louder_christmas.mp4`.
   - **VO:** "...you're not doing the season wrong."
3. **Spare: "What I read at 2am."** Psalm 121:3-4.
   - **Face:** "This is the verse I read when I can't sleep."
   - **Cut to:** `r09_doesnt_sleep.mp4`.
4. **Spare: founder note (product, 15s).**
   - **Face:** "I built Seek for the moments you don't know where to look. You
     type what's going on. It finds the verses, and a prayer."
   - **Cut to:** `ads/ad01_racing_mind_9x16.mp4` from about 2.6s (the app demo).

If a face video doesn't get filmed, the card tail posts on its own. It's a complete
reel, already in the queue.

Upload a filmed version as `reels-refresh/<id>_face.mp4`, then:
```sql
update ig_post_queue set media_path = 'reels-refresh/<id>_face.mp4'
where media_path = 'reels-refresh/<id>.mp4';
```

## Stories and comments (hand-posted, the API can't add stickers)

**Each week:**
- One poll: "Morning verse or night verse?" (it also feeds the time test).
- One question sticker: "What can we pray for? (anonymous)". Answer with a verse
  card Story.

**Comments:** reply to every comment within the first hour with a verse reference.
On Saturday prompt posts, reply to each word with a verse. Seek can find one in
seconds.

**Carousels:** a 9:16 cover goes up as a Story 30 minutes after the carousel. The
remaining 9:16 slides are in `carousels-refresh/<id>/` if you want to post the
full set by hand.

## Files and workflow

| File | What |
|---|---|
| `marketing/instagram/refresh_slate.py` | Every reel, carousel and ad: hook, kicker, verse, palette, caption parts |
| `marketing/instagram/render_hook_reels.py` | Renders reels (`reels`), carousels (`carousels`), review stills (`stills`) |
| `marketing/instagram/render_ads.py` | Renders the paid ads (see `docs/seek-ads-plan.md`) |
| `marketing/instagram/seed_refresh_calendar.py` | Writes the queue SQL |
| `marketing/instagram/seed-refresh-weeks1-2.sql` | Weeks 1-2 + bridge + Saturdays (13 rows) |
| `marketing/instagram/seed-refresh-weeks3-4.sql` | Weeks 3-4 at 7:30am (regenerate with `pm` if PM wins) |
| `marketing/instagram/refresh-ops.sql` | Pause refill, cancel old queue, results query |
| `marketing/instagram/reels-refresh/` | 20 rendered reels + `_frame1/` review stills. Media is gitignored (one example reel + `frame1_sheet.png` are committed); render with the commands in `marketing/instagram/ASSETS.md` |
| `marketing/instagram/carousels-refresh/` | 2 carousels, 4:5 feed + 9:16 story versions (gitignored, same as above) |

**Order:**
1. Run `refresh-ops.sql` steps 1-3.
2. Upload `reels-refresh/` and `carousels-refresh/` to the `ig-media` bucket.
3. Run `seed-refresh-weeks1-2.sql`.
4. Approve week 1 in the dashboard before Nov 30 (or Nov 26 for the bridge).
5. After Dec 11, pick the slot and seed weeks 3-4.

**To add or change a reel:**
1. Edit `refresh_slate.py`.
2. Run `python3 render_hook_reels.py reels <id>`, then
   `python3 render_hook_reels.py stills <id>`.
3. Check `_frame1/<id>_f1.png` (it must work as a still) and `<id>_end.png`.
4. Re-run `seed_refresh_calendar.py`.

If the ambient beds are missing, run `cd feature-reels/_render && python3 bedgen.py`
first.

## Open items

- Supabase connector is on the POPLIFE org, so Claude can't read Seek's queue or
  insights yet. Once fixed: check what was already queued past Nov 26, and why
  Stories mostly didn't post.
- Add Galatians 1:10, Mark 9:24, 1 Kings 19:11-12 and Psalm 46:10 to
  `seed-nlt.sql` from a verified NLT source if you want them in rotation.
