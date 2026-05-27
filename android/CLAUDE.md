# Seek for Android — Kotlin/Compose port

## What This Is
Native Android port of Seek (live on iOS App Store). Same concept: share what's
on your heart → AI surfaces 3-5 Bible verses + prayer + worship song → create
shareable verse cards; daily verse + streaks. Built against the **same Supabase
backend** as iOS (no backend changes needed).

## Tech Stack
- Kotlin 2.0, Jetpack Compose (Material 3), minSdk 26 / target 35
- MVVM: ViewModel + StateFlow + Repository
- Room (local persistence) — mirrors iOS SwiftData models
- supabase-kt (Auth, Postgrest, Functions) — project ref `hxfiaowayrhuhzhhbaix`
- Claude via the shared `chat` Edge Function proxy (never direct)
- DataStore for auth-state flags

## Critical Rules
- NEVER call Claude API directly — always through the `chat` Edge Function.
- Scripture text renders in a serif (`ScriptureFontFamily`, target Lora), always
  distinct from UI sans.
- App is ALWAYS light mode — `SeekTheme` is a fixed `lightColorScheme`; never
  read `isSystemInDarkTheme()`. Use `SeekColors` tokens, never adaptive colors.
- Default translation NLT, switchable to KJV; stored in profile +
  `profiles.preferred_translation` (shared schema).
- Denominationally neutral tone; crisis language surfaces scripture AND
  professional-help encouragement (handled server-side in the shared prompt).
- All schemas/IDs live in `../docs/schemas.md` and `../docs/api-routes.md` —
  these are SHARED with iOS. Reference before any data work.

## Auth-state rule (do not relearn iOS's pain)
supabase-kt session-status events are not authoritative (same class of bug that
cost iOS App Review Builds 8 & 9). In `SessionRepository`:
- Cross-check `auth.currentSessionOrNull()` before honoring a "not authenticated"
  event.
- Set ALL derived flags (`hasOptedForGuest`, `hasCompletedOnboarding`) directly
  and atomically in each auth-success path. Never let a listener clear them.
- Explicit `signOut()` owns its own reset.

## Reference Docs (shared with iOS unless noted)
- Android plan: `../docs/android-plan.md`
- Schemas + IDs: `../docs/schemas.md`
- API routes: `../docs/api-routes.md`
- Design system: `../docs/design-system.md`
- Android build plan: `docs/build-plan.md`
- Android changelog: `docs/changelog.md`

## Build / Run
Open the `android/` folder in Android Studio (not the repo root). First sync
downloads deps + SDK. Run on an API 26+ device/emulator. See `README.md`.

## Gotchas
- Georgia (iOS scripture font) is proprietary — cannot bundle on Android. Lora
  is the substitute; ships as `FontFamily.Serif` (Noto Serif) until the Lora
  downloadable-font resource is added via Android Studio's Google Fonts wizard.
- Only `gradle-wrapper.properties` is committed; Android Studio generates the
  wrapper jar on first open.
- supabase-kt `functions.invoke` builder signature should be confirmed on first
  sync (see comment in `SeekApi.kt`) — request is encoded to a JSON string and
  decoded manually to avoid reified-type content-negotiation issues.
- **The `chat` Edge Function needs BOTH timeouts raised.** Claude generating
  3-5 verses + prayer + song routinely exceeds 10s. There are two independent
  10s ceilings: ktor's `requestTimeout` (set on the SupabaseClient builder) AND
  OkHttp's socket/call timeout (set via `httpEngine = OkHttp.create { config {
  callTimeout/readTimeout } }`). Raising only one still times out at the other.
  Both are set to 60s in `SupabaseModule`.

## Current Phase
Phase 0 (scaffold) — DONE. Builds to a 3-tab shell on the Seek theme with Room +
Supabase wired. Next: Phase 1 (auth + Home live data). See `docs/build-plan.md`.
