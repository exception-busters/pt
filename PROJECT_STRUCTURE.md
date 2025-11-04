# 프로젝트 구조 문서 📚

## 📁 프로젝트 개요
**Pose Detection App** - ML Kit 기반 실시간 운동 자세 교정 애플리케이션

### 핵심 기능
- 📹 실시간 카메라 포즈 감지 (ML Kit)
- 🎯 운동별 자세 평가 및 점수 산정
- 💬 실시간 피드백 제공
- 📊 운동 단계별 진행 관리
- 🎨 시각적 스켈레톤 오버레이 (각도별 색상 구분)
- 🔄 2단계 스무딩 시스템 (떨림 보정)

---

## 📂 파일 구조

```
lib/
├── main.dart                           # 엔트리 포인트
├── app.dart                            # ExerciseApp (MaterialApp 설정)
│
├── screens/
│   └── exercise_screen.dart            # 메인 운동 화면
│
├── models/
│   └── exercise_model.dart             # 운동 데이터 모델
│
├── services/
│   ├── exercise_loader.dart            # JSON 로더
│   ├── pose_scorer.dart                # 점수 계산
│   ├── feedback_generator.dart         # 피드백 생성
│   ├── phase_manager.dart              # 단계 관리
│   ├── angle_smoother.dart             # 각도 스무딩 (2차)
│   └── landmark_smoother.dart          # 랜드마크 스무딩 (1차)
│
├── widgets/
│   ├── exercise_dropdown.dart          # 운동 선택
│   ├── phase_progress_widget.dart      # 단계 진행 표시
│   ├── compact_score_display.dart      # 점수 표시
│   ├── collapsible_feedback_panel.dart # 피드백 패널
│   └── angle_legend_widget.dart        # 각도 색상 범례
│
├── angle_calculator.dart               # 각도 계산 유틸
└── pose_painter.dart                   # 스켈레톤 렌더링
```

---

## 🔑 핵심 클래스 및 함수

### 1. **ExerciseScreen** (screens/exercise_screen.dart)
메인 화면 - 카메라 + 포즈 감지 + 피드백

**주요 함수**:
- `initState()`: 초기화 (카메라, 포즈 감지기, 스무더)
- `_processCameraImage()`: 실시간 포즈 처리
- `_updateFeedback()`: 점수 및 피드백 생성
- `_calculateUserAngles()`: 사용자 각도 계산 + 스무딩
- `_getLandmark()`: 랜드마크 매핑 (복합 랜드마크 계산)

### 2. **PosePainter** (pose_painter.dart)
스켈레톤 렌더링

**주요 함수**:
- `paint()`: 캔버스에 스켈레톤 그리기
- `_drawBaseSkeleton()`: 기본 스켈레톤
- `_drawAngleHighlights()`: 각도별 색상 강조
- `_angleColors`: 각도 키 → 색상 매핑 (22개 각도)

### 3. **Services**

#### AngleSmoother (2차 스무딩)
- `smoothAngleAdaptive()`: 적응형 EMA 필터

#### LandmarkSmoother (1차 스무딩)
- `smoothPose()`: 전체 포즈 스무딩
- 임계값 필터 (4px) + EMA (alpha=0.25)

#### PoseScorer
- `calculateScore()`: 전체 점수 (가중 평균)
- `calculateDetailedScores()`: 각도별 점수
- 후한 점수 시스템 (tolerance × 3까지)

#### PhaseManager
- `update()`: 단계 진행 관리
- `checkConditions()`: 조건 확인
- `reset()`: 초기화

---

## 🔄 데이터 흐름

```
카메라 이미지
  ↓
ML Kit 포즈 감지
  ↓
[1차] LandmarkSmoother
  ↓
UI 렌더링 (PosePainter)
  ↓
각도 계산
  ↓
[2차] AngleSmoother
  ↓
PoseScorer → FeedbackGenerator → PhaseManager
  ↓
UI 업데이트 (ValueNotifier)
```

---

## 🎯 핵심 알고리즘

### 2단계 스무딩
```
원본 좌표
  → LandmarkSmoother (EMA + 임계값 필터)
  → 각도 계산
  → AngleSmoother (적응형 EMA)
  → 안정적인 각도
```

### 점수 계산
```dart
angleDiff = |userAngle - idealMean|

if (angleDiff ≤ tolerance): 100점
else if (angleDiff ≤ tolerance × 2): 50-100점 (sqrt 곡선)
else if (angleDiff ≤ tolerance × 3): 10-50점
else: 10점 (최소)

totalScore = Σ(score_i × weight_i) / Σ(weight_i)
```

---

## ⚡ 성능 최적화

1. **적응형 프레임 레이트**: 30fps → 15fps (CPU 50% 감소)
2. **ValueNotifier**: 변경된 위젯만 리빌드
3. **Static Final 캐싱**: 색상 맵 재생성 방지
4. **저해상도 카메라**: ResolutionPreset.low

---

## 🛠️ 기술 스택

- **Flutter** 3.x
- **ML Kit Pose Detection**
- **Camera** 패키지
- **ValueNotifier** (상태 관리)

---

## 📝 리팩토링 변경사항 (v2.0)

### 이전 구조
```
lib/
├── main.dart        # 모든 로직 포함 (691줄)
└── exercise.dart    # 백업
```

### 현재 구조 (충돌 최소화)
```
lib/
├── main.dart                    # 엔트리 포인트만 (5줄)
├── app.dart                     # MaterialApp 설정 (17줄)
└── screens/
    └── exercise_screen.dart     # 메인 화면 (569줄)
```

### 장점
✅ **충돌 최소화**: main.dart가 매우 단순해짐  
✅ **모듈화**: 각 파일의 책임이 명확  
✅ **유지보수**: 코드 찾기 쉬움  
✅ **확장성**: 새 화면 추가 용이

---
