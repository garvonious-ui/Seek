# Architecture

## Core Principles

### 1. Local-First with Cloud Sync
- SwiftData is the primary data store for all user content (cards, favorites, chat history, streak data)
- Supabase PostgreSQL syncs profile, streak, and premium status across devices
- Bible text is always local (bundled JSON) — never fetched from network

### 2. Claude API Proxy Pattern
- App NEVER calls Claude API directly — API key stays on server
- Supabase Edge Function acts as proxy: validates auth token → checks rate limit → forwards to Claude → returns response
- Rate limit tracked in Supabase: `usage_logs` table with `(user_id, log_date)` unique constraint
- System prompt is server-side only — user cannot modify or see it

### 3. Card Rendering Client-Side
- No server-side image generation — cards are rendered locally using SwiftUI's ImageRenderer
- Templates are SwiftUI views with parameterized verse text
- Rendered at 1080x1920 (IG story) as PNG
- Keeps it fast, free, and offline-capable

### 4. Subscription via StoreKit 2
- In-app purchases managed through StoreKit 2 (native Swift API)
- Receipt validation via Supabase Edge Function → App Store Server API
- Premium status cached locally in SwiftData, verified against Supabase on launch

### 5. Push Notification Architecture
- Direct APNs integration (no FCM dependency) via Supabase Edge Functions
- pg_cron schedules trigger Edge Functions for notification logic
- User timezone stored in Supabase `notification_settings` table for localized delivery
- Device APNs token stored in `notification_settings.apns_device_token`

### 6. Supabase Auth
- Sign in with Apple (required by App Store), Google, email/password
- Supabase handles JWT tokens — app stores session via supabase-swift client
- RLS policies enforce data isolation per user
- Profile row auto-created via database trigger on auth.users insert

## Tech Stack Summary
- **Client:** SwiftUI (iOS 17+), Swift 5.9+, SwiftData, NavigationStack
- **Backend:** Supabase (Auth, PostgreSQL, Edge Functions)
- **AI:** Claude API (claude-sonnet-4-20250514) via Edge Function proxy
- **Bible data:** KJV bundled as local JSON (public domain)
- **Payments:** StoreKit 2 for subscriptions
- **Ads:** Google AdMob (banner + interstitial)
- **Notifications:** APNs via Edge Functions + pg_cron

## Data Flow
```
User Input → SwiftUI → SupabaseService → Edge Function → Claude API
                                              ↓
                                         Rate limit check (usage_logs)
                                              ↓
                                         Response → Parse → Display verses
                                              ↓
                                         User taps verse → CardCreatorView
```

## Key Libraries
- supabase-swift (Supabase client)
- StoreKit 2 (subscriptions)
- Google Mobile Ads SDK (AdMob)
