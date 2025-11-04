import 'dart:math';
import '../models/exercise_model.dart';

// 점수 계산이 더 관대해졌습니다:
// - tolerance 내: 100점
// - tolerance의 2배: 100점 → 50점 (완만한 곡선)
// - tolerance의 3배: 50점 → 10점
// - 그 이상: 최소 10점 보장

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
      
      // 점수 계산 (tolerance 내면 만점, 벗어나면 관대하게 감점)
      double angleScore;
      if (angleDiff <= tolerance) {
        // tolerance 내: 100점
        angleScore = 100.0;
      } else if (angleDiff <= tolerance * 2) {
        // tolerance의 2배까지: 완만한 감점 (제곱근 사용)
        final excess = angleDiff - tolerance;
        final ratio = excess / tolerance;
        angleScore = 100.0 - (50.0 * sqrt(ratio)); // 50점까지만 감점
      } else if (angleDiff <= tolerance * 3) {
        // tolerance의 3배까지: 추가 감점
        final excess = angleDiff - tolerance * 2;
        final ratio = excess / tolerance;
        angleScore = 50.0 - (40.0 * ratio); // 10점까지만 감점
      } else {
        // tolerance의 3배 초과: 최소 10점 유지 (0점은 너무 가혹함)
        angleScore = 10.0;
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
      } else if (angleDiff <= tolerance * 2) {
        final excess = angleDiff - tolerance;
        final ratio = excess / tolerance;
        scores[angleKey] = 100.0 - (50.0 * sqrt(ratio));
      } else if (angleDiff <= tolerance * 3) {
        final excess = angleDiff - tolerance * 2;
        final ratio = excess / tolerance;
        scores[angleKey] = 50.0 - (40.0 * ratio);
      } else {
        scores[angleKey] = 10.0;
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


