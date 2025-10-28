import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

// 🚀 최적화 4: 카메라 설정 최적화
class OptimizedCameraController {
  static const Map<String, ResolutionPreset> _resolutionPresets = {
    'ultra_low': ResolutionPreset.veryLow,    // 240x320
    'low': ResolutionPreset.low,               // 480x640
    'medium': ResolutionPreset.medium,         // 720x1280
    'high': ResolutionPreset.high,             // 1080x1920
  };

  static CameraController? _controller;
  static bool _isInitialized = false;

  // 🚀 최적화: 동적 해상도 조정
  static Future<CameraController> initializeCamera({
    String resolution = 'low',
    bool enableAudio = false,
  }) async {
    if (_controller != null && _isInitialized) {
      return _controller!;
    }

    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      throw CameraException('NoCamerasAvailable', 'No cameras found');
    }

    final preset = _resolutionPresets[resolution] ?? ResolutionPreset.low;
    
    _controller = CameraController(
      cameras.first,
      preset,
      enableAudio: enableAudio,
      imageFormatGroup: ImageFormatGroup.yuv420, // 🚀 최적화: 효율적인 포맷 사용
    );

    await _controller!.initialize();
    _isInitialized = true;
    
    debugPrint('카메라 초기화 완료: ${_controller!.value.previewSize}');
    return _controller!;
  }

  // 🚀 최적화: 메모리 효율적인 카메라 해제
  static Future<void> dispose() async {
    if (_controller != null) {
      await _controller!.dispose();
      _controller = null;
      _isInitialized = false;
    }
  }

  // 🚀 최적화: 카메라 상태 모니터링
  static Stream<CameraValue> get cameraValueStream {
    if (_controller == null) {
      throw CameraException('CameraNotInitialized', 'Camera not initialized');
    }
    return _controller!.valueStream;
  }
}

// 🚀 최적화 5: 카메라 프레임 처리 최적화
class FrameProcessor {
  static const int _maxFrameRate = 30;
  static const int _minFrameRate = 10;
  
  static DateTime? _lastProcessedTime;
  static int _currentFrameRate = _minFrameRate;

  // 🚀 최적화: 적응형 프레임 레이트 조정
  static bool shouldProcessFrame() {
    final now = DateTime.now();
    
    if (_lastProcessedTime == null) {
      _lastProcessedTime = now;
      return true;
    }

    final timeDiff = now.difference(_lastProcessedTime!);
    final targetInterval = Duration(milliseconds: 1000 ~/ _currentFrameRate);
    
    if (timeDiff >= targetInterval) {
      _lastProcessedTime = now;
      
      // 🚀 최적화: CPU 사용량에 따른 프레임 레이트 조정
      _adjustFrameRate();
      return true;
    }
    
    return false;
  }

  static void _adjustFrameRate() {
    // 실제 구현에서는 CPU 사용량을 모니터링하여 조정
    // 여기서는 간단한 예시
    if (_currentFrameRate < _maxFrameRate) {
      _currentFrameRate = (_currentFrameRate + 1).clamp(_minFrameRate, _maxFrameRate);
    }
  }

  static void resetFrameRate() {
    _currentFrameRate = _minFrameRate;
    _lastProcessedTime = null;
  }
}

