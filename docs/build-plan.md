# Build Plan

## Phase 1 — MVP (App Store Ready)

### Project Setup
- [x] Initialize Xcode project (SwiftUI, iOS 17+)
- [x] Set up Supabase project (Auth, Database, Edge Functions, storage)
- [x] Bundle KJV Bible JSON data
- [x] Set up SwiftData models
- [x] Create project file structure (Views/, Models/, Services/, Components/, Resources/)
- [ ] Configure AdMob SDK
- [ ] Set up StoreKit 2 configuration file

### Authentication & Onboarding
- [x] Implement Sign in with Apple
- [ ] Implement Google Sign-In (deferred — Apple + email covers launch)
- [x] Implement email/password auth
- [x] Password reset flow (email-based via Supabase)
- [x] Build onboarding flow (4 screens)
- [x] Save onboarding topic selections
- [x] Handle auth state persistence and auto-login
- [x] Build sign-out and delete account flows

### Home Screen
- [x] Daily verse card display (tappable)
- [x] Streak counter with fire emoji
- [x] Chat input prompt ("What's on your heart?")
- [ ] AdMob banner integration
- [x] Pull-to-refresh for new daily verse

### Scripture Chat
- [x] Build chat UI (message bubbles, scroll, input bar)
- [x] Deploy Supabase Edge Function proxy for Claude API
- [x] Implement Claude system prompt for scripture matching
- [x] Parse structured verse response and display as tappable cards
- [x] Display prayer card below verses (styled distinctly)
- [x] Display worship song recommendation with Apple Music/Spotify deep link
- [x] Implement conversation history (follow-up context)
- [x] Rate limit tracking (5 free / 50 premium per day)
- [x] Rate limit reached UI with upgrade CTA
- [x] Save conversations to SwiftData
- [x] Handle edge cases (empty input, non-faith topics, crisis language)

### Verse Card Creator
- [x] Build card preview screen
- [x] Design and implement 16-20 card templates (4 categories x 4-5 each)
- [x] Horizontal template picker with live preview
- [x] Render card as 1080x1920 PNG via ImageRenderer
- [x] Save to photo library (request permission)
- [x] iOS share sheet integration
- [x] App watermark on cards
- [x] Mark 5-10 templates as premium-only

### Saved Library
- [x] Cards tab (thumbnail grid of saved cards)
- [x] Favorites tab (list of hearted verses)
- [x] History tab (past chat conversations)
- [x] Re-share, edit template, delete, copy actions
- [x] Empty states for each tab

### Streak & Engagement
- [x] Streak calculation logic (daily reset, grace period)
- [x] Milestone detection (7, 30, 90, 365)
- [x] Streak display on home screen
- [ ] Weekly summary card generation

### Push Notifications

**Phase A — Local notifications (DONE Session 12, 2026-05-01).** Daily verse + streak reminders fire from `UNCalendarNotificationTrigger` on-device. No APNs key, AppDelegate, or Edge Function required.
- [x] Request notification permission (onboarding wired to `NotificationManager.requestPermission()`; settings has its own re-request button)
- [x] Schedule daily verse + streak nudge automatically on permission grant in onboarding (defaults: 7am / 7pm)
- [x] Notification preferences UI in settings — toggles + time pickers
- [x] Persist preferences to Supabase `notification_settings` (survives reinstall, syncs across devices)
- [x] Handle notification tap deep links (`.openDailyVerse` / `.openHome` posted via NotificationCenter)

**Phase B — APNs server-side push (deferred — needs Apple Developer Program + APNs key).** Would replace generic body ("Tap to see today's verse") with the actual verse text in the notification.
- [ ] Add `aps-environment` entitlement to Seek.entitlements
- [ ] Declare Push Notifications capability in project.yml
- [ ] Add `UIApplicationDelegateAdaptor` AppDelegate to capture `didRegisterForRemoteNotificationsWithDeviceToken`
- [ ] Generate APNs Authentication Key in Apple Developer portal; upload to Supabase secrets
- [ ] Build `send-daily-push` Edge Function (APNs HTTP/2 with JWT auth)
- [ ] pg_cron migration to invoke daily push hourly (find users in their local time window)
- [ ] Test on physical device (simulator can't receive APNs)

### Profile & Settings
- [x] Profile screen with stats
- [x] Settings screen (notifications, translation, subscription)
- [x] Subscription management screen
- [x] Rate/review prompt (after 7-day streak)
- [x] Share app action
- [x] Privacy policy and terms of service screens

### Monetization — replaced with optional donations (Session 11, 2026-05-01)
- [x] ~~Configure StoreKit 2 products~~ Code retained but unwired; chat rate limit now flat 50/day for everyone
- [x] ~~Build premium upgrade screen~~ Hidden in ProfileView; sheet presentation removed from ChatView
- [x] ~~Premium template unlock logic~~ All templates unlocked for everyone
- [x] DonationView.swift — editorial in-app page with Stripe Payment Link CTA (URL is a placeholder pending Stripe dashboard setup)
- [x] Apple compliance: no IAP for donations (App Review Guideline 3.2.1) — external `openURL` to Stripe

### Polish & Launch
- [x] App icon design (multiple sizes) — Claude Design deliverable: cream squircle, serif S, gold dot
- [x] Launch screen — LaunchScreen.storyboard with wordmark + "SCRIPTURE FOR EVERY MOMENT" subtitle
- [x] Loading states and skeleton screens
- [x] Error handling (network, auth, API failures)
- [x] Offline mode handling (graceful degradation)
- [ ] App Store screenshots (6.7" and 6.1")
- [ ] App Store description and metadata
- [ ] Privacy nutrition labels
- [x] TestFlight beta distribution
- [ ] Final QA pass
- [ ] Submit to App Store

### Pre-launch Marketing
- [x] Public GitHub repo (github.com/garvonious-ui/Seek)
- [x] Wordmark + app icon assets rendered from Claude Design spec
- [x] Marketing landing page (`landing/index.html`) — hero, how-it-works, AI spotlight, verse card templates, features strip, waitlist CTA
- [x] Supabase `waitlist` table (citext + RLS anon-insert-only + format CHECK)
- [x] Landing waitlist forms wired to Supabase REST (smoke-tested: 201, 409, format reject, tampered source)
- [x] Host landing page on Vercel — deployed Session 9, custom domain `askseekpray.app` attached Session 13 (apex A record + www CNAME at GoDaddy → Vercel auto-issued SSL)
- [x] Privacy policy + Terms pages (`landing/privacy.html`, `landing/terms.html`) wired into footer of `index.html`

## Phase 2 — Expansion
- [x] ~~ESV API integration~~ Multi-translation support (NLT default, KJV switchable) — done in Phase 1
- [ ] Verse of the Day widget (iOS home screen / lock screen)
- [ ] Search/browse Bible by book and chapter
- [ ] Topical verse index (pre-curated lists)
- [ ] Journaling feature (personal notes tied to verses)
- [ ] Cloud sync of all local data via Supabase
- [ ] Advanced analytics via Supabase + PostHog
- [ ] Additional card template packs

## Known Bugs
- [x] Profile auto-create trigger not firing for Apple Sign In users — fixed: ensureRemoteProfile() called after Apple Sign In
- [x] ~~Apple Sign In needs Apple Service ID configured in Supabase dashboard~~ — was a stale TODO; native iOS `signInWithIdToken` flow only needs the Bundle ID in Supabase's Apple provider (already set to `com.loucesario.seek` since at least Session 1b). Verified Session 13 — five real Apple Sign In users since 2026-04-07 in `auth.identities` (provider=apple).
- [x] daily_verses table is empty — fixed: seed.sql has 365 verses across 20 themes
- [x] Loading past conversations opens them read-only — fixed: input bar stays active, messages save to existing conversation
- [x] Premium upgrade sheet not wired from rate limit card in chat — fixed: rate limit card triggers PremiumUpgradeView
- [x] Chat displaying raw JSON instead of verse cards — fixed: max_tokens increased 1500→3000, added JSON salvage logic + client-side fallback
- [x] Chat returning 502 on every request — fixed: deprecated model `claude-sonnet-4-20250514` replaced with `claude-sonnet-4-6`, added model fallback logic

## Pending Data / Blockers
- Apple Developer Program enrollment ($99/year) required for App Store + push notifications
- Supabase Pro plan may be needed for Edge Functions volume and pg_cron
- Anthropic API key needed for Claude integration
- AdMob account setup
- App Store Connect setup (bundle ID, certificates, provisioning profiles)
