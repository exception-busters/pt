-- 루틴 생성 테스트 SQL
-- 이 파일은 create_complete_routine 함수를 테스트하기 위한 예시입니다.

-- 1. 테스트용 사용자 ID (실제 사용 시 auth.users에서 가져온 UUID 사용)
-- 예시: '23ec0e22-3879-4609-ba5e-3c75996d5dfa'

-- 2. 하체 루틴 생성 테스트
SELECT create_complete_routine(
  '23ec0e22-3879-4609-ba5e-3c75996d5dfa'::UUID,  -- 사용자 ID
  '하체 집중 루틴',                                -- 루틴 제목
  '스쿼트, 런지, 데드리프트를 중심으로 한 하체 강화 운동', -- 설명
  '[
    {"exercise_id": 1, "sets": 4, "reps": 12, "rest_time_sec": 60},
    {"exercise_id": 2, "sets": 3, "reps": 10, "rest_time_sec": 90},
    {"exercise_id": 3, "sets": 3, "reps": 8, "rest_time_sec": 120}
  ]'::jsonb
) AS created_routine;

-- 3. 상체 루틴 생성 테스트
SELECT create_complete_routine(
  '23ec0e22-3879-4609-ba5e-3c75996d5dfa'::UUID,
  '상체 집중 루틴',
  '푸쉬업과 플랭크를 중심으로 한 상체 강화 운동',
  '[
    {"exercise_id": 4, "sets": 3, "reps": 15, "rest_time_sec": 45},
    {"exercise_id": 5, "sets": 3, "reps": 30, "rest_time_sec": 60}
  ]'::jsonb
) AS created_routine;

-- 4. 생성된 루틴 확인
SELECT 
  wr.routine_id,
  wr.title,
  wr.description,
  wr.created_at,
  COUNT(re.routine_ex_id) as exercise_count
FROM workoutroutine wr
LEFT JOIN routineexercise re ON wr.routine_id = re.routine_id
WHERE wr.user_id = '23ec0e22-3879-4609-ba5e-3c75996d5dfa'::UUID
GROUP BY wr.routine_id, wr.title, wr.description, wr.created_at
ORDER BY wr.created_at DESC;

-- 5. 루틴별 운동 상세 정보 확인
SELECT 
  wr.title as routine_title,
  e.name as exercise_name,
  re.sets,
  re.reps,
  re.rest_time_sec
FROM workoutroutine wr
JOIN routineexercise re ON wr.routine_id = re.routine_id
JOIN exercise e ON re.exercise_id = e.exercise_id
WHERE wr.user_id = '23ec0e22-3879-4609-ba5e-3c75996d5dfa'::UUID
ORDER BY wr.created_at DESC, re.routine_ex_id;

-- 6. 함수 실행 권한 확인
SELECT 
  routine_name,
  routine_type,
  security_definer
FROM information_schema.routines 
WHERE routine_name = 'create_complete_routine';