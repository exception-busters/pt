import 'dart:math';

import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class AngleCalculator {
  static double calculateAngle(PoseLandmark p1, PoseLandmark p2, PoseLandmark p3) {
    final angle = (atan2(p3.y - p2.y, p3.x - p2.x) - atan2(p1.y - p2.y, p1.x - p2.x)) * 180 / pi;
    return angle.abs();
  }
}
