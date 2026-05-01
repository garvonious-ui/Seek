import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
);

const WEBHOOK_SECRET = Deno.env.get("STRIPE_WEBHOOK_SECRET") ?? "";
const RESEND_API_KEY = Deno.env.get("RESEND_API_KEY"); // optional — emails skipped if unset
const TOLERANCE_SEC = 300; // 5 min, matches Stripe's default replay window

serve(async (req: Request) => {
  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  const sigHeader = req.headers.get("stripe-signature");
  if (!sigHeader) {
    return new Response("Missing stripe-signature header", { status: 400 });
  }

  // CRITICAL: signature is computed over raw bytes. Must use text(), not json().
  const rawBody = await req.text();

  const event = await verifyAndParse(rawBody, sigHeader, WEBHOOK_SECRET);
  if (!event) {
    return new Response("Invalid signature", { status: 400 });
  }

  console.log(`Webhook ${event.type} (${event.id})`);

  try {
    if (event.type === "checkout.session.completed") {
      await handleCheckoutCompleted(event.data.object);
    } else if (event.type === "charge.refunded") {
      await handleChargeRefunded(event.data.object);
    }
    // Other event types are ignored — we only care about the donation lifecycle.
  } catch (err) {
    // Log and still return 200. Stripe retries on 5xx; that creates duplicate
    // side effects on intermittent errors. Manual replay via the dashboard is
    // safer than auto-retry for these handlers.
    console.error(
      `Handler failed for ${event.type}:`,
      err instanceof Error ? err.message : err,
    );
  }

  return new Response("OK", { status: 200 });
});

interface StripeEvent {
  id: string;
  type: string;
  data: { object: any };
}

interface CheckoutSession {
  id: string;
  payment_intent?: string | null;
  amount_total?: number | null;
  currency?: string | null;
  customer_details?: {
    email?: string | null;
    name?: string | null;
  };
}

interface Charge {
  payment_intent?: string | null;
}

/**
 * Verifies the Stripe webhook signature against the raw payload.
 * Returns the parsed event on success, null on any failure (invalid header,
 * out of tolerance, signature mismatch, malformed JSON).
 *
 * Implements Stripe's documented HMAC-SHA256 algorithm directly using Web
 * Crypto so we don't pull in the full Stripe SDK for one helper function.
 * https://stripe.com/docs/webhooks/signatures
 */
async function verifyAndParse(
  payload: string,
  header: string,
  secret: string,
): Promise<StripeEvent | null> {
  if (!secret) return null;

  // Header format: "t=timestamp,v1=signature,v1=signature,..."
  // Multiple v1 entries appear during signing-key rotation.
  const parts: Record<string, string[]> = {};
  for (const item of header.split(",")) {
    const [k, v] = item.split("=");
    if (!k || !v) continue;
    (parts[k] ??= []).push(v);
  }

  const timestamp = parts.t?.[0];
  const signatures = parts.v1;
  if (!timestamp || !signatures?.length) return null;

  // Replay protection
  const ts = parseInt(timestamp, 10);
  if (!Number.isFinite(ts)) return null;
  if (Math.abs(Date.now() / 1000 - ts) > TOLERANCE_SEC) return null;

  // HMAC-SHA256(secret, "{timestamp}.{rawBody}")
  const signedPayload = `${timestamp}.${payload}`;
  const enc = new TextEncoder();
  const key = await crypto.subtle.importKey(
    "raw",
    enc.encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const sigBuf = await crypto.subtle.sign("HMAC", key, enc.encode(signedPayload));
  const expected = Array.from(new Uint8Array(sigBuf))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");

  // Constant-time comparison — must succeed for at least one of the v1 sigs.
  if (!signatures.some((sig) => timingSafeEqual(sig, expected))) {
    return null;
  }

  try {
    return JSON.parse(payload) as StripeEvent;
  } catch {
    return null;
  }
}

function timingSafeEqual(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let result = 0;
  for (let i = 0; i < a.length; i++) {
    result |= a.charCodeAt(i) ^ b.charCodeAt(i);
  }
  return result === 0;
}

async function handleCheckoutCompleted(session: CheckoutSession) {
  // Upsert keyed on stripe_session_id so Stripe retries don't duplicate.
  const { error } = await supabase.from("donations").upsert(
    {
      stripe_session_id: session.id,
      stripe_payment_intent_id: session.payment_intent ?? null,
      amount_cents: session.amount_total ?? 0,
      currency: session.currency ?? "usd",
      donor_email: session.customer_details?.email ?? null,
      donor_name: session.customer_details?.name ?? null,
      status: "completed",
    },
    { onConflict: "stripe_session_id" },
  );
  if (error) throw new Error(`Insert failed: ${error.message}`);

  if (RESEND_API_KEY && session.customer_details?.email) {
    await sendThankYouEmail(
      session.customer_details.email,
      session.customer_details.name ?? "friend",
      (session.amount_total ?? 0) / 100,
    );
  }
}

async function handleChargeRefunded(charge: Charge) {
  if (!charge.payment_intent) return;
  const { error } = await supabase
    .from("donations")
    .update({ status: "refunded" })
    .eq("stripe_payment_intent_id", charge.payment_intent);
  if (error) throw new Error(`Refund update failed: ${error.message}`);
}

async function sendThankYouEmail(toEmail: string, name: string, amountUsd: number) {
  const formatted = amountUsd.toFixed(2);
  const res = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${RESEND_API_KEY}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      from: "Seek <hello@askseekpray.app>",
      to: toEmail,
      subject: "Thank you for supporting Seek",
      html: thankYouEmailHtml(name, formatted),
      text: thankYouEmailText(name, formatted),
    }),
  });
  if (!res.ok) {
    throw new Error(`Resend ${res.status}: ${await res.text()}`);
  }
}

function thankYouEmailHtml(name: string, amount: string): string {
  const safeName = escapeHtml(name);
  return `<!doctype html>
<html><head><meta charset="utf-8"><title>Thank you for supporting Seek</title></head>
<body style="font-family: Georgia, 'Iowan Old Style', 'Times New Roman', serif; max-width: 560px; margin: 40px auto; padding: 0 24px; color: #1A1A1A; line-height: 1.65; background: #FAFAF6;">
  <h1 style="font-weight: 400; font-size: 28px; letter-spacing: -0.01em; margin: 0 0 16px;">Thank you, ${safeName}.</h1>
  <p>Your gift of <strong>$${amount}</strong> helps keep Seek free for everyone &mdash; servers, AI, App Store fees, all of it. You&rsquo;re keeping the lights on for the next person who opens the app and asks for scripture.</p>
  <p style="margin-top: 24px; font-style: italic; color: #5B7B5E;">&ldquo;&hellip;let us not grow weary of doing good, for in due season we will reap, if we do not give up.&rdquo; &mdash; Galatians 6:9</p>
  <p style="color: #6B7280; margin-top: 32px;">&mdash; Seek</p>
  <hr style="border: 0; border-top: 1px solid #E5E7EB; margin: 32px 0;">
  <p style="font-size: 12px; color: #9CA3AF;">Donations to Seek are not tax-deductible. Your payment receipt was sent separately by Stripe.</p>
</body></html>`;
}

function thankYouEmailText(name: string, amount: string): string {
  return `Thank you, ${name}.

Your gift of $${amount} helps keep Seek free for everyone — servers, AI, App Store fees, all of it. You're keeping the lights on for the next person who opens the app and asks for scripture.

"...let us not grow weary of doing good, for in due season we will reap, if we do not give up." — Galatians 6:9

— Seek

---
Donations to Seek are not tax-deductible. Your payment receipt was sent separately by Stripe.
`;
}

function escapeHtml(s: string): string {
  return s
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}
