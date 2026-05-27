# Seek for Android

Native Kotlin + Jetpack Compose port of the live iOS app, against the **same
Supabase backend** (project ref `hxfiaowayrhuhzhhbaix`). See
[`../docs/android-plan.md`](../docs/android-plan.md) for the full plan and
[`docs/build-plan.md`](docs/build-plan.md) for the task checklist.

## First-time setup

This machine has no Android toolchain — like iOS (Xcode), the build/run happens
in **Android Studio**, which bundles the JDK, Android SDK, and Gradle.

1. Install **Android Studio** (latest stable, Ladybug or newer).
2. `File → Open` → select this `android/` folder (not the repo root).
3. Android Studio will:
   - prompt to generate the Gradle **wrapper jar** (accept) — only the
     `gradle-wrapper.properties` is committed, not the binary jar;
   - download the SDK platform (API 35) + build tools if missing;
   - run the first Gradle sync (pulls supabase-kt, Compose, Room, etc.).
4. Pick a device/emulator (API 26+) and **Run**.

## State of the scaffold (Phase 0)

Builds to a 3-tab shell (Home / Chat / Library) on the Seek theme. Wired:
- Compose theme + color tokens (mirrors `../docs/design-system.md`), locked light.
- Room DB with all 6 entities (mirrors `../docs/schemas.md`).
- supabase-kt client (Auth + Postgrest + Functions) on the shared project.
- `SeekApi` wrappers for the `chat` and `daily-verse` Edge Functions.
- `SessionRepository` with the correct auth-state pattern (see below).

Home shows a static daily verse; Chat/Library are placeholders. Live data,
auth, card creator, etc. come in Phases 1–4.

## Two things to finish before they look final

- **Scripture font → Lora.** Ships with `FontFamily.Serif` (Noto Serif) as a
  zero-config stand-in. To switch to the design-target Lora: `res → New → Font →
  Get more fonts → Lora` (the wizard generates the downloadable-font cert
  resource correctly), then point `ScriptureFontFamily` in
  `ui/theme/Type.kt` at it. Single-line change.
- **Launcher icon.** Ships a placeholder adaptive icon. Regenerate the real one
  via `res → New → Image Asset` using the existing 1024px Seek icon
  (cream squircle, serif S, gold dot).

## Architecture notes that matter

- **Auth state (learned the hard way on iOS — cost App Review Builds 8 & 9):**
  trust the persisted Supabase session, not session-status events. All derived
  flags (`hasOptedForGuest`, `hasCompletedOnboarding`) are set atomically in
  each auth-success path inside `SessionRepository`, never cleared by a
  listener side-effect. Preserve this when building Phase 1 auth.
- **Never call Claude directly** — always through the `chat` Edge Function
  (same rule as iOS). `SeekApi.sendChat` does this.
- The Edge Functions are deployed `--no-verify-jwt` and validate in-function,
  so the anon-key client works for guests; the session token is attached
  automatically when present.
