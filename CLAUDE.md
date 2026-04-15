# Seek — AI-powered scripture companion for iOS

## What This Is
A native iOS SwiftUI app where users share what's on their heart — joy, gratitude, struggle, seeking — an AI surfaces 3-5 relevant Bible verses with a prayer and worship song recommendation, and they create beautiful shareable verse cards. Also includes daily verse notifications and streak tracking. Free with ads, premium tier removes ads and increases AI chat limit.

## Tech Stack
- SwiftUI (iOS 17+), Swift 5.9+
- SwiftData (local persistence), Supabase (Auth, PostgreSQL, Edge Functions)
- Claude API via Supabase Edge Functions proxy
- KJV Bible bundled as JSON (public domain)
- StoreKit 2 for subscriptions, AdMob for ads

## Critical Rules
- NEVER call Claude API directly from client — always through Supabase Edge Function proxy
- Scripture text always renders in serif font (Georgia/New York), distinct from UI text
- Rate limit: 5 free chats/day, 50 premium — tracked server-side in Supabase usage_logs table
- Default translation is NLT; user can switch to KJV in Settings. Translation preference stored in UserProfile.preferredTranslation and Supabase profiles.preferred_translation
- Denominationally neutral tone — no specific church doctrine in any AI response
- Crisis language in chat must surface scripture AND encourage professional help
- Match user's emotional energy — celebrate with those who celebrate, don't default to "comfort" tone
- All schemas and IDs are in @docs/schemas.md — always reference before data work

## Session Rules
- BEFORE starting work: read @docs/build-plan.md and @docs/changelog.md
- AFTER completing a feature or before /clear: update both files
- If session runs longer than 30 minutes, pause and offer to update changelog
- When I say "wrap up": update build-plan checkboxes, write changelog entry, summarize

## Reference Docs
- Architecture: @docs/architecture.md
- Schemas + IDs: @docs/schemas.md
- Build plan: @docs/build-plan.md
- Design system: @docs/design-system.md
- API routes: @docs/api-routes.md
- Screen specs: @docs/screens.md

## Commands
- Cmd+R — build and run in simulator
- Cmd+B — build only
- Cmd+Shift+K — clean build folder

## Gotchas (Learned the Hard Way)
- ALWAYS force light mode — `INFOPLIST_KEY_UIUserInterfaceStyle: Light` in project.yml AND `.preferredColorScheme(.light)` on root view
- NEVER use `Color(.systemGray6)` or any adaptive system colors — use explicit hex `Color(hex: "F3F4F6")`
- NEVER use `.foregroundStyle(.secondary)` — use explicit `Color(hex: "6B7280")`
- `@Observable` CANNOT track computed properties that read from UserDefaults — use a stored property with `didSet` to persist
- `scaleEffect()` on large views (1080x1920) does NOT work for previews — the layout engine still allocates full size. Use inline screen-sized preview instead.
- `.sheet(item:)` is more reliable than `.sheet(isPresented:)` when the sheet content depends on state set at tap time
- `xcodegen generate` resets the signing team — user must re-select in Xcode
- Integer division in Swift: `250/255 = 0` not `0.98`. Use `250.0/255.0` for UIColor
- Claude API may return JSON wrapped in markdown fences — always strip them server-side
- Claude chat Edge Function `max_tokens` must be ≥3000 — full responses (3-5 verses + prayer + song + action) easily exceed 1500 tokens, causing truncated JSON that displays as raw text
- After `xcodegen generate`, always verify the build number in Xcode matches project.yml — Xcode may cache the old value
- Edge Functions with `verify_jwt = true` block the auth token from reaching the function code — use `--no-verify-jwt` and validate in-function
- SwiftData @Model: new stored properties MUST have default values on the declaration (`var foo: String = "default"`), not just in the init parameter. Without declaration-level defaults, SwiftData can't perform lightweight migration and may wipe the local store.
- NEVER nest Buttons in SwiftUI — the outer button swallows inner button taps. Use separate buttons side by side instead.
- Anthropic silently deprecates model IDs — pin the chat Edge Function to a current model AND keep a `CLAUDE_MODEL_FALLBACK` constant with retry logic. Log `model + status + errBody` on every Claude API failure so future deprecations surface in Supabase logs instead of hiding behind a generic 502.
- NEVER invent a Claude model ID — the date strings are not predictable and a hallucinated ID will silently break the fallback path until it fires for real. Always verify against `https://platform.claude.com/docs/en/about-claude/models/overview` before pinning. Twice now we've shipped invalid fallback IDs that would have 4xx'd if they'd ever been called.
- `NWPathMonitor`-backed reachability services must start OPTIMISTIC (`isConnected = true`). The monitor takes a beat to call `pathUpdateHandler` on launch, and any offline UI gated on `isConnected` will flash briefly on every cold start if you default to false.
- Classify network errors by `NSURLErrorDomain` + code set (`NotConnectedToInternet`, `NetworkConnectionLost`, `TimedOut`, `CannotConnectToHost`, `CannotFindHost`, `DNSLookupFailed`, `InternationalRoamingOff`, `DataNotAllowed`), NOT by string-matching `error.localizedDescription`. Localized strings are user-facing and change between iOS versions and locales.

## Supabase Project
- Ref: hxfiaowayrhuhzhhbaix
- Region: East US (North Virginia)
- Bundle ID: com.loucesario.seek

## Current Phase
Phase 1 — MVP (App Store Ready)
See @docs/build-plan.md for task checklist
