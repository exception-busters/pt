-- users 테이블에 profile_completed 컬럼 추가
-- 이 SQL을 Supabase SQL Editor에서 실행하세요

-- profile_completed 컬럼 추가 (기본값 false)
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS profile_completed BOOLEAN DEFAULT FALSE;

-- 컬럼 코멘트 추가
COMMENT ON COLUMN users.profile_completed IS '프로필 완성 여부 (온보딩 완료 여부)';

-- 기존 사용자들을 모두 미완료 상태로 설정 (필요시)
UPDATE users SET profile_completed = FALSE WHERE profile_completed IS NULL;

-- 확인 쿼리들 (주석 해제해서 사용)
-- SELECT user_id, email, nickname, profile_completed, join_date
-- FROM users 
-- ORDER BY join_date DESC;

-- 특정 사용자의 profile_completed 업데이트 (테스트용)
-- UPDATE users 
-- SET profile_completed = TRUE 
-- WHERE user_id = 'your-user-id-here';