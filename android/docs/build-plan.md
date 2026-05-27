# Seek for Android — Build Plan

Full strategy + stack mapping: [`../../docs/android-plan.md`](../../docs/android-plan.md).

## Phase 0 — Scaffold ✅
- [x] Gradle project, version catalog, app module, manifest, resources
- [x] Compose theme: color tokens (light-locked), typography, scripture serif
- [x] Launcher icon (placeholder adaptive — regenerate from 1024px asset)
- [x] Room DB: 6 entities + DAOs + converters (mirrors `schemas.md`)
- [x] supabase-kt client (Auth + Postgrest + Functions) on shared project
- [x] `SeekApi` wrappers for `chat` + `daily-verse`
- [x] `SessionRepository` with correct auth-state pattern
- [x] App shell: MainActivity + 3-tab nav + placeholder screens
- [x] Project docs (CLAUDE.md, build-plan, changelog, README)

## Phase 1 — Auth + Home
- [ ] Onboarding flow (Welcome → Personalization → Notifications → Sign In)
- [ ] Google Sign-In via Credential Manager (primary on Android)
- [ ] Sign in with Apple via Supabase OAuth web flow (Custom Tabs)
- [ ] Email/password sign-in + sign-up + password reset
- [ ] Guest mode ("Continue without an account") + gating
- [ ] Auth gate routing in SeekRoot (onboarding vs shell vs guest)
- [ ] Home: live daily verse (`SeekApi.dailyVerse()`), streak capsule, quick prompts
- [ ] Profile/settings (translation picker, sign out, delete account)

## Phase 2 — Chat
- [ ] Chat UI (message bubbles, input bar, keyboard handling)
- [ ] Wire `SeekApi.sendChat` with conversation history + translation
- [ ] Parse response → verse cards, prayer card, worship song (deep links)
- [ ] Rate-limit UI; error classification (transient vs real, offline)
- [ ] Persist conversations to Room; staggered card reveal animation
- [ ] Regenerate scripture

## Phase 3 — Card Creator + Library
- [ ] Card templates (port the 18 iOS templates / 4 categories)
- [ ] Render Composable → 1080×1920 Bitmap (GraphicsLayer), save to gallery + share
- [ ] App watermark
- [ ] Library: Cards grid / Favorites / History tabs; re-edit, delete, copy

## Phase 4 — Notifications + Polish
- [ ] Scheduled local notifications (WorkManager) — daily verse + streak nudge
- [ ] Notification settings UI; persist to `notification_settings` (shared table)
- [ ] Deep links from notification taps
- [ ] Offline handling, loading/skeleton, error states

## Phase 5 — Play Store
- [ ] Google Play Developer account ($25 one-time)
- [ ] Store listing, screenshots, feature graphic
- [ ] Data safety form (mirror iOS privacy nutrition labels)
- [ ] Real launcher icon + Lora font swapped in
- [ ] Internal testing track → production submit

## Decisions log
- Native Kotlin/Compose (not cross-platform/PWA) — match iOS polish.
- `android/` folder in the iOS monorepo; `docs/schemas.md` + `docs/api-routes.md` shared.
- Package `com.loucesario.seek` (= iOS bundle ID; reuses Supabase + Apple provider).
- Scripture font: Lora (Georgia can't be bundled); Noto Serif stand-in until added.
- Card rendering: Compose → Bitmap via GraphicsLayer at fixed 1080×1920.
