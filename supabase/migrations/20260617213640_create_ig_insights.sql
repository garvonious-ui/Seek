create table if not exists public.ig_insights (
  ig_media_id text primary key,
  queue_id uuid,
  day_index int,
  media_type text,
  permalink text,
  caption_hook text,
  reach int,
  views int,
  likes int,
  comments int,
  shares int,
  saved int,
  total_interactions int,
  replies int,
  posted_at timestamptz,
  fetched_at timestamptz default now(),
  raw jsonb
);
alter table public.ig_insights enable row level security;  -- service-role only, no policies

create table if not exists public.ig_account_insights (
  snapshot_date date primary key,
  followers_count int,
  media_count int,
  reach int,
  fetched_at timestamptz default now()
);
alter table public.ig_account_insights enable row level security; -- service-role only

create index if not exists ig_insights_day_idx on public.ig_insights(day_index);
