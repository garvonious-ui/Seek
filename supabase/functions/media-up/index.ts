// media-up — authenticated upload into the ig-media bucket. Auth: Bearer app_config['ig_cron_secret'].
// POST /media-up?path=reels-carousel/reel_x.mp4  body=raw bytes, Content-Type: video/mp4
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
const BUCKET = Deno.env.get("IG_MEDIA_BUCKET") ?? "ig-media";
serve(async (req: Request) => {
  const supabase = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
  const { data: secretRow } = await supabase.from("app_config").select("value").eq("key", "ig_cron_secret").single();
  const cronSecret = secretRow?.value;
  if (!cronSecret || (req.headers.get("Authorization") ?? "") !== `Bearer ${cronSecret}`) {
    return new Response(JSON.stringify({ error: "unauthorized" }), { status: 401 });
  }
  const url = new URL(req.url);
  const path = url.searchParams.get("path");
  if (!path) return new Response(JSON.stringify({ error: "missing path" }), { status: 400 });
  const contentType = req.headers.get("Content-Type") ?? "application/octet-stream";
  const body = new Uint8Array(await req.arrayBuffer());
  if (!body.length) return new Response(JSON.stringify({ error: "empty body" }), { status: 400 });
  const { error } = await supabase.storage.from(BUCKET).upload(path, body, { contentType, upsert: true });
  if (error) return new Response(JSON.stringify({ error: error.message }), { status: 500 });
  const pub = supabase.storage.from(BUCKET).getPublicUrl(path).data.publicUrl;
  return new Response(JSON.stringify({ ok: true, path, bytes: body.length, publicUrl: pub }), { headers: { "Content-Type": "application/json" } });
});
