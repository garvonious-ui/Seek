import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

serve(async (req: Request) => {
  try {
    if (req.method === "OPTIONS") {
      return new Response(null, {
        headers: {
          "Access-Control-Allow-Origin": "*",
          "Access-Control-Allow-Methods": "GET, OPTIONS",
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

    // Verify JWT
    const token = authHeader.replace("Bearer ", "");
    const { error: authError } = await supabase.auth.getUser(token);
    if (authError) {
      return new Response(JSON.stringify({ error: "Invalid token" }), {
        status: 401,
      });
    }

    // Get a daily verse that hasn't been used recently (within 90 days)
    const ninetyDaysAgo = new Date();
    ninetyDaysAgo.setDate(ninetyDaysAgo.getDate() - 90);

    const { data: verse, error } = await supabase
      .from("daily_verses")
      .select("*")
      .or(
        `last_used_date.is.null,last_used_date.lt.${ninetyDaysAgo.toISOString().split("T")[0]}`,
      )
      .limit(1)
      .single();

    if (error || !verse) {
      // Fallback: get the least recently used verse
      const { data: fallback } = await supabase
        .from("daily_verses")
        .select("*")
        .order("last_used_date", { ascending: true, nullsFirst: true })
        .limit(1)
        .single();

      if (!fallback) {
        return new Response(
          JSON.stringify({ error: "No daily verses available" }),
          { status: 404 },
        );
      }

      await supabase
        .from("daily_verses")
        .update({ last_used_date: new Date().toISOString().split("T")[0] })
        .eq("id", fallback.id);

      return new Response(
        JSON.stringify({
          reference: fallback.reference,
          text: fallback.text,
          theme: fallback.theme,
        }),
        { headers: { "Content-Type": "application/json" } },
      );
    }

    await supabase
      .from("daily_verses")
      .update({ last_used_date: new Date().toISOString().split("T")[0] })
      .eq("id", verse.id);

    return new Response(
      JSON.stringify({
        reference: verse.reference,
        text: verse.text,
        theme: verse.theme,
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
