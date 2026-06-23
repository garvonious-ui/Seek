#!/usr/bin/env python3
"""
Generate ig_post_queue INSERTs that MIX the new verse-for content into the live
calendar, continuing after 2026-07-17 (day_index 31). Cadence per week:
Mon reel(heavy) · Tue reel(joy) · Wed carousel · Thu reel(heavy) · Fri single card ·
Sat reel(heavy) · Sun reel(joy). Android launch carousel kicks off day 1.
Each day also gets a morning repost story (11:10) + an evening verse-card story (23:10).
All rows status='pending' (approval gate holds).

Writes seed-vfw-calendar.sql.
"""
import os, datetime
from render_vfw import EMOTIONS, PALETTES
from render_batch2_carousels import BY_REF

START = datetime.date(2026, 7, 18)   # day after last scheduled feed (07-17)
DAY0 = 32                            # max day_index was 31
DARK = {"navy", "forest", "ocean", "plum"}

def disp(e): return e
def slug(e): return e.replace(" ", "_")
TAG = {"anxious": "anxiety", "overwhelmed": "rest", "afraid": "fearnot", "grieving": "grief",
       "discouraged": "hope", "restless": "peace", "weak": "strength", "lonely": "notalone",
       "heartbroken": "healing", "guilty": "grace", "lost": "guidance", "doubting": "faith",
       "worried": "peace", "hopeless": "hope", "unsteady": "trust", "fearful": "courage",
       "hurting": "healing", "grateful": "gratitude", "joyful": "joy", "thankful": "thankful",
       "hopeful": "hope", "blessed": "blessed", "celebrating": "praise", "at peace": "peace",
       "loved": "loved", "rejoicing": "praise", "praising": "worship"}

struggle = [(e, r) for (e, r, p) in EMOTIONS if p in DARK]
positive = [(e, r) for (e, r, p) in EMOTIONS if p not in DARK]
carousels = [  # (theme dir, cover headline)
    ("scr_peace", "for when anxiety won't quiet down"),
    ("scr_comfort", "for when your heart is breaking"),
    ("scr_strength", "for when you feel like you can't"),
    ("scr_hope", "for when hope feels far off"),
    ("scr_trust", "for when you can't see the way forward"),
]

def esc(s): return s.replace("'", "''")
HASH = "#bibleverse #scripture #faith #prayer #christianliving #nlt"

def cap_reel(e, r, joyful):
    if joyful:
        return (f"A verse for when you're {disp(e)}. ✨\n\n"
                f"The good moments are worth marking too — celebrate this one with His word.\n\n"
                f"{r} · NLT\n\n"
                f"Seek finds the verse for whatever you're feeling, high or low. Type how you feel and it surfaces "
                f"scripture, a prayer, even a worship song. Free on iPhone & Android — link in bio. \U0001f49b\n\n"
                f"{HASH} #{TAG.get(e,'faith')} #gratitude")
    return (f"A verse for when you're feeling {disp(e)}. \U0001f90d\n\n"
            f"Whatever you're carrying today, you're not carrying it alone.\n\n"
            f"{r} · NLT\n\n"
            f"Seek meets you in the moment — tell it what's on your heart and it surfaces scripture, a prayer, "
            f"even a worship song. Free on iPhone & Android — link in bio. \U0001f517\n\n"
            f"{HASH} #{TAG.get(e,'faith')}")

def cap_single(e, r, joyful):
    return (f"Save this for when you're {disp(e)}. \U0001f516\n\n"
            f"{r} · NLT\n\n"
            f"Seek surfaces the verse for whatever you're walking through — free on iPhone & Android. Link in bio. \U0001f517\n\n"
            f"{HASH} #{TAG.get(e,'faith')} #savethis")

def cap_carousel(headline):
    return (f"Scriptures {headline}. Save this \U0001f516\n\n"
            f"Swipe through → and keep the one that meets you. Which do you need today? \U0001f447\n\n"
            f"Seek finds these for you — type how you feel, get scripture in seconds. Free on iPhone & Android. \U0001f517\n\n"
            f"{HASH} #savethis #christian")

CAP_ANDROID = ("It's here. \U0001f389 Seek — scripture for whatever's on your heart — is now on ANDROID. Free, no ads.\n\n"
               "Type how you feel → get 3–5 verses, a prayer, even a worship song. Beautiful shareable verse cards. "
               "Daily verse + streaks.\n\nTell the friend who's been waiting. \U0001f49b Link in bio — on iPhone & Android.\n\n"
               "#seek #bibleapp #android #nowonandroid #faith #christian #bibleverse")

rows = []  # (day_index, 'YYYY-MM-DD HH:MM', media_type, media_path, media_paths(list|None), caption)
def add(di, d, hhmm, mt, mp, mps, cap):
    rows.append((di, f"{d} {hhmm}:00+00", mt, mp, mps, cap))

day = DAY0
date = START
si, pi, ci, card_i, story_i = 0, 0, 0, 0, 0     # cursors
all_cards = [slug(e) for (e, r, p) in EMOTIONS]  # for stories + singles
first = True
while si < len(struggle) or pi < len(positive):
    wd = date.weekday()  # Mon=0 .. Sun=6
    feed = None
    if first:
        # kickoff: Android launch
        mps = [f"carousels/android_launch/android_launch_{i}.png" for i in range(4)]
        add(day, date, "11:00", "CAROUSEL", mps[0], mps, CAP_ANDROID)
        morning = mps[0]; feed = "android"
        first = False
    elif wd in (0, 3, 5) and si < len(struggle):          # Mon/Thu/Sat heavy reel
        e, r = struggle[si]; si += 1
        add(day, date, "11:00", "REELS", f"reels-vfw/vfw_{slug(e)}.mp4", None, cap_reel(e, r, False))
        morning = f"reels-vfw/vfw_{slug(e)}.mp4"
    elif wd in (1, 6) and pi < len(positive):             # Tue/Sun joyful reel
        e, r = positive[pi]; pi += 1
        add(day, date, "11:00", "REELS", f"reels-vfw/vfw_{slug(e)}.mp4", None, cap_reel(e, r, True))
        morning = f"reels-vfw/vfw_{slug(e)}.mp4"
    elif wd == 2 and ci < len(carousels):                 # Wed carousel
        th, hl = carousels[ci]; ci += 1
        mps = [f"carousels/{th}/{th}_{i}.png" for i in range(7)]
        add(day, date, "11:00", "CAROUSEL", mps[0], mps, cap_carousel(hl))
        morning = mps[0]
    else:                                                 # Fri single card / fallbacks
        e, r, p = EMOTIONS[card_i % len(EMOTIONS)]; card_i += 1
        joyful = p not in DARK
        add(day, date, "11:00", "IMAGE", f"cards-vfw/vfw_{slug(e)}.png", None, cap_single(e, r, joyful))
        morning = f"cards-vfw/vfw_{slug(e)}.png"
    # morning repost story (reuse feed media) + evening verse-card story
    add(day, date, "11:10", "STORIES", morning, None, "")
    ecard = all_cards[story_i % len(all_cards)]; story_i += 1
    add(day, date, "23:10", "STORIES", f"cards-vfw/vfw_{ecard}.png", None, "")
    day += 1
    date += datetime.timedelta(days=1)

# build SQL
vals = []
for di, ts, mt, mp, mps, cap in rows:
    mps_sql = "NULL" if not mps else "ARRAY[" + ",".join(f"'{esc(x)}'" for x in mps) + "]"
    vals.append(f"({di},'{ts}','{mt}','{esc(mp)}',{mps_sql},'{esc(cap)}','pending')")
sql = ("insert into ig_post_queue (day_index, scheduled_for, media_type, media_path, media_paths, caption, status)\nvalues\n"
       + ",\n".join(vals) + ";\n")
out = os.path.join(os.path.dirname(__file__), "seed-vfw-calendar.sql")
open(out, "w").write(sql)

feed_rows = [r for r in rows if r[2] in ("REELS", "CAROUSEL", "IMAGE")]
print(f"days: {day-DAY0}  ({START} .. {date-datetime.timedelta(days=1)})")
print(f"feed posts: {len(feed_rows)}  (reels {sum(1 for r in feed_rows if r[2]=='REELS')}, "
      f"carousels {sum(1 for r in feed_rows if r[2]=='CAROUSEL')}, singles {sum(1 for r in feed_rows if r[2]=='IMAGE')})")
print(f"story rows: {sum(1 for r in rows if r[2]=='STORIES')}")
print(f"total rows: {len(rows)}  -> {out}")
