# Data Schemas

## SwiftData Models (Local)

### UserProfile
| Field | Type | Notes |
|-------|------|-------|
| id | String | Supabase Auth UID, @unique |
| displayName | String | |
| email | String | |
| profileImageURL | String? | |
| createdAt | Date | |
| isPremium | Bool | |
| premiumExpiresAt | Date? | |
| onboardingTopics | [String] | Selected during onboarding |
| streakCount | Int | |
| longestStreak | Int | |
| lastActiveDate | Date? | For streak calculation |
| totalVersesExplored | Int | |
| totalCardsCreated | Int | |
| dailyChatsUsed | Int | |
| dailyChatsResetDate | Date | Midnight local |

### SavedCard
| Field | Type | Notes |
|-------|------|-------|
| id | UUID | @unique |
| verseReference | String | e.g. "Philippians 4:6-7" |
| verseText | String | |
| templateID | String | Which card template |
| createdAt | Date | |
| isFavorite | Bool | |
| contextNote | String? | Situation that prompted this verse |

### ChatConversation
| Field | Type | Notes |
|-------|------|-------|
| id | UUID | @unique |
| startedAt | Date | |
| messages | [ChatMessage] | Relationship, cascade delete |
| summary | String? | First user message as summary |

### ChatMessage
| Field | Type | Notes |
|-------|------|-------|
| id | UUID | @unique |
| role | String | "user" or "assistant" |
| content | String | Raw text for user, JSON for assistant |
| timestamp | Date | |
| conversation | ChatConversation? | Inverse relationship |

### FavoriteVerse
| Field | Type | Notes |
|-------|------|-------|
| id | UUID | @unique |
| reference | String | |
| text | String | |
| savedAt | Date | |
| source | String | "chat" or "daily_verse" |

## Supabase PostgreSQL Tables (Cloud)

### profiles
```sql
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name TEXT,
  email TEXT,
  profile_image_url TEXT,
  is_premium BOOLEAN DEFAULT FALSE,
  premium_expires_at TIMESTAMPTZ,
  onboarding_topics TEXT[],
  streak_count INT DEFAULT 0,
  longest_streak INT DEFAULT 0,
  last_active_date DATE,
  total_verses_explored INT DEFAULT 0,
  total_cards_created INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### notification_settings
```sql
CREATE TABLE notification_settings (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  daily_verse_enabled BOOLEAN DEFAULT TRUE,
  daily_verse_time TIME DEFAULT '07:00',
  streak_nudge_enabled BOOLEAN DEFAULT TRUE,
  streak_nudge_time TIME DEFAULT '19:00',
  timezone TEXT DEFAULT 'America/New_York',
  apns_device_token TEXT
);
```

### daily_verses
```sql
CREATE TABLE daily_verses (
  id SERIAL PRIMARY KEY,
  reference TEXT NOT NULL,
  text TEXT NOT NULL,
  theme TEXT,
  last_used_date DATE
);
```

### usage_logs
```sql
CREATE TABLE usage_logs (
  id SERIAL PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  log_date DATE NOT NULL DEFAULT CURRENT_DATE,
  chat_count INT DEFAULT 0,
  last_chat_at TIMESTAMPTZ,
  UNIQUE(user_id, log_date)
);
```

### Cloud sync tables (Session 29 — see docs/cloud-sync.md)
Mirror the local content models. Shared columns on every table: `id uuid PK` (= local id),
`user_id uuid → auth.users ON DELETE CASCADE, default auth.uid()`,
`updated_at timestamptz` (trigger-stamped, pull cursor), `deleted_at timestamptz` (soft delete).
RLS: authenticated users select/insert/update/delete only `user_id = auth.uid()`; no anon access.

| Table | Columns (besides the shared ones) |
|-------|-----------------------------------|
| saved_cards | verse_reference, verse_text, template_id, is_favorite, context_note, created_at |
| favorite_verses | reference, text, source, saved_at |
| saved_prayers | text, source, context_note, saved_at |
| chat_conversations | summary, started_at |
| chat_messages | conversation_id → chat_conversations ON DELETE CASCADE, role ('user'/'assistant'), content, sent_at |

Local side: each synced model has `needsSync: Bool = true` (Room: `needsSync INTEGER NOT NULL DEFAULT 1`),
plus a `SyncTombstone` / `sync_tombstone` table holding deletes that haven't been pushed.

### Row Level Security
```sql
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE usage_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users read own profile" ON profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users update own profile" ON profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Users read own usage" ON usage_logs FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Daily verses public read" ON daily_verses FOR SELECT USING (true);
```

## Bible Data (Bundled JSON)
```json
{
  "books": [
    {
      "name": "Genesis",
      "abbreviation": "Gen",
      "chapters": [
        {
          "number": 1,
          "verses": [
            {
              "number": 1,
              "text": "In the beginning God created the heaven and the earth."
            }
          ]
        }
      ]
    }
  ]
}
```
Source: KJV JSON from public domain repository (aruljohn/Bible-kjv)
