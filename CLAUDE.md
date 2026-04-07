# Seek — AI-powered scripture companion for iOS

## What This Is
A native iOS SwiftUI app where users share what's on their heart — joy, gratitude, struggle, seeking — an AI surfaces 3-5 relevant Bible verses with a prayer and worship song recommendation, and they create beautiful shareable verse cards. Also includes daily verse notifications and streak tracking. Free with ads, premium tier removes ads and increases AI chat limit.

## Tech Stack
- SwiftUI (iOS 17+), Swift 5.9+
- SwiftData (local persistence), Supabase (Auth, PostgreSQL, Edge Functions)
- Claude API via Supabase Edge Functions proxy
- KJV Bible bundled as JSON (public domain)
- StoreKit 2 for subscriptions, AdMob for ads

## Critical Rules
- NEVER call Claude API directly from client — always through Supabase Edge Function proxy
- Scripture text always renders in serif font (Georgia/New York), distinct from UI text
- Rate limit: 5 free chats/day, 50 premium — tracked server-side in Supabase usage_logs table
- All scripture is KJV unless user has premium ESV enabled
- Denominationally neutral tone — no specific church doctrine in any AI response
- Crisis language in chat must surface scripture AND encourage professional help
- Match user's emotional energy — celebrate with those who celebrate, don't default to "comfort" tone
- All schemas and IDs are in @docs/schemas.md — always reference before data work

## Session Rules
- BEFORE starting work: read @docs/build-plan.md and @docs/changelog.md
- AFTER completing a feature or before /clear: update both files
- If session runs longer than 30 minutes, pause and offer to update changelog
- When I say "wrap up": update build-plan checkboxes, write changelog entry, summarize

## Reference Docs
- Architecture: @docs/architecture.md
- Schemas + IDs: @docs/schemas.md
- Build plan: @docs/build-plan.md
- Design system: @docs/design-system.md
- API routes: @docs/api-routes.md
- Screen specs: @docs/screens.md

## Commands
- Cmd+R — build and run in simulator
- Cmd+B — build only
- Cmd+Shift+K — clean build folder

## Current Phase
Phase 1 — MVP (App Store Ready)
See @docs/build-plan.md for task checklist
