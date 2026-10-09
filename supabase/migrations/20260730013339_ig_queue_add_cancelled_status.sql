alter table public.ig_post_queue drop constraint if exists ig_post_queue_status_check;
alter table public.ig_post_queue add constraint ig_post_queue_status_check
  check (status = any (array['pending','approved','publishing','posted','failed','cancelled']));
