import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:motion_recognition_app/angle_calculator.dart';
import 'package:motion_recognition_app/pose_painter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const CameraPreviewWidget(),
    );
  }
}

class CameraPreviewWidget extends StatefulWidget {
  const CameraPreviewWidget({super.key});

  @override
  State<CameraPreviewWidget> createState() => _CameraPreviewWidgetState();
}

class _CameraPreviewWidgetState extends State<CameraPreviewWidget> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  late final PoseDetector _poseDetector;
  bool _isBusy = false;
  List<Pose> _poses = [];
  Size? _imageSize;
  String _feedback = '';
  int _frameCount = 0;
  int _skipFrames = 0; // 프레임 스킵용

  @override
  void initState() {
    super.initState();
    _initializePoseDetector();
    _initializeCamera();
  }

  void _initializePoseDetector() {
    final options = PoseDetectorOptions(
      mode: PoseDetectionMode.stream,
      model: PoseDetectionModel.base, // accurate는 무겁고 오류가 많아서 base로 변경
    );
    _poseDetector = PoseDetector(options: options);
    print('포즈 감지기 초기화 완료 - base 모델 사용');
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    print('사용 가능한 카메라: ${_cameras?.length}개');

    if (_cameras != null && _cameras!.isNotEmpty) {
      // 전면 카메라 찾기
      CameraDescription? frontCamera;
      for (var camera in _cameras!) {
        if (camera.lensDirection == CameraLensDirection.front) {
          frontCamera = camera;
          print('전면 카메라 발견: ${camera.name}');
          break;
        }
      }

      // 전면 카메라가 없으면 첫 번째 카메라 사용
      final selectedCamera = frontCamera ?? _cameras![0];
      print('선택된 카메라: ${selectedCamera.lensDirection}');

      // low 해상도로 변경 (처리 속도 향상 및 오류 감소)
      _controller = CameraController(selectedCamera, ResolutionPreset.low);
      await _controller!.initialize();
      if (!mounted) {
        return;
      }
      _imageSize = _controller!.value.previewSize;
      print('카메라 초기화 완료 - 프리뷰 크기: $_imageSize');
      print('센서 방향: ${selectedCamera.sensorOrientation}');

      _controller!.startImageStream((image) {
        _processCameraImage(image);
      });
      setState(() {
        _isCameraInitialized = true;
      });
    }
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isBusy) return;

    // 3프레임 중 1프레임만 처리 (처리 부담 감소)
    _skipFrames++;
    if (_skipFrames % 3 != 0) {
      return;
    }

    _isBusy = true;
    _frameCount++;

    final inputImage = _inputImageFromCameraImage(image);
    if (inputImage == null) {
      if (_frameCount % 10 == 0) {
        print('InputImage 생성 실패!');
      }
      _isBusy = false;
      return;
    }

    // 10프레임마다 한 번씩만 로그 출력
    if (_frameCount % 10 == 1) {
      print('이미지 처리 중... 크기: ${image.width}x${image.height}');
    }

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

      setState(() {
        _poses = poses;
        _updateFeedback();
      });
    } catch (e) {
      if (_frameCount % 10 == 1) {
        print('포즈 감지 오류: $e');
      }
    }

    _isBusy = false;
  }

  void _updateFeedback() {
    if (_poses.isNotEmpty) {
      final pose = _poses[0];
      final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
      final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];
      final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];

      if (leftHip != null && leftKnee != null && leftAnkle != null) {
        final angle = AngleCalculator.calculateAngle(
          leftHip,
          leftKnee,
          leftAnkle,
        );
        if (angle > 160) {
          _feedback = 'Stand up straight';
        } else if (angle < 70) {
          _feedback = 'Too low';
        } else {
          _feedback = 'Good';
        }
      } else {
        _feedback = '';
      }
    } else {
      _feedback = '';
    }
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    final camera = _controller!.description;
    final sensorOrientation = camera.sensorOrientation;

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

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) {
      if (_frameCount % 30 == 1) {
        print('지원하지 않는 이미지 포맷: ${image.format.raw}');
      }
      return null;
    }

    if (image.planes.isEmpty) {
      return null;
    }

    if (_frameCount % 30 == 1) {
      print('InputImage - 크기: ${image.width}x${image.height}, 포맷: $format');
      print('회전: $rotation, 평면 수: ${image.planes.length}');
    }

    // YUV_420_888을 NV21 형식으로 변환
    final WriteBuffer allBytes = WriteBuffer();

    // Y plane (전체)
    allBytes.putUint8List(image.planes[0].bytes);

    // U와 V plane을 인터리브 (NV21 형식: YYYYYYYY VUVUVUVU)
    final int uvWidth = image.width ~/ 2;
    final int uvHeight = image.height ~/ 2;

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

    final inputImageData = InputImageMetadata(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: rotation,
      format: InputImageFormat.nv21,
      bytesPerRow: image.width,
    );

    return InputImage.fromBytes(bytes: bytes, metadata: inputImageData);
  }

  @override
  void dispose() {
    _controller?.dispose();
    _poseDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pose Detection'),
        backgroundColor: Colors.black87,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(_controller!),
          if (_imageSize != null)
            CustomPaint(painter: PosePainter(_poses, _imageSize!)),
          // 포즈 감지 상태 표시
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
          // 피드백 메시지
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
}
