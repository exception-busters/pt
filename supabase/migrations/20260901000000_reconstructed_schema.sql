-- ============================================================================
-- 재구성된 스키마 (Supabase 프로젝트 wkmnnzndtggrlrzjlncn 유실 후 복구용)
-- 작성일: 2026-09-01
--
-- 실제 코드(lib/**)에서 현재 활발히 select/insert/update 하는 테이블만 포함.
-- 어떤 코드 경로에서도 쓰기(write)가 일어나지 않는 죽은 테이블(usermeal)과,
-- users 테이블 내에서 더 이상 읽거나 쓰지 않는 레거시 컬럼(gender/age/weight/
-- height/workout_goal/workout_level/onboarding_completed/updated_at — 지금은
-- userprofile/exercisegoal/dietgoal 테이블로 이관되어 있음)은 제외했습니다.
--
-- 이 파일은 실제 프로덕션 DB에서 덤프한 것이 아니라, 코드베이스를 역공학해서
-- 재구성한 것입니다. 아래 신뢰도 표기를 반드시 참고하세요.
--
--   [확정]   앱 코드가 최근까지 실제로 select/insert/update 하는 컬럼 —
--            신뢰도 높음. 타입은 값의 쓰임(문자열/정수/불리언/배열 등)으로 추론.
--   [추정]   과거 SQL 마이그레이션 문서에는 있으나 현재 코드에서 더 이상
--            직접 참조되지 않는 컬럼/제약. 실제 운영 DB에 남아있었을 가능성은
--            있지만 확인 불가.
--   [불명]   존재 여부/정확한 타입·길이·기본값을 코드만으로는 알 수 없음.
--
-- 코드만으로는 복구 불가능한 것들 (이 파일에 포함되지 않음):
--   - 실제 row 데이터 전부 (auth.users 계정, 운동/식단 기록 등)
--   - 정확한 VARCHAR 길이, NUMERIC precision/scale
--   - 각 테이블의 실제 RLS 정책 (아래는 코드 패턴에서 추론한 합리적 기본값이며
--     원본 정책과 다를 수 있음)
--   - Storage 버킷, Auth 이메일 템플릿, 커스텀 Auth 훅
--   - 시퀀스 현재값 (BIGSERIAL 등은 1부터 다시 시작)
--
-- ============================================================================


-- ----------------------------------------------------------------------------
-- 1. public.users  [확정: user_id, email, nickname, join_date, profile_completed]
--    (supabase_service.dart getUserInfo/isProfileCompleted/createUser select 목록,
--    user_model.dart 와 정확히 일치)
--    profile_image는 onboarding_service.dart 주석("users 테이블에는 email, nickname,
--    profile_image만 있음")과 user_model.dart 양쪽에서 확인되어 포함.
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.users (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email VARCHAR(255) NOT NULL,
    nickname VARCHAR(50) NOT NULL DEFAULT '사용자',
    profile_image TEXT,
    profile_completed BOOLEAN DEFAULT FALSE,
    join_date TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_users_email ON public.users(email);

ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can view own profile" ON public.users;
CREATE POLICY "Users can view own profile" ON public.users
  FOR SELECT USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can update own profile" ON public.users;
CREATE POLICY "Users can update own profile" ON public.users
  FOR UPDATE USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON public.users;
CREATE POLICY "Enable insert for authenticated users only" ON public.users
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- auth.users 가입 시 public.users 자동 생성 트리거 [확정: supabase_user_sync_trigger.sql]
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.users WHERE user_id = NEW.id) THEN
    INSERT INTO public.users (user_id, email, nickname, join_date)
    VALUES (NEW.id, NEW.email, COALESCE(NEW.raw_user_meta_data->>'display_name', '사용자'), NOW());
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();


-- ----------------------------------------------------------------------------
-- 2. public.userprofile  [확정: user_id, gender, age, height, weight]
--    (profile_data_service.dart, diet_profile_repository.dart)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.userprofile (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    gender VARCHAR(10),
    age INTEGER,
    height DOUBLE PRECISION,
    weight DOUBLE PRECISION,
    created_at TIMESTAMP DEFAULT NOW(),           -- [불명] 존재 추정
    updated_at TIMESTAMP DEFAULT NOW()             -- [불명] 존재 추정
);

ALTER TABLE public.userprofile ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users manage own userprofile" ON public.userprofile
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);


-- ----------------------------------------------------------------------------
-- 3. public.exercisegoal (a.k.a legacy public.workoutgoal)
--    [확정 컬럼: user_id, goal_type, level, experience_duration, weekly_days,
--     daily_duration_min, preferred_types]
--    코드가 'exercisegoal'을 먼저 시도하고 없으면 'workoutgoal'로 폴백함
--    (profile_data_service.dart _workoutGoalTableCandidates) —
--    즉 실제 운영 DB의 테이블명은 exercisegoal 이었을 가능성이 높음.
--    experience_duration 컬럼은 옛 create_profile_goals_tables.sql에는 없고
--    코드(WorkoutGoalModel)에만 있어 나중에 추가된 것으로 보임.
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.exercisegoal (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    goal_type VARCHAR(50) CHECK (goal_type IN ('weightLoss','muscleGain','endurance','strength','general')),
    level VARCHAR(50) CHECK (level IN ('beginner','intermediate','advanced')),
    experience_duration VARCHAR(50) CHECK (experience_duration IN
        ('lessThan6Months','sixMonthsToYear','oneToTwoYears','moreThanTwoYears')),
    weekly_days INTEGER CHECK (weekly_days BETWEEN 1 AND 7),
    daily_duration_min INTEGER CHECK (daily_duration_min BETWEEN 15 AND 300),
    preferred_types TEXT[],
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

ALTER TABLE public.exercisegoal ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users manage own exercisegoal" ON public.exercisegoal
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_exercisegoal_updated_at
  BEFORE UPDATE ON public.exercisegoal
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();


-- ----------------------------------------------------------------------------
-- 4. public.dietgoal  [확정: user_id, daily_calorie_target, diet_type,
--    meals_per_day, daily_water_ml, dietary_restrictions, created_at]
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.dietgoal (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    daily_calorie_target INTEGER CHECK (daily_calorie_target BETWEEN 1000 AND 5000),
    diet_type VARCHAR(50) CHECK (diet_type IN ('balanced','lowCarb','highProtein','vegetarian','vegan','keto')),
    meals_per_day INTEGER CHECK (meals_per_day BETWEEN 3 AND 6),
    daily_water_ml INTEGER CHECK (daily_water_ml BETWEEN 1000 AND 5000),
    dietary_restrictions TEXT[],
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

ALTER TABLE public.dietgoal ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users manage own dietgoal" ON public.dietgoal
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE TRIGGER update_dietgoal_updated_at
  BEFORE UPDATE ON public.dietgoal
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();


-- (제외됨: public.usermeal — diet_profile_repository.dart 의 _estimateMealsPerDay()
-- 에서 읽기만 하고(user_id, meal_time), 어떤 코드 경로도 여기에 쓰지 않는 죽은
-- 테이블. 없어도 해당 함수는 catch에서 기본값(mealsPerDay=3)으로 정상 동작함.)


-- ----------------------------------------------------------------------------
-- 5. public.meal_record  [확정: meal_record_id, user_id, meal_date, meal_type,
--    calories, carbs, protein, fat]  (diet_providers.dart, diet_history_repository.dart)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.meal_record (
    meal_record_id BIGSERIAL PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    meal_date DATE NOT NULL,
    meal_type VARCHAR(20) NOT NULL CHECK (meal_type IN ('breakfast','lunch','dinner')),
    calories NUMERIC,
    carbs NUMERIC,
    protein NUMERIC,
    fat NUMERIC,
    created_at TIMESTAMP DEFAULT NOW()             -- [불명] 존재 추정
);

CREATE INDEX IF NOT EXISTS idx_meal_record_user_date ON public.meal_record(user_id, meal_date);

ALTER TABLE public.meal_record ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users manage own meal_record" ON public.meal_record
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);


-- ----------------------------------------------------------------------------
-- 6. public.meal_component  [확정: meal_record_id, food_code, food_name,
--    food_category, grams, calories, carbs, protein, fat]
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.meal_component (
    id BIGSERIAL PRIMARY KEY,                      -- [불명] PK 컬럼명 추정
    meal_record_id BIGINT NOT NULL REFERENCES public.meal_record(meal_record_id) ON DELETE CASCADE,
    food_code VARCHAR(50),
    food_name VARCHAR(255),
    food_category VARCHAR(100),
    grams NUMERIC,
    calories NUMERIC,
    carbs NUMERIC,
    protein NUMERIC,
    fat NUMERIC
);

CREATE INDEX IF NOT EXISTS idx_meal_component_meal_record_id ON public.meal_component(meal_record_id);

ALTER TABLE public.meal_component ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users manage own meal_component" ON public.meal_component
  FOR ALL USING (
    EXISTS (SELECT 1 FROM public.meal_record mr WHERE mr.meal_record_id = meal_component.meal_record_id AND mr.user_id = auth.uid())
  ) WITH CHECK (
    EXISTS (SELECT 1 FROM public.meal_record mr WHERE mr.meal_record_id = meal_component.meal_record_id AND mr.user_id = auth.uid())
  );


-- ----------------------------------------------------------------------------
-- 7. public.nutritionsummary  [확정: user_id, date, total_calories, total_carbs,
--    total_protein, total_fat]  UNIQUE(user_id, date) — onConflict 'user_id,date' 사용
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.nutritionsummary (
    id BIGSERIAL PRIMARY KEY,                      -- [불명]
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    total_calories NUMERIC DEFAULT 0,
    total_carbs NUMERIC DEFAULT 0,
    total_protein NUMERIC DEFAULT 0,
    total_fat NUMERIC DEFAULT 0,
    UNIQUE (user_id, date)
);

ALTER TABLE public.nutritionsummary ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users manage own nutritionsummary" ON public.nutritionsummary
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);


-- ----------------------------------------------------------------------------
-- 8. public.exercise  [확정: exercise_id, name, body_part, description,
--    difficulty, video_url, created_at, updated_at]  (setup_exercise_table_*.sql +
--    supabase_exercise.dart 모델과 일치)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.exercise (
    exercise_id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    body_part VARCHAR(100) NOT NULL DEFAULT '맨몸운동',
    description TEXT,
    difficulty VARCHAR(50) DEFAULT '초급',
    video_url TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_exercise_body_part ON public.exercise(body_part);

ALTER TABLE public.exercise ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can view exercises" ON public.exercise FOR SELECT USING (true);
GRANT SELECT ON public.exercise TO anon, authenticated;
GRANT INSERT, UPDATE, DELETE ON public.exercise TO authenticated;

CREATE OR REPLACE FUNCTION update_exercise_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_exercise_updated_at_trigger
  BEFORE UPDATE ON public.exercise
  FOR EACH ROW EXECUTE FUNCTION update_exercise_updated_at();

-- 기본 운동 데이터 (setup_exercise_table_wkmnnzndtggrlrzjlncn.sql 기준, exercise_reference.json과 매핑됨)
INSERT INTO public.exercise (exercise_id, name, body_part, description, difficulty) VALUES
  (1, '스탠딩 사이드 크런치', '맨몸운동', '서서 좌우로 몸을 기울여 옆구리 근육을 강화하는 운동', '초급'),
  (2, '스탠딩 니업', '맨몸운동', '서서 무릎을 교대로 가슴 쪽으로 들어올리는 유산소 운동', '초급'),
  (3, '스쿼트', '맨몸운동', '하체 근력을 강화하는 기본 운동', '초급')
ON CONFLICT (exercise_id) DO NOTHING;
SELECT setval(pg_get_serial_sequence('public.exercise','exercise_id'), GREATEST((SELECT MAX(exercise_id) FROM public.exercise), 1));


-- ----------------------------------------------------------------------------
-- 9. public.routine  (구 workoutroutine)  [확정: routine_id, user_id, title,
--     description, created_at]  (supabase_workout_routine.dart, service select)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.routine (
    routine_id BIGSERIAL PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()              -- [불명] 존재 추정
);

CREATE INDEX IF NOT EXISTS idx_routine_user_id ON public.routine(user_id);

ALTER TABLE public.routine ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users manage own routine" ON public.routine
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);


-- ----------------------------------------------------------------------------
-- 10. public.routine_exercise (구 routineexercise)  [확정: routine_ex_id, routine_id,
--     exercise_id, sets, reps, rest_time_sec]  (supabase_routine_exercise.dart)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.routine_exercise (
    routine_ex_id BIGSERIAL PRIMARY KEY,
    routine_id BIGINT REFERENCES public.routine(routine_id) ON DELETE CASCADE,
    exercise_id BIGINT REFERENCES public.exercise(exercise_id) ON DELETE CASCADE,
    sets INTEGER NOT NULL DEFAULT 1,
    reps INTEGER NOT NULL DEFAULT 1,
    rest_time_sec INTEGER DEFAULT 60,
    order_index INTEGER DEFAULT 0,                  -- [추정] 옛 문서 기준
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_routine_exercise_routine_id ON public.routine_exercise(routine_id);

ALTER TABLE public.routine_exercise ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users manage own routine_exercise" ON public.routine_exercise
  FOR ALL USING (
    EXISTS (SELECT 1 FROM public.routine r WHERE r.routine_id = routine_exercise.routine_id AND r.user_id = auth.uid())
  ) WITH CHECK (
    EXISTS (SELECT 1 FROM public.routine r WHERE r.routine_id = routine_exercise.routine_id AND r.user_id = auth.uid())
  );


-- ----------------------------------------------------------------------------
-- 11. public.routine_record  (운동 세션 기록)
--     [확정: session_id, user_id, routine_id, start_time, end_time, total_calories,
--      session_status, completion_method, manual_notes, perceived_intensity,
--      is_user_reported]  — supabase_workout_service.dart select 목록 및
--      supabase_workout_session.dart 모델과 정확히 일치
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.routine_record (
    session_id BIGSERIAL PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    routine_id BIGINT REFERENCES public.routine(routine_id) ON DELETE SET NULL,
    start_time TIMESTAMP DEFAULT NOW(),
    end_time TIMESTAMP,
    total_calories INTEGER DEFAULT 0,
    session_status VARCHAR(50) DEFAULT 'in_progress' CHECK (session_status IN ('in_progress','completed','cancelled')),
    completion_method VARCHAR(50) DEFAULT 'app',    -- [추정] 'app'|'manual' 또는 'pose_assisted'|'manual' (문서 간 불일치, 코드는 값 검증 없이 그대로 저장)
    manual_notes TEXT,
    perceived_intensity SMALLINT CHECK (perceived_intensity BETWEEN 1 AND 10),
    is_user_reported BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_routine_record_user_id ON public.routine_record(user_id);

ALTER TABLE public.routine_record ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users manage own routine_record" ON public.routine_record
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);


-- ----------------------------------------------------------------------------
-- 12. public.workoutrecords (세트별 상세 기록)  [확정: record_id, session_id,
--     exercise_id, set_num, reps_done, start_time, end_time, calories_burned]
--     (supabase_workout_record.dart)
--     [추정] weight_kg — 옛 workout_database_schema.sql에는 있었으나 현재 Dart
--     모델에는 없음. 실제 DB에 남아있었을 수도, 이미 제거됐을 수도 있음.
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.workoutrecords (
    record_id BIGSERIAL PRIMARY KEY,
    session_id BIGINT REFERENCES public.routine_record(session_id) ON DELETE CASCADE,
    exercise_id BIGINT REFERENCES public.exercise(exercise_id) ON DELETE CASCADE,
    set_num INTEGER NOT NULL,
    reps_done INTEGER NOT NULL,
    weight_kg DECIMAL(5,2) DEFAULT 0,               -- [추정]
    start_time TIMESTAMP DEFAULT NOW(),
    end_time TIMESTAMP,
    calories_burned INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_workoutrecords_session_id ON public.workoutrecords(session_id);

ALTER TABLE public.workoutrecords ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users manage own workoutrecords" ON public.workoutrecords
  FOR ALL USING (
    EXISTS (SELECT 1 FROM public.routine_record rr WHERE rr.session_id = workoutrecords.session_id AND rr.user_id = auth.uid())
  ) WITH CHECK (
    EXISTS (SELECT 1 FROM public.routine_record rr WHERE rr.session_id = workoutrecords.session_id AND rr.user_id = auth.uid())
  );


-- ----------------------------------------------------------------------------
-- 13. public.routine_schedule  [확정: schedule_id, user_id, routine_id, weekday,
--     start_time, sort_order, is_active, note]  (20250113_routine_schedule.sql +
--     supabase_workout_service.dart select 목록 정확히 일치)
--     주의: user_id는 public.users(user_id) 참조 (auth.users 아님 — 원본 문서 기준)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.routine_schedule (
    schedule_id INTEGER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    routine_id INTEGER NOT NULL REFERENCES public.routine(routine_id) ON DELETE CASCADE,
    weekday SMALLINT NOT NULL CHECK (weekday BETWEEN 0 AND 6),
    start_time TIME WITHOUT TIME ZONE,
    sort_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    note TEXT,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS routine_schedule_user_weekday_idx
  ON public.routine_schedule (user_id, weekday, routine_id, sort_order);

ALTER TABLE public.routine_schedule ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users manage own routine_schedule" ON public.routine_schedule
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);


-- ============================================================================
-- 함수: create_complete_routine
-- 원본(create_complete_routine_function.sql, test_routine_creation.sql)은
-- 구 테이블명(workoutroutine/routineexercise)을 사용함. 현재 코드의 실제 테이블명
-- (routine/routine_exercise)에 맞춰 아래와 같이 고쳐서 재구성함. 이 함수가 최신
-- 스키마에서도 실제로 쓰이고 있었는지는 코드에서 직접 호출부를 찾지 못해 불확실.
-- ============================================================================
CREATE OR REPLACE FUNCTION create_complete_routine(
  p_user_id UUID,
  p_title VARCHAR(255),
  p_description TEXT DEFAULT '',
  p_exercises JSONB DEFAULT '[]'
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_routine_id BIGINT;
  v_exercise JSONB;
  v_result JSON;
BEGIN
  INSERT INTO public.routine (user_id, title, description, created_at)
  VALUES (p_user_id, p_title, p_description, NOW())
  RETURNING routine_id INTO v_routine_id;

  FOR v_exercise IN SELECT * FROM jsonb_array_elements(p_exercises)
  LOOP
    INSERT INTO public.routine_exercise (routine_id, exercise_id, sets, reps, rest_time_sec, created_at)
    VALUES (
      v_routine_id,
      (v_exercise->>'exercise_id')::INTEGER,
      (v_exercise->>'sets')::INTEGER,
      (v_exercise->>'reps')::INTEGER,
      COALESCE((v_exercise->>'rest_time_sec')::INTEGER, 60),
      NOW()
    );
  END LOOP;

  SELECT row_to_json(r.*) INTO v_result FROM public.routine r WHERE r.routine_id = v_routine_id;
  RETURN v_result;
EXCEPTION
  WHEN OTHERS THEN
    RAISE EXCEPTION '루틴 생성 실패: %', SQLERRM;
END;
$$;

GRANT EXECUTE ON FUNCTION create_complete_routine TO authenticated;
