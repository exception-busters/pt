# AI 기반 실시간 자세 교정 시스템 개발 가이드

## 🎯 1. 프로젝트 개요

### 1.1 프로젝트 목표
AI 기반 PT 앱의 핵심 기능으로, 사용자가 특정 운동 자세를 얼마나 정확하게 따라 하는지 실시간으로 분석하고 피드백하는 시스템을 구축한다. 시스템은 미리 정의된 '표준 자세'와 사용자의 실시간 자세를 수학적으로 비교하여 정확도를 0-100% 사이의 점수로 정량화하고, 구체적인 교정 가이드를 제공하는 것을 목표로 한다.

### 1.2 핵심 기능
- **실시간 자세 분석**: MediaPipe Pose를 활용한 관절 각도 추출
- **정확도 점수화**: 코사인 유사도 기반 0-100% 점수 계산
- **즉시 피드백**: 구체적이고 직관적인 교정 가이드 제공
- **시각적 강조**: 오차가 큰 관절 부위를 색상으로 구분 표시

---

## 🏗️ 2. 시스템 아키텍처

### 2.1 전체 구조
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   오프라인 분석   │    │   실시간 분석    │    │   피드백 시스템   │
│  (사전 처리)     │    │  (런타임)       │    │  (UI/UX)        │
├─────────────────┤    ├─────────────────┤    ├─────────────────┤
│ • 표준 자세 분석  │    │ • 사용자 자세 분석│    │ • 점수 시각화    │
│ • 정답 벡터 생성  │    │ • 벡터 비교      │    │ • 교정 가이드    │
│ • DB 구축       │    │ • 유사도 계산    │    │ • 성공 피드백    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### 2.2 데이터 흐름
1. **표준 자세 이미지** → MediaPipe 분석 → **정답 벡터** → JSON DB 저장
2. **실시간 카메라** → MediaPipe 분석 → **사용자 벡터** → 유사도 계산
3. **점수 + 오차 분석** → UI 렌더링 → **사용자 피드백**

---

## 📊 3. 상세 구현 계획

### Step 1: 오프라인 분석 - 정답 자세 데이터베이스 생성

#### 3.1 입력 데이터
- 각 운동별 가장 이상적인 자세를 보여주는 고화질 이미지 파일
- 예시: `squat_perfect.png`, `lunge_perfect.png`, `pushup_perfect.png`

#### 3.2 처리 로직
```python
# 1. MediaPipe Pose로 3D 월드 랜드마크 추출
mp_pose = mp.solutions.pose
pose = mp_pose.Pose(static_image_mode=True)

# 2. 핵심 관절 그룹 정의 (운동별)
key_joints = {
    "squat": [
        {"name": "left_hip", "points": [11, 23, 25]},  # 어깨-엉덩이-무릎
        {"name": "left_knee", "points": [23, 25, 27]}, # 엉덩이-무릎-발목
        {"name": "right_hip", "points": [12, 24, 26]},
        {"name": "right_knee", "points": [24, 26, 28]}
    ]
}

# 3. 3D 각도 계산 (벡터 내적 사용)
def calculate_angle_3d(point1, point2, point3):
    vector1 = np.array(point1) - np.array(point2)
    vector2 = np.array(point3) - np.array(point2)
    
    cos_angle = np.dot(vector1, vector2) / (np.linalg.norm(vector1) * np.linalg.norm(vector2))
    angle = np.arccos(np.clip(cos_angle, -1.0, 1.0))
    return np.degrees(angle)
```

#### 3.3 출력 데이터 구조
```json
// assets/pose_database.json
{
  "exercises": [
    {
      "name": "squat",
      "description": "스쿼트 운동",
      "key_joints_indices": [
        {"name": "left_hip", "points": [11, 23, 25], "description": "왼쪽 고관절"},
        {"name": "left_knee", "points": [23, 25, 27], "description": "왼쪽 무릎"},
        {"name": "right_hip", "points": [12, 24, 26], "description": "오른쪽 고관절"},
        {"name": "right_knee", "points": [24, 26, 28], "description": "오른쪽 무릎"}
      ],
      "correct_vector": [110.5, 92.1, 111.2, 93.5],
      "thresholds": {
        "perfect": 95.0,
        "good": 85.0
      }
    },
    {
      "name": "lunge",
      "description": "런지 운동",
      "key_joints_indices": [
        {"name": "front_knee", "points": [23, 25, 27], "description": "앞쪽 무릎"},
        {"name": "back_knee", "points": [24, 26, 28], "description": "뒤쪽 무릎"},
        {"name": "hip_alignment", "points": [23, 24, 25], "description": "고관절 정렬"}
      ],
      "correct_vector": [90.0, 180.0, 0.0],
      "thresholds": {
        "perfect": 92.0,
        "good": 80.0
      }
    }
  ]
}
```

### Step 2: 실시간 분석 - 사용자 자세 벡터 계산

#### 3.4 실시간 처리 로직
```dart
class PoseAnalyzer {
  // 1. 실시간 포즈 랜드마크 추출
  Future<List<double>> calculateUserVector(
    List<Map<String, dynamic>> landmarks,
    String exerciseName
  ) async {
    final exerciseData = await _loadExerciseData(exerciseName);
    final userAngles = <double>[];
    
    for (final joint in exerciseData['key_joints_indices']) {
      final points = joint['points'] as List<int>;
      final angle = _calculateAngle3D(
        landmarks[points[0]],
        landmarks[points[1]], 
        landmarks[points[2]]
      );
      userAngles.add(angle);
    }
    
    return userAngles;
  }
  
  // 2. 3D 각도 계산
  double _calculateAngle3D(
    Map<String, dynamic> point1,
    Map<String, dynamic> point2,
    Map<String, dynamic> point3
  ) {
    final v1 = Vector3(
      point1['x'] - point2['x'],
      point1['y'] - point2['y'],
      point1['z'] - point2['z']
    );
    
    final v2 = Vector3(
      point3['x'] - point2['x'],
      point3['y'] - point2['y'],
      point3['z'] - point2['z']
    );
    
    final cosAngle = v1.dot(v2) / (v1.length * v2.length);
    return math.acos(cosAngle.clamp(-1.0, 1.0)) * 180 / math.pi;
  }
}
```

### Step 3: 코사인 유사도 계산 및 점수화

#### 3.5 유사도 계산
```dart
class SimilarityCalculator {
  // 코사인 유사도 계산
  double calculateCosineSimilarity(
    List<double> correctVector,
    List<double> userVector
  ) {
    if (correctVector.length != userVector.length) {
      throw ArgumentError('벡터 길이가 일치하지 않습니다');
    }
    
    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;
    
    for (int i = 0; i < correctVector.length; i++) {
      dotProduct += correctVector[i] * userVector[i];
      normA += correctVector[i] * correctVector[i];
      normB += userVector[i] * userVector[i];
    }
    
    if (normA == 0.0 || normB == 0.0) return 0.0;
    
    return dotProduct / (math.sqrt(normA) * math.sqrt(normB));
  }
  
  // 점수 및 등급 계산
  PoseScore calculateScore(double similarity, Map<String, double> thresholds) {
    final score = similarity * 100;
    
    PoseGrade grade;
    if (score >= thresholds['perfect']!) {
      grade = PoseGrade.perfect;
    } else if (score >= thresholds['good']!) {
      grade = PoseGrade.good;
    } else {
      grade = PoseGrade.tryAgain;
    }
    
    return PoseScore(score: score, grade: grade);
  }
}
```

### Step 4: 사용자 피드백 구현

#### 3.6 UI 컴포넌트 설계
```dart
class PoseFeedbackWidget extends StatefulWidget {
  final PoseScore score;
  final List<JointError> jointErrors;
  final String exerciseName;
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 1. 전체 정확도 시각화
        CircularProgressIndicator(
          value: score.score / 100,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(
            _getScoreColor(score.grade)
          ),
        ),
        
        // 2. 점수 표시
        Text(
          '${score.score.toStringAsFixed(1)}%',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: _getScoreColor(score.grade)
          ),
        ),
        
        // 3. 등급 표시
        Text(
          _getGradeText(score.grade),
          style: TextStyle(
            fontSize: 18,
            color: _getScoreColor(score.grade)
          ),
        ),
        
        // 4. 구체적 교정 가이드
        if (jointErrors.isNotEmpty)
          Container(
            padding: EdgeInsets.all(16),
            margin: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red[200]!)
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '교정이 필요한 부위:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red[800]
                  ),
                ),
                SizedBox(height: 8),
                ...jointErrors.map((error) => 
                  Text('• ${error.description}')
                ).toList(),
              ],
            ),
          ),
      ],
    );
  }
}
```

#### 3.7 부위별 상세 피드백
```dart
class JointErrorAnalyzer {
  List<JointError> analyzeJointErrors(
    List<double> correctVector,
    List<double> userVector,
    List<Map<String, dynamic>> keyJoints
  ) {
    final errors = <JointError>[];
    
    for (int i = 0; i < correctVector.length; i++) {
      final error = (userVector[i] - correctVector[i]).abs();
      final threshold = correctVector[i] * 0.1; // 10% 오차 허용
      
      if (error > threshold) {
        errors.add(JointError(
          jointName: keyJoints[i]['name'],
          description: _generateFeedback(
            keyJoints[i]['description'],
            userVector[i],
            correctVector[i]
          ),
          errorAmount: error,
          severity: _getSeverity(error, threshold)
        ));
      }
    }
    
    // 오차가 큰 순서대로 정렬
    errors.sort((a, b) => b.errorAmount.compareTo(a.errorAmount));
    return errors;
  }
  
  String _generateFeedback(
    String jointDescription,
    double userAngle,
    double correctAngle
  ) {
    final difference = userAngle - correctAngle;
    
    if (jointDescription.contains('무릎')) {
      if (difference > 0) {
        return '무릎을 조금 더 굽혀주세요';
      } else {
        return '무릎을 조금 더 펴주세요';
      }
    } else if (jointDescription.contains('고관절')) {
      if (difference > 0) {
        return '엉덩이를 조금 더 내려주세요';
      } else {
        return '엉덩이를 조금 더 올려주세요';
      }
    }
    
    return '$jointDescription을 조정해주세요';
  }
}
```

---

## ⚡ 4. 성능 최적화 전략

### 4.1 Isolate 활용
```dart
class PoseProcessingService {
  static Future<PoseResult> processPoseInIsolate(
    List<Map<String, dynamic>> landmarks,
    String exerciseName
  ) async {
    return await compute(_processPoseData, {
      'landmarks': landmarks,
      'exerciseName': exerciseName,
    });
  }
  
  static PoseResult _processPoseData(Map<String, dynamic> data) {
    // 무거운 계산 작업을 Isolate에서 처리
    final analyzer = PoseAnalyzer();
    final calculator = SimilarityCalculator();
    
    final userVector = analyzer.calculateUserVector(
      data['landmarks'],
      data['exerciseName']
    );
    
    final correctVector = _loadCorrectVector(data['exerciseName']);
    final similarity = calculator.calculateCosineSimilarity(
      correctVector,
      userVector
    );
    
    return PoseResult(
      score: similarity * 100,
      userVector: userVector,
      correctVector: correctVector,
    );
  }
}
```

### 4.2 프레임 레이트 최적화
```dart
class FrameRateController {
  static const int targetFPS = 30;
  static const int analysisFPS = 10; // 분석은 더 낮은 주기로
  
  Timer? _analysisTimer;
  int _frameCount = 0;
  
  void startAnalysis(Function() onAnalysis) {
    _analysisTimer = Timer.periodic(
      Duration(milliseconds: 1000 ~/ analysisFPS),
      (_) => onAnalysis()
    );
  }
  
  bool shouldAnalyzeFrame() {
    _frameCount++;
    return _frameCount % (targetFPS ~/ analysisFPS) == 0;
  }
}
```

---

## 🎨 5. UI/UX 설계 가이드

### 5.1 시각적 피드백 계층
1. **전체 점수**: 원형 프로그레스 바 (상단 중앙)
2. **등급 표시**: 색상 코딩 (초록/노랑/빨강)
3. **교정 가이드**: 텍스트 박스 (하단)
4. **관절 강조**: 스켈레톤 오버레이 (실시간)

### 5.2 색상 시스템
```dart
class PoseColors {
  static const Color perfect = Color(0xFF4CAF50); // 초록
  static const Color good = Color(0xFFFF9800);    // 주황
  static const Color tryAgain = Color(0xFFF44336); // 빨강
  static const Color neutral = Color(0xFF9E9E9E);  // 회색
}
```

### 5.3 애니메이션 효과
- **성공 시**: 화면 전체 펄스 효과
- **점수 변화**: 부드러운 전환 애니메이션
- **오류 강조**: 깜빡이는 효과

---

## 🧪 6. 테스트 및 검증

### 6.1 정확도 검증
- 다양한 체형의 테스트 사용자
- 다양한 조명 조건에서 테스트
- 각 운동별 임계값 튜닝

### 6.2 성능 테스트
- CPU 사용률 모니터링
- 메모리 사용량 추적
- 배터리 소모 측정

### 6.3 사용자 경험 테스트
- 피드백 지연 시간 측정
- 사용자 만족도 조사
- 학습 효과 검증

---

## 📚 7. 확장 가능성

### 7.1 추가 운동 지원
- 새로운 운동 추가 시 JSON 데이터만 업데이트
- 모듈화된 구조로 쉬운 확장

### 7.2 개인화 기능
- 사용자별 맞춤 임계값
- 학습 진도 추적
- 개인 기록 관리

### 7.3 소셜 기능
- 친구와 점수 비교
- 챌린지 모드
- 성취 배지 시스템

---

## 🔧 8. 개발 체크리스트

### Phase 1: 기본 구조
- [ ] MediaPipe Pose 통합
- [ ] 기본 UI 컴포넌트 구현
- [ ] JSON 데이터베이스 구조 설계

### Phase 2: 핵심 기능
- [ ] 3D 각도 계산 로직 구현
- [ ] 코사인 유사도 계산
- [ ] 실시간 피드백 시스템

### Phase 3: 최적화
- [ ] Isolate를 활용한 성능 최적화
- [ ] 프레임 레이트 조절
- [ ] 메모리 사용량 최적화

### Phase 4: 완성도
- [ ] 다양한 운동 지원
- [ ] 사용자 테스트 및 피드백 반영
- [ ] 최종 튜닝 및 배포

---

## 📖 9. 참고 자료

### 9.1 MediaPipe Pose 랜드마크 인덱스
```
0: nose
1: left_eye_inner
2: left_eye
3: left_eye_outer
4: right_eye_inner
5: right_eye
6: right_eye_outer
7: left_ear
8: right_ear
9: mouth_left
10: mouth_right
11: left_shoulder
12: right_shoulder
13: left_elbow
14: right_elbow
15: left_wrist
16: right_wrist
17: left_pinky
18: right_pinky
19: left_index
20: right_index
21: left_thumb
22: right_thumb
23: left_hip
24: right_hip
25: left_knee
26: right_knee
27: left_ankle
28: right_ankle
29: left_heel
30: right_heel
31: left_foot_index
32: right_foot_index
```

### 9.2 코사인 유사도 수식
```
Similarity = cos(θ) = (A · B) / (||A|| × ||B||)

여기서:
- A: 정답 벡터
- B: 사용자 벡터
- θ: 두 벡터 간의 각도
- ||A||, ||B||: 각 벡터의 크기(노름)
```

### 9.3 권장 임계값
- **Perfect**: 95% 이상
- **Good**: 85% 이상
- **Try Again**: 85% 미만

---

이 가이드 문서를 기반으로 체계적이고 확장 가능한 AI 자세 교정 시스템을 구축할 수 있습니다. 각 단계별로 세심한 테스트와 검증을 통해 사용자에게 최고의 경험을 제공하는 시스템을 만들어보세요! 🚀

