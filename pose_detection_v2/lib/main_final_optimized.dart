import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'dart:convert';

// 🚀 최종 최적화된 메인 앱
void main() {
  runApp(const PoseDetectionApp());
}

class PoseDetectionApp extends StatelessWidget {
  const PoseDetectionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pose Detection V2 - Optimized',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const PoseDetectionScreen(),
      // 🚀 최적화: 디버그 배너 비활성화 (릴리즈에서)
      debugShowCheckedModeBanner: false,
    );
  }
}

class PoseDetectionScreen extends StatefulWidget {
  const PoseDetectionScreen({super.key});

  @override
  State<PoseDetectionScreen> createState() => _PoseDetectionScreenState();
}

class _PoseDetectionScreenState extends State<PoseDetectionScreen>
    with SafeWidgetLifecycle {
  
  CameraController? _cameraController;
  PoseDetectionState? _state;
  PoseDataStream? _poseDataStream;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    _state = PoseDetectionState();
    _poseDataStream = PoseDataStream();
    
    await _initializeCamera();
    await _startPoseDetection();
    _setupPoseDataListener();
  }

  Future<void> _initializeCamera() async {
    final status = await Permission.camera.request();
    if (status != PermissionStatus.granted) {
      _showErrorDialog('카메라 권한이 필요합니다.');
      return;
    }

    try {
      _cameraController = await OptimizedCameraController.initializeCamera(
        resolution: 'low',
        enableAudio: false,
      );
      
      _state?.setInitialized(true);
    } catch (e) {
      _showErrorDialog('카메라 초기화 중 오류가 발생했습니다: $e');
    }
  }

  Future<void> _startPoseDetection() async {
    final success = await _poseDataStream?.startDetection() ?? false;
    _state?.setServerRunning(success);
    _state?.setServerStatus(success ? "서버 연결됨" : "서버 연결 실패");
  }

  void _setupPoseDataListener() {
    _poseDataStream?.poseStream.listen(
      (data) {
        // 🚀 최적화: Isolate에서 데이터 처리
        PoseDataProcessor.processPoseDataInIsolate(data).then((processedData) {
          safeSetState(() {
            _state?.setPoseData(processedData);
          });
        });
      },
      onError: (error) {
        debugPrint('포즈 데이터 스트림 오류: $error');
      },
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('오류'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _poseDataStream?.dispose();
    _state?.dispose();
    OptimizedCameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Pose Detection V2 - Optimized'),
      ),
      body: _state?.isInitialized == true
          ? _OptimizedPoseDetectionBody(
              cameraController: _cameraController!,
              state: _state!,
            )
          : const Center(
              child: CircularProgressIndicator(),
            ),
    );
  }
}

// 🚀 최적화된 메인 바디 위젯
class _OptimizedPoseDetectionBody extends StatelessWidget {
  final CameraController cameraController;
  final PoseDetectionState state;

  const _OptimizedPoseDetectionBody({
    required this.cameraController,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 카메라 미리보기
        Positioned.fill(
          child: Container(
            color: Colors.black,
            child: CameraPreview(cameraController),
          ),
        ),
        // 포즈 오버레이 (조건부 렌더링)
        OptimizedWidgetBuilder.conditional(
          condition: state.poseData != null,
          builder: () => Positioned.fill(
            child: CustomPaint(
              painter: OptimizedPosePainter(state.poseData!),
              child: const SizedBox.expand(),
            ),
          ),
        ),
        // 상태 정보 (ValueListenableBuilder 사용)
        ValueListenableBuilder<int>(
          valueListenable: state.poseCountNotifier,
          builder: (context, poseCount, child) {
            return ValueListenableBuilder<String>(
              valueListenable: state.serverStatusNotifier,
              builder: (context, serverStatus, child) {
                return Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: AppConstants.statusPadding,
                    decoration: AppConstants.statusDecoration,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '감지된 포즈: $poseCount개',
                          style: AppConstants.statusTextStyle,
                        ),
                        Text(
                          '서버: $serverStatus',
                          style: AppConstants.serverTextStyle,
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
        // 디버그 정보
        const Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: _DebugInfoOverlay(),
        ),
      ],
    );
  }
}

// 🚀 최적화된 디버그 정보 위젯
class _DebugInfoOverlay extends StatelessWidget {
  const _DebugInfoOverlay();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppConstants.debugPadding,
      decoration: AppConstants.debugDecoration,
      child: const Text(
        'Python 서버 + Flutter 클라이언트 구조\n실시간 포즈 감지 (최적화됨)',
        style: AppConstants.debugTextStyle,
        textAlign: TextAlign.center,
      ),
    );
  }
}

// 🚀 최적화된 포즈 페인터
class OptimizedPosePainter extends CustomPainter {
  final Map<String, dynamic> poseData;

  OptimizedPosePainter(this.poseData);

  @override
  void paint(Canvas canvas, Size size) {
    if (poseData['landmarks'] == null) return;

    // 🚀 최적화: Paint 객체 재사용
    final linePaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    final pointPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    final landmarks = poseData['landmarks'] as List<dynamic>;
    final connections = poseData['connections'] as List<dynamic>?;

    // 🚀 최적화: 랜드마크 그리기
    for (final landmark in landmarks) {
      final point = Offset(
        landmark['x'] * size.width,
        landmark['y'] * size.height,
      );
      canvas.drawCircle(point, 8, pointPaint);
    }

    // 🚀 최적화: 연결선 그리기
    if (connections != null) {
      for (final connection in connections) {
        final startIndex = connection['start'] as int;
        final endIndex = connection['end'] as int;
        
        if (startIndex < landmarks.length && endIndex < landmarks.length) {
          final startLandmark = landmarks[startIndex];
          final endLandmark = landmarks[endIndex];
          
          final startPoint = Offset(
            startLandmark['x'] * size.width,
            startLandmark['y'] * size.height,
          );
          final endPoint = Offset(
            endLandmark['x'] * size.width,
            endLandmark['y'] * size.height,
          );
          canvas.drawLine(startPoint, endPoint, linePaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is OptimizedPosePainter) {
      return oldDelegate.poseData != poseData;
    }
    return true;
  }
}
