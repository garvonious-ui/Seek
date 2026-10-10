-- Production alerting (health-alert Edge Function). See supabase/functions/health-alert.
-- Not yet applied: deploy the function and set ALERT_NTFY_TOPIC first.

-- Throttle log: one row per alert sent, so the same alert isn't re-sent every 15 min.
create table if not exists public.ops_alerts (
  id bigint generated always as identity primary key,
  alert_key text not null,
  message text not null,
  delivered boolean not null default false,
  sent_at timestamptz not null default now()
);
create index if not exists ops_alerts_key_sent_at on public.ops_alerts (alert_key, sent_at desc);
-- Service-role only, like the other ops tables.
alter table public.ops_alerts enable row level security;

insert into public.app_config (key, value)
values ('health_alert_url', 'https://hxfiaowayrhuhzhhbaix.supabase.co/functions/v1/health-alert')
on conflict (key) do update set value = excluded.value;

select cron.schedule(
  'health-alert',
  '*/15 * * * *',
  $$
  select net.http_post(
    url     := (select value from public.app_config where key = 'health_alert_url'),
    headers := jsonb_build_object(
                 'Content-Type','application/json',
                 'Authorization','Bearer ' || (select value from public.app_config where key = 'ig_cron_secret')),
    body    := '{}'::jsonb
  );
  $$
);
