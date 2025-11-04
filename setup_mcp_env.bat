@echo off
REM MCP Supabase 환경 변수 설정 스크립트
REM 이 스크립트를 관리자 권한으로 실행하세요

echo ========================================
echo MCP Supabase 환경 변수 설정
echo ========================================
echo.

REM 현재 사용자 환경 변수 설정
setx SUPABASE_URL "https://wkmnnzndtggrlrzjlncn.supabase.co"
setx SUPABASE_ANON_KEY "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndrbW5uem5kdGdncmxyempsbmNuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjExODU1NDIsImV4cCI6MjA3Njc2MTU0Mn0.bd9pcs-4YDyL98YcKhBzq53u2CONtjUv7NdYEcDA-eU"

echo.
echo 환경 변수가 설정되었습니다!
echo.
echo 다음 단계:
echo 1. Cursor를 완전히 종료하세요
echo 2. Cursor를 다시 실행하세요
echo 3. MCP 연결이 정상적으로 작동하는지 확인하세요
echo.
pause





