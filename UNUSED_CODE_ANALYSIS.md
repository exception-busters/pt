# 🗑️ 사용되지 않는 코드 분석 보고서

## 📅 분석 일자
2025-11-04

---

## 🎯 분석 목적
프로젝트를 최대한 경량화하기 위해 사용되지 않는 파일, 함수, 클래스를 식별

---

## ❌ 삭제 가능 항목

### 1. 전체 파일 (미사용)

#### `lib/widgets/feedback_panel.dart` ❌
- **이유**: `CollapsibleFeedbackPanel`로 완전히 대체됨
- **사용처**: 없음 (exercise_screen.dart에서 CollapsibleFeedbackPanel 사용)
- **크기**: ~95 lines
- **권장**: 삭제

#### `lib/widgets/score_display.dart` ❌
- **이유**: `CompactScoreDisplay`로 완전히 대체됨
- **사용처**: 없음 (exercise_screen.dart에서 CompactScoreDisplay 사용)
- **크기**: ~119 lines
- **권장**: 삭제

---

### 2. 함수 (부분 미사용)

#### `lib/angle_calculator.dart`

##### `calculateAngle2D()` ❌
```dart
static double calculateAngle2D(
  PoseLandmark point1,
  PoseLandmark point2,
  PoseLandmark point3,
)
```
- **이유**: 2D 각도 계산은 사용되지 않음 (3D만 사용)
- **사용처**: 없음 (exercise_screen.dart에서 `calculateAngle` (3D) 사용)
- **크기**: ~22 lines
- **권장**: 삭제

---

#### `lib/services/angle_smoother.dart`

##### `smoothAngle()` ❌
```dart
double smoothAngle(String angleKey, double angle)
```
- **이유**: 단순 이동 평균은 사용되지 않음
- **사용처**: 없음 (exercise_screen.dart에서 `smoothAngleAdaptive` 사용)
- **권장**: 삭제

##### `smoothAngleWeighted()` ❌
```dart
double smoothAngleWeighted(String angleKey, double angle)
```
- **이유**: 가중 이동 평균은 사용되지 않음
- **사용처**: 없음
- **권장**: 삭제

##### `smoothAngleMedian()` ❌
```dart
double smoothAngleMedian(String angleKey, double angle)
```
- **이유**: 미디안 필터는 사용되지 않음
- **사용처**: 없음
- **권장**: 삭제

##### `smoothAngleExponential()` ⚠️
```dart
double smoothAngleExponential(
  String angleKey,
  double angle, {
  double alpha = 0.3,
})
```
- **이유**: 외부에서 직접 호출 안 됨
- **사용처**: `smoothAngleAdaptive` 내부에서만 사용
- **권장**: **유지** (내부적으로 필요)

##### `getBufferState()` ❌
```dart
Map<String, List<double>> getBufferState()
```
- **이유**: 디버깅용, 실제 사용 안 됨
- **사용처**: 없음
- **권장**: 삭제

---

### 3. 클래스 및 Enum (전체 미사용)

#### `AngleSmootherFactory` ❌
```dart
class AngleSmootherFactory {
  static double applySmoothing(...) { ... }
}
```
- **이유**: 팩토리 패턴이 사용되지 않음
- **사용처**: 없음
- **크기**: ~35 lines
- **권장**: 삭제

#### `SmoothingType` enum ❌
```dart
enum SmoothingType {
  simple, weighted, exponential, median, adaptive,
}
```
- **이유**: AngleSmootherFactory와 함께 미사용
- **사용처**: 없음
- **권장**: 삭제

---

#### `lib/services/feedback_generator.dart`

##### `getScoreColor()` ❌
```dart
static String getScoreColor(double score)
```
- **이유**: 각 위젯에서 자체 `_getScoreColor` 구현
- **사용처**: 없음 (CompactScoreDisplay와 ScoreDisplay가 자체 구현)
- **권장**: 삭제

---

### 4. 문서 (중복)

#### 삭제 가능 문서 목록
1. ❌ `EXERCISE_08_README.md` - v1.1 변경사항, FINAL_OPTIMIZATION에 통합 가능
2. ❌ `SMOOTHING_ENHANCEMENT_SUMMARY.md` - 스무딩 개선 내역, 통합 가능
3. ❌ `COLOR_MAPPING_FIX.md` - 색상 매핑 수정, 통합 가능
4. ❌ `FINAL_5_EXERCISES.md` - 최종 5개 운동, PROJECT_STRUCTURE에 통합 가능
5. ❌ `OPTIMIZATION_COMPLETE.md` - 최적화 완료 보고서, 통합 예정
6. ❌ `OPTIMIZATION_REPORT_V2.md` - 최적화 v2.0, 통합 예정
7. ❌ `FINAL_OPTIMIZATION_REPORT.md` - 최적화 보고서, 통합 예정
8. ❌ `REFACTORING_SUMMARY.md` - 리팩토링 내역, PROJECT_STRUCTURE에 통합 가능

#### 유지 문서
- ✅ `PROJECT_STRUCTURE.md` - 프로젝트 구조 (핵심)
- ✅ `PT_POSE_DATA_GUIDE.md` - 데이터 가이드 (핵심)
- ✅ `README.md` - 프로젝트 소개 (필수)

---

## 📊 예상 효과

### 삭제 시 경량화 효과
| 항목 | 현재 | 삭제 후 | 감소 |
|------|------|---------|------|
| **Dart 파일 수** | 19개 | 17개 | -2개 |
| **코드 라인 수** | ~3000+ | ~2700+ | -10% |
| **MD 문서 수** | 12개 | 4개 | -8개 |
| **총 파일 수** | 31개 | 21개 | -32% |

### 구체적 절감
- **Dart 코드**: 약 300 라인 삭제
- **문서**: 약 1500 라인 삭제
- **빌드 시간**: 약간 개선 (~1-2초)
- **유지보수성**: 크게 향상 (코드 복잡도 감소)

---

## ⚠️ 주의사항

### 유지 필요 항목

#### `smoothAngleExponential()` ✅
- `smoothAngleAdaptive()`의 내부 의존성
- 삭제 시 적응형 필터 작동 불가
- **권장**: 유지하되 `private`으로 변경

---

## 🔄 삭제 절차 권장 순서

### 1단계: 안전한 삭제 (즉시 가능)
```bash
# 미사용 위젯 파일
rm lib/widgets/feedback_panel.dart
rm lib/widgets/score_display.dart
```

### 2단계: 함수 정리 (리팩토링)
1. `angle_calculator.dart`에서 `calculateAngle2D` 삭제
2. `angle_smoother.dart`에서 다음 삭제:
   - `smoothAngle()`
   - `smoothAngleWeighted()`
   - `smoothAngleMedian()`
   - `getBufferState()`
   - `AngleSmootherFactory` 클래스
   - `SmoothingType` enum
3. `smoothAngleExponential()`을 `_smoothAngleExponential()`로 변경 (private)

### 3단계: 문서 통합 (이 보고서 다음)
1. 세 개의 최적화 문서를 하나로 통합
2. 중복 문서 8개 삭제
3. 최종 문서 4개만 유지

---

## 📝 삭제 전 체크리스트

### 필수 확인 사항
- [ ] `flutter analyze` 오류 없음
- [ ] 기존 기능 모두 정상 작동
- [ ] 빌드 성공 (`flutter build apk`)
- [ ] 실제 디바이스에서 테스트 완료

### 선택 확인 사항
- [ ] Git 커밋 백업
- [ ] 삭제된 코드 별도 보관 (필요 시 복구용)

---

## 🎯 결론

### 삭제 권장
- **파일**: 2개 (feedback_panel.dart, score_display.dart)
- **함수**: 6개 (calculateAngle2D, smoothAngle 계열 4개, getBufferState)
- **클래스/Enum**: 2개 (AngleSmootherFactory, SmoothingType)
- **문서**: 8개 (중복 문서들)

### 유지 필요
- **함수**: 1개 (smoothAngleExponential - 내부 의존성)
- **문서**: 4개 (README, PROJECT_STRUCTURE, PT_POSE_DATA_GUIDE, 통합 최적화 문서)

### 예상 결과
- **32% 파일 감소**
- **10% 코드 감소**
- **유지보수성 크게 향상**
- **기능 손실 없음**

---

**작성자**: AI Assistant (Claude Sonnet 4.5)  
**분석 완료**: 2025-11-04  
**권장 조치**: 즉시 적용 가능 ✅

