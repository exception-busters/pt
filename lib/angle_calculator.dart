import 'dart:math';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// 각도 계산 유틸리티
class AngleCalculator {
  /// 세 점으로 이루어진 각도 계산 (3D 벡터 사용, degree)
  /// 
  /// point1 -----> point2 -----> point3
  ///                 ^
  ///                 | 
  ///              이 각도를 계산
  /// 
  /// 3D 공간에서 계산하므로 카메라 각도와 무관하게 정확한 측정 가능
  static double calculateAngle(
    PoseLandmark point1,  // 첫 번째 점
    PoseLandmark point2,  // 중심점 (각도를 측정할 점)
    PoseLandmark point3,  // 세 번째 점
  ) {
    // 1. 3D 벡터 계산
    // 벡터 A: point2 → point1
    final double ax = point1.x - point2.x;
    final double ay = point1.y - point2.y;
    final double az = point1.z - point2.z;
    
    // 벡터 B: point2 → point3
    final double bx = point3.x - point2.x;
    final double by = point3.y - point2.y;
    final double bz = point3.z - point2.z;

    // 2. 벡터의 크기 계산
    final double magnitudeA = sqrt(ax * ax + ay * ay + az * az);
    final double magnitudeB = sqrt(bx * bx + by * by + bz * bz);

    // 3. 벡터의 크기가 0이면 각도를 계산할 수 없음
    if (magnitudeA == 0 || magnitudeB == 0) {
      return 0.0;
    }

    // 4. 내적(Dot Product) 계산
    final double dotProduct = ax * bx + ay * by + az * bz;

    // 5. 코사인 값 계산 (내적 / (크기A * 크기B))
    double cosineAngle = dotProduct / (magnitudeA * magnitudeB);
    
    // 6. 코사인 값을 -1 ~ 1 범위로 클램핑 (부동소수점 오차 방지)
    cosineAngle = cosineAngle.clamp(-1.0, 1.0);

    // 7. 아크코사인으로 각도 계산 (라디안)
    final double radians = acos(cosineAngle);

    // 8. 라디안 → 도(degree) 변환
    final double angle = radians * 180.0 / pi;

    return angle;
  }

  /// 2D 각도 계산 (호환성을 위해 유지)
  static double calculateAngle2D(
    PoseLandmark point1,
    PoseLandmark point2,
    PoseLandmark point3,
  ) {
    final double radians = atan2(
      point3.y - point2.y,
      point3.x - point2.x
    ) - atan2(
      point1.y - point2.y,
      point1.x - point2.x
    );

    double angle = radians * 180.0 / pi;
    angle = angle.abs();
    if (angle > 180.0) {
      angle = 360.0 - angle;
    }

    return angle;
  }
}
