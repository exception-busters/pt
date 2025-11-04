-- 운동 관련 데이터베이스 스키마 생성 SQL
-- Supabase PostgreSQL용

-- 1. exercise 테이블 - 운동 동작 기본 정보
CREATE TABLE IF NOT EXISTS public.exercise (
    exercise_id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    body_part VARCHAR(100) NOT NULL,
    description TEXT,
    difficulty VARCHAR(50) CHECK (difficulty IN ('초급', '중급', '고급', 'beginner', 'intermediate', 'advanced')),
    video_url TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- 2. workoutroutine 테이블 - 사용자별 운동 루틴
CREATE TABLE IF NOT EXISTS public.workoutroutine (
    routine_id BIGSERIAL PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- 3. routineexercise 테이블 - 루틴 내 운동 구성
CREATE TABLE IF NOT EXISTS public.routineexercise (
    routine_ex_id BIGSERIAL PRIMARY KEY,
    routine_id BIGINT REFERENCES public.workoutroutine(routine_id) ON DELETE CASCADE,
    exercise_id BIGINT REFERENCES public.exercise(exercise_id) ON DELETE CASCADE,
    sets INTEGER NOT NULL DEFAULT 1,
    reps INTEGER NOT NULL DEFAULT 1,
    rest_time_sec INTEGER DEFAULT 60,
    order_index INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW()
);

-- 4. workoutsession 테이블 - 운동 세션 기록
CREATE TABLE IF NOT EXISTS public.workoutsession (
    session_id BIGSERIAL PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    routine_id BIGINT REFERENCES public.workoutroutine(routine_id) ON DELETE SET NULL,
    start_time TIMESTAMP DEFAULT NOW(),
    end_time TIMESTAMP,
    total_calories INTEGER DEFAULT 0,
    session_status VARCHAR(50) DEFAULT 'in_progress' CHECK (session_status IN ('in_progress', 'completed', 'cancelled')),
    created_at TIMESTAMP DEFAULT NOW()
);

-- 5. workoutrecords 테이블 - 세트별 운동 수행 기록
CREATE TABLE IF NOT EXISTS public.workoutrecords (
    record_id BIGSERIAL PRIMARY KEY,
    session_id BIGINT REFERENCES public.workoutsession(session_id) ON DELETE CASCADE,
    exercise_id BIGINT REFERENCES public.exercise(exercise_id) ON DELETE CASCADE,
    set_num INTEGER NOT NULL,
    reps_done INTEGER NOT NULL,
    weight_kg DECIMAL(5,2) DEFAULT 0,
    start_time TIMESTAMP DEFAULT NOW(),
    end_time TIMESTAMP,
    calories_burned INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW()
);

-- 인덱스 생성 (성능 최적화)
CREATE INDEX IF NOT EXISTS idx_workout_routine_user_id ON public.workoutroutine(user_id);
CREATE INDEX IF NOT EXISTS idx_routine_exercise_routine_id ON public.routineexercise(routine_id);
CREATE INDEX IF NOT EXISTS idx_workout_session_user_id ON public.workoutsession(user_id);
CREATE INDEX IF NOT EXISTS idx_workout_records_session_id ON public.workoutrecords(session_id);
CREATE INDEX IF NOT EXISTS idx_exercise_body_part ON public.exercise(body_part);

-- RLS (Row Level Security) 정책 설정
ALTER TABLE public.workoutroutine ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.routineexercise ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workoutsession ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workoutrecords ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.exercise ENABLE ROW LEVEL SECURITY;

-- workoutroutine 정책
CREATE POLICY "Users can view own routines" ON public.workoutroutine
    FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own routines" ON public.workoutroutine
    FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own routines" ON public.workoutroutine
    FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own routines" ON public.workoutroutine
    FOR DELETE USING (auth.uid() = user_id);

-- routineexercise 정책
CREATE POLICY "Users can view own routine exercises" ON public.routineexercise
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.workoutroutine 
            WHERE routine_id = routineexercise.routine_id 
            AND user_id = auth.uid()
        )
    );
CREATE POLICY "Users can insert own routine exercises" ON public.routineexercise
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.workoutroutine 
            WHERE routine_id = routineexercise.routine_id 
            AND user_id = auth.uid()
        )
    );
CREATE POLICY "Users can update own routine exercises" ON public.routineexercise
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM public.workoutroutine 
            WHERE routine_id = routineexercise.routine_id 
            AND user_id = auth.uid()
        )
    );
CREATE POLICY "Users can delete own routine exercises" ON public.routineexercise
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM public.workoutroutine 
            WHERE routine_id = routineexercise.routine_id 
            AND user_id = auth.uid()
        )
    );

-- workoutsession 정책
CREATE POLICY "Users can view own sessions" ON public.workoutsession
    FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own sessions" ON public.workoutsession
    FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own sessions" ON public.workoutsession
    FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own sessions" ON public.workoutsession
    FOR DELETE USING (auth.uid() = user_id);

-- workoutrecords 정책
CREATE POLICY "Users can view own records" ON public.workoutrecords
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.workoutsession 
            WHERE session_id = workoutrecords.session_id 
            AND user_id = auth.uid()
        )
    );
CREATE POLICY "Users can insert own records" ON public.workoutrecords
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.workoutsession 
            WHERE session_id = workoutrecords.session_id 
            AND user_id = auth.uid()
        )
    );
CREATE POLICY "Users can update own records" ON public.workoutrecords
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM public.workoutsession 
            WHERE session_id = workoutrecords.session_id 
            AND user_id = auth.uid()
        )
    );
CREATE POLICY "Users can delete own records" ON public.workoutrecords
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM public.workoutsession 
            WHERE session_id = workoutrecords.session_id 
            AND user_id = auth.uid()
        )
    );

-- exercise 정책 (모든 사용자가 읽기 가능, 관리자만 수정 가능)
CREATE POLICY "Anyone can view exercises" ON public.exercise
    FOR SELECT USING (true);

-- 기본 운동 데이터 삽입
INSERT INTO public.exercise (name, body_part, description, difficulty) VALUES
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
COMMENT ON TABLE public.exercise IS '운동 동작 기본 정보';
COMMENT ON TABLE public.workoutroutine IS '사용자별 운동 루틴';
COMMENT ON TABLE public.routineexercise IS '루틴 내 운동 구성';
COMMENT ON TABLE public.workoutsession IS '운동 세션 기록';
COMMENT ON TABLE public.workoutrecords IS '세트별 운동 수행 기록';