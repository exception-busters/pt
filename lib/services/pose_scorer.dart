import 'dart:math';
import '../models/exercise_model.dart';

/// 포즈 점수 계산기
class PoseScorer {
  /// 전체 점수 계산 (100점 만점)
  static double calculateScore(
    Map<String, double> userAngles,      // 사용자의 현재 각도
    Map<String, KeyAngle> referenceAngles // 정답 데이터의 각도
  ) {
    double totalScore = 0.0;
    double totalWeight = 0.0;
    
    for (var angleKey in referenceAngles.keys) {
      final ref = referenceAngles[angleKey]!;
      final userAngle = userAngles[angleKey];
      
      if (userAngle == null) continue;
      
      // 각도 차이 계산
      final angleDiff = (userAngle - ref.idealMean).abs();
      final tolerance = ref.tolerance;
      final weight = ref.weight;
      
      // 점수 계산 (tolerance 내면 만점, 벗어나면 감점)
      double angleScore;
      if (angleDiff <= tolerance) {
        angleScore = 100.0;
      } else {
        // 선형 감점 (tolerance의 2배 벗어나면 0점)
        angleScore = max(0.0, 100.0 - (angleDiff - tolerance) * (100.0 / tolerance));
      }
      
      totalScore += angleScore * weight;
      totalWeight += weight;
    }
    
    return totalWeight > 0 ? totalScore / totalWeight : 0.0;
  }
  
  /// 각 관절별 점수 계산
  static Map<String, double> calculateDetailedScores(
    Map<String, double> userAngles,
    Map<String, KeyAngle> referenceAngles
  ) {
    Map<String, double> scores = {};
    
    for (var angleKey in referenceAngles.keys) {
      final ref = referenceAngles[angleKey]!;
      final userAngle = userAngles[angleKey];
      
      if (userAngle == null) {
        scores[angleKey] = 0.0;
        continue;
      }
      
      final angleDiff = (userAngle - ref.idealMean).abs();
      final tolerance = ref.tolerance;
      
      if (angleDiff <= tolerance) {
        scores[angleKey] = 100.0;
      } else {
        scores[angleKey] = max(0.0, 100.0 - (angleDiff - tolerance) * (100.0 / tolerance));
      }
    }
    
    return scores;
  }

  /// 각도가 이상적인 범위 내에 있는지 확인
  static bool isAngleInIdealRange(double angle, KeyAngle reference) {
    return angle >= reference.idealRange[0] && angle <= reference.idealRange[1];
  }

  /// 각도 차이 계산
  static double getAngleDifference(double userAngle, KeyAngle reference) {
    return (userAngle - reference.idealMean).abs();
  }
}


