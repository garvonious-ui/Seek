# Seek for Android — Planning Doc

**Status:** Exploration → committed direction. No Android code exists yet.
**Decided:** 2026-05-25, driven by repeated user demand for an Android version.

## Direction (decided)
- **Native Kotlin + Jetpack Compose.** Match the polish of the live iOS app — the calm, reverent UI is Seek's differentiator, so cross-platform/PWA compromises were rejected.
- **Full feature parity** with the live iOS app (1.0.1 / Build 10): chat, card creator, library, streaks, daily verse, notifications, auth.
- **Built solo + Claude**, same workflow that shipped iOS (Claude writes Kotlin/Gradle; user builds & runs in Android Studio, same split as the Xcode GUI archive step).

## Core insight: the backend ports for free
Seek splits into a reusable backend and an Apple-only frontend.

**Reused unchanged (the hard, production-hardened half):**
- Supabase — Auth, Postgres, RLS, all tables (`profiles`, `notification_settings`, `daily_verses`, `usage_logs`, `waitlist`, `donations`)
- `chat` Edge Function (Claude proxy, system prompt, rate limits, retry-with-backoff, `debug_logs` sink)
- `daily-verse` Edge Function (auth-optional, NLT default for guests)
- 365-verse seed (KJV + NLT), Bible data
- Stripe/donations infra (dormant), waitlist
- Shared truth docs: `docs/schemas.md`, `docs/api-routes.md`, `docs/architecture.md`

**Rebuilt (≈100% of the client):** see stack mapping below.

## Stack mapping (iOS → Android)
| iOS (current) | Android equivalent | Notes |
|---|---|---|
| SwiftUI | Jetpack Compose | Closest 1:1 — declarative, similar model |
| `@Observable` / state | ViewModel + StateFlow (MVVM) | Standard Compose architecture |
| NavigationStack | Navigation-Compose | |
| SwiftData (6 `@Model`s) | Room (SQLite) | UserProfile, SavedCard, ChatConversation, ChatMessage, FavoriteVerse, SavedPrayer |
| supabase-swift | supabase-kt | Official Kotlin SDK — Auth, Postgrest, Functions |
| Sign in with Apple | Supabase OAuth web flow (Custom Tabs) | Works, clunkier on Android |
| *(add)* Google Sign-In | Credential Manager | Net-new; Android users expect it |
| email/password | supabase-kt Auth | Identical behavior |
| guest mode (`hasOptedForGuest`) | same flag in ViewModel | Port the auth-state logic carefully (see iOS gotchas) |
| ImageRenderer 1080×1920 PNG | Compose → Bitmap (Canvas / GraphicsLayer) | Card creator — trickiest port |
| Local notifications (UNCalendar) | WorkManager + NotificationManager | Scheduled daily verse / streak nudge |
| Deep link from notification | Intent + Navigation | `.openDailyVerse` / `.openHome` equivalents |
| AdMob (unwired) | Google Mobile Ads SDK | First-class on Android |
| StoreKit 2 (dormant) | Play Billing | Only if donations return |
| Georgia serif | **serif substitute** (Lora / PT Serif / Noto Serif) | Georgia is proprietary — cannot bundle. Design call. |
| Forced light mode | Compose theme locked to light | |
| Color hex tokens | carry over directly | sage #5B7B5E, gold #CDA349, bg #FAFAF6, etc. |

## Decisions unique to Android (settle early)
1. **Scripture font.** Georgia is Microsoft-proprietary and cannot be bundled on Android. Scripture text and card templates depend on it. Pick a free serif (Lora / PT Serif / Noto Serif) — this subtly changes the app's feel, so it's a real design decision. The wordmark is a PNG, so it's safe.
2. **Card rendering parity.** Pixel-faithful cards across a different font + render engine is the biggest fidelity risk. Plan for iteration. Validate with short (Psalm 23:1) and long (Romans 8:28-39) passages per the iOS card-template rules.
3. **Auth emphasis flips.** Google Sign-In is primary on Android, Apple secondary (reverse of iOS). Email/password unchanged.
4. **Repo structure.** Sibling repo `Seek-Android` (or `android/` folder) with its own CLAUDE.md / build-plan.md / changelog.md mirroring the iOS discipline. `docs/schemas.md` + `docs/api-routes.md` remain shared truth.
5. **minSdk / targetSdk.** Recommend minSdk 26 (Android 8) for modern Compose without legacy workarounds; target latest stable.

## Carry-over gotchas from iOS (apply to Android port)
- **Auth-state flags must be set atomically at each sign-in success path**, not via the auth listener. The supabase-swift `.signedOut` event being non-authoritative cost iOS Builds 8 & 9. supabase-kt's `SessionStatus` flow likely has the same race — trust the persisted session, set `hasOptedForGuest`/onboarding flags directly in each success path. (See iOS AuthManager Session 17 fix + CLAUDE.md.)
- **Chat must tolerate transient Anthropic 5xx.** Already handled server-side by `callClaudeWithRetry` in the `chat` function — Android client inherits this for free, but client-side error UX should still distinguish transient vs real failures (mirror iOS `classifyChatError`).
- **Edge Functions are deployed `--no-verify-jwt` and validate in-function** — any client (including the Kotlin anon-key caller) works. daily-verse already serves guest callers.

## Parity roadmap (phased)
- **Phase 0 — Scaffold:** Android Studio project, Gradle/Compose, supabase-kt wired, light-mode theme + color tokens + serif font, Room entities + DAOs.
- **Phase 1 — Auth + Home:** Google + Apple + email sign-in, guest mode, daily verse card, streak counter.
- **Phase 2 — Chat:** core loop against existing `chat` function — verse/prayer/worship-song cards, conversation history, rate-limit UI.
- **Phase 3 — Card creator + Library:** templates, Canvas render to PNG, save to gallery + share sheet, Cards/Favorites/History tabs.
- **Phase 4 — Notifications + polish:** scheduled local notifications, offline handling, loading/error states.
- **Phase 5 — Play Store:** $25 one-time Google Play Developer account, listing, screenshots, data-safety form, submit.

## Platform notes
- **Google Play account:** $25 one-time (vs Apple $99/yr).
- **Play review:** generally faster and less adversarial than App Review.
- **Donations on Android:** Google's payment rules differ from Apple's — re-enabling donations may be easier here. Worth checking if/when monetization returns.
- **Push (later):** Android server push is FCM, not APNs. Local notifications (Phase 4) cover the launch need, same as iOS Phase A.

## Effort estimate
Multi-session effort comparable to the iOS build, but front-loaded with backend reuse and free of the App Review rejection cycle iOS endured. Card creator and auth-state correctness are the two areas to budget extra time for.
