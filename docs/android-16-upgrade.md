# Android 16 (API 36) upgrade — Play deadline 2026-08-31

Google Play notice (received 2026-07-21): from **Aug 31, 2026** all new apps and
app updates must target **API 36**. Seek Android was on `targetSdk = 35`.

**Consequence of missing it:** Seek is *not* delisted — an app at 35 still meets
the "remain available to new users" bar. But every AAB upload is rejected, so
the Play listing freezes at whatever is live until the bump lands.

An extension to **Nov 1, 2026** can be requested in Play Console later in the year.
Treat that as a safety net, not a plan.

---

## Changes applied

| File | Before | After |
|---|---|---|
| `app/build.gradle.kts` | `compileSdk = 35` | `compileSdk = 36` |
| `app/build.gradle.kts` | `targetSdk = 35` | `targetSdk = 36` |
| `gradle/libs.versions.toml` | `agp = "8.7.3"` | `agp = "8.13.2"` |
| `gradle/wrapper/gradle-wrapper.properties` | `gradle-8.11.1` | `gradle-8.13` |

**Why the toolchain moved too:** compiling against API 36 requires **AGP ≥ 8.9.0**.
8.7.3 cannot do it. AGP 8.13.2 is the current stable and requires Gradle ≥ 8.13,
hence the wrapper bump.

*Lower-churn alternative if 8.13.2 causes trouble:* **AGP 8.10** also supports API 36
and runs on the Gradle 8.11.1 you already had — revert the wrapper line and set
`agp = "8.10.x"`. Fewer moving parts, but leaves you further behind next year.

`versionCode` deliberately left at **6**. Per `docs/changelog.md`, v6 / 1.2.0 (the
widget release) was built but never uploaded to Play, so 6 is still unused. Bumping
would burn a number for nothing.

---

## Compatibility review — risk is LOW

I read the manifest, themes, MainActivity, and the widget/alarm code against the
Android 16 behavior changes that bite at `targetSdk = 36`.

### Already safe

- **Edge-to-edge.** Android 16 removes the `windowOptOutEdgeToEdgeEnforcement`
  escape hatch. Seek never used it — `MainActivity` already calls
  `enableEdgeToEdge()`, and you've been on `targetSdk = 35` (where enforcement
  started), so this is absorbed. No action.
- **Exact alarms.** `DailyVerseWidget.scheduleMidnightRefresh` uses
  `setAndAllowWhileIdle(AlarmManager.RTC, ...)` — inexact. It does **not** need
  `SCHEDULE_EXACT_ALARM` / `USE_EXACT_ALARM`, which is the permission that has
  been tightening release over release. Good call by whoever wrote it.
- **PendingIntent mutability.** Both `PendingIntent`s use `FLAG_IMMUTABLE`,
  required since API 31.
- **Implicit broadcasts.** `ACTION_DAILY_REFRESH` is sent to an explicit
  component (`Intent(context, DailyVerseWidget::class.java)`), so background
  implicit-broadcast restrictions don't apply.
- **Receiver export flags.** Both receivers declare `android:exported`, required
  since API 31/34.
- **Orientation / resizability.** Android 16 ignores orientation and resizability
  restrictions on large screens (≥600dp). No `screenOrientation` is set anywhere
  in the manifest, so nothing to unwind — but the app will now be resizable on
  tablets and foldables, which is a **layout** thing to eyeball, not a crash risk.

### Worth checking on device

1. **Predictive back.** At `targetSdk = 36` the predictive back gesture is on by
   default. Seek has no `BackHandler` and no `onBackPressed` override, so the
   risk is low, but walk the Compose Navigation stack (Home → Chat → Card
   Creator → Library, and the sign-in sheet) and confirm back gestures animate
   and land where they should.

2. **Dead theme attributes.** `res/values/themes.xml` still sets
   `android:statusBarColor` and `android:navigationBarColor`. Both were
   deprecated at API 35 and are already no-ops for you today — this is not a
   regression, but they're misleading. Bar coloring now comes from your Compose
   edge-to-edge setup. `android:windowBackground` still works and is what kills
   the launch flash, so keep that one.

3. **The widget, hardest.** It's the newest code and the most
   platform-sensitive:
   - Place the widget, then let the device sit past local midnight and confirm
     the verse rolls over without opening the app.
   - Note `RTC` (not `RTC_WAKEUP`) means the refresh fires when the device next
     wakes rather than waking it. That's correct for a widget nobody's looking
     at — just don't read a late rollover on a sleeping device as a bug.
   - Confirm the `seek://dailyverse` tap-through still opens the app on Home.
   - Resize the widget on a large screen, given the new resizability behavior.

4. **Dependency floors.** Compose BOM (`2024.12.01`) and `core-ktx` (`1.15.0`)
   are from the API-35 era. Nothing here *requires* bumping them for API 36, and
   I deliberately left them alone to keep this diff small before a deadline. If
   the build surfaces warnings about them, bump then — not now.

---

## Build + ship sequence

Everything below has to run on the Mac — this sandbox has no Android SDK, so
none of it has been compiled yet. **The edits above are unverified by a build.**

```bash
cd android
./gradlew --stop                 # drop daemons on the old Gradle
./gradlew clean assembleDebug    # first run downloads Gradle 8.13 + build-tools 36
```

1. `assembleDebug` — expect AGP 8.7 → 8.13 deprecation warnings; read them, they
   often flag removals landing in AGP 9.
2. Install on an emulator/device running **Android 16** and work the checklist above.
3. `./gradlew bundleRelease` and confirm the AAB signs with `keystore.properties`.
4. Upload to Play as **v6 / 1.2.0** (widget + API 36 together).

---

## Blocker found while doing this

**Session 25's work is uncommitted.** On `main` right now:

```
?? SeekWidget/
?? Shared/
?? android/app/src/main/java/com/loucesario/seek/widget/
?? android/app/src/main/assets/daily_verses.json
?? android/app/src/main/res/layout/
?? android/app/src/main/res/xml/daily_verse_widget_info.xml
 M android/app/src/main/AndroidManifest.xml
 M android/app/src/main/java/com/loucesario/seek/ui/home/HomeViewModel.kt
 M Seek/ContentView.swift, Seek/Views/Home/HomeView.swift, project.yml, ...
```

The entire Verse of the Day feature — both platforms — exists only as untracked
files in the working tree. Last commit is `1b8501a marketing(ig): ...`. That
explains why v6 was never uploaded and why iOS build 12 never archived: the work
was finished but never landed.

This is the real risk to the Aug 31 date. An uncommitted month-old working tree
is one `git clean` from gone. Commit it before touching anything else.
