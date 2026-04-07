---
globs: ["supabase/functions/**/*.ts"]
---
# Supabase Edge Functions Rules
- Chat proxy must validate Supabase Auth JWT before forwarding to Claude
- Rate limit check happens BEFORE Claude API call (don't waste API credits)
- Claude system prompt lives in Edge Function env vars — never exposed to client
- All responses include remainingChats count
- Upsert usage to usage_logs table on every chat request
- Handle Claude API errors gracefully — return user-friendly error message
- Use Supabase client with service_role key for DB writes in Edge Functions
- Reference @docs/api-routes.md for all endpoint specs
