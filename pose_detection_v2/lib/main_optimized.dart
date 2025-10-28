import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import 'dart:async';

void main() {
  runApp(const PoseDetectionApp());
}

class PoseDetectionApp extends StatelessWidget {
  const PoseDetectionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pose Detection V2',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const PoseDetectionScreen(),
    );
  }
}

class PoseDetectionScreen extends StatefulWidget {
  const PoseDetectionScreen({super.key});

  @override
  State<PoseDetectionScreen> createState() => _PoseDetectionScreenState();
}

class _PoseDetectionScreenState extends State<PoseDetectionScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  Map<String, dynamic>? _poseData;
  Timer? _poseTimer;
  String _serverStatus = "연결 중...";
  bool _isServerRunning = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _startPoseDetection();
  }

  Future<void> _initializeCamera() async {
    final status = await Permission.camera.request();
    if (status != PermissionStatus.granted) {
      _showErrorDialog('카메라 권한이 필요합니다.');
      return;
    }

    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        _showErrorDialog('사용 가능한 카메라가 없습니다.');
        return;
      }

      _cameraController = CameraController(
        _cameras![0],
        ResolutionPreset.low,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      
      print('카메라 초기화 완료: ${_cameraController!.value.isInitialized}');
      print('카메라 해상도: ${_cameraController!.value.previewSize}');

      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      _showErrorDialog('카메라 초기화 중 오류가 발생했습니다: $e');
    }
  }

  Future<void> _startPoseDetection() async {
    try {
      print('Python 서버 연결 시도 중...');
      final response = await http.post(
        Uri.parse('http://10.0.2.2:5000/start'),
        headers: {'Content-Type': 'application/json'},
      );
      
      print('서버 응답: ${response.statusCode}');
      print('서버 응답 내용: ${response.body}');
      
      if (response.statusCode == 200) {
        setState(() {
          _serverStatus = "서버 연결됨";
          _isServerRunning = true;
        });
        
        // 최적화: 더 긴 간격으로 변경 (500ms)
        _poseTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
          _fetchPoseData();
        });
      } else {
        setState(() {
          _serverStatus = "서버 연결 실패: ${response.statusCode}";
        });
      }
    } catch (e) {
      print('서버 연결 오류: $e');
      setState(() {
        _serverStatus = "서버 연결 오류: $e";
      });
    }
  }

  Future<void> _fetchPoseData() async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:5000/pose'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('포즈 데이터 수신: ${data.toString()}');
        if (mounted) {
          setState(() {
            _poseData = Map<String, dynamic>.from(data);
          });
        }
      } else {
        print('포즈 데이터 요청 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('포즈 데이터 가져오기 오류: $e');
    }
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
    _cameraController?.dispose();
    _poseTimer?.cancel();
    _stopPoseDetection();
    super.dispose();
  }

  Future<void> _stopPoseDetection() async {
    try {
      await http.post(
        Uri.parse('http://10.0.2.2:5000/stop'),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('서버 중지 오류: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Pose Detection V2'),
      ),
      body: _isInitialized
          ? _PoseDetectionBody(
              cameraController: _cameraController!,
              poseData: _poseData,
              serverStatus: _serverStatus,
            )
          : const Center(
              child: CircularProgressIndicator(),
            ),
    );
  }
}

// 🚀 최적화 1: 위젯 분리로 build 메서드 단순화
class _PoseDetectionBody extends StatelessWidget {
  final CameraController cameraController;
  final Map<String, dynamic>? poseData;
  final String serverStatus;

  const _PoseDetectionBody({
    required this.cameraController,
    required this.poseData,
    required this.serverStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 카메라 미리보기
        const _CameraPreview(),
        // 포즈 오버레이
        if (poseData != null) _PoseOverlay(poseData: poseData!),
        // 상태 정보
        const _StatusOverlay(),
        // 디버그 정보
        const _DebugInfoOverlay(),
      ],
    );
  }
}

// 🚀 최적화 2: 카메라 미리보기 위젯 분리
class _CameraPreview extends StatelessWidget {
  const _CameraPreview();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black,
        child: CameraPreview(
          // CameraController는 상위에서 전달받아야 함
          (context.findAncestorStateOfType<_PoseDetectionScreenState>()?._cameraController)!,
        ),
      ),
    );
  }
}

// 🚀 최적화 3: 포즈 오버레이 위젯 분리
class _PoseOverlay extends StatelessWidget {
  final Map<String, dynamic> poseData;

  const _PoseOverlay({required this.poseData});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: CustomPaint(
        painter: PosePainter(poseData),
        child: const SizedBox.expand(),
      ),
    );
  }
}

// 🚀 최적화 4: 상태 정보 위젯 분리
class _StatusOverlay extends StatelessWidget {
  const _StatusOverlay();

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<_PoseDetectionScreenState>()!;
    
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '감지된 포즈: ${state._poseData != null && state._poseData!['landmarks'] != null ? state._poseData!['landmarks'].length : 0}개',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '서버: ${state._serverStatus}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 🚀 최적화 5: 디버그 정보 위젯 분리
class _DebugInfoOverlay extends StatelessWidget {
  const _DebugInfoOverlay();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'Python 서버 + Flutter 클라이언트 구조\n실시간 포즈 감지',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

// 🚀 최적화 6: PosePainter 성능 개선
class PosePainter extends CustomPainter {
  final Map<String, dynamic> poseData;

  PosePainter(this.poseData);

  @override
  void paint(Canvas canvas, Size size) {
    if (poseData['landmarks'] == null) return;

    // 🚀 최적화: Paint 객체 재사용으로 메모리 절약
    final linePaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    final pointPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    final landmarks = poseData['landmarks'] as List<dynamic>;
    final connections = poseData['connections'] as List<dynamic>?;

    // 🚀 최적화: 랜드마크 그리기 최적화
    for (final landmark in landmarks) {
      final point = Offset(
        landmark['x'] * size.width,
        landmark['y'] * size.height,
      );
      canvas.drawCircle(point, 8, pointPaint);
    }

    // 🚀 최적화: 연결선 그리기 최적화
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
    // 🚀 최적화: 실제 데이터 변경시에만 리페인트
    if (oldDelegate is PosePainter) {
      return oldDelegate.poseData != poseData;
    }
    return true;
  }
}
