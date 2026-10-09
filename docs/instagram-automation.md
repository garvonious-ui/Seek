# Instagram Content Automation

End-to-end system that auto-publishes Seek's Instagram feed: branded verse cards + motion Reels, captioned and scheduled, posted to **@askseekpray** via the Instagram Graph API on a Supabase cron, with a tap-to-approve gate.

Sibling doc: `instagram-content-plan.md` (the 30-day calendar, strategy, Claude Design prompts). This doc is the **technical/operational** reference.

> **Current format (Session 21): daily Reel → Reel → Carousel.** 20 reels + 10 carousels over 30 days, 7am ET from 2026-06-17. Carousels on days 3/6/9/…/30. Reels live in `marketing/instagram/reels/` → `ig-media/reels/`; carousel cards in `marketing/instagram/carousels/` → `ig-media/carousels/`. Seed: `seed-rrc.sql`; captions: `captions-rrc.md`. The earlier single-card `feedv2/` set is unused by the current schedule.
>
> **Carousels:** `media_type='CAROUSEL'`, ordered slide keys in `media_paths text[]` (cover first), `media_path` = cover (for the dashboard thumb). `ig-publish` posts them by creating a child container per image (`is_carousel_item=true`), wrapping them in a `media_type=CAROUSEL` parent with `children=<comma-ids>`, then publishing. Validated live (Day 3, June 17).

---

## 1. What's deployed

| Piece | Where | Notes |
|-------|-------|-------|
| 21 verse cards (4:5, 1080×1350) | `marketing/instagram/cards/` → bucket `ig-media/feedv2/` | Lora serif, real Seek wordmark, NLT + reference. Rendered by `marketing/instagram/render_cards.py` (run via the outputs scratch copy). |
| 9 motion Reels (9:16, 1080×1920, H.264+AAC) | `marketing/instagram/reels/` → bucket `ig-media/reels/` | Rendered from the **Seek Design System** animation engine — see §5. |
| 30 captions | `marketing/instagram/captions.md` | Hook + body + CTA + hashtags, NLT. |
| Queue seed | `marketing/instagram/seed-ig-queue.sql` | 30 rows, 7:00 AM ET, start 2026-06-17. |
| Tables + cron | migration `supabase/migrations/20260616120000_create_ig_post_queue.sql` | `ig_post_queue`, `ig_config`, `app_config`. |
| Publisher | `supabase/functions/ig-publish/` | cron every 15 min; posts one due+approved row. |
| Token refresh | `supabase/functions/ig-token-refresh/` | weekly; extends the 60-day Meta token. |
| Live dashboard | Cowork artifact `seek-instagram-schedule` (+ local `marketing/instagram/admin.html`) | Preview + approve each post. |

Supabase project: `hxfiaowayrhuhzhhbaix`. IG account: **@askseekpray**, IG user id `17841417170841946`, linked to FB Page **Ask Seek Pray** (`1232119886641487`). Meta app **Seek Scripture Companion** `882028774961076`.

---

## 2. Data model

`public.ig_post_queue` — one row per scheduled post.
- `day_index` (1–30), `scheduled_for` (timestamptz, UTC), `media_type` (`IMAGE`|`REELS`), `media_path` (key within `ig-media`), `caption`, `status` (`pending`→`approved`→`publishing`→`posted`/`failed`), `container_id`, `ig_media_id`, `error`, `attempts`, `posted_at`.
- RLS: **service-role only** (no anon/auth policies).

`public.ig_config` — single row (`id=1`) holding the rotating Meta `access_token` + `ig_user_id`. Service-role only. The token lives in the DB (not an env var) so `ig-token-refresh` can rotate it in place.

`public.app_config` — key/value for cron: `ig_publish_url`, `ig_token_refresh_url`, `ig_cron_secret`. The functions read the cron secret from here (so `ig-publish` needs **no** manually-set secrets — Supabase auto-injects `SUPABASE_URL` + `SUPABASE_SERVICE_ROLE_KEY`).

Storage: public bucket `ig-media`, prefixes `feedv2/` (cards) and `reels/` (videos). Public read; writes are service-role only in steady state.

---

## 3. Publish flow (`ig-publish`)

Cron (`pg_cron` job `ig-autopost`, `*/15 * * * *`) → `net.http_post` to the function with `Authorization: Bearer <app_config.ig_cron_secret>`.

1. Auth: compare bearer to `app_config.ig_cron_secret`.
2. Select the **single oldest** row with `status='approved'` and `scheduled_for <= now()`.
3. Claim it (`status='publishing'`, guarded `eq('status','approved')`) — safe against overlapping ticks.
4. Build the public media URL from `ig-media`.
5. Create the Graph container: `POST /{IG_USER_ID}/media` (`image_url` or `media_type=REELS,video_url`).
6. **Reels only:** poll `GET /{container}?fields=status_code` until `FINISHED` (≤2 min).
7. Publish: `POST /{IG_USER_ID}/media_publish`.
8. Record `posted` + `ig_media_id`, or `failed` + `error` (logs `endpoint+status+body`).

Deployed with `verify_jwt=false` (it does its own cron-secret auth — mirrors the `--no-verify-jwt` gotcha in `CLAUDE.md`). Graph version pinned `v21.0`.

### Constraints (verified June 2026)
- Media must be a **public HTTPS URL** the Graph API fetches (hence the public bucket).
- 100 published posts / rolling 24h (carousel = 1). We do 1/day.
- Reels: 9:16, 5–90s, H.264/HEVC + AAC. Business account only.

---

## 4. Token

Long-lived user token (instagram_basic, instagram_content_publish, pages_show_list, pages_read_engagement, business_management), ~60-day expiry, stored in `ig_config.access_token`. `ig-token-refresh` (cron `ig-token-refresh`, Mondays 08:00 UTC) calls `oauth/access_token?grant_type=fb_exchange_token` with `META_APP_ID`/`META_APP_SECRET` and overwrites the row.

⚠ For the weekly refresh to work, set Edge secrets **`META_APP_ID`** and **`META_APP_SECRET`** (dashboard → Edge Functions → Secrets). Until then the current token still covers the campaign (expires ~Aug 15, 2026); refresh just keeps it alive long-term.

To re-mint a token manually: Graph API Explorer → app *Seek Scripture Companion* → add the 5 scopes → Generate → Access Token Tool → **Extend Access Token** → store in `ig_config`.

---

## 5. Reel render pipeline

Reels are rendered from the **`Seek Design System/`** folder's animation engine (`animations.jsx` `Stage`/`Sprite`/easing, `seek-screens.jsx`, `video-components.jsx`) — same system that made the app promo videos. Workspace: `outputs/reels/` (scratch).

- `reel.html` — loads the engine + a `VerseReel` motion template; 9 reel configs (verse/kicker/ref/CTA/gradient) keyed by `?reel=<day>`. Uses real **Georgia** (`Seek Design System/fonts/`) and the official `wordmark_light.png`.
- `render.js` — headless Chromium (Playwright) drives the timeline deterministically (`window.__setT(t)`), screenshots each frame at 24fps.
- `make.sh <id>` — renders frames to `/tmp` then `ffmpeg` → `reel_NN.mp4` (libx264, yuv420p, +faststart, silent AAC track for IG).

Headless note: the sandbox lacks root, so Chromium's system libs (libXdamage etc.) were staged locally and pointed to via `LD_LIBRARY_PATH`. Frames render to `/tmp` (mounted FS blocks `rmdir`). Page is served over `http://localhost` (file:// blocks the `.jsx` XHR).

To regenerate a reel: edit its config in `reel.html`, run `./make.sh <day>`, re-upload to `ig-media/reels/`.

---

## 6. Operations

**Approve posts.** Open the `seek-instagram-schedule` artifact (or `admin.html` locally with the service-role key) → tap **Approve**. Only `approved` rows post.

**Add/replace media.** Storage overwrite/delete by anon is blocked; upload new files under a **fresh prefix** and repoint: `update ig_post_queue set media_path=… where …`. (That's why cards live in `feedv2/`, not `feed/` or `cards/` — earlier revisions are orphaned but harmless.)

**Re-seed / change start date.** Edit `marketing/instagram/gen_captions_seed.py` (or `render_cards.py` data), regenerate, re-run the INSERT.

**Smoke test before trusting it.** Set one row `scheduled_for = now()`, approve it, confirm it posts (and check the IG account). Reset its time afterward.

**Failure triage.** `select day_index, error from ig_post_queue where status='failed'`. A missing Reel file or expired token are the usual causes. Re-approve to retry.

---

## 7. Feature reels + bed variety (Session 22)

App-demo reels (not verse cards) + multiple ambient beds. Full detail in `docs/feature-reels.md`.
- 4 feature reels (`marketing/instagram/feature-reels/`) occupy product slots **days 7/13/19/29** (day 1 was already posted): cardflip / streak / worship / chat. Morning repost stories reuse the new reel video; evening verse stories unchanged.
- 5 ambient beds (`feature-reels/_render/bedgen.py`): warm/tender/hopeful/still/vespers. All 16 scheduled verse reels were re-bedded (audio swap, rotating beds) and **overwritten in place** at `ig-media/reelsa/reel_NN.mp4` — so media_path is unchanged; the variety is in the files. Re-bedded sources: `marketing/instagram/reels_music/`.
- **Uploading new media to the bucket:** anon overwrite is blocked. Session 22 used a temporary token-guarded service-role Edge Function (`media-up`) to write to `ig-media`, then decommissioned it (now returns 410). To push more media later, redeploy a similar one-shot uploader or use the Storage UI. `media-up` can be deleted from the dashboard.
- Applied SQL of record: `seed-feature-reels.sql`, `seed-bed-variations.sql`. **Watch out:** each `day_index` has 3 rows (1 feed + 2 stories) — always filter `media_type='REELS'` when updating a feed row.

## 8. Performance insights (Session 23)

Daily pull of Graph API insights → Supabase → live dashboard.
- Tables: `ig_insights` (per-media, keyed on `ig_media_id`) + `ig_account_insights` (daily snapshot, keyed on `snapshot_date`). RLS service-role only.
- `ig-insights` Edge Function (auth = `Bearer app_config['ig_cron_secret']`, Graph v21). Stores followers/media + per-post likes/comments/permalink (always) and reach/saved/views/shares (needs `instagram_manage_insights`). Invoke manually: `POST /functions/v1/ig-insights` with the Bearer secret → returns a diagnostic.
- `pg_cron` `ig-insights-daily` at `0 12 * * *`. `app_config.ig_insights_url` holds the endpoint.
- Dashboard: Cowork artifact **`seek-ig-performance`** (Chart.js + KPIs + top posts).
- **To unlock reach/saves/views:** regenerate the long-lived token with `instagram_manage_insights` (own-account, no full App Review) and `update ig_config set access_token=…`. No code change needed; the daily job backfills.

## 9. Self-replenishing queue (Session 24)

Keeps the feed from running dry. `ig-replenish` Edge Function (Bearer `ig_cron_secret`): when future feed posts < `keep_days_ahead` (14), extends the R-R-C calendar from the existing media library (LRU reels/carousels) out to `extend_to_days_ahead` (30) with fresh Claude-written captions, inserting feed + 2 stories per day as `pending`. `pg_cron ig-replenish-weekly` Mon 09:00 UTC (`max_new` 16). `app_config.ig_replenish_url`.
- Test: `POST /functions/v1/ig-replenish` with `{"force":true,"dry_run":true}` → returns the plan + a sample caption without inserting.
- Recycles vetted media only (no new renders). To add genuinely new reels, render via `feature-reels/_render` + upload; the LRU pool picks them up.
- Inserts `pending` → still gated by approval. Change the function's `status` to `approved` for fully hands-off.

## 10. Open items

- [x] ~~Add `instagram_manage_insights` to unlock reach/saves/views~~ — DONE. Enabled the permission on the Meta app (Use cases → Instagram API → Permissions and features → "Ready for testing"), re-consented, and put the non-expiring Page token in `ig_config`. Insights now flowing. The Page token is `type=PAGE, expires_at=0` (never expires); the weekly `ig-token-refresh` keeps the data-access window fresh.
- [ ] Set `META_APP_ID` + `META_APP_SECRET` Edge secrets (enables weekly token auto-refresh).
- [ ] Live smoke-test one post end-to-end.
- [ ] Review day 7 (cardflip) before it auto-posts 2026-06-23; delete the dormant `media-up` function.
- [ ] (Optional) Clean orphaned `cards/` + `feed/` objects from the bucket via the Storage UI.
