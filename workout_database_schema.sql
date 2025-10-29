-- 운동 관련 데이터베이스 스키마 생성 SQL
-- Supabase PostgreSQL용

-- 1. Exercise 테이블 - 운동 동작 기본 정보
CREATE TABLE IF NOT EXISTS public.Exercise (
    exercise_id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    body_part VARCHAR(100) NOT NULL,
    description TEXT,
    difficulty VARCHAR(50) CHECK (difficulty IN ('초급', '중급', '고급', 'beginner', 'intermediate', 'advanced')),
    video_url TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- 2. WorkoutRoutine 테이블 - 사용자별 운동 루틴
CREATE TABLE IF NOT EXISTS public.WorkoutRoutine (
    routine_id BIGSERIAL PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- 3. RoutineExercise 테이블 - 루틴 내 운동 구성
CREATE TABLE IF NOT EXISTS public.RoutineExercise (
    routine_ex_id BIGSERIAL PRIMARY KEY,
    routine_id BIGINT REFERENCES public.WorkoutRoutine(routine_id) ON DELETE CASCADE,
    exercise_id BIGINT REFERENCES public.Exercise(exercise_id) ON DELETE CASCADE,
    sets INTEGER NOT NULL DEFAULT 1,
    reps INTEGER NOT NULL DEFAULT 1,
    rest_time_sec INTEGER DEFAULT 60,
    order_index INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW()
);

-- 4. WorkoutSession 테이블 - 운동 세션 기록
CREATE TABLE IF NOT EXISTS public.WorkoutSession (
    session_id BIGSERIAL PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    routine_id BIGINT REFERENCES public.WorkoutRoutine(routine_id) ON DELETE SET NULL,
    start_time TIMESTAMP DEFAULT NOW(),
    end_time TIMESTAMP,
    total_calories INTEGER DEFAULT 0,
    session_status VARCHAR(50) DEFAULT 'in_progress' CHECK (session_status IN ('in_progress', 'completed', 'cancelled')),
    created_at TIMESTAMP DEFAULT NOW()
);

-- 5. WorkoutRecords 테이블 - 세트별 운동 수행 기록
CREATE TABLE IF NOT EXISTS public.WorkoutRecords (
    record_id BIGSERIAL PRIMARY KEY,
    session_id BIGINT REFERENCES public.WorkoutSession(session_id) ON DELETE CASCADE,
    exercise_id BIGINT REFERENCES public.Exercise(exercise_id) ON DELETE CASCADE,
    set_num INTEGER NOT NULL,
    reps_done INTEGER NOT NULL,
    weight_kg DECIMAL(5,2) DEFAULT 0,
    start_time TIMESTAMP DEFAULT NOW(),
    end_time TIMESTAMP,
    calories_burned INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW()
);

-- 인덱스 생성 (성능 최적화)
CREATE INDEX IF NOT EXISTS idx_workout_routine_user_id ON public.WorkoutRoutine(user_id);
CREATE INDEX IF NOT EXISTS idx_routine_exercise_routine_id ON public.RoutineExercise(routine_id);
CREATE INDEX IF NOT EXISTS idx_workout_session_user_id ON public.WorkoutSession(user_id);
CREATE INDEX IF NOT EXISTS idx_workout_records_session_id ON public.WorkoutRecords(session_id);
CREATE INDEX IF NOT EXISTS idx_exercise_body_part ON public.Exercise(body_part);

-- RLS (Row Level Security) 정책 설정
ALTER TABLE public.WorkoutRoutine ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.RoutineExercise ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.WorkoutSession ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.WorkoutRecords ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.Exercise ENABLE ROW LEVEL SECURITY;

-- WorkoutRoutine 정책
CREATE POLICY "Users can view own routines" ON public.WorkoutRoutine
    FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own routines" ON public.WorkoutRoutine
    FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own routines" ON public.WorkoutRoutine
    FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own routines" ON public.WorkoutRoutine
    FOR DELETE USING (auth.uid() = user_id);

-- RoutineExercise 정책
CREATE POLICY "Users can view own routine exercises" ON public.RoutineExercise
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.WorkoutRoutine 
            WHERE routine_id = RoutineExercise.routine_id 
            AND user_id = auth.uid()
        )
    );
CREATE POLICY "Users can insert own routine exercises" ON public.RoutineExercise
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.WorkoutRoutine 
            WHERE routine_id = RoutineExercise.routine_id 
            AND user_id = auth.uid()
        )
    );
CREATE POLICY "Users can update own routine exercises" ON public.RoutineExercise
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM public.WorkoutRoutine 
            WHERE routine_id = RoutineExercise.routine_id 
            AND user_id = auth.uid()
        )
    );
CREATE POLICY "Users can delete own routine exercises" ON public.RoutineExercise
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM public.WorkoutRoutine 
            WHERE routine_id = RoutineExercise.routine_id 
            AND user_id = auth.uid()
        )
    );

-- WorkoutSession 정책
CREATE POLICY "Users can view own sessions" ON public.WorkoutSession
    FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own sessions" ON public.WorkoutSession
    FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own sessions" ON public.WorkoutSession
    FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own sessions" ON public.WorkoutSession
    FOR DELETE USING (auth.uid() = user_id);

-- WorkoutRecords 정책
CREATE POLICY "Users can view own records" ON public.WorkoutRecords
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.WorkoutSession 
            WHERE session_id = WorkoutRecords.session_id 
            AND user_id = auth.uid()
        )
    );
CREATE POLICY "Users can insert own records" ON public.WorkoutRecords
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.WorkoutSession 
            WHERE session_id = WorkoutRecords.session_id 
            AND user_id = auth.uid()
        )
    );
CREATE POLICY "Users can update own records" ON public.WorkoutRecords
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM public.WorkoutSession 
            WHERE session_id = WorkoutRecords.session_id 
            AND user_id = auth.uid()
        )
    );
CREATE POLICY "Users can delete own records" ON public.WorkoutRecords
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM public.WorkoutSession 
            WHERE session_id = WorkoutRecords.session_id 
            AND user_id = auth.uid()
        )
    );

-- Exercise 정책 (모든 사용자가 읽기 가능, 관리자만 수정 가능)
CREATE POLICY "Anyone can view exercises" ON public.Exercise
    FOR SELECT USING (true);

-- 기본 운동 데이터 삽입
INSERT INTO public.Exercise (name, body_part, description, difficulty) VALUES
('푸시업', '가슴', '가슴과 팔 근육을 강화하는 기본 운동', '초급'),
('스쿼트', '하체', '하체 전체 근육을 강화하는 운동', '초급'),
('플랭크', '코어', '코어 근육을 강화하는 정적 운동', '초급'),
('풀업', '등', '등과 팔 근육을 강화하는 운동', '중급'),
('데드리프트', '전신', '전신 근육을 강화하는 복합 운동', '고급'),
('벤치프레스', '가슴', '가슴 근육을 집중적으로 강화하는 운동', '중급'),
('런지', '하체', '하체 근육과 균형감각을 기르는 운동', '초급'),
('버피', '전신', '전신 유산소 및 근력 운동', '중급')
ON CONFLICT DO NOTHING;

-- 테이블 코멘트 추가
COMMENT ON TABLE public.Exercise IS '운동 동작 기본 정보';
COMMENT ON TABLE public.WorkoutRoutine IS '사용자별 운동 루틴';
COMMENT ON TABLE public.RoutineExercise IS '루틴 내 운동 구성';
COMMENT ON TABLE public.WorkoutSession IS '운동 세션 기록';
COMMENT ON TABLE public.WorkoutRecords IS '세트별 운동 수행 기록';