# 떨림 보정 강화 요약 📊

## 개요
스켈레톤이 과도하게 떨리는 현상을 해결하기 위해 **2단계 스무딩** 시스템을 구현했습니다.

## 문제점
- 스켈레톤이 화면에서 과도하게 떨리는 현상
- 기존 각도 스무딩만으로는 시각적 안정성 부족
- 랜드마크 좌표 자체의 미세한 떨림이 누적됨

## 해결 방법

### 1️⃣ 랜드마크 좌표 스무딩 (새로 추가)

**파일**: `lib/services/landmark_smoother.dart`

#### 주요 기능
- **Exponential Moving Average (EMA)** 사용
- **임계값 기반 필터링**: 미세한 떨림(4픽셀 이하) 무시
- **자연스러운 움직임 유지**: 큰 움직임은 빠르게 반응

#### 핵심 파라미터
```dart
LandmarkSmoother(
  alpha: 0.25,  // 낮은 값 = 더 부드러움 (25% 새 값, 75% 이전 값)
  movementThreshold: 4.0,  // 4픽셀 이하 움직임 무시
);
```

#### 작동 원리
1. **임계값 필터링**: 움직임이 4픽셀 미만이면 이전 값 유지
2. **EMA 적용**: 임계값 초과 시 부드러운 전환
   ```
   smoothed = 0.25 × current + 0.75 × previous
   ```
3. **3D 좌표 모두 처리**: x, y, z 좌표 모두 스무딩

### 2️⃣ 각도 스무딩 강화 (기존 개선)

**파일**: `lib/services/angle_smoother.dart`

#### 개선 사항
1. **윈도우 크기 증가**: 5 → 7 프레임
2. **적응형 필터 임계값 조정**: 10.0° → 5.0°
3. **알파 값 최적화**:
   - 큰 변화: 0.7 → 0.6 (조금 더 부드럽게)
   - 작은 변화: 0.2 → 0.15 (더 부드럽게)

```dart
AngleSmoother(windowSize: 7);  // 기본값 증가

// 적응형 필터
threshold: 5.0  // 더 민감하게 반응
alpha: change > threshold ? 0.6 : 0.15  // 더 부드러운 스무딩
```

### 3️⃣ 통합 적용

**파일**: `lib/main.dart`

#### 초기화
```dart
@override
void initState() {
  super.initState();
  _angleSmoother = AngleSmoother(windowSize: 7);
  _landmarkSmoother = LandmarkSmoother(
    alpha: 0.25,
    movementThreshold: 4.0,
  );
  ...
}
```

#### 처리 순서
```dart
// 1. 포즈 감지
final poses = await _poseDetector.processImage(inputImage);

// 2. 랜드마크 좌표 스무딩 (먼저)
final smoothedPoses = poses.map((pose) => 
  _landmarkSmoother.smoothPose(pose)
).toList();

// 3. UI 업데이트 (스무딩된 좌표 사용)
setState(() {
  _poses = smoothedPoses;
});

// 4. 각도 계산 시 추가 스무딩
final smoothedAngle = _angleSmoother.smoothAngleAdaptive(
  angleKey, 
  rawAngle
);
```

#### 버퍼 관리
```dart
void _onExerciseSelected(String exerciseId) {
  // 운동 변경 시 모든 버퍼 초기화
  _angleSmoother.resetAll();
  _landmarkSmoother.resetAll();
  ...
}
```

## 기술적 특징

### 🎯 2단계 스무딩
1. **1단계 (랜드마크)**: 원본 좌표의 떨림 제거
2. **2단계 (각도)**: 계산된 각도의 변동 완화

### 📊 적응형 알고리즘
- **작은 움직임**: 강한 스무딩 (떨림 제거)
- **큰 움직임**: 약한 스무딩 (반응성 유지)

### 🎨 시각적 안정성
- 임계값 필터로 미세한 떨림 차단
- EMA로 자연스러운 전환
- 부드러운 스켈레톤 렌더링

## 성능 영향

### ✅ 장점
- 시각적으로 훨씬 부드러운 스켈레톤
- 미세한 떨림 효과적으로 제거
- 여전히 빠른 반응성 유지

### ⚖️ 트레이드오프
- 약간의 추가 메모리 사용 (버퍼 2개)
- 미세한 지연 (1-2 프레임, 거의 감지 불가)
- 매우 빠른 움직임은 약간 부드럽게 처리됨

## 파라미터 튜닝 가이드

### 더 부드럽게 하고 싶다면
```dart
LandmarkSmoother(
  alpha: 0.15,  // 낮춤 (0.25 → 0.15)
  movementThreshold: 5.0,  // 높임 (4.0 → 5.0)
)

AngleSmoother(windowSize: 9)  // 높임 (7 → 9)
```

### 더 반응적으로 하고 싶다면
```dart
LandmarkSmoother(
  alpha: 0.35,  // 높임 (0.25 → 0.35)
  movementThreshold: 3.0,  // 낮춤 (4.0 → 3.0)
)

AngleSmoother(windowSize: 5)  // 낮춤 (7 → 5)
```

## 변경된 파일

### 신규 파일
- ✅ `lib/services/landmark_smoother.dart`
- ✅ `SMOOTHING_ENHANCEMENT_SUMMARY.md` (이 파일)

### 수정된 파일
- ✅ `lib/services/angle_smoother.dart`
  - 윈도우 크기: 5 → 7
  - 적응형 임계값: 10.0 → 5.0
  - 알파 값 최적화: (0.7, 0.2) → (0.6, 0.15)
  
- ✅ `lib/main.dart`
  - `LandmarkSmoother` import 및 초기화
  - 포즈 처리에 랜드마크 스무딩 적용
  - 운동 변경 시 양쪽 버퍼 초기화

## 테스트 권장사항

### 확인 사항
1. ✅ 스켈레톤이 부드럽게 움직이는가?
2. ✅ 미세한 떨림이 줄어들었는가?
3. ✅ 빠른 움직임에도 잘 반응하는가?
4. ✅ 운동 전환이 부드럽게 되는가?

### 조정이 필요한 경우
- **떨림이 여전히 있음** → `alpha`를 낮추거나 `windowSize`를 높이기
- **반응이 너무 느림** → `alpha`를 높이거나 `windowSize`를 낮추기
- **작은 움직임이 무시됨** → `movementThreshold`를 낮추기
- **너무 민감함** → `movementThreshold`를 높이기

## 향후 개선 가능성

### 고급 필터링
- Kalman Filter 적용 (예측 기반 스무딩)
- 주파수 기반 필터링 (FFT)
- 머신러닝 기반 노이즈 제거

### 적응형 파라미터
- 운동 종류에 따른 자동 조정
- 움직임 속도에 따른 동적 임계값
- 사용자 맞춤형 스무딩 강도

## 결론
**2단계 스무딩 시스템**으로 스켈레톤의 떨림을 효과적으로 제거하면서도 반응성을 유지했습니다. 사용자는 훨씬 부드럽고 안정적인 피드백을 경험할 수 있습니다. 🎉

