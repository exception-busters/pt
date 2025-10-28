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
    // 카메라 권한 요청
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
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();

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
      // Python 서버 시작 요청
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
        
        // 주기적으로 포즈 데이터 가져오기
        _poseTimer = Timer.periodic(Duration(milliseconds: 100), (timer) {
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
          ? Stack(
              children: [
                // 카메라 미리보기
                Positioned.fill(
                  child: CameraPreview(_cameraController!),
                ),
                // 포즈 오버레이
                if (_poseData != null)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: PosePainter(_poseData),
                    ),
                  ),
                // 상태 정보
                Positioned(
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
                      children: [
                        Text(
                          '감지된 포즈: ${_poseData != null && _poseData!['landmarks'] != null ? _poseData!['landmarks'].length : 0}개',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '서버: $_serverStatus',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // 디버그 정보
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Python 서버 + Flutter 클라이언트 구조\n실시간 포즈 감지',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            )
          : const Center(
              child: CircularProgressIndicator(),
            ),
    );
  }
}

class PosePainter extends CustomPainter {
  final Map<String, dynamic>? poseData;

  PosePainter(this.poseData);

  @override
  void paint(Canvas canvas, Size size) {
    if (poseData == null || poseData!['landmarks'] == null) return;

    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    final pointPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    final landmarks = poseData!['landmarks'] as List<dynamic>;
    final connections = poseData!['connections'] as List<dynamic>?;

    // 포즈 랜드마크 그리기
    for (int i = 0; i < landmarks.length; i++) {
      final landmark = landmarks[i] as Map<String, dynamic>;
      final point = Offset(
        landmark['x'] * size.width,
        landmark['y'] * size.height,
      );
      canvas.drawCircle(point, 5, pointPaint);
    }

    // 포즈 연결선 그리기
    if (connections != null) {
      for (final connection in connections) {
        final startIndex = connection['start'] as int;
        final endIndex = connection['end'] as int;
        
        if (startIndex < landmarks.length && endIndex < landmarks.length) {
          final startLandmark = landmarks[startIndex] as Map<String, dynamic>;
          final endLandmark = landmarks[endIndex] as Map<String, dynamic>;
          
          final startPoint = Offset(
            startLandmark['x'] * size.width,
            startLandmark['y'] * size.height,
          );
          final endPoint = Offset(
            endLandmark['x'] * size.width,
            endLandmark['y'] * size.height,
          );
          canvas.drawLine(startPoint, endPoint, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}