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

type OpenAIResponseChoice = {
  message?: {
    content?: unknown;
  };
  text?: unknown;
};

function extractTextFromResponse(result: unknown): string | null {
  if (!result || typeof result !== "object") {
    return null;
  }

  const maybeText = (result as { output_text?: unknown }).output_text;
  if (typeof maybeText === "string" && maybeText.trim().length > 0) {
    return maybeText;
  }

  const maybeChoices = (result as { choices?: unknown }).choices;
  if (Array.isArray(maybeChoices)) {
    for (const choice of maybeChoices) {
      const message = (choice as OpenAIResponseChoice).message;
      const content = message?.content;

      // Handle string content (standard chat completions format)
      if (typeof content === "string" && content.trim().length > 0) {
        return content;
      }

      // Handle array content
      if (Array.isArray(content)) {
        for (const block of content) {
          const blockText = (block as { text?: unknown }).text;
          if (typeof blockText === "string" && blockText.trim().length > 0) {
            return blockText;
          }
        }
      }
      const text = (choice as OpenAIResponseChoice).text;
      if (typeof text === "string" && text.trim().length > 0) {
        return text;
      }
    }
  }

  const outputs = (result as { output?: unknown }).output;
  if (Array.isArray(outputs)) {
    const textChunks: string[] = [];
    const jsonChunks: string[] = [];

    for (const item of outputs) {
      const content = (item as { content?: unknown }).content;
      if (!Array.isArray(content)) continue;

      for (const piece of content) {
        if (typeof piece === "string" && piece.trim().length > 0) {
          textChunks.push(piece);
          continue;
        }

        if (!piece || typeof piece !== "object") continue;
        const maybePieceText = (piece as { text?: unknown }).text;
        if (typeof maybePieceText === "string" && maybePieceText.trim().length > 0) {
          textChunks.push(maybePieceText);
          continue;
        }

        const value = (piece as Record<string, unknown>).text as {
          value?: unknown;
        } | undefined;
        if (value && typeof value.value === "string" && value.value.trim().length > 0) {
          textChunks.push(value.value);
          continue;
        }

        const jsonValue = (piece as { json?: unknown }).json;
        if (jsonValue !== undefined) {
          try {
            jsonChunks.push(typeof jsonValue === "string"
              ? jsonValue
              : JSON.stringify(jsonValue));
          } catch (_error) {
            jsonChunks.push(String(jsonValue));
          }
        }
      }
    }

    if (jsonChunks.length > 0) {
      return jsonChunks.join("\n");
    }
    if (textChunks.length > 0) {
      return textChunks.join("\n");
    }
  }

  return null;
}

function stripCodeFences(text: string): string {
  const trimmed = text.trim();
  if (!trimmed.startsWith("```")) {
    return text;
  }

  const lines = trimmed.split("\n");
  if (lines.length === 0) {
    return text;
  }

  lines.shift(); // drop opening ```... line

  const lastLine = lines[lines.length - 1];
  if (lastLine !== undefined && lastLine.trim() === "```") {
    lines.pop();
  }

  return lines.join("\n").trim();
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

  let detailText: string | undefined;
  if (details instanceof Error) {
    detailText = `${details.name}: ${details.message}`;
  } else if (typeof details === "string") {
    detailText = details;
  } else if (details) {
    try {
      detailText = JSON.stringify(details);
    } catch (_error) {
      detailText = String(details);
    }
  }

  return new Response(JSON.stringify({ error: message, details: detailText }), {
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

6. 선호/제한 사항을 반드시 준수하고, dietPreference가 'vegetarian' 또는 'vegan'이면 동물성 식재료를 제외하며, dietaryRestrictions에 포함된 재료는 사용하지 마세요.

응답은 반드시 위 구조의 JSON 문자열만 반환하세요.`;
}

async function callOpenAI(prompt: string): Promise<DietPlan> {
  const response = await fetch("https://api.openai.com/v1/chat/completions", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "Authorization": `Bearer ${OPENAI_API_KEY}`,
    },
    body: JSON.stringify({
      model: "gpt-4o-mini",
      messages: [
        {
          role: "system",
          content: "당신은 한국어로 답변하는 전문 영양사입니다. 사용자 정보를 기반으로 개인 맞춤 식단을 JSON 형식으로 제공하세요."
        },
        {
          role: "user",
          content: prompt
        }
      ],
      max_tokens: 800,
      temperature: 0.7,
    }),
  });

  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(`OpenAI request failed: ${errorText}`);
  }

  const result = await response.json();
  let text = extractTextFromResponse(result);

  if (typeof text !== "string" || text.trim().length === 0) {
    throw new Error(
      `OpenAI 응답에 텍스트가 없습니다. result=${JSON.stringify(result)}`,
    );
  }

  text = stripCodeFences(text);

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
