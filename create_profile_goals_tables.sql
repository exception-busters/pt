-- 프로필 목표 테이블 생성 SQL
-- Supabase PostgreSQL용

-- 1. workoutgoal 테이블 - 사용자별 운동 목표
CREATE TABLE IF NOT EXISTS public.workoutgoal (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    goal_type VARCHAR(50) CHECK (goal_type IN ('weightLoss', 'muscleGain', 'endurance', 'strength', 'general')),
    level VARCHAR(50) CHECK (level IN ('beginner', 'intermediate', 'advanced')),
    weekly_days INTEGER CHECK (weekly_days >= 1 AND weekly_days <= 7),
    daily_duration_min INTEGER CHECK (daily_duration_min >= 15 AND daily_duration_min <= 300),
    preferred_types TEXT[], -- 선호하는 운동 유형들 (배열)
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- 2. dietgoal 테이블 - 사용자별 식단 목표
CREATE TABLE IF NOT EXISTS public.dietgoal (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    daily_calorie_target INTEGER CHECK (daily_calorie_target >= 1000 AND daily_calorie_target <= 5000),
    diet_type VARCHAR(50) CHECK (diet_type IN ('balanced', 'lowCarb', 'highProtein', 'vegetarian', 'vegan', 'keto')),
    meals_per_day INTEGER CHECK (meals_per_day >= 3 AND meals_per_day <= 6),
    daily_water_ml INTEGER CHECK (daily_water_ml >= 1000 AND daily_water_ml <= 5000),
    dietary_restrictions TEXT[], -- 식이 제한사항들 (배열)
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- 인덱스 생성
CREATE INDEX IF NOT EXISTS idx_workoutgoal_user_id ON public.workoutgoal(user_id);
CREATE INDEX IF NOT EXISTS idx_dietgoal_user_id ON public.dietgoal(user_id);

-- RLS (Row Level Security) 정책 설정
ALTER TABLE public.workoutgoal ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.dietgoal ENABLE ROW LEVEL SECURITY;

-- workoutgoal 정책
CREATE POLICY "Users can view own workout goals" ON public.workoutgoal
    FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own workout goals" ON public.workoutgoal
    FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own workout goals" ON public.workoutgoal
    FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own workout goals" ON public.workoutgoal
    FOR DELETE USING (auth.uid() = user_id);

-- dietgoal 정책
CREATE POLICY "Users can view own diet goals" ON public.dietgoal
    FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own diet goals" ON public.dietgoal
    FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own diet goals" ON public.dietgoal
    FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own diet goals" ON public.dietgoal
    FOR DELETE USING (auth.uid() = user_id);

-- updated_at 자동 업데이트 트리거 함수
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- workoutgoal 테이블에 트리거 적용
CREATE TRIGGER update_workoutgoal_updated_at 
    BEFORE UPDATE ON public.workoutgoal 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- dietgoal 테이블에 트리거 적용
CREATE TRIGGER update_dietgoal_updated_at 
    BEFORE UPDATE ON public.dietgoal 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 테이블 코멘트 추가
COMMENT ON TABLE public.workoutgoal IS '사용자별 운동 목표 설정';
COMMENT ON TABLE public.dietgoal IS '사용자별 식단 목표 설정';

-- 컬럼 코멘트 추가
COMMENT ON COLUMN public.workoutgoal.goal_type IS '운동 목표 유형 (체중감량, 근육증가, 지구력, 근력, 일반)';
COMMENT ON COLUMN public.workoutgoal.level IS '운동 레벨 (초급, 중급, 고급)';
COMMENT ON COLUMN public.workoutgoal.weekly_days IS '주간 운동 일수 (1-7일)';
COMMENT ON COLUMN public.workoutgoal.daily_duration_min IS '일일 운동 시간 (분)';
COMMENT ON COLUMN public.workoutgoal.preferred_types IS '선호하는 운동 유형들';

COMMENT ON COLUMN public.dietgoal.daily_calorie_target IS '일일 칼로리 목표 (kcal)';
COMMENT ON COLUMN public.dietgoal.diet_type IS '식단 유형 (균형, 저탄수화물, 고단백질, 채식, 비건, 케토)';
COMMENT ON COLUMN public.dietgoal.meals_per_day IS '하루 식사 횟수 (3-6회)';
COMMENT ON COLUMN public.dietgoal.daily_water_ml IS '일일 수분 섭취 목표 (ml)';
COMMENT ON COLUMN public.dietgoal.dietary_restrictions IS '식이 제한사항들';