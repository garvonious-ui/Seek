-- ig_schedule_public is a postgres-owned view over ig_post_queue (no security_invoker),
-- so it bypasses the table's RLS. It was auto-updatable and anon/authenticated held
-- INSERT/UPDATE/DELETE: anyone with the public anon key could rewrite a caption,
-- set status='approved', and the ig-autopost cron would publish it.
-- The public schedule page only reads it; the admin dashboard writes ig_post_queue
-- directly with the service key. Keep SELECT, drop everything else.
revoke insert, update, delete, truncate, references, trigger
  on public.ig_schedule_public from anon, authenticated;
