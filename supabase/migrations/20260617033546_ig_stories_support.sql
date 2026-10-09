alter table public.ig_post_queue drop constraint if exists ig_post_queue_media_type_check;
alter table public.ig_post_queue add constraint ig_post_queue_media_type_check
  check (media_type in ('IMAGE','REELS','CAROUSEL','STORIES'));
