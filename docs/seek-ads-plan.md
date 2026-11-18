# Seek Ads, low-budget install test (Dec 2026)

Companion to `docs/instagram-refresh-2026-11.md`. Creative renders from
`marketing/instagram/render_ads.py`, copy and hooks in `refresh_slate.py` (`ADS`).

## Where things stand (from changelog, Session 28)

- **Ad account:** "Seek Ads" (`act=28085607991055964`) in the Seek business
  portfolio (`1397648395755717`). The Seek app (`882028774961076`) is connected.
- **Campaign:** "Seek - App Installs (Lean Test)" is a $10/day draft, never
  published. It has 6 draft ads:
  - Demo - Chat, Card Flip, Worship (feature reels)
  - Verse - Lost, Lonely, Restless
- **No payment method** on the account yet.
- **iOS is blocked:** the ad set still points at the legacy "iOS 13.7 or
  earlier" store. The iOS 14+ option unlocks once Meta sees the Facebook SDK in a
  live App Store build, and 1.3.0 is the first build that carries it. **Check
  whether 1.3.0 is live yet.** It went to review Oct 9.
## Recommendation

**iOS only** (Lou's call, 2026-11-18). One campaign, one broad ad set, 4-5 ads,
$10/day. At this budget, more ad sets just split too little data. 4 weeks at
$10/day is about $280.

| Step | When | What |
|---|---|---|
| 1 | Now | Add billing. The 4 ads are rendered and ready to upload. |
| 1b | Dec 12 to 22 | Follower bridge, $5/day (below). Runs whether or not 1.3.0 is live yet. |
| 2 | 1.3.0 is live and the iOS 14+ store option shows in the ad set | Edit the existing draft "Seek - App Installs (Lean Test)": store "Apple App Store", finish the SKAN prompt in Events Manager, load the ads, publish at $10/day. |
| 3 | Day 14 | Keep the best 2 ads, render 2 variants of the winner. |

The campaign can't publish until step 2. Meta's iOS 14+ install campaigns need
the SDK in a live App Store build. If 1.3.0 is still in review, that's the
blocker. Android stays available as a fallback if iOS keeps slipping (the creative
would only need its end card changed to "Free on iPhone & Android").

## Follower bridge (Dec 12 to 22)

A small follower ad to run while the iPhone install ads are blocked on billing
and 1.3.0. It needs neither the SDK nor a live build.

**Why it's small.** 38 followers is too small an audience for Meta to target,
and about 90% of reel views already come from non-followers, so followers
aren't the goal. A follower is worth less than an install. Holiday auction
prices are also higher through December.

**What it buys:**
1. A paid read on which of the new hooks hold strangers, before more money goes
   into install ads built on the same hooks.
2. A warm audience. Save everyone who watched 50% or more of a reel as a custom
   audience. Once it's in the thousands, it's the first audience to try with the
   install ads.

| | |
|---|---|
| When | Dec 12 to 22. Starts after the posting-time test (Dec 11) so paid views don't skew it. |
| Creative | The best 1 or 2 reels from weeks 1-2, as posted (use the existing post so likes and comments stack). |
| Objective | Engagement, optimized for Instagram profile visits. |
| Audience | United States, 18+, Advantage+ audience (same as the install plan). |
| Budget | $5/day, about $50 total. Separate from the install budget. |
| Custom audience | Video viewers, 50%+ of the boosted reels (and the organic ones), last 365 days. Create it on day 1 so it fills from the start. |
| Stop rule | After $25: if it's buying views but almost no follows, stop. Keep the custom audience. |

**When installs unlock:** put most of the budget there. Add one install ad set
aimed at the video-viewer audience next to the broad one, and compare cost per
install.

## Targeting

- **Location:** United States. One market keeps the first read clean. Add CA,
  UK, AU later if CPI is fine.
- **Age:** 18+. The app allows 13+, but ads stay adult.
- **Language:** English.
- **Audience:** Advantage+ audience, no detailed targeting.
  - As far as I know, Meta removed detailed-targeting options tied to religious
    practices and groups in 2022. Confirm in Ads Manager.
  - Stacking proxy interests (worship artists, Bible apps) on a $10 budget would
    shrink delivery anyway.
  - The creative does the targeting: scripture on screen in the first second
    filters for the right people.
- **Placements:** Advantage+ placements, but exclude Audience Network. On small
  install budgets it tends to buy low-quality installs. Recheck after week 1 if
  delivery is weak.
- **Devices:** iOS only, set by the campaign's app/store choice. Don't narrow by
  device model or OS version beyond Seek's iOS 17 minimum, if Meta offers that
  field.
- **Exclusions:** none yet. With ~190 users there's nothing worth excluding.

## Creative

Run 5 ads per ad set: the 4 new ones below plus the best existing draft (Demo -
Chat). Each new ad has a 9:16 cut (Reels, Stories) and a 4:5 cut (Feed). Upload
both to one ad and let placement pick.

| Ad | Angle | Structure | Files |
|---|---|---|---|
| ad01 Racing mind | Night / anxious | Hook "For the nights the mind won't slow down." then chat screen ("Say what's on your heart. Get the verses for it."), then card screen, then end card | `ads/ad01_racing_mind_9x16.mp4`, `_4x5.mp4` |
| ad02 Words won't come | Honest prayer | Hook "Prayer, when the words won't come." then chat, then card, then end card | `ads/ad02_words_wont_come_*` |
| ad03 Before the news | Morning habit | Hook "One verse before the news." then home screen with daily verse, then card, then end card | `ads/ad03_before_news_*` |
| ad04 Foggy | Verse-first (best organic) | The "Foggy" hook reel with Jeremiah 29:11, then end card | `ads/ad04_foggy_*` |
| Demo - Chat | Product | Existing draft | already in the ad account |

- Every ad has the hook on frame 1, a 12-13s runtime, an original ambient bed at
  -18 LUFS, and burned-in text, so they work with sound off.
- The end card reads "Free on iPhone".
- **The iPhone screens are drawn in code**, the same approach as the older feature
  reels. `marketing/instagram/ios-screens/screens.html` rebuilds Home, Chat and
  Create Card from the SwiftUI views (colors, copy, layout). Georgia is rendered
  with Lora and SF Pro with Inter, since neither can be redistributed.
  - The chat types its message, then the intro, verse cards and prayer stream in.
  - The card creator cycles templates.
  - Verse text is the real NLT from the seed. The intro, context lines and
    prayer stand in for a typical answer.
- Content lives in `refresh_slate.IOS_SCREENS`. To re-render:
  `python3 render_ios_screens.py`, then `python3 render_ads.py`.

**Meta AI creative enhancements and generated variants: keep OFF**, as set in
Session 28. Auto-generated scripture copy or images is a brand risk.

## Copy

Meta's personal-attributes policy bans copy that asserts or implies the viewer's
religion, mental health or other personal traits. Lines like "Are you anxious?",
"Struggling with your faith?" or "Christians, you need this" can get the ad
rejected. Speak about the moment, not the person. No health claims either:
nothing like "relieves anxiety" or "better sleep."

**Primary text** (enter all 3, Meta rotates them):
1. Some nights the mind won't slow down. Seek finds a verse for whatever you're carrying, plus a short prayer. Free, no ads.
2. Type what's on your heart in plain words. Seek answers with scripture, a prayer and a worship song. Free on iPhone.
3. One verse before the news. A daily verse, verse cards you can share, and scripture for whatever the day brings. Free.

**Headlines:**
1. Scripture for whatever you're carrying
2. A verse for this moment
3. Free Bible verse companion

**CTA button:** Install now.

## What to measure

| Metric | Where | Why |
|---|---|---|
| Cost per install (CPI) | Ads Manager | The main number. No benchmark set; week 1 is the baseline. |
| Hook rate (3-sec views / impressions) | Ads Manager, add the column | Tells you whether frame 1 stops the scroll. Compare ads against each other. |
| CTR (link) | Ads Manager | Hook works but CTR is low: the demo or end card isn't selling. |
| New sign-ups per day | Supabase `profiles.created_at` | Installs that never sign up are wasted. Baseline: about 3 a week organic (+32 users Jul 30 to Oct 9, Session 28). |
| First chat within 24h | Supabase `usage_logs` | Real activation. |

## Rules for the test

- **Days 1-3:** don't touch anything. Edits reset Meta's learning.
- **Day 7:** pause any ad that has spent 2x the ad set's average CPI and has zero
  installs. Keep at least 3 ads live.
- **Day 14:** keep the best 2. Make 2 new variants of the winner (new hook, same
  structure) with `render_ads.py`.
- **Stop or rethink** if, after $150 spent, sign-ups per install are under 30%.
  At that point the installs aren't real users, and placements or creative are
  buying the wrong people.

## Launch checklist

1. **Lou:** add a payment method to Seek Ads.
2. **Confirm 1.3.0 is live** on the App Store (App Store Connect).
3. In Events Manager, check the Seek app's SDK tab. It should no longer say "out
   of date / release the app". Finish any SKAN schema prompt.
4. Open the draft "Seek - App Installs (Lean Test)". Switch the ad set store from
   "Apple App Store (iOS 13.7 or earlier)" to "Apple App Store".
5. Load the 4 new ads (both cuts each) plus Demo - Chat, with the copy above.
6. Set identity to Page **Ask Seek Pray** and Instagram **@askseekpray**.
7. Publish at $10/day. Note the date in `docs/changelog.md`.

## Reuse at POPLIFE

The hook-first renderer pattern (`render_hook_reels.py`) and this checklist are
brand-agnostic.

**What carries over:**
- Text on frame 1
- One broad ad set
- Personal-attributes-safe copy
- Kill rules tied to your own baseline

**What doesn't:** spirits clients need TTB/DISCUS review and 21+ age gating, and
none of that applies here.
