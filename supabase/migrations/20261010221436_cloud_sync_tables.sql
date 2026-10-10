-- Cloud sync for user content (cards, favorite verses, saved prayers, chat history).
-- Until now all of it lived only on-device (SwiftData / Room), so a reinstall or a
-- new phone wiped it permanently. These tables mirror the local models 1:1 and are
-- shared by iOS and Android, so content follows the account across platforms.
--
-- Sync model (see docs/cloud-sync.md):
--   * ids are client-generated UUIDs (the same id the local row already has)
--   * push = upsert dirty rows; deletes are soft (deleted_at) so other devices learn them
--   * pull = rows where updated_at > cursor; updated_at is always stamped server-side
--     with clock_timestamp() so a client clock can't move another device's cursor
--   * rows cascade away with auth.users, so delete-account removes everything

create or replace function public.sync_touch_updated_at()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.updated_at := clock_timestamp();
  return new;
end;
$$;

-- ---------------------------------------------------------------- saved_cards
create table public.saved_cards (
  id              uuid primary key,
  user_id         uuid not null default auth.uid() references auth.users(id) on delete cascade,
  verse_reference text not null,
  verse_text      text not null check (length(verse_text) <= 20000),
  template_id     text not null,
  is_favorite     boolean not null default false,
  context_note    text check (length(context_note) <= 20000),
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default clock_timestamp(),
  deleted_at      timestamptz
);

-- ----------------------------------------------------------- favorite_verses
create table public.favorite_verses (
  id         uuid primary key,
  user_id    uuid not null default auth.uid() references auth.users(id) on delete cascade,
  reference  text not null,
  text       text not null check (length(text) <= 20000),
  source     text not null default 'chat',
  saved_at   timestamptz not null default now(),
  updated_at timestamptz not null default clock_timestamp(),
  deleted_at timestamptz
);

-- ------------------------------------------------------------- saved_prayers
create table public.saved_prayers (
  id           uuid primary key,
  user_id      uuid not null default auth.uid() references auth.users(id) on delete cascade,
  text         text not null check (length(text) <= 20000),
  source       text not null default 'chat',
  context_note text check (length(context_note) <= 20000),
  saved_at     timestamptz not null default now(),
  updated_at   timestamptz not null default clock_timestamp(),
  deleted_at   timestamptz
);

-- -------------------------------------------------------- chat_conversations
create table public.chat_conversations (
  id         uuid primary key,
  user_id    uuid not null default auth.uid() references auth.users(id) on delete cascade,
  summary    text check (length(summary) <= 2000),
  started_at timestamptz not null default now(),
  updated_at timestamptz not null default clock_timestamp(),
  deleted_at timestamptz
);

-- ------------------------------------------------------------- chat_messages
-- Clients push conversations before messages so the FK is always satisfied.
create table public.chat_messages (
  id              uuid primary key,
  user_id         uuid not null default auth.uid() references auth.users(id) on delete cascade,
  conversation_id uuid not null references public.chat_conversations(id) on delete cascade,
  role            text not null check (role in ('user', 'assistant')),
  content         text not null check (length(content) <= 100000), -- user text or assistant JSON
  sent_at         timestamptz not null default now(),
  updated_at      timestamptz not null default clock_timestamp(),
  deleted_at      timestamptz
);

-- ---------------------------------------------------- shared: index, trigger, RLS
do $$
declare t text;
begin
  foreach t in array array['saved_cards','favorite_verses','saved_prayers','chat_conversations','chat_messages'] loop
    execute format('create index %1$s_user_updated_idx on public.%1$s (user_id, updated_at)', t);
    execute format('create trigger %1$s_touch before insert or update on public.%1$s
                    for each row execute function public.sync_touch_updated_at()', t);
    execute format('alter table public.%1$s enable row level security', t);
    execute format('create policy "own rows: select" on public.%1$s for select to authenticated
                    using ((select auth.uid()) = user_id)', t);
    execute format('create policy "own rows: insert" on public.%1$s for insert to authenticated
                    with check ((select auth.uid()) = user_id)', t);
    execute format('create policy "own rows: update" on public.%1$s for update to authenticated
                    using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id)', t);
    execute format('create policy "own rows: delete" on public.%1$s for delete to authenticated
                    using ((select auth.uid()) = user_id)', t);
    execute format('revoke all on public.%1$s from anon', t);
    execute format('grant select, insert, update, delete on public.%1$s to authenticated', t);
  end loop;
end $$;

create index chat_messages_conversation_idx on public.chat_messages (conversation_id);
