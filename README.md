# 🏋️ AI 자세 교정 앱 (Pose Detection App)

**실시간 포즈 감지와 AI 기반 운동 자세 교정 Flutter 애플리케이션**

---

## 📋 프로젝트 개요

Google ML Kit Pose Detection을 활용하여 실시간으로 사용자의 운동 자세를 분석하고, 정답 데이터와 비교하여 점수와 피드백을 제공하는 Flutter 애플리케이션입니다.

### 주요 기능

✅ **실시간 포즈 감지** - Google ML Kit 포즈 감지
✅ **스켈레톤 시각화** - 33개 신체 랜드마크 포인트
✅ **운동 선택** - 드롭다운으로 다양한 운동 선택
✅ **자세 점수 계산** - 100점 만점 실시간 채점
✅ **상세 피드백** - 관절별 점수 및 교정 피드백
✅ **각도 분석** - 주요 관절 각도 계산 및 비교

---

## 🛠️ 기술 스택

- **Flutter SDK**: 3.9.2+
- **Dart SDK**: 3.9.2+
- **Google ML Kit Pose Detection**: ^0.14.0
- **Camera**: ^0.11.0+2

---

## 📁 프로젝트 구조

```
pose_detection_app/
├── assets/
│   └── exercise_reference.json    # 운동 정답 데이터
├── lib/
│   ├── models/
│   │   └── exercise_model.dart    # 운동 데이터 모델
│   ├── services/
│   │   ├── exercise_loader.dart    # JSON 로더
│   │   ├── pose_scorer.dart        # 점수 계산
│   │   └── feedback_generator.dart # 피드백 생성
│   ├── widgets/
│   │   ├── exercise_dropdown.dart  # 운동 선택 UI
│   │   ├── score_display.dart      # 점수 표시
│   │   └── feedback_panel.dart     # 피드백 패널
│   ├── main.dart                   # 메인 앱
│   ├── pose_painter.dart           # 스켈레톤 렌더링
│   └── angle_calculator.dart       # 각도 계산
├── scripts/
│   └── extract_reference_data.py   # 정답 데이터 추출
├── PT-Pose-Data/                   # 학습 데이터 (별도)
├── PT_POSE_DATA_GUIDE.md          # 데이터 활용 가이드
└── PROJECT_GUIDE.md               # 프로젝트 가이드
```

---

## 🚀 시작하기

### 1. 사전 요구사항

```bash
flutter doctor
```

- Flutter SDK 3.9.2 이상
- Android Studio 또는 VS Code
- Android 기기 또는 에뮬레이터

### 2. 의존성 설치

```bash
flutter pub get
```

### 3. 앱 실행

```bash
flutter run
```

### 4. (선택) 정답 데이터 추출

PT-Pose-Data가 있는 경우:

```bash
python scripts/extract_reference_data.py \
  --input PT-Pose-Data/PT_Pose/1.Training/Labeling/맨몸운동_Labeling_new_220128/맨몸운동_01 \
  --output assets/exercise_reference.json \
  --exercise-id "001-1-1-01"
```

---

## 📊 현재 지원 운동

| 운동 ID | 운동 이름 | 카테고리 | 난이도 |
|---------|-----------|----------|--------|
| 001-1-1-01 | 스탠딩 사이드 크런치 | 맨몸운동 | 초급 |
| 001-1-1-02 | 스탠딩 니업 | 맨몸운동 | 초급 |
| 001-1-1-03 | 스쿼트 | 맨몸운동 | 초급 |

*현재 3개 운동 (초급) 지원 중입니다.*

---

## 🎯 핵심 기능 설명

### 1. 포즈 감지
- Google ML Kit을 사용하여 33개 신체 랜드마크 감지
- 실시간 프레임 처리 (성능 최적화)
- YUV_420_888 → NV21 포맷 변환

### 2. 각도 계산
- 3점 기반 각도 계산 (A-B-C)
- 주요 관절 각도 분석:
  - 상체 기울기 (좌/우)
  - 팔 각도 (좌/우)
  - 무릎 각도 (좌/우)

### 3. 점수 계산
```dart
점수 = (Σ(각도별 점수 × 가중치)) / 총 가중치

각도별 점수:
- tolerance 이내: 100점
- tolerance 초과: 선형 감점 (최대 0점)
```

### 4. 피드백 생성
- 점수 기반 피드백 (90+: 완벽, 70+: 우수, ...)
- 규칙 기반 피드백 (조건부)
- 관절별 상세 피드백

---

## 🏗️ 아키텍처

### 데이터 흐름

```
카메라 → ML Kit → 포즈 감지
              ↓
        각도 계산
              ↓
    정답 데이터와 비교
              ↓
     점수 + 피드백 생성
              ↓
         UI 업데이트
```

### 주요 클래스

- **ExerciseModel**: 운동 데이터 모델
- **PoseScorer**: 점수 계산 로직
- **FeedbackGenerator**: 피드백 생성
- **ExerciseLoader**: JSON 로더
- **AngleCalculator**: 각도 계산 유틸

---

## 📖 문서

- [PT_POSE_DATA_GUIDE.md](PT_POSE_DATA_GUIDE.md) - PT Pose Data 활용 가이드
- [PROJECT_GUIDE.md](PROJECT_GUIDE.md) - 프로젝트 완전 가이드

---

## 🔧 설정

### Android 설정 (android/app/build.gradle.kts)

```kotlin
android {
    compileSdk = flutter.compileSdkVersion
    
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }
    
    dependencies {
        implementation("com.google.mlkit:pose-detection-accurate:18.0.0-beta3")
    }
}
```

### 권한 (AndroidManifest.xml)

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-feature android:name="android.hardware.camera" />
<uses-feature android:name="android.hardware.camera.autofocus" />
```

---

## 🎨 UI 스크린샷

*(스크린샷 추가 예정)*

---

## 🚧 향후 계획

- [ ] 더 많은 운동 추가 (스쿼트, 런지, 푸시업 등)
- [ ] 운동 기록 저장 및 통계
- [ ] 음성 피드백
- [ ] 운동 진행 상황 추적
- [ ] 운동 루틴 생성
- [ ] 소셜 공유 기능

---

## 🐛 트러블슈팅

### 포즈 감지 안됨
- 밝은 조명 확인
- 카메라에서 2~3미터 거리 유지
- 몸 전체가 화면에 들어오도록 조정

### 앱 느림 / 프레임 드롭
- 프레임 스킵 증가 (main.dart의 `_skipFrames % 3` → `% 5`)
- 해상도 낮추기 (`ResolutionPreset.low`)

### 빌드 오류
```bash
flutter clean
flutter pub get
flutter run
```

---

## 📜 라이선스

이 프로젝트는 MIT 라이선스로 배포됩니다.

---

## 🤝 기여

기여는 언제나 환영합니다!

1. 프로젝트를 포크하세요
2. 기능 브랜치를 생성하세요 (`git checkout -b feature/AmazingFeature`)
3. 변경 사항을 커밋하세요 (`git commit -m 'Add some AmazingFeature'`)
4. 브랜치에 푸시하세요 (`git push origin feature/AmazingFeature`)
5. Pull Request를 열어 주세요

---

## 👥 팀

- **GitHub**: [exception-busters/pt](https://github.com/exception-busters/pt)
- **Branch**: chaewon-2

---

## 📞 문의

프로젝트 관련 문의사항이 있으시면 GitHub Issues를 통해 연락주세요.

---

**Flutter와 Google ML Kit으로 ❤️를 담아 만들었습니다.**

## 📘 모바일 PT 앱 확장 개요 (추가 안내)

스마트폰 카메라와 AI로 실시간 자세 인식/피드백을 제공하고, 개인화 루틴/식단/기록을 통합 관리하는 크로스플랫폼 앱입니다.

프로젝트 핵심 요약과 아키텍처/요구사항/로드맵은 `문서/문서_요약.md`에 통합되어 있습니다.

### 사전 준비 사항
- Flutter SDK(안정 채널), Dart SDK `^3.9.2` 호환 버전
- Android 10+ 또는 iOS 14+ 디바이스/에뮬레이터

### 빠른 시작
1) 의존성 설치
```
flutter pub get
```

2) 실행
```
flutter run -d chrome   # 웹
flutter run -d android  # 안드로이드
flutter run -d ios      # iOS (맥OS 필요)
```

3) 분석/포맷(optional)
```
flutter analyze
flutter test
```

### 프로젝트 구조(계획)
- 상태관리: Riverpod, 라우팅: GoRouter
- 폴더링(요약):
  - `lib/core` – 상수/에러/네트워크/스토리지
  - `lib/features` – 도메인별 `data/domain/presentation`
  - `lib/common` – 공용 위젯/스타일

현 시점 코드는 단일 파일 목업(`lib/main.dart`)이며, 단계적으로 위 구조로 리팩터링 예정입니다.

### 서버/AI 연동 개요
- 서버: Spring Boot + PostgreSQL 기반 REST API
- 인증: Firebase Auth(JWT), 통신: HTTPS(TLS 1.2 이상)
- AI: 온디바이스 TFLite + MediaPipe Pose(33 랜드마크), 필요 시 경량 서버 추론 폴백

엔드포인트/스키마/성능 목표 등 상세는 `문서/문서_요약.md`의 4, 6, 8장을 참고하세요.
