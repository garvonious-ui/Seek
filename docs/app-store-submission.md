# App Store Submission — Paste-Ready

Drafted Session 13 (2026-05-01). Updated Session 16 (2026-05-07) to remove donation language after App Review rejected Build 7 on Guideline 3.1.1. Every field below is sized to its App Store Connect character limit; copy block-by-block into ASC.

---

## App Information

**App Name** (already registered)
```
Seek - Scripture Companion
```
*Note: bare "Seek" was taken on the App Store in Session 2b; we're listed under "Seek - Scripture Companion." App icon + launch wordmark just say "Seek."*

**Subtitle** (30 chars max — currently 26)
```
Scripture for every moment
```
*Mirrors the launch screen tagline. Calm, no superlatives, no AI buzzword.*

**Primary Category:** Lifestyle
**Secondary Category:** Reference

**Age Rating:** 4+ *(see questionnaire answers below)*

**Bundle ID:** `com.loucesario.seek`

---

## URLs

All three resolve once `askseekpray.app` DNS is attached in Vercel. The HTML pages are already deployed on Vercel; only the custom domain attachment is pending.

| Field | URL |
| --- | --- |
| Support URL | `https://askseekpray.app/support` |
| Marketing URL (optional) | `https://askseekpray.app` |
| Privacy Policy URL | `https://askseekpray.app/privacy` |
| Terms of Use URL | `https://askseekpray.app/terms` |

---

## Promotional Text (170 chars max)

This field can be edited *without* a new build review — useful for launch-day adjustments. Currently 137 chars.

```
Tell Seek what is on your heart and receive scripture, prayer, and worship matched to the moment. Free, no ads, no subscription.
```

---

## Description (4000 chars max — currently 2,882)

```
When you are anxious, tired, grateful, hurting, or hopeful — the right scripture meets the moment. Seek finds it for you.

Tell Seek what is on your heart in a few words or a few paragraphs. Within seconds, you receive 3–5 verses chosen for what you actually shared, a short prayer, an action step, and a worship song that fits the mood. Tap any verse to turn it into a beautiful shareable card.

WHAT SEEK DOES

Scripture chat — Type freely or pick a quick prompt like "Joy," "Anxious," or "Lonely." Receive verses with brief context, a prayer, an action step, and a worship song with Apple Music and Spotify links.

Verse card creator — Eighteen pre-designed templates across nature, minimal, watercolor, and bold styles. Renders at story size for sharing or saving to your camera roll.

Daily verse — A new verse every morning, themed, with pull-to-refresh. Shows the most recent saved verse if you are offline.

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

We collect your account info (Apple Sign In or email), your preferences (translation, notification times), basic usage stats (chats per day for rate limits), and your push token if you enable notifications. We do not use third-party analytics SDKs, AdMob, advertising identifiers, or precise location.

DENOMINATIONALLY NEUTRAL

Seek does not promote any particular church, doctrine, or interpretation. The verses come from the Bible. The prayers are short and broad. The worship songs span tradition and contemporary.

Built with love for the people of God.
```

*Characters: ~2,610 / 4,000. Headroom is intentional — Apple's preview cuts off at ~700 chars on most devices, so the lead 2 paragraphs do most of the work.*

---

## Keywords (100 chars max — currently 89)

Comma-separated, no spaces between commas. Don't repeat words from the title or subtitle ("seek," "scripture," "moment" are already auto-indexed).

```
bible,prayer,christian,faith,verse,worship,kjv,nlt,devotional,gospel,jesus,psalm,ai bible
```

*"ai bible" is two words separated by a space — Apple indexes both as separate searchable terms (`ai`, `bible`) within the same keyword slot. Good ASO move.*

---

## What's New in This Version (4000 chars max)

For 1.0.0 launch:

```
Welcome to Seek.

Tell us what is on your heart and we will find scripture for the moment. Three to five verses, a short prayer, a worship song, an action step. Tap any verse to share it as a beautiful card.

Free for everyone. No subscription, no ads. Built for the people of God.
```

---

## Privacy Nutrition Labels

Apple's questionnaire is structured by data category. The answers below reflect the **current** app state (no IAP, no donations, local notifications only).

### Data Used to Track You
**Answer:** None. Seek does not use any data for tracking across apps or websites.

### Data Linked to You
*(everything we collect is tied to your Supabase auth UID)*

| Category | Data Type | Purposes |
| --- | --- | --- |
| Contact Info | Email Address | App Functionality |
| Contact Info | Name (display name from Apple Sign In or self-provided) | App Functionality |
| Identifiers | User ID (Supabase auth UID) | App Functionality |
| User Content | Other User Content (chat messages forwarded to Anthropic in transit; not persisted on Seek's servers) | App Functionality |
| Usage Data | Product Interaction (chat counts for rate limiting, streak counts, totals) | App Functionality |

### Data Not Linked to You
**Answer:** None.

### Drops vs. earlier draft
- **Purchase History — NOT collected.** App has no in-app purchases, no donations, and no payment surfaces.
- **Diagnostics — NOT collected.** No crash analytics, no perf monitoring, no third-party SDKs.

---

## Age Rating Questionnaire

Apple's questionnaire — answers below produce a **4+** rating.

| Question | Answer |
| --- | --- |
| Cartoon or Fantasy Violence | None |
| Realistic Violence | None |
| Prolonged Graphic or Sadistic Realistic Violence | None |
| Profanity or Crude Humor | None |
| Mature/Suggestive Themes | None |
| Horror/Fear Themes | None |
| Sexual Content or Nudity | None |
| Graphic Sexual Content and Nudity | None |
| Alcohol, Tobacco, or Drug Use or References | None |
| Simulated Gambling | None |
| Medical/Treatment Information | None |
| Unrestricted Web Access | No |
| Gambling | No |
| Contests | No |

*Note on crisis content: Seek may surface mental-health hotline numbers when a user describes crisis. This is text-based safety information, not "Medical/Treatment Information" in Apple's sense. Don't check that box.*

---

## App Review Information

### Sign-In Required: YES
A test account is required because all features sit behind authentication.

**Setup before submission:** create a Supabase user explicitly for App Review. Suggested credentials:
- Email: `appreview@askseekpray.app` (forwarded to your inbox)
- Password: *(generate a strong one and paste into ASC's secure field — do NOT commit it)*
- Verify the email manually in the Supabase dashboard if email verification is on.
- Optionally seed the account with a streak and a saved card so the reviewer immediately sees the engagement state.

### Notes for Reviewer (paste-ready)

```
Thank you for reviewing Seek. This is Build 8, addressing the four items from the Build 7 rejection of 2026-05-04.

CHANGES SINCE BUILD 7
- 2.1(a) Apple Sign In: refactored the Apple Sign In handler to flip authentication state and onboarding completion atomically inside a single MainActor.run block, eliminating an .onChange-driven navigation race that we believe broke under iOS 26.4.2.
- 5.1.1(v) Forced login: added "Continue without an account" on the sign-in screen. Guests reach Home and the Daily Verse without an account; chat and library remain account-based with sign-in CTAs.
- 2.1 China mainland: removed China mainland from this app's distribution territories.
- 3.1.1 Donations: removed entirely. There is no donation surface anywhere in the app.

SIGN-IN
- Apple Sign In is fully active. You may use it if your Apple ID is convenient, or use the email/password test account above. The "Continue without an account" path is also available for verifying guest behavior.

WHAT THE APP DOES
- User shares an emotion or moment in the chat ("anxious," "grateful," "lonely," etc.). The app calls a Supabase Edge Function which proxies to Anthropic's Claude API. Claude returns 3-5 Bible verses with brief context, a short prayer, an action step, and a worship song recommendation.
- All scripture text is real KJV or NLT (NLT default; KJV switchable in Settings). Anthropic generates the empathetic intro, prayer, action, and song suggestion — never the verse text itself.
- User can tap any verse to open a card creator with 18 pre-designed templates and save or share the result.

GUEST MODE
- The sign-in screen has a "Continue without an account" option directly below the email form. Guests land on Home and can read the daily verse, share the app with friends, and view the Privacy Policy and Terms of Service. Chat and Library are gated behind sign-in CTAs because both depend on rate limits, conversation history, or saved content (account-based features).

NO MONETIZATION
- Seek is free with no subscription, no in-app purchase, no ads, and no premium tier. The optional donation surface that appeared in Build 7 has been removed in full.

CRISIS LANGUAGE
- If a user types crisis-indicating language ("I want to hurt myself," etc.), Claude is instructed to surface grounding scripture AND mental-health hotline numbers (988 in the US, 116 123 in the UK, findahelpline.com globally). This is a deliberate safety feature.

NOTIFICATIONS
- Local notifications only. No APNs server-side push in this build. Daily verse fires at the user's chosen time via UNCalendarNotificationTrigger.

PRIVACY
- Seek's servers do not persist the contents of chat messages. Only the count of chats per day per user is stored, for rate limiting.

If you have any questions, please reach hello@askseekpray.app.
```

### Contact Info
- First Name: *(your first name)*
- Last Name: *(your last name)*
- Phone: *(your phone)*
- Email: `hello@askseekpray.app`

### Marketing Opt-Outs
- Sign me up for marketing email from Apple: your call

---

## Build & Submission

| Field | Value |
| --- | --- |
| Version | 1.0.0 |
| Build | 8 (resubmission build, replaces rejected Build 7) |
| Copyright | © 2026 LCIII Ventures LLC |
| Trade Representative Contact (Korea) | Skip unless distributing in South Korea |

### Pricing & Availability
- **Price:** Free
- **Availability:** All territories *(or restrict; Apple defaults to all)*
- **Pre-order:** Off

### App Privacy
- **Data collection:** Yes *(see nutrition labels above)*
- **Tracking:** No

---

## Pre-submission Checklist

- [x] Vercel: `askseekpray.app` attached, all four URLs resolve (Session 13)
- [x] Supabase: `appreview@askseekpray.app` test account provisioned (Session 13)
- [x] Apple Sign In: confirmed working server-side (Session 13 — five real production users)
- [x] App Store Connect: pasted blocks, screenshots uploaded, age rating + privacy labels complete (Session 14)
- [x] Submitted (Build 7 — rejected 2026-05-04)
- [ ] **Build 8 — resubmission**
  - [ ] App Store Connect: remove China mainland from Pricing & Availability
  - [ ] App Store Connect: update Promotional Text, Description ("WHY IT IS FREE" block), and What's New from this doc
  - [ ] App Store Connect: confirm Privacy Nutrition Labels still match (Purchase History should be unchecked)
  - [ ] Xcode: archive Build 8 (verify Build = 8, not cached as 7)
  - [ ] TestFlight: smoke test on iOS 26.4.2 device (guest flow + Apple Sign In)
  - [ ] App Store Connect: attach Build 8 to the version, paste updated reviewer notes, reply to App Review with response from changelog Session 16
  - [ ] Click Resubmit to App Review

---

*Last updated: 2026-05-01 (Session 13). Edit freely as fields evolve.*
