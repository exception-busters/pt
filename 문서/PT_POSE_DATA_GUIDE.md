# 🎯 PT Pose Data 활용 가이드

## 📋 목차
1. [데이터 구조 분석](#데이터-구조-분석)
2. [운동 코드 체계](#운동-코드-체계)
3. [JSON 데이터 형식](#json-데이터-형식)
4. [정답 데이터 추출 전략](#정답-데이터-추출-전략)
5. [실시간 비교 로직](#실시간-비교-로직)
6. [구현 계획](#구현-계획)

---

## 데이터 구조 분석

### 폴더 구조
```
PT-Pose-Data/
├── Document/
│   └── Data_Naming_Convention/
│       └── PT_Pose_Data_Naming_Convention.xlsx  # 운동 코드 매핑 테이블
│
└── PT_Pose/
    ├── 1.Training/           # 학습 데이터
    │   └── Labeling/
    │       ├── 맨몸운동_Labeling_new_220128/
    │       │   ├── 맨몸운동_01/  # 스탠딩 사이드 크런치
    │       │   ├── 맨몸운동_02/
    │       │   └── ...
    │       └── 바벨_덤벨_Labeling_new_220128/
    │           ├── 바벨_덤벨_01/
    │           └── ...
    │
    └── 2.Validation/         # 검증 데이터
        └── 라벨링데이터/
            ├── body_01/      # 맨몸운동 검증
            ├── babel_01/     # 바벨/덤벨 검증
            └── furniture_01/ # 기구 운동 검증
```

---

## 운동 코드 체계

### 운동 분류 체계 (Data_Naming_Convention 기준)

#### 1. 운동 상태 (3자리)
- `001`: 운동 (Training/Validation 데이터)

#### 2. 운동 종류 (1자리)
| 코드 | 분류 | 경로 |
|------|------|------|
| 1 | 맨몸 운동 | `맨몸운동_Labeling_new_220128/맨몸운동_XX` |
| 2 | 바벨/덤벨 | `바벨_덤벨_Labeling_new_220128/바벨_덤벨_XX` |
| 3 | 기구 | (추후 확장) |

#### 3. 자세 (1자리)
- `1`: 선 자세
- `2`: 누운 자세
- `3`: 앉은 자세

#### 4. 운동형 (2자리)
- `01`: 스탠딩 사이드 크런치 ⭐ **(구현 완료 - 선정)**
- `02`: 스탠딩 니업 ⭐ **(구현 완료 - 선정)**
- `03`: 스쿼트 ⭐ **(구현 완료 - 선정)**
- `04`: 스탠딩 프론트 다이나믹 런지 ❌ (제외됨 - 중급 난이도)
- `05`: 스탠딩 백워드 다이나믹 런지 ❌ (제외됨 - 04번과 중복)
- `06`: 스탠딩 암 서클 ❌ (제외됨 - 측정 어려움)
- `07`: 스탠딩 레그 스윙 ❌ (제외됨 - 측정 어려움)
- `08`: 굿모닝 (Good Morning) ❌ (제외됨 - 중급 난이도)
- ... (더 많은 운동)

### 운동 01번 상세 정보
```
정식명칭: 001-1-1-01 (스탠딩 사이드 크런치)
- 운동 상태: 001 (운동)
- 운동 종류: 1 (맨몸 운동)
- 자세: 1 (선 자세)
- 운동형: 01 (스탠딩 사이드 크런치)

데이터 경로:
- Training: PT-Pose-Data/PT_Pose/1.Training/Labeling/맨몸운동_Labeling_new_220128/맨몸운동_01/
- Validation: PT-Pose-Data/PT_Pose/2.Validation/라벨링데이터/body_01/
```

---

## JSON 데이터 형식

### 파일 네이밍
```
D05-8-001.json       # 2D 포즈 데이터
D05-8-001-3d.json    # 3D 포즈 데이터 (사용 권장)
```

### 3D JSON 구조
```json
{
  "frames": [
    {
      "pts": {
        "Nose": {"x": -1.34, "y": 174.27, "z": 9.66},
        "Left Eye": {"x": 2.38, "y": 176.85, "z": 9.18},
        "Right Eye": {"x": -4.17, "y": 177.11, "z": 8.26},
        "Left Ear": {"x": 8.17, "y": 174.28, "z": 0.75},
        "Right Ear": {"x": -6.42, "y": 174.40, "z": -1.91},
        "Left Shoulder": {"x": 21.27, "y": 155.13, "z": -3.68},
        "Right Shoulder": {"x": -19.30, "y": 155.68, "z": -4.45},
        "Left Elbow": {"x": 38.71, "y": 156.54, "z": -0.23},
        "Right Elbow": {"x": -44.62, "y": 161.65, "z": 3.69},
        "Left Wrist": {"x": 21.51, "y": 161.81, "z": 5.19},
        "Right Wrist": {"x": -21.52, "y": 166.10, "z": 3.20},
        "Left Hip": {"x": 12.23, "y": 106.32, "z": -2.22},
        "Right Hip": {"x": -10.95, "y": 105.92, "z": -2.13},
        "Left Knee": {"x": 12.09, "y": 57.97, "z": -4.44},
        "Right Knee": {"x": -8.22, "y": 57.01, "z": -5.00},
        "Left Ankle": {"x": 10.62, "y": 16.87, "z": -8.41},
        "Right Ankle": {"x": -6.60, "y": 15.95, "z": -9.69},
        "Neck": {"x": 0.71, "y": 165.87, "z": -1.84},
        "Left Palm": {"x": 14.62, "y": 162.56, "z": 5.30},
        "Right Palm": {"x": -14.17, "y": 167.23, "z": 2.20},
        "Back": {"x": 0.90, "y": 148.05, "z": -3.18},
        "Waist": {"x": 0.62, "y": 119.89, "z": -2.94},
        "Left Foot": {"x": 11.71, "y": 10.34, "z": -2.23},
        "Right Foot": {"x": -9.47, "y": 9.19, "z": -2.35}
      }
    },
    // ... 더 많은 프레임
  ]
}
```

### 랜드마크 포인트 (총 25개)
```dart
- Nose               (코)
- Left/Right Eye     (양쪽 눈)
- Left/Right Ear     (양쪽 귀)
- Left/Right Shoulder (양쪽 어깨) ⭐
- Left/Right Elbow   (양쪽 팔꿈치) ⭐
- Left/Right Wrist   (양쪽 손목) ⭐
- Left/Right Palm    (양쪽 손바닥)
- Left/Right Hip     (양쪽 엉덩이) ⭐⭐
- Left/Right Knee    (양쪽 무릎) ⭐⭐
- Left/Right Ankle   (양쪽 발목) ⭐⭐
- Left/Right Foot    (양쪽 발)
- Neck               (목)
- Back               (등)
- Waist              (허리) ⭐
```
⭐⭐ = 주요 관절 (각도 계산에 핵심)
⭐ = 보조 관절

---

## 정답 데이터 추출 전략

### 1. 데이터 선정 기준

#### Training 데이터 활용
```
경로: PT-Pose-Data/PT_Pose/1.Training/Labeling/맨몸운동_Labeling_new_220128/맨몸운동_01/
파일 수: 약 1,890개 (945 쌍의 2D/3D)
```

#### Validation 데이터 활용
```
경로: PT-Pose-Data/PT_Pose/2.Validation/라벨링데이터/body_01/
파일 수: 약 2,240개 (1,120 쌍의 2D/3D)
```

### 2. 정답 데이터 추출 프로세스

#### STEP 1: 데이터 정제
```python
# 1. 3D JSON 파일만 추출 (*-3d.json)
# 2. 각 파일에서 프레임 데이터 읽기
# 3. 완전한 랜드마크를 가진 프레임만 선택
#    - 모든 주요 관절(Hip, Knee, Ankle, Shoulder, Elbow)이 존재
#    - z 좌표 값이 유효한 범위 내 (-100 ~ 100)
```

#### STEP 2: 운동 동작 세그먼트 분할
```python
# 스탠딩 사이드 크런치 동작 사이클:
# 1. 시작 자세 (서 있는 상태)
# 2. 왼쪽으로 기울이기
# 3. 중앙으로 복귀
# 4. 오른쪽으로 기울이기
# 5. 중앙으로 복귀

# 각도 변화를 기준으로 동작 분할:
# - 허리-어깨 각도 변화
# - 상체 기울기 (Left Shoulder - Right Shoulder의 y 좌표 차이)
```

#### STEP 3: 관절 각도 계산
```python
# 주요 각도 계산 포인트 (스탠딩 사이드 크런치):

# 1. 상체 기울기 (좌/우)
#    - Left Shoulder - Waist - Right Shoulder

# 2. 팔 각도 (양손을 머리 위로)
#    - Shoulder - Elbow - Wrist (양쪽)

# 3. 무릎 각도 (서 있는 자세 유지)
#    - Hip - Knee - Ankle (양쪽)

# 4. 척추 각도
#    - Neck - Back - Waist
```

#### STEP 4: 통계 분석
```python
# 각 동작 단계별로:
# - 평균 각도 (mean)
# - 표준 편차 (std)
# - 허용 범위 (mean ± 2*std)
# - 최소/최대 각도

# 예시:
{
  "exercise_id": "001-1-1-01",
  "exercise_name": "스탠딩 사이드 크런치",
  "key_angles": {
    "left_body_tilt": {
      "points": ["Left Shoulder", "Waist", "Right Shoulder"],
      "mean_angle": 165.0,
      "std": 5.0,
      "min_angle": 155.0,
      "max_angle": 175.0,
      "ideal_range": [160.0, 170.0]
    },
    "left_arm_raise": {
      "points": ["Left Shoulder", "Left Elbow", "Left Wrist"],
      "mean_angle": 170.0,
      "std": 8.0,
      "min_angle": 155.0,
      "max_angle": 180.0,
      "ideal_range": [162.0, 178.0]
    },
    // ... 더 많은 각도
  },
  "motion_phases": [
    {
      "phase": "start",
      "description": "서 있는 중립 자세",
      "duration_frames": 10,
      "key_checks": {
        "body_upright": true,
        "arms_raised": true,
        "knees_straight": true
      }
    },
    {
      "phase": "left_bend",
      "description": "왼쪽으로 상체 숙이기",
      "duration_frames": 15,
      "key_checks": {
        "left_body_tilt": [145, 160],
        "right_knee_stable": true
      }
    },
    // ... 더 많은 단계
  ]
}
```

### 3. 최종 정답 JSON 형식
```json
{
  "version": "1.0",
  "last_updated": "2025-10-31",
  "exercises": [
    {
      "exercise_id": "001-1-1-01",
      "exercise_code": "001-1-1-01",
      "exercise_name": "스탠딩 사이드 크런치",
      "category": "맨몸운동",
      "posture": "선 자세",
      "difficulty": "초급",
      "description": "서서 상체를 좌우로 기울여 복사근을 자극하는 운동",
      
      "key_joints": [
        "Left Shoulder", "Right Shoulder",
        "Left Elbow", "Right Elbow",
        "Waist", "Neck",
        "Left Hip", "Right Hip",
        "Left Knee", "Right Knee"
      ],
      
      "key_angles": {
        "left_body_tilt": {
          "name": "좌측 상체 기울기",
          "points": ["Left Shoulder", "Waist", "Right Shoulder"],
          "ideal_mean": 165.0,
          "ideal_range": [155.0, 175.0],
          "tolerance": 10.0,
          "weight": 1.0
        },
        "right_body_tilt": {
          "name": "우측 상체 기울기",
          "points": ["Right Shoulder", "Waist", "Left Shoulder"],
          "ideal_mean": 165.0,
          "ideal_range": [155.0, 175.0],
          "tolerance": 10.0,
          "weight": 1.0
        },
        "left_arm_angle": {
          "name": "좌측 팔 각도",
          "points": ["Left Shoulder", "Left Elbow", "Left Wrist"],
          "ideal_mean": 170.0,
          "ideal_range": [160.0, 180.0],
          "tolerance": 15.0,
          "weight": 0.5
        },
        "right_arm_angle": {
          "name": "우측 팔 각도",
          "points": ["Right Shoulder", "Right Elbow", "Right Wrist"],
          "ideal_mean": 170.0,
          "ideal_range": [160.0, 180.0],
          "tolerance": 15.0,
          "weight": 0.5
        },
        "left_knee_angle": {
          "name": "좌측 무릎 각도",
          "points": ["Left Hip", "Left Knee", "Left Ankle"],
          "ideal_mean": 175.0,
          "ideal_range": [170.0, 180.0],
          "tolerance": 10.0,
          "weight": 0.3
        },
        "right_knee_angle": {
          "name": "우측 무릎 각도",
          "points": ["Right Hip", "Right Knee", "Right Ankle"],
          "ideal_mean": 175.0,
          "ideal_range": [170.0, 180.0],
          "tolerance": 10.0,
          "weight": 0.3
        }
      },
      
      "motion_phases": [
        {
          "phase_id": 1,
          "phase_name": "시작 자세",
          "description": "양발을 어깨 너비로 벌리고 서서 양손을 머리 뒤로",
          "duration_sec": 1.0,
          "key_checks": ["body_upright", "arms_raised", "feet_stable"]
        },
        {
          "phase_id": 2,
          "phase_name": "좌측 굽히기",
          "description": "상체를 왼쪽으로 천천히 기울이기",
          "duration_sec": 1.5,
          "key_checks": ["left_tilt_active", "no_forward_bend", "knee_stable"]
        },
        {
          "phase_id": 3,
          "phase_name": "중앙 복귀",
          "description": "천천히 시작 자세로 돌아오기",
          "duration_sec": 1.0,
          "key_checks": ["body_upright", "smooth_motion"]
        },
        {
          "phase_id": 4,
          "phase_name": "우측 굽히기",
          "description": "상체를 오른쪽으로 천천히 기울이기",
          "duration_sec": 1.5,
          "key_checks": ["right_tilt_active", "no_forward_bend", "knee_stable"]
        },
        {
          "phase_id": 5,
          "phase_name": "완료",
          "description": "시작 자세로 복귀",
          "duration_sec": 1.0,
          "key_checks": ["body_upright"]
        }
      ],
      
      "feedback_rules": [
        {
          "condition": "left_body_tilt < 145",
          "feedback": "좌측으로 너무 많이 기울였습니다",
          "severity": "warning"
        },
        {
          "condition": "left_body_tilt > 175",
          "feedback": "좌측으로 더 기울여주세요",
          "severity": "info"
        },
        {
          "condition": "left_knee_angle < 160",
          "feedback": "무릎을 쭉 펴주세요",
          "severity": "warning"
        },
        {
          "condition": "abs(left_body_tilt - right_body_tilt) > 15",
          "feedback": "좌우 기울기를 균형있게 해주세요",
          "severity": "info"
        }
      ],
      
      "common_mistakes": [
        "무릎을 구부림",
        "앞으로 숙임",
        "양손이 머리에서 떨어짐",
        "골반이 틀어짐"
      ]
    }
  ]
}
```

---

## 실시간 비교 로직

### 1. 점수 계산 알고리즘

```dart
class PoseScorer {
  /// 전체 점수 계산 (100점 만점)
  static double calculateScore(
    Map<String, double> userAngles,      // 사용자의 현재 각도
    Map<String, dynamic> referenceAngles // 정답 데이터의 각도
  ) {
    double totalScore = 0.0;
    double totalWeight = 0.0;
    
    for (var angleKey in referenceAngles.keys) {
      final ref = referenceAngles[angleKey];
      final userAngle = userAngles[angleKey];
      
      if (userAngle == null) continue;
      
      // 각도 차이 계산
      final angleDiff = (userAngle - ref['ideal_mean']).abs();
      final tolerance = ref['tolerance'] as double;
      final weight = ref['weight'] as double;
      
      // 점수 계산 (tolerance 내면 만점, 벗어나면 감점)
      double angleScore;
      if (angleDiff <= tolerance) {
        angleScore = 100.0;
      } else {
        // 선형 감점 (tolerance의 2배 벗어나면 0점)
        angleScore = max(0.0, 100.0 - (angleDiff - tolerance) * (100.0 / tolerance));
      }
      
      totalScore += angleScore * weight;
      totalWeight += weight;
    }
    
    return totalWeight > 0 ? totalScore / totalWeight : 0.0;
  }
  
  /// 각 관절별 점수 계산
  static Map<String, double> calculateDetailedScores(
    Map<String, double> userAngles,
    Map<String, dynamic> referenceAngles
  ) {
    Map<String, double> scores = {};
    
    for (var angleKey in referenceAngles.keys) {
      final ref = referenceAngles[angleKey];
      final userAngle = userAngles[angleKey];
      
      if (userAngle == null) {
        scores[angleKey] = 0.0;
        continue;
      }
      
      final angleDiff = (userAngle - ref['ideal_mean']).abs();
      final tolerance = ref['tolerance'] as double;
      
      if (angleDiff <= tolerance) {
        scores[angleKey] = 100.0;
      } else {
        scores[angleKey] = max(0.0, 100.0 - (angleDiff - tolerance) * (100.0 / tolerance));
      }
    }
    
    return scores;
  }
}
```

### 2. 피드백 생성 로직

```dart
class FeedbackGenerator {
  /// 실시간 피드백 생성
  static List<String> generateFeedback(
    Map<String, double> userAngles,
    Map<String, double> detailedScores,
    Map<String, dynamic> referenceAngles,
    List<dynamic> feedbackRules
  ) {
    List<String> feedbacks = [];
    
    // 1. 점수 기반 피드백
    for (var angleKey in detailedScores.keys) {
      final score = detailedScores[angleKey]!;
      final ref = referenceAngles[angleKey];
      final userAngle = userAngles[angleKey]!;
      final idealMean = ref['ideal_mean'] as double;
      final name = ref['name'] as String;
      
      if (score < 50) {
        // 각도가 너무 벗어남
        if (userAngle < idealMean) {
          feedbacks.add('$name: 각도를 더 벌려주세요 (현재: ${userAngle.toStringAsFixed(1)}°)');
        } else {
          feedbacks.add('$name: 각도를 줄여주세요 (현재: ${userAngle.toStringAsFixed(1)}°)');
        }
      } else if (score < 80) {
        feedbacks.add('$name: 조금 더 조정이 필요합니다');
      }
    }
    
    // 2. 규칙 기반 피드백
    for (var rule in feedbackRules) {
      if (_evaluateCondition(rule['condition'], userAngles)) {
        feedbacks.add(rule['feedback']);
      }
    }
    
    // 3. 전체 점수에 따른 피드백
    final avgScore = detailedScores.values.reduce((a, b) => a + b) / detailedScores.length;
    if (avgScore >= 90) {
      feedbacks.insert(0, '✓ 완벽한 자세입니다!');
    } else if (avgScore >= 70) {
      feedbacks.insert(0, '좋습니다! 조금만 더 개선해보세요');
    } else if (avgScore >= 50) {
      feedbacks.insert(0, '자세를 교정해주세요');
    } else {
      feedbacks.insert(0, '⚠ 잘못된 자세입니다');
    }
    
    return feedbacks.take(3).toList(); // 최대 3개의 피드백만 표시
  }
  
  static bool _evaluateCondition(String condition, Map<String, double> angles) {
    // 간단한 조건 파싱 및 평가
    // 예: "left_body_tilt < 145"
    // 실제로는 더 복잡한 파서 필요
    return false; // TODO: 구현
  }
}
```

### 3. 실시간 처리 플로우

```dart
void _updateFeedback() {
  if (_poses.isEmpty || _selectedExercise == null) {
    _feedback = '';
    _score = 0.0;
    return;
  }
  
  final pose = _poses[0];
  
  // 1. 사용자의 현재 각도 계산
  final userAngles = _calculateUserAngles(pose, _selectedExercise!);
  
  if (userAngles.isEmpty) {
    _feedback = '전신이 보이도록 해주세요';
    return;
  }
  
  // 2. 점수 계산
  final score = PoseScorer.calculateScore(
    userAngles,
    _selectedExercise!['key_angles']
  );
  
  // 3. 상세 점수 계산
  final detailedScores = PoseScorer.calculateDetailedScores(
    userAngles,
    _selectedExercise!['key_angles']
  );
  
  // 4. 피드백 생성
  final feedbacks = FeedbackGenerator.generateFeedback(
    userAngles,
    detailedScores,
    _selectedExercise!['key_angles'],
    _selectedExercise!['feedback_rules']
  );
  
  // 5. UI 업데이트
  setState(() {
    _score = score;
    _feedback = feedbacks.join('\n');
    _detailedScores = detailedScores;
  });
}

Map<String, double> _calculateUserAngles(
  Pose pose,
  Map<String, dynamic> exercise
) {
  Map<String, double> angles = {};
  
  final keyAngles = exercise['key_angles'] as Map<String, dynamic>;
  
  for (var angleKey in keyAngles.keys) {
    final angleInfo = keyAngles[angleKey];
    final points = angleInfo['points'] as List<dynamic>;
    
    // 3점으로 각도 계산
    final point1 = _getLandmark(pose, points[0]);
    final point2 = _getLandmark(pose, points[1]);
    final point3 = _getLandmark(pose, points[2]);
    
    if (point1 != null && point2 != null && point3 != null) {
      angles[angleKey] = AngleCalculator.calculateAngle(point1, point2, point3);
    }
  }
  
  return angles;
}

PoseLandmark? _getLandmark(Pose pose, String name) {
  final typeMap = {
    'Left Shoulder': PoseLandmarkType.leftShoulder,
    'Right Shoulder': PoseLandmarkType.rightShoulder,
    'Left Elbow': PoseLandmarkType.leftElbow,
    'Right Elbow': PoseLandmarkType.rightElbow,
    'Left Wrist': PoseLandmarkType.leftWrist,
    'Right Wrist': PoseLandmarkType.rightWrist,
    'Left Hip': PoseLandmarkType.leftHip,
    'Right Hip': PoseLandmarkType.rightHip,
    'Left Knee': PoseLandmarkType.leftKnee,
    'Right Knee': PoseLandmarkType.rightKnee,
    'Left Ankle': PoseLandmarkType.leftAnkle,
    'Right Ankle': PoseLandmarkType.rightAnkle,
    // ... 추가 매핑
  };
  
  final type = typeMap[name];
  return type != null ? pose.landmarks[type] : null;
}
```

---

## 구현 계획

### Phase 1: 데이터 추출 (Python 스크립트)
```bash
# 스크립트 위치: scripts/extract_reference_data.py, scripts/analyze_exercise_08.py
# 입력: PT-Pose-Data/
# 출력: assets/exercise_reference.json
```

**작업 내용:**
1. ✅ Training 데이터 파싱 (맨몸운동_01, 맨몸운동_08)
2. ✅ Validation 데이터 파싱 (body_01)
3. ✅ 프레임별 랜드마크 추출
4. ✅ 관절 각도 계산
5. ✅ 통계 분석 (평균, 표준편차)
6. ✅ JSON 파일 생성
7. ✅ 미세한 떨림 보정 로직 구현 (Savitzky-Golay 필터)

### Phase 2: Flutter 통합
**파일 생성:**
```
lib/
├── models/
│   ├── exercise_model.dart          # 운동 데이터 모델
│   └── pose_reference_data.dart     # JSON 파싱
├── services/
│   ├── pose_scorer.dart              # 점수 계산 로직
│   ├── feedback_generator.dart       # 피드백 생성
│   ├── exercise_loader.dart          # JSON 로드
│   ├── angle_smoother.dart           # ✅ 떨림 보정 서비스
│   └── phase_manager.dart            # 단계 관리
└── widgets/
    ├── exercise_dropdown.dart        # 운동 선택 드롭다운
    ├── score_display.dart            # 점수 표시
    ├── feedback_panel.dart           # 피드백 패널
    └── phase_progress_widget.dart    # 단계 진행 표시
```

**작업 내용:**
1. ✅ JSON 파싱 모델 생성
2. ✅ AngleCalculator 확장 (3점 각도 계산)
3. ✅ PoseScorer 구현
4. ✅ FeedbackGenerator 구현
5. ✅ UI 컴포넌트 추가
6. ✅ main.dart 통합
7. ✅ 떨림 보정 로직 통합 (AngleSmoother)
8. ✅ 복합 랜드마크 매핑 (Neck, Back, Waist)

### Phase 3: UI/UX 개선
1. 운동 선택 드롭다운
2. 실시간 점수 표시 (0-100)
3. 관절별 점수 시각화
4. 피드백 메시지 표시
5. 운동 진행 상태 표시

### Phase 4: 확장
1. 더 많은 운동 추가 (02, 03, ...)
2. 운동 기록 저장
3. 통계 및 진행 상황 추적
4. 음성 피드백 추가

---

## 다음 단계

### 즉시 실행 가능한 작업:

#### 1. Python 스크립트 작성
```bash
# scripts/extract_reference_data.py 생성
python scripts/extract_reference_data.py \
  --input PT-Pose-Data/PT_Pose/1.Training/Labeling/맨몸운동_Labeling_new_220128/맨몸운동_01 \
  --output assets/exercise_reference.json \
  --exercise-id "001-1-1-01"
```

#### 2. assets 폴더 생성
```bash
mkdir assets
touch assets/exercise_reference.json
```

#### 3. pubspec.yaml 수정
```yaml
flutter:
  assets:
    - assets/exercise_reference.json
```

#### 4. 구현 시작
- [ ] Python 스크립트로 정답 데이터 추출
- [ ] exercise_reference.json 생성
- [ ] Flutter 모델 클래스 생성
- [ ] 점수 계산 로직 구현
- [ ] UI 통합

---

## 참고 자료

### ML Kit Pose Detection 랜드마크 매핑
```dart
// PT Pose Data → ML Kit Pose Detection 매핑
final landmarkMapping = {
  // PT Pose Data 이름 → ML Kit PoseLandmarkType
  'Nose': PoseLandmarkType.nose,
  'Left Shoulder': PoseLandmarkType.leftShoulder,
  'Right Shoulder': PoseLandmarkType.rightShoulder,
  'Left Elbow': PoseLandmarkType.leftElbow,
  'Right Elbow': PoseLandmarkType.rightElbow,
  'Left Wrist': PoseLandmarkType.leftWrist,
  'Right Wrist': PoseLandmarkType.rightWrist,
  'Left Hip': PoseLandmarkType.leftHip,
  'Right Hip': PoseLandmarkType.rightHip,
  'Left Knee': PoseLandmarkType.leftKnee,
  'Right Knee': PoseLandmarkType.rightKnee,
  'Left Ankle': PoseLandmarkType.leftAnkle,
  'Right Ankle': PoseLandmarkType.rightAnkle,
};
```

### 각도 계산 공식
```dart
// 3점 A-B-C로 이루어진 각도 ∠ABC 계산
// B가 중심점 (vertex)
double calculateAngle(Point a, Point b, Point c) {
  final radians = atan2(c.y - b.y, c.x - b.x) - 
                  atan2(a.y - b.y, a.x - b.x);
  double angle = radians * 180.0 / pi;
  angle = angle.abs();
  if (angle > 180.0) angle = 360.0 - angle;
  return angle;
}
```

---

## 버전 이력
- v1.0 (2025-10-31): 초안 작성, 운동 01번 (스탠딩 사이드 크런치) 분석 완료
- v1.1 (2025-11-03): 운동 08번 (굿모닝) 추가, 떨림 보정 로직 구현 완료
- v1.2 (2025-11-03): 운동 02~07번 전체 추가, 각도별 색상 시각화 완료
- v1.3 (2025-11-03): 인식 기준 관대화 - tolerance 2배 증가 + 점수 계산 알고리즘 개선
- v1.4 (2025-11-03): 최종 5개 운동 선정 - 코칭 실현성 기준으로 05, 06, 07번 제외
- v2.0 (2025-11-04): 중급 난이도 운동 2개 제외 (004, 008) - 최종 3개 운동 (초급만 지원)

---

## 추가된 기능 (v1.1)

### 1. 운동 08번 (굿모닝) 추가
- **운동 코드**: 001-1-1-08
- **난이도**: 중급
- **주요 각도**:
  - 힙 각도 (좌/우): 힙을 중심으로 상체를 숙이는 각도
  - 무릎 각도 (좌/우): 무릎을 펴진 상태로 유지
  - 등 각도: 등을 곧게 유지하는 각도
  - 상체 숙임 각도: 전체 상체의 앞으로 숙임 정도

### 2. 떨림 보정 시스템
인간의 몸은 미세한 떨림이 있으므로, 안정적인 각도 측정을 위해 여러 필터링 기법을 구현:

#### 구현된 필터 종류:
1. **단순 이동 평균 (Simple Moving Average)**
   - 가장 기본적인 스무딩 방법
   - N개 프레임의 평균 계산

2. **가중 이동 평균 (Weighted Moving Average)**
   - 최근 프레임에 더 높은 가중치 부여
   - 더 반응성이 좋은 스무딩

3. **지수 이동 평균 (Exponential Moving Average)**
   - alpha 파라미터로 반응성 조절
   - 메모리 효율적 (이전 평균값만 저장)

4. **미디안 필터 (Median Filter)**
   - 이상치 제거에 효과적
   - 갑작스러운 튀는 값 방지

5. **적응형 필터 (Adaptive Filter)** ⭐ **(기본 사용)**
   - 변화가 클 때: 빠르게 반응 (alpha = 0.7)
   - 변화가 작을 때: 스무딩 (alpha = 0.2)
   - 자연스러운 동작 추적

#### 사용 예시:
```dart
// main.dart에서
final _angleSmoother = AngleSmoother(windowSize: 5);

// 각도 계산 시
final rawAngle = AngleCalculator.calculateAngle(p1, p2, p3);
final smoothedAngle = _angleSmoother.smoothAngleAdaptive(
  'hip_angle_left',
  rawAngle,
  threshold: 10.0, // 10도 이상 변화시 즉시 반응
);
```

### 3. 복합 랜드마크 매핑
PT Pose Data의 랜드마크를 ML Kit의 랜드마크로 매핑:

| PT Pose Data | ML Kit 매핑 | 설명 |
|-------------|-------------|------|
| Neck | 양쪽 어깨 중점 | 목 위치 근사 |
| Back | 어깨와 힙의 중간점 | 등 중앙 위치 |
| Waist | 양쪽 힙 중점 | 허리 위치 |
| Shoulder | 양쪽 어깨 평균 | 어깨 중점 |
| Hip | 양쪽 힙 평균 | 힙 중점 |
| Knee | 양쪽 무릎 평균 | 무릎 중점 |


