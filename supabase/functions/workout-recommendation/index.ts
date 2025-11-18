import "jsr:@supabase/functions-js/edge-runtime.d.ts"

const OPENAI_API_KEY = Deno.env.get("OPENAI_API_KEY")
if (!OPENAI_API_KEY) {
  console.warn("OPENAI_API_KEY env var is not set. workout-recommendation will fall back to local rules.")
}

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
}

type WorkoutRequest = {
  user?: { id?: string }
  goal?: {
    goal_type?: string
    level?: string
    weekly_days?: number
    daily_minutes?: number
  }
  preferences?: { preferred_types?: string[] }
  profile?: {
    gender?: string
    age?: number
    height_cm?: number
    weight_kg?: number
  }
  catalog?: CatalogExercise[]
  options?: {
    routine_count?: number
    min_blocks?: number
    max_blocks?: number
    language?: string
  }
}

type CatalogExercise = {
  exercise_id?: number
  name?: string
  category?: string
  description?: string
  estimated_duration_sec?: number
}

type RoutineBlock = {
  exercise_id: number
  display_name: string
  sets: number
  reps: number
  rest_seconds: number
  estimated_duration_sec: number
  notes?: string
}

type Routine = {
  id: string
  name: string
  blocks: RoutineBlock[]
  notes?: string
}

type OpenAIChoice = {
  message?: {
    content?: unknown
  }
  text?: unknown
}

const GOAL_LABELS: Record<string, string> = {
  weightloss: "체지방 감소",
  musclegain: "근력 강화",
  endurance: "지구력 향상",
  strength: "파워 업",
  general: "전신 밸런스",
}

const LEVEL_LABELS: Record<string, string> = {
  beginner: "초급",
  intermediate: "중급",
  advanced: "고급",
}

const INTENSITY_BY_LEVEL: Record<
  string,
  { sets: number; reps: number; rest: number }
> = {
  beginner: { sets: 3, reps: 12, rest: 60 },
  intermediate: { sets: 4, reps: 14, rest: 50 },
  advanced: { sets: 5, reps: 16, rest: 40 },
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders })
  }

  if (req.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405)
  }

  let payload: WorkoutRequest
  try {
    payload = await req.json()
  } catch (_error) {
    return jsonResponse({ error: "Invalid JSON body" }, 400)
  }

  try {
    const routines = await buildAiDrivenRoutines(payload)
    return jsonResponse({ routines })
  } catch (error) {
    console.error("workout-recommendation error", error)
    return jsonResponse(
      { error: "Failed to build routines", details: `${error}` },
      500,
    )
  }
})

function buildRoutines(payload: WorkoutRequest): Routine[] {
  const catalog = dedupeExercises(payload.catalog ?? [])
  if (catalog.length === 0) {
    return []
  }

  const routineCount = clamp(payload.options?.routine_count ?? 3, 1, 5)
  const minBlocks = clamp(payload.options?.min_blocks ?? 3, 1, 5)
  const maxBlocks = clamp(payload.options?.max_blocks ?? 5, minBlocks, 6)
  const language = (payload.options?.language ?? "ko").toLowerCase()

  const goalKey = (payload.goal?.goal_type ?? "general").toLowerCase()
  const levelKey = (payload.goal?.level ?? "beginner").toLowerCase()
  const preferredTypes = (payload.preferences?.preferred_types ?? []).map((p) =>
    p.toLowerCase()
  )

  const orderedExercises = prioritizeExercises(catalog, preferredTypes)
  const targetBlocks = clamp(
    Math.min(maxBlocks, orderedExercises.length || minBlocks),
    minBlocks,
    maxBlocks,
  )
  const intensity = INTENSITY_BY_LEVEL[levelKey] ?? INTENSITY_BY_LEVEL.beginner

  const routines: Routine[] = []
  for (let i = 0; i < routineCount; i++) {
    const blocks: RoutineBlock[] = []
    for (let b = 0; b < targetBlocks; b++) {
      const exercise = orderedExercises[(i + b) % orderedExercises.length]
      blocks.push(
        createBlock({
          exercise,
          intensity,
          goalKey,
          blockIndex: b,
          routineIndex: i,
        }),
      )
    }

    routines.push({
      id: `edge_${goalKey}_${levelKey}_${i}_${Date.now()}`,
      name: buildRoutineName(goalKey, levelKey, i, language),
      blocks,
      notes: buildRoutineNotes(goalKey, preferredTypes),
    })
  }

  return routines
}

async function buildAiDrivenRoutines(payload: WorkoutRequest): Promise<Routine[]> {
  if (!OPENAI_API_KEY) {
    return buildRoutines(payload)
  }

  try {
    const aiRoutines = await generateRoutinesWithOpenAI(payload)
    if (aiRoutines.length > 0) {
      return aiRoutines
    }
    console.warn("OpenAI returned no routines. Falling back to local builder.")
  } catch (error) {
    console.error("OpenAI routine generation failed", error)
  }

  return buildRoutines(payload)
}

async function generateRoutinesWithOpenAI(payload: WorkoutRequest): Promise<Routine[]> {
  if (!OPENAI_API_KEY) return []

  const catalog = dedupeExercises(payload.catalog ?? [])
  if (catalog.length === 0) {
    return []
  }

  const prompt = buildOpenAiPrompt(payload, catalog)
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
          content: "당신은 한국어 트레이너입니다. 사용자 정보를 참고해 개인 맞춤 운동 루틴을 JSON으로 생성하세요."
        },
        {
          role: "user",
          content: prompt
        }
      ],
      max_tokens: 900,
      temperature: 0.7,
    }),
  })

  if (!response.ok) {
    const errorText = await response.text()
    throw new Error(`OpenAI request failed: ${errorText}`)
  }

  const result = await response.json()
  let text = extractTextFromResponse(result)
  if (!text || text.trim().length === 0) {
    throw new Error("OpenAI response did not include text")
  }
  text = stripCodeFences(text)

  let parsed: unknown
  try {
    parsed = JSON.parse(text)
  } catch (_error) {
    throw new Error("OpenAI response was not valid JSON")
  }

  const normalized = normalizeAiRoutineResponse(parsed, catalog)
  return normalized
}

function buildOpenAiPrompt(payload: WorkoutRequest, catalog: CatalogExercise[]): string {
  const trimmedCatalog = catalog.slice(0, 30)
  const formattedPayload = {
    goal: payload.goal ?? null,
    preferences: payload.preferences ?? null,
    profile: payload.profile ?? null,
    options: payload.options ?? null,
    catalog: trimmedCatalog,
  }

  return `당신은 한국어 트레이너입니다. 아래 사용자 정보를 참고해 개인 맞춤 운동 루틴을 JSON으로 생성하세요.

요구 사항:
1. routines 배열을 반환하세요 (최대 ${payload.options?.routine_count ?? 3}개).
2. 각 루틴은 id(string), name(string), notes(string)와 blocks 배열을 포함합니다.
3. blocks 배열의 원소는 catalog.exercise_id 값을 참조하는 숫자 exercise_id, display_name, sets, reps, rest_seconds, estimated_duration_sec, notes를 포함합니다.
4. 세트/횟수는 사용자의 목표(goal_type)와 레벨(level)에 맞춰 합리적으로 설정하세요.
5. catalog에 존재하지 않는 운동은 사용하지 마세요.

반드시 아래 JSON 스키마와 동일한 키/자료형을 지켜 출력하세요.
{
  "routines": [
    {
      "id": "string",
      "name": "string",
      "notes": "string",
      "blocks": [
        {
          "exercise_id": 123,
          "display_name": "스쿼트 변형",
          "sets": 4,
          "reps": 12,
          "rest_seconds": 45,
          "estimated_duration_sec": 180,
          "notes": "운동 팁"
        }
      ]
    }
  ]
}

사용자 입력:
${JSON.stringify(formattedPayload, null, 2)}`
}

function dedupeExercises(exercises: CatalogExercise[]): CatalogExercise[] {
  const seen = new Set<number>()
  const result: CatalogExercise[] = []
  for (const exercise of exercises) {
    if (
      typeof exercise.exercise_id !== "number" ||
      !exercise.name ||
      seen.has(exercise.exercise_id)
    ) {
      continue
    }
    seen.add(exercise.exercise_id)
    result.push(exercise)
  }
  return result
}

function prioritizeExercises(
  catalog: CatalogExercise[],
  preferredTypes: string[],
): CatalogExercise[] {
  if (preferredTypes.length === 0) {
    return catalog
  }

  const preferred: CatalogExercise[] = []
  const others: CatalogExercise[] = []

  for (const exercise of catalog) {
    const category = exercise.category?.toLowerCase() ?? ""
    const name = exercise.name?.toLowerCase() ?? ""
    const matches = preferredTypes.some((pref) =>
      category.includes(pref) || name.includes(pref)
    )
    if (matches) {
      preferred.push(exercise)
    } else {
      others.push(exercise)
    }
  }

  return preferred.length > 0 ? [...preferred, ...others] : catalog
}

function createBlock(params: {
  exercise: CatalogExercise
  intensity: { sets: number; reps: number; rest: number }
  goalKey: string
  blockIndex: number
  routineIndex: number
}): RoutineBlock {
  const { exercise, intensity, goalKey, blockIndex, routineIndex } = params
  const variation = routineIndex + blockIndex
  const sets = Math.max(2, intensity.sets + Math.floor(variation / 2))
  const reps = Math.max(8, intensity.reps - blockIndex + (goalKey === "strength" ? -2 : 0))
  const restSeconds = Math.max(30, intensity.rest - variation * 5)
  const estimatedDuration = exercise.estimated_duration_sec ??
    sets * reps * 4

  return {
    exercise_id: exercise.exercise_id!,
    display_name: exercise.name ?? `운동 ${exercise.exercise_id}`,
    sets,
    reps,
    rest_seconds: restSeconds,
    estimated_duration_sec: estimatedDuration,
    notes: buildBlockNotes(goalKey, exercise),
  }
}

function buildRoutineName(
  goalKey: string,
  levelKey: string,
  index: number,
  language: string,
): string {
  const goalLabel = GOAL_LABELS[goalKey] ?? GOAL_LABELS.general
  const levelLabel = LEVEL_LABELS[levelKey] ?? LEVEL_LABELS.beginner
  if (language === "en") {
    return `AI ${goalLabel} Routine ${index + 1} (${levelLabel})`
  }
  return `AI ${goalLabel} 루틴 ${index + 1} (${levelLabel})`
}

function buildRoutineNotes(goalKey: string, preferences: string[]): string {
  const base = {
    weightloss: "심박을 높이고 칼로리를 소모하는 구성입니다.",
    musclegain: "근비대를 위한 세트/횟수를 중심으로 구성했어요.",
    endurance: "지구력을 기르는 데 집중한 루틴입니다.",
    strength: "고강도 파워 출력을 목표로 합니다.",
    general: "전신 밸런스를 맞추는 기본 루틴입니다.",
  }[goalKey] ?? GOAL_LABELS.general

  if (preferences.length > 0) {
    return `${base} 선호 운동 유형(${preferences.join(", ")})을 우선 반영했어요.`
  }
  return base
}

function buildBlockNotes(goalKey: string, exercise: CatalogExercise): string {
  const name = exercise.name ?? "동작"
  switch (goalKey) {
    case "weightloss":
      return `${name} 동작에서 템포를 유지하며 심박을 높여보세요.`
    case "musclegain":
      return `${name} 시 마지막 2회는 근육에 타는 느낌이 오도록 집중하세요.`
    case "endurance":
      return `${name} 을 할 때 호흡을 일정하게 유지해 주세요.`
    case "strength":
      return `${name} 시 폭발적인 힘을 사용하되, 충분한 휴식을 취하세요.`
    default:
      return `${name} 자세를 안정적으로 유지하며 수행해 주세요.`
  }
}

function clamp(value: number, min: number, max: number): number {
  return Math.max(min, Math.min(max, value))
}

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "Content-Type": "application/json",
      ...corsHeaders,
    },
  })
}

function normalizeAiRoutineResponse(data: unknown, catalog: CatalogExercise[]): Routine[] {
  if (!data || typeof data !== "object") return []
  const routines = (data as { routines?: unknown }).routines
  if (!Array.isArray(routines)) return []

  const catalogMap = new Map<number, CatalogExercise>()
  for (const exercise of catalog) {
    if (typeof exercise.exercise_id === "number") {
      catalogMap.set(exercise.exercise_id, exercise)
    }
  }

  const normalized: Routine[] = []
  for (const routine of routines) {
    if (!routine || typeof routine !== "object") continue
    const blocks = Array.isArray((routine as { blocks?: unknown }).blocks)
      ? (routine as { blocks: unknown[] }).blocks
      : []

    const normalizedBlocks: RoutineBlock[] = []
    for (const block of blocks) {
      if (!block || typeof block !== "object") continue
      const exerciseIdRaw = (block as { exercise_id?: unknown }).exercise_id
      const exerciseId = typeof exerciseIdRaw === "number"
        ? exerciseIdRaw
        : Number(exerciseIdRaw)
      if (!Number.isFinite(exerciseId) || !catalogMap.has(exerciseId)) {
        continue
      }

      const reference = catalogMap.get(exerciseId)
      const sets = sanitizeInteger((block as { sets?: unknown }).sets, 1, 8, 3)
      const reps = sanitizeInteger((block as { reps?: unknown }).reps, 6, 30, 12)
      const restSeconds = sanitizeInteger(
        (block as { rest_seconds?: unknown }).rest_seconds,
        20,
        180,
        60,
      )
      const estimatedDuration = sanitizeInteger(
        (block as { estimated_duration_sec?: unknown }).estimated_duration_sec,
        60,
        1200,
        reference?.estimated_duration_sec ?? sets * reps * 4,
      )

      normalizedBlocks.push({
        exercise_id: exerciseId,
        display_name: String(
          (block as { display_name?: unknown }).display_name ??
            reference?.name ??
            `운동 ${exerciseId}`,
        ),
        sets,
        reps,
        rest_seconds: restSeconds,
        estimated_duration_sec: estimatedDuration,
        notes: typeof (block as { notes?: unknown }).notes === "string"
          ? (block as { notes?: string }).notes
          : undefined,
      })
    }

    if (normalizedBlocks.length === 0) {
      continue
    }

    normalized.push({
      id: String((routine as { id?: unknown }).id ?? `openai_${crypto.randomUUID()}`),
      name: String((routine as { name?: unknown }).name ?? "AI 루틴"),
      notes: typeof (routine as { notes?: unknown }).notes === "string"
        ? (routine as { notes?: string }).notes
        : undefined,
      blocks: normalizedBlocks,
    })
  }

  return normalized
}

function sanitizeInteger(
  value: unknown,
  min: number,
  max: number,
  fallback: number,
): number {
  const num = typeof value === "number" ? value : Number(value)
  if (Number.isFinite(num)) {
    return clamp(Math.round(num), min, max)
  }
  return clamp(fallback, min, max)
}

function extractTextFromResponse(result: unknown): string | null {
  if (!result || typeof result !== "object") {
    return null
  }

  const outputText = (result as { output_text?: unknown }).output_text
  if (typeof outputText === "string" && outputText.trim().length > 0) {
    return outputText
  }

  const choices = (result as { choices?: unknown }).choices
  if (Array.isArray(choices)) {
    for (const choice of choices) {
      const message = (choice as OpenAIChoice).message
      const content = message?.content

      // Handle string content (standard chat completions format)
      if (typeof content === "string" && content.trim().length > 0) {
        return content
      }

      // Handle array content
      if (Array.isArray(content)) {
        for (const block of content) {
          const text = (block as { text?: unknown }).text
          if (typeof text === "string" && text.trim().length > 0) {
            return text
          }
        }
      }
      const text = (choice as OpenAIChoice).text
      if (typeof text === "string" && text.trim().length > 0) {
        return text
      }
    }
  }

  const outputs = (result as { output?: unknown }).output
  if (Array.isArray(outputs)) {
    const chunks: string[] = []
    for (const item of outputs) {
      const content = (item as { content?: unknown }).content
      if (!Array.isArray(content)) continue
      for (const piece of content) {
        if (typeof piece === "string" && piece.trim().length > 0) {
          chunks.push(piece)
        } else if (
          piece &&
          typeof piece === "object" &&
          typeof (piece as { text?: unknown }).text === "string"
        ) {
          chunks.push((piece as { text: string }).text)
        }
      }
    }
    if (chunks.length > 0) {
      return chunks.join("\n")
    }
  }

  return null
}

function stripCodeFences(text: string): string {
  const trimmed = text.trim()
  if (!trimmed.startsWith("```")) {
    return text
  }

  const lines = trimmed.split("\n")
  if (lines.length === 0) {
    return text
  }

  lines.shift()
  const lastLine = lines[lines.length - 1]
  if (lastLine !== undefined && lastLine.trim() === "```") {
    lines.pop()
  }

  return lines.join("\n").trim()
}
