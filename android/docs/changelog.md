# Seek for Android — Changelog

## 2026-05-25 — Session A5 (Phase 4: notifications + offline, verified on emulator)

### Built
- **Local notifications** — `SeekNotifications` (channel + daily-verse/streak
  builders, tap→MainActivity), `NotificationScheduler` (AlarmManager
  `setInexactRepeating` — no exact-alarm permission needed), `NotificationReceiver`.
- **POST_NOTIFICATIONS** runtime request (Android 13+) via Compose
  `rememberLauncherForActivityResult`.
- **Notification settings in Profile** — Daily verse (7am) + Streak nudge (7pm)
  toggles persisted to DataStore (`NotificationPrefs`), schedule/cancel on
  change, "Send a test reminder".
- **Offline handling** — `ConnectivityObserver` (callbackFlow over
  ConnectivityManager); Home offline pill + verse fallback ("· offline" badge);
  Chat offline banner + disabled send.

### Verified on emulator (screenshots)
- Profile → notification toggles + "Send a test reminder". ✅
- Tapped test → **system permission dialog** ("Allow Seek to send you
  notifications?") → Allow → notification **fired in the shade**: "Your Daily
  Verse — Start your day with God's word." ✅
- Airplane mode → Home shows **"Offline" pill** + daily verse falls back to
  **"Psalm 46:1 · offline"**. ✅

### Two crash/bug fixes (the blockers)
1. **Startup crash** — `registerDefaultNetworkCallback` threw
   `SecurityException` (ConnectivityService.enforceAccessPermission). Missing
   `ACCESS_NETWORK_STATE`. Added it.
   - **Gotcha:** any ConnectivityManager network-callback use needs
     `ACCESS_NETWORK_STATE` (a normal install-time permission), not just INTERNET.
2. **Offline never detected when opening already-offline** — the observer seeded
   an optimistic `true` and waited for a NetworkCallback event that never fires
   when nothing changes. Fixed: seed the **actual current state** synchronously
   via `getNetworkCapabilities`, and require `NET_CAPABILITY_VALIDATED` (not just
   INTERNET) so "connected, no real internet" reads offline.

### Notes
- While offline, supabase-kt can't restore the session (network-gated), so a
  cold start offline lands on the onboarding gate — expected. The Home offline
  path (pill + fallback) was verified via guest mode.
- Supabase `notification_settings` sync, notification deep links, and skeleton
  loaders deferred.

### Next
- Phase 5: Play Store prep (real icon, Lora font, listing, internal testing).

## 2026-05-25 — Session A4 (Phase 3: card creator + library, verified on emulator)

### Built
- **`CardRenderer`** — a single Android-Canvas renderer producing an exact
  1080×1920 Bitmap (vertical gradient bg, auto-fit serif verse, reference,
  "Seek" watermark). Used for BOTH the preview and the export, so they can't
  diverge (the iOS gotcha where preview ≠ export). 6 templates across categories.
- **`CardExport`** — save-to-gallery via MediaStore (Pictures/Seek) + share via
  FileProvider. FileProvider + `WRITE_EXTERNAL_STORAGE` (maxSdk 28) wired in
  manifest; `res/xml/file_paths.xml` added.
- **CardCreatorScreen** — live preview (rendered Bitmap), horizontal template
  picker, Share + Save; persists a SavedCard to Room. Reached via an in-memory
  `CardDraft` holder (avoids URL-encoding verse text through nav args).
- **Entry points** — tap the Home daily verse OR a chat verse card → creator.
- **Library** — real Cards / Favorites / History tabs from Room
  (`LibraryViewModel` flows). Cards grid re-renders thumbnails from stored
  template+verse via `CardRenderer`. Empty states; guest gate retained.

### Verified on emulator (screenshots)
- Signed-in Home → tapped daily verse (Matthew 21:22) → **Create card** opened
  with a sage-gradient preview. ✅
- Switched to the **Gold** template → preview re-rendered live (gold gradient,
  dark text). ✅
- **Save** → "Saved to your gallery" snackbar (MediaStore write succeeded). ✅
- **Library → Cards** → the saved Gold card appears in the grid, re-rendered
  from Room. ✅

### Notes / deferred
- 6 templates for now (iOS has 18); favoriting to populate the Favorites tab,
  card delete/edit mode, and worship deep links are deferred polish.
- Screenshots from `adb` are 1080×2400 — downscale with `sips -Z 1500` before
  reading (the reader rejects >2000px in multi-image turns).

### Next
- Phase 4: scheduled local notifications (daily verse + streak nudge), offline
  handling, loading/error polish.

## 2026-05-25 — Session A3 (Phase 2: scripture chat, verified on emulator)

### Built
- **ChatViewModel** — sends through the shared `chat` Edge Function with
  conversation history + translation, maps the structured response to display
  items (intro / verses / prayer / worship song / follow-up / rate-limit /
  error), and persists conversation + messages to Room.
- **Chat UI** — message transcript (LazyColumn, auto-scroll), sage user bubbles,
  white verse cards (serif scripture), gold PRAYER card, WORSHIP card, italic
  follow-up; input bar with send; empty "What's on your heart?" state. Guests
  still see the sign-in gate.

### Verified on emulator (screenshots)
- Provisioned a confirmed test user via Supabase MCP
  (`androidtest@askseekpray.app`, premium, NLT) — replicating the iOS Session 13
  pattern (empty-string token columns; `email` identity row; profile trigger
  fired).
- Signed in **through the app** with email/password → authenticated Home
  (🔥 streak capsule now visible; "What's on your heart?" label). ✅
- Chat: typed "I feel anxious about the future" → sent → **full Claude
  response rendered**: verse + context, gold prayer card ("Lord, I bring my
  anxious heart to You right now…"), worship song, and a follow-up question. ✅

### Two timeout fixes (the only blockers)
Diagnosed via logcat — chat threw, UI showed the error card correctly:
1. `POST /functions/v1/chat timed out after 10000 ms` — ktor's request timeout.
   Fixed: `requestTimeout = 60.seconds`.
2. Then `SocketTimeoutException` from OkHttp (its **own** 10s socket timeout,
   independent of ktor). Fixed: explicit `OkHttp.create { config { callTimeout
   / readTimeout = 60s } }` as the `httpEngine`.
   - **Gotcha:** the `chat` function (Claude generating 3-5 verses + prayer +
     song) routinely exceeds 10s. BOTH the ktor request timeout AND the OkHttp
     engine socket/call timeout must be raised — they're separate ceilings.

### Notes
- Chat state resets if the Chat destination is popped via system BACK (nav
  lifecycle); persisted to Room regardless. Flagged as polish.
- Worship deep links, staggered reveal, regenerate — deferred.

### Next
- Phase 3: Card Creator + Library (Compose→Bitmap render, save/share, tabs).

## 2026-05-25 — Session A2 (Phase 1: auth + live Home, verified on emulator)

### Built
- **AuthViewModel** — email sign-in/up + password reset via supabase-kt, browser
  OAuth for Google/Apple, guest mode, sign-out. Every success path calls
  `SessionRepository.onAuthSuccess()` directly (atomic flag flip — the iOS
  Build 8/9 lesson), with a defensive `sessionStatus` listener for cold-start
  restoration only.
- **Auth gate** (`SeekApp`) routes: authenticated/guest → 3-tab shell;
  otherwise → onboarding.
- **Onboarding**: gold-halo Welcome → SignIn (email form, Forgot password,
  Google/Apple buttons, "Continue without an account").
- **Home (live)**: `HomeViewModel` fetches `SeekApi.dailyVerse()` with an
  evergreen fallback; streak capsule (auth-only); quick-prompt grid; profile
  entry. Guest variant hides streak + relabels prompts.
- **Profile**: guest sign-in CTA (`exitGuest`) / authed sign-out.
- **Guest gates** on Chat + Library (reusable `GuestGate`).

### Verified on emulator (screenshots)
- Fresh launch → **Welcome** (gold halo, wordmark, Begin). ✅
- → **Sign In** (fields, disabled-while-empty button, social + guest). ✅
- "Continue without an account" → **Home**, and the daily verse came back
  **live from the Edge Function** ("1 John 5:4", NLT) — not the hardcoded
  fallback. Confirms guest anon-key → `daily-verse` works end to end. ✅
- Chat tab (guest) → **GuestGate** ("Sign in to chat"). ✅

### Build fixes this session
- `SeekApi.kt`: added supabase `functions` accessor + ktor `setBody` imports
  (confirmed signatures via `javap`).
- `SignInScreen.kt`: removed `cursorBrush` (not a Material3 OutlinedTextField
  param — it's BasicTextField only); cascaded into 6 errors, gone after removal.

### Needs external config (wired, not yet functional)
- **Google Sign-In**: needs a Google OAuth Web client ID in Supabase's Google
  provider. Code path ready.
- **Apple Sign-In (Android)**: needs the Apple OAuth Services ID + key in
  Supabase (iOS uses the native flow, which doesn't apply to Android). Code
  path ready.

### Next
- Phase 2: scripture chat (the core loop) against the shared `chat` function.

## 2026-05-25 — Session A1 (Phase 0 scaffold)

### Built
Native Kotlin + Jetpack Compose project scaffold under `android/`, against the
same Supabase backend as iOS (no backend changes).

- **Build config:** Gradle 8.11.1, AGP 8.7.3, Kotlin 2.0.21, version catalog
  (`libs.versions.toml`), `app` module (minSdk 26 / target 35), manifest with
  INTERNET + POST_NOTIFICATIONS + OAuth redirect intent-filter
  (`seek://auth-callback`), proguard rules for kotlinx.serialization.
- **Theme:** `SeekColors` tokens from `design-system.md`, `SeekTheme` locked to
  a fixed `lightColorScheme` (no dark mode, matching iOS forced-light),
  typography with `ScriptureFontFamily`/`ScriptureTextStyle`.
- **Persistence:** Room DB v1 with 6 entities (UserProfile, SavedCard,
  ChatConversation, ChatMessage, FavoriteVerse, SavedPrayer) mirroring the iOS
  SwiftData models in `schemas.md`; DAOs, type converters, `ConversationWithMessages`
  relation, singleton `SeekDatabase`.
- **Remote:** `SupabaseModule` (Auth + Postgrest + Functions) on project
  `hxfiaowayrhuhzhhbaix` with URL + public anon key via BuildConfig; `SeekApi`
  wrappers for `chat` and `daily-verse`; serializable DTOs matching `api-routes.md`.
- **Auth state:** `SessionRepository` implementing the correct pattern — trust
  `currentSessionOrNull()` over events, set derived flags atomically per
  success path, defensive `continueAsGuest`, explicit `signOut` reset. Encodes
  the lesson that cost iOS App Review Builds 8 & 9.
- **Shell:** `SeekApplication` (manual DI singletons), `MainActivity`, `SeekRoot`
  with 3-tab `NavigationBar` (Home/Chat/Library); Home renders a static daily
  verse on the theme; Chat/Library placeholders.
- **Docs:** project `CLAUDE.md`, `README.md` (build steps), this changelog, and
  `build-plan.md` (Phases 0–5).

### Decisions
- Scripture font ships as `FontFamily.Serif` (Noto Serif) — a zero-config
  stand-in for the design-target Lora (Georgia is proprietary, can't bundle).
  Swap is a one-line change once Lora is added via Android Studio's Google Fonts
  wizard.
- Launcher icon is a placeholder adaptive icon (cream bg + stylized serif S +
  gold dot vector) — regenerate from the real 1024px asset before Play submit.
- supabase-kt `functions.invoke` builder signature flagged for confirmation on
  first Gradle sync; request encoded to JSON string + decoded manually to avoid
  reified-type content-negotiation pitfalls.

### Not yet verified
- **No local Android toolchain** (no JDK/Gradle/SDK on this machine). The
  scaffold has NOT been compiled. First Gradle sync + run happens in Android
  Studio (same model as the iOS Xcode-GUI build step). Expect minor first-sync
  fixups (dependency versions, the invoke signature).

### Verified on emulator (same session)
- Android Studio first sync: **green** (no errors) — supabase-kt, Compose, Room all resolved.
- Drove the rest headless from CLI: installed `cmdline-tools`, pulled the
  `android-35;google_apis;arm64-v8a` system image, created AVD `seek_pixel`,
  fetched the Gradle wrapper jar, built the debug APK, booted the emulator,
  `adb install` + launched.
- **One compile fix:** `SeekApi.kt` was missing two imports —
  `io.github.jan.supabase.functions.functions` (the accessor extension) and
  `io.ktor.client.request.setBody`. Confirmed the real `Functions.invoke`
  builder-lambda signature via `javap` on the resolved jar; the call structure
  was already correct. `SessionRepository` and everything else compiled clean
  first pass.
- **Result: Seek runs on Android.** Home renders the daily-verse card in the
  serif font on the cream background, 3-tab nav working. Screenshot-verified.
- `gradle-wrapper.jar` committed so `./gradlew` works going forward.

### Current Status
- Phase 0 complete and **verified running on an API 35 emulator**.
- Next: Phase 1 — auth (Google/Apple/email + guest) and live Home data.
