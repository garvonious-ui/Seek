// ig-insights — pulls account + per-media Instagram insights into Supabase.
// Auth: Bearer app_config['ig_cron_secret']. Defensive: stores what the token
// permits, returns a diagnostic of any insight-permission gaps.
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const GRAPH_VERSION = Deno.env.get("GRAPH_VERSION") ?? "v21.0";

async function graphGet(path: string, params: Record<string, string>) {
  const url = `https://graph.facebook.com/${GRAPH_VERSION}/${path}?` + new URLSearchParams(params).toString();
  const res = await fetch(url);
  const text = await res.text();
  let json: any = {};
  try { json = JSON.parse(text); } catch (_) {}
  if (!res.ok) throw new Error(`${res.status}: ${text}`);
  return json;
}

function metricMap(insightsJson: any): Record<string, number> {
  const out: Record<string, number> = {};
  for (const item of insightsJson?.data ?? []) {
    const v = item?.values?.[0]?.value ?? item?.total_value?.value ?? 0;
    out[item.name] = typeof v === "number" ? v : 0;
  }
  return out;
}

const METRICS: Record<string, string> = {
  REELS: "reach,saved,likes,comments,shares,total_interactions,views",
  IMAGE: "reach,saved,likes,comments,shares,total_interactions",
  CAROUSEL: "reach,saved,likes,comments,shares,total_interactions",
  STORIES: "reach,replies",
};

serve(async (req: Request) => {
  const supabase = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
  const { data: secretRow } = await supabase.from("app_config").select("value").eq("key", "ig_cron_secret").single();
  const cronSecret = secretRow?.value;
  if (!cronSecret || (req.headers.get("Authorization") ?? "") !== `Bearer ${cronSecret}`) {
    return new Response(JSON.stringify({ error: "unauthorized" }), { status: 401 });
  }

  const { data: cfg, error: cfgErr } = await supabase.from("ig_config").select("*").eq("id", 1).single();
  if (cfgErr || !cfg) return new Response(JSON.stringify({ error: "ig_config missing" }), { status: 500 });
  const igId = cfg.ig_user_id, token = cfg.access_token;

  const diag: any = { account: null, media: 0, insightErrors: [], updated: [] };

  // ---- account snapshot ----
  try {
    const acct = await graphGet(`${igId}`, { fields: "followers_count,media_count", access_token: token });
    let reach = null;
    try {
      const r = await graphGet(`${igId}/insights`, { metric: "reach", period: "day", access_token: token });
      reach = metricMap(r).reach ?? null;
    } catch (e) { diag.insightErrors.push("account_reach: " + (e as Error).message.slice(0, 160)); }
    const today = new Date().toISOString().slice(0, 10);
    await supabase.from("ig_account_insights").upsert({ snapshot_date: today, followers_count: acct.followers_count ?? null, media_count: acct.media_count ?? null, reach, fetched_at: new Date().toISOString() }, { onConflict: "snapshot_date" });
    diag.account = { followers: acct.followers_count, media: acct.media_count, reach };
  } catch (e) { diag.insightErrors.push("account: " + (e as Error).message.slice(0, 200)); }

  // ---- per-media ----
  const { data: posts } = await supabase.from("ig_post_queue").select("id, day_index, media_type, caption, ig_media_id, posted_at").not("ig_media_id", "is", null);
  for (const p of posts ?? []) {
    const row: any = {
      ig_media_id: p.ig_media_id, queue_id: p.id, day_index: p.day_index, media_type: p.media_type,
      caption_hook: (p.caption || "").split("\n")[0].slice(0, 120), posted_at: p.posted_at, fetched_at: new Date().toISOString(), raw: {},
    };
    // basic fields (instagram_basic)
    try {
      const b = await graphGet(`${p.ig_media_id}`, { fields: "permalink,like_count,comments_count,media_product_type,timestamp", access_token: token });
      row.permalink = b.permalink ?? null; row.likes = b.like_count ?? null; row.comments = b.comments_count ?? null;
      row.raw.basic = b;
    } catch (e) { diag.insightErrors.push(`media_basic ${p.ig_media_id}: ` + (e as Error).message.slice(0, 120)); }
    // insights (instagram_manage_insights)
    try {
      const metric = METRICS[p.media_type] || METRICS.IMAGE;
      const ins = await graphGet(`${p.ig_media_id}/insights`, { metric, access_token: token });
      const m = metricMap(ins);
      row.reach = m.reach ?? null; row.views = m.views ?? null; row.saved = m.saved ?? null;
      row.shares = m.shares ?? null; row.total_interactions = m.total_interactions ?? null; row.replies = m.replies ?? null;
      if (m.likes != null) row.likes = m.likes; if (m.comments != null) row.comments = m.comments;
      row.raw.insights = m;
    } catch (e) { diag.insightErrors.push(`media_insights d${p.day_index} ${p.media_type}: ` + (e as Error).message.slice(0, 140)); }
    await supabase.from("ig_insights").upsert(row, { onConflict: "ig_media_id" });
    diag.media++;
    diag.updated.push({ day: p.day_index, type: p.media_type, reach: row.reach, views: row.views, saved: row.saved, likes: row.likes });
  }

  return new Response(JSON.stringify(diag, null, 2), { headers: { "Content-Type": "application/json" } });
});
