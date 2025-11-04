import '../models/exercise_model.dart';

// 정확한 점수 계산 시스템:
// - tolerance의 50% 내: 100점 (완벽)
// - tolerance의 50% ~ 100%: 100점 → 80점 (선형 감점)
// - tolerance의 100% ~ 150%: 80점 → 50점 (선형 감점)
// - tolerance의 150% ~ 200%: 50점 → 20점 (선형 감점)
// - tolerance의 200% 초과: 20점 → 0점 (선형 감점)

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
      
      // 정확한 점수 계산 (엄격한 기준)
      double angleScore;
      
      if (angleDiff <= tolerance * 0.5) {
        // tolerance의 50% 내: 100점 (완벽)
        angleScore = 100.0;
      } else if (angleDiff <= tolerance) {
        // tolerance의 50% ~ 100%: 100점 → 80점 (선형 감점)
        final excess = angleDiff - tolerance * 0.5;
        final ratio = excess / (tolerance * 0.5);
        angleScore = 100.0 - (20.0 * ratio);
      } else if (angleDiff <= tolerance * 1.5) {
        // tolerance의 100% ~ 150%: 80점 → 50점 (선형 감점)
        final excess = angleDiff - tolerance;
        final ratio = excess / (tolerance * 0.5);
        angleScore = 80.0 - (30.0 * ratio);
      } else if (angleDiff <= tolerance * 2.0) {
        // tolerance의 150% ~ 200%: 50점 → 20점 (선형 감점)
        final excess = angleDiff - tolerance * 1.5;
        final ratio = excess / (tolerance * 0.5);
        angleScore = 50.0 - (30.0 * ratio);
      } else {
        // tolerance의 200% 초과: 20점 → 0점 (선형 감점)
        final excess = angleDiff - tolerance * 2.0;
        final ratio = excess / tolerance;
        angleScore = (20.0 - (20.0 * ratio.clamp(0.0, 1.0))).clamp(0.0, 20.0);
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
      
      // 정확한 점수 계산 (전체 점수와 동일한 로직)
      if (angleDiff <= tolerance * 0.5) {
        scores[angleKey] = 100.0;
      } else if (angleDiff <= tolerance) {
        final excess = angleDiff - tolerance * 0.5;
        final ratio = excess / (tolerance * 0.5);
        scores[angleKey] = 100.0 - (20.0 * ratio);
      } else if (angleDiff <= tolerance * 1.5) {
        final excess = angleDiff - tolerance;
        final ratio = excess / (tolerance * 0.5);
        scores[angleKey] = 80.0 - (30.0 * ratio);
      } else if (angleDiff <= tolerance * 2.0) {
        final excess = angleDiff - tolerance * 1.5;
        final ratio = excess / (tolerance * 0.5);
        scores[angleKey] = 50.0 - (30.0 * ratio);
      } else {
        final excess = angleDiff - tolerance * 2.0;
        final ratio = excess / tolerance;
        scores[angleKey] = (20.0 - (20.0 * ratio.clamp(0.0, 1.0))).clamp(0.0, 20.0);
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


