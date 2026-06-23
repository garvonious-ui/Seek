-- Read-only public view of the IG post queue, backing the shareable schedule page
-- (marketing/instagram/share). Exposes only non-sensitive columns; granted to anon
-- (SELECT only — no writes). The base table keeps its RLS; anon can read this view.
create or replace view public.ig_schedule_public as
  select id, day_index, scheduled_for, media_type, media_path, media_paths, caption, status
  from public.ig_post_queue;
grant select on public.ig_schedule_public to anon;
