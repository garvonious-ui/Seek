"""
Content refresh slate, Nov 30 - Dec 25 2026 (see docs/instagram-refresh-2026-11.md).

One source of truth for the renderer (render_hook_reels.py), the queue seed
(seed_refresh_calendar.py) and the strategy doc. Edit here, re-render, re-seed.

Fields
  id       file slug -> reels-refresh/<id>.mp4
  date     post date (ET)
  pillar   when | prayer | scroll | rest | prompt
  kind     card | face (Lou films a 2s opener, this render is the card tail)
           | repurpose | prompt (weekend, no verse) | carousel (see CAROUSELS)
  palette  purple (grief/heavy) | green (fear/rest) | peach (joy/thankful)
           | midnight (night/anxious)
  kicker   small sans line above the hook (on screen from frame 1)
  hook     big serif line (on screen from frame 1)
  ref      NLT reference. Text is ALWAYS read from supabase/seed-nlt.sql.
           Never type verse text here.
  line     caption line under the hook (human, 1-2 sentences)
  ask      caption save/send prompt
"""

SLATE = [
    # ---- bridge: Thanksgiving (optional, stays outside the time test) ----
    dict(id="r00_empty_chair", date="2026-11-26", pillar="when", kind="card", palette="purple",
         kicker="FOR THE EMPTY CHAIR", hook="Grateful and\ngrieving at\nthe same table.",
         ref="Psalm 30:5",
         line="Both can be true today. You don't have to pick one.",
         ask="Send this to someone setting one less plate."),

    # ---- Week 1: Nov 30 - Dec 4, 7:30am ET (time test A) ----
    dict(id="r01_not_too_much", date="2026-11-30", pillar="when", kind="card", palette="green",
         kicker="FOR THE OVERWHELMED", hook="You're not\ntoo much\nfor Him.",
         ref="Matthew 11:28",
         line="The invitation was never \"get it together first.\" It's just come.",
         ask="Save this for the next heavy day."),
    dict(id="r02_feed_future", date="2026-12-01", pillar="scroll", kind="card", palette="midnight",
         kicker="BEFORE YOU OPEN THE APP", hook="Your feed\nisn't your\nfuture.",
         ref="Proverbs 16:9",
         line="Plans, comparisons, predictions. None of them get the last word.",
         ask="Send this to the friend who reads the news at 2am."),
    dict(id="r03_doubts_come", date="2026-12-02", pillar="prayer", kind="card", palette="purple",
         kicker="HONEST PRAYER", hook="Your doubts\ncan come\nwith you.",
         ref="Psalm 94:19",
         line="You don't have to clean up your questions before you pray.",
         ask="Save this for the days faith feels thin."),
    dict(id="r04_rest_not_earned", date="2026-12-03", pillar="rest", kind="card", palette="green",
         kicker="FOR THE TIRED", hook="Rest isn't\nsomething\nyou earn.",
         ref="Psalm 23:2-3",
         line="He leads you to rest. You don't have to finish the list first.",
         ask="Save this for Sunday."),
    dict(id="r05_foggy_map", date="2026-12-04", pillar="when", kind="repurpose", palette="peach",
         kicker="WHEN THE FUTURE IS FOGGY", hook="You don't\nneed the\nwhole map.",
         ref="Jeremiah 29:11",
         line="You need the next step, and the One who already sees the end.",
         ask="Send this to someone in a waiting season."),

    # ---- Week 2: Dec 7 - 11, 7:30pm ET (time test B) ----
    dict(id="r06_grief_faith", date="2026-12-07", pillar="when", kind="card", palette="purple",
         kicker="FOR THE GRIEVING", hook="Grief isn't\na lack\nof faith.",
         ref="Psalm 34:18",
         line="Tears and trust can live in the same heart.",
         ask="Send this to someone missing someone."),
    dict(id="r07_good_lighting", date="2026-12-08", pillar="scroll", kind="card", palette="peach",
         kicker="FOR THE COMPARISON SPIRAL", hook="Comparison\nis a liar with\ngood lighting.",
         ref="Ephesians 2:10",
         line="You were made on purpose, not as a rough draft of someone else.",
         ask="Save this for the next time the feed gets loud."),
    dict(id="r08_waiting_wasted", date="2026-12-09", pillar="prayer", kind="card", palette="green",
         kicker="FOR THE WAITING", hook="Waiting\nisn't wasted.",
         ref="Psalm 40:1",
         line="Unanswered isn't the same as unheard.",
         ask="Send this to someone still waiting on an answer."),
    dict(id="r09_doesnt_sleep", date="2026-12-10", pillar="rest", kind="card", palette="midnight",
         kicker="FOR 2AM", hook="He doesn't\nsleep.\nSo you can.",
         ref="Psalm 121:3-4",
         line="You're not the one holding the world together tonight.",
         ask="Save this for tonight."),
    dict(id="r10_open_hands", date="2026-12-11", pillar="scroll", kind="repurpose", palette="midnight",
         kicker="THE SCROLL WANTS YOU ANXIOUS", hook="Close the app.\nOpen your\nhands.",
         ref="1 Peter 5:7",
         line="Not every worry you read about is yours to carry.",
         ask="Send this to someone who can't put the phone down."),

    # ---- Week 3: Dec 14 - 18, winning time, 60/20/20 mix ----
    dict(id="r11_not_abandoned", date="2026-12-14", pillar="when", kind="card", palette="purple",
         kicker="FOR THE LONELY", hook="Alone isn't\nthe same as\nabandoned.",
         ref="Isaiah 41:13",
         line="Feeling alone is real. So is the hand holding yours.",
         ask="Send this to someone who's been quiet lately."),
    dict(id="r12_ask_again", date="2026-12-15", pillar="prayer", kind="face", palette="peach",
         kicker="HONEST PRAYER", hook="Ask again.\nHe's not\nannoyed.",
         ref="Matthew 7:7",
         line="Keep asking isn't nagging. It's an invitation.",
         ask="Save this for the prayer you've prayed a hundred times."),
    dict(id="r13_headline", date="2026-12-16", pillar="scroll", kind="card", palette="midnight",
         kicker="AFTER THE DOOMSCROLL", hook="Not every\nheadline is\nyours to carry.",
         ref="John 16:33",
         line="Trouble is real. It isn't the end of the story.",
         ask="Send this to someone carrying the whole news cycle."),
    # Thu Dec 17 = carousel "save for tonight" (see CAROUSELS)
    dict(id="r14_not_a_burden", date="2026-12-18", pillar="when", kind="repurpose", palette="peach",
         kicker="HE'S NOT JUST PUTTING UP WITH YOU", hook="You're not\na burden\nto Him.",
         ref="Zephaniah 3:17",
         line="He delights in you. Read that again slowly.",
         ask="Send this to someone who apologizes for existing."),

    # ---- Week 4: Dec 21 - 25, Christmas week ----
    dict(id="r15_came_quietly", date="2026-12-21", pillar="rest", kind="card", palette="midnight",
         kicker="CHRISTMAS WEEK", hook="Christmas\nis loud. He\ncame quietly.",
         ref="Isaiah 9:6",
         line="You don't need a perfect holiday to meet Him in it.",
         ask="Save this for when the week gets loud."),
    dict(id="r16_louder_christmas", date="2026-12-22", pillar="when", kind="face", palette="purple",
         kicker="FOR THE GRIEVING", hook="Grief gets\nlouder at\nChristmas.",
         ref="Psalm 147:3",
         line="If this season hurts, you're not doing it wrong.",
         ask="Send this to someone facing their first Christmas without someone."),
    dict(id="r17_real_version", date="2026-12-23", pillar="prayer", kind="card", palette="green",
         kicker="HONEST PRAYER", hook="Tell Him\nthe real\nversion.",
         ref="Psalm 62:8",
         line="Not the polished one. The one you'd only say out loud alone.",
         ask="Save this for the prayer you haven't said yet."),
    # Thu Dec 24 = carousel "send to someone who's waiting" (see CAROUSELS)
    dict(id="r18_joy_allowed", date="2026-12-25", pillar="when", kind="repurpose", palette="peach",
         kicker="CHRISTMAS DAY", hook="Joy is\nallowed\ntoday.",
         ref="Psalm 118:24",
         line="Even in a hard year, today can hold some light.",
         note="Fallback. If a week 1-3 reel clearly won, re-cut it with a new hook and post that instead.",
         ask="Send this to someone you're grateful for."),

    # ---- Weekend prompt (optional, reusable any Saturday) ----
    dict(id="r19_one_word", date="weekend", pillar="prompt", kind="prompt", palette="green",
         kicker="SATURDAY", hook="One word\nfor your\nweek?",
         ref=None,
         line="Comment it below. We'll answer with a verse.",
         ask="Reply to every comment with a verse (Seek can find it in seconds)."),
]

CAROUSELS = [
    dict(id="c01_save_tonight", date="2026-12-17", palette="midnight",
         cover_kicker="SAVE THIS FOR TONIGHT", cover="Verses for when your mind won't slow down.",
         refs=["Psalm 4:8", "Psalm 121:3-4", "Isaiah 26:3", "Matthew 11:28", "John 14:27"],
         line="Five verses for the hours after midnight. Keep them close.",
         ask="Save this. Which one do you need tonight? Comment the number."),
    dict(id="c02_still_waiting", date="2026-12-24", palette="green",
         cover_kicker="SEND THIS TO SOMEONE", cover="For the one who's still waiting.",
         refs=["Psalm 40:1", "Psalm 27:14", "Lamentations 3:25", "Romans 12:12", "Micah 7:7"],
         line="Waiting through the holidays is its own kind of hard.",
         ask="Send this to someone who's been waiting a long time."),
]

# Paid-ad creative (see docs/seek-ads-plan.md). Copy follows Meta's
# personal-attributes policy: no "you are anxious / are you a Christian" claims.
ADS = [
    dict(id="ad01_racing_mind", palette="midnight", kicker="SCRIPTURE FOR 2AM",
         hook="For the nights\nthe mind won't\nslow down.",
         demo=["chat", "card"],
         captions=["Say what's on your heart.\nGet the verses for it.", "Turn any verse into a card."]),
    dict(id="ad02_words_wont_come", palette="purple", kicker="FOR THE HARD DAYS",
         hook="Prayer, when\nthe words\nwon't come.",
         demo=["chat", "card"],
         captions=["Say it plainly.\nSeek finds scripture for it.", "Keep the one that meets you."]),
    dict(id="ad03_before_news", palette="peach", kicker="A BETTER MORNING",
         hook="One verse\nbefore\nthe news.",
         demo=["home", "card"],
         captions=["A verse waiting\nevery morning.", "Make it a card. Share it."]),
    dict(id="ad04_foggy", palette="green", kicker="WHEN THE FUTURE IS FOGGY",
         hook="You don't\nneed the\nwhole map.",
         verse="Jeremiah 29:11", demo=[], captions=[]),
]

HASHTAGS = ("#dailyverse #verseoftheday #bibleverse #scriptureoftheday #faithoverfear "
            "#christianquotes #godisgood #christianliving #dailydevotional #walkbyfaith "
            "#scripturecards #biblescripture")
CTA = "Seek finds scripture for whatever you're carrying. Free on iPhone & Android, link in bio."
