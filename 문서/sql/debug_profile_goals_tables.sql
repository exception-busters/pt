-- 현재 테이블 상태 확인 및 문제 해결 SQL

-- 1. 현재 테이블 구조 확인
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name IN ('workoutgoal', 'dietgoal')
ORDER BY table_name, ordinal_position;

-- 2. 제약조건 확인
SELECT 
    tc.table_name,
    tc.constraint_name,
    tc.constraint_type,
    kcu.column_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu 
    ON tc.constraint_name = kcu.constraint_name
WHERE tc.table_name IN ('workoutgoal', 'dietgoal');

-- 3. 현재 데이터 확인 (중복 확인)
SELECT 'workoutgoal' as table_name, user_id, COUNT(*) as count
FROM public.workoutgoal 
GROUP BY user_id 
HAVING COUNT(*) > 1
UNION ALL
SELECT 'dietgoal' as table_name, user_id, COUNT(*) as count
FROM public.dietgoal 
GROUP BY user_id 
HAVING COUNT(*) > 1;

-- 4. 전체 데이터 개수 확인
SELECT 
    'workoutgoal' as table_name, 
    COUNT(*) as total_rows,
    COUNT(DISTINCT user_id) as unique_users
FROM public.workoutgoal
UNION ALL
SELECT 
    'dietgoal' as table_name, 
    COUNT(*) as total_rows,
    COUNT(DISTINCT user_id) as unique_users
FROM public.dietgoal;