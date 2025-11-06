-- 데이터베이스 상태 확인 및 수정용 SQL
-- 이 쿼리들을 Supabase SQL Editor에서 실행하세요

-- 1. users 테이블 구조 확인
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'users' 
ORDER BY ordinal_position;

-- 2. 모든 사용자 데이터 확인
SELECT user_id, email, nickname, profile_completed, join_date
FROM users 
ORDER BY join_date DESC;

-- 3. profile_completed 컬럼이 없다면 추가 (필수!)
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS profile_completed BOOLEAN DEFAULT FALSE;

-- 4. 기존 사용자들의 profile_completed를 false로 초기화
UPDATE users 
SET profile_completed = FALSE 
WHERE profile_completed IS NULL;

-- 5. 특정 사용자 확인 (user_id를 실제 값으로 바꿔서 실행)
-- SELECT user_id, email, nickname, profile_completed, join_date
-- FROM users 
-- WHERE user_id = '3ce86fd3-0727-4c3a-ab25-78271c1abf84';

-- 6. 테스트용: 특정 사용자를 온보딩 완료로 설정
-- UPDATE users 
-- SET profile_completed = TRUE 
-- WHERE user_id = '3ce86fd3-0727-4c3a-ab25-78271c1abf84';