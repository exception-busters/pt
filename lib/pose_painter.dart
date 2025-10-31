import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class PosePainter extends CustomPainter {
  PosePainter(this.poses, this.imageSize);

  final List<Pose> poses;
  final Size imageSize;

  @override
  void paint(Canvas canvas, Size size) {
    // 디버그: 캔버스 크기와 이미지 크기 출력
    print('PosePainter - 캔버스 크기: $size, 이미지 크기: $imageSize, 포즈 개수: ${poses.length}');
    
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..color = Colors.greenAccent
      ..strokeCap = StrokeCap.round;

    final circlePaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    for (final pose in poses) {
      // 모든 랜드마크에 점 그리기
      for (final landmark in pose.landmarks.values) {
        final translatedPoint = _translatePoint(landmark.x, landmark.y, imageSize, size);
        canvas.drawCircle(translatedPoint, 8.0, circlePaint);
      }
      
      // 디버그: 첫 번째 랜드마크 위치 출력
      if (pose.landmarks.isNotEmpty) {
        final firstLandmark = pose.landmarks.values.first;
        print('첫 번째 랜드마크 위치: (${firstLandmark.x}, ${firstLandmark.y})');
      }

      // 몸통 연결
      _drawConnection(canvas, paint, pose, PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder, imageSize, size);
      _drawConnection(canvas, paint, pose, PoseLandmarkType.leftHip, PoseLandmarkType.rightHip, imageSize, size);
      _drawConnection(canvas, paint, pose, PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip, imageSize, size);
      _drawConnection(canvas, paint, pose, PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip, imageSize, size);
      
      // 왼팔
      _drawConnection(canvas, paint, pose, PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow, imageSize, size);
      _drawConnection(canvas, paint, pose, PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist, imageSize, size);
      
      // 오른팔
      _drawConnection(canvas, paint, pose, PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow, imageSize, size);
      _drawConnection(canvas, paint, pose, PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist, imageSize, size);
      
      // 왼다리
      _drawConnection(canvas, paint, pose, PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee, imageSize, size);
      _drawConnection(canvas, paint, pose, PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle, imageSize, size);
      
      // 오른다리
      _drawConnection(canvas, paint, pose, PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee, imageSize, size);
      _drawConnection(canvas, paint, pose, PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle, imageSize, size);
    }
  }

  void _drawConnection(
      Canvas canvas,
      Paint paint,
      Pose pose,
      PoseLandmarkType type1,
      PoseLandmarkType type2,
      Size inputImageSize,
      Size size) {
    final landmark1 = pose.landmarks[type1];
    final landmark2 = pose.landmarks[type2];

    if (landmark1 != null && landmark2 != null) {
      final point1 = _translatePoint(landmark1.x, landmark1.y, inputImageSize, size);
      final point2 = _translatePoint(landmark2.x, landmark2.y, inputImageSize, size);
      canvas.drawLine(point1, point2, paint);
    }
  }

  Offset _translatePoint(double x, double y, Size inputImageSize, Size size) {
    // 단순 스케일링만 적용
    final double scaleX = size.width / inputImageSize.width;
    final double scaleY = size.height / inputImageSize.height;
    
    return Offset(x * scaleX, y * scaleY);
  }

  @override
  bool shouldRepaint(PosePainter oldDelegate) {
    return oldDelegate.poses != poses || oldDelegate.imageSize != imageSize;
  }
}
