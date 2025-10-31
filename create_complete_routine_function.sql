-- PostgreSQL 저장 함수: 루틴과 운동을 한 번에 생성
-- Supabase RPC로 호출 가능

CREATE OR REPLACE FUNCTION create_complete_routine(
  p_user_id UUID,
  p_title VARCHAR(255),
  p_description TEXT DEFAULT '',
  p_exercises JSONB
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_routine_id BIGINT;
  v_exercise JSONB;
  v_result JSON;
BEGIN
  -- 1. 루틴 생성
  INSERT INTO workoutroutine (user_id, title, description, created_at)
  VALUES (p_user_id, p_title, p_description, NOW())
  RETURNING routine_id INTO v_routine_id;
  
  -- 2. 운동들 추가
  FOR v_exercise IN SELECT * FROM jsonb_array_elements(p_exercises)
  LOOP
    INSERT INTO routineexercise (routine_id, exercise_id, sets, reps, rest_time_sec, created_at)
    VALUES (
      v_routine_id,
      (v_exercise->>'exercise_id')::INTEGER,
      (v_exercise->>'sets')::INTEGER,
      (v_exercise->>'reps')::INTEGER,
      COALESCE((v_exercise->>'rest_time_sec')::INTEGER, 60),
      NOW()
    );
  END LOOP;
  
  -- 3. 생성된 루틴 정보 반환
  SELECT row_to_json(wr.*)
  INTO v_result
  FROM workoutroutine wr
  WHERE wr.routine_id = v_routine_id;
  
  RETURN v_result;
  
EXCEPTION
  WHEN OTHERS THEN
    -- 에러 발생 시 롤백 (트랜잭션 자동 처리)
    RAISE EXCEPTION '루틴 생성 실패: %', SQLERRM;
END;
$$;

-- RLS 정책에서 함수 실행 허용
GRANT EXECUTE ON FUNCTION create_complete_routine TO authenticated;

-- 함수 설명
COMMENT ON FUNCTION create_complete_routine IS '운동 루틴과 관련 운동들을 원자적으로 생성하는 함수';

-- 사용 예시 (주석)
/*
SELECT create_complete_routine(
  'user-uuid-here',
  '하체 루틴',
  '스쿼트, 런지, 데드리프트 중심의 하체 운동',
  '[
    {"exercise_id": 1, "sets": 4, "reps": 12, "rest_time_sec": 60},
    {"exercise_id": 2, "sets": 3, "reps": 10, "rest_time_sec": 90},
    {"exercise_id": 3, "sets": 3, "reps": 8, "rest_time_sec": 120}
  ]'::jsonb
);
*/