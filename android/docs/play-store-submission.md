# Google Play Store Submission — Paste-Ready

Drafted 2026-06-10 for the Android port of Seek (live on iOS App Store as 1.0.1 / Build 10).

Mirrors `../../docs/app-store-submission.md` (the iOS source-of-truth) and adapts every field to Google Play's structure + character limits. Where Play requires something Apple doesn't (Short Description, Data Safety form, Content Rating questionnaire) this doc has the answer ready.

---

## Identity

| Field | Value | Limit |
| --- | --- | --- |
| **App name** | `Seek - Scripture Companion` | 30 chars / using 27 |
| **Package name** | `com.loucesario.seek` | — |
| **Default language** | English (United States) | — |

App name matches iOS for consistency. Bare "Seek" is taken on iOS; we use the suffixed form there. Play *might* allow bare "Seek" but using the same name everywhere is the right call for brand consistency.

---

## Short Description (80 chars max — currently 78)

**Required by Play.** Shown above the full description in the Play Store listing, on cards in search results, and in some surfaces where the long description is hidden.

```
Scripture, prayer, and worship for what's on your heart. Free, no ads.
```

---

## Full Description (4000 chars max — currently ~2,650)

The iOS App Store description, lightly adapted (no Apple-specific terms like "Apple Sign In," "Apple Music"). All the substance is the same — Play and Apple users are getting the same Seek.

```
When you are anxious, tired, grateful, hurting, or hopeful — the right scripture meets the moment. Seek finds it for you.

Tell Seek what is on your heart in a few words or a few paragraphs. Within seconds, you receive 3–5 verses chosen for what you actually shared, a short prayer, an action step, and a worship song that fits the mood. Tap any verse to turn it into a beautiful shareable card.

WHAT SEEK DOES

Scripture chat — Type freely or pick a quick prompt like "Joy," "Anxious," or "Lonely." Receive verses with brief context, a prayer, an action step, and a worship song.

Verse card creator — Pre-designed templates across nature, minimal, watercolor, and bold styles. Renders at story size for sharing or saving to your gallery.

Daily verse — A new verse every morning, themed. Shows the most recent saved verse if you are offline.

Streak tracker — A simple counter that rewards showing up. Milestones at 7, 30, 90, and 365 days.

Two translations — NLT for clarity, KJV for tradition. Switch any time in Settings.

Library — Hearted verses, saved cards, saved prayers, past conversations. Re-share, edit, copy, or delete from any of them.

Daily reminders — Optional morning verse and evening streak nudge. Time pickers in Settings.

WHY IT IS FREE

Seek is free for everyone. There is no subscription, no in-app purchase, no ads, no upsell, no premium tier. Built for the people of God, not for profit.

A NOTE ON AI

Seek uses Claude (Anthropic) to match scripture to your situation. Verses are real KJV or NLT scripture, not AI-generated. The empathetic intro, prayer, and worship recommendation are written for you fresh each time. Seek's servers do not persist the contents of your chat messages.

A NOTE ON CRISIS

If you are in crisis or thinking of harming yourself, Seek will share grounding scripture and encourage you to reach out for human help. Please contact 988 (US Suicide and Crisis Lifeline), 116 123 (Samaritans, UK), or findahelpline.com to reach a trained human.

PRIVACY

We collect your account info (Google Sign In or email), your preferences (translation, notification times), basic usage stats (chats per day for rate limits), and your notification token if you enable reminders. We do not use third-party analytics SDKs, advertising IDs, or precise location.

DENOMINATIONALLY NEUTRAL

Seek does not promote any particular church, doctrine, or interpretation. The verses come from the Bible. The prayers are short and broad. The worship songs span tradition and contemporary.

Built with love for the people of God.
```

---

## Category

| Field | Value |
| --- | --- |
| **Application or game** | Application |
| **App category** | Lifestyle |
| **Tags** | Bible, Prayer, Devotional, Christian (Play tag picker — pick from preset list, max 5) |

*Play does not have an "iOS-style Secondary Category." Tags replace Apple's secondary category role.*

---

## Store Listing Assets

Required dimensions for the Play Console upload:

| Asset | Spec | Status |
| --- | --- | --- |
| **App icon** | 512 × 512 PNG, max 1024 KB | `android/store/icon_512.png` — generated 2026-06-10 |
| **Feature graphic** | 1024 × 500 PNG/JPG, no transparency, max 1 MB | TODO (designed asset) |
| **Phone screenshots** | 2–8 images, 16:9 or 9:16, min 320 px, max 3840 px | TODO (see `screenshots/` once captured) |
| **7-inch tablet screenshots** | 2–8 images, optional but ships better | TODO |
| **10-inch tablet screenshots** | optional | TODO |

---

## Data Safety Form (Play's privacy disclosure)

Play asks more granular questions than Apple's nutrition labels. Walks you through every data type with three sub-questions: collected? shared? required-or-optional? Below mirrors `app-store-submission.md` Data Linked / Data Used to Track sections, plus Play's extra fields.

### Data collection and security

| Field | Answer |
| --- | --- |
| Does your app collect or share any of the required user data types? | **Yes** |
| Is all of the user data collected by your app encrypted in transit? | **Yes** (HTTPS to Supabase + Anthropic) |
| Do you provide a way for users to request that their data is deleted? | **Yes** (delete-account in Profile + email to hello@askseekpray.app) |

### Data types collected — answers per category

For each row: **Collected = Yes**, **Shared with third parties = No** (Anthropic processes prompts in-transit but doesn't persist; that's transit, not sharing), **Optional or required = Required** (account is required for chat/library; daily verse works for guests but only authenticated users provide this data).

| Category | Type | Purpose |
| --- | --- | --- |
| **Personal info** | Name | Account management |
| **Personal info** | Email address | Account management |
| **Personal info** | User IDs (Supabase UID) | Account management |
| **Messages** | Other in-app messages | App functionality (chat content sent to Anthropic for verse matching; not persisted on Seek's servers) |
| **App activity** | App interactions | App functionality (chat counts for rate limit, streak counts, totals) |

### Data types **not** collected (call these out explicitly — Play asks)

- **Approximate location** — No
- **Precise location** — No
- **Photos and videos** — No (cards saved to user's own gallery only; we never read photos)
- **Files and docs** — No
- **Calendar** — No
- **Contacts** — No
- **Audio files** — No
- **Device or other IDs** — No (no advertising ID, no IMEI, etc.)
- **Web browsing history** — No
- **Health and fitness** — No
- **Financial info** — No
- **Diagnostic info** — No (no crash analytics, no perf monitoring)

### Sharing

| Question | Answer |
| --- | --- |
| Is user data shared with third parties? | **No** *(Anthropic processes chat prompts in-transit per their API terms; this is transit, not sharing for Play's purposes.)* |

---

## Content Rating Questionnaire (IARC)

Play uses the IARC questionnaire which feeds ESRB, PEGI, USK, ACB, etc. Below is the answer set that yields **Everyone (3+/4+/E/USK 0/ACB G)** in every territory.

| Question | Answer |
| --- | --- |
| Violence | None |
| Sexuality | None |
| Language | None |
| Controlled substances | None |
| Crude humor | None |
| Gambling | None |
| User-generated content shared between users | **No** *(Seek has zero social/chat-between-users)* |
| Personal information shared with other users | **No** |
| Users can communicate with each other | **No** |
| Location sharing | **No** |
| Digital purchases | **No** *(no IAP, no donations)* |

**On crisis content:** if asked, Seek may surface mental-health hotline information (988, 116 123, findahelpline.com) in response to crisis-language input. This is text-based safety information, not "self-harm content" in IARC's sense. Don't flag.

---

## Target Audience and Content

| Field | Answer |
| --- | --- |
| Target age groups | **18 and over** *(faith app for adults — keep age targeting clean to avoid Designed-for-Families program rules which restrict Anthropic API integrations)* |
| Does the app appeal to children? | **No** |
| Stores experience for kids? | **No** |

---

## Ads

| Question | Answer |
| --- | --- |
| Does your app contain ads? | **No** |

---

## App Access (test account for review)

Required because chat and library are behind auth. Same account as iOS App Review or a separate Android-only one — your call.

```
Email: appreview@askseekpray.app  (or androidtest@askseekpray.app — the
       account we provisioned during dev verification)
Password: (paste the secure password directly into Play Console — do not
          commit to the repo)

Instructions for the reviewer:
1. Tap "Sign in with email" on the welcome screen, enter the credentials.
2. The user lands on Home with a daily verse and a "What's on your heart?"
   prompt. Tap any of the six quick-prompt chips to send a real scripture
   chat — within ~5 seconds you'll see 3-5 verses, a prayer, an action step,
   and a worship song suggestion.
3. Tap any verse to enter the Card Creator. Pick a template. Tap Save to
   add the rendered 1080x1920 card to the gallery, or Share to bring up the
   system share sheet.
4. The Library tab shows saved cards (re-rendered thumbnails), favorited
   verses, and chat history.
5. The "Continue without an account" button on the welcome screen verifies
   guest access — guests can read the daily verse on Home but Chat and
   Library show a sign-in CTA (account-based features).
```

---

## URLs

All four resolve at `askseekpray.app` (live on Vercel, custom domain attached Session 13).

| Field | URL |
| --- | --- |
| App support email | `hello@askseekpray.app` |
| Website | `https://askseekpray.app` |
| Privacy policy | `https://askseekpray.app/privacy` |

*Play does not require a separate Terms URL in the listing, but link to `/terms` from the privacy page (already done in the Vercel site).*

---

## Crisis Help Resources (paste-ready for Play's safety-feature questionnaire if asked)

```
988 — US Suicide and Crisis Lifeline
116 123 — Samaritans (UK)
findahelpline.com — international directory
```

---

## What's New / Release Notes (500 chars max)

For first release:

```
Welcome to Seek for Android. Tell us what is on your heart and receive scripture, prayer, and worship for the moment. Free, no ads, no subscription. Built for the people of God.
```

---

## Pricing & Distribution

| Field | Value |
| --- | --- |
| **App pricing** | Free |
| **In-app products** | None |
| **Countries / regions** | All available *(or restrict per your call; default is all)* |
| **Devices** | Phones + 7" and 10" tablets *(no Wear OS, no Android TV, no Auto)* |
| **Contains ads** | No |

---

## Pre-submission Checklist

### Code-side (DONE 2026-06-10 unless noted)
- [x] Real adaptive launcher icon generated from iOS 1024 asset
- [x] Lora scripture font wired (Compose downloadable + bundled TTF for card render)
- [x] Release signing keystore generated, gitignored, backed up to `~/.seek/`
- [x] Signed AAB built (`app/build/outputs/bundle/release/app-release.aab`)
- [ ] Phone screenshots captured from emulator
- [ ] (Optional) 7" tablet screenshots
- [ ] (Optional) Designed 1024×500 feature graphic

### Play-side (BLOCKED on Google Play org account approval)
- [ ] Google Play Developer account ($25 one-time) — paid + verified
- [ ] D-U-N-S number plugged into org verification
- [ ] App created in Play Console (package name `com.loucesario.seek`)
- [ ] Internal testing track: upload first AAB
- [ ] Store listing: paste fields above
- [ ] Data safety form: complete per matrix above
- [ ] Content rating: complete IARC questionnaire
- [ ] App access: paste test account credentials
- [ ] Closed testing → production submit

---

*Last updated: 2026-06-10. Edit freely as fields evolve.*
