# Screen Map & Feature Specs

## Navigation Structure
```
App Launch
├── Onboarding (first launch only)
│   ├── Welcome
│   ├── Personalization
│   ├── Notification Permission
│   └── Sign In
├── Tab Bar (3 tabs)
│   ├── Home
│   │   ├── Daily Verse Card (tappable → card creator)
│   │   ├── Streak Counter
│   │   ├── Chat Input ("What's on your heart?")
│   │   └── [Ad Banner]
│   ├── Chat
│   │   ├── Active Conversation
│   │   ├── Verse Results (tappable → card creator)
│   │   └── Rate Limit Message (when hit)
│   └── Library
│       ├── Cards Tab (grid)
│       ├── Favorites Tab (list)
│       └── History Tab (list)
├── Card Creator (modal)
│   ├── Template Picker (horizontal scroll)
│   ├── Preview
│   └── Save / Share Actions
├── Profile (accessible from tab bar avatar)
│   ├── Stats
│   ├── Settings
│   ├── Subscription Management
│   └── Sign Out / Delete Account
└── Premium Upgrade (modal, triggered from rate limit or settings)
    ├── Feature Comparison
    ├── Price + Trial CTA
    └── Restore Purchases
```

## Feature 1: Scripture Chat (Core Feature)
User types what they're going through → AI returns 3-5 relevant scriptures with brief context for each → user taps one → verse card creation flow.

**Chat UX flow:**
1. Home screen has prominent text input: "What's on your heart today?"
2. User types freely — any emotion or life moment
3. App sends to Claude API with scripture-matching system prompt
4. AI responds with 3-5 scripture options + prayer + worship song
5. User taps a verse → transitions to Card Creator
6. Conversation persists in a scrollable chat view
7. User can ask follow-up questions

**Edge cases:**
- Empty/nonsensical input → "I'd love to help — could you tell me a little more?"
- Non-faith topic → Gentle redirect
- Crisis language → Comforting scripture + encourage professional help
- Purely positive input → Match their joy
- Very long input → Truncate at 500 chars client-side

## Feature 2: Verse Card Creator
15-20 pre-designed templates in 4 categories: Nature, Minimal, Watercolor, Bold. Cards render at 1080x1920 (9:16 IG story) as PNG via ImageRenderer. Save to Photos or share via iOS share sheet.

## Feature 3: Daily Verse & Push Notifications
Pre-curated pool of 365 verses, themed, avoids repeating within 90 days. Two notification types: Daily Verse (morning) and Streak Nudge (evening if inactive).

## Feature 4: Streak Tracker
Day counts if user: opens app + views daily verse, has AI chat, or saves/shares a card. Streak milestones at 7, 30, 90, 365. Grace period: miss one day, do two actions today to restore.

## Feature 5: Saved Library
Three tabs: Cards (thumbnail grid), Favorites (hearted verses list), History (past conversations). Actions: re-share, edit template, delete, copy text.

## Feature 6: Profile & Settings
Stats display, notification preferences, subscription management, rate/review, share app, privacy/terms, sign out, delete account.

## Feature 7: Onboarding
3-4 screens: Welcome → Personalization (multi-select topics) → Notification permission → Sign In (Apple, Google, email).

## Feature 8: Monetization
Free: 5 chats/day, ads, all basic templates. Premium ($4.99/mo or $39.99/yr): 50 chats/day, ad-free, premium templates, 7-day free trial.
