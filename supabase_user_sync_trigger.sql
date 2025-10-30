-- Supabase Auth Users 자동 동기화 SQL 스크립트
-- 회원가입 시 auth.users 테이블의 데이터를 public.Users 테이블에 자동으로 복사

-- 1. 트리거 함수 생성
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  -- 중복 방지: 이미 존재하는 auth_user_id가 있는지 확인
  IF NOT EXISTS (
    SELECT 1 FROM public.Users WHERE auth_user_id = NEW.id
  ) THEN
    -- Users 테이블에 새 사용자 정보 삽입
    INSERT INTO public.Users (
      auth_user_id,
      email,
      nickname,
      join_date
    ) VALUES (
      NEW.id,                                    -- auth.users.id를 auth_user_id에 저장
      NEW.email,                                 -- auth.users.email
      COALESCE(NEW.raw_user_meta_data->>'display_name', '사용자'), -- display_name 또는 기본값
      NOW()                                      -- 현재 시간을 join_date에 저장
    );
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. 기존 트리거가 있다면 삭제
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- 3. 새 사용자 생성 시 트리거 설정
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 4. RLS (Row Level Security) 정책 설정 (선택사항)
-- Users 테이블에 RLS가 활성화되어 있다면 필요할 수 있습니다
ALTER TABLE public.Users ENABLE ROW LEVEL SECURITY;

-- 사용자가 자신의 데이터만 볼 수 있도록 정책 생성
CREATE POLICY "Users can view own profile" ON public.Users
  FOR SELECT USING (auth.uid() = auth_user_id);

-- 사용자가 자신의 데이터만 업데이트할 수 있도록 정책 생성
CREATE POLICY "Users can update own profile" ON public.Users
  FOR UPDATE USING (auth.uid() = auth_user_id);

-- 트리거 함수가 Users 테이블에 INSERT할 수 있도록 정책 생성
CREATE POLICY "Enable insert for authenticated users only" ON public.Users
  FOR INSERT WITH CHECK (true);

-- 5. 테스트용 쿼리 (실행 후 확인용)
-- SELECT * FROM public.Users ORDER BY join_date DESC LIMIT 5;

-- 6. 트리거 상태 확인 쿼리
-- SELECT * FROM information_schema.triggers WHERE trigger_name = 'on_auth_user_created';

COMMENT ON FUNCTION public.handle_new_user() IS '새 사용자 가입 시 auth.users 데이터를 public.Users 테이블에 자동 동기화';
COMMENT ON TRIGGER on_auth_user_created ON auth.users IS 'auth.users INSERT 시 public.Users 테이블에 자동으로 사용자 정보 복사';