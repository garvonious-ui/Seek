
create extension if not exists citext;

create table if not exists public.waitlist (
  id         bigserial primary key,
  email      citext      not null unique,
  source     text        not null default 'landing',
  created_at timestamptz not null default now()
);

alter table public.waitlist enable row level security;

-- Anon can INSERT only; we never expose the list.
-- Validate email format and length at the row level so garbage can't enter.
create policy "anon_insert_waitlist"
  on public.waitlist
  for insert
  to anon, authenticated
  with check (
    email is not null
    and length(email::text) <= 254
    and email::text ~* '^[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}$'
    and source = 'landing'
  );

-- Intentionally NO select/update/delete policy for anon.
-- Service role (via dashboard) retains full access.

comment on table public.waitlist is 'Pre-launch landing page signups. Anon can insert; only service role can read.';
