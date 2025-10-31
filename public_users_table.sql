-- public.users 테이블 생성 SQL
-- auth.users와 연동하여 사용자 정보를 저장하는 테이블

-- 기존 테이블이 있다면 삭제 (개발 환경에서만 사용)
-- DROP TABLE IF EXISTS public.users CASCADE;

-- public.users 테이블 생성
CREATE TABLE IF NOT EXISTS public.users (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email VARCHAR(255) NOT NULL,
    nickname VARCHAR(50) NOT NULL,
    join_date TIMESTAMP DEFAULT NOW()
);

-- 인덱스 생성
CREATE INDEX IF NOT EXISTS idx_users_email ON public.users(email);
CREATE INDEX IF NOT EXISTS idx_users_nickname ON public.users(nickname);

-- RLS (Row Level Security) 활성화
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- 기존 정책 삭제 (있다면)
DROP POLICY IF EXISTS "Users can view own profile" ON public.users;
DROP POLICY IF EXISTS "Users can update own profile" ON public.users;
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON public.users;

-- 사용자가 자신의 데이터만 볼 수 있도록 정책 생성
CREATE POLICY "Users can view own profile" ON public.users
  FOR SELECT USING (auth.uid() = user_id);

-- 사용자가 자신의 데이터만 업데이트할 수 있도록 정책 생성
CREATE POLICY "Users can update own profile" ON public.users
  FOR UPDATE USING (auth.uid() = user_id);

-- 회원가입 시 INSERT 허용 정책
CREATE POLICY "Enable insert for authenticated users only" ON public.users
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- 테이블 코멘트
COMMENT ON TABLE public.users IS '사용자 기본 정보 테이블 (auth.users와 연동)';
COMMENT ON COLUMN public.users.user_id IS 'auth.users.id 참조 (UUID 타입)';
COMMENT ON COLUMN public.users.email IS '사용자 이메일';
COMMENT ON COLUMN public.users.nickname IS '사용자 닉네임';
COMMENT ON COLUMN public.users.join_date IS '가입일시';

-- 테스트용 쿼리 (실행 후 확인용)
-- SELECT column_name, data_type, is_nullable 
-- FROM information_schema.columns 
-- WHERE table_name = 'users' AND table_schema = 'public';