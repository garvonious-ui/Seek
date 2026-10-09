-- Hardening flagged by the security advisor while working on auth:
-- handle_new_user is SECURITY DEFINER with a mutable search_path, and EXECUTE
-- was granted to anon/authenticated. Pin the search_path and revoke EXECUTE.
--
-- Safe: this is a trigger function. Postgres checks EXECUTE against the table
-- owner when firing a trigger, not against the session role, so revoking from
-- anon/authenticated cannot break signup. Body is unchanged.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $function$
BEGIN
  INSERT INTO profiles (id, email, display_name)
  VALUES (
    NEW.id,
    COALESCE(NEW.email, ''),
    COALESCE(NEW.raw_user_meta_data->>'full_name', '')
  )
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO notification_settings (id)
  VALUES (NEW.id)
  ON CONFLICT (id) DO NOTHING;

  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  RETURN NEW;
END;
$function$;

revoke all on function public.handle_new_user() from public, anon, authenticated;
