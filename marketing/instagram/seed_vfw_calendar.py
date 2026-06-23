#!/usr/bin/env python3
"""
Generate ig_post_queue INSERTs that MIX the verse-for content into the live
calendar at TWO feed posts/day (morning + evening devotional rhythm), continuing
after 2026-07-17 (day_index 31).

Per day:
  - AM feed @ 11:00 UTC (7am ET)  = the "anchor": a Reel (or Wed carousel; Android launch kicks off day 1)
  - midday verse-card Story @ 16:00 UTC (12pm ET)
  - PM feed @ 23:00 UTC (7pm ET)  = a complementary single verse card, mood-contrasting the AM anchor

AM reels alternate heavy/joyful; PM card is the opposite mood (heavy AM -> joyful PM, and vice-versa).
All rows status='pending' (approval gate holds). Writes seed-vfw-calendar.sql.
"""
import os, datetime
from render_vfw import EMOTIONS, PALETTES
from render_batch2_carousels import BY_REF

START = datetime.date(2026, 7, 18)
DAY0 = 32
DARK = {"navy", "forest", "ocean", "plum"}
slug = lambda e: e.replace(" ", "_")
TAG = {"anxious": "anxiety", "overwhelmed": "rest", "afraid": "fearnot", "grieving": "grief",
       "discouraged": "hope", "restless": "peace", "weak": "strength", "lonely": "notalone",
       "heartbroken": "healing", "guilty": "grace", "lost": "guidance", "doubting": "faith",
       "worried": "peace", "hopeless": "hope", "unsteady": "trust", "fearful": "courage",
       "hurting": "healing", "grateful": "gratitude", "joyful": "joy", "thankful": "thankful",
       "hopeful": "hope", "blessed": "blessed", "celebrating": "praise", "at peace": "peace",
       "loved": "loved", "rejoicing": "praise", "praising": "worship"}

struggle = [(e, r) for (e, r, p) in EMOTIONS if p in DARK]       # 17 (cycle navy/forest/ocean/plum)
positive = [(e, r) for (e, r, p) in EMOTIONS if p not in DARK]   # 10 (cycle gold/sunrise/sage/blush)
# AM reel order: spread the 10 bright reels EVENLY across the 27 so dark/light
# backgrounds alternate throughout (no clump of dark palettes at the tail).
am_reels = []
total = len(struggle) + len(positive)
light_pos = {round(k * total / len(positive)) for k in range(len(positive))}
hi = li = 0
for k in range(total):
    if k in light_pos and li < len(positive):
        am_reels.append(("joy", *positive[li])); li += 1
    elif hi < len(struggle):
        am_reels.append(("heavy", *struggle[hi])); hi += 1
    elif li < len(positive):
        am_reels.append(("joy", *positive[li])); li += 1
carousels = [("scr_peace", "for when anxiety won't quiet down"),
             ("scr_comfort", "for when your heart is breaking"),
             ("scr_strength", "for when you feel like you can't"),
             ("scr_hope", "for when hope feels far off"),
             ("scr_trust", "for when you can't see the way forward")]
heavy_cards = [(e, r) for (e, r, p) in EMOTIONS if p in DARK]
joy_cards   = [(e, r) for (e, r, p) in EMOTIONS if p not in DARK]
all_slugs   = [slug(e) for (e, r, p) in EMOTIONS]

esc = lambda s: s.replace("'", "''")
HASH = "#bibleverse #scripture #faith #prayer #christianliving #nlt"

def cap_reel(e, r, joyful):
    if joyful:
        return (f"A verse for when you're {e}. ✨\n\nThe good moments are worth marking too — celebrate this one "
                f"with His word.\n\n{r} · NLT\n\nSeek finds the verse for whatever you're feeling, high or low. "
                f"Free on iPhone & Android — link in bio. \U0001f49b\n\n{HASH} #{TAG.get(e,'faith')} #gratitude")
    return (f"A verse for when you're feeling {e}. \U0001f90d\n\nWhatever you're carrying today, you're not "
            f"carrying it alone.\n\n{r} · NLT\n\nSeek meets you in the moment — tell it what's on your heart and it "
            f"surfaces scripture, a prayer, even a worship song. Free on iPhone & Android — link in bio. \U0001f517\n\n"
            f"{HASH} #{TAG.get(e,'faith')}")

def cap_card(e, r):
    return (f"Save this for when you're {e}. \U0001f516\n\n{r} · NLT\n\nSeek surfaces the verse for whatever you're "
            f"walking through — free on iPhone & Android. Link in bio. \U0001f517\n\n{HASH} #{TAG.get(e,'faith')} #savethis")

def cap_carousel(hl):
    return (f"Scriptures {hl}. Save this \U0001f516\n\nSwipe through → and keep the one that meets you. "
            f"Which do you need today? \U0001f447\n\nSeek finds these for you — type how you feel, get scripture in "
            f"seconds. Free on iPhone & Android. \U0001f517\n\n{HASH} #savethis #christian")

CAP_ANDROID = ("It's here. \U0001f389 Seek — scripture for whatever's on your heart — is now on ANDROID. Free, no ads.\n\n"
               "Type how you feel → get 3–5 verses, a prayer, even a worship song. Beautiful shareable verse cards. "
               "Daily verse + streaks.\n\nTell the friend who's been waiting. \U0001f49b Link in bio — on iPhone & Android.\n\n"
               "#seek #bibleapp #android #nowonandroid #faith #christian #bibleverse")

rows = []
def add(di, d, hhmm, mt, mp, mps, cap):
    rows.append((di, f"{d} {hhmm}:00+00", mt, mp, mps, cap))

day, date = DAY0, START
am_i = car_i = hc = jc = story_i = 0
while True:
    wd = date.weekday()
    if wd == 2 and car_i < len(carousels):                        # Wed carousel
        th, hl = carousels[car_i]; car_i += 1
        mps = [f"carousels/{th}/{th}_{k}.png" for k in range(7)]
        add(day, date, "11:00", "CAROUSEL", mps[0], mps, cap_carousel(hl)); am_mood = "carousel"
    elif am_i < len(am_reels):                                    # reel anchor
        mood, e, r = am_reels[am_i]; am_i += 1
        add(day, date, "11:00", "REELS", f"reels-vfw/vfw_{slug(e)}.mp4", None, cap_reel(e, r, mood == "joy"))
        am_mood = mood
    else:
        break
    # midday verse-card story
    sc = all_slugs[story_i % len(all_slugs)]; story_i += 1
    add(day, date, "16:00", "STORIES", f"cards-vfw/vfw_{sc}.png", None, "")
    # PM complementary card — opposite mood of the AM anchor
    if am_mood == "heavy":
        e2, r2 = joy_cards[jc % len(joy_cards)]; jc += 1; joyful = True
    else:  # joy / carousel / news -> ground the evening with a heavy-emotion comfort card
        e2, r2 = heavy_cards[hc % len(heavy_cards)]; hc += 1; joyful = False
    add(day, date, "23:00", "IMAGE", f"cards-vfw/vfw_{slug(e2)}.png", None, cap_card(e2, r2))
    day += 1; date += datetime.timedelta(days=1)

vals = []
for di, ts, mt, mp, mps, cap in rows:
    mps_sql = "NULL" if not mps else "ARRAY[" + ",".join(f"'{esc(x)}'" for x in mps) + "]"
    vals.append(f"({di},'{ts}','{mt}','{esc(mp)}',{mps_sql},'{esc(cap)}','pending')")
sql = ("insert into ig_post_queue (day_index, scheduled_for, media_type, media_path, media_paths, caption, status)\nvalues\n"
       + ",\n".join(vals) + ";\n")
open(os.path.join(os.path.dirname(__file__), "seed-vfw-calendar.sql"), "w").write(sql)

feed = [r for r in rows if r[2] in ("REELS", "CAROUSEL", "IMAGE")]
print(f"days: {day-DAY0}  ({START} .. {date-datetime.timedelta(days=1)})  = 2 feed/day")
print(f"feed posts: {len(feed)}  (reels {sum(1 for r in feed if r[2]=='REELS')}, "
      f"carousels {sum(1 for r in feed if r[2]=='CAROUSEL')}, single cards {sum(1 for r in feed if r[2]=='IMAGE')})")
print(f"stories: {sum(1 for r in rows if r[2]=='STORIES')}   total rows: {len(rows)}")
