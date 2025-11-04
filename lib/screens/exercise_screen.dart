import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:go_router/go_router.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

// Models
import '../models/exercise_model.dart';

// Services
import '../services/exercise_loader.dart';
import '../services/exercise_mapper.dart';
import '../services/pose_scorer.dart';
import '../features/workout/data/supabase_workout_service.dart';
import '../services/feedback_generator.dart';
import '../services/phase_manager.dart';
import '../services/angle_smoother.dart';
import '../services/landmark_smoother.dart';
import '../services/tts_service.dart';

// Widgets
import '../widgets/phase_progress_widget.dart';
import '../widgets/compact_score_display.dart';
import '../pose_painter.dart';
import '../angle_calculator.dart';

/// 운동 자세 교정 메인 화면
class ExerciseScreen extends StatefulWidget {
  final List<int>? exerciseIds; // 루틴의 exercise_id 리스트 (선택적)

  const ExerciseScreen({Key? key, this.exerciseIds}) : super(key: key);

  @override
  State<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends State<ExerciseScreen> {
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
  int _currentExerciseIndex = 0; // 현재 진행 중인 운동 인덱스
  
  // 운동별 video_url 저장 (exercise_id -> video_url)
  Map<int, String?> _exerciseVideoUrls = {};
  
  // 동영상 재생 여부
  bool _hasShownVideo = false; // 첫 운동 시작 시에만 영상 표시

  // 피드백 및 점수 (ValueNotifier로 최적화)
  final ValueNotifier<List<String>> _feedbacksNotifier = ValueNotifier([]);
  final ValueNotifier<double> _scoreNotifier = ValueNotifier(0.0);

  // 떨림 보정
  late final AngleSmoother _angleSmoother;
  late final LandmarkSmoother _landmarkSmoother;

  // TTS (음성 피드백)
  final TtsService _ttsService = TtsService();
  String? _lastSpokenFeedback; // TTS 중복 방지용

  // 성능 관리 (적응형 프레임 레이트)
  int _frameCount = 0;
  static const int _frameSkipThreshold = 3; // 30fps → 10fps (버퍼 부족 방지)
  DateTime _lastUpdateTime = DateTime.now();
  
  // 운동 완료 상태 추적
  bool _wasCompleted = false;
  
  // 스켈레톤 렌더링 표시 여부
  bool _showSkeleton = true;
  
  // 준비 피드백 메시지 (맨 아래 고정)
  final ValueNotifier<String?> _readyFeedbackNotifier = ValueNotifier(null);
  
  // 마지막으로 읽은 단계 설명 (중복 방지)
  String? _lastSpokenPhaseDescription;

  @override
  void initState() {
    super.initState();
    _angleSmoother = AngleSmoother(windowSize: 7);
    _landmarkSmoother = LandmarkSmoother(alpha: 0.5, movementThreshold: 2.0);
    _ttsService.initialize(); // TTS 초기화
    _initializePoseDetector();
    _initializeCamera();
    _loadExercises();
  }

  @override
  void dispose() {
    _controller
        ?.stopImageStream()
        .then((_) {
          _controller?.dispose();
        })
        .catchError((_) {
          _controller?.dispose();
        });
    _poseDetector.close();
    _feedbacksNotifier.dispose();
    _scoreNotifier.dispose();
    _readyFeedbackNotifier.dispose();
    _ttsService.dispose(); // TTS 리소스 해제
    super.dispose();
  }

  Future<void> _loadExercises() async {
    try {
      List<ExerciseModel> exercises;
      final Map<int, String?> videoUrls = {};
      
      // 루틴의 exercise_id 리스트가 있으면 해당 운동들만 로드
      if (widget.exerciseIds != null && widget.exerciseIds!.isNotEmpty) {
        exercises = [];
        
        // Supabase에서 video_url 가져오기
        final service = SupabaseWorkoutService();
        for (final exerciseId in widget.exerciseIds!) {
          // ExerciseModel 로드
          final exercise = await ExerciseMapper.loadExerciseFromExerciseId(exerciseId);
          if (exercise != null) {
            exercises.add(exercise);
          }
          
          // SupabaseExercise에서 video_url 가져오기
          final supabaseExercise = await service.getExerciseByListId(exerciseId);
          if (supabaseExercise != null) {
            videoUrls[exerciseId] = supabaseExercise.videoUrl;
          }
        }
        print('루틴 운동 데이터 로드 완료: ${exercises.length}개 (IDs: ${widget.exerciseIds})');
      } else {
        // 전체 운동 로드 (기존 동작)
        exercises = await ExerciseLoader.getAllExercises();
        print('전체 운동 데이터 로드 완료: ${exercises.length}개');
      }
      
      setState(() {
        _exercises = exercises;
        _exerciseVideoUrls = videoUrls;
        _currentExerciseIndex = 0; // 첫 번째 운동부터 시작
        if (exercises.isNotEmpty) {
          _selectedExercise = exercises[0];
          _phaseManager = PhaseManager(exercises[0]);
          _lastUpdateTime = DateTime.now();
          _wasCompleted = false; // 완료 상태 리셋
          _lastSpokenPhaseDescription = null; // 단계 설명 초기화
          _hasShownVideo = false; // 첫 운동 영상 표시 플래그 리셋
        }
      });
      
      // 첫 운동 시작 전 영상 재생
      if (exercises.isNotEmpty && widget.exerciseIds != null && widget.exerciseIds!.isNotEmpty) {
        final firstExerciseId = widget.exerciseIds![0];
        final videoUrl = videoUrls[firstExerciseId];
        if (videoUrl != null && !_hasShownVideo) {
          _hasShownVideo = true;
          // 약간의 지연 후 영상 재생 다이얼로그 표시
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              _showVideoDialog(videoUrl);
            }
          });
        } else {
          // 영상이 없으면 첫 단계 설명 읽기
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted && _phaseManager != null && _selectedExercise != null) {
              final phaseDescription = _phaseManager!.currentPhase.description;
              _ttsService.speak(phaseDescription);
              _lastSpokenPhaseDescription = phaseDescription;
            }
          });
        }
      } else {
        // 첫 단계 설명 읽기 (약간의 지연 후)
        if (exercises.isNotEmpty) {
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted && _phaseManager != null && _selectedExercise != null) {
              final phaseDescription = _phaseManager!.currentPhase.description;
              _ttsService.speak(phaseDescription);
              _lastSpokenPhaseDescription = phaseDescription;
            }
          });
        }
      }
    } catch (e) {
      print('운동 데이터 로드 실패: $e');
    }
  }

  void _initializePoseDetector() {
    final options = PoseDetectorOptions(
      mode: PoseDetectionMode.stream,
      model: PoseDetectionModel.base,
    );
    _poseDetector = PoseDetector(options: options);
    print('포즈 감지기 초기화 완료 - base 모델 사용');
  }

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

  Future<void> _processCameraImage(CameraImage image) async {
    // 중복 처리 방지 및 프레임 스킵
    if (_isBusy) return;

    _frameCount++;
    // 프레임 스킵: 더 많은 프레임을 건너뛰어 버퍼 부족 방지
    if (_frameCount % _frameSkipThreshold != 0) {
      return; // 이미지 버퍼는 자동으로 해제됨
    }

    _isBusy = true;

    try {
      final inputImage = _inputImageFromCameraImage(image);
      if (inputImage == null) {
        _isBusy = false;
        return;
      }

      final poses = await _poseDetector.processImage(inputImage);

      if (_frameCount % 30 == 0) {
        print('포즈 처리 완료: ${poses.length}개 감지 (프레임: $_frameCount)');
      }

      final smoothedPoses = poses
          .map((pose) => _landmarkSmoother.smoothPose(pose))
          .toList();

      if (mounted) {
        setState(() {
          _poses = smoothedPoses;
        });
        _updateFeedback();
      }
    } catch (e) {
      if (_frameCount % 30 == 0) {
        print('포즈 감지 오류: $e');
      }
    } finally {
      // 항상 busy 플래그 해제 (예외 발생 시에도)
      _isBusy = false;
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

  /// YouTube URL에서 video ID 추출
  String? _extractYouTubeVideoId(String url) {
    // 다양한 YouTube URL 형식 지원
    final patterns = [
      RegExp(r'youtube\.com/watch\?v=([a-zA-Z0-9_-]+)'),
      RegExp(r'youtu\.be/([a-zA-Z0-9_-]+)'),
      RegExp(r'youtube\.com/shorts/([a-zA-Z0-9_-]+)'),
      RegExp(r'youtube\.com/embed/([a-zA-Z0-9_-]+)'),
    ];
    
    for (final pattern in patterns) {
      final match = pattern.firstMatch(url);
      if (match != null && match.groupCount >= 1) {
        return match.group(1);
      }
    }
    return null;
  }

  /// 동영상 재생 다이얼로그 표시
  void _showVideoDialog(String videoUrl) {
    final videoId = _extractYouTubeVideoId(videoUrl);
    
    if (videoId == null) {
      // YouTube URL이 아니면 외부 브라우저로 열기
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) => AlertDialog(
          title: const Text('운동 영상'),
          content: const Text('영상을 외부 브라우저에서 열까요?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () async {
                final uri = Uri.parse(videoUrl);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text('열기'),
            ),
          ],
        ),
      );
      return;
    }

    // YouTube 플레이어 다이얼로그
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 헤더
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.white24, width: 1),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _selectedExercise?.exerciseName ?? '운동 영상',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              // YouTube 플레이어
              Container(
                width: double.infinity,
                height: 250,
                child: YoutubePlayer(
                  controller: YoutubePlayerController(
                    initialVideoId: videoId,
                    flags: const YoutubePlayerFlags(
                      autoPlay: true,
                      mute: false,
                    ),
                  ),
                  showVideoProgressIndicator: true,
                  progressIndicatorColor: Colors.blue,
                  progressColors: const ProgressBarColors(
                    playedColor: Colors.blue,
                    handleColor: Colors.blueAccent,
                  ),
                ),
              ),
              // 닫기 버튼
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('운동 시작하기'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 다음 운동으로 이동하거나 모든 운동이 완료되면 운동 탭으로 돌아가기
  void _moveToNextExercise() {
    // 약간의 지연 후 다음 운동으로 이동 (사용자가 완료 메시지를 볼 수 있도록)
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      
      // 다음 운동이 있는지 확인
      if (_currentExerciseIndex < _exercises.length - 1) {
        // 다음 운동으로 이동
        final nextExerciseId = widget.exerciseIds?[_currentExerciseIndex + 1];
        final nextVideoUrl = nextExerciseId != null ? _exerciseVideoUrls[nextExerciseId] : null;
        
        setState(() {
          _currentExerciseIndex++;
          _selectedExercise = _exercises[_currentExerciseIndex];
          _phaseManager = PhaseManager(_exercises[_currentExerciseIndex]);
          _wasCompleted = false; // 완료 상태 리셋
          _lastUpdateTime = DateTime.now();
          _scoreNotifier.value = 0.0;
          _feedbacksNotifier.value = [];
          _readyFeedbackNotifier.value = null;
          _angleSmoother.resetAll();
          _landmarkSmoother.resetAll();
          _lastSpokenFeedback = null;
          _lastSpokenPhaseDescription = null;
          _ttsService.resetLastSpoken();
        });
        print('다음 운동으로 이동: ${_selectedExercise!.exerciseName} (${_currentExerciseIndex + 1}/${_exercises.length})');
        
        // 다음 운동 시작 전 영상 재생
        if (nextVideoUrl != null && mounted) {
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              _showVideoDialog(nextVideoUrl);
            }
          });
        } else {
          // 영상이 없으면 첫 단계 설명 읽기
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted && _phaseManager != null && _selectedExercise != null) {
              final phaseDescription = _phaseManager!.currentPhase.description;
              _ttsService.speak(phaseDescription);
              _lastSpokenPhaseDescription = phaseDescription;
            }
          });
        }
      } else {
        // 모든 운동 완료 - 홈 화면으로 이동
        print('🎉 모든 운동 완료! 홈 화면으로 이동합니다.');
        context.go('/app/home');
      }
    });
  }

  void _updateFeedback() {
    if (_poses.isEmpty || _selectedExercise == null) {
      _feedbacksNotifier.value = [];
      _scoreNotifier.value = 0.0;
      return;
    }

    final pose = _poses[0];
    final userAngles = _calculateUserAngles(pose, _selectedExercise!);

    if (userAngles.isEmpty) {
      _feedbacksNotifier.value = ['전신이 보이도록 해주세요'];
      return;
    }

    final score = PoseScorer.calculateScore(
      userAngles,
      _selectedExercise!.keyAngles,
    );

    final detailedScores = PoseScorer.calculateDetailedScores(
      userAngles,
      _selectedExercise!.keyAngles,
    );

    final feedbacks = FeedbackGenerator.generateFeedback(
      userAngles,
      detailedScores,
      _selectedExercise!.keyAngles,
      _selectedExercise!.feedbackRules,
    );

    // 준비 피드백과 일반 피드백 분리
    String? readyFeedback;
    List<String> ttsFeedbacks = [];

    if (_phaseManager != null) {
      final now = DateTime.now();
      final deltaTime = now.difference(_lastUpdateTime).inMilliseconds / 1000.0;
      _lastUpdateTime = now;

      final phaseChanged = _phaseManager!.update(
        userAngles,
        score,
        deltaTime: deltaTime,
      );

      if (phaseChanged) {
        // 단계 변경 시 설명 먼저 읽기
        final phaseDescription = _phaseManager!.currentPhase.description;
        if (_lastSpokenPhaseDescription != phaseDescription) {
          _ttsService.speak(phaseDescription);
          _lastSpokenPhaseDescription = phaseDescription;
        }
        
        if (_phaseManager!.isCompleted) {
          // 운동 완료 - TTS만 제공
          ttsFeedbacks.add('🎉 운동 완료!');
          // 운동 완료 시 다음 운동으로 이동 또는 운동 탭으로 돌아가기
          if (!_wasCompleted) {
            _wasCompleted = true;
            _moveToNextExercise();
          }
        } else {
          // 다음 단계 - TTS만 제공 (설명은 이미 읽음)
          ttsFeedbacks.add('✓ 다음 단계: ${_phaseManager!.currentPhase.phaseName}');
        }
      }
      
      // 첫 단계 시작 시에도 설명 읽기
      if (_phaseManager!.currentPhaseIndex == 0 && !_phaseManager!.isReady && !_phaseManager!.isCompleted) {
        final phaseDescription = _phaseManager!.currentPhase.description;
        if (_lastSpokenPhaseDescription != phaseDescription) {
          _ttsService.speak(phaseDescription);
          _lastSpokenPhaseDescription = phaseDescription;
        }
      }
      
      // 운동 완료 상태 체크 (phaseChanged가 false여도 완료될 수 있음)
      if (_phaseManager!.isCompleted && !_wasCompleted) {
        _wasCompleted = true;
        ttsFeedbacks.add('🎉 운동 완료!');
        _moveToNextExercise();
      }

      if (!_phaseManager!.isReady && !_phaseManager!.isCompleted) {
        // 준비 피드백 - 맨 아래 고정 표시
        readyFeedback = '⏳ 준비: 자세를 2초 유지하세요 (${_phaseManager!.readyDuration.toStringAsFixed(1)}초)';
      } else if (_phaseManager!.isReady && !_phaseManager!.isCompleted) {
        // 운동 진행 중 - TTS만 제공
        ttsFeedbacks.add('⚠️ ${_phaseManager!.currentPhase.description}');
        readyFeedback = null; // 준비 완료되면 준비 피드백 제거
      } else {
        readyFeedback = null;
      }
    }

    // 일반 피드백도 TTS만 제공 (텍스트는 표시하지 않음)
    for (final feedback in feedbacks) {
      if (!feedback.contains('준비:') && !feedback.contains('운동 완료')) {
        ttsFeedbacks.add(feedback);
      }
    }

    _scoreNotifier.value = score;
    _feedbacksNotifier.value = []; // 텍스트 피드백 비우기 (표시하지 않음)
    _readyFeedbackNotifier.value = readyFeedback; // 준비 피드백만 별도로 관리

    // TTS: 피드백 음성 재생 (첫 번째 피드백만)
    if (ttsFeedbacks.isNotEmpty) {
      final topFeedback = ttsFeedbacks[0];
      // 이전 피드백과 다를 때만 재생 (중복 방지)
      if (_lastSpokenFeedback != topFeedback) {
        _ttsService.speak(topFeedback);
        _lastSpokenFeedback = topFeedback;
      }
    } else {
      _lastSpokenFeedback = null;
    }
  }

  Map<String, double> _calculateUserAngles(Pose pose, ExerciseModel exercise) {
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
        final rawAngle = AngleCalculator.calculateAngle(point1, point2, point3);
        final smoothedAngle = _angleSmoother.smoothAngleAdaptive(
          angleKey,
          rawAngle,
          threshold: 10.0,
        );
        angles[angleKey] = smoothedAngle;
      }
    }

    return angles;
  }

  PoseLandmark? _getLandmark(Pose pose, String name) {
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

    if (directMap.containsKey(name)) {
      return pose.landmarks[directMap[name]];
    }

    switch (name) {
      case 'Neck':
        final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
        final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
        if (leftShoulder != null && rightShoulder != null) {
          return PoseLandmark(
            type: PoseLandmarkType.nose,
            x: (leftShoulder.x + rightShoulder.x) / 2,
            y: (leftShoulder.y + rightShoulder.y) / 2,
            z: (leftShoulder.z + rightShoulder.z) / 2,
            likelihood:
                (leftShoulder.likelihood + rightShoulder.likelihood) / 2,
          );
        }
        break;

      case 'Back':
        final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
        final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
        final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
        final rightHip = pose.landmarks[PoseLandmarkType.rightHip];

        if (leftShoulder != null &&
            rightShoulder != null &&
            leftHip != null &&
            rightHip != null) {
          final shoulderMidX = (leftShoulder.x + rightShoulder.x) / 2;
          final shoulderMidY = (leftShoulder.y + rightShoulder.y) / 2;
          final shoulderMidZ = (leftShoulder.z + rightShoulder.z) / 2;

          final hipMidX = (leftHip.x + rightHip.x) / 2;
          final hipMidY = (leftHip.y + rightHip.y) / 2;
          final hipMidZ = (leftHip.z + rightHip.z) / 2;

          return PoseLandmark(
            type: PoseLandmarkType.nose,
            x: (shoulderMidX + hipMidX) / 2,
            y: (shoulderMidY + hipMidY) / 2,
            z: (shoulderMidZ + hipMidZ) / 2,
            likelihood:
                (leftShoulder.likelihood +
                    rightShoulder.likelihood +
                    leftHip.likelihood +
                    rightHip.likelihood) /
                4,
          );
        }
        break;

      case 'Waist':
        final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
        final rightHip = pose.landmarks[PoseLandmarkType.rightHip];
        if (leftHip != null && rightHip != null) {
          return PoseLandmark(
            type: PoseLandmarkType.nose,
            x: (leftHip.x + rightHip.x) / 2,
            y: (leftHip.y + rightHip.y) / 2,
            z: (leftHip.z + rightHip.z) / 2,
            likelihood: (leftHip.likelihood + rightHip.likelihood) / 2,
          );
        }
        break;

      case 'Shoulder':
        final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
        final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
        if (leftShoulder != null && rightShoulder != null) {
          return PoseLandmark(
            type: PoseLandmarkType.nose,
            x: (leftShoulder.x + rightShoulder.x) / 2,
            y: (leftShoulder.y + rightShoulder.y) / 2,
            z: (leftShoulder.z + rightShoulder.z) / 2,
            likelihood:
                (leftShoulder.likelihood + rightShoulder.likelihood) / 2,
          );
        }
        break;

      case 'Hip':
        final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
        final rightHip = pose.landmarks[PoseLandmarkType.rightHip];
        if (leftHip != null && rightHip != null) {
          return PoseLandmark(
            type: PoseLandmarkType.nose,
            x: (leftHip.x + rightHip.x) / 2,
            y: (leftHip.y + rightHip.y) / 2,
            z: (leftHip.z + rightHip.z) / 2,
            likelihood: (leftHip.likelihood + rightHip.likelihood) / 2,
          );
        }
        break;

      case 'Knee':
        final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];
        final rightKnee = pose.landmarks[PoseLandmarkType.rightKnee];
        if (leftKnee != null && rightKnee != null) {
          return PoseLandmark(
            type: PoseLandmarkType.nose,
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Transform.scale(scaleX: -1, child: CameraPreview(_controller!)),

          if (_imageSize != null && _showSkeleton)
            Transform.scale(
              scaleX: -1,
              child: CustomPaint(
                painter: PosePainter(
                  _poses,
                  _imageSize!,
                  exercise: _selectedExercise,
                ),
                child: Container(),
              ),
            ),
          
          // 개발자 전용 스킵 버튼
          if (_phaseManager != null && !_phaseManager!.isCompleted)
            Positioned(
              top: 48,
              left: 16,
              child: IconButton(
                icon: const Icon(
                  Icons.skip_next,
                  color: Colors.orange,
                  size: 28,
                ),
                onPressed: () {
                  // 개발자 전용: 운동 완료까지 모든 단계 스킵
                  if (_phaseManager != null) {
                    setState(() {
                      _wasCompleted = false;
                      _lastUpdateTime = DateTime.now();
                      _scoreNotifier.value = 0.0;
                      _feedbacksNotifier.value = [];
                      _readyFeedbackNotifier.value = null;
                      _angleSmoother.resetAll();
                      _landmarkSmoother.resetAll();
                      _lastSpokenFeedback = null;
                      _lastSpokenPhaseDescription = null;
                      _ttsService.resetLastSpoken();
                      
                      // 모든 단계를 스킵하여 운동 완료까지 이동
                      while (!_phaseManager!.isCompleted) {
                        _phaseManager!.forceNextPhase();
                      }
                      
                      // 운동 완료 처리
                      _wasCompleted = true;
                      _moveToNextExercise();
                    });
                  }
                },
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black.withValues(alpha: 0.5),
                  padding: const EdgeInsets.all(12),
                ),
                tooltip: '개발자: 운동 완료까지 스킵',
              ),
            ),

          Positioned(
            top: 48,
            left: 16,
            right: 16,
            child: Column(
              children: [
                // 현재 운동 이름 표시
                if (_selectedExercise != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.fitness_center, color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          _selectedExercise!.exerciseName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_exercises.length > 1) ...[
                          const SizedBox(width: 6),
                          Text(
                            '(${_currentExerciseIndex + 1}/${_exercises.length})',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                
                const SizedBox(height: 8),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
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

                    if (_selectedExercise != null) ...[
                      const SizedBox(width: 8),
                      ValueListenableBuilder<double>(
                        valueListenable: _scoreNotifier,
                        builder: (context, score, child) {
                          if (score == 0) return const SizedBox.shrink();
                          return CompactScoreDisplay(score: score);
                        },
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          
          // 스켈레톤 토글 버튼과 동영상 버튼
          Positioned(
            top: 48,
            right: 16,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 동영상 재생 버튼
                if (_selectedExercise != null && widget.exerciseIds != null && widget.exerciseIds!.isNotEmpty)
                  Builder(
                    builder: (context) {
                      final currentExerciseId = widget.exerciseIds![_currentExerciseIndex];
                      final videoUrl = _exerciseVideoUrls[currentExerciseId];
                      if (videoUrl == null) return const SizedBox.shrink();
                      
                      return IconButton(
                        icon: const Icon(
                          Icons.play_circle_outline,
                          color: Colors.red,
                          size: 28,
                        ),
                        onPressed: () {
                          _showVideoDialog(videoUrl);
                        },
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black.withValues(alpha: 0.5),
                          padding: const EdgeInsets.all(12),
                        ),
                        tooltip: '운동 영상 보기',
                      );
                    },
                  ),
                if (_selectedExercise != null && widget.exerciseIds != null && widget.exerciseIds!.isNotEmpty)
                  const SizedBox(width: 8),
                // 스켈레톤 토글 버튼
                IconButton(
                  icon: Icon(
                    _showSkeleton ? Icons.visibility : Icons.visibility_off,
                    color: Colors.white,
                    size: 28,
                  ),
                  onPressed: () {
                    setState(() {
                      _showSkeleton = !_showSkeleton;
                    });
                  },
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black.withValues(alpha: 0.5),
                    padding: const EdgeInsets.all(12),
                  ),
                  tooltip: '스켈레톤 표시/숨김',
                ),
              ],
            ),
          ),

          if (_phaseManager != null)
            Positioned(
              top: 100,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  PhaseStepIndicator(phaseManager: _phaseManager),
                  const SizedBox(width: 8),
                  PhaseProgressWidget(phaseManager: _phaseManager),
                ],
              ),
            ),

          // 준비 피드백 (맨 아래 고정)
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: ValueListenableBuilder<String?>(
              valueListenable: _readyFeedbackNotifier,
              builder: (context, readyFeedback, child) {
                if (readyFeedback == null) return const SizedBox.shrink();
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    readyFeedback,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
