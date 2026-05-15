import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const CLAUDE_API_URL = "https://api.anthropic.com/v1/messages";
// Primary: latest Sonnet (Sonnet 4.6). Fallback: Sonnet 4.5 — same family,
// same price, listed under "Legacy models" but still supported. The previous
// fallback ID `claude-sonnet-4-5-20241022` was a hallucination — that exact
// date string never existed and the fallback would have 4xx'd if it ever
// fired. Always cross-check against docs.anthropic.com before pinning.
const CLAUDE_MODEL = "claude-sonnet-4-6";
const CLAUDE_MODEL_FALLBACK = "claude-sonnet-4-5-20250929";

function buildSystemPrompt(translation: string): string {
  const t = ["KJV", "NLT"].includes(translation) ? translation : "NLT";
  return `You are a compassionate scripture companion. When a user shares what's on their heart — whether they're celebrating, grateful, hurting, seeking, or simply reflecting — respond with 3-5 Bible verses (${t} translation) that speak to their moment.

For each verse, provide:
1. The full reference (e.g., Philippians 4:6-7)
2. The complete verse text in ${t}
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
      "text": "Full verse text in the requested translation",
      "context": "Why this verse fits their situation"
    }
  ],
  "prayer": "A short 2-4 sentence prayer in first person",
  "worshipSong": {
    "title": "Song title",
    "artist": "Artist name",
    "context": "One sentence on why this song fits"
  },
  "followUp": "Optional — a gentle prompt for further exploration",
  "action": {
    "title": "A short action title like 'Release + Move' or 'Express It'",
    "steps": ["Step 1", "Step 2", "Step 3"],
    "reason": "One sentence on why this action helps"
  }
}

Also include a practical "action" — a real-world step the user can take right now based on their emotional state. Examples:
- Anxiety → "Release + Move": Take a 10-minute walk without your phone, Speak your worries out loud to God, Write down what you can control vs. what you can't
- Gratitude → "Express It": Tell someone "thank you" directly, Write down 3 blessings, Give generously (time or resource)
- Grief → "Sit + Remember": Light a candle and sit in silence for 5 minutes, Write a letter to who you're missing, Call someone who knew them too
- Celebration → "Share the Joy": Text someone the good news, Do something kind for a stranger, Dance or sing — literally
- Depression → "One Small Step": Get outside for 5 minutes, Text one person you trust, Do one act of service for someone else

The action should feel doable, not overwhelming. 2-3 concrete steps. Match the user's energy.

IMPORTANT: Return ONLY the raw JSON object. Do NOT wrap it in markdown code fences or any other formatting. Just the raw JSON.`;
}

const SYSTEM_PROMPT = buildSystemPrompt("NLT");

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

    // Get user's timezone and premium status
    const { data: notifSettings } = await supabase
      .from("notification_settings")
      .select("timezone")
      .eq("id", user.id)
      .single();

    const { data: profile } = await supabase
      .from("profiles")
      .select("is_premium")
      .eq("id", user.id)
      .single();

    // Compute "today" in the user's local timezone (not UTC)
    const userTz = notifSettings?.timezone ?? "America/New_York";
    const today = new Date().toLocaleDateString("en-CA", { timeZone: userTz }); // "YYYY-MM-DD"

    // Check rate limit BEFORE calling Claude
    const { data: usage } = await supabase
      .from("usage_logs")
      .select("chat_count")
      .eq("user_id", user.id)
      .eq("log_date", today)
      .single();

    const chatCount = usage?.chat_count ?? 0;

    const maxChats = 50;

    if (chatCount >= maxChats) {
      const tomorrow = new Date();
      tomorrow.setDate(tomorrow.getDate() + 1);
      tomorrow.setHours(0, 0, 0, 0);

      return new Response(
        JSON.stringify({
          error: "daily_limit_reached",
          message: `You've used your ${maxChats} scripture chats for today.`,
          resetsAt: tomorrow.toISOString(),
        }),
        { status: 429 },
      );
    }

    // Parse request
    const { message, conversationHistory, translation } = await req.json();

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

    // Call Claude API with automatic fallback on model errors
    const claudeApiKey = Deno.env.get("ANTHROPIC_API_KEY")!;
    const systemPrompt = buildSystemPrompt(translation ?? "NLT");

    async function callClaude(model: string) {
      return fetch(CLAUDE_API_URL, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "x-api-key": claudeApiKey,
          "anthropic-version": "2023-06-01",
        },
        body: JSON.stringify({
          model,
          max_tokens: 3000,
          system: systemPrompt,
          messages,
        }),
      });
    }

    // Retry transient 5xx + 429 with exponential backoff. Build 9 was
    // rejected by App Review because Anthropic returned brief 5xx errors
    // during their test window; the function passed those straight through
    // as 502s. Three short retries with backoff (500ms, 1.2s, 2.5s) absorb
    // most transient blips. 4xx errors (model not found, bad request,
    // billing) are not retried — they're not transient.
    async function callClaudeWithRetry(model: string): Promise<Response> {
      const delays = [500, 1200, 2500];
      let resp = await callClaude(model);
      for (const delay of delays) {
        if (resp.ok) return resp;
        if (resp.status >= 400 && resp.status < 500 && resp.status !== 429) return resp;
        await new Promise((r) => setTimeout(r, delay));
        resp = await callClaude(model);
      }
      return resp;
    }

    let claudeResponse = await callClaudeWithRetry(CLAUDE_MODEL);
    let primaryStatus = claudeResponse.status;
    let primaryErr = "";
    let fallbackStatus = 0;
    let fallbackErr = "";

    // If primary model fails, capture the error and try fallback
    if (!claudeResponse.ok) {
      primaryErr = await claudeResponse.text();
      console.error(`Claude API error (${CLAUDE_MODEL}, status ${primaryStatus}):`, primaryErr);

      // Retry with fallback model on 4xx errors (not rate limits) — also
      // uses the same backoff retry loop in case the fallback model has
      // its own transient blips.
      if (claudeResponse.status !== 429) {
        console.log(`Retrying with fallback model: ${CLAUDE_MODEL_FALLBACK}`);
        claudeResponse = await callClaudeWithRetry(CLAUDE_MODEL_FALLBACK);
        fallbackStatus = claudeResponse.status;
      }

      if (!claudeResponse.ok) {
        fallbackErr = await claudeResponse.text();
        console.error(`Claude API fallback error (status ${fallbackStatus}):`, fallbackErr);

        // Persist the error so we can read it via SQL — the basic edge-function
        // logs only show HTTP status, not function stdout. Remove this debug
        // sink once the root cause is fixed.
        await supabase.from("debug_logs").insert({
          context: "chat_anthropic_error",
          payload: {
            user_id: user.id,
            message_preview: message.slice(0, 200),
            history_length: (conversationHistory ?? []).length,
            primaryModel: CLAUDE_MODEL,
            primaryStatus,
            primaryError: primaryErr.slice(0, 1500),
            fallbackModel: fallbackStatus > 0 ? CLAUDE_MODEL_FALLBACK : null,
            fallbackStatus: fallbackStatus || null,
            fallbackError: fallbackErr.slice(0, 1500),
          },
        });

        return new Response(
          JSON.stringify({
            error: "ai_error",
            message:
              "Something went wrong finding scripture for you. Please try again.",
            debug: {
              primaryModel: CLAUDE_MODEL,
              primaryStatus,
              primaryError: primaryErr.slice(0, 500),
              fallbackModel: fallbackStatus > 0 ? CLAUDE_MODEL_FALLBACK : null,
              fallbackStatus: fallbackStatus || null,
              fallbackError: fallbackErr.slice(0, 500),
            },
          }),
          { status: 502 },
        );
      }
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

    // Parse Claude's JSON response — strip markdown fences if present
    let cleanedMessage = assistantMessage.trim();
    // Strip any markdown code fences (```json ... ```, ``` ... ```, or multiple backtick styles)
    cleanedMessage = cleanedMessage.replace(/^```\w*\s*\n?/, "").replace(/\n?\s*```\s*$/, "");
    // If still not starting with {, try to extract JSON object
    if (!cleanedMessage.startsWith("{")) {
      const jsonStart = cleanedMessage.indexOf("{");
      if (jsonStart !== -1) {
        cleanedMessage = cleanedMessage.slice(jsonStart);
      }
    }

    let parsed;
    try {
      parsed = JSON.parse(cleanedMessage);
    } catch {
      // JSON parse failed (likely truncated response) — try to salvage partial JSON
      // by closing any open structures
      let salvaged = cleanedMessage;
      // Count open braces/brackets to close them
      const openBraces = (salvaged.match(/{/g) || []).length - (salvaged.match(/}/g) || []).length;
      const openBrackets = (salvaged.match(/\[/g) || []).length - (salvaged.match(/]/g) || []).length;
      // Trim trailing incomplete values (partial strings, etc.)
      salvaged = salvaged.replace(/,\s*"[^"]*$/, "");
      salvaged = salvaged.replace(/,\s*$/, "");
      for (let i = 0; i < openBrackets; i++) salvaged += "]";
      for (let i = 0; i < openBraces; i++) salvaged += "}";
      try {
        parsed = JSON.parse(salvaged);
      } catch {
        parsed = {
          message: assistantMessage,
          verses: [],
          prayer: "",
          worshipSong: null,
        };
      }
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
    // Best-effort write to debug_logs so we can see the unexpected error
    // without relying on stdout. Wrapped in try because supabase client may
    // not be initialized if the catch fires before the client is created.
    try {
      const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
      const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
      const supabase = createClient(supabaseUrl, supabaseServiceKey);
      await supabase.from("debug_logs").insert({
        context: "chat_unexpected_error",
        payload: {
          message: err instanceof Error ? err.message : String(err),
          stack: err instanceof Error ? err.stack?.slice(0, 2000) : null,
          name: err instanceof Error ? err.name : null,
        },
      });
    } catch (_inner) {}
    return new Response(
      JSON.stringify({
        error: "server_error",
        message: "Something went wrong. Please try again.",
      }),
      { status: 500 },
    );
  }
});
