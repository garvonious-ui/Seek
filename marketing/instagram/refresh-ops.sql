-- Content refresh ops, Nov 2026. Run in the Seek project SQL editor, top to bottom.
-- Nothing here deletes rows. Old rows are set to 'cancelled' (allowed by the
-- ig_queue_add_cancelled_status migration) so they can be restored.

-- 1. Pause the weekly auto-refill so it doesn't add recycled daily reels on
--    top of the 5/week test. Re-enable at the end (step 6).
select jobid, jobname, schedule, active from cron.job where jobname in ('ig-replenish-weekly', 'ig-approve-stories');
select cron.alter_job(jobid, active := false) from cron.job where jobname = 'ig-replenish-weekly';

-- Note: 'ig-approve-stories' stays on. It auto-approves upcoming pending
-- STORIES rows, which includes the two carousel-cover stories in weeks 3-4.

-- 2. Preview what's already queued from Thanksgiving on. Anything here would
--    post alongside the refresh and muddy the time test.
select id, day_index, scheduled_for, media_type, media_path, status
from ig_post_queue
where scheduled_for >= '2026-11-26'
  and status in ('pending', 'approved')
  and media_path not like 'reels-refresh/%'
  and media_path not like 'carousels-refresh/%'
order by scheduled_for;

-- 3. Cancel those rows (only after reading step 2).
-- update ig_post_queue set status = 'cancelled'
-- where scheduled_for >= '2026-11-26'
--   and status in ('pending', 'approved')
--   and media_path not like 'reels-refresh/%'
--   and media_path not like 'carousels-refresh/%';

-- 4. Upload media to the ig-media bucket (dashboard > Storage > ig-media),
--    keeping folder names: reels-refresh/*.mp4 and carousels-refresh/<id>/*.png.
--    Then run seed-refresh-weeks1-2.sql. Approve week 1 in the dashboard.

-- 5. After Dec 11 (week 2 done): read results, pick AM or PM, then
--    python3 seed_refresh_calendar.py am   (or pm)
--    and run seed-refresh-weeks3-4.sql.

-- 6. After Dec 25: turn the auto-refill back on (or leave it off and keep
--    seeding by hand from refresh_slate.py).
-- select cron.alter_job(jobid, active := true) from cron.job where jobname = 'ig-replenish-weekly';

-- Results query for the time test (needs the ig-insights job to have run).
select q.scheduled_for at time zone 'America/New_York' as posted_et,
       q.media_path, i.*
from ig_post_queue q
left join ig_insights i on i.ig_media_id = q.ig_media_id
where q.media_path like 'reels-refresh/%'
order by q.scheduled_for;
