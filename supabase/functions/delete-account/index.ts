import { createClient } from "jsr:@supabase/supabase-js@2";

// Permanently deletes the calling user's account and all associated data.
// The caller is identified from their own JWT; the actual delete uses the
// service role. Deleting the auth user cascades to profiles,
// notification_settings, and usage_logs (FK ON DELETE CASCADE). Chat content
// is never persisted server-side. Required for the Google Play / App Store
// account-deletion policy.
//
// Deployed with verify_jwt=false (the token is validated in-function via
// getUser) following this project's chat/daily-verse pattern.

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, content-type, apikey",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function json(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...cors, "Content-Type": "application/json" },
  });
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return json({ error: "method_not_allowed" }, 405);

  try {
    const authHeader = req.headers.get("Authorization") ?? "";
    const token = authHeader.replace(/^Bearer\s+/i, "").trim();
    if (!token) return json({ error: "missing_token" }, 401);

    const url = Deno.env.get("SUPABASE_URL")!;
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

    // Identify the caller from their JWT.
    const userClient = createClient(url, anonKey, {
      global: { headers: { Authorization: `Bearer ${token}` } },
    });
    const { data: { user }, error: userErr } = await userClient.auth.getUser(token);
    if (userErr || !user) return json({ error: "invalid_token" }, 401);

    // Delete the auth user with the service role. Cascades to all PII rows.
    const admin = createClient(url, serviceKey, {
      auth: { autoRefreshToken: false, persistSession: false },
    });
    const { error: delErr } = await admin.auth.admin.deleteUser(user.id);
    if (delErr) {
      console.error("delete-account failed", user.id, delErr.message);
      return json({ error: "delete_failed" }, 500);
    }

    return json({ success: true }, 200);
  } catch (e) {
    console.error("delete-account unexpected", String(e));
    return json({ error: "unexpected" }, 500);
  }
});
