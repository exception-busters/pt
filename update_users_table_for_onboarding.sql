-- Users 테이블에 온보딩 관련 컬럼들 추가
-- 이 SQL을 Supabase SQL Editor에서 실행하세요

-- 온보딩 관련 컬럼들 추가
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS gender VARCHAR(10),
ADD COLUMN IF NOT EXISTS age INTEGER,
ADD COLUMN IF NOT EXISTS weight DECIMAL(5,2),
ADD COLUMN IF NOT EXISTS height DECIMAL(5,2),
ADD COLUMN IF NOT EXISTS workout_goal VARCHAR(50),
ADD COLUMN IF NOT EXISTS workout_level VARCHAR(20),
ADD COLUMN IF NOT EXISTS onboarding_completed BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP DEFAULT NOW();

-- 컬럼 코멘트 추가
COMMENT ON COLUMN users.gender IS '성별 (male/female)';
COMMENT ON COLUMN users.age IS '나이';
COMMENT ON COLUMN users.weight IS '체중 (kg)';
COMMENT ON COLUMN users.height IS '키 (cm)';
COMMENT ON COLUMN users.workout_goal IS '운동 목표';
COMMENT ON COLUMN users.workout_level IS '운동 레벨';
COMMENT ON COLUMN users.onboarding_completed IS '온보딩 완료 여부 (추가 필드)';
COMMENT ON COLUMN users.updated_at IS '마지막 업데이트 시간';

-- 확인 쿼리
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'users' 
ORDER BY ordinal_position;