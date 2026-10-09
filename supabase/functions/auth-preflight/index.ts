// auth-preflight — tells the sign-in screen the truth about an email address
// before it promises a password reset.
//
// Why this exists: Supabase's resetPasswordForEmail() returns 200 for ANY
// email, by design, so it never leaks whether an account exists. The app
// treated that 200 as "sent" and showed "Reset Email Sent — check your email."
// For the 95 of 157 users who signed up with Apple/Google there IS no password
// and no email is ever sent, so they tapped Forgot Password forever and nothing
// arrived.
//
// This endpoint branches honestly:
//   { status: "oauth_only", providers: ["apple"] }  -> tell them to use Apple
//   { status: "no_account" }                        -> tell them to sign up
//   { status: "sent" }                              -> a reset really was sent
//   { status: "rate_limited" }
//
// Tradeoff, stated plainly: this IS a user-enumeration endpoint. That is the
// entire point — the alternative is lying to 60% of users. For a devotional app
// whose "sensitive" fact is "this person uses Seek", that is the right trade.
// Do not copy this pattern into something where account existence is a secret.
//
// Throttling is deliberately two-tier. Per-email is tight (5 / 15 min): a human
// resetting their own password never needs more. Per-IP is loose (60 / 15 min)
// because Seek is a mobile app and many users share a carrier-grade NAT egress
// IP — a tight IP limit would lock out real people while barely inconveniencing
// an attacker rotating proxies.
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const EMAIL_LIMIT = 5;
const IP_LIMIT = 60;

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "authorization, content-type, apikey",
};
const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS, "Content-Type": "application/json" },
  });

// Hash the address so the throttle table never becomes a second store of user
// emails.
async function emailKey(email: string): Promise<string> {
  const data = new TextEncoder().encode(email.trim().toLowerCase());
  const digest = await crypto.subtle.digest("SHA-256", data);
  const hex = Array.from(new Uint8Array(digest))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
  return `email:${hex.slice(0, 32)}`;
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response(null, { headers: CORS });

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  try {
    const { email } = await req.json().catch(() => ({ email: null }));
    if (!email || typeof email !== "string" || !email.includes("@")) {
      return json({ status: "invalid_email" }, 400);
    }

    const ip =
      req.headers.get("x-forwarded-for")?.split(",")[0]?.trim() ??
      req.headers.get("cf-connecting-ip") ??
      "";

    const [emailOk, ipOk] = await Promise.all([
      supabase.rpc("auth_preflight_allow", { p_key: await emailKey(email), p_limit: EMAIL_LIMIT }),
      supabase.rpc("auth_preflight_allow", { p_key: ip ? `ip:${ip}` : "", p_limit: IP_LIMIT }),
    ]);
    if (emailOk.data === false || ipOk.data === false) {
      return json({
        status: "rate_limited",
        message: "Too many attempts. Please wait a few minutes and try again.",
      }, 429);
    }

    const { data: info, error: lookupErr } = await supabase.rpc(
      "auth_preflight_lookup",
      { p_email: email },
    );
    if (lookupErr) throw lookupErr;

    if (!info?.exists) {
      return json({
        status: "no_account",
        message: "We couldn't find an account with that email. Want to create one?",
      });
    }

    if (!info.has_password) {
      const providers: string[] = Array.isArray(info.providers) ? info.providers : [];
      const primary = providers.find((p) => p !== "email") ?? providers[0] ?? "social";
      const label = primary === "apple" ? "Apple"
        : primary === "google" ? "Google"
        : primary.charAt(0).toUpperCase() + primary.slice(1);
      return json({
        status: "oauth_only",
        providers,
        provider: primary,
        message:
          `This account signs in with ${label}, so there's no password to reset. ` +
          `Tap "Continue with ${label}" instead.`,
      });
    }

    // Real password account — send the reset for real, and only now say so.
    const redirectTo = Deno.env.get("PASSWORD_RESET_REDIRECT") ?? "seek://password-reset";
    const { error: resetErr } = await supabase.auth.resetPasswordForEmail(email, {
      redirectTo,
    });
    if (resetErr) {
      console.error("reset_send_failed", resetErr);
      return json({
        status: "send_failed",
        message: "We couldn't send the reset email just now. Please try again.",
      }, 502);
    }

    return json({
      status: "sent",
      message: "Check your email for a password reset link.",
    });
  } catch (err) {
    console.error("auth_preflight_error", err);
    try {
      await supabase.from("debug_logs").insert({
        context: "auth_preflight_error",
        payload: {
          message: err instanceof Error ? err.message : String(err),
          stack: err instanceof Error ? err.stack?.slice(0, 2000) : null,
        },
      });
    } catch (_) {}
    return json({
      status: "server_error",
      message: "Something went wrong. Please try again.",
    }, 500);
  }
});
