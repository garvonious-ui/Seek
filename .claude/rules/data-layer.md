---
globs: ["*/Models/**/*.swift", "*/Services/**/*.swift"]
---
# Data Layer Rules
- All schema definitions are in @docs/schemas.md — never hardcode field names
- SwiftData is the primary local store — Supabase PostgreSQL is for sync and server-side data only
- Never store Claude API key or system prompt in client code
- Rate limit state comes from server response, not local calculation
- Bible verse lookups use local bundled JSON — never network calls
- All Supabase reads/writes go through a dedicated SupabaseService class
