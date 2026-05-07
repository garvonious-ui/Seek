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
- **iOS caches the launch storyboard aggressively.** Even after a fresh `xcodebuild` + deploy, the OS will keep showing prior-build splash assets. To verify a changed launch screen on device: (1) delete the app from the phone, (2) Clean Build Folder in Xcode (⇧⌘K), (3) redeploy. A device reboot sometimes helps if step 1 alone isn't enough. Do not trust the phone's splash as a debugging signal until you've done this — the asset on disk can be correct while the device keeps showing the stale one.
- **Claude Design PNG exports can diverge from their own HTML source.** The shipped `wordmark_dark.png` in our design bundle placed the gold dot as a tittle over the "k", but `Seek Logos.html` Logo 01 specified a superscript dot after the "k" (`translateY(-0.72em)`). Treat the HTML+CSS in `project/*.html` as the source of truth, visually verify PNGs before shipping, and re-render from the HTML spec when they don't match. Renderable with Python + Pillow + `/System/Library/Fonts/Supplemental/Georgia.ttf` — PIL has no kern/tracking parameter, so CSS `letter-spacing` must be applied glyph-by-glyph via `font.getlength()` + manual x-advance.
- **Supabase PostgREST returns 401 (not 400/403) for RLS `WITH CHECK` violations.** Format-violating INSERTs and tampered-field INSERTs both come back as 401 from `/rest/v1/*`. Don't hardcode "401 = auth failure" in client error handling — for public anon-insert endpoints (waitlists, contact forms), a 401 after a 200-OK preflight means the row failed validation.
- **For public write-only tables (waitlists, contact forms): use `citext` email + `unique` + anon-INSERT-only RLS with a `WITH CHECK` that validates format AND pins any metadata fields to a fixed value.** Pattern in `public.waitlist` — anon can insert but cannot spoof `source` or submit malformed emails, and cannot read the list. Service role (Supabase dashboard) retains full access.
- **When inserting directly into `auth.users` via SQL (bypassing `auth.signUp`), `confirmation_token` / `recovery_token` / `email_change_token_new` / `email_change` MUST be `''` (empty string), not `NULL`.** GoTrue's user-lookup query filters those columns with non-null predicates, so a NULL value returns `500 unexpected_failure: "Database error querying schema"` on every login. The dashboard "Add user" UI sets them to `''` implicitly; raw SQL inserts don't. `information_schema` marks them as nullable with no default, which is misleading. Caught Session 13 while provisioning the App Review test account — fix is `update auth.users set confirmation_token='', recovery_token='', email_change_token_new='', email_change='' where id = ...`.
- **`.scrollDismissesKeyboard(.interactively)` alone is not discoverable UX.** Drag-down works, but most users never find it. For any focused TextField in a chat-style view, ALSO add a keyboard accessory Done button: `.toolbar { ToolbarItemGroup(placement: .keyboard) { Spacer(); Button("Done") { isInputFocused = false } } }` paired with `@FocusState private var isInputFocused: Bool` and `.focused($isInputFocused)` on the field. Auto-dismiss on `sendMessage()` too so the keyboard collapses out of the way of incoming response cards. Caught Session 15 — first-pass ChatView shipped without it and the keyboard could not be collapsed once expanded.
- **SwiftUI `.transition(...)` only fires when the underlying state change is wrapped in `withAnimation`.** A row in `LazyVStack { ForEach(messages) }` with `.transition(.opacity)` will still appear instantly if the append is bare `messages.append(...)`. Wrap each append: `withAnimation(.easeOut(duration: 0.3)) { messages.append(...) }`. For staggered reveals (e.g. response cards streaming in), put a `try? await Task.sleep(for: .milliseconds(140))` between each animated append in an `@MainActor async` function — 140ms reads as deliberate pacing, less feels like a single dump, more feels artificially slow.
- **Never name a stored property on a SwiftUI `View` `body`.** It collides with `View`'s required `var body: some View` and the compiler reports "invalid redeclaration of 'body'" pointing at the computed property line — NOT the offending stored property. SourceKit also surfaces the same redeclaration error as a phantom in unrelated files. Rename the parameter (`let message: String`, `let content: String`, etc.). Caught Session 16 in `GuestGateView`.

## Supabase Project
- Ref: hxfiaowayrhuhzhhbaix
- Region: East US (North Virginia)
- Bundle ID: com.loucesario.seek

## Current Phase
Phase 1 — MVP (App Store Ready)
See @docs/build-plan.md for task checklist
