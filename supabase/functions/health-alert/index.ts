// health-alert — pushes a phone notification when production is failing.
// cron every 15 min. Auth: Bearer app_config['ig_cron_secret'] (same as the IG crons).
//
// Why: in Session 26 chat was down for 2 days (49 crashes sitting in debug_logs)
// and 7 IG posts died silently — both found only because someone texted. Every
// failure path already writes debug_logs or marks the queue row, so this just
// watches those and says so out loud.
//
// Delivery: ntfy (https://ntfy.sh) — install the ntfy app and subscribe to the
// topic in the ALERT_NTFY_TOPIC secret. Pick an unguessable topic name; anyone
// who knows it can read the alerts. No secret set => checks run, nothing is sent.
//
// Each alert key is sent at most once per THROTTLE_HOURS (tracked in ops_alerts).
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const WINDOW_MIN = 15;          // matches the cron interval
const ERROR_THRESHOLD = 3;      // debug_logs rows per window before alerting
const OVERDUE_MIN = 60;         // approved IG post this late and unposted = stalled
const THROTTLE_HOURS = 6;

type Alert = { key: string; title: string; message: string; priority: "high" | "default" };

serve(async (req: Request) => {
  const supabase = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
  const { data: secretRow } = await supabase.from("app_config").select("value").eq("key", "ig_cron_secret").single();
  const cronSecret = secretRow?.value;
  if (!cronSecret || (req.headers.get("Authorization") ?? "") !== `Bearer ${cronSecret}`) {
    return new Response(JSON.stringify({ error: "unauthorized" }), { status: 401 });
  }

  const now = Date.now();
  const since = new Date(now - WINDOW_MIN * 60_000).toISOString();
  const alerts: Alert[] = [];

  // 1. Errors logged by chat / auth-preflight / anything else that writes debug_logs.
  const { data: errors } = await supabase.from("debug_logs").select("context").gte("created_at", since);
  if (errors && errors.length >= ERROR_THRESHOLD) {
    const byContext: Record<string, number> = {};
    for (const e of errors) byContext[e.context] = (byContext[e.context] ?? 0) + 1;
    const breakdown = Object.entries(byContext).sort((a, b) => b[1] - a[1]).map(([c, n]) => `${c} ×${n}`).join(", ");
    alerts.push({
      key: "debug_logs_spike",
      title: "Seek: errors spiking",
      message: `${errors.length} errors in the last ${WINDOW_MIN} min — ${breakdown}. Check debug_logs.`,
      priority: errors.some((e) => e.context.startsWith("chat_")) ? "high" : "default",
    });
  }

  // 2. IG autopost stalled: approved posts well past their slot and still unposted.
  const overdueBefore = new Date(now - OVERDUE_MIN * 60_000).toISOString();
  const { count: overdue } = await supabase.from("ig_post_queue")
    .select("id", { count: "exact", head: true })
    .eq("status", "approved").is("posted_at", null).lt("scheduled_for", overdueBefore);
  if (overdue && overdue > 0) {
    alerts.push({
      key: "ig_autopost_stalled",
      title: "Seek: Instagram autopost stalled",
      message: `${overdue} approved post(s) are over ${OVERDUE_MIN} min late and unposted. Check the ig-autopost cron and ig-publish logs.`,
      priority: "default",
    });
  }

  // 3. IG posts that hit the retry limit in the last day.
  const dayAgo = new Date(now - 24 * 3600_000).toISOString();
  const { data: failed } = await supabase.from("ig_post_queue")
    .select("media_path, error").eq("status", "failed").gte("scheduled_for", dayAgo);
  if (failed && failed.length > 0) {
    alerts.push({
      key: "ig_publish_failed",
      title: "Seek: Instagram post failed",
      message: `${failed.length} post(s) failed after retries — e.g. ${failed[0].media_path}: ${(failed[0].error ?? "").slice(0, 120)}`,
      priority: "default",
    });
  }

  const topic = Deno.env.get("ALERT_NTFY_TOPIC");
  const throttleSince = new Date(now - THROTTLE_HOURS * 3600_000).toISOString();
  const sent: string[] = [];
  for (const a of alerts) {
    const { count: recent } = await supabase.from("ops_alerts")
      .select("id", { count: "exact", head: true }).eq("alert_key", a.key).gte("sent_at", throttleSince);
    if (recent && recent > 0) continue;
    if (topic) {
      const res = await fetch(`https://ntfy.sh/${topic}`, {
        method: "POST",
        headers: { Title: a.title, Priority: a.priority, Tags: "warning" },
        body: a.message,
      });
      if (!res.ok) { console.error("ntfy_failed", res.status, await res.text()); continue; }
    }
    await supabase.from("ops_alerts").insert({ alert_key: a.key, message: a.message, delivered: !!topic });
    sent.push(a.key);
  }

  return new Response(JSON.stringify({ checked: 3, alerts: alerts.map((a) => a.key), sent, delivery: topic ? "ntfy" : "none" }), {
    headers: { "Content-Type": "application/json" },
  });
});
