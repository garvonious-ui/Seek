# Seek — Play Store upload kit (everything's ready)

Org account approved. All assets below are final. Full listing copy + Data Safety + Content Rating answers live in [`../docs/play-store-submission.md`](../docs/play-store-submission.md). This file is the click-order checklist.

## Assets on disk
| Asset | File | Spec | ✓ |
| --- | --- | --- | --- |
| **Signed AAB** | `android/app/build/outputs/bundle/release/app-release.aab` | 6.3 MB, v1.0.0 (code 1) | ✅ |
| **App icon** | `android/store/icon_512.png` | 512×512 | ✅ |
| **Feature graphic** | `android/store/feature_graphic.png` | 1024×500 | ✅ |
| **Phone screenshots** | `android/store/screenshots/01–05_*.png` | 5 × 1080×2400 | ✅ |

Screenshots: 01 Home · 02 Chat (verse cards) · 03 Card creator (interpretation on) · 04 Library · 05 Profile.

## Click order in Play Console (play.google.com/console)

1. **Create app** — name `Seek - Scripture Companion`, English (US), App, Free, accept declarations.
   - ⚠️ package `com.loucesario.seek` locks on first upload — it's correct, don't mistype.
2. **Testing → Internal testing → Create release** — upload `app-release.aab`.
   - Accept **Play App Signing** (Google holds the real key; your keystore is the upload key).
   - Add your own email as a tester → install from the opt-in link → confirm it runs.
3. **App content** (left nav — every item must go green before production):
   - Privacy policy → `https://askseekpray.app/privacy`
   - Ads → **No**
   - Data safety → fill per the matrix in `play-store-submission.md`
   - Content rating → IARC questionnaire per the doc → **Everyone**
   - Target audience → **18+**, not appealing to children
   - News app / Government / Financial features → **No**
4. **Store listing** (Grow → Store presence → Main store listing):
   - App name, short description (80), full description — paste from the doc.
   - Upload `icon_512.png`, `feature_graphic.png`, and the 5 screenshots.
5. **Countries/regions** → All (or your pick) · **App access** → paste the test-account block from the doc (chat/library are behind sign-in).
6. **Promote to Production** — org accounts skip the 12-tester/14-day gate. First-app review for a new dev can take a few days.

## Notes
- Build is `versionName 1.0.0`, `versionCode 1` — first Play release, independent of the iOS version (which is on 1.1.0/11).
- If you'd rather I rebuild the AAB or re-shoot any screenshot, just say so.
