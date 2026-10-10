# Cloud Sync

Backs up saved cards, favorite verses, saved prayers and chat history to Supabase so
they survive a reinstall or a new phone, and follow the account between iOS and
Android. Local storage (SwiftData / Room) is still what the UI reads; Supabase is the
copy that restores it.

- iOS: `Seek/Services/SyncService.swift`
- Android: `android/.../data/SyncRepository.kt` + `data/local/SyncDao.kt` (Room v2, `MIGRATION_1_2`)
- Server: migration `20261010221436_cloud_sync_tables.sql`

## Tables
`saved_cards`, `favorite_verses`, `saved_prayers`, `chat_conversations`, `chat_messages`
(columns in `schemas.md`). All share:
- `id uuid` = the local row's id (client-generated), `user_id` defaults to `auth.uid()`
- `updated_at` stamped by trigger with `clock_timestamp()` on every insert/update — the
  pull cursor; clients never send it
- `deleted_at` = soft delete, set only by tombstone pushes
- RLS: authenticated users read/write only their own rows; anon has no access
- `on delete cascade` from `auth.users`, so Delete Account removes everything

## Algorithm
**Push** (dirty rows → server)
1. Upsert rows with `needsSync = true`, conversations before messages (FK), 100 per
   request, then mark them clean.
2. For each tombstone (a local delete), set `deleted_at = now()` on the remote row,
   then drop the tombstone.

**Pull** (server → device), per table, after push:
- `updated_at > cursor − 2 min`, ordered by `updated_at`, 500 per page. The overlap
  catches rows committed out of order; applying a row twice is harmless.
- `deleted_at` set → delete locally. Otherwise insert if missing; update only if the
  local copy isn't dirty (local wins until its push lands). Messages, favorites and
  prayers are immutable, so they're insert-only.
- Cursor = newest `updated_at` seen, stored per user + table (UserDefaults
  `sync.cursor.*` / SharedPreferences `seek_sync`).

Push never sends `updated_at` / `deleted_at`, so a stale device can't un-delete a row.

## When it runs
- Sign-in and cold start with a saved session → full sync (this is the restore)
- App foreground, connection regained → debounced sync
- After every local write/delete → debounced (1.5 s) sync
- A failed sync leaves dirty flags/tombstones in place; the next trigger retries

## Sign-out and account switches
- Sign-out runs a final sync. If anything is still unpushed (offline), the user is
  warned ("Not backed up yet" → Stay Signed In / Sign Out Anyway). Then the device's
  library and cursors are cleared; the next sign-in restores from the cloud.
- The first account to sync on a device adopts whatever is local (existing users, guest
  favorites). If a *different* account later finds data owned by someone else on the
  device (only possible with leftovers from a pre-sync build), it's dropped rather than
  uploaded into the wrong account.

## Gotchas
- SwiftData: `needsSync` needs its declaration-level default (`= true`) for lightweight
  migration. Existing rows come up dirty — that's what uploads them on the first sync.
- Room: pull writes use `@Upsert`, never `REPLACE`. REPLACE is delete+insert, and the
  `chat_message` FK would cascade-delete a conversation's messages.
- Bare `modelContext.delete` / DAO deletes skip the tombstone, so the row comes back on
  the next pull. Delete synced rows through `SyncService.delete(...)` /
  `SyncRepository.delete*`.
- The privacy policy, the support FAQ and the App Store / Play data-safety answers say
  chat history and saved items are backed up. Keep them in step with this file.
