import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// 포즈 스켈레톤 렌더링을 위한 CustomPainter
class PosePainter extends CustomPainter {
  final List<Pose> poses;      // 감지된 포즈 목록
  final Size imageSize;        // 원본 이미지 크기

  PosePainter(this.poses, this.imageSize);

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

  /// 연결선 그리기
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

  /// 좌표 변환 (이미지 크기 → 캔버스 크기)
  Offset _translatePoint(double x, double y, Size inputImageSize, Size size) {
    // 이미지 크기 → 캔버스 크기로 스케일링
    final double scaleX = size.width / inputImageSize.width;
    final double scaleY = size.height / inputImageSize.height;
    
    return Offset(x * scaleX, y * scaleY);
  }

  @override
  bool shouldRepaint(PosePainter oldDelegate) {
    return oldDelegate.poses != poses || oldDelegate.imageSize != imageSize;
  }
}



