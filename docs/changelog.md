# Changelog

## 2026-04-06 — Session 0 (Pre-Build)
- Generated full build prompt with all specs
- Defined tech stack: SwiftUI + Supabase + Claude API
- Designed data schemas (SwiftData local + Supabase PostgreSQL cloud)
- Specified API routes (chat proxy, daily verse, receipt validation, push triggers)
- Created design system (light theme, blue/gold palette, serif scripture text)
- Scoped Phase 1 (MVP) and Phase 2 (expansion)
- Decision: KJV bundled locally (public domain), ESV deferred to Phase 2
- Decision: Card templates pre-designed (not AI-generated) for quality control
- Decision: Claude API proxied through Supabase Edge Functions (never direct from client)
- Decision: 5 free chats/day, 50 premium — tracked server-side
- Decision: App name is Seek ("Seek and ye shall find")
- Decision: No devotionals — app is spontaneous/daily practice, not structured plans
- Decision: No social features — focused experience, not a community app

## 2026-04-07 — Session 1 (Project Init)
- Created Xcode project with XcodeGen
- Set up project folder structure (Views/, Models/, Services/, Components/, CardTemplates/, Resources/)
- Initialized Supabase project and Edge Function scaffolds
- Extracted build prompt into docs/ files
- Created CLAUDE.md, .claude/commands/, .claude/rules/
- Built SwiftData models (UserProfile, SavedCard, ChatConversation, ChatMessage, FavoriteVerse)
- Built app shell with 3-tab navigation (Home, Chat, Library)
- Bundled KJV Bible JSON
- Created BibleService and SupabaseService stubs

## 2026-04-07 — Session 1b (Auth + Home + Chat)
- Created Supabase project "Seek" (hxfiaowayrhuhzhhbaix, East US)
- Pushed DB migration: profiles, notification_settings, daily_verses, usage_logs tables
- RLS policies + auto-profile trigger on signup
- Added supabase-swift SPM dependency + Sign in with Apple entitlement
- Built AuthManager (@Observable) with full auth state machine
- Built SupabaseService with real Supabase SDK integration (auth, chat proxy, daily verse)
- Built 4-screen onboarding: Welcome → Personalization (topic chips) → Notifications → Sign In
- Built SignInView: Sign in with Apple + email/password with sign-up toggle
- Wired SeekApp to route based on auth state (onboarding vs main app)
- Built full Home Screen: daily verse from API, streak counter, chat navigation, pull-to-refresh
- Built full Chat UI: user/assistant bubbles, verse cards (tappable → card creator), prayer card, worship song card, suggestion chips, rate limit banner
- Chat wired to Supabase Edge Function → Claude API with conversation history
- Rate limit tracking (local profile + server response), rate limit UI with upgrade CTA
- Conversations + messages saved to SwiftData
- Profile view wired: sign out, delete account (with confirmation), live stats
- Decision: Google Sign-In deferred — Apple + email covers App Store launch
- Decision: Edge cases handled via Claude system prompt (server-side), plus 500-char client truncation
- Next: Verse Card Creator (templates), Saved Library, Streak logic

## 2026-04-07 — Session 1c (Card Creator + Library + Streaks)
- Built 18 card templates across 4 categories (Nature 5, Minimal 5, Watercolor 4, Bold 4)
- 6 templates marked premium-only (Mountain, Blush, Seafoam, Rose, Fire, Gold)
- VerseCardView renders at 1080x1920 (9:16 IG story) with auto-sizing font
- CardCreatorView: live preview, horizontal template picker, save to Photos, share sheet
- App watermark on all cards (semi-transparent, bottom corner)
- LibraryView with 3 tabs: Cards (thumbnail grid), Favorites (swipe-to-delete list), History (conversation list)
- Cards grid shows mini previews with correct template colors
- Favorites show source tag (Chat / Daily Verse) + context menu copy
- History shows conversation summaries with message count
- StreakManager: daily activity tracking, consecutive day detection, grace period, milestone check
- Streak recorded on HomeView appear
- Decision: Card templates defined in code (CardTemplate struct), not in asset catalog
- Next: Push notifications, Profile settings, Monetization (StoreKit 2)

## 2026-04-07 — Session 1d (Notifications + Monetization + Polish)
- NotificationManager: permission handling, APNs token storage to Supabase, local scheduling fallback
- Daily verse reminder (default 7:00 AM) and streak nudge (default 7:00 PM)
- Deep link routing from notification taps (openDailyVerse, openHome)
- NotificationSettingsView: toggles + time pickers for each notification type
- StoreManager: StoreKit 2 product loading, purchasing, restore, transaction listener
- SeekProducts.storekit config: monthly ($4.99) and yearly ($39.99) with 7-day free trials
- PremiumUpgradeView: feature comparison, plan selector, subscribe CTA
- SubscriptionManagementView: current plan display, App Store management link
- ProfileView fully wired: notifications, subscription, rate/review, share, privacy/terms
- WebContentView: WKWebView wrapper for privacy policy and terms
- LoadingView and ErrorView reusable components
- Premium template lock overlay in card creator
- Decision: Local notification scheduling as fallback (server push needs APNs cert)
- Remaining: App icon, launch screen, AdMob, offline mode, App Store assets

## 2026-04-07 — Session 2 (Color Palette, Auth Fixes, Features, Testing)

### Built
- Switched entire color palette from blue/gold to Gold + Soft Sage (#5B7B5E, #CDA349, #8AAF8D)
- Forced light mode (INFOPLIST_KEY_UIUserInterfaceStyle + .preferredColorScheme(.light))
- Replaced ALL Color(.systemGray6) with explicit Color(hex: "F3F4F6") across all views
- Replaced ALL .foregroundStyle(.secondary/.tertiary) with explicit hex colors
- Created Supabase project "Seek" (hxfiaowayrhuhzhhbaix), pushed DB schema, deployed Edge Functions
- Set Anthropic API key in Supabase secrets — chat is live with Claude
- Fixed auth flow: hasCompletedOnboarding changed from computed UserDefaults property to stored @Observable property (SwiftUI couldn't track UserDefaults changes)
- Reordered onboarding: Welcome → Sign In → Personalization → Notifications
- Returning users (sign in) skip personalization/notifications, go straight to home
- Revamped home screen: time-based greeting, 6 quick prompt chips in 2-col grid, removed redundant "Start a conversation" button
- ChatListView: recent conversations list + "New Conversation" button on Chat tab
- Load past conversations: messages parsed from stored JSON back into verse cards, prayer cards, etc.
- Card creator: fixed blank screen (inline preview instead of 1080x1920 scaleEffect)
- Card creator: .sheet(item:) instead of .sheet(isPresented:) — fixes blank on first tap
- Chat JSON parsing: strip markdown fences from Claude response, "return raw JSON only" in system prompt
- Action steps: Claude returns practical real-world actions based on emotional state (e.g., Anxiety → "Release + Move")
- Action card UI: numbered steps with sage green styling
- Worship song: Apple Music + Spotify deep links with web fallback
- Heart toggle: filled/unfilled state on daily verse and chat verse cards
- Favorites → Create Card: tap any favorited verse to open card creator
- NSPhotoLibraryAddUsageDescription added to Info.plist (was crashing on save)
- Edge Functions deployed with --no-verify-jwt (chat + daily-verse)
- User account set to premium in Supabase for testing

### Decisions
- Dark mode root cause: app never forced light mode, user's phone was in dark mode
- Removed UIKit UINavigationBarAppearance hacks — unnecessary with forced light mode
- Google Sign-In deferred to post-launch
- AdMob deferred to post-launch
- Action steps added to Claude system prompt with examples for common emotions

### Bugs Found / Issues for Next Session
- Apple Sign In needs Apple Service ID configured in Supabase dashboard
- daily_verses table is empty — daily verse returns 404, fallback shows Psalm 46:1
- Loading past conversations opens them read-only — can't continue the conversation
- Premium upgrade sheet not wired from rate limit card in chat
- SupabaseService still has a stale TODO comment about credentials (they're set)
- xcodegen resets signing team on every regenerate — need to add team ID to project.yml

### Current Status
- Phase 1 MVP: ~85% complete
- All core features working: auth, chat with Claude, card creator, library, streaks, notifications, monetization
- Remaining: App icon, launch screen, AdMob, offline mode, App Store assets, TestFlight, final QA
- 8 commits on main, Supabase project live with Edge Functions deployed

## 2026-04-07 — Session 2b (TestFlight Deploy)
- Generated 1024x1024 app icon (sage green + gold circle + book + "Seek" text)
- Added iPad orientation support (all 4 orientations required by App Store)
- Added DEVELOPMENT_TEAM (6QU295KVS2) to project.yml
- Added NSPhotoLibraryAddUsageDescription to Info.plist
- Created "Seek - Scripture Companion" app record in App Store Connect
- Successfully archived and uploaded Seek 1.0.0 (1) to TestFlight
- App name "Seek" was taken — using "Seek - Scripture Companion" on App Store
- 10 commits on main

### Remaining for App Store submission
- Professional app icon (current is placeholder)
- App Store screenshots (6.7" and 6.1")
- Privacy nutrition labels
- Seed daily_verses table (365 verses)
- Configure Apple Sign In service ID in Supabase
- AdMob integration (optional for launch)
- Offline mode handling
- Final QA pass

## 2026-04-08 — Session 3 (Multi-Translation Support)

### Built
- Multi-translation support: default NLT, switchable to KJV in Settings
- BibleTranslation enum (Seek/Models/BibleTranslation.swift) — NLT and KJV with display names
- Added `preferredTranslation` property to UserProfile SwiftData model (default: "NLT")
- Supabase migration: `preferred_translation` column on profiles table (default: "NLT")
- SupabaseService: `sendChatMessage` now accepts `translation` param; new `updatePreferredTranslation` method
- Chat Edge Function: parameterized system prompt — `buildSystemPrompt(translation)` replaces hardcoded KJV
- Server-side validation: only accepts "KJV" or "NLT" (prevents prompt injection)
- TranslationPickerView: dedicated settings screen with checkmark selection
- ChatView passes user's `preferredTranslation` to API on every chat request
- Daily verses: added `translation` column, seeded 364 NLT verses alongside 364 KJV
- Daily-verse Edge Function reads user's `preferred_translation` from profiles and filters
- All users set to premium (is_premium default = true) until pricing is finalized
- Fixed nested button bug: Favorite and Create Card are now separate independent buttons in verse cards
- Both Edge Functions redeployed (chat + daily-verse)
- TestFlight build 1.0.0 uploaded

### Bug fixes confirmed from prior sessions
- Profile auto-create for Apple Sign In — working (ensureRemoteProfile called)
- daily_verses table — seeded with 364 verses per translation
- Past conversations read-only — fixed (input bar active, messages save)
- Premium upgrade sheet — wired from rate limit card in chat
- Nested button in verse card — Favorite tap was swallowed by outer Create Card button

### Decisions
- NLT text in chat generated by Claude from training data (not bundled JSON) — no licensing needed
- NLT daily verses seeded in database (364 verses matching KJV references)
- No onboarding change for translation — Settings only, default NLT
- KJV JSON bundle kept for offline/future use but not used in chat flow
- All users premium until pricing structure is finalized pre-App Store launch

### Gotcha discovered
- SwiftData: new stored properties on @Model MUST have default values on the declaration (`var foo: String = "default"`), not just in the init. Without it, SwiftData can't perform lightweight migration and may wipe the local store.

### Current Status
- Phase 1 MVP: ~90% complete
- All core features working: auth, chat with NLT/KJV, card creator, library, streaks, notifications, monetization
- Remaining: Professional app icon, launch screen, App Store screenshots/metadata, privacy labels, offline mode, final QA
- 4 commits this session, both Edge Functions redeployed, TestFlight build uploaded

## 2026-04-11 — Session 4 (Chat JSON Fix + Polish)

### Bug fix
- Chat was displaying raw JSON instead of parsed verse cards, prayer cards, etc.
- Root cause: `max_tokens: 1500` in chat Edge Function — Claude's response (3-5 verses + prayer + song + action) exceeded the limit, truncating the JSON mid-response. `JSON.parse` failed, fallback put the raw JSON string into the `message` field, which rendered as a plain text bubble.
- Fix (Edge Function): increased `max_tokens` from 1500 to 3000, improved markdown fence stripping to handle text before JSON, added truncated JSON salvage logic (closes open braces/brackets before giving up)
- Fix (client-side): if `response.verses` is empty but `response.message` starts with `{`, re-parse it as `ChatResponse` — catches edge case where server fallback wraps valid JSON in the message field
- Chat Edge Function redeployed

### Previously uncommitted changes (from between sessions 3–4)
- Verse card font sizes bumped significantly for 1080x1920 render (short verse: 48→88pt, reference: 28→44pt, more line spacing/padding)
- Card creator preview font sizes updated to match new scale
- Quick prompts on home screen changed from sentences to single-word emotions (Fear, Anger, Joy, Loneliness, etc.)
- Premium status sync added on home screen launch (reads `is_premium` from Supabase)
- AuthManager: `ensureRemoteProfile()` + `ensureNotificationSettings()` called after Apple Sign In and email auth
- `skip_nonce_check` set to false in Supabase config (tighter Apple auth)

### Decisions
- 3000 max_tokens is sufficient headroom for full chat responses (3-5 verses + prayer + song + action + follow-up)
- Client-side fallback re-parsing is a safety net — primary fix is server-side

### Current Status
- Phase 1 MVP: ~90% complete
- All core features working: auth, chat with NLT/KJV, card creator, library, streaks, notifications, monetization
- Remaining: Professional app icon, launch screen, App Store screenshots/metadata, privacy labels, offline mode, final QA
- TestFlight build 4 uploading
