import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

// Models
import 'models/exercise_model.dart';

// Services
import 'services/exercise_loader.dart';
import 'services/pose_scorer.dart';
import 'services/feedback_generator.dart';
import 'services/phase_manager.dart';
import 'services/angle_smoother.dart';

// Widgets
import 'widgets/exercise_dropdown.dart';
import 'widgets/phase_progress_widget.dart';
import 'widgets/compact_score_display.dart';
import 'widgets/collapsible_feedback_panel.dart';
import 'widgets/angle_legend_widget.dart';
import 'pose_painter.dart';
import 'angle_calculator.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI 자세 교정',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const CameraPreviewWidget(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class CameraPreviewWidget extends StatefulWidget {
  const CameraPreviewWidget({Key? key}) : super(key: key);

  @override
  State<CameraPreviewWidget> createState() => _CameraPreviewWidgetState();
}

class _CameraPreviewWidgetState extends State<CameraPreviewWidget> {
  // 카메라 관련
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;

  // ML Kit 포즈 감지
  late final PoseDetector _poseDetector;
  bool _isBusy = false;
  List<Pose> _poses = [];
  Size? _imageSize;

  // 운동 데이터
  List<ExerciseModel> _exercises = [];
  ExerciseModel? _selectedExercise;
  PhaseManager? _phaseManager;
  
  // 피드백 및 점수
  List<String> _feedbacks = [];
  double _score = 0.0;

  // 떨림 보정
  late final AngleSmoother _angleSmoother;

  // 성능 관리
  int _frameCount = 0;
  int _skipFrames = 0;
  DateTime _lastUpdateTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _angleSmoother = AngleSmoother(windowSize: 5); // 5 프레임 윈도우로 떨림 보정
    _initializePoseDetector();
    _initializeCamera();
    _loadExercises();
  }

  @override
  void dispose() {
    _controller?.dispose();
    _poseDetector.close();
    super.dispose();
  }

  /// 운동 데이터 로드
  Future<void> _loadExercises() async {
    try {
      final exercises = await ExerciseLoader.getAllExercises();
      setState(() {
        _exercises = exercises;
        if (exercises.isNotEmpty) {
          _selectedExercise = exercises[0]; // 첫 번째 운동 자동 선택
          _phaseManager = PhaseManager(exercises[0]); // 단계 관리자 초기화
          _lastUpdateTime = DateTime.now();
        }
      });
      print('운동 데이터 로드 완료: ${exercises.length}개');
    } catch (e) {
      print('운동 데이터 로드 실패: $e');
    }
  }

  /// 포즈 감지기 초기화
  void _initializePoseDetector() {
    final options = PoseDetectorOptions(
      mode: PoseDetectionMode.stream,
      model: PoseDetectionModel.base,
    );
    _poseDetector = PoseDetector(options: options);
    print('포즈 감지기 초기화 완료 - base 모델 사용');
  }

  /// 카메라 초기화
  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      print('사용 가능한 카메라: ${_cameras?.length}개');
      
      if (_cameras != null && _cameras!.isNotEmpty) {
        CameraDescription? frontCamera;
        for (var camera in _cameras!) {
          if (camera.lensDirection == CameraLensDirection.front) {
            frontCamera = camera;
            print('전면 카메라 발견: ${camera.name}');
            break;
          }
        }
        
        final selectedCamera = frontCamera ?? _cameras![0];
        print('선택된 카메라: ${selectedCamera.lensDirection}');
        
        _controller = CameraController(selectedCamera, ResolutionPreset.low);
        
        await _controller!.initialize();
        if (!mounted) return;
        
        _imageSize = _controller!.value.previewSize;
        print('카메라 초기화 완료 - 프리뷰 크기: $_imageSize');
        
        _controller!.startImageStream((image) {
          _processCameraImage(image);
        });
        
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      print('카메라 초기화 오류: $e');
    }
  }

  /// 카메라 이미지 처리
  Future<void> _processCameraImage(CameraImage image) async {
    if (_isBusy) return;
    
    _skipFrames++;
    if (_skipFrames % 3 != 0) return;
    
    _isBusy = true;
    _frameCount++;

    final inputImage = _inputImageFromCameraImage(image);
    if (inputImage == null) {
      _isBusy = false;
      return;
    }

    try {
      final poses = await _poseDetector.processImage(inputImage);

      if (_frameCount % 10 == 1) {
        print('포즈 처리 완료: ${poses.length}개 감지');
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

  /// InputImage 변환
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
    
    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null || image.planes.isEmpty) return null;

    final WriteBuffer allBytes = WriteBuffer();
    allBytes.putUint8List(image.planes[0].bytes);
    
    final int uvWidth = image.width ~/ 2;
    final int uvHeight = image.height ~/ 2;
    
    for (int i = 0; i < uvHeight * uvWidth; i++) {
      if (i < image.planes[2].bytes.length) {
        allBytes.putUint8(image.planes[2].bytes[i]);
      }
      if (i < image.planes[1].bytes.length) {
        allBytes.putUint8(image.planes[1].bytes[i]);
      }
    }
    
    final bytes = allBytes.done().buffer.asUint8List();
    
    final inputImageData = InputImageMetadata(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: rotation,
      format: InputImageFormat.nv21,
      bytesPerRow: image.width,
    );

    return InputImage.fromBytes(bytes: bytes, metadata: inputImageData);
  }

  /// 피드백 업데이트
  void _updateFeedback() {
    if (_poses.isEmpty || _selectedExercise == null) {
      _feedbacks = [];
      _score = 0.0;
      return;
    }
    
    final pose = _poses[0];
    
    // 1. 사용자의 현재 각도 계산
    final userAngles = _calculateUserAngles(pose, _selectedExercise!);
    
    if (userAngles.isEmpty) {
      _feedbacks = ['전신이 보이도록 해주세요'];
      return;
    }
    
    // 2. 점수 계산
    final score = PoseScorer.calculateScore(
      userAngles,
      _selectedExercise!.keyAngles,
    );
    
    // 3. 상세 점수 계산
    final detailedScores = PoseScorer.calculateDetailedScores(
      userAngles,
      _selectedExercise!.keyAngles,
    );
    
    // 4. 피드백 생성
    final feedbacks = FeedbackGenerator.generateFeedback(
      userAngles,
      detailedScores,
      _selectedExercise!.keyAngles,
      _selectedExercise!.feedbackRules,
    );
    
    // 5. 단계 관리 업데이트
    if (_phaseManager != null) {
      final now = DateTime.now();
      final deltaTime = now.difference(_lastUpdateTime).inMilliseconds / 1000.0;
      _lastUpdateTime = now;
      
      final phaseChanged = _phaseManager!.update(userAngles, score, deltaTime: deltaTime);
      
      // 단계가 변경되면 피드백에 추가
      if (phaseChanged) {
        if (_phaseManager!.isCompleted) {
          feedbacks.insert(0, '🎉 운동 완료!');
        } else {
          feedbacks.insert(0, '✓ 다음 단계: ${_phaseManager!.currentPhase.phaseName}');
        }
      }
      
      // 준비 단계 피드백
      if (!_phaseManager!.isReady && !_phaseManager!.isCompleted) {
        if (_phaseManager!.isConditionMet) {
          feedbacks.insert(0, '⏳ 준비: 자세를 2초 유지하세요 (${_phaseManager!.readyDuration.toStringAsFixed(1)}초)');
        } else {
          feedbacks.insert(0, '⚠️ ${_phaseManager!.currentPhase.description}');
        }
      }
      // 운동 단계에서 조건 불만족 시 피드백
      else if (_phaseManager!.isReady && !_phaseManager!.isConditionMet && !_phaseManager!.isCompleted) {
        feedbacks.insert(0, '⚠️ 자세를 유지하세요!');
      }
    }
    
    // 6. 상태 업데이트
    setState(() {
      _score = score;
      _feedbacks = feedbacks;
    });
  }

  /// 사용자 각도 계산 (떨림 보정 포함)
  Map<String, double> _calculateUserAngles(
    Pose pose,
    ExerciseModel exercise,
  ) {
    Map<String, double> angles = {};
    
    for (var entry in exercise.keyAngles.entries) {
      final angleKey = entry.key;
      final angleInfo = entry.value;
      final points = angleInfo.points;
      
      if (points.length != 3) continue;
      
      final point1 = _getLandmark(pose, points[0]);
      final point2 = _getLandmark(pose, points[1]);
      final point3 = _getLandmark(pose, points[2]);
      
      if (point1 != null && point2 != null && point3 != null) {
        // 원시 각도 계산
        final rawAngle = AngleCalculator.calculateAngle(point1, point2, point3);
        
        // 떨림 보정: 적응형 필터 적용
        // 변화가 클 때는 빠르게 반응, 작을 때는 스무딩
        final smoothedAngle = _angleSmoother.smoothAngleAdaptive(
          angleKey,
          rawAngle,
          threshold: 10.0, // 10도 이상 변화시 즉시 반응
        );
        
        angles[angleKey] = smoothedAngle;
      }
    }
    
    return angles;
  }

  /// 랜드마크 가져오기 (PT Pose Data → ML Kit 매핑)
  PoseLandmark? _getLandmark(Pose pose, String name) {
    // 직접 매핑 가능한 랜드마크
    final directMap = {
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
    
    // 직접 매핑
    if (directMap.containsKey(name)) {
      return pose.landmarks[directMap[name]];
    }
    
    // 복합 랜드마크 (중점 계산)
    switch (name) {
      case 'Neck':
        // 목: 양쪽 어깨 중점
        final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
        final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
        if (leftShoulder != null && rightShoulder != null) {
          return PoseLandmark(
            type: PoseLandmarkType.nose, // 타입은 임시
            x: (leftShoulder.x + rightShoulder.x) / 2,
            y: (leftShoulder.y + rightShoulder.y) / 2,
            z: (leftShoulder.z + rightShoulder.z) / 2,
            likelihood: (leftShoulder.likelihood + rightShoulder.likelihood) / 2,
          );
        }
        break;
        
      case 'Back':
        // 등: 양쪽 어깨 중점에서 약간 아래
        final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
        final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
        final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
        final rightHip = pose.landmarks[PoseLandmarkType.rightHip];
        
        if (leftShoulder != null && rightShoulder != null && 
            leftHip != null && rightHip != null) {
          // 어깨와 힙의 중간점 (등 중앙)
          final shoulderMidX = (leftShoulder.x + rightShoulder.x) / 2;
          final shoulderMidY = (leftShoulder.y + rightShoulder.y) / 2;
          final shoulderMidZ = (leftShoulder.z + rightShoulder.z) / 2;
          
          final hipMidX = (leftHip.x + rightHip.x) / 2;
          final hipMidY = (leftHip.y + rightHip.y) / 2;
          final hipMidZ = (leftHip.z + rightHip.z) / 2;
          
          return PoseLandmark(
            type: PoseLandmarkType.nose, // 타입은 임시
            x: (shoulderMidX + hipMidX) / 2,
            y: (shoulderMidY + hipMidY) / 2,
            z: (shoulderMidZ + hipMidZ) / 2,
            likelihood: (leftShoulder.likelihood + rightShoulder.likelihood + 
                        leftHip.likelihood + rightHip.likelihood) / 4,
          );
        }
        break;
        
      case 'Waist':
        // 허리: 양쪽 힙 중점
        final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
        final rightHip = pose.landmarks[PoseLandmarkType.rightHip];
        if (leftHip != null && rightHip != null) {
          return PoseLandmark(
            type: PoseLandmarkType.nose, // 타입은 임시
            x: (leftHip.x + rightHip.x) / 2,
            y: (leftHip.y + rightHip.y) / 2,
            z: (leftHip.z + rightHip.z) / 2,
            likelihood: (leftHip.likelihood + rightHip.likelihood) / 2,
          );
        }
        break;
        
      case 'Shoulder':
        // 어깨 중점: 양쪽 어깨 평균
        final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
        final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
        if (leftShoulder != null && rightShoulder != null) {
          return PoseLandmark(
            type: PoseLandmarkType.nose, // 타입은 임시
            x: (leftShoulder.x + rightShoulder.x) / 2,
            y: (leftShoulder.y + rightShoulder.y) / 2,
            z: (leftShoulder.z + rightShoulder.z) / 2,
            likelihood: (leftShoulder.likelihood + rightShoulder.likelihood) / 2,
          );
        }
        break;
        
      case 'Hip':
        // 힙 중점: 양쪽 힙 평균
        final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
        final rightHip = pose.landmarks[PoseLandmarkType.rightHip];
        if (leftHip != null && rightHip != null) {
          return PoseLandmark(
            type: PoseLandmarkType.nose, // 타입은 임시
            x: (leftHip.x + rightHip.x) / 2,
            y: (leftHip.y + rightHip.y) / 2,
            z: (leftHip.z + rightHip.z) / 2,
            likelihood: (leftHip.likelihood + rightHip.likelihood) / 2,
          );
        }
        break;
        
      case 'Knee':
        // 무릎 중점: 양쪽 무릎 평균
        final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];
        final rightKnee = pose.landmarks[PoseLandmarkType.rightKnee];
        if (leftKnee != null && rightKnee != null) {
          return PoseLandmark(
            type: PoseLandmarkType.nose, // 타입은 임시
            x: (leftKnee.x + rightKnee.x) / 2,
            y: (leftKnee.y + rightKnee.y) / 2,
            z: (leftKnee.z + rightKnee.z) / 2,
            likelihood: (leftKnee.likelihood + rightKnee.likelihood) / 2,
          );
        }
        break;
    }
    
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 레이어 1: 카메라 프리뷰 (미러링)
          Transform.scale(
            scaleX: -1,
            child: CameraPreview(_controller!),
          ),
          
          // 레이어 2: 스켈레톤 오버레이 (미러링) - 각도별 색상 표시
          if (_imageSize != null)
            Transform.scale(
              scaleX: -1,
              child: CustomPaint(
                painter: PosePainter(
                  _poses, 
                  _imageSize!,
                  exercise: _selectedExercise, // 선택된 운동 전달
                ),
              ),
            ),
          
          // 레이어 3: 상단 UI (운동 선택 + 상태)
          Positioned(
            top: 48,
            left: 16,
            right: 16,
            child: Column(
              children: [
                // 운동 선택 드롭다운
                if (_exercises.isNotEmpty)
                  ExerciseDropdown(
                    exercises: _exercises,
                    selectedExercise: _selectedExercise,
                    onChanged: (exercise) {
                      setState(() {
                        _selectedExercise = exercise;
                        _score = 0.0;
                        _feedbacks = [];
                        // 단계 관리자 초기화
                        if (exercise != null) {
                          _phaseManager = PhaseManager(exercise);
                          _lastUpdateTime = DateTime.now();
                        } else {
                          _phaseManager = null;
                        }
                      });
                    },
                  ),
                
                const SizedBox(height: 12),
                
                // 포즈 감지 상태 + 점수 표시
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 포즈 감지 상태
                    Container(
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
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    
                    // 점수 표시 (컴팩트)
                    if (_selectedExercise != null && _score > 0) ...[
                      const SizedBox(width: 8),
                      CompactScoreDisplay(score: _score),
                    ],
                  ],
                ),
              ],
            ),
          ),
          
          // 레이어 4: 단계 진행 표시 (중앙)
          if (_phaseManager != null)
            Positioned(
              top: 150,
              left: 16,
              right: 16,
              child: Column(
                children: [
                  PhaseStepIndicator(phaseManager: _phaseManager),
                  const SizedBox(height: 12),
                  PhaseProgressWidget(phaseManager: _phaseManager),
                ],
              ),
            ),
          
          // 레이어 5: 하단 UI (피드백 + 리셋)
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 피드백 패널 (접을 수 있음)
                CollapsibleFeedbackPanel(feedbacks: _feedbacks),
                
                // 리셋 버튼 (운동 완료 시)
                if (_phaseManager != null && _phaseManager!.isCompleted) ...[
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _phaseManager?.reset();
                        _lastUpdateTime = DateTime.now();
                      });
                    },
                    icon: const Icon(Icons.replay),
                    label: const Text('다시 시작'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // 레이어 6: 좌측 하단 - 각도 색상 범례
          if (_selectedExercise != null)
            Positioned(
              left: 16,
              bottom: 200,
              child: AngleLegendWidget(exercise: _selectedExercise),
            ),
        ],
      ),
    );
  }
}
