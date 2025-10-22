# AI 기반 모바일 PT 앱 (Flutter)

스마트폰 카메라와 AI로 실시간 자세 인식/피드백을 제공하고, 개인화 루틴/식단/기록을 통합 관리하는 크로스플랫폼 앱입니다.

프로젝트 핵심 요약과 아키텍처/요구사항/로드맵은 `문서/문서_요약.md`에 통합되어 있습니다.

## Prerequisites
- Flutter SDK (stable), Dart SDK `^3.9.2` 호환
- Android 10+/iOS 14+ 디바이스 또는 에뮬레이터

## Quick Start
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

## 프로젝트 구조(계획)
- 상태관리: Riverpod, 라우팅: GoRouter
- 폴더링(요약):
  - `lib/core` – 상수/에러/네트워크/스토리지
  - `lib/features` – 도메인별 `data/domain/presentation`
  - `lib/common` – 공용 위젯/스타일

현 시점 코드는 단일 파일 목업(`lib/main.dart`)이며, 단계적으로 위 구조로 리팩터링 예정입니다.

## 서버/AI 연동(개요)
- 서버: Spring Boot + PostgreSQL (REST API)
- 인증: Firebase Auth(JWT), 통신: HTTPS(TLS1.2+)
- AI: On-device TFLite + MediaPipe Pose(33 랜드마크), 필요 시 경량 서버 추론 폴백

엔드포인트/스키마/성능 목표 등 상세는 `문서/문서_요약.md`의 4, 6, 8장을 참고하세요.
