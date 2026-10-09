-- Cron jobs can't read ALTER DATABASE GUCs without superuser, so config lives in a table.
create table if not exists public.app_config (
  key   text primary key,
  value text not null
);
alter table public.app_config enable row level security;  -- service_role / postgres only

-- Reschedule both jobs to read URL + secret from app_config.
select cron.unschedule('ig-autopost');
select cron.unschedule('ig-token-refresh');

select cron.schedule(
  'ig-autopost',
  '*/15 * * * *',
  $$
  select net.http_post(
    url     := (select value from public.app_config where key = 'ig_publish_url'),
    headers := jsonb_build_object(
                 'Content-Type','application/json',
                 'Authorization','Bearer ' || (select value from public.app_config where key = 'ig_cron_secret')),
    body    := '{}'::jsonb
  );
  $$
);

select cron.schedule(
  'ig-token-refresh',
  '0 8 * * 1',
  $$
  select net.http_post(
    url     := (select value from public.app_config where key = 'ig_token_refresh_url'),
    headers := jsonb_build_object(
                 'Content-Type','application/json',
                 'Authorization','Bearer ' || (select value from public.app_config where key = 'ig_cron_secret')),
    body    := '{}'::jsonb
  );
  $$
);
