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

## Phase 1 — Auth + Home  (core verified on emulator)
- [x] Onboarding flow (Welcome → Sign In) — gold-halo welcome + Begin
- [x] Email/password sign-in + sign-up + password reset (verified UI; full signup depends on Supabase email-confirm setting)
- [x] Guest mode ("Continue without an account") + gating — **verified: guest → Home → live verse**
- [x] Auth gate routing in SeekApp (onboarding vs shell vs guest)
- [x] Home: live daily verse (`SeekApi.dailyVerse()`), streak capsule (auth-only), quick prompts
- [x] Profile (guest sign-in CTA / authed sign-out); Chat + Library guest gates
- [~] Google Sign-In via browser OAuth — **wired in code; needs Google client ID configured in Supabase to function**
- [~] Sign in with Apple via browser OAuth — **wired; needs Apple OAuth Services ID + key in Supabase (iOS uses native flow, N/A here)**
- [ ] Personalization + notifications onboarding steps (deferred)
- [ ] Translation picker (currently static NLT), delete account

## Phase 2 — Chat  (verified on emulator)
- [x] Chat UI (message bubbles, verse/prayer/song/follow-up cards, input bar)
- [x] Wire `SeekApi.sendChat` with conversation history + translation
- [x] Parse response → verse cards (serif), gold prayer card, worship song, follow-up
- [x] Rate-limit + error handling (basic classification)
- [x] Persist conversations + messages to Room
- [x] **Verified: signed-in test user → "I feel anxious about the future" → full
      verse + prayer + worship + follow-up response rendered**
- [ ] Worship song deep links (Apple Music / Spotify) — deferred
- [ ] Staggered card reveal animation — deferred
- [ ] Regenerate scripture — deferred
- [ ] Persist chat state across tab switches (currently resets if nav popped) — polish

## Phase 3 — Card Creator + Library  (verified on emulator)
- [x] Card templates — 6 across categories (Sage/Cream/Gold/Night/Blush/Sky)
- [x] **Canvas renderer → exact 1080×1920 Bitmap** (single source for preview +
      export; avoids the iOS preview/export divergence). Auto-fit serif verse,
      reference, "Seek" watermark.
- [x] Card creator: live preview, horizontal template picker, save-to-gallery
      (MediaStore), share (FileProvider), persist SavedCard to Room
- [x] Entry points: tap Home daily verse / chat verse card → creator
- [x] Library: Cards grid (re-rendered thumbnails), Favorites (verses+prayers),
      History (conversations), empty states; guest gate retained
- [x] **Verified: Home verse → creator → switch to Gold template (live) → Save
      ("Saved to your gallery") → card appears in Library Cards grid**
- [ ] Port remaining iOS templates (18 total) — deferred
- [ ] Favoriting verses/prayers to populate Favorites tab — deferred
- [ ] Card delete / long-press edit mode — deferred

## Phase 4 — Notifications + Polish  (verified on emulator)
- [x] Local notifications — channel, daily-verse + streak-nudge builders,
      AlarmManager `setInexactRepeating` scheduler (no exact-alarm permission),
      BroadcastReceiver, tap→open app
- [x] POST_NOTIFICATIONS runtime request (Android 13+)
- [x] Notification settings in Profile — toggles (7am verse / 7pm streak),
      persisted to DataStore, schedule/cancel on change, "Send a test reminder"
- [x] Offline handling — `ConnectivityObserver` (validated-internet),
      Home offline pill + verse fallback badge, Chat offline banner + disabled send
- [x] **Verified: permission dialog → test notification fired in shade
      ("Your Daily Verse"); airplane mode → Home "Offline" pill + "Psalm 46:1 ·
      offline" fallback**
- [ ] Persist notification prefs to Supabase `notification_settings` (shared) — deferred
- [ ] Notification deep links to specific screens — deferred
- [ ] Skeleton loaders — deferred (spinners in place)

## Phase 5 — Play Store (code prep DONE; blocked on Play org account)
- [x] Real adaptive launcher icon (PNG mipmaps + adaptive XML + monochrome silhouette) from iOS 1024 asset
- [x] Lora font swap — GoogleFont downloadable on Compose side, bundled TTF on CardRenderer side
- [x] Release signing keystore + signingConfigs in app/build.gradle.kts (creds in `~/.seek/`)
- [x] Signed release AAB (`app/build/outputs/bundle/release/app-release.aab`)
- [x] Store listing draft — `docs/play-store-submission.md`
- [x] Data safety form draft (in `play-store-submission.md`)
- [x] IARC content rating draft (in `play-store-submission.md`)
- [x] Phone screenshots (5) — `store/screenshots/`
- [ ] **Google Play Developer Org account** — D-U-N-S in hand; sign up at play.google.com/console/signup, $25, identity verification
- [ ] Designed 1024×500 feature graphic (optional polish)
- [ ] 7" / 10" tablet screenshots (optional polish)
- [ ] Upload AAB to internal testing track
- [ ] Paste listing, complete Data Safety + IARC, paste test account
- [ ] Closed testing → production submit

## Decisions log
- Native Kotlin/Compose (not cross-platform/PWA) — match iOS polish.
- `android/` folder in the iOS monorepo; `docs/schemas.md` + `docs/api-routes.md` shared.
- Package `com.loucesario.seek` (= iOS bundle ID; reuses Supabase + Apple provider).
- Scripture font: Lora (Georgia can't be bundled); Noto Serif stand-in until added.
- Card rendering: Compose → Bitmap via GraphicsLayer at fixed 1080×1920.
