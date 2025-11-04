# 🗑️ 파일 삭제 가이드

## ⚠️ 삭제 전 필수 작업
```bash
# 1. Git 커밋 (백업)
git add .
git commit -m "최적화 전 백업"

# 2. 브랜치 생성 (안전)
git checkout -b cleanup
```

---

## 📝 삭제 명령어 모음

### 1단계: 미사용 Dart 파일 삭제
```powershell
# 2개 파일 삭제
Remove-Item lib\widgets\feedback_panel.dart
Remove-Item lib\widgets\score_display.dart
```

### 2단계: 중복/구버전 문서 삭제
```powershell
# 8개 문서 삭제
Remove-Item COLOR_MAPPING_FIX.md
Remove-Item EXERCISE_08_README.md
Remove-Item FINAL_5_EXERCISES.md
Remove-Item OPTIMIZATION_COMPLETE.md
Remove-Item OPTIMIZATION_REPORT_V2.md
Remove-Item FINAL_OPTIMIZATION_REPORT.md
Remove-Item REFACTORING_SUMMARY.md
Remove-Item SMOOTHING_ENHANCEMENT_SUMMARY.md
```

### 3단계: 검증
```bash
flutter analyze
```

---

## 📊 삭제 후 파일 구조

### 최종 문서 (6개)
```
✅ README.md                       # 프로젝트 소개
✅ PROJECT_STRUCTURE.md            # 프로젝트 구조
✅ PROJECT_GUIDE.md                # 프로젝트 가이드
✅ PT_POSE_DATA_GUIDE.md           # 데이터 가이드
✅ FINAL_OPTIMIZATION_GUIDE.md     # 최종 최적화 가이드
✅ UNUSED_CODE_ANALYSIS.md         # 미사용 코드 분석
✅ OPTIMIZATION_SUMMARY.md         # 최적화 요약
✅ DELETE_GUIDE.md                 # 이 문서
```

### Dart 파일 (17개)
```
lib/
├── main.dart                           ✅
├── app.dart                            ✅
├── angle_calculator.dart               ✅
├── pose_painter.dart                   ✅
├── models/
│   └── exercise_model.dart             ✅
├── screens/
│   └── exercise_screen.dart            ✅
├── services/ (6개)
│   ├── angle_smoother.dart             ✅
│   ├── landmark_smoother.dart          ✅
│   ├── exercise_loader.dart            ✅
│   ├── feedback_generator.dart         ✅
│   ├── phase_manager.dart              ✅
│   └── pose_scorer.dart                ✅
└── widgets/ (5개)
    ├── angle_legend_widget.dart        ✅
    ├── collapsible_feedback_panel.dart ✅
    ├── compact_score_display.dart      ✅
    ├── exercise_dropdown.dart          ✅
    └── phase_progress_widget.dart      ✅
```

---

## 🎯 예상 효과

| 항목 | 현재 | 삭제 후 | 감소 |
|------|------|---------|------|
| 문서 파일 | 15개 | 8개 | -7개 (47%) |
| Dart 파일 | 19개 | 17개 | -2개 (11%) |
| 총 파일 | 34개 | 25개 | -9개 (26%) |

---

## ⚠️ 주의: 코드 내부 함수 정리 (선택)

### 수동 삭제 필요 (파일 편집)

#### lib/angle_calculator.dart
- **삭제**: `calculateAngle2D()` 함수 (58~78 라인)

#### lib/services/angle_smoother.dart
- **삭제**: 
  - `smoothAngle()` (15~42 라인)
  - `smoothAngleWeighted()` (46~79 라인)
  - `smoothAngleMedian()` (105~134 라인)
  - `getBufferState()` (176~180 라인)
  - `AngleSmootherFactory` 클래스 (202~236 라인)
  - `SmoothingType` enum (184~199 라인)

#### lib/services/feedback_generator.dart
- **삭제**: `getScoreColor()` 함수 (114~120 라인)

**참고**: `UNUSED_CODE_ANALYSIS.md` 참조

---

## ✅ 삭제 후 체크리스트

```bash
# 1. 분석
flutter analyze

# 2. 테스트 (있는 경우)
flutter test

# 3. 빌드
flutter build apk --release

# 4. 실행 테스트
flutter run
```

---

## 🔄 복구 방법 (필요 시)

```bash
# Git 커밋 이전으로 되돌리기
git reset --hard HEAD~1

# 또는 특정 파일만 복구
git checkout HEAD -- lib/widgets/feedback_panel.dart
```

---

**작성일**: 2025-11-04  
**권장**: 한 번에 모든 파일 삭제 (일관성 유지)

