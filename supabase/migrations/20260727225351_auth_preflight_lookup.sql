-- Lookup used by the `auth-preflight` Edge Function so the app can tell a user
-- the truth about their account instead of always claiming a reset email was
-- sent. Returns only what the sign-in screen needs to branch on: does the
-- account exist, and does it have a password.
--
-- SECURITY DEFINER because auth.users is not reachable by postgrest roles.
-- EXECUTE is revoked from anon/authenticated so this is callable ONLY with the
-- service-role key (i.e. only from the Edge Function). It must never become a
-- public user-enumeration endpoint.
create or replace function public.auth_preflight_lookup(p_email text)
returns json
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_user auth.users%rowtype;
begin
  select * into v_user
  from auth.users
  where lower(email) = lower(trim(p_email))
    and deleted_at is null
  limit 1;

  if not found then
    return json_build_object('exists', false);
  end if;

  return json_build_object(
    'exists', true,
    'has_password', (v_user.encrypted_password is not null
                     and v_user.encrypted_password <> ''),
    'providers', coalesce(v_user.raw_app_meta_data -> 'providers', '[]'::jsonb),
    'email_confirmed', (v_user.email_confirmed_at is not null)
  );
end;
$$;

revoke all on function public.auth_preflight_lookup(text) from public;
revoke all on function public.auth_preflight_lookup(text) from anon;
revoke all on function public.auth_preflight_lookup(text) from authenticated;
grant execute on function public.auth_preflight_lookup(text) to service_role;

comment on function public.auth_preflight_lookup(text) is
  'Service-role only. Backs the auth-preflight Edge Function so password reset can distinguish OAuth-only accounts (no password) from real reset candidates. Do not grant to anon/authenticated.';
