# API Routes (Supabase Edge Functions)

## POST /api/chat
**Purpose:** Proxy to Claude API with rate limiting

**Request:**
```json
{
  "message": "User's message text",
  "conversationHistory": [
    { "role": "user", "content": "..." },
    { "role": "assistant", "content": "..." }
  ]
}
```
**Headers:** `Authorization: Bearer {supabaseAccessToken}`

**Response (200):**
```json
{
  "message": "Empathetic intro",
  "verses": [
    {
      "reference": "Book Chapter:Verse",
      "text": "Full KJV verse text",
      "context": "Why this verse fits"
    }
  ],
  "prayer": "Short 2-4 sentence prayer",
  "worshipSong": {
    "title": "Song title",
    "artist": "Artist name",
    "context": "Why this song fits"
  },
  "followUp": "Optional gentle prompt",
  "remainingChats": 3
}
```

**Response (429):**
```json
{
  "error": "daily_limit_reached",
  "message": "You've used your 5 free scripture chats for today.",
  "resetsAt": "2026-04-07T04:00:00Z",
  "upgradeURL": "seek://upgrade"
}
```

## GET /api/daily-verse
**Purpose:** Get today's daily verse

**Headers:** `Authorization: Bearer {supabaseAccessToken}`

**Response (200):**
```json
{
  "reference": "Psalm 46:1",
  "text": "God is our refuge and strength, a very present help in trouble.",
  "theme": "strength"
}
```

## POST /api/verify-receipt
**Purpose:** Validate App Store subscription receipt

**Request:**
```json
{ "receiptData": "base64encodedreceipt" }
```

**Response (200):**
```json
{ "isPremium": true, "expiresAt": "2026-05-06T00:00:00Z" }
```

## Scheduled Functions (pg_cron + Edge Functions)

### dailyVersePush
- pg_cron runs every hour
- Triggers Edge Function that queries users whose notification time matches current hour in their timezone
- Sends APNs push with daily verse

### streakNudgePush
- pg_cron runs at 6 PM UTC
- Triggers Edge Function that checks users who haven't logged activity today
- Sends nudge if enabled

## Rate Limiting Logic
- Free tier: 5 AI conversations per day
- Premium tier: 50 conversations per day
- A "conversation" = one prompt + response (follow-ups within same chat don't count as new)
- Rate limit resets at midnight local time
- Tracked in `usage_logs` table: `(user_id, log_date, chat_count)`
- Rate limit check happens BEFORE Claude API call (don't waste API credits)
