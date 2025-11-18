-- routine_record 테이블에 추가 컬럼 추가
-- RPE(인지 강도), 메모, 완료 방법 등을 저장하기 위한 마이그레이션

-- 1. completion_method: 운동 완료 방법 (app: 앱으로 진행, manual: 수동 완료)
ALTER TABLE public.routine_record
ADD COLUMN IF NOT EXISTS completion_method VARCHAR(50) DEFAULT 'app'
CHECK (completion_method IN ('app', 'manual'));

-- 2. manual_notes: 사용자가 작성한 메모
ALTER TABLE public.routine_record
ADD COLUMN IF NOT EXISTS manual_notes TEXT;

-- 3. perceived_intensity: RPE (Rating of Perceived Exertion) - 인지 강도 1~10
ALTER TABLE public.routine_record
ADD COLUMN IF NOT EXISTS perceived_intensity INTEGER
CHECK (perceived_intensity >= 1 AND perceived_intensity <= 10);

-- 4. is_user_reported: 사용자가 직접 입력한 기록인지 여부
ALTER TABLE public.routine_record
ADD COLUMN IF NOT EXISTS is_user_reported BOOLEAN DEFAULT FALSE;

-- 5. 인덱스 추가 (성능 최적화)
CREATE INDEX IF NOT EXISTS idx_routine_record_completion_method
ON public.routine_record(completion_method);

CREATE INDEX IF NOT EXISTS idx_routine_record_perceived_intensity
ON public.routine_record(perceived_intensity);

-- 컬럼 코멘트 추가
COMMENT ON COLUMN public.routine_record.completion_method IS '운동 완료 방법 (app: 앱으로 진행, manual: 수동 완료)';
COMMENT ON COLUMN public.routine_record.manual_notes IS '사용자가 작성한 메모 (일부 운동 완료 시 운동 목록 포함)';
COMMENT ON COLUMN public.routine_record.perceived_intensity IS 'RPE (인지 강도) 1~10 (1-2: 매우 가벼움, 3-4: 가벼움, 5-6: 보통, 7-8: 힘듦, 9-10: 매우 힘듦)';
COMMENT ON COLUMN public.routine_record.is_user_reported IS '사용자가 직접 입력한 기록 여부 (true: 빠른 완료, false: 앱으로 진행)';

-- 마이그레이션 완료 확인용 쿼리
SELECT
    column_name,
    data_type,
    column_default,
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'routine_record'
ORDER BY ordinal_position;
