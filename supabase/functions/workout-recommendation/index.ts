import "jsr:@supabase/functions-js/edge-runtime.d.ts"

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
    const routines = buildRoutines(payload)
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
