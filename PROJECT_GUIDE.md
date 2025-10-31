# Motion Recognition App - 완전 가이드라인

## 📋 목차
1. [프로젝트 개요](#프로젝트-개요)
2. [기술 스택](#기술-스택)
3. [프로젝트 구조](#프로젝트-구조)
4. [핵심 로직 설명](#핵심-로직-설명)
5. [이미지 포맷 변환](#이미지-포맷-변환)
6. [포즈 감지 및 스켈레톤 렌더링](#포즈-감지-및-스켈레톤-렌더링)
7. [각도 계산 및 피드백](#각도-계산-및-피드백)
8. [설정 파일](#설정-파일)
9. [빌드 및 실행](#빌드-및-실행)
10. [트러블슈팅](#트러블슈팅)

---

## 프로젝트 개요

### 목적
실시간 카메라를 통해 사용자의 포즈를 감지하고, 운동 동작(스쿼트)을 분석하여 피드백을 제공하는 Flutter 애플리케이션

### 주요 기능
- 실시간 포즈 감지 (Google ML Kit Pose Detection)
- 스켈레톤 시각화 (33개 랜드마크 포인트)
- 무릎 각도 계산을 통한 스쿼트 자세 분석
- 실시간 피드백 제공 ("Good", "Stand up straight", "Too low")

---

## 기술 스택

### Flutter & Dart
- **Flutter SDK**: 3.9.2 이상
- **Dart SDK**: 3.9.2 이상

### 주요 패키지
```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  google_mlkit_pose_detection: ^0.14.0  # ML Kit 포즈 감지
  camera: ^0.11.0+2                      # 카메라 접근
```

### Android 설정
- **minSdk**: 21 이상
- **compileSdk**: Flutter 기본 설정
- **targetSdk**: Flutter 기본 설정
- **Java Version**: 11
- **Kotlin**: 최신 버전

### ML Kit 의존성
```kotlin
dependencies {
    implementation("com.google.mlkit:pose-detection-accurate:18.0.0-beta3")
}
```

---

## 프로젝트 구조

```
motion_recognition_app/
├── lib/
│   ├── main.dart                 # 메인 앱 + 카메라 + 포즈 감지 로직
│   ├── pose_painter.dart         # 스켈레톤 렌더링 (CustomPainter)
│   └── angle_calculator.dart     # 각도 계산 유틸리티
├── android/
│   ├── app/
│   │   ├── build.gradle.kts      # Android 빌드 설정
│   │   └── src/main/
│   │       └── AndroidManifest.xml  # 카메라 권한 설정
├── pubspec.yaml                  # 패키지 의존성
├── analysis_options.yaml         # Linter 설정
└── PROJECT_GUIDE.md             # 이 문서
```

---

## 핵심 로직 설명

### 1. 애플리케이션 구조

#### main.dart 주요 클래스

```dart
// 앱 엔트리 포인트
void main() {
  runApp(const MyApp());
}

// 메인 앱 위젯
class MyApp extends StatelessWidget {
  // MaterialApp 설정
}

// 카메라 프리뷰 위젯
class CameraPreviewWidget extends StatefulWidget {
  // 카메라와 포즈 감지 통합
}

// 상태 관리
class _CameraPreviewWidgetState extends State<CameraPreviewWidget> {
  // 모든 로직이 여기에 구현됨
}
```

#### 상태 변수

```dart
CameraController? _controller;        // 카메라 컨트롤러
List<CameraDescription>? _cameras;    // 사용 가능한 카메라 목록
bool _isCameraInitialized = false;    // 카메라 초기화 상태
late final PoseDetector _poseDetector; // ML Kit 포즈 감지기
bool _isBusy = false;                 // 이미지 처리 중 플래그
List<Pose> _poses = [];               // 감지된 포즈 목록
Size? _imageSize;                     // 카메라 이미지 크기
String _feedback = '';                // 사용자 피드백 메시지
int _frameCount = 0;                  // 처리된 프레임 카운트
int _skipFrames = 0;                  // 프레임 스킵 카운터
```

---

### 2. 초기화 프로세스

#### 2.1 포즈 감지기 초기화

```dart
void _initializePoseDetector() {
  final options = PoseDetectorOptions(
    mode: PoseDetectionMode.stream,  // 실시간 스트리밍 모드
    model: PoseDetectionModel.base,  // base 모델 (빠르고 가벼움)
  );
  _poseDetector = PoseDetector(options: options);
  print('포즈 감지기 초기화 완료 - base 모델 사용');
}
```

**모델 선택:**
- `PoseDetectionModel.base`: 빠르고 가벼움, 정확도 중간
- `PoseDetectionModel.accurate`: 느리지만 정확, 리소스 많이 사용

**모드 선택:**
- `PoseDetectionMode.stream`: 실시간 비디오 스트림 (이 프로젝트)
- `PoseDetectionMode.single`: 단일 이미지 처리

#### 2.2 카메라 초기화

```dart
Future<void> _initializeCamera() async {
  // 1. 사용 가능한 카메라 목록 가져오기
  _cameras = await availableCameras();
  print('사용 가능한 카메라: ${_cameras?.length}개');
  
  if (_cameras != null && _cameras!.isNotEmpty) {
    // 2. 전면 카메라 찾기
    CameraDescription? frontCamera;
    for (var camera in _cameras!) {
      if (camera.lensDirection == CameraLensDirection.front) {
        frontCamera = camera;
        print('전면 카메라 발견: ${camera.name}');
        break;
      }
    }
    
    // 3. 전면 카메라가 없으면 첫 번째 카메라 사용
    final selectedCamera = frontCamera ?? _cameras![0];
    print('선택된 카메라: ${selectedCamera.lensDirection}');
    
    // 4. 카메라 컨트롤러 생성 (low 해상도)
    _controller = CameraController(selectedCamera, ResolutionPreset.low);
    
    // 5. 초기화
    await _controller!.initialize();
    if (!mounted) return;
    
    // 6. 이미지 크기 저장
    _imageSize = _controller!.value.previewSize;
    print('카메라 초기화 완료 - 프리뷰 크기: $_imageSize');
    print('센서 방향: ${selectedCamera.sensorOrientation}');
    
    // 7. 이미지 스트림 시작
    _controller!.startImageStream((image) {
      _processCameraImage(image);
    });
    
    // 8. UI 업데이트
    setState(() {
      _isCameraInitialized = true;
    });
  }
}
```

**해상도 옵션:**
- `ResolutionPreset.low`: 320x240 (이 프로젝트, 성능 최적화)
- `ResolutionPreset.medium`: 720x480
- `ResolutionPreset.high`: 1280x720
- `ResolutionPreset.veryHigh`: 1920x1080

---

### 3. 이미지 처리 파이프라인

#### 3.1 프레임 처리 흐름

```dart
Future<void> _processCameraImage(CameraImage image) async {
  // 1. 중복 처리 방지
  if (_isBusy) return;
  
  // 2. 프레임 스킵 (3프레임 중 1개만 처리)
  _skipFrames++;
  if (_skipFrames % 3 != 0) {
    return;
  }
  
  // 3. 처리 시작 플래그 설정
  _isBusy = true;
  _frameCount++;

  // 4. CameraImage → InputImage 변환
  final inputImage = _inputImageFromCameraImage(image);
  if (inputImage == null) {
    if (_frameCount % 10 == 0) {
      print('InputImage 생성 실패!');
    }
    _isBusy = false;
    return;
  }

  // 5. 로그 출력 (10프레임마다)
  if (_frameCount % 10 == 1) {
    print('이미지 처리 중... 크기: ${image.width}x${image.height}');
  }

  // 6. ML Kit 포즈 감지 실행
  try {
    final poses = await _poseDetector.processImage(inputImage);

    if (_frameCount % 10 == 1) {
      print('포즈 처리 완료: ${poses.length}개 감지');
    }

    if (poses.isNotEmpty) {
      if (_frameCount % 10 == 1) {
        print('✓ 포즈 감지 성공!');
        final pose = poses[0];
        print('랜드마크 개수: ${pose.landmarks.length}');
      }
    } else {
      if (_frameCount % 10 == 1) {
        print('✗ 포즈 감지 안됨 - 몸 전체가 보이는지 확인하세요');
      }
    }

    // 7. UI 업데이트
    setState(() {
      _poses = poses;
      _updateFeedback();
    });
  } catch (e) {
    if (_frameCount % 10 == 1) {
      print('포즈 감지 오류: $e');
    }
  }

  // 8. 처리 완료 플래그 해제
  _isBusy = false;
}
```

**성능 최적화 포인트:**
- `_isBusy` 플래그: 동시 처리 방지
- 프레임 스킵: CPU 부하 감소 (3프레임 중 1개만 처리)
- 조건부 로그: 콘솔 출력 최소화

---

## 이미지 포맷 변환

### YUV_420_888 → NV21 변환 로직

이 부분이 **가장 중요하고 복잡한 로직**입니다.

#### 문제 상황
- Android 카메라는 `YUV_420_888` 포맷으로 이미지를 제공
- Google ML Kit은 `NV21` 또는 `YUV420` 포맷만 지원
- 직접 변환이 필요함

#### YUV_420_888 구조

```
이미지 크기: 320x240 (width x height)

Plane 0 (Y - 밝기):
- 크기: 320 x 240 = 76,800 bytes
- bytesPerRow: 320
- 모든 픽셀의 밝기 정보

Plane 1 (U - 색차):
- 크기: 160 x 120 = 19,200 pixels (서브샘플링)
- bytesPerRow: 320 (stride)
- 실제 데이터: 38,399 bytes (패딩 포함)

Plane 2 (V - 색차):
- 크기: 160 x 120 = 19,200 pixels
- bytesPerRow: 320 (stride)
- 실제 데이터: 38,399 bytes (패딩 포함)
```

#### NV21 구조

```
NV21 = Y plane + VU interleaved

예시 (320x240):
[Y0, Y1, Y2, ..., Y76799,  V0, U0, V1, U1, ..., V19199, U19199]
 |-- Y plane (76,800) ---|  |---- VU interleaved (38,400) ----|
```

#### 변환 코드 상세

```dart
InputImage? _inputImageFromCameraImage(CameraImage image) {
  final camera = _controller!.description;
  final sensorOrientation = camera.sensorOrientation;
  
  // 1. 회전 값 계산
  InputImageRotation? rotation;
  if (sensorOrientation == 0) {
    rotation = InputImageRotation.rotation0deg;
  } else if (sensorOrientation == 90) {
    rotation = InputImageRotation.rotation90deg;
  } else if (sensorOrientation == 180) {
    rotation = InputImageRotation.rotation180deg;
  } else if (sensorOrientation == 270) {
    rotation = InputImageRotation.rotation270deg;
  }
  
  if (rotation == null) {
    if (_frameCount % 30 == 1) {
      print('회전 값을 구할 수 없음: $sensorOrientation');
    }
    return null;
  }

  // 2. 이미지 포맷 확인
  final format = InputImageFormatValue.fromRawValue(image.format.raw);
  if (format == null) {
    if (_frameCount % 30 == 1) {
      print('지원하지 않는 이미지 포맷: ${image.format.raw}');
    }
    return null;
  }

  // 3. Plane 데이터 확인
  if (image.planes.isEmpty) {
    return null;
  }

  if (_frameCount % 30 == 1) {
    print('InputImage - 크기: ${image.width}x${image.height}, 포맷: $format');
    print('회전: $rotation, 평면 수: ${image.planes.length}');
  }

  // 4. YUV_420_888 → NV21 변환
  final WriteBuffer allBytes = WriteBuffer();
  
  // 4-1. Y plane 복사 (밝기 정보 전체)
  allBytes.putUint8List(image.planes[0].bytes);
  
  // 4-2. U와 V plane을 인터리브 (NV21 형식: YYYYYYYY VUVUVUVU)
  final int uvWidth = image.width ~/ 2;      // 160 (서브샘플링)
  final int uvHeight = image.height ~/ 2;    // 120
  
  // V와 U를 번갈아가며 배치 (NV21 = Y + VU)
  for (int i = 0; i < uvHeight * uvWidth; i++) {
    // V (Cr) - Plane 2
    if (i < image.planes[2].bytes.length) {
      allBytes.putUint8(image.planes[2].bytes[i]);
    }
    // U (Cb) - Plane 1
    if (i < image.planes[1].bytes.length) {
      allBytes.putUint8(image.planes[1].bytes[i]);
    }
  }
  
  final bytes = allBytes.done().buffer.asUint8List();
  
  if (_frameCount % 30 == 1) {
    print('NV21 변환 완료 - 총 바이트: ${bytes.length}');
  }
  
  // 5. InputImageMetadata 생성
  final inputImageData = InputImageMetadata(
    size: Size(image.width.toDouble(), image.height.toDouble()),
    rotation: rotation,
    format: InputImageFormat.nv21,  // NV21로 명시
    bytesPerRow: image.width,       // Y plane의 stride
  );

  // 6. InputImage 생성 및 반환
  return InputImage.fromBytes(bytes: bytes, metadata: inputImageData);
}
```

#### 바이트 계산

```
원본 YUV_420_888 (320x240):
- Y plane:  76,800 bytes
- U plane:  38,399 bytes (패딩 포함)
- V plane:  38,399 bytes (패딩 포함)
- 총합:    153,598 bytes

변환된 NV21:
- Y plane:  76,800 bytes
- VU interleaved: 38,400 bytes (160 * 120 * 2)
- 총합:    115,200 bytes

차이 이유: 
- YUV_420_888은 stride와 패딩 때문에 더 큼
- NV21은 실제 픽셀 데이터만 포함
```

#### 회전(Rotation) 처리

```dart
// 센서 방향에 따라 이미지 회전 설정
// 전면 카메라는 보통 270도 회전되어 있음

switch (sensorOrientation) {
  case 0:   rotation = InputImageRotation.rotation0deg;    break;
  case 90:  rotation = InputImageRotation.rotation90deg;   break;
  case 180: rotation = InputImageRotation.rotation180deg;  break;
  case 270: rotation = InputImageRotation.rotation270deg;  break;
}
```

---

## 포즈 감지 및 스켈레톤 렌더링

### ML Kit Pose Detection

#### 33개 랜드마크 포인트

```dart
enum PoseLandmarkType {
  nose,                    // 0: 코
  leftEyeInner,           // 1: 왼쪽 눈 안쪽
  leftEye,                // 2: 왼쪽 눈
  leftEyeOuter,           // 3: 왼쪽 눈 바깥쪽
  rightEyeInner,          // 4: 오른쪽 눈 안쪽
  rightEye,               // 5: 오른쪽 눈
  rightEyeOuter,          // 6: 오른쪽 눈 바깥쪽
  leftEar,                // 7: 왼쪽 귀
  rightEar,               // 8: 오른쪽 귀
  leftMouth,              // 9: 왼쪽 입
  rightMouth,             // 10: 오른쪽 입
  leftShoulder,           // 11: 왼쪽 어깨 ★
  rightShoulder,          // 12: 오른쪽 어깨 ★
  leftElbow,              // 13: 왼쪽 팔꿈치 ★
  rightElbow,             // 14: 오른쪽 팔꿈치 ★
  leftWrist,              // 15: 왼쪽 손목 ★
  rightWrist,             // 16: 오른쪽 손목 ★
  leftPinky,              // 17: 왼쪽 새끼손가락
  rightPinky,             // 18: 오른쪽 새끼손가락
  leftIndex,              // 19: 왼쪽 검지
  rightIndex,             // 20: 오른쪽 검지
  leftThumb,              // 21: 왼쪽 엄지
  rightThumb,             // 22: 오른쪽 엄지
  leftHip,                // 23: 왼쪽 엉덩이 ★
  rightHip,               // 24: 오른쪽 엉덩이 ★
  leftKnee,               // 25: 왼쪽 무릎 ★★
  rightKnee,              // 26: 오른쪽 무릎 ★★
  leftAnkle,              // 27: 왼쪽 발목 ★★
  rightAnkle,             // 28: 오른쪽 발목 ★★
  leftHeel,               // 29: 왼쪽 발뒤꿈치
  rightHeel,              // 30: 오른쪽 발뒤꿈치
  leftFootIndex,          // 31: 왼쪽 발가락
  rightFootIndex,         // 32: 오른쪽 발가락
}

// ★ 표시: 스켈레톤 렌더링에 사용
// ★★ 표시: 각도 계산에 사용
```

#### 랜드마크 데이터 구조

```dart
class PoseLandmark {
  final double x;           // 이미지 내 X 좌표 (픽셀)
  final double y;           // 이미지 내 Y 좌표 (픽셀)
  final double z;           // 깊이 (현재 사용 안 함)
  final double likelihood;  // 신뢰도 (0.0 ~ 1.0)
}

// 예시
final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];
print('무릎 위치: (${leftKnee.x}, ${leftKnee.y})');
print('신뢰도: ${leftKnee.likelihood}');
```

### 스켈레톤 렌더링 (pose_painter.dart)

#### PosePainter 클래스

```dart
class PosePainter extends CustomPainter {
  final List<Pose> poses;      // 감지된 포즈 목록
  final Size imageSize;        // 원본 이미지 크기

  PosePainter(this.poses, this.imageSize);

  @override
  void paint(Canvas canvas, Size size) {
    // 캔버스에 그리기
  }

  @override
  bool shouldRepaint(PosePainter oldDelegate) {
    return oldDelegate.poses != poses || oldDelegate.imageSize != imageSize;
  }
}
```

#### paint 메서드 상세

```dart
@override
void paint(Canvas canvas, Size size) {
  // 디버그 정보
  print('PosePainter - 캔버스 크기: $size, 이미지 크기: $imageSize, 포즈 개수: ${poses.length}');
  
  // 1. 선 스타일 설정 (뼈대)
  final paint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 4.0
    ..color = Colors.greenAccent
    ..strokeCap = StrokeCap.round;

  // 2. 점 스타일 설정 (관절)
  final circlePaint = Paint()
    ..color = Colors.red
    ..style = PaintingStyle.fill;

  // 3. 각 포즈에 대해 그리기
  for (final pose in poses) {
    // 3-1. 모든 랜드마크에 점 그리기
    for (final landmark in pose.landmarks.values) {
      final translatedPoint = _translatePoint(
        landmark.x, 
        landmark.y, 
        imageSize, 
        size
      );
      canvas.drawCircle(translatedPoint, 8.0, circlePaint);
    }
    
    // 디버그: 첫 번째 랜드마크 위치
    if (pose.landmarks.isNotEmpty) {
      final firstLandmark = pose.landmarks.values.first;
      print('첫 번째 랜드마크 위치: (${firstLandmark.x}, ${firstLandmark.y})');
    }

    // 3-2. 몸통 연결
    _drawConnection(canvas, paint, pose, 
      PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder, 
      imageSize, size);
    _drawConnection(canvas, paint, pose, 
      PoseLandmarkType.leftHip, PoseLandmarkType.rightHip, 
      imageSize, size);
    _drawConnection(canvas, paint, pose, 
      PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip, 
      imageSize, size);
    _drawConnection(canvas, paint, pose, 
      PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip, 
      imageSize, size);
    
    // 3-3. 왼팔
    _drawConnection(canvas, paint, pose, 
      PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow, 
      imageSize, size);
    _drawConnection(canvas, paint, pose, 
      PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist, 
      imageSize, size);
    
    // 3-4. 오른팔
    _drawConnection(canvas, paint, pose, 
      PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow, 
      imageSize, size);
    _drawConnection(canvas, paint, pose, 
      PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist, 
      imageSize, size);
    
    // 3-5. 왼다리
    _drawConnection(canvas, paint, pose, 
      PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee, 
      imageSize, size);
    _drawConnection(canvas, paint, pose, 
      PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle, 
      imageSize, size);
    
    // 3-6. 오른다리
    _drawConnection(canvas, paint, pose, 
      PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee, 
      imageSize, size);
    _drawConnection(canvas, paint, pose, 
      PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle, 
      imageSize, size);
  }
}
```

#### 연결선 그리기

```dart
void _drawConnection(
  Canvas canvas,
  Paint paint,
  Pose pose,
  PoseLandmarkType type1,
  PoseLandmarkType type2,
  Size inputImageSize,
  Size size
) {
  // 1. 두 랜드마크 가져오기
  final landmark1 = pose.landmarks[type1];
  final landmark2 = pose.landmarks[type2];

  // 2. 둘 다 존재할 때만 그리기
  if (landmark1 != null && landmark2 != null) {
    // 3. 좌표 변환
    final point1 = _translatePoint(landmark1.x, landmark1.y, inputImageSize, size);
    final point2 = _translatePoint(landmark2.x, landmark2.y, inputImageSize, size);
    
    // 4. 선 그리기
    canvas.drawLine(point1, point2, paint);
  }
}
```

#### 좌표 변환

```dart
Offset _translatePoint(double x, double y, Size inputImageSize, Size size) {
  // 이미지 크기 → 캔버스 크기로 스케일링
  final double scaleX = size.width / inputImageSize.width;
  final double scaleY = size.height / inputImageSize.height;
  
  return Offset(x * scaleX, y * scaleY);
}
```

**좌표 변환 예시:**
```
이미지 크기: 320x240
캔버스 크기: 1080x1920

scaleX = 1080 / 320 = 3.375
scaleY = 1920 / 240 = 8.0

랜드마크 좌표: (100, 50)
변환된 좌표: (100 * 3.375, 50 * 8.0) = (337.5, 400.0)
```

---

## 각도 계산 및 피드백

### angle_calculator.dart

#### 3점 각도 계산

```dart
import 'dart:math';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class AngleCalculator {
  /// 세 점으로 이루어진 각도 계산 (degree)
  /// 
  /// point1 -----> point2 -----> point3
  ///                 ^
  ///                 | 
  ///              이 각도를 계산
  static double calculateAngle(
    PoseLandmark point1,  // 엉덩이
    PoseLandmark point2,  // 무릎 (중심점)
    PoseLandmark point3,  // 발목
  ) {
    // 1. 벡터 계산
    // 벡터 A: point2 → point1
    final double radians = atan2(
      point3.y - point2.y,  // 벡터 B의 y
      point3.x - point2.x   // 벡터 B의 x
    ) - atan2(
      point1.y - point2.y,  // 벡터 A의 y
      point1.x - point2.x   // 벡터 A의 x
    );

    // 2. 라디안 → 도(degree) 변환
    double angle = radians * 180.0 / pi;

    // 3. 각도를 0~180 범위로 정규화
    angle = angle.abs();
    if (angle > 180.0) {
      angle = 360.0 - angle;
    }

    return angle;
  }
}
```

#### 각도 계산 수학 원리

```
벡터 A = (point1.x - point2.x, point1.y - point2.y)
벡터 B = (point3.x - point2.x, point3.y - point2.y)

각도 θ = atan2(벡터B) - atan2(벡터A)

예시 (스쿼트):
- 엉덩이 (100, 50)
- 무릎 (100, 100)  <- 중심점
- 발목 (100, 150)

벡터 A = (100-100, 50-100) = (0, -50)
벡터 B = (100-100, 150-100) = (0, 50)

atan2(50, 0) = 90° (π/2)
atan2(-50, 0) = -90° (-π/2)

θ = 90° - (-90°) = 180°  (다리를 완전히 펼 때)
```

### 피드백 로직

```dart
void _updateFeedback() {
  if (_poses.isNotEmpty) {
    final pose = _poses[0];  // 첫 번째 포즈 사용
    
    // 1. 왼쪽 다리 랜드마크 가져오기
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];
    final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];

    // 2. 모든 랜드마크가 감지되었는지 확인
    if (leftHip != null && leftKnee != null && leftAnkle != null) {
      // 3. 무릎 각도 계산
      final angle = AngleCalculator.calculateAngle(
        leftHip,
        leftKnee,
        leftAnkle,
      );
      
      // 4. 각도에 따른 피드백
      if (angle > 160) {
        _feedback = 'Stand up straight';  // 거의 서 있음
      } else if (angle < 70) {
        _feedback = 'Too low';            // 너무 낮게 앉음
      } else {
        _feedback = 'Good';               // 적절한 스쿼트 자세
      }
    } else {
      _feedback = '';  // 랜드마크 감지 안됨
    }
  } else {
    _feedback = '';  // 포즈 감지 안됨
  }
}
```

#### 각도 범위 설명

```
180° ──────────────────── 완전히 선 상태
      ↑
160° ─┤ "Stand up straight"
      │
      │  적절한 범위
      │
70°  ─┤ "Good" (70° ~ 160°)
      │
      ↓
0°   ──────────────────── "Too low"
```

**각도 범위 조정:**
```dart
// 더 엄격한 기준
if (angle > 150) {
  _feedback = 'Stand up straight';
} else if (angle < 90) {
  _feedback = 'Too low';
} else {
  _feedback = 'Good';
}

// 더 관대한 기준
if (angle > 170) {
  _feedback = 'Stand up straight';
} else if (angle < 60) {
  _feedback = 'Too low';
} else {
  _feedback = 'Good';
}
```

---

## UI 구조

### 메인 화면 레이아웃

```dart
@override
Widget build(BuildContext context) {
  // 1. 카메라 초기화 중
  if (!_isCameraInitialized) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator())
    );
  }
  
  // 2. 메인 화면
  return Scaffold(
    appBar: AppBar(
      title: const Text('Pose Detection'),
      backgroundColor: Colors.black87,
    ),
    body: Stack(
      fit: StackFit.expand,
      children: [
        // 레이어 1: 카메라 프리뷰
        CameraPreview(_controller!),
        
        // 레이어 2: 스켈레톤 오버레이
        if (_imageSize != null)
          CustomPaint(painter: PosePainter(_poses, _imageSize!)),
        
        // 레이어 3: 포즈 감지 상태 표시 (상단)
        Positioned(
          top: 10,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: _poses.isEmpty
                    ? Colors.red.withValues(alpha: 0.7)
                    : Colors.green.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _poses.isEmpty ? '포즈 감지 안됨' : '포즈 감지됨 ✓',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        
        // 레이어 4: 피드백 메시지 (하단)
        Positioned(
          bottom: 50,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Text(
                _feedback.isEmpty ? '몸 전체가 보이도록 서주세요' : _feedback,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
```

#### 화면 레이어 구조

```
┌─────────────────────────────────┐
│  ┌──────────────────────┐       │ ← 레이어 3: 상태 표시
│  │ 포즈 감지됨 ✓        │       │
│  └──────────────────────┘       │
│                                  │
│  ┌────────────────────────────┐ │
│  │                            │ │
│  │     카메라 프리뷰          │ │ ← 레이어 1: 카메라
│  │                            │ │
│  │  + 스켈레톤 오버레이       │ │ ← 레이어 2: 스켈레톤
│  │                            │ │
│  └────────────────────────────┘ │
│                                  │
│  ┌──────────────────────┐       │
│  │      Good            │       │ ← 레이어 4: 피드백
│  └──────────────────────┘       │
└─────────────────────────────────┘
```

---

## 설정 파일

### pubspec.yaml

```yaml
name: motion_recognition_app
description: "A new Flutter project."
publish_to: 'none'

version: 1.0.0+1

environment:
  sdk: ^3.9.2

dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  google_mlkit_pose_detection: ^0.14.0  # ML Kit 포즈 감지
  camera: ^0.11.0+2                      # 카메라 접근

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0

flutter:
  uses-material-design: true
```

### android/app/build.gradle.kts

```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.motion_recognition_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.motion_recognition_app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    dependencies {
        implementation("com.google.mlkit:pose-detection-accurate:18.0.0-beta3")
    }
}

flutter {
    source = "../.."
}
```

### android/app/src/main/AndroidManifest.xml

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- 카메라 권한 -->
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-feature android:name="android.hardware.camera" />
    <uses-feature android:name="android.hardware.camera.autofocus" />
    
    <application
        android:label="motion_recognition_app"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:taskAffinity=""
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
            <meta-data
              android:name="io.flutter.embedding.android.NormalTheme"
              android:resource="@style/NormalTheme"
              />
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
        <meta-data
            android:name="flutterEmbedding"
            android:value="2" />
    </application>
    
    <queries>
        <intent>
            <action android:name="android.intent.action.PROCESS_TEXT"/>
            <data android:mimeType="text/plain"/>
        </intent>
    </queries>
</manifest>
```

### analysis_options.yaml

```yaml
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    avoid_print: false  # print 경고 비활성화
```

---

## 빌드 및 실행

### 사전 요구사항

1. **Flutter 설치**
   ```bash
   flutter doctor
   ```

2. **Android Studio 또는 VS Code**
   - Android SDK 설치
   - Android Emulator 또는 실제 기기

3. **의존성 설치**
   ```bash
   cd motion_recognition_app
   flutter pub get
   ```

### 빌드 및 실행

#### 방법 1: Android Studio

1. Android Studio에서 프로젝트 열기
2. 기기 선택 (에뮬레이터 또는 실제 기기)
3. Run 버튼 클릭 (Shift + F10)

#### 방법 2: 명령줄

```bash
# 연결된 기기 확인
flutter devices

# 디버그 모드 실행
flutter run

# 릴리스 모드 빌드
flutter build apk --release

# 특정 기기에서 실행
flutter run -d <device-id>
```

### 첫 실행 시

1. **ML Kit 모델 다운로드**
   - 첫 실행 시 자동으로 포즈 감지 모델 다운로드
   - Wi-Fi 연결 필요
   - 약 10~20MB 크기

2. **카메라 권한 허용**
   - 앱 실행 시 카메라 권한 요청
   - "허용" 선택 필요

---

## 트러블슈팅

### 일반적인 오류

#### 1. InputImageConverterError

**오류 메시지:**
```
PlatformException(InputImageConverterError, ImageFormat is not supported., null, null)
```

**원인:**
- YUV_420_888 포맷을 ML Kit이 직접 지원하지 않음

**해결:**
- YUV_420_888 → NV21 변환 로직 사용 (이미 구현됨)
- `_inputImageFromCameraImage` 메서드 확인

#### 2. 포즈 감지 안됨

**증상:**
- "포즈 감지 안됨" 메시지 계속 표시
- 스켈레톤이 그려지지 않음

**해결 방법:**

1. **조명 확인**
   - 밝은 곳에서 테스트
   - 역광 피하기

2. **거리 조정**
   - 카메라에서 2~3미터 떨어지기
   - 몸 전체가 화면에 들어오도록

3. **카메라 해상도 조정**
   ```dart
   // main.dart에서
   _controller = CameraController(
     selectedCamera, 
     ResolutionPreset.medium  // low → medium으로 변경
   );
   ```

4. **모델 변경**
   ```dart
   // main.dart에서
   final options = PoseDetectorOptions(
     mode: PoseDetectionMode.stream,
     model: PoseDetectionModel.accurate,  // base → accurate로 변경
   );
   ```

#### 3. 앱 느림 / 프레임 드롭

**원인:**
- 포즈 감지가 CPU 집약적임

**해결:**

1. **프레임 스킵 증가**
   ```dart
   // main.dart에서
   if (_skipFrames % 5 != 0) {  // 3 → 5로 변경
     return;
   }
   ```

2. **해상도 낮추기**
   ```dart
   _controller = CameraController(
     selectedCamera, 
     ResolutionPreset.low
   );
   ```

3. **base 모델 사용**
   ```dart
   model: PoseDetectionModel.base,
   ```

#### 4. Gradle 빌드 오류

**오류 메시지:**
```
Execution failed for task ':app:checkDebugAarMetadata'
```

**해결:**
```bash
cd motion_recognition_app
flutter clean
flutter pub get
flutter run
```

#### 5. 카메라 권한 오류

**오류 메시지:**
```
CameraException: Camera permission not granted
```

**해결:**
1. AndroidManifest.xml 확인 (이미 설정됨)
2. 기기 설정에서 수동으로 권한 허용
3. 앱 재설치

### 디버깅 팁

#### 1. Logcat 확인

Android Studio Logcat에서 다음 메시지 확인:

```
✓ 성공적인 실행:
포즈 감지기 초기화 완료 - base 모델 사용
사용 가능한 카메라: 2개
전면 카메라 발견: ...
선택된 카메라: CameraLensDirection.front
카메라 초기화 완료 - 프리뷰 크기: Size(...)
InputImage - 크기: 320x240, 포맷: InputImageFormat.yuv_420_888
NV21 변환 완료 - 총 바이트: 115200
포즈 처리 완료: 1개 감지
✓ 포즈 감지 성공!
랜드마크 개수: 33

✗ 문제 발생:
포즈 처리 완료: 0개 감지
✗ 포즈 감지 안됨 - 몸 전체가 보이는지 확인하세요
```

#### 2. 성능 모니터링

```dart
// main.dart에 추가
Stopwatch? _stopwatch;

Future<void> _processCameraImage(CameraImage image) async {
  _stopwatch = Stopwatch()..start();
  
  // ... 기존 코드 ...
  
  final poses = await _poseDetector.processImage(inputImage);
  
  _stopwatch!.stop();
  if (_frameCount % 10 == 1) {
    print('처리 시간: ${_stopwatch!.elapsedMilliseconds}ms');
  }
  
  // ... 나머지 코드 ...
}
```

---

## 성능 최적화

### 현재 최적화 사항

1. **프레임 스킵**: 3프레임 중 1개만 처리
2. **낮은 해상도**: ResolutionPreset.low (320x240)
3. **base 모델**: 빠른 처리 속도
4. **중복 처리 방지**: `_isBusy` 플래그
5. **조건부 로그**: 10/30프레임마다만 출력

### 추가 최적화 방법

#### 1. 관심 영역만 처리

```dart
// 상체만 감지하도록 이미지 자르기
InputImage? _inputImageFromCameraImage(CameraImage image) {
  // 이미지 하단 절반만 사용
  final croppedHeight = image.height ~/ 2;
  // ... 자르기 로직 추가
}
```

#### 2. 비동기 처리

```dart
// compute 함수로 격리된 스레드에서 처리
Future<InputImage?> _convertImageInIsolate(CameraImage image) async {
  return await compute(_inputImageFromCameraImage, image);
}
```

#### 3. 캐싱

```dart
// 최근 포즈 결과 캐싱
Pose? _lastValidPose;
int _noDetectionCount = 0;

void _updateFeedback() {
  if (_poses.isNotEmpty) {
    _lastValidPose = _poses[0];
    _noDetectionCount = 0;
  } else if (_lastValidPose != null && _noDetectionCount < 10) {
    // 최근 포즈 사용 (10프레임까지)
    _noDetectionCount++;
    _poses = [_lastValidPose!];
  }
  // ... 피드백 계산
}
```

---

## 확장 기능 아이디어

### 1. 운동 카운터

```dart
class ExerciseCounter {
  int _count = 0;
  bool _isDown = false;
  
  void updateSquatCount(double angle) {
    if (!_isDown && angle < 90) {
      _isDown = true;
    } else if (_isDown && angle > 160) {
      _isDown = false;
      _count++;
      print('스쿼트 횟수: $_count');
    }
  }
  
  int get count => _count;
  void reset() => _count = 0;
}

// 사용
ExerciseCounter _squatCounter = ExerciseCounter();

void _updateFeedback() {
  // ... 각도 계산
  _squatCounter.updateSquatCount(angle);
}
```

### 2. 다른 운동 추가

```dart
enum ExerciseType {
  squat,
  pushup,
  lunge,
}

ExerciseType _currentExercise = ExerciseType.squat;

void _updateFeedbackForExercise() {
  switch (_currentExercise) {
    case ExerciseType.squat:
      _updateSquatFeedback();
      break;
    case ExerciseType.pushup:
      _updatePushupFeedback();
      break;
    case ExerciseType.lunge:
      _updateLungeFeedback();
      break;
  }
}

void _updatePushupFeedback() {
  // 팔꿈치 각도 계산
  final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
  final leftElbow = pose.landmarks[PoseLandmarkType.leftElbow];
  final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
  
  if (leftShoulder != null && leftElbow != null && leftWrist != null) {
    final angle = AngleCalculator.calculateAngle(
      leftShoulder,
      leftElbow,
      leftWrist,
    );
    // ... 피드백 로직
  }
}
```

### 3. 운동 기록 저장

```dart
class WorkoutSession {
  final DateTime startTime;
  final DateTime endTime;
  final ExerciseType type;
  final int count;
  final Duration duration;
  
  WorkoutSession({
    required this.startTime,
    required this.endTime,
    required this.type,
    required this.count,
    required this.duration,
  });
  
  Map<String, dynamic> toJson() => {
    'startTime': startTime.toIso8601String(),
    'endTime': endTime.toIso8601String(),
    'type': type.toString(),
    'count': count,
    'duration': duration.inSeconds,
  };
}

// SharedPreferences 또는 SQLite로 저장
```

### 4. 음성 피드백

```dart
import 'package:flutter_tts/flutter_tts.dart';

class VoiceFeedback {
  final FlutterTts _tts = FlutterTts();
  
  Future<void> speak(String message) async {
    await _tts.setLanguage('ko-KR');
    await _tts.speak(message);
  }
}

// 사용
VoiceFeedback _voiceFeedback = VoiceFeedback();

void _updateFeedback() {
  // ... 피드백 계산
  if (_feedback != _previousFeedback) {
    _voiceFeedback.speak(_feedback);
    _previousFeedback = _feedback;
  }
}
```

---

## 라이선스 및 참고

### 사용된 오픈소스 라이선스

- **Flutter**: BSD 3-Clause License
- **google_mlkit_pose_detection**: BSD 3-Clause License
- **camera**: BSD 3-Clause License

### 참고 문서

- [Google ML Kit Pose Detection](https://developers.google.com/ml-kit/vision/pose-detection)
- [Flutter Camera Plugin](https://pub.dev/packages/camera)
- [Flutter CustomPainter](https://api.flutter.dev/flutter/rendering/CustomPainter-class.html)
- [YUV 이미지 포맷](https://en.wikipedia.org/wiki/YUV)

---

## 프로젝트 히스토리

### 주요 해결 과제

1. **YUV_420_888 → NV21 변환**
   - 문제: ML Kit이 YUV_420_888 직접 지원 안 함
   - 해결: 수동으로 NV21 포맷으로 변환하는 로직 구현

2. **성능 최적화**
   - 문제: 실시간 포즈 감지로 인한 프레임 드롭
   - 해결: 프레임 스킵, 낮은 해상도, base 모델 사용

3. **좌표 변환**
   - 문제: 카메라 이미지 좌표 → 화면 좌표 변환
   - 해결: 스케일링 기반 좌표 변환 로직

4. **카메라 회전 처리**
   - 문제: 센서 방향에 따른 이미지 회전
   - 해결: InputImageRotation 설정

---

## 개발자 노트

### 중요 개념

1. **YUV 색 공간**: Y(밝기) + UV(색차)로 구성
2. **서브샘플링**: UV 데이터는 Y 데이터의 1/4 크기
3. **NV21 포맷**: Y plane + VU interleaved
4. **ML Kit 랜드마크**: 33개 신체 포인트 제공
5. **각도 계산**: atan2를 사용한 벡터 각도 계산

### 최적화 우선순위

1. 프레임 스킵 > 해상도 낮추기 > 모델 변경
2. 성능 > 정확도 (실시간 앱의 특성상)
3. 사용자 경험 > 완벽한 감지

### 테스트 환경

- Android 기기 권장 (에뮬레이터보다 실제 기기)
- 밝은 조명 필요
- 2~3미터 거리 유지
- 몸 전체가 화면에 들어와야 함

---

## 버전 정보

- **프로젝트 버전**: 1.0.0
- **Flutter SDK**: 3.9.2+
- **google_mlkit_pose_detection**: 0.14.0
- **camera**: 0.11.0+2
- **마지막 업데이트**: 2025-10-31

---

## 연락처

프로젝트 관련 문의:
- GitHub: https://github.com/exception-busters/pt
- Branch: chaewon-2

---

**이 문서는 Motion Recognition App의 모든 기술적 세부사항을 포함합니다.**

