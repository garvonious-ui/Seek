-- ============================================================================
-- Feature reels → content calendar wiring  [APPLIED LIVE 2026-06-17]
-- ----------------------------------------------------------------------------
-- Four app-demo reels (marketing/instagram/feature-reels/, uploaded to
-- ig-media/reelsa/) occupy the upcoming product slots. Day 1 had already
-- POSTED when these were wired, so the reels land on days 7/13/19/29 instead.
-- Each day's REELS feed row gets the reel + caption; the morning repost STORY
-- (11:10) reuses the same reel video; the evening verse-card STORY (23:10) is
-- left untouched. This is the exact SQL applied to the live ig_post_queue.
-- ============================================================================

-- Day 7 — Card creator flip
update public.ig_post_queue set media_path='reelsa/seek_cardflip_reel.mp4', media_paths=NULL,
  caption='One verse. Eighteen ways to make it yours. 🤍

Pick the words, pick the look, send it to someone who needs it today. All free in Seek.

Link in bio.

.
.
#bibleapp #faithtech #christianapp #scriptureart #versecard #prayerlife #quiettime #morningdevotion #faithjourney #seekapp #digitaldiscipleship #christiancreators'
where day_index=7 and media_type='REELS';

-- Day 13 — Daily verse + streak
update public.ig_post_queue set media_path='reelsa/seek_streak_reel.mp4', media_paths=NULL,
  caption='One true thing, before the noise gets in. 🔥

A verse every morning and a streak that quietly builds the habit — Seek makes it a rhythm, not a chore.

Free. Link in bio.

.
.
#bibleapp #faithtech #christianapp #scriptureart #versecard #prayerlife #quiettime #morningdevotion #faithjourney #seekapp #digitaldiscipleship #christiancreators'
where day_index=13 and media_type='REELS';

-- Day 19 — Worship-song spotlight
update public.ig_post_queue set media_path='reelsa/seek_worship_reel.mp4', media_paths=NULL,
  caption='More than a verse — a song to carry it. 🤍

Seek pairs scripture for your moment with worship to match, ready to open in Apple Music or Spotify.

Free on the App Store. Link in bio.

.
.
#bibleapp #faithtech #christianapp #scriptureart #versecard #prayerlife #quiettime #morningdevotion #faithjourney #seekapp #digitaldiscipleship #christiancreators'
where day_index=19 and media_type='REELS';

-- Day 29 — Chat answer demo (the core product moment; day-1 slot was already posted)
update public.ig_post_queue set media_path='reelsa/seek_chat_reel.mp4', media_paths=NULL,
  caption='Tell Seek what''s actually on your heart — and get real scripture back.

Anxious, grateful, lost, hopeful — say it plainly, and Seek meets you there with verses, a prayer, and a song to match.

Free on the App Store. Link in bio. 🤍

.
.
#bibleapp #faithtech #christianapp #scriptureart #versecard #prayerlife #quiettime #morningdevotion #faithjourney #seekapp #digitaldiscipleship #christiancreators'
where day_index=29 and media_type='REELS';

-- Morning repost stories on those days reuse the new feed reel video:
update public.ig_post_queue set media_path='reelsa/seek_cardflip_reel.mp4' where day_index=7  and media_type='STORIES' and extract(hour from scheduled_for)=11;
update public.ig_post_queue set media_path='reelsa/seek_streak_reel.mp4'   where day_index=13 and media_type='STORIES' and extract(hour from scheduled_for)=11;
update public.ig_post_queue set media_path='reelsa/seek_worship_reel.mp4'  where day_index=19 and media_type='STORIES' and extract(hour from scheduled_for)=11;
update public.ig_post_queue set media_path='reelsa/seek_chat_reel.mp4'     where day_index=29 and media_type='STORIES' and extract(hour from scheduled_for)=11;
