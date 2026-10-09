-- Instagram auto-posting queue for the Seek content campaign.
create table if not exists public.ig_post_queue (
  id            uuid primary key default gen_random_uuid(),
  day_index     int  not null,
  scheduled_for timestamptz not null,
  media_type    text not null check (media_type in ('IMAGE','REELS')),
  media_path    text not null,
  caption       text not null,
  status        text not null default 'pending'
                  check (status in ('pending','approved','publishing','posted','failed')),
  container_id  text,
  ig_media_id   text,
  error         text,
  attempts      int  not null default 0,
  posted_at     timestamptz,
  created_at    timestamptz not null default now()
);

create index if not exists ig_post_queue_due_idx
  on public.ig_post_queue (status, scheduled_for);

alter table public.ig_post_queue enable row level security;

create table if not exists public.ig_config (
  id            int primary key default 1 check (id = 1),
  ig_user_id    text not null,
  access_token  text not null,
  token_updated_at timestamptz not null default now()
);
alter table public.ig_config enable row level security;

create extension if not exists pg_cron;
create extension if not exists pg_net;

select cron.schedule(
  'ig-autopost',
  '*/15 * * * *',
  $$
  select net.http_post(
    url     := current_setting('app.ig_publish_url'),
    headers := jsonb_build_object(
                 'Content-Type','application/json',
                 'Authorization','Bearer ' || current_setting('app.ig_cron_secret')),
    body    := '{}'::jsonb
  );
  $$
);

select cron.schedule(
  'ig-token-refresh',
  '0 8 * * 1',
  $$
  select net.http_post(
    url     := current_setting('app.ig_token_refresh_url'),
    headers := jsonb_build_object(
                 'Content-Type','application/json',
                 'Authorization','Bearer ' || current_setting('app.ig_cron_secret')),
    body    := '{}'::jsonb
  );
  $$
);
