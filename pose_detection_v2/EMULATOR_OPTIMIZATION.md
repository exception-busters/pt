# 🚀 Android 에뮬레이터 메모리 최적화 가이드

## 📱 에뮬레이터 설정 최적화

### 1. AVD Manager에서 에뮬레이터 설정 변경
- **RAM**: 2048MB (기본값보다 낮게)
- **VM Heap**: 256MB
- **Internal Storage**: 4GB (충분한 용량)
- **SD Card**: 비활성화 (필요시에만)

### 2. 하드웨어 가속 설정
- **Graphics**: Software - GLES 2.0 (호스트 GPU 사용)
- **Multi-Core CPU**: 2 cores (4 cores → 2 cores)
- **Hardware - GLES 2.0**: 활성화

### 3. 에뮬레이터 실행 옵션
```bash
# 메모리 제한된 에뮬레이터 실행
emulator -avd YOUR_AVD_NAME -memory 2048 -cores 2 -gpu swiftshader_indirect
```

## 🔧 추가 최적화 방법

### A. 불필요한 앱 제거
- Google Play Store 앱들 비활성화
- 기본 앱들 중 사용하지 않는 것들 제거

### B. 개발자 옵션 설정
- **Background process limit**: 2 processes
- **Don't keep activities**: 활성화 (메모리 절약)
- **Hardware acceleration**: 활성화

### C. 시스템 UI 튜너
- 애니메이션 효과 줄이기
- 불필요한 위젯 제거

## 📊 예상 메모리 절약 효과
- **기존**: ~14GB
- **최적화 후**: ~6-8GB (약 40-50% 절약)

## ⚠️ 주의사항
- 너무 낮은 메모리 설정은 앱 크래시를 일으킬 수 있음
- 포즈 감지 성능이 약간 떨어질 수 있음
- 테스트하면서 적절한 균형점 찾기 필요
