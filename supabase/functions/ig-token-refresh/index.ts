// ig-token-refresh — extends the long-lived Meta token (~60 day expiry) and stores it
// back in public.ig_config. Invoked weekly by pg_cron (Bearer = app.ig_cron_secret).
//
// Uses the fb_exchange_token grant, which re-issues a fresh 60-day long-lived token from a
// still-valid one. Run weekly so the clock never runs out.
//
// Auth: Bearer = app_config['ig_cron_secret'] (read from DB).
// SUPABASE_URL + SUPABASE_SERVICE_ROLE_KEY auto-injected. You must set as Edge secrets:
//   META_APP_ID, META_APP_SECRET. Optional: GRAPH_VERSION (default v21.0).

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const GRAPH_VERSION = Deno.env.get("GRAPH_VERSION") ?? "v21.0";

serve(async (req: Request) => {
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  const { data: secretRow } = await supabase
    .from("app_config").select("value").eq("key", "ig_cron_secret").single();
  const cronSecret = secretRow?.value;
  const auth = req.headers.get("Authorization") ?? "";
  if (!cronSecret || auth !== `Bearer ${cronSecret}`) {
    return new Response(JSON.stringify({ error: "unauthorized" }), { status: 401 });
  }

  try {
    const { data: cfg, error: cfgErr } = await supabase
      .from("ig_config").select("*").eq("id", 1).single();
    if (cfgErr || !cfg) throw new Error("ig_config missing");

    const params = new URLSearchParams({
      grant_type: "fb_exchange_token",
      client_id: Deno.env.get("META_APP_ID")!,
      client_secret: Deno.env.get("META_APP_SECRET")!,
      fb_exchange_token: cfg.access_token,
    });
    const res = await fetch(
      `https://graph.facebook.com/${GRAPH_VERSION}/oauth/access_token?${params}`,
    );
    const text = await res.text();
    if (!res.ok) {
      console.error(`token_refresh_fail status=${res.status} body=${text}`);
      throw new Error(`refresh ${res.status}: ${text}`);
    }
    const json = JSON.parse(text);
    if (!json.access_token) throw new Error(`no access_token in response: ${text}`);

    await supabase.from("ig_config").update({
      access_token: json.access_token,
      token_updated_at: new Date().toISOString(),
    }).eq("id", 1);

    return new Response(
      JSON.stringify({ status: "refreshed", expires_in: json.expires_in ?? null }),
      { headers: { "Content-Type": "application/json" } },
    );
  } catch (err) {
    const msg = err instanceof Error ? err.message : String(err);
    console.error(`token_refresh_error ${msg}`);
    return new Response(JSON.stringify({ status: "error", error: msg }), { status: 500 });
  }
});
