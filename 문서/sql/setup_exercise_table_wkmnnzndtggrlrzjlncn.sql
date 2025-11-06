-- Flutter 앱이 연결된 실제 Supabase 프로젝트에서 실행할 SQL
-- 프로젝트: wkmnnzndtggrlrzjlncn.supabase.co
-- Supabase 대시보드 > SQL Editor에서 실행하세요

-- exercise 테이블 생성 (없는 경우)
CREATE TABLE IF NOT EXISTS exercise (
  exercise_id BIGSERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  body_part VARCHAR(100) NOT NULL DEFAULT '맨몸운동',
  description TEXT,
  difficulty VARCHAR(50) DEFAULT '초급',
  video_url TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- 기존 데이터 모두 삭제
TRUNCATE TABLE exercise RESTART IDENTITY CASCADE;

-- 3개 운동 추가 (exercise_id: 1, 2, 3 → exercise_reference.json의 001, 002, 003과 매핑)
INSERT INTO exercise (exercise_id, name, body_part, description, difficulty) VALUES
  (1, '스탠딩 사이드 크런치', '맨몸운동', '서서 좌우로 몸을 기울여 옆구리 근육을 강화하는 운동', '초급'),
  (2, '스탠딩 니업', '맨몸운동', '서서 무릎을 교대로 가슴 쪽으로 들어올리는 유산소 운동', '초급'),
  (3, '스쿼트', '맨몸운동', '하체 근력을 강화하는 기본 운동', '초급');

-- updated_at 자동 업데이트 트리거
CREATE OR REPLACE FUNCTION update_exercise_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_exercise_updated_at_trigger ON exercise;
CREATE TRIGGER update_exercise_updated_at_trigger
  BEFORE UPDATE ON exercise
  FOR EACH ROW
  EXECUTE FUNCTION update_exercise_updated_at();

-- 권한 설정
GRANT SELECT ON exercise TO anon, authenticated;
GRANT INSERT, UPDATE, DELETE ON exercise TO authenticated;

-- RLS 정책 설정
ALTER TABLE exercise ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "exercise_select_policy" ON exercise;
CREATE POLICY "exercise_select_policy"
  ON exercise
  FOR SELECT
  USING (true);

-- 데이터 확인
SELECT exercise_id, name, description FROM exercise ORDER BY exercise_id;





