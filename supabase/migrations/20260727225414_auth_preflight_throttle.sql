-- Throttle for the auth-preflight endpoint. Pre-flight necessarily reveals
-- whether an email has an account, so it must not be cheaply scriptable.
-- Service-role only; the Edge Function is the sole writer.
create table if not exists public.auth_preflight_throttle (
  ip            text primary key,
  window_start  timestamptz not null default now(),
  attempts      int         not null default 0
);

alter table public.auth_preflight_throttle enable row level security;
-- No policies: RLS on with zero policies means anon/authenticated get nothing.
-- service_role bypasses RLS.

-- Returns true when the caller is allowed to proceed. 10 requests per IP per
-- 15-minute rolling window — generous for a human who mistyped their email,
-- useless for enumerating 157 accounts.
create or replace function public.auth_preflight_allow(p_ip text)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_row public.auth_preflight_throttle%rowtype;
  c_limit  constant int := 10;
  c_window constant interval := interval '15 minutes';
begin
  if p_ip is null or p_ip = '' then
    return true; -- cannot throttle what we cannot identify; fail open
  end if;

  insert into public.auth_preflight_throttle (ip, window_start, attempts)
  values (p_ip, now(), 1)
  on conflict (ip) do update
    set attempts = case
          when public.auth_preflight_throttle.window_start < now() - c_window then 1
          else public.auth_preflight_throttle.attempts + 1
        end,
        window_start = case
          when public.auth_preflight_throttle.window_start < now() - c_window then now()
          else public.auth_preflight_throttle.window_start
        end
  returning * into v_row;

  return v_row.attempts <= c_limit;
end;
$$;

revoke all on function public.auth_preflight_allow(text) from public, anon, authenticated;
grant execute on function public.auth_preflight_allow(text) to service_role;
