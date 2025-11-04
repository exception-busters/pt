import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'dart:math';

/// 랜드마크 좌표 스무딩 서비스
/// - Exponential Moving Average (EMA) 사용
/// - 임계값 기반 필터링으로 미세한 떨림 제거
/// - 자연스러운 움직임 유지
class LandmarkSmoother {
  // EMA 알파 값 (0~1, 낮을수록 더 부드럽지만 반응이 느림)
  final double alpha;
  
  // 움직임 임계값 (픽셀 단위, 이 값보다 작은 움직임은 무시)
  final double movementThreshold;
  
  // 각 랜드마크의 이전 평활화된 좌표를 저장
  final Map<PoseLandmarkType, _SmoothedPoint> _previousPoints = {};
  
  LandmarkSmoother({
    this.alpha = 0.3,  // 기본값: 적당한 스무딩 (0.3 = 30% 새 값, 70% 이전 값)
    this.movementThreshold = 3.0,  // 기본값: 3픽셀 이하 움직임은 무시
  });

  /// 포즈 랜드마크 스무딩
  Pose smoothPose(Pose pose) {
    final smoothedLandmarks = <PoseLandmarkType, PoseLandmark>{};
    
    for (final entry in pose.landmarks.entries) {
      final type = entry.key;
      final landmark = entry.value;
      
      final smoothedPoint = _smoothLandmark(type, landmark);
      
      // 새로운 PoseLandmark 생성
      smoothedLandmarks[type] = PoseLandmark(
        type: type,
        x: smoothedPoint.x,
        y: smoothedPoint.y,
        z: smoothedPoint.z,
        likelihood: landmark.likelihood,
      );
    }
    
    return Pose(
      landmarks: smoothedLandmarks,
    );
  }

  /// 개별 랜드마크 스무딩
  _SmoothedPoint _smoothLandmark(PoseLandmarkType type, PoseLandmark landmark) {
    final currentPoint = _SmoothedPoint(
      x: landmark.x,
      y: landmark.y,
      z: landmark.z,
    );
    
    // 첫 번째 프레임이거나 이전 값이 없으면 현재 값 사용
    if (!_previousPoints.containsKey(type)) {
      _previousPoints[type] = currentPoint;
      return currentPoint;
    }
    
    final previousPoint = _previousPoints[type]!;
    
    // 움직임 거리 계산 (2D 평면에서만, z는 별도)
    final distance = sqrt(
      pow(currentPoint.x - previousPoint.x, 2) +
      pow(currentPoint.y - previousPoint.y, 2)
    );
    
    // 임계값보다 작은 움직임은 무시 (이전 값 유지)
    if (distance < movementThreshold) {
      return previousPoint;
    }
    
    // EMA 적용: smoothed = alpha * current + (1 - alpha) * previous
    final smoothedPoint = _SmoothedPoint(
      x: alpha * currentPoint.x + (1 - alpha) * previousPoint.x,
      y: alpha * currentPoint.y + (1 - alpha) * previousPoint.y,
      z: alpha * currentPoint.z + (1 - alpha) * previousPoint.z,
    );
    
    // 다음 프레임을 위해 저장
    _previousPoints[type] = smoothedPoint;
    
    return smoothedPoint;
  }

  /// 모든 버퍼 초기화 (운동 변경 시 사용)
  void resetAll() {
    _previousPoints.clear();
  }

  /// 특정 랜드마크의 버퍼만 초기화
  void reset(PoseLandmarkType type) {
    _previousPoints.remove(type);
  }
}

/// 스무딩된 3D 포인트
class _SmoothedPoint {
  final double x;
  final double y;
  final double z;

  _SmoothedPoint({
    required this.x,
    required this.y,
    required this.z,
  });
}

