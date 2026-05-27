# Seek for Android — Changelog

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

### Current Status
- Phase 0 complete (pending first-sync verification in Android Studio).
- Next: Phase 1 — auth (Google/Apple/email + guest) and live Home data.
