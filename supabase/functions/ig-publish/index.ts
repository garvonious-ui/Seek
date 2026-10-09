// ig-publish — IMAGE, REELS, CAROUSEL, STORIES. cron every 15 min. Auth: Bearer app_config['ig_cron_secret'].
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const GRAPH_VERSION = Deno.env.get("GRAPH_VERSION") ?? "v21.0";
const BUCKET = Deno.env.get("IG_MEDIA_BUCKET") ?? "ig-media";
const POLL_MAX = 20, POLL_MS = 6000;
// Images/carousel children usually finish in well under a second, so poll them
// on a much tighter loop than video — otherwise a 10-slide carousel would burn
// 10 x 6s of function time just confirming what is already done.
const FAST_POLL_MAX = 15, FAST_POLL_MS = 1000;
const sleep = (ms: number) => new Promise((r) => setTimeout(r, ms));

async function graph(path: string, params: Record<string, string>, method: "GET" | "POST") {
  const url = `https://graph.facebook.com/${GRAPH_VERSION}/${path}`;
  const body = new URLSearchParams(params);
  const res = method === "GET" ? await fetch(`${url}?${body.toString()}`)
    : await fetch(url, { method: "POST", headers: { "Content-Type": "application/x-www-form-urlencoded" }, body });
  const text = await res.text();
  let json: any = {};
  try { json = JSON.parse(text); } catch (_) {}
  if (!res.ok) { console.error(`graph_fail endpoint=${path} status=${res.status} body=${text}`); throw new Error(`graph ${res.status}: ${text}`); }
  return json;
}

// Wait for a container to reach FINISHED before it is used (published, or
// attached to a carousel parent).
//
// This previously ran ONLY for REELS and for video STORIES. Image containers —
// carousel children, the carousel parent, image stories, and plain IMAGE posts —
// were published the instant they were created. Instagram had usually not
// finished processing them yet, so /media_publish returned
//   9007 / 2207027 "Media ID is not available"
// which killed 3 carousels and 4 image stories between 2026-06-21 and 07-22.
// Every container type now waits.
//
// `opts.fast` uses the short interval for image-ish containers.
// If the API omits status_code entirely (it is not documented for every
// container type / version), treat that as ready rather than looping to the
// timeout — the publish call itself is then the source of truth.
async function pollFinished(id: string, token: string, label: string, opts: { fast?: boolean } = {}) {
  const max = opts.fast ? FAST_POLL_MAX : POLL_MAX;
  const wait = opts.fast ? FAST_POLL_MS : POLL_MS;
  for (let i = 0; i < max; i++) {
    await sleep(wait);
    const st = await graph(id, { fields: "status_code", access_token: token }, "GET");
    if (st.status_code === undefined) {
      console.log(`poll ${label} ${id}: no status_code field, assuming ready`);
      return;
    }
    if (st.status_code === "FINISHED") return;
    if (st.status_code === "ERROR") throw new Error(`${label} processing error: ${JSON.stringify(st)}`);
  }
  throw new Error(`${label} processing timed out after ${max * wait}ms`);
}

serve(async (req: Request) => {
  const supabase = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
  const { data: secretRow } = await supabase.from("app_config").select("value").eq("key", "ig_cron_secret").single();
  const cronSecret = secretRow?.value;
  if (!cronSecret || (req.headers.get("Authorization") ?? "") !== `Bearer ${cronSecret}`) return new Response(JSON.stringify({ error: "unauthorized" }), { status: 401 });

  const { data: rows, error: selErr } = await supabase.from("ig_post_queue").select("*").eq("status", "approved").lte("scheduled_for", new Date().toISOString()).order("scheduled_for", { ascending: true }).limit(1);
  if (selErr) { console.error("select_fail", selErr); return new Response(JSON.stringify({ error: "select_failed" }), { status: 500 }); }
  if (!rows || rows.length === 0) return new Response(JSON.stringify({ status: "idle" }), { headers: { "Content-Type": "application/json" } });
  const post = rows[0];

  const { data: claimed } = await supabase.from("ig_post_queue").update({ status: "publishing", attempts: (post.attempts ?? 0) + 1 }).eq("id", post.id).eq("status", "approved").select("id");
  if (!claimed || claimed.length === 0) return new Response(JSON.stringify({ status: "already_claimed" }), { headers: { "Content-Type": "application/json" } });

  const pub = (p: string) => supabase.storage.from(BUCKET).getPublicUrl(p).data.publicUrl;
  try {
    const { data: cfg, error: cfgErr } = await supabase.from("ig_config").select("*").eq("id", 1).single();
    if (cfgErr || !cfg) throw new Error("ig_config missing");
    const igId = cfg.ig_user_id, token = cfg.access_token;
    let creationId: string;

    if (post.media_type === "CAROUSEL") {
      const paths: string[] = post.media_paths || [];
      if (!paths.length) throw new Error("carousel has no media_paths");
      const childIds: string[] = [];
      for (const p of paths) {
        const child = await graph(`${igId}/media`, { image_url: pub(p), is_carousel_item: "true", access_token: token }, "POST");
        childIds.push(child.id);
      }
      // Every child must be processed before the parent references it.
      for (const [i, id] of childIds.entries()) {
        await pollFinished(id, token, `carousel child ${i + 1}/${childIds.length}`, { fast: true });
      }
      const container = await graph(`${igId}/media`, { media_type: "CAROUSEL", children: childIds.join(","), caption: post.caption, access_token: token }, "POST");
      creationId = container.id;
      await pollFinished(creationId, token, "carousel", { fast: true });
    } else if (post.media_type === "REELS") {
      const container = await graph(`${igId}/media`, { media_type: "REELS", video_url: pub(post.media_path), caption: post.caption, access_token: token }, "POST");
      creationId = container.id; await pollFinished(creationId, token, "reel");
    } else if (post.media_type === "STORIES") {
      const path = post.media_path; const isVideo = /\.(mp4|mov)$/i.test(path);
      const params = isVideo ? { media_type: "STORIES", video_url: pub(path), access_token: token } : { media_type: "STORIES", image_url: pub(path), access_token: token };
      const container = await graph(`${igId}/media`, params, "POST");
      creationId = container.id;
      await pollFinished(creationId, token, isVideo ? "story video" : "story image", { fast: !isVideo });
    } else {
      const container = await graph(`${igId}/media`, { image_url: pub(post.media_path), caption: post.caption, access_token: token }, "POST");
      creationId = container.id;
      await pollFinished(creationId, token, "image", { fast: true });
    }

    const published = await graph(`${igId}/media_publish`, { creation_id: creationId, access_token: token }, "POST");
    await supabase.from("ig_post_queue").update({ status: "posted", container_id: creationId, ig_media_id: published.id, posted_at: new Date().toISOString(), error: null }).eq("id", post.id);
    return new Response(JSON.stringify({ status: "posted", day: post.day_index, type: post.media_type, ig_media_id: published.id }), { headers: { "Content-Type": "application/json" } });
  } catch (err) {
    const msg = err instanceof Error ? err.message : String(err);
    console.error(`publish_fail day=${post.day_index} type=${post.media_type} err=${msg}`);
    // Retry transient failures instead of burying the row. A post that has not
    // exhausted its attempts goes back to `approved` so the next 15-min cron
    // tick picks it up; only after 3 tries does it stick at `failed`. The old
    // behaviour marked the very first failure terminal, which is why seven
    // posts died silently and nothing ever retried them.
    const attempts = (post.attempts ?? 0) + 1;
    const terminal = attempts >= 3;
    await supabase.from("ig_post_queue").update({ status: terminal ? "failed" : "approved", error: msg }).eq("id", post.id);
    return new Response(JSON.stringify({ status: terminal ? "failed" : "will_retry", attempts, day: post.day_index, error: msg }), { status: 500, headers: { "Content-Type": "application/json" } });
  }
});
