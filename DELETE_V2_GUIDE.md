# pose_detection_v2 삭제 가이드

## 삭제해도 되는 이유
- pose_detection_v2는 이전 프로젝트
- 현재 작업은 pose_detection_app에서만 진행
- Android Studio 인덱싱 부담 감소

## 삭제 방법

### 방법 1: 백업 후 삭제 (권장)
```powershell
# 백업
Move-Item pose_detection_app\pose_detection_v2 C:\temp\pose_detection_v2_backup

# 나중에 필요하면 복원
Move-Item C:\temp\pose_detection_v2_backup pose_detection_app\pose_detection_v2
```

### 방법 2: 완전 삭제
```powershell
Remove-Item -Recurse -Force pose_detection_app\pose_detection_v2
```

### 방법 3: 파일 탐색기에서
1. `pose_detection_app\pose_detection_v2` 폴더로 이동
2. 폴더 우클릭 → 삭제 (또는 잘라내기 → C:\temp에 붙여넣기)

## 삭제 후 확인
- Android Studio 재시작
- 오류 메시지에서 pose_detection_v2 관련 항목 사라짐
- 빌드/실행 속도 개선

## 현재 프로젝트 구조
```
motion-test/
  pose_detection_app/        ← 현재 작업 중
    lib/
      main.dart              ← 실행 파일
      pose_comparison_demo.dart
      angle_calculator.dart
      ...
    assets/
      pose_database.json
```



