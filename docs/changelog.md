# Changelog

## 2026-04-30 — Session 10 (Privacy + Terms + Vercel config)

### Built
- **`landing/privacy.html`** — full privacy policy. Plain-language, accurate to what the app actually does. Documents: account info from Supabase auth, preferences/streak/usage stats, push token; chat content is NOT stored on Seek's servers (verified by reading `supabase/functions/chat/index.ts` — only `chat_count` + `last_chat_at` are persisted to `usage_logs`); Anthropic processes prompts in transit per their API terms (no training); saved cards/favorites/prayers are device-only via SwiftData. Discloses no third-party analytics, no AdMob, no IDFA, no precise location, write-only Photos permission. Lists service providers (Supabase, Anthropic, Apple) with regions. Has explicit EEA/UK/CCPA rights section, retention, security, international transfers, children, change notice, contact.
- **`landing/terms.html`** — full ToS. Sections: eligibility (13+), account, what Seek does + denominational neutrality, AI-generated content disclaimer + crisis disclaimer (988, Samaritans, findahelpline.com), acceptable use, subscriptions + 7-day free trial + Apple-only refunds, user content + no-train-on-prompts commitment, watermark rules, termination, "as is" disclaimer, liability cap (greater of fees-paid-12mo or USD $50), indemnification, Delaware governing law, change notice, contact.
- Both pages share the landing visual system (cream `#FAFAF6` bg, sage `#5B7B5E` link color, serif headlines via Georgia, UI body via SF Pro), self-contained CSS, mobile responsive, nav bar to home, footer matching `index.html`. Max content width 760px so long-form reads cleanly.
- **`landing/index.html` footer wired** — `href="#"` placeholders for Privacy/Terms now point at `privacy.html`/`terms.html`. Email link updated `hello@seek.app` → `hello@seek-app.com` for consistency with the legal pages.
- **`landing/vercel.json`** — Vercel hosting config:
  - `cleanUrls: true` so `/privacy` and `/terms` work without `.html` extensions. Critical: this matches what the iOS app already hardcodes at `Seek/Views/Profile/ProfileView.swift:126,131` (`https://seek-app.com/privacy`, `https://seek-app.com/terms`). When the domain is bought and pointed at Vercel, the in-app legal links will Just Work — no app rebuild required.
  - `trailingSlash: false`, basic security headers (`X-Content-Type-Options`, `Referrer-Policy: strict-origin-when-cross-origin`, `X-Frame-Options: DENY`, `Permissions-Policy` disabling FLoC + sensitive APIs), 1-year `Cache-Control: immutable` for `/assets/*`. No CSP — landing relies on inline `<style>` and inline JS for the Supabase POST; tightening later.
- **`.gitignore`** — added `landing/.vercel/` so the project linkage created by `vercel` CLI doesn't get committed.

### Decisions
- **Vercel over GitHub Pages.** User asked for Vercel. Cleaner DX, free custom domain attachment later (Project Settings → Domains), preview deploys per branch, edge cache. The `cleanUrls: true` feature is the deciding factor — it lets `/privacy` and `/terms` resolve to `.html` files without needing `.html` in the URL, which exactly matches the URL shape the iOS app already ships with. GitHub Pages doesn't do clean URLs without a hack.
- **Domain placeholder is `seek-app.com` everywhere.** User is buying the domain today. Privacy/Terms contact is `hello@seek-app.com`. The iOS app's hardcoded WebContentView URLs are `https://seek-app.com/privacy|terms`. Once the domain points at Vercel, all three (in-app links, footer mailto, legal pages contact) match without code changes.
- **Privacy policy is written from a position of confidence, not boilerplate.** Concrete claims like "Seek's servers do not persist the contents of your chat messages" and "We do not use third-party analytics SDKs" are made because the codebase actually backs them up — verified by reading the chat Edge Function and grepping the Swift sources. App Store privacy nutrition labels can be filled in honestly using this doc as the source of truth.
- **Crisis disclaimer is in the ToS callout block** in addition to whatever surfaces in chat. Belt-and-suspenders for the most safety-critical disclosure in the doc. Lists 988 (US), 116 123 (UK Samaritans), and `findahelpline.com` for everywhere else.
- **Delaware governing law.** Default for US software ToS, low cost to operate, predictable courts. Easy to change later if user incorporates elsewhere — search-and-replace one section.
- **Liability cap of greater-of-fees-paid-12mo or USD $50.** Standard for indie consumer apps. The $50 floor catches the free-tier user who pays nothing but still has a claim.
- **No CSP in `vercel.json` for now.** A strict CSP would break the existing landing waitlist form (inline `<script>` posting to Supabase) and the inline `<style>` blocks. Logging this as a future hardening pass — at minimum can add `frame-ancestors 'none'` even with the inline-friendly setup.

### Gotchas / things to know
- **Chat content really is server-private.** Re-confirmed by reading `supabase/functions/chat/index.ts:127-229`: the function reads `chat_count` from `usage_logs`, forwards `message + conversationHistory` to Anthropic, and upserts `{user_id, log_date, chat_count, last_chat_at}` back to `usage_logs`. No user message bodies hit our database. Edge Function transient logs only capture upstream API errors, not request bodies. Worth re-verifying if anyone refactors `chat/index.ts` — the privacy policy is contractually committed to this.
- **The iOS WebContentView is a `WKWebView` pointed at the live URL** (`Seek/Views/Profile/WebContentView.swift`), not a bundled HTML view. So once `seek-app.com` resolves, the legal pages will be fetched live every time — no app update needed for legal copy revisions.
- **Vercel CLI 52 is already installed at `/opt/homebrew/bin/vercel`.** First deploy is interactive (`cd landing && vercel`) — opens a browser for OAuth login on first run, then prompts for project setup. Subsequent deploys are `vercel --prod` non-interactively. The `landing/.vercel/` directory created on first link is gitignored.

### Deployed
- Live at [landing-rouge-xi-28.vercel.app](https://landing-rouge-xi-28.vercel.app) (auto-alias) and a hash URL `landing-11yvfcsak-garvonious-uis-projects.vercel.app`. Project linked under scope `garvonious-uis-projects/landing`.
- Verified live: `/`, `/privacy`, `/terms` all 200; security headers + asset cache headers from `vercel.json` applied as configured.
- Vercel CLI auto-generated `landing/.gitignore` with `.vercel` on line 1, in addition to my root-level `landing/.vercel/` entry. Both ignore the project linkage; harmless redundancy.
- Project name is currently `landing` (Vercel defaulted to the directory name). To rename to `seek` and regenerate prettier auto-aliases: Vercel dashboard → Project → Settings → General → Project Name. Cosmetic only — irrelevant once the custom domain attaches.
- Future deploys: `cd landing && vercel --prod` (production) or `vercel` (preview). Linkage persists in `landing/.vercel/`.

### Current Status
- Phase 1 MVP: ~96% complete. Legal docs and hosting are both off the blocker list now.
- Domain purchase is the user's next move. Once `seek-app.com` is bought and DNS-pointed at Vercel via Project → Settings → Domains, the in-app `WebContentView` URLs (`https://seek-app.com/privacy|terms`) resolve without any iOS code change. The hardcoded host already matches the contact email and footer copy across both legal pages.
- Build number unchanged from Session 9 (still 6). No iOS rebuild needed for any of this.

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

## 2026-04-13 — Session 6 (Home input, prayer saving, regenerate, favorites filter, markdown fix)

### Built
- **Home free-text input**: new "Or type your own..." capsule input below the Quick Prompts grid on `HomeView`. Submitting pushes `ChatView` with the typed text as `initialMessage`. Home's quick-prompt tiles converted from inline `NavigationLink` to `Button`s driving one shared `navigationDestination(item:)` target so all Home → Chat nav flows through a single path.
- **Keyboard dismissal fixes on Home input**: `@FocusState` binding on the TextField, `isCustomPromptFocused = false` on submit, and `.scrollDismissesKeyboard(.interactively)` on the Home ScrollView. Previously the keyboard could get stuck up after typing in the input and navigating around.
- **Markdown rendering for assistant replies**: `ChatView.assistantIntro` now parses content through `AttributedString(markdown:, options: .inlineOnlyPreservingWhitespace)`, so `**bold**` / `*italic*` / newlines render properly. Root cause was `Text(variable)` — SwiftUI only interprets markdown from `LocalizedStringKey` literals. This mainly surfaced on conversational follow-ups like "write me a prayer from those verses" where Claude returned prose instead of the structured JSON schema.
- **Save prayers as favorites**: new `SavedPrayer` SwiftData model (`Seek/Models/SavedPrayer.swift`), registered in the model container. `ChatView.prayerCard` now has Favorite + Create Card buttons mirroring the verse card UX. `togglePrayerFavorite` stores the current `lastUserPrompt` as `contextNote` so the saved prayer knows which question produced it.
- **Prayer → Card flow**: new `CardCreatorView.init(prayerText:)` initializer reuses the existing verse-card templates with `"A Prayer"` as the reference line (no new template system — first-pass reuse).
- **Favorites tab rebuild**: merged list of `FavoriteVerse` + `SavedPrayer` sorted newest-first via a `FavoriteItem` enum. New filter chips row (**All / Verses / Prayers**) styled as sage-green capsules above the list. Prayer rows use the gold "Prayer" chip to distinguish from verses. Swipe-to-delete routes to the correct model. Empty states change per filter.
- **Regenerate scripture button**: new `regenerateBar` above the input in `ChatView`, only visible when `canRegenerate` is true (not loading, `lastUserPrompt` exists, last display message is actual content — verses/prayer/song/action/follow-up). Tap strips the trailing assistant messages back to the user bubble, drops the matching assistant entry from `conversationHistory`, and re-sends with a hint appended to history ("Please share different scriptures for my previous message on the same topic."). No duplicate user bubble appears.
- Extracted `ChatView.renderResponse(_:)` helper so `sendMessage` and `regenerateScripture` share one append/persist/stats-bump code path.

### Decisions
- **Prayer cards reuse verse templates** for now — reference line shows "A Prayer". If prayer cards need distinct styling later, add a separate template subset.
- **Markdown fix is a bandaid**, not an architectural fix. The real root cause is that the chat Edge Function has exactly one response schema (scripture-seek). Conversational follow-ups that don't fit that schema return markdown prose. Proper fix is a multi-mode chat (e.g. `{mode: "conversation", message: "..."}` vs `{mode: "scripture_seek", verses: [...]}`). Deferring to a future session.
- **Regenerated responses append** to the conversation in SwiftData rather than replacing the prior one. When reopening a conversation via History, both responses render stacked. Chose append over replace because destroying data on a tap felt wrong.
- **Regenerate costs a chat credit** — it's a real Claude API call. Didn't try to make it free because that would require server-side "regeneration token" tracking.
- Regenerate hint goes into `conversationHistory` only, not into the visible `messages` list — user's original prompt stays as the anchor.

### Gotchas discovered
- **SwiftUI `Text(variable)` does not render markdown.** Only `Text(LocalizedStringKey("literal"))` and `Text(attributedString)` do. Fix is `Text(AttributedString(markdown: str, options: .inlineOnlyPreservingWhitespace))` — the `inlineOnlyPreservingWhitespace` option is critical to keep newlines intact for multi-paragraph content.
- **TextField focus persists through NavigationStack push.** Without `@FocusState` + `scrollDismissesKeyboard`, the keyboard stayed up when navigating from Home → Chat and back. Three-layer fix: focus-state binding, explicit `false` on submit, and interactive scroll dismissal.
- **SourceKit can go completely out of sync after `xcodegen generate`**, reporting dozens of phantom "Cannot find type" errors on unchanged code. They resolve after the next real build. `xcodebuild` is the source of truth, not the inline diagnostics panel.
- **`xcodebuild archive` needs `-allowProvisioningUpdates`** for automatic signing to work. Even then, if Xcode's Accounts pane isn't signed in, the CLI sees "No Account for Team" — archive must then happen via Xcode GUI where keychain access is full.

### Current Status
- Phase 1 MVP: ~90% complete
- All core features working: auth, chat with NLT/KJV + markdown fallback, card creator (verses + prayers), library with filtered favorites, streaks, notifications, monetization, regenerate scripture
- Remaining: Professional app icon, launch screen, App Store screenshots/metadata, privacy labels, offline mode, final QA
- Build number bumped 4 → 5 in `project.yml` / `CURRENT_PROJECT_VERSION`
- Code builds clean; user to archive + upload via Xcode Organizer (CLI archive blocked on Apple Developer account auth)

## 2026-04-17 — Session 9 (Design handoff, app icon, launch screen, marketing landing page)

### Infra
- Public GitHub repo created at [github.com/garvonious-ui/Seek](https://github.com/garvonious-ui/Seek); `main` pushed. Cleared to be public because the only "sensitive" string in the tree is the Supabase anon JWT (role: "anon"), which is designed to ship in client bundles and is protected by RLS policies. No service-role key, no Anthropic key, no secrets tracked.
- Exported system Georgia family (4 weights) to `~/Downloads/Seek-Fonts/` for upload to Claude Design's brand system setup.

### Design handoff
- Ingested a Claude Design bundle (tarball from `api.anthropic.com/v1/design/h/...`) and a downloaded zip of its `exports/` folder. Both contained identical icon/wordmark PNGs; the zip's README was richer, with full implementation specs for launch screen, onboarding refinement, and a marketing landing page.
- Key files used: `project/Seek App Icon.html` (icon source of truth), `project/Seek Logos.html` (wordmark Logo 01 spec), `exports/icon_1024.png`, `exports/wordmark_*.png`, full `colors_and_type.css` tokens.

### App icon
- Replaced the placeholder `AppIcon.png` at `Seek/Assets.xcassets/AppIcon.appiconset/AppIcon.png` with the Claude Design deliverable's `icon_1024.png`. Contents.json unchanged — project uses the modern single-file 1024 universal format, iOS 17+ generates all smaller sizes.
- Design: cream `#FAFAF6` squircle (iOS standard 22.5% radius), dark Georgia upright "S" at 72% size, small gold `#CDA349` dot at top-right as accent.

### Launch screen
- Added `Wordmark.imageset` and `LaunchBackground.colorset` (= `#FAFAF6`) to the asset catalog.
- New `Seek/Resources/LaunchScreen.storyboard` — LaunchBackground fill, wordmark ImageView centered (240pt wide × 120pt tall to match the 2:1 aspect of the regenerated PNG), "SCRIPTURE FOR EVERY MOMENT" UILabel below (+16pt gap, system medium 12pt, `#6B7280`, NSKern = 1.92 which matches CSS +0.16em at 12pt).
- `project.yml` swap: `INFOPLIST_KEY_UILaunchScreen_Generation: YES` → `INFOPLIST_KEY_UILaunchStoryboardName: LaunchScreen`. `xcodegen generate` + `xcodebuild` on `iphonesimulator` confirmed `UILaunchStoryboardName = LaunchScreen` in built Info.plist and the `Assets.car` compiled with both new resources.

### Wordmark regeneration (important correctness fix)
- **The shipped `wordmark_dark.png` did not match the HTML spec.** The PNG rendered the gold dot as a tittle directly above the "k" (as if dotting an "i"), but `Seek Logos.html` Logo 01 placed it as a superscript after the "k" (`margin-left: 2px; transform: translateY(-0.72em)`). The user caught this on first visual review.
- Regenerated the PNG with Python + Pillow + `/System/Library/Fonts/Supplemental/Georgia.ttf`: Georgia at 4× the 96pt base for crispness, letter-spacing `-0.015em` applied glyph-by-glyph via `font.getlength()` + manual x-advance, gold dot ellipse drawn at the computed baseline-offset position after "k". Output cropped with 20pt margin. Writes directly to `Seek/Assets.xcassets/Wordmark.imageset/wordmark_dark.png`, used by both the launch storyboard and the landing page.

### HomeView wordmark swap
- Replaced `.navigationTitle("Seek")` with `.navigationTitle("")` + `.toolbarTitleDisplayMode(.inline)` and inserted the `Image("Wordmark")` at the top of the ScrollView VStack (leading-aligned, 44pt tall, padded horizontally). The profile icon in `.topBarTrailing` still renders in the now-inline nav bar.

### Marketing landing page
- New `landing/index.html` — single self-contained static site, inline CSS, no build step. Assets at `landing/assets/wordmark_dark.png` + `icon.png` + `wordmark_sage.png`.
- Sections: nav, hero (headline + subhead + waitlist form + full-Home-screen iPhone mock with tab bar), "How it works" 3-up, AI spotlight (bulleted features + full chat mock with user bubble → AI intro → verse tiles → prayer tile → worship song tile), 3-template verse card showcase (cream/sage/gold CSS gradients), "More ways Seek meets you" features strip (Daily Verse, Streaks, Worship songs), secondary waitlist CTA, footer.
- Iterated twice: first pass had a sparse single-card verse section and a phone mock that only showed the top of Home. Fixed by bumping nav wordmark 28→44px, restructuring `.device .screen` as flex column with a pinned tab bar, and rebuilding the showcase as a 3-template grid.

### Waitlist backend
- Migration `create_waitlist_table`: `create extension citext; create table public.waitlist (id bigserial pk, email citext unique, source text default 'landing', created_at timestamptz default now())`.
- RLS policy `anon_insert_waitlist`: allows anon + authenticated INSERT only, WITH CHECK validating email format (regex), length ≤ 254, and `source = 'landing'` (prevents clients from spoofing the source field). No SELECT/UPDATE/DELETE for anon — the list is write-only to the public.
- Landing page JS auto-wires every `form.waitlist` — POSTs to `/rest/v1/waitlist` with the anon JWT (same key the iOS app ships), prefers `return=minimal`, handles 201 (success), 409 (already on list — treated as success for UX), everything else (format reject etc. → generic error + re-enable).
- Smoke-tested via curl: valid → 201, duplicate → 409, malformed email → 401, tampered `source` → 401, anon SELECT → `[]`. Test row cleaned up.

### Decisions
- **Use Claude Design's PNG exports but verify against the HTML source.** The icon PNG was fine; the wordmark PNG diverged from the HTML spec. Rule going forward: when Claude Design ships both HTML source and PNG exports, treat the HTML as the source of truth and spot-check the PNGs before committing.
- **Public GitHub repo.** Anon Supabase JWT is safe to publish (designed for client bundles, protected by RLS). No service role key, no Anthropic API key, no secrets tracked.
- **Landing page is vanilla HTML/CSS, no framework.** Single file, deployable anywhere. One JS `<script>` for the Supabase POST. Zero build step.
- **Waitlist list is write-only to the public.** Anon role gets INSERT only, no SELECT. Operator reads the list via Supabase dashboard (service role). This is the right default for any "public form" pattern in this stack.
- **Landing `source` field is server-validated.** Without the CHECK constraint, a motivated browser user could POST `{source: "spam"}` and pollute segmentation. Locking `source = 'landing'` via RLS prevents that.
- **iPhone mock on landing is pure CSS, not a real screenshot.** Faithful enough for a pre-launch marketing page; real screenshots go into App Store assets later.
- **Duplicate email returns 409 but shows "you're already on the list" as a success-kind message** rather than an error. Minor privacy consideration (reveals email-is-registered state) but the right UX for a pre-launch waitlist.

### Gotchas discovered
- **iOS caches the launch storyboard aggressively.** Even after a new build deploys, the OS serves the prior splash assets. User saw the old "dot over k" wordmark on splash even after the corrected PNG had shipped. Fix: delete the app from the device, clean build folder in Xcode, re-deploy. This is a real documented iOS behavior, not an Xcode quirk. Add to CLAUDE.md.
- **Claude Design PNG exports can diverge from the HTML source.** Treat the HTML+CSS as the source of truth, verify PNGs visually, and re-render from the HTML spec when they don't match. Add to CLAUDE.md.
- **Supabase PostgREST returns 401 (not 400/403) for RLS WITH CHECK violations.** Our smoke test showed tampered source + malformed email both coming back as 401 from `/rest/v1/waitlist`. Worth knowing for future client error classification — don't assume 401 always means auth failure.
- **PIL letter-spacing requires manual glyph-by-glyph x-advance.** `ImageDraw.text()` has no kern/tracking parameter. Applied CSS `letter-spacing` by iterating characters, measuring each with `font.getlength()`, and advancing x by `advance + kern_px` per character.

### Current Status
- Phase 1 MVP: ~95% complete.
- App icon and launch screen are done and in the tree — biggest remaining items from Phase 1 Polish were these, now checked off.
- Marketing landing page is built and the waitlist is live on Supabase. Needs a host and real Privacy/Terms URLs before it goes public.
- Remaining code-adjacent work: none. Remaining asset/submission work: App Store screenshots, App Store description + metadata, privacy nutrition labels, final QA pass, submission.
- Build number unchanged from Session 7 (still 6). Next TestFlight upload will pick up the new icon and launch screen — needs Xcode GUI archive (CLI archive still blocked on Apple Developer account auth).
- **Validation needed next session**: user should delete Seek from their phone, clean build folder, reinstall fresh to verify the corrected wordmark shows on splash (iOS launch-screen cache).

## 2026-04-14 — Session 8 (Claude fallback model fix)

### Bug fix: chat Edge Function fallback was pointing at a non-existent model
- Triggered by an Anthropic email warning that `claude-sonnet-4` (the bare alias for the original Sonnet 4 from May 2025) is being retired June 15, 2026, with degraded availability starting May 14.
- We don't use the bare alias — primary is `claude-sonnet-4-6` (Sonnet 4.6, current latest), which is unaffected. So the email itself didn't break anything for us.
- BUT the audit it prompted exposed a real latent bug: the fallback `claude-sonnet-4-5-20241022` is **not a valid model ID**. The real Sonnet 4.5 ID is `claude-sonnet-4-5-20250929`. The `20241022` date string was a hallucination from Session 5 when the fallback was originally added. The fallback would have 4xx'd with "model not found" the first time it actually fired.
- Fix: updated `CLAUDE_MODEL_FALLBACK` to the real `claude-sonnet-4-5-20250929` ID after cross-checking against `platform.claude.com/docs/en/about-claude/models/overview`.
- Added an inline comment in `chat/index.ts` documenting why the fallback is what it is and warning future-me to always cross-check model IDs before pinning.
- Edge Function redeployed (`supabase functions deploy chat --no-verify-jwt`).

### Why Sonnet 4.5 as the fallback (not Opus 4.6 or Haiku 4.5)
- **Opus 4.6** ($5/$25): would silently bill 5x more if the fallback ever fires. Overkill for scripture matching.
- **Haiku 4.5** ($1/$5): cheaper but smaller (200k context, no adaptive thinking). The chat function emits a strict JSON schema with 3000-token responses; safer to keep the fallback in the same family with the same characteristics.
- **Sonnet 4.5** ($3/$15): same price as primary, listed under "Legacy models" in the docs which means still supported but not bleeding edge. Same family, same prompt behavior, same context window. Ideal fallback semantics.

### Decisions
- Server-side fix only — no iOS rebuild, no TestFlight upload required. Live for everyone immediately.
- Did not touch the primary model — `claude-sonnet-4-6` is current and the email targets a different older model entirely.
- Added a new gotcha to CLAUDE.md: NEVER invent a Claude model ID, always verify against the official docs page. Twice now (Session 5 and Session 8) we've shipped invalid fallback IDs that would have 4xx'd on first use.

### Anthropic deprecation deadlines (for future reference)
- `claude-sonnet-4-20250514` (Sonnet 4 base) — retires June 15, 2026
- `claude-opus-4-20250514` — retires June 15, 2026
- `claude-3-haiku-20240307` — retires April 19, 2026
- We use NONE of these. Current latest Sonnet is `claude-sonnet-4-6`, current latest Haiku is `claude-haiku-4-5-20251001`, current latest Opus is `claude-opus-4-6`.

### Current Status
- Phase 1 MVP: ~92% complete (unchanged from Session 7)
- Chat is back on solid ground: primary on the latest Sonnet, fallback on a real Sonnet 4.5 ID that will actually work if the primary errors
- Build 6 already on TestFlight from Session 7; no new client build needed for this fix
- Remaining (non-code or asset work): Professional app icon, launch screen, App Store screenshots/metadata, privacy labels, AdMob (deferred), final QA, submission

## 2026-04-14 — Session 7 (Offline mode handling)

### Built
- **NetworkMonitor service** (`Seek/Services/NetworkMonitor.swift`): `@Observable` wrapper around `NWPathMonitor` that publishes `isConnected` and `isExpensive`. Starts with `isConnected = true` so the first paint doesn't flash offline while the monitor warms up. Injected at the app root via `.environment(networkMonitor)` in `SeekApp.swift`.
- **DailyVerseCache** (`Seek/Services/DailyVerseCache.swift`): tiny single-slot `UserDefaults`-backed cache that persists the most recent successful `DailyVerse` fetch with its fetch timestamp. Not a history — one entry, overwritten on each successful fetch.
- **HomeView offline handling**:
  - New "Offline" pill below the streak capsule when `!networkMonitor.isConnected`.
  - New "Saved copy" badge next to the Daily Verse header when the card is rendering the cached copy instead of a fresh fetch.
  - `loadDailyVerse` shows any cached verse immediately, then only hits the network if connected. On failure it keeps the cached copy in place and flips the "Saved copy" badge on. On success it caches the new verse and clears the badge.
  - `.onChange(of: networkMonitor.isConnected)` auto-refreshes the daily verse (and premium status) as soon as the device reconnects, so users don't have to pull-to-refresh after regaining signal.
- **ChatView offline handling**:
  - New offline banner above the input bar: "You're offline. Scripture chat will resume when you reconnect." Uses the same gray `F3F4F6` treatment as the existing rate-limit banner.
  - Input placeholder switches to "Waiting for connection..." when offline; both the TextField and the send button are disabled.
  - `isSendDisabled` now factors in `networkMonitor.isConnected` alongside empty text and in-flight loading.
  - `canRegenerate` returns false when offline, so the Regenerate Scripture bar disappears the moment signal drops.
  - `sendMessage` has an upfront guard that appends a plain offline error bubble if called without a connection (belt-and-suspenders for auto-submit from `initialMessage`).
  - New `classifyChatError(_:)` helper replaces the inline rate-limit/generic branch in both `sendMessage` and `regenerateScripture`. It prefers a dedicated offline error when `NetworkMonitor` says we're offline OR when the thrown `NSError` is an `NSURLErrorDomain` in the usual "no connection" code set (`NSURLErrorNotConnectedToInternet`, `NSURLErrorNetworkConnectionLost`, `NSURLErrorTimedOut`, `NSURLErrorCannotConnectToHost`, `NSURLErrorCannotFindHost`, `NSURLErrorDNSLookupFailed`, `NSURLErrorInternationalRoamingOff`, `NSURLErrorDataNotAllowed`). Rate limit (`429`/`daily_limit`) still wins when we're online; generic "something went wrong" is the final fallback.
- Previews for HomeView and ChatView updated to inject `NetworkMonitor()` alongside the existing AuthManager/ModelContainer.
- Build number bumped 5 → 6 in `project.yml`.

### Decisions
- **Cache is a single slot**, not a history. The daily-verse endpoint returns a different verse per day, so "last one we successfully fetched" is the only meaningful offline state. Simpler than dated bucketing and avoids stale 7-day-old verses piling up in UserDefaults.
- **Offline card keeps the evergreen Psalm 46:1 fallback** for the first-run-no-cache-no-network case. Without this the card would render empty on a brand new install launched in airplane mode.
- **Chat hard-blocks sends when offline** rather than queueing them for later retry. Queue-and-resend introduces ordering bugs (user sends A while offline, comes online and types B, which runs first if B's round trip is faster) and the UX gain is thin — users just reconnect and retype. Revisit only if TestFlight feedback asks for it.
- **Library/Cards/Favorites need zero offline work** — they're already SwiftData-backed and CardCreatorView is pure local render via ImageRenderer. Verified by grep; no placeholder code added.
- **Sign-in offline story is the existing `error.localizedDescription`** from Supabase. Not polished here; a dedicated offline state on SignInView is a future session if beta testers complain.

### Gotchas confirmed (not new)
- **Stale SourceKit after file adds** — SourceKit flagged dozens of phantom "Cannot find type" errors on `NetworkMonitor`, `AuthManager`, `DailyVerse`, etc. even in files I hadn't touched. `xcodebuild` was clean on the first run. This is the gotcha from Session 6's changelog: always trust `xcodebuild`, not inline diagnostics.
- The Network framework is in the iOS SDK — no new SPM dependency or `project.yml` change needed to import `Network` and use `NWPathMonitor`.

### Current Status
- Phase 1 MVP: ~92% complete
- Offline mode is the last substantive code feature from the Phase 1 checklist. All core features work gracefully offline now: home shows cached daily verse + offline pill, chat blocks cleanly with a dedicated banner, library/cards/favorites untouched because they're already local-only.
- Remaining (non-code or asset work): Professional app icon, launch screen, App Store screenshots/metadata, privacy labels, AdMob (deferred), final QA, submission.
- Build 6 compiles clean, needs archive + TestFlight upload via Xcode GUI (same pattern as Session 6 — CLI archive blocked on Apple Developer account auth).
- To verify the offline paths manually: toggle Airplane Mode in simulator/device, expect the Offline pill on Home, "Saved copy" badge on Daily Verse after the first successful fetch, the offline banner + disabled input in Chat, and an auto-refresh when you turn Airplane Mode back off.

## 2026-04-13 — Session 5 (Chat 502 Fix + Password Reset)

### Bug fix: chat Edge Function returning 502 on every request
- Root cause: model ID `claude-sonnet-4-20250514` had been deprecated by Anthropic. Every chat call failed because Claude API rejected the model name, the Edge Function caught the non-OK response, and returned 502 with "Something went wrong finding scripture for you."
- Fix: updated model ID to `claude-sonnet-4-6` in `supabase/functions/chat/index.ts`
- Diagnosed via Supabase edge-function logs (all chat POSTs returning 502, daily-verse fine) — confirmed the failure was downstream of Supabase itself

### Resilience improvement: model fallback
- Added `CLAUDE_MODEL_FALLBACK = "claude-sonnet-4-5-20241022"` constant
- Refactored Claude API call into a `callClaude(model)` helper
- If primary model returns a non-429 error, automatically retries with the fallback
- 429 (rate limit) errors are NOT retried (don't spam on rate limits)
- Improved error logging: `console.error` now includes model name and HTTP status code alongside the error body, so future deprecations are visible in Supabase logs immediately

### Built: password reset flow
- New `SupabaseService.resetPassword(email:)` — calls `client.auth.resetPasswordForEmail(email)`
- New `AuthManager.resetPassword(email:)` — async wrapper with error handling, sets `resetPasswordSent` flag on success
- `SignInView`: added "Forgot Password?" button below the password field, visible only when `!isSignUp`. Tap sends the reset email and shows a success alert ("Check your email for a password reset link"). Empty email shows inline error.
- Supabase sends the reset email via its default recovery flow (browser-based password reset form)

### Auth investigation (false alarm)
- Test user reported "invalid login credentials" — diagnosed via auth logs (`POST /token` with `grant_type: "password"` returning `invalid_credentials` from their IP)
- Queried `auth.users` to list existing accounts, confirmed user was typing the wrong email
- No code change needed — user error

### Decisions
- Model fallback is a belt-and-suspenders approach: pin to the latest known-good model, but don't let a silent deprecation take down chat again
- 429 errors should NOT trigger fallback (rate limits apply per key, not per model)
- Reset password uses Supabase's default browser-based flow for now — no deep-link-into-app flow needed for launch

### Gotchas discovered
- **Anthropic deprecates model IDs silently from the client's perspective** — the Edge Function gets a 4xx from `api.anthropic.com` but the generic 502 we return hides the underlying cause. Always include model name + status code in error logs, and keep a fallback model pinned.

### Current Status
- Phase 1 MVP: ~90% complete
- Chat is back online with `claude-sonnet-4-6` + automatic fallback
- Password reset shipped — test users who forget passwords can now self-serve
- All core features working: auth (Apple + email + reset), chat with NLT/KJV, card creator, library, streaks, notifications, monetization
- Remaining: Professional app icon, launch screen, App Store screenshots/metadata, privacy labels, offline mode, final QA
- Build passing, needs TestFlight upload to get fix to test users
