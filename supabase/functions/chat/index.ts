import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const CLAUDE_API_URL = "https://api.anthropic.com/v1/messages";
const CLAUDE_MODEL = "claude-sonnet-4-20250514";

const SYSTEM_PROMPT = Deno.env.get("CLAUDE_SYSTEM_PROMPT") ?? `You are a compassionate scripture companion. When a user shares what's on their heart — whether they're celebrating, grateful, hurting, seeking, or simply reflecting — respond with 3-5 Bible verses (KJV translation) that speak to their moment.

For each verse, provide:
1. The full reference (e.g., Philippians 4:6-7)
2. The complete verse text in KJV
3. A brief 1-2 sentence explanation of how this verse relates to their situation

Guidelines:
- Be warm and pastoral in tone, never preachy or judgmental
- Match the user's emotional energy — celebrate with those who celebrate, mourn with those who mourn
- Stay denominationally neutral — no specific church doctrine
- If the user's situation involves crisis (self-harm, abuse, danger), acknowledge their pain, provide comforting scripture, AND encourage them to reach out to a trusted person, counselor, or crisis helpline
- Always ground responses in scripture — don't offer personal opinions or non-biblical advice
- Keep explanations concise — this is mobile, not a seminary lecture
- Include a short prayer (2-4 sentences) that the user can pray in response
- Suggest a worship song that fits the emotional tone

Respond in this JSON format:
{
  "message": "A brief empathetic intro (1-2 sentences)",
  "verses": [
    {
      "reference": "Book Chapter:Verse",
      "text": "Full KJV verse text",
      "context": "Why this verse fits their situation"
    }
  ],
  "prayer": "A short 2-4 sentence prayer in first person",
  "worshipSong": {
    "title": "Song title",
    "artist": "Artist name",
    "context": "One sentence on why this song fits"
  },
  "followUp": "Optional — a gentle prompt for further exploration"
}`;

serve(async (req: Request) => {
  try {
    // CORS headers
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

    // Check rate limit BEFORE calling Claude
    const today = new Date().toISOString().split("T")[0];
    const { data: usage } = await supabase
      .from("usage_logs")
      .select("chat_count")
      .eq("user_id", user.id)
      .eq("log_date", today)
      .single();

    const chatCount = usage?.chat_count ?? 0;

    // Check premium status
    const { data: profile } = await supabase
      .from("profiles")
      .select("is_premium")
      .eq("id", user.id)
      .single();

    const maxChats = profile?.is_premium ? 50 : 5;

    if (chatCount >= maxChats) {
      const tomorrow = new Date();
      tomorrow.setDate(tomorrow.getDate() + 1);
      tomorrow.setHours(0, 0, 0, 0);

      return new Response(
        JSON.stringify({
          error: "daily_limit_reached",
          message: `You've used your ${maxChats} ${profile?.is_premium ? "premium" : "free"} scripture chats for today.`,
          resetsAt: tomorrow.toISOString(),
          upgradeURL: "seek://upgrade",
        }),
        { status: 429 },
      );
    }

    // Parse request
    const { message, conversationHistory } = await req.json();

    if (!message || typeof message !== "string") {
      return new Response(
        JSON.stringify({ error: "Message is required" }),
        { status: 400 },
      );
    }

    // Build Claude messages
    const messages = [
      ...(conversationHistory ?? []),
      { role: "user", content: message.slice(0, 500) },
    ];

    // Call Claude API
    const claudeApiKey = Deno.env.get("ANTHROPIC_API_KEY")!;
    const claudeResponse = await fetch(CLAUDE_API_URL, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-api-key": claudeApiKey,
        "anthropic-version": "2023-06-01",
      },
      body: JSON.stringify({
        model: CLAUDE_MODEL,
        max_tokens: 1500,
        system: SYSTEM_PROMPT,
        messages,
      }),
    });

    if (!claudeResponse.ok) {
      const errBody = await claudeResponse.text();
      console.error("Claude API error:", errBody);
      return new Response(
        JSON.stringify({
          error: "ai_error",
          message:
            "Something went wrong finding scripture for you. Please try again.",
        }),
        { status: 502 },
      );
    }

    const claudeData = await claudeResponse.json();
    const assistantMessage = claudeData.content[0]?.text;

    // Upsert usage count
    await supabase.from("usage_logs").upsert(
      {
        user_id: user.id,
        log_date: today,
        chat_count: chatCount + 1,
        last_chat_at: new Date().toISOString(),
      },
      { onConflict: "user_id,log_date" },
    );

    // Parse Claude's JSON response
    let parsed;
    try {
      parsed = JSON.parse(assistantMessage);
    } catch {
      parsed = {
        message: assistantMessage,
        verses: [],
        prayer: "",
        worshipSong: null,
      };
    }

    return new Response(
      JSON.stringify({
        ...parsed,
        remainingChats: maxChats - chatCount - 1,
      }),
      {
        headers: { "Content-Type": "application/json" },
      },
    );
  } catch (err) {
    console.error("Unexpected error:", err);
    return new Response(
      JSON.stringify({
        error: "server_error",
        message: "Something went wrong. Please try again.",
      }),
      { status: 500 },
    );
  }
});
