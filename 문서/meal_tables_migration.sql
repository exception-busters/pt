-- 식단 기록을 위한 새 테이블 마이그레이션
-- Supabase SQL Editor에서 실행하세요

-- 1. 식단 기록 메인 테이블 생성
CREATE TABLE IF NOT EXISTS public.meal_record (
  meal_record_id SERIAL PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
  meal_date DATE NOT NULL,
  meal_type VARCHAR(20) NOT NULL CHECK (meal_type IN ('breakfast', 'lunch', 'dinner')),
  calories NUMERIC DEFAULT 0,
  carbs NUMERIC DEFAULT 0,
  protein NUMERIC DEFAULT 0,
  fat NUMERIC DEFAULT 0,
  created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW()
);

-- 2. 식단 구성요소 테이블 생성
CREATE TABLE IF NOT EXISTS public.meal_component (
  component_id SERIAL PRIMARY KEY,
  meal_record_id INTEGER NOT NULL REFERENCES public.meal_record(meal_record_id) ON DELETE CASCADE,
  food_code VARCHAR(50),
  food_name VARCHAR(200) NOT NULL,
  food_category VARCHAR(100),
  grams NUMERIC NOT NULL CHECK (grams >= 0),
  calories NUMERIC DEFAULT 0,
  protein NUMERIC DEFAULT 0,
  carbs NUMERIC DEFAULT 0,
  fat NUMERIC DEFAULT 0,
  fiber NUMERIC DEFAULT 0,
  sodium NUMERIC DEFAULT 0
);

-- 3. 인덱스 생성 (성능 최적화)
CREATE INDEX IF NOT EXISTS idx_meal_record_user_date
  ON public.meal_record(user_id, meal_date DESC);

CREATE INDEX IF NOT EXISTS idx_meal_record_user_type_date
  ON public.meal_record(user_id, meal_type, meal_date DESC);

CREATE INDEX IF NOT EXISTS idx_meal_component_meal_record
  ON public.meal_component(meal_record_id);

-- 4. RLS (Row Level Security) 활성화
ALTER TABLE public.meal_record ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.meal_component ENABLE ROW LEVEL SECURITY;

-- 5. RLS 정책 생성 (사용자는 자신의 데이터만 접근 가능)
CREATE POLICY "Users can view their own meal records"
  ON public.meal_record FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own meal records"
  ON public.meal_record FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own meal records"
  ON public.meal_record FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own meal records"
  ON public.meal_record FOR DELETE
  USING (auth.uid() = user_id);

-- meal_component는 meal_record를 통해 간접적으로 접근
CREATE POLICY "Users can view meal components of their meals"
  ON public.meal_component FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.meal_record
      WHERE meal_record.meal_record_id = meal_component.meal_record_id
        AND meal_record.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can insert meal components for their meals"
  ON public.meal_component FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.meal_record
      WHERE meal_record.meal_record_id = meal_component.meal_record_id
        AND meal_record.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can update meal components of their meals"
  ON public.meal_component FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.meal_record
      WHERE meal_record.meal_record_id = meal_component.meal_record_id
        AND meal_record.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can delete meal components of their meals"
  ON public.meal_component FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM public.meal_record
      WHERE meal_record.meal_record_id = meal_component.meal_record_id
        AND meal_record.user_id = auth.uid()
    )
  );

-- 6. updated_at 자동 업데이트 트리거 함수 생성
CREATE OR REPLACE FUNCTION public.update_meal_record_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 7. 트리거 생성
CREATE TRIGGER trigger_update_meal_record_updated_at
  BEFORE UPDATE ON public.meal_record
  FOR EACH ROW
  EXECUTE FUNCTION public.update_meal_record_updated_at();

-- 완료 메시지
COMMENT ON TABLE public.meal_record IS '사용자 식단 기록 메인 테이블';
COMMENT ON TABLE public.meal_component IS '식단 구성요소 상세 테이블';
