// ig-replenish — keeps the IG queue from running dry. When future feed posts
// drop below a threshold, extends the R-R-C calendar from the EXISTING media
// library (least-recently-used) with fresh Claude-written captions. Inserts as
// 'pending' so the approval flow still gates posting.
// Auth: Bearer app_config['ig_cron_secret'].
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const FEED = ["IMAGE", "REELS", "CAROUSEL"];
const HASHTAGS = {
  verse: "#dailyverse #verseoftheday #bibleverse #scriptureoftheday #faithoverfear #christianquotes #godisgood #christianliving #dailydevotional #walkbyfaith #scripturecards #biblescripture",
  product: "#bibleapp #faithtech #christianapp #scriptureart #versecard #prayerlife #quiettime #morningdevotion #faithjourney #seekapp #digitaldiscipleship #christiancreators",
};
const ANTHROPIC_URL = "https://api.anthropic.com/v1/messages";
const MODEL = "claude-sonnet-5";

function firstLine(s: string) { return (s || "").split("\n")[0].slice(0, 200); }

async function genCaptions(items: any[]): Promise<string[] | null> {
  const key = Deno.env.get("ANTHROPIC_API_KEY");
  if (!key) return null;
  const list = items.map((p, i) => `${i + 1}. kind=${p.kind}, type=${p.type}, original="${firstLine(p.srcCaption)}"`).join("\n");
  const prompt = `You write Instagram captions for Seek, a scripture app (@askseekpray). Voice: warm, pastoral, denominationally neutral, NLT, never preachy. For each item below write ONE fresh caption BODY (do not reuse the original wording). Keep the same Bible verse/reference if the original has one, and include the "— Book Chapter:Verse, NLT" line when relevant. If kind=product, keep it about the app and end with "Free on the App Store. Link in bio." Do NOT include hashtags (they are added separately). Keep each to 2-4 short lines.\n\nItems:\n${list}\n\nReturn ONLY a JSON array of ${items.length} strings, in order. No markdown.`;
  try {
    const res = await fetch(ANTHROPIC_URL, {
      method: "POST",
      headers: { "Content-Type": "application/json", "x-api-key": key, "anthropic-version": "2023-06-01" },
      body: JSON.stringify({ model: MODEL, max_tokens: 2200, messages: [{ role: "user", content: prompt }] }),
    });
    if (!res.ok) return null;
    const data = await res.json();
    let txt = (data.content?.[0]?.text || "").trim();
    txt = txt.replace(/^```\w*\s*\n?/, "").replace(/\n?\s*```\s*$/, "");
    const arr = JSON.parse(txt.slice(txt.indexOf("[")));
    return Array.isArray(arr) && arr.length === items.length ? arr.map((s) => String(s)) : null;
  } catch (_) { return null; }
}

serve(async (req: Request) => {
  const supabase = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
  const { data: secretRow } = await supabase.from("app_config").select("value").eq("key", "ig_cron_secret").single();
  const cronSecret = secretRow?.value;
  if (!cronSecret || (req.headers.get("Authorization") ?? "") !== `Bearer ${cronSecret}`) {
    return new Response(JSON.stringify({ error: "unauthorized" }), { status: 401 });
  }
  const body = await req.json().catch(() => ({}));
  const keepAhead = body.keep_days_ahead ?? 14;
  const extendTo = body.extend_to_days_ahead ?? 30;
  const maxNew = body.max_new ?? 12;
  const force = !!body.force;
  const dryRun = !!body.dry_run;

  const { data: all } = await supabase.from("ig_post_queue").select("day_index, scheduled_for, media_type, media_path, media_paths, caption");
  if (!all || !all.length) return new Response(JSON.stringify({ error: "empty queue" }), { status: 500 });
  const now = Date.now();
  const feed = all.filter((r: any) => FEED.includes(r.media_type));
  const futureFeed = feed.filter((r: any) => new Date(r.scheduled_for).getTime() > now).length;
  if (futureFeed >= keepAhead && !force) {
    return new Response(JSON.stringify({ status: "idle", futureFeed, keepAhead }), { headers: { "Content-Type": "application/json" } });
  }
  const maxDay = Math.max(...all.map((r: any) => r.day_index));
  const lastFeed = feed.reduce((a: any, b: any) => new Date(a.scheduled_for) > new Date(b.scheduled_for) ? a : b);
  const base = new Date(lastFeed.scheduled_for);

  // least-recently-used pools from existing library
  const lastUsed: Record<string, number> = {};
  const sample: Record<string, any> = {};
  for (const r of feed) {
    const k = r.media_type === "CAROUSEL" ? r.media_path : r.media_path; // cover key for carousels
    const t = new Date(r.scheduled_for).getTime();
    if (!(k in lastUsed) || t > lastUsed[k]) lastUsed[k] = t;
    if (!sample[k]) sample[k] = r;
  }
  const reelPool = feed.filter((r: any) => r.media_type === "REELS").map((r: any) => r.media_path)
    .filter((v, i, a) => a.indexOf(v) === i).sort((x, y) => (lastUsed[x] || 0) - (lastUsed[y] || 0));
  const carPool = feed.filter((r: any) => r.media_type === "CAROUSEL").map((r: any) => r.media_path)
    .filter((v, i, a) => a.indexOf(v) === i).sort((x, y) => (lastUsed[x] || 0) - (lastUsed[y] || 0));
  const storyPngs = all.filter((r: any) => r.media_type === "STORIES" && (r.media_path || "").startsWith("stories/"))
    .map((r: any) => r.media_path).filter((v, i, a) => a.indexOf(v) === i).sort();

  const target = new Date(); target.setUTCDate(target.getUTCDate() + extendTo);
  const plan: any[] = [];
  let di = maxDay, ri = 0, ci = 0, si = 0;
  for (let i = 1; i <= 60 && plan.length < maxNew; i++) {
    const d = new Date(base); d.setUTCDate(base.getUTCDate() + i); d.setUTCHours(11, 0, 0, 0);
    if (d > target) break;
    di += 1;
    // Carousels retired 2026-07-30 review: ~5 avg reach vs ~68 for reels.
    // Feed is reels-only now; carousel *content* is being rebuilt as reels.
    const isCar = false;
    if (isCar) {
      const cover = carPool[ci % carPool.length]; ci++;
      const src = sample[cover];
      plan.push({ di, d, type: "CAROUSEL", media_path: cover, media_paths: src?.media_paths || null, srcCaption: src?.caption || "", kind: "verse" });
    } else {
      const mp = reelPool[ri % reelPool.length]; ri++;
      const src = sample[mp];
      plan.push({ di, d, type: "REELS", media_path: mp, media_paths: null, srcCaption: src?.caption || "", kind: mp.startsWith("reelsa/seek_") ? "product" : "verse" });
    }
  }
  if (!plan.length) return new Response(JSON.stringify({ status: "idle", reason: "nothing to add", futureFeed }), { headers: { "Content-Type": "application/json" } });

  const captions = await genCaptions(plan);
  const rows: any[] = [];
  for (let i = 0; i < plan.length; i++) {
    const p = plan[i];
    const bodyTxt = (captions && captions[i]) ? captions[i] : firstLine(p.srcCaption);
    const caption = `${bodyTxt}\n\n.\n.\n${HASHTAGS[p.kind] || HASHTAGS.verse}`;
    rows.push({ day_index: p.di, scheduled_for: p.d.toISOString(), media_type: p.type, media_path: p.media_path, media_paths: p.media_paths, caption, status: "pending" });
    if (storyPngs.length) { const e = new Date(p.d); e.setUTCHours(23, 10, 0, 0); rows.push({ day_index: p.di, scheduled_for: e.toISOString(), media_type: "STORIES", media_path: storyPngs[si % storyPngs.length], media_paths: null, caption: "", status: "pending" }); si++; }
    const m = new Date(p.d); m.setUTCHours(11, 10, 0, 0); rows.push({ day_index: p.di, scheduled_for: m.toISOString(), media_type: "STORIES", media_path: p.media_path, media_paths: null, caption: "", status: "pending" });
  }

  if (dryRun) {
    return new Response(JSON.stringify({ status: "dry_run", futureFeed, wouldAdd: plan.length, dayRange: [plan[0].di, plan[plan.length - 1].di], dateRange: [plan[0].d, plan[plan.length - 1].d], captionsGenerated: !!captions, sampleCaption: rows[0].caption }, null, 2), { headers: { "Content-Type": "application/json" } });
  }
  const { error: insErr } = await supabase.from("ig_post_queue").insert(rows);
  if (insErr) return new Response(JSON.stringify({ status: "insert_failed", error: insErr.message }), { status: 500 });
  return new Response(JSON.stringify({ status: "replenished", futureFeedBefore: futureFeed, feedAdded: plan.length, rowsAdded: rows.length, dayRange: [plan[0].di, plan[plan.length - 1].di], captionsGenerated: !!captions }, null, 2), { headers: { "Content-Type": "application/json" } });
});
