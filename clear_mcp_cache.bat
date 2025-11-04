@echo off
echo ========================================
echo Cursor MCP 캐시 삭제 스크립트
echo ========================================
echo.
echo ⚠️  주의: Cursor를 완전히 종료한 후 실행하세요!
echo.
pause

set CURSOR_APPDATA=%APPDATA%\Cursor\User
set GLOBAL_STORAGE=%CURSOR_APPDATA%\globalStorage
set WORKSPACE_STORAGE=%CURSOR_APPDATA%\workspaceStorage

echo.
echo [1/3] Cursor 프로세스 확인 중...
tasklist | findstr /i "cursor.exe" >nul
if %errorlevel% == 0 (
    echo ⚠️  Cursor가 실행 중입니다!
    echo 작업 관리자에서 Cursor 프로세스를 모두 종료하고 다시 실행하세요.
    pause
    exit /b 1
)
echo ✅ Cursor가 종료되어 있습니다.

echo.
echo [2/3] globalStorage 폴더 확인 중...
if exist "%GLOBAL_STORAGE%" (
    echo 📁 globalStorage 경로: %GLOBAL_STORAGE%
    echo    MCP 관련 폴더를 검색 중...
    dir /b /ad "%GLOBAL_STORAGE%" | findstr /i "mcp" >nul
    if %errorlevel% == 0 (
        echo    MCP 관련 폴더 발견됨
    ) else (
        echo    MCP 관련 폴더를 직접 찾지 못했습니다
        echo    전체 globalStorage 폴더를 백업 후 삭제할 수 있습니다
    )
) else (
    echo ⚠️  globalStorage 폴더를 찾을 수 없습니다
)

echo.
echo [3/3] workspaceStorage 폴더 확인 중...
if exist "%WORKSPACE_STORAGE%" (
    echo 📁 workspaceStorage 경로: %WORKSPACE_STORAGE%
    echo    프로젝트별 캐시 폴더가 있습니다
) else (
    echo ⚠️  workspaceStorage 폴더를 찾을 수 없습니다
)

echo.
echo ========================================
echo 삭제 옵션
echo ========================================
echo.
echo 1. globalStorage 폴더 전체 삭제 (권장)
echo    - 모든 확장 프로그램의 전역 캐시가 삭제됩니다
echo    - Cursor 재시작 시 자동으로 재생성됩니다
echo.
echo 2. workspaceStorage 폴더 전체 삭제
echo    - 모든 프로젝트의 워크스페이스 캐시가 삭제됩니다
echo    - 프로젝트 열 때 다시 생성됩니다
echo.
echo 3. 둘 다 삭제 (완전 초기화)
echo.
echo 4. 취소
echo.
set /p choice="선택하세요 (1-4): "

if "%choice%"=="1" (
    echo.
    echo globalStorage 폴더를 삭제합니다...
    if exist "%GLOBAL_STORAGE%" (
        rd /s /q "%GLOBAL_STORAGE%"
        echo ✅ globalStorage 삭제 완료
    ) else (
        echo ⚠️  globalStorage 폴더가 없습니다
    )
)

if "%choice%"=="2" (
    echo.
    echo workspaceStorage 폴더를 삭제합니다...
    if exist "%WORKSPACE_STORAGE%" (
        rd /s /q "%WORKSPACE_STORAGE%"
        echo ✅ workspaceStorage 삭제 완료
    ) else (
        echo ⚠️  workspaceStorage 폴더가 없습니다
    )
)

if "%choice%"=="3" (
    echo.
    echo 모든 캐시를 삭제합니다...
    if exist "%GLOBAL_STORAGE%" (
        rd /s /q "%GLOBAL_STORAGE%"
        echo ✅ globalStorage 삭제 완료
    )
    if exist "%WORKSPACE_STORAGE%" (
        rd /s /q "%WORKSPACE_STORAGE%"
        echo ✅ workspaceStorage 삭제 완료
    )
)

if "%choice%"=="4" (
    echo 취소되었습니다.
    exit /b 0
)

echo.
echo ========================================
echo 다음 단계
echo ========================================
echo.
echo 1. Cursor를 다시 실행하세요
echo 2. MCP 연결 상태를 확인하세요
echo.
pause

