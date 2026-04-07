import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

serve(async (req: Request) => {
  try {
    if (req.method === "OPTIONS") {
      return new Response(null, {
        headers: {
          "Access-Control-Allow-Origin": "*",
          "Access-Control-Allow-Methods": "POST, OPTIONS",
          "Access-Control-Allow-Headers": "authorization, content-type",
        },
      });
    }

    // Validate auth
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "Missing authorization" }), {
        status: 401,
      });
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // Verify JWT and get user
    const token = authHeader.replace("Bearer ", "");
    const {
      data: { user },
      error: authError,
    } = await supabase.auth.getUser(token);
    if (authError || !user) {
      return new Response(JSON.stringify({ error: "Invalid token" }), {
        status: 401,
      });
    }

    const { receiptData } = await req.json();

    if (!receiptData) {
      return new Response(
        JSON.stringify({ error: "Receipt data is required" }),
        { status: 400 },
      );
    }

    // TODO: Implement App Store Server API v2 verification
    // 1. Decode the receipt
    // 2. Verify with Apple's App Store Server API
    // 3. Check subscription status and expiry

    const isPremium = false; // TODO: Set based on receipt verification
    const expiresAt = null; // TODO: Set based on subscription expiry

    await supabase
      .from("profiles")
      .update({
        is_premium: isPremium,
        premium_expires_at: expiresAt,
      })
      .eq("id", user.id);

    return new Response(
      JSON.stringify({
        isPremium,
        expiresAt,
      }),
      { headers: { "Content-Type": "application/json" } },
    );
  } catch (err) {
    console.error("Unexpected error:", err);
    return new Response(
      JSON.stringify({
        error: "server_error",
        message: "Something went wrong.",
      }),
      { status: 500 },
    );
  }
});
