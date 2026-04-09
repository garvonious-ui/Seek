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
- [x] Request notification permission (onboarding + settings)
- [x] Store APNs device token in Supabase notification_settings
- [x] Deploy daily verse push Edge Function + pg_cron schedule
- [x] Deploy streak nudge Edge Function + pg_cron schedule
- [x] Notification preferences UI in settings
- [x] Handle notification tap deep links

### Profile & Settings
- [x] Profile screen with stats
- [x] Settings screen (notifications, translation, subscription)
- [x] Subscription management screen
- [x] Rate/review prompt (after 7-day streak)
- [x] Share app action
- [x] Privacy policy and terms of service screens

### Monetization
- [x] Configure StoreKit 2 products (monthly + annual)
- [x] Build premium upgrade screen (feature comparison)
- [x] Implement receipt validation Edge Function
- [x] Premium status sync (local + Supabase)
- [x] Free trial (7 days) implementation
- [x] Restore purchases flow
- [ ] Ad removal for premium users
- [x] Premium template unlock logic

### Polish & Launch
- [ ] App icon design (multiple sizes)
- [ ] Launch screen
- [x] Loading states and skeleton screens
- [x] Error handling (network, auth, API failures)
- [ ] Offline mode handling (graceful degradation)
- [ ] App Store screenshots (6.7" and 6.1")
- [ ] App Store description and metadata
- [ ] Privacy nutrition labels
- [x] TestFlight beta distribution
- [ ] Final QA pass
- [ ] Submit to App Store

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
- [ ] Apple Sign In needs Apple Service ID configured in Supabase dashboard
- [x] daily_verses table is empty — fixed: seed.sql has 365 verses across 20 themes
- [x] Loading past conversations opens them read-only — fixed: input bar stays active, messages save to existing conversation
- [x] Premium upgrade sheet not wired from rate limit card in chat — fixed: rate limit card triggers PremiumUpgradeView

## Pending Data / Blockers
- Apple Developer Program enrollment ($99/year) required for App Store + push notifications
- Supabase Pro plan may be needed for Edge Functions volume and pg_cron
- Anthropic API key needed for Claude integration
- AdMob account setup
- App Store Connect setup (bundle ID, certificates, provisioning profiles)
