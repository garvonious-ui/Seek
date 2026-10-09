-- Seed ig_post_queue with the 30-day Seek campaign.
-- scheduled_for = 7:00 AM America/New_York (stored UTC; June–July 2026 = EDT = UTC-4 = 11:00Z).
-- Adjust the start date by editing gen_captions_seed.py and regenerating, or shift in SQL.
-- All rows start 'pending' — approve each in the admin page before it posts.

insert into public.ig_post_queue
  (day_index, scheduled_for, media_type, media_path, caption, status)
values
  (1, '2026-06-17 11:00:00+00', 'IMAGE', 'cards/card_01.png', 'New week. New mercies. They show up every morning whether you feel them or not.

You don''t have to drag last week into this one. The slate isn''t just wiped clean — it''s refilled. Daily. No streak required.

— Lamentations 3:22-23, NLT

Save this for Monday-you.

.
.
#dailyverse #verseoftheday #bibleverse #scriptureoftheday #faithoverfear #christianquotes #godisgood #christianliving #dailydevotional #walkbyfaith #scripturecards #biblescripture', 'pending'),
  (2, '2026-06-18 11:00:00+00', 'REELS', 'reels/reel_02.mp4', 'What if you could just say what''s actually on your heart — the anxiety, the gratitude, the questions you don''t say out loud — and get real scripture back?

That''s Seek. Tell it where you are, and it meets you there with verses, a prayer, and a song.

Free on the App Store. Link in bio. 🤍

.
.
#bibleapp #faithtech #christianapp #scriptureart #versecard #prayerlife #quiettime #morningdevotion #faithjourney #seekapp #digitaldiscipleship #christiancreators', 'pending'),
  (3, '2026-06-19 11:00:00+00', 'IMAGE', 'cards/card_03.png', 'Stop trying to map the whole road. Trust the next step.

You were never promised the full picture — just enough light for the step in front of you. That''s not less. That''s an invitation to trust.

— Proverbs 3:5-6, NLT

What decision are you overthinking right now? 👇

.
.
#dailyverse #verseoftheday #bibleverse #scriptureoftheday #faithoverfear #christianquotes #godisgood #christianliving #dailydevotional #walkbyfaith #scripturecards #biblescripture', 'pending'),
  (4, '2026-06-20 11:00:00+00', 'REELS', 'reels/reel_04.mp4', 'For the 2am spiral. Read this slowly.

Worry says "carry it all, right now, alone." This says the opposite: hand it over, one honest sentence at a time, and let a peace you can''t explain stand guard over your mind.

— Philippians 4:6-7, NLT

Send this to someone who isn''t sleeping tonight.

.
.
#dailyverse #verseoftheday #bibleverse #scriptureoftheday #faithoverfear #christianquotes #godisgood #christianliving #dailydevotional #walkbyfaith #scripturecards #biblescripture', 'pending'),
  (5, '2026-06-21 11:00:00+00', 'IMAGE', 'cards/card_05.png', 'Name one thing. Out loud. Right now.

Gratitude isn''t pretending it''s all fine. It''s finding the one true good thing in today and saying it on purpose — even through gritted teeth some days.

— 1 Thessalonians 5:18, NLT

Drop your one thing below. 👇

.
.
#dailyverse #verseoftheday #bibleverse #scriptureoftheday #faithoverfear #christianquotes #godisgood #christianliving #dailydevotional #walkbyfaith #scripturecards #biblescripture', 'pending'),
  (6, '2026-06-22 11:00:00+00', 'IMAGE', 'cards/card_06.png', 'Saturday song: pair this verse with something loud in your headphones.

There''s a kind of joy that doesn''t stay quiet. Let today be a little louder than your week was.

— Psalm 95:1, NLT

What''s the song? Tell me below. 🎧

.
.
#dailyverse #verseoftheday #bibleverse #scriptureoftheday #faithoverfear #christianquotes #godisgood #christianliving #dailydevotional #walkbyfaith #scripturecards #biblescripture', 'pending'),
  (7, '2026-06-23 11:00:00+00', 'IMAGE', 'cards/card_07.png', 'You''re allowed to put it down today.

Rest isn''t a reward you earn after you''ve done enough. It''s an invitation — already open, already yours. Especially on the Sundays you feel furthest from it.

— Matthew 11:28, NLT

Save this for a heavy day.

.
.
#dailyverse #verseoftheday #bibleverse #scriptureoftheday #faithoverfear #christianquotes #godisgood #christianliving #dailydevotional #walkbyfaith #scripturecards #biblescripture', 'pending'),
  (8, '2026-06-24 11:00:00+00', 'IMAGE', 'cards/card_08.png', 'Whatever this week asks of you — you don''t walk in alone.

Courage isn''t the absence of fear. It''s moving forward anyway, because the One who told you to go is already there.

— Joshua 1:9, NLT

.
.
#dailyverse #verseoftheday #bibleverse #scriptureoftheday #faithoverfear #christianquotes #godisgood #christianliving #dailydevotional #walkbyfaith #scripturecards #biblescripture', 'pending'),
  (9, '2026-06-25 11:00:00+00', 'REELS', 'reels/reel_09.mp4', 'Turn any verse into a card you''ll actually want to share. 15 seconds, start to finish. 🤍

Pick the words, pick the look, send it to someone who needs it today. All free in Seek.

Link in bio.

— Psalm 46:10, NLT

.
.
#bibleapp #faithtech #christianapp #scriptureart #versecard #prayerlife #quiettime #morningdevotion #faithjourney #seekapp #digitaldiscipleship #christiancreators', 'pending'),
  (10, '2026-06-26 11:00:00+00', 'IMAGE', 'cards/card_10.png', 'Don''t have the answer? You''re allowed to ask for it.

There''s no eye-roll waiting on the other side of your questions. Wisdom gets handed out generously, to anyone honest enough to admit they need it.

— James 1:5, NLT

.
.
#dailyverse #verseoftheday #bibleverse #scriptureoftheday #faithoverfear #christianquotes #godisgood #christianliving #dailydevotional #walkbyfaith #scripturecards #biblescripture', 'pending'),
  (11, '2026-06-27 11:00:00+00', 'REELS', 'reels/reel_11.mp4', '"I believe — help my unbelief." Maybe the most honest prayer in the whole Bible.

You don''t need airtight faith to start. You just need to be honest about the faith you''ve got. That''s enough to be met.

— Mark 9:24, NLT

Share this with someone in the in-between.

.
.
#dailyverse #verseoftheday #bibleverse #scriptureoftheday #faithoverfear #christianquotes #godisgood #christianliving #dailydevotional #walkbyfaith #scripturecards #biblescripture', 'pending'),
  (12, '2026-06-28 11:00:00+00', 'IMAGE', 'cards/card_12.png', 'Joy isn''t the absence of hard things. It''s a presence.

Not a mood you have to manufacture — a Person you get to be near. The path forward isn''t empty. It''s full.

— Psalm 16:11, NLT

.
.
#dailyverse #verseoftheday #bibleverse #scriptureoftheday #faithoverfear #christianquotes #godisgood #christianliving #dailydevotional #walkbyfaith #scripturecards #biblescripture', 'pending'),
  (13, '2026-06-29 11:00:00+00', 'IMAGE', 'cards/card_13.png', 'Saturday reset: walk in grateful before you walk in anything else.

Thanksgiving isn''t the last step after everything goes right. It''s the front door.

— Psalm 100:4, NLT

Pair it with a worship song today. 🎧

.
.
#dailyverse #verseoftheday #bibleverse #scriptureoftheday #faithoverfear #christianquotes #godisgood #christianliving #dailydevotional #walkbyfaith #scripturecards #biblescripture', 'pending'),
  (14, '2026-06-30 11:00:00+00', 'IMAGE', 'cards/card_14.png', 'A different kind of peace than the world hands out.

The world''s peace depends on everything going right. This one doesn''t. It holds even when the circumstances don''t.

— John 14:27, NLT

Save this for Sunday-night nerves.

.
.
#dailyverse #verseoftheday #bibleverse #scriptureoftheday #faithoverfear #christianquotes #godisgood #christianliving #dailydevotional #walkbyfaith #scripturecards #biblescripture', 'pending'),
  (15, '2026-07-01 11:00:00+00', 'IMAGE', 'cards/card_15.png', 'Don''t quit in the season right before it grows.

The harvest has a clock you can''t see. Tired is not the same as finished. Keep going.

— Galatians 6:9, NLT

Tag someone who needs to hear this today.

.
.
#dailyverse #verseoftheday #bibleverse #scriptureoftheday #faithoverfear #christianquotes #godisgood #christianliving #dailydevotional #walkbyfaith #scripturecards #biblescripture', 'pending'),
  (16, '2026-07-02 11:00:00+00', 'REELS', 'reels/reel_16.mp4', 'A verse a day + a streak that actually builds the habit. Here''s what day 30 looks like. 🔥

Start your morning with one true thing before the noise gets in. Seek makes it a rhythm you''ll keep.

Free. Link in bio.

— Psalm 143:8, NLT

.
.
#bibleapp #faithtech #christianapp #scriptureart #versecard #prayerlife #quiettime #morningdevotion #faithjourney #seekapp #digitaldiscipleship #christiancreators', 'pending'),
  (17, '2026-07-03 11:00:00+00', 'IMAGE', 'cards/card_17.png', 'Read it like it''s about you. Because it is.

Not a generic compliment — a craftsman''s pride over a specific, complicated, one-of-a-kind work. That''s you.

— Psalm 139:14, NLT

Someone needs this today. Send it.

.
.
#dailyverse #verseoftheday #bibleverse #scriptureoftheday #faithoverfear #christianquotes #godisgood #christianliving #dailydevotional #walkbyfaith #scripturecards #biblescripture', 'pending'),
  (18, '2026-07-04 11:00:00+00', 'REELS', 'reels/reel_18.mp4', 'For when the room is full and you still feel alone.

Loneliness lies and says you''re the exception — the one nobody''s with. This says you were gone-ahead-of and never left. Both at once.

— Deuteronomy 31:8, NLT

Save it for a long night.

.
.
#dailyverse #verseoftheday #bibleverse #scriptureoftheday #faithoverfear #christianquotes #godisgood #christianliving #dailydevotional #walkbyfaith #scripturecards #biblescripture', 'pending'),
  (19, '2026-07-05 11:00:00+00', 'IMAGE', 'cards/card_19.png', 'This day. This one. It counts.

Not the highlight-reel day, not the one you''re waiting for. Today — ordinary, unfinished — is the one you actually get. So get it.

— Psalm 118:24, NLT

.
.
#dailyverse #verseoftheday #bibleverse #scriptureoftheday #faithoverfear #christianquotes #godisgood #christianliving #dailydevotional #walkbyfaith #scripturecards #biblescripture', 'pending'),
  (20, '2026-07-06 11:00:00+00', 'IMAGE', 'cards/card_20.png', 'He''s singing over you. Let that reframe your Saturday.

Not tolerating you. Not disappointed. Delighting — out loud, like a song. Sit in that one for a second.

— Zephaniah 3:17, NLT

Worship song in the comments? 🎧

.
.
#dailyverse #verseoftheday #bibleverse #scriptureoftheday #faithoverfear #christianquotes #godisgood #christianliving #dailydevotional #walkbyfaith #scripturecards #biblescripture', 'pending'),
  (21, '2026-07-07 11:00:00+00', 'IMAGE', 'cards/card_21.png', 'Hand it over. You were never meant to carry it.

The weight you''ve been white-knuckling all week? There''s an open hand asking for it — not to judge it, because you''re cared about.

— 1 Peter 5:7, NLT

Save this for the next heavy Sunday.

.
.
#dailyverse #verseoftheday #bibleverse #scriptureoftheday #faithoverfear #christianquotes #godisgood #christianliving #dailydevotional #walkbyfaith #scripturecards #biblescripture', 'pending'),
  (22, '2026-07-08 11:00:00+00', 'IMAGE', 'cards/card_22.png', 'Plans you can''t see yet are still plans.

Uncertain doesn''t mean unplanned. The fog in front of you isn''t the absence of a future — it''s just the part you can''t read yet.

— Jeremiah 29:11, NLT

.
.
#dailyverse #verseoftheday #bibleverse #scriptureoftheday #faithoverfear #christianquotes #godisgood #christianliving #dailydevotional #walkbyfaith #scripturecards #biblescripture', 'pending'),
  (23, '2026-07-09 11:00:00+00', 'REELS', 'reels/reel_23.mp4', 'When you don''t have the words, Seek writes the prayer with you. Watch. 🤍

No performance, no formula. Just an honest place to start when your own words run out.

Free on the App Store. Link in bio.

— Matthew 6:6, NLT

.
.
#bibleapp #faithtech #christianapp #scriptureart #versecard #prayerlife #quiettime #morningdevotion #faithjourney #seekapp #digitaldiscipleship #christiancreators', 'pending'),
  (24, '2026-07-10 11:00:00+00', 'IMAGE', 'cards/card_24.png', 'Waiting isn''t wasted. It''s where strength gets rebuilt.

The waiting room feels like nothing''s happening. It isn''t. That''s where the new strength is quietly being made.

— Isaiah 40:31, NLT

.
.
#dailyverse #verseoftheday #bibleverse #scriptureoftheday #faithoverfear #christianquotes #godisgood #christianliving #dailydevotional #walkbyfaith #scripturecards #biblescripture', 'pending'),
  (25, '2026-07-11 11:00:00+00', 'REELS', 'reels/reel_25.mp4', 'The scroll wants you anxious. Here''s the antidote.

Comparison runs on one question: "am I enough for them?" Freedom comes from a better one: "who am I actually living for?"

— Galatians 1:10, NLT

Save this for your next doom-scroll.

.
.
#dailyverse #verseoftheday #bibleverse #scriptureoftheday #faithoverfear #christianquotes #godisgood #christianliving #dailydevotional #walkbyfaith #scripturecards #biblescripture', 'pending'),
  (26, '2026-07-12 11:00:00+00', 'IMAGE', 'cards/card_26.png', 'The definition we keep forgetting.

Not a feeling that happens to you — a way of showing up that you choose. Read it slowly and notice which line you needed.

— 1 Corinthians 13:4-5, NLT

Send it to someone you love.

.
.
#dailyverse #verseoftheday #bibleverse #scriptureoftheday #faithoverfear #christianquotes #godisgood #christianliving #dailydevotional #walkbyfaith #scripturecards #biblescripture', 'pending'),
  (27, '2026-07-13 11:00:00+00', 'IMAGE', 'cards/card_27.png', 'Saturday: one song, full volume, no skipping.

If you''re breathing, you''re already qualified. That''s the whole requirement. So make a little noise today.

— Psalm 150:6, NLT

What''s on repeat this week? 🎧

.
.
#dailyverse #verseoftheday #bibleverse #scriptureoftheday #faithoverfear #christianquotes #godisgood #christianliving #dailydevotional #walkbyfaith #scripturecards #biblescripture', 'pending'),
  (28, '2026-07-14 11:00:00+00', 'IMAGE', 'cards/card_28.png', 'Let yourself be led somewhere quiet today.

You don''t have to find the still water on your own. You just have to follow. Rest is the assignment today.

— Psalm 23:1-3, NLT

Save this for a restless Sunday.

.
.
#dailyverse #verseoftheday #bibleverse #scriptureoftheday #faithoverfear #christianquotes #godisgood #christianliving #dailydevotional #walkbyfaith #scripturecards #biblescripture', 'pending'),
  (29, '2026-07-15 11:00:00+00', 'IMAGE', 'cards/card_29.png', 'Whatever Monday brings — fear doesn''t get the final word.

Notice it''s not "figure it out yourself." It''s "I''ve got you, I''m holding you up." Walk in held.

— Isaiah 41:10, NLT

.
.
#dailyverse #verseoftheday #bibleverse #scriptureoftheday #faithoverfear #christianquotes #godisgood #christianliving #dailydevotional #walkbyfaith #scripturecards #biblescripture', 'pending'),
  (30, '2026-07-16 11:00:00+00', 'REELS', 'reels/reel_30.mp4', '30 days of showing up. 🤍

If even one of these met you where you actually were this month — that''s the whole point. Seek is free, and it''s here for the next 30 too.

Link in bio.

— Psalm 19:14, NLT

.
.
#bibleapp #faithtech #christianapp #scriptureart #versecard #prayerlife #quiettime #morningdevotion #faithjourney #seekapp #digitaldiscipleship #christiancreators', 'pending');
