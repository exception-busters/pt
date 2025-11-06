// Follow this setup guide to integrate the Deno language server with your editor:
// https://deno.land/manual/getting_started/setup_your_environment
// This enables autocomplete, go to definition, etc.
// Setup type definitions for built-in Supabase Runtime APIs
import "jsr:@supabase/functions-js/edge-runtime.d.ts";

import { createClient } from "@supabase/supabase-js";

const OPENAI_API_KEY = Deno.env.get("OPENAI_API_KEY");
const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY");

if (!OPENAI_API_KEY) {
  console.warn("OPENAI_API_KEY env var is not set. diet-recommendation function will fail.");
}
if (!SUPABASE_URL || !SUPABASE_ANON_KEY) {
  console.warn("Supabase URL / anon key env vars are missing.");
}

type DietProfilePayload = {
  profile?: Record<string, unknown>;
  dietGoal?: Record<string, unknown>;
  preferences?: Record<string, unknown>;
};

interface DietPlan {
  plan: unknown;
  rawText: string;
  isStructured: boolean;
}

function unauthorized(body: string | Record<string, unknown>) {
  return new Response(
    typeof body === "string" ? body : JSON.stringify(body),
    {
      status: 401,
      headers: { "Content-Type": "application/json" },
    },
  );
}

function badRequest(message: string) {
  return new Response(JSON.stringify({ error: message }), {
    status: 400,
    headers: { "Content-Type": "application/json" },
  });
}

function serverError(message: string, details?: unknown) {
  console.error(message, details);
  return new Response(JSON.stringify({ error: message }), {
    status: 500,
    headers: { "Content-Type": "application/json" },
  });
}

function buildPrompt(payload: DietProfilePayload) {
  const profile = JSON.stringify(payload.profile ?? {}, null, 2);
  const dietGoal = JSON.stringify(payload.dietGoal ?? {}, null, 2);
  const preferences = JSON.stringify(payload.preferences ?? {}, null, 2);

  return `다음은 개인 맞춤 식단 추천을 위한 사용자 정보입니다.

[사용자 프로필]
${profile}

[식단 목표]
${dietGoal}

[선호/제한 사항]
${preferences}

요구 사항:
1. 아침, 점심, 저녁 3끼 식단을 각각 JSON 배열로 제공하세요.
2. 각 끼니에는 음식 이름, 1인분(g), 단백질/탄수화물/지방(g), 열량(kcal)의 키를 포함하세요.
3. 한국 가정식 또는 쉽게 구할 수 있는 재료 위주로 제안해주세요.
4. 총 열량과 각 끼니의 요약 설명을 함께 포함하세요.
5. JSON 최상위 구조는 아래 예시를 따르세요.

{
  "totalCalories": 1900,
  "summary": "하루 총열량, 목표 대비 설명 등",
  "meals": [
    {
      "label": "아침",
      "items": [
        { "food": "현미밥", "grams": 150, "protein": 4, "carbs": 30, "fat": 1, "calories": 170 },
        ...
      ],
      "notes": "한 줄 설명 또는 팁"
    },
    ...
  ]
}

응답은 반드시 위 구조의 JSON 문자열만 반환하세요.`;
}

async function callOpenAI(prompt: string): Promise<DietPlan> {
  const response = await fetch("https://api.openai.com/v1/responses", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "Authorization": `Bearer ${OPENAI_API_KEY}`,
    },
    body: JSON.stringify({
      model: "gpt-4.1-mini",
      input: prompt,
      max_output_tokens: 800,
    }),
  });

  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(`OpenAI request failed: ${errorText}`);
  }

  const result = await response.json();
  const text: unknown = result?.output_text ??
    result?.choices?.[0]?.message?.content?.[0]?.text ??
    "";

  if (typeof text !== "string" || text.trim().length === 0) {
    throw new Error("OpenAI 응답에 텍스트가 없습니다.");
  }

  let parsed: unknown = null;
  try {
    parsed = JSON.parse(text);
  } catch (_error) {
    return {
      plan: text,
      rawText: text,
      isStructured: false,
    };
  }

  return {
    plan: parsed,
    rawText: text,
    isStructured: true,
  };
}

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  if (!OPENAI_API_KEY) {
    return serverError("OPENAI_API_KEY is not configured");
  }

  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return unauthorized({ error: "Missing Authorization header" });
  }

  if (!SUPABASE_URL || !SUPABASE_ANON_KEY) {
    return serverError("Supabase configuration is missing");
  }

  const supabase = createClient(
    SUPABASE_URL,
    SUPABASE_ANON_KEY,
    {
      global: {
        headers: { Authorization: authHeader },
      },
    },
  );

  const { data: { user }, error } = await supabase.auth.getUser();
  if (error || !user) {
    return unauthorized({ error: "Invalid or expired token" });
  }

  let payload: DietProfilePayload;
  try {
    payload = await req.json();
  } catch (_error) {
    return badRequest("Request body must be valid JSON.");
  }

  try {
    const prompt = buildPrompt(payload);
    const dietPlan = await callOpenAI(prompt);

    const body = {
      userId: user.id,
      plan: dietPlan.plan,
      rawText: dietPlan.rawText,
      isStructured: dietPlan.isStructured,
    };

    return new Response(JSON.stringify(body), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  } catch (err) {
    return serverError("Failed to generate diet recommendation", err);
  }
});
