-- v2: throttle on an arbitrary key with a caller-supplied limit, so the Edge
-- Function can apply two different budgets.
--
-- Why: v1 keyed on IP alone at 10/15min. Seek is a mobile app, so many users sit
-- behind the same carrier-grade NAT egress IP — a single shared IP could lock
-- out real people, while an attacker rotating through proxies sails past it
-- (observed directly while testing: one client presented three egress IPs).
-- Per-email is the meaningful limit for a human resetting their own password;
-- per-IP stays as a much looser backstop against scripted sweeps.

alter table public.auth_preflight_throttle rename to auth_preflight_throttle_v1;

create table if not exists public.auth_preflight_throttle (
  key           text primary key,   -- 'ip:1.2.3.4' or 'email:sha of address'
  window_start  timestamptz not null default now(),
  attempts      int         not null default 0
);
alter table public.auth_preflight_throttle enable row level security;
-- RLS on, no policies: anon/authenticated get nothing; service_role bypasses.

drop function if exists public.auth_preflight_allow(text);

create or replace function public.auth_preflight_allow(p_key text, p_limit int)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_row public.auth_preflight_throttle%rowtype;
  c_window constant interval := interval '15 minutes';
begin
  if p_key is null or p_key = '' then
    return true; -- cannot throttle what we cannot identify; fail open
  end if;

  insert into public.auth_preflight_throttle (key, window_start, attempts)
  values (p_key, now(), 1)
  on conflict (key) do update
    set attempts = case
          when public.auth_preflight_throttle.window_start < now() - c_window then 1
          else public.auth_preflight_throttle.attempts + 1
        end,
        window_start = case
          when public.auth_preflight_throttle.window_start < now() - c_window then now()
          else public.auth_preflight_throttle.window_start
        end
  returning * into v_row;

  return v_row.attempts <= p_limit;
end;
$$;

revoke all on function public.auth_preflight_allow(text, int) from public, anon, authenticated;
grant execute on function public.auth_preflight_allow(text, int) to service_role;

comment on function public.auth_preflight_allow(text, int) is
  'Service-role only. Rolling 15-minute counter for auth-preflight. Called twice per request: email key (tight) and IP key (loose, NAT-tolerant).';
