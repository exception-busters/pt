-- public_users 테이블에 온보딩 관련 컬럼 추가
ALTER TABLE public_users 
ADD COLUMN IF NOT EXISTS gender VARCHAR(10),
ADD COLUMN IF NOT EXISTS age INTEGER,
ADD COLUMN IF NOT EXISTS weight DECIMAL(5,2),
ADD COLUMN IF NOT EXISTS height DECIMAL(5,2),
ADD COLUMN IF NOT EXISTS workout_goal VARCHAR(50),
ADD COLUMN IF NOT EXISTS workout_level VARCHAR(20),
ADD COLUMN IF NOT EXISTS onboarding_completed BOOLEAN DEFAULT FALSE;

-- 인덱스 추가 (성능 향상)
CREATE INDEX IF NOT EXISTS idx_public_users_onboarding_completed ON public_users(onboarding_completed);
CREATE INDEX IF NOT EXISTS idx_public_users_workout_level ON public_users(workout_level);

-- 제약 조건 추가
ALTER TABLE public_users 
ADD CONSTRAINT chk_gender CHECK (gender IN ('male', 'female') OR gender IS NULL),
ADD CONSTRAINT chk_age CHECK (age >= 15 AND age <= 100 OR age IS NULL),
ADD CONSTRAINT chk_weight CHECK (weight >= 30 AND weight <= 200 OR weight IS NULL),
ADD CONSTRAINT chk_height CHECK (height >= 140 AND height <= 250 OR height IS NULL),
ADD CONSTRAINT chk_workout_goal CHECK (workout_goal IN ('weightLoss', 'muscleGain', 'fitnessImprovement', 'healthMaintenance') OR workout_goal IS NULL),
ADD CONSTRAINT chk_workout_level CHECK (workout_level IN ('beginner', 'intermediate', 'advanced') OR workout_level IS NULL);

-- 코멘트 추가
COMMENT ON COLUMN public_users.gender IS '사용자 성별 (male/female)';
COMMENT ON COLUMN public_users.age IS '사용자 나이 (15-100)';
COMMENT ON COLUMN public_users.weight IS '사용자 몸무게 (kg)';
COMMENT ON COLUMN public_users.height IS '사용자 키 (cm)';
COMMENT ON COLUMN public_users.workout_goal IS '운동 목적 (weightLoss/muscleGain/fitnessImprovement/healthMaintenance)';
COMMENT ON COLUMN public_users.workout_level IS '운동 수준 (beginner/intermediate/advanced)';
COMMENT ON COLUMN public_users.onboarding_completed IS '온보딩 완료 여부';