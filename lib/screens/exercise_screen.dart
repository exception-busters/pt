import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:go_router/go_router.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

// 모델
import '../models/exercise_model.dart' show ExerciseModel, KeyAngle;

// 서비스
import '../services/exercise_loader.dart';
import '../services/exercise_mapper.dart';
import '../services/pose_scorer.dart';
import '../features/workout/data/supabase_workout_service.dart';
import '../features/workout/domain/models/supabase_exercise.dart';
import '../services/feedback_generator.dart';
import '../services/phase_manager.dart';
import '../services/angle_smoother.dart';
import '../services/landmark_smoother.dart';
import '../services/tts_service.dart';

// 위젯
import '../widgets/phase_progress_widget.dart';
import '../widgets/compact_score_display.dart';
import '../widgets/exercise_guide_dialog.dart';
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
  final ValueNotifier<List<Pose>> _posesNotifier = ValueNotifier([]);
  final ValueNotifier<Size?> _imageSizeNotifier = ValueNotifier(null);

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
  static const int _frameSkipThreshold = 4; // 30fps → 7.5fps (CPU 사용량 감소)
  DateTime _lastUpdateTime = DateTime.now();
  
  // 운동 완료 상태 추적
  bool _wasCompleted = false;
  
  // 다음 운동으로 이동 중인지 추적 (중복 호출 방지)
  bool _isMovingToNext = false;
  
  // 스켈레톤 렌더링 표시 여부
  bool _showSkeleton = true;
  
  // 준비 피드백 메시지 (맨 아래 고정)
  final ValueNotifier<String?> _readyFeedbackNotifier = ValueNotifier(null);

  // 디버그 정보 (개발 모드에서 표시)
  final ValueNotifier<String> _debugInfoNotifier = ValueNotifier('');
  
  // 마지막으로 읽은 단계 설명 (중복 방지)
  String? _lastSpokenPhaseDescription;
  
  // 동영상 다이얼로그 열림 상태
  bool _isVideoDialogOpen = false;

  @override
  void initState() {
    super.initState();
    // 가벼운 초기화만 먼저 실행 (동기)
    _angleSmoother = AngleSmoother(windowSize: 7);
    _landmarkSmoother = LandmarkSmoother(alpha: 0.5, movementThreshold: 2.0);
    
    // 모든 무거운 초기화를 비동기로 지연 실행 - 메인 스레드 블로킹 방지
    // 첫 프레임 렌더링 후 초기화 시작
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAsync();
    });
  }

  /// 비동기 초기화 (메인 스레드 블로킹 방지)
  Future<void> _initializeAsync() async {
    // 모든 무거운 초기화를 병렬로 실행
    await Future.wait([
      // PoseDetector 초기화 (비동기로 이동)
      Future(() {
        _initializePoseDetector();
      }),
      // 카메라 초기화
      _initializeCamera(),
      // TTS 초기화 (에러가 나도 앱은 계속 실행)
      _ttsService.initialize().catchError((e) {
        print('TTS 초기화 오류: $e');
      }),
    ]);
    
    // 운동 데이터 로드 (카메라 초기화 후 실행하여 사용자 경험 향상)
    await _loadExercises();
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
    _debugInfoNotifier.dispose();
    _posesNotifier.dispose(); // 추가: 포즈 리소스 해제
    _imageSizeNotifier.dispose(); // 추가: 이미지 크기 리소스 해제
    _ttsService.dispose(); // TTS 리소스 해제
    super.dispose();
  }

  Future<void> _loadExercises() async {
    try {
      List<ExerciseModel> exercises = [];
      final Map<int, String?> videoUrls = {};
      
      // 루틴의 exercise_id 리스트가 있으면 해당 운동들만 로드
      if (widget.exerciseIds != null && widget.exerciseIds!.isNotEmpty) {
        // 병렬 처리로 네트워크 요청 최적화 - 순차 처리 대신 동시 실행
        final service = SupabaseWorkoutService();
        final futures = widget.exerciseIds!.map((exerciseId) async {
          // ExerciseModel과 SupabaseExercise를 병렬로 로드
          final results = await Future.wait([
            ExerciseMapper.loadExerciseFromExerciseId(exerciseId),
            service.getExerciseByListId(exerciseId),
          ]);
          
          return {
            'exercise': results[0] as ExerciseModel?,
            'supabaseExercise': results[1] as SupabaseExercise?,
            'exerciseId': exerciseId,
          };
        });
        
        final results = await Future.wait(futures);
        
        for (final result in results) {
          final exercise = result['exercise'] as ExerciseModel?;
          final supabaseExercise = result['supabaseExercise'] as SupabaseExercise?;
          final exerciseId = result['exerciseId'] as int;
          
          if (exercise != null) {
            exercises.add(exercise);
          }
          
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
      
      // 가이드 화면 → 영상 → 운동 시작 흐름
      if (exercises.isNotEmpty) {
        // 약간의 지연 후 가이드 또는 영상 표시
        Future.delayed(const Duration(milliseconds: 300), () async {
          if (!mounted) return;

          // 1. 가이드 화면 표시 여부 확인
          final shouldShowGuide = await ExerciseGuideDialog.shouldShowGuide();

          if (shouldShowGuide) {
            // 가이드 화면 표시
            if (mounted) {
              await showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => ExerciseGuideDialog(
                  onComplete: () {
                    Navigator.of(context).pop();
                  },
                ),
              );
            }
          }

          // 2. 가이드 완료 후 영상 재생 또는 단계 설명
          if (mounted && widget.exerciseIds != null && widget.exerciseIds!.isNotEmpty) {
            final firstExerciseId = widget.exerciseIds![0];
            final videoUrl = videoUrls[firstExerciseId];
            if (videoUrl != null && !_hasShownVideo) {
              _hasShownVideo = true;
              // 영상 재생 다이얼로그 표시
              if (mounted) {
                _showVideoDialog(videoUrl);
              }
            } else {
              // 영상이 없으면 첫 단계 설명 읽기
              Future.delayed(const Duration(milliseconds: 200), () {
                if (mounted && _phaseManager != null && _selectedExercise != null) {
                  final phaseDescription = _phaseManager!.currentPhase.description;
                  _ttsService.speak(phaseDescription);
                  _lastSpokenPhaseDescription = phaseDescription;
                }
              });
            }
          } else {
            // 첫 단계 설명 읽기
            Future.delayed(const Duration(milliseconds: 200), () {
              if (mounted && _phaseManager != null && _selectedExercise != null) {
                final phaseDescription = _phaseManager!.currentPhase.description;
                _ttsService.speak(phaseDescription);
                _lastSpokenPhaseDescription = phaseDescription;
              }
            });
          }
        });
      }
    } catch (e) {
      print('운동 데이터 로드 실패: $e');
    }
  }

  void _initializePoseDetector() {
    try {
      final options = PoseDetectorOptions(
        mode: PoseDetectionMode.stream,
        model: PoseDetectionModel.base,
      );
      _poseDetector = PoseDetector(options: options);
      print('포즈 감지기 초기화 완료 - base 모델 사용');
    } catch (e) {
      print('포즈 감지기 초기화 오류: $e');
    }
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

        _imageSizeNotifier.value = _controller!.value.previewSize;
        print('카메라 초기화 완료 - 프리뷰 크기: ${_imageSizeNotifier.value}');

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

    // 동영상 다이얼로그가 열려있으면 카메라 피드백 중단
    if (_isVideoDialogOpen) return;
    
    // 스킵 버튼이 눌려서 홈으로 이동 중이면 카메라 피드백 중단
    if (_isMovingToNext) return;

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

      // 로그 출력 최소화 (60프레임마다만)
      if (_frameCount % 60 == 0) {
        print('포즈 처리 완료: ${poses.length}개 감지 (프레임: $_frameCount)');
      }

      // 리스트 변환 최적화 - growable: false로 고정 크기 리스트 사용
      final smoothedPoses = List<Pose>.generate(
        poses.length,
        (i) => _landmarkSmoother.smoothPose(poses[i]),
        growable: false,
      );

      if (mounted) {
        // ValueNotifier로 변경 - setState 제거하여 리빌드 최소화
        _posesNotifier.value = smoothedPoses;
        _updateFeedback();
      }
    } catch (e) {
      // 로그 출력 최소화
      if (_frameCount % 60 == 0) {
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

  /// YouTube URL에서 영상 ID 추출
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
      _isVideoDialogOpen = true;
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) => AlertDialog(
          title: const Text('운동 영상'),
          content: const Text('영상을 외부 브라우저에서 열까요?'),
          actions: [
            TextButton(
              onPressed: () {
                _isVideoDialogOpen = false;
                Navigator.of(context).pop();
              },
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () async {
                _isVideoDialogOpen = false;
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
      ).then((_) {
        // 다이얼로그가 닫힐 때 플래그 리셋
        _isVideoDialogOpen = false;
      });
      return;
    }

    // YouTube 플레이어 다이얼로그
    _isVideoDialogOpen = true;
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
                      onPressed: () {
                        _isVideoDialogOpen = false;
                        Navigator.of(context).pop();
                      },
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
                    onPressed: () {
                      _isVideoDialogOpen = false;
                      Navigator.of(context).pop();
                    },
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
    ).then((_) {
      // 다이얼로그가 닫힐 때 플래그 리셋 (뒤로가기 버튼 등으로 닫힐 때도 처리)
      _isVideoDialogOpen = false;
    });
  }

  /// 개발자 전용: 진행 상태 종료하고 홈 화면으로 이동
  void _skipAllExercises() {
    // 중복 호출 방지
    if (_isMovingToNext) return;
    _isMovingToNext = true;
    
    print('🚀 개발자 스킵: 진행 상태 종료하고 홈 화면으로 이동합니다.');
    
    // 즉시 홈 화면으로 이동 (복잡한 로직 없이)
    Future.microtask(() {
      if (mounted) {
        _isMovingToNext = false;
        context.go('/app/home');
      }
    });
  }

  /// 다음 운동으로 이동하거나 모든 운동이 완료되면 운동 탭으로 돌아가기
  void _moveToNextExercise() {
    // 중복 호출 방지
    if (_isMovingToNext) return;
    _isMovingToNext = true;
    
    // 약간의 지연 후 다음 운동으로 이동 (사용자가 완료 메시지를 볼 수 있도록)
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) {
        _isMovingToNext = false;
        return;
      }
      
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
          _isMovingToNext = false; // 이동 플래그 리셋
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
        _isMovingToNext = false; // 플래그 리셋
        context.go('/app/home');
      }
    });
  }

  void _updateFeedback() {
    final poses = _posesNotifier.value;
    if (poses.isEmpty || _selectedExercise == null || _phaseManager == null) {
      _feedbacksNotifier.value = [];
      _scoreNotifier.value = 0.0;
      return;
    }

    final pose = poses[0];

    // 현재 페이즈의 각도 기준 가져오기
    final currentPhaseAngles = _phaseManager!.getCurrentPhaseAngles();

    final userAngles = _calculateUserAnglesWithPhase(pose, currentPhaseAngles);

    if (userAngles.isEmpty) {
      _feedbacksNotifier.value = ['전신이 보이도록 해주세요'];
      return;
    }

    final score = PoseScorer.calculateScore(
      userAngles,
      currentPhaseAngles,
    );

    final detailedScores = PoseScorer.calculateDetailedScores(
      userAngles,
      currentPhaseAngles,
    );

    final feedbacks = FeedbackGenerator.generateFeedback(
      userAngles,
      detailedScores,
      currentPhaseAngles,
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
          // 운동 완료 - TTS만 제공 (중복 방지)
          // _isMovingToNext가 true면 스킵 버튼이 눌린 상태이므로 더 이상 처리하지 않음
          if (!_wasCompleted && !_isMovingToNext && _lastSpokenFeedback != '🎉 운동 완료!') {
            _wasCompleted = true;
            ttsFeedbacks.add('🎉 운동 완료!');
            _moveToNextExercise();
          }
        } else {
          // 다음 단계 - TTS만 제공 (설명은 이미 읽음)
          ttsFeedbacks.add('✓ 다음 단계: ${_phaseManager!.currentPhase.phaseName}');
        }
      }
      
      // 첫 단계 시작 시 설명 읽기
      if (_phaseManager!.currentPhaseIndex == 0 && !_phaseManager!.isCompleted) {
        final phaseDescription = _phaseManager!.currentPhase.description;
        if (_lastSpokenPhaseDescription != phaseDescription) {
          _ttsService.speak(phaseDescription);
          _lastSpokenPhaseDescription = phaseDescription;
        }
      }
      
      // 운동 완료 상태 체크 (phaseChanged가 false여도 완료될 수 있음)
      // 단, 개발자 스킵 버튼으로 인한 완료는 제외 (중복 호출 방지)
      // _isMovingToNext가 true면 스킵 버튼이 눌린 상태이므로 더 이상 처리하지 않음
      if (_phaseManager!.isCompleted && !_wasCompleted && !_isMovingToNext) {
        _wasCompleted = true;
        // TTS만 제공 (중복 방지)
        if (_lastSpokenFeedback != '🎉 운동 완료!') {
          ttsFeedbacks.add('🎉 운동 완료!');
        }
        _moveToNextExercise();
      }

      // 준비 피드백 없음 - 점수 충족 시 즉시 통과
      readyFeedback = null;
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

    // 디버그 정보 업데이트
    if (_phaseManager != null) {
      _debugInfoNotifier.value = _phaseManager!.getDebugInfo(score);
    }

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

  /// 페이즈별 각도 기준으로 사용자 각도 계산
  /// 측면 촬영 시 한쪽 랜드마크만 보이는 경우도 처리
  Map<String, double> _calculateUserAnglesWithPhase(Pose pose, Map<String, KeyAngle> phaseAngles) {
    Map<String, double> angles = {};

    for (var entry in phaseAngles.entries) {
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

    // 측면 촬영 지원: 한쪽만 감지된 경우 반대쪽 각도도 채움
    _fillMirroredAngles(angles, phaseAngles);

    return angles;
  }

  /// 좌/우 대칭 각도 쌍 정의
  static const Map<String, String> _mirroredAnglePairs = {
    'left_knee_angle': 'right_knee_angle',
    'right_knee_angle': 'left_knee_angle',
    'left_hip_angle': 'right_hip_angle',
    'right_hip_angle': 'left_hip_angle',
    'left_hip_flexion': 'right_hip_flexion',
    'right_hip_flexion': 'left_hip_flexion',
    'left_body_tilt': 'right_body_tilt',
    'right_body_tilt': 'left_body_tilt',
  };

  /// 한쪽만 감지된 경우 반대쪽 각도를 복사하여 채움
  void _fillMirroredAngles(Map<String, double> angles, Map<String, KeyAngle> phaseAngles) {
    final anglesToAdd = <String, double>{};

    for (var entry in angles.entries) {
      final angleKey = entry.key;
      final mirroredKey = _mirroredAnglePairs[angleKey];

      // 반대쪽 각도가 정의되어 있고, 아직 계산되지 않은 경우
      if (mirroredKey != null &&
          phaseAngles.containsKey(mirroredKey) &&
          !angles.containsKey(mirroredKey)) {
        anglesToAdd[mirroredKey] = entry.value;
      }
    }

    angles.addAll(anglesToAdd);
  }

  /// 기존 메서드 (호환성 유지)
  Map<String, double> _calculateUserAngles(Pose pose, ExerciseModel exercise) {
    return _calculateUserAnglesWithPhase(pose, exercise.keyAngles);
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
          // 카메라 프리뷰와 스켈레톤을 좌우 반전 (거울 모드)
          Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()..scale(-1.0, 1.0),
            child: Stack(
              fit: StackFit.expand,
              children: [
                CameraPreview(_controller!),

                // ValueListenableBuilder로 스켈레톤만 선택적 리빌드
                ValueListenableBuilder<Size?>(
                  valueListenable: _imageSizeNotifier,
                  builder: (context, imageSize, child) {
                    if (imageSize == null || !_showSkeleton) {
                      return const SizedBox.shrink();
                    }
                    return ValueListenableBuilder<List<Pose>>(
                      valueListenable: _posesNotifier,
                      builder: (context, poses, child) {
                        return CustomPaint(
                          painter: PosePainter(
                            poses,
                            imageSize,
                            exercise: _selectedExercise,
                          ),
                          child: Container(),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),

          // 개발자 전용 스킵 버튼 - 모든 운동 완료 및 홈으로 이동
          Positioned(
            top: 48,
            left: 16,
            child: IconButton(
              icon: const Icon(
                Icons.skip_next,
                color: Colors.orange,
                size: 28,
              ),
              onPressed: _skipAllExercises,
              style: IconButton.styleFrom(
                backgroundColor: Colors.black.withValues(alpha: 0.5),
                padding: const EdgeInsets.all(12),
              ),
              tooltip: '개발자: 모든 운동 완료하고 홈으로 이동',
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
                    ValueListenableBuilder<List<Pose>>(
                      valueListenable: _posesNotifier,
                      builder: (context, poses, child) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: poses.isEmpty
                                ? Colors.red.withValues(alpha: 0.7)
                                : Colors.green.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            poses.isEmpty ? '포즈 감지 안됨' : '포즈 감지됨 ✓',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
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

          // 진행도 표시 바 (하단 배치)
          if (_phaseManager != null)
            Positioned(
              bottom: 24,
              left: 16,
              right: 16,
              child: PhaseProgressWidget(
                phaseManager: _phaseManager,
                currentExerciseIndex: widget.exerciseIds != null && widget.exerciseIds!.isNotEmpty
                    ? _currentExerciseIndex
                    : null,
                totalExercises: widget.exerciseIds != null && widget.exerciseIds!.isNotEmpty
                    ? _exercises.length
                    : null,
              ),
            ),

          // 디버그 정보 (좌측 하단)
          Positioned(
            bottom: 160,
            left: 16,
            child: ValueListenableBuilder<String>(
              valueListenable: _debugInfoNotifier,
              builder: (context, debugInfo, child) {
                if (debugInfo.isEmpty) return const SizedBox.shrink();
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    debugInfo,
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 12,
                      fontFamily: 'monospace',
                      height: 1.4,
                    ),
                  ),
                );
              },
            ),
          ),

          // 준비 피드백 (진행도 바 위에 배치)
          Positioned(
            bottom: 80, // 진행도 바 위에 위치 (진행도 바 높이 + 여백)
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
