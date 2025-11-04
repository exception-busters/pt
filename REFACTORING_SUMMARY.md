# 리팩토링 요약 📝

## 목적
브랜치 머지 시 충돌을 최소화하고 코드 구조를 개선

---

## 변경 사항

### 이전 구조
```
lib/
├── main.dart (691줄)    # 모든 로직 포함
└── exercise.dart        # main.dart의 복사본
```

### 현재 구조
```
lib/
├── main.dart (5줄)                      # 엔트리 포인트만
├── app.dart (17줄)                      # ExerciseApp 위젯
├── screens/
│   └── exercise_screen.dart (569줄)     # 메인 화면
├── models/
├── services/
└── widgets/
```

---

## 주요 변경

### 1. main.dart (5줄)
```dart
import 'package:flutter/material.dart';
import 'app.dart';

void main() {
  runApp(const ExerciseApp());
}
```
- 엔트리 포인트만 포함
- 매우 단순하여 충돌 가능성 최소화

### 2. app.dart (신규, 17줄)
```dart
import 'package:flutter/material.dart';
import 'screens/exercise_screen.dart';

class ExerciseApp extends StatelessWidget {
  // MaterialApp 설정
}
```
- ExerciseApp 위젯 분리
- MaterialApp 설정만 담당

### 3. screens/exercise_screen.dart (신규, 569줄)
- 이전의 `CameraPreviewWidget` → `ExerciseScreen`으로 리네임
- 모든 운동 관련 로직 포함
- 독립적인 화면 모듈

### 4. exercise.dart (삭제)
- app.dart와 exercise_screen.dart로 분리되어 제거

---

## 이점

### ✅ 충돌 최소화
- **main.dart**: 5줄만 있어 거의 충돌 없음
- **app.dart**: 새 파일이므로 충돌 없음
- **screens/**: 새 디렉토리이므로 충돌 없음

### ✅ 명확한 책임 분리
- `main.dart`: 앱 시작
- `app.dart`: 앱 설정
- `exercise_screen.dart`: 운동 화면

### ✅ 확장성
```
screens/
├── exercise_screen.dart    # 운동 화면
├── settings_screen.dart    # 설정 화면 (추가 가능)
└── history_screen.dart     # 기록 화면 (추가 가능)
```

### ✅ 유지보수
- 파일 크기 감소 (691줄 → 569줄)
- 코드 찾기 쉬움
- 테스트 용이

---

## 머지 전략

### 시나리오 1: 다른 브랜치가 main.dart를 수정한 경우
```bash
# 충돌 발생
<<<<<<< HEAD (현재 브랜치)
import 'app.dart';
void main() {
  runApp(const ExerciseApp());
}
=======
// 다른 브랜치의 복잡한 코드
>>>>>>>

# 해결 방법
1. 현재 브랜치(HEAD)의 main.dart 유지 (단순함)
2. 다른 브랜치의 로직을 exercise_screen.dart에 수동 병합
```

### 시나리오 2: 새 기능 추가
```dart
// app.dart에서 라우팅 추가
home: const ExerciseScreen(),
routes: {
  '/settings': (context) => const SettingsScreen(),
  '/history': (context) => const HistoryScreen(),
}
```

---

## 테스트 확인

### 분석 결과
```bash
flutter analyze lib/
# 12 issues found (기존 linter 경고, 새 에러 없음)
```

### 실행 확인
```bash
flutter run
# ✅ 정상 실행 확인
```

---

## 파일 변경 요약

| 파일 | 상태 | 라인 수 | 설명 |
|------|------|---------|------|
| `lib/main.dart` | 수정 | 5 | 단순화 |
| `lib/app.dart` | 신규 | 17 | ExerciseApp 분리 |
| `lib/screens/exercise_screen.dart` | 신규 | 569 | 메인 화면 |
| `lib/exercise.dart` | 삭제 | - | 분리 완료 |
| `PROJECT_STRUCTURE.md` | 업데이트 | 186 | 간소화 (648→186줄) |

---

## 마이그레이션 가이드

### 다른 브랜치에서 이 구조로 전환하기

1. **백업**
```bash
cp lib/main.dart lib/main.dart.backup
```

2. **새 파일 생성**
```bash
mkdir lib/screens
# app.dart 생성
# screens/exercise_screen.dart 생성
```

3. **기존 코드 이동**
- ExerciseApp → app.dart
- CameraPreviewWidget → screens/exercise_screen.dart
- main() → main.dart (5줄만)

4. **import 경로 수정**
- `import 'exercise.dart'` → `import 'screens/exercise_screen.dart'`
- 상대 경로에 `../` 추가

5. **테스트**
```bash
flutter analyze
flutter run
```

---

## 결론

✅ 구조가 명확해지고 충돌 가능성이 크게 감소했습니다.  
✅ 새로운 기능 추가가 쉬워졌습니다.  
✅ 코드 가독성과 유지보수성이 향상되었습니다.

