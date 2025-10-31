import '../models/exercise_model.dart';

/// 피드백 생성기
class FeedbackGenerator {
  /// 실시간 피드백 생성
  static List<String> generateFeedback(
    Map<String, double> userAngles,
    Map<String, double> detailedScores,
    Map<String, KeyAngle> referenceAngles,
    List<FeedbackRule> feedbackRules,
  ) {
    List<String> feedbacks = [];
    
    // 1. 점수 기반 피드백
    for (var angleKey in detailedScores.keys) {
      final score = detailedScores[angleKey]!;
      final ref = referenceAngles[angleKey];
      final userAngle = userAngles[angleKey];
      
      if (ref == null || userAngle == null) continue;
      
      final idealMean = ref.idealMean;
      final name = ref.name;
      
      if (score < 50) {
        // 각도가 너무 벗어남
        if (userAngle < idealMean) {
          feedbacks.add('$name: 각도를 더 벌려주세요 (현재: ${userAngle.toStringAsFixed(1)}°)');
        } else {
          feedbacks.add('$name: 각도를 줄여주세요 (현재: ${userAngle.toStringAsFixed(1)}°)');
        }
      } else if (score < 80) {
        feedbacks.add('$name: 조금 더 조정이 필요합니다');
      }
    }
    
    // 2. 규칙 기반 피드백 (간단한 구현)
    for (var rule in feedbackRules) {
      if (_evaluateSimpleCondition(rule.condition, userAngles)) {
        feedbacks.add(rule.feedback);
      }
    }
    
    // 3. 전체 점수에 따른 피드백
    if (detailedScores.isNotEmpty) {
      final avgScore = detailedScores.values.reduce((a, b) => a + b) / detailedScores.length;
      String overallFeedback;
      
      if (avgScore >= 90) {
        overallFeedback = '✓ 완벽한 자세입니다!';
      } else if (avgScore >= 70) {
        overallFeedback = '좋습니다! 조금만 더 개선해보세요';
      } else if (avgScore >= 50) {
        overallFeedback = '자세를 교정해주세요';
      } else {
        overallFeedback = '⚠ 잘못된 자세입니다';
      }
      
      feedbacks.insert(0, overallFeedback);
    }
    
    // 최대 3개의 피드백만 표시
    return feedbacks.take(3).toList();
  }
  
  /// 간단한 조건 평가 (예: "left_body_tilt < 145")
  static bool _evaluateSimpleCondition(String condition, Map<String, double> angles) {
    try {
      // 간단한 파싱: "angleKey operator value"
      final parts = condition.split(' ');
      if (parts.length < 3) return false;
      
      final angleKey = parts[0];
      final operator = parts[1];
      final valueStr = parts[2];
      
      final userAngle = angles[angleKey];
      if (userAngle == null) return false;
      
      final value = double.tryParse(valueStr);
      if (value == null) return false;
      
      switch (operator) {
        case '<':
          return userAngle < value;
        case '>':
          return userAngle > value;
        case '<=':
          return userAngle <= value;
        case '>=':
          return userAngle >= value;
        case '==':
          return (userAngle - value).abs() < 1.0; // 1도 이내면 같다고 판단
        default:
          return false;
      }
    } catch (e) {
      print('조건 평가 실패: $condition - $e');
      return false;
    }
  }

  /// 점수 레벨 문자열 반환
  static String getScoreLevel(double score) {
    if (score >= 90) return '완벽';
    if (score >= 80) return '우수';
    if (score >= 70) return '양호';
    if (score >= 60) return '보통';
    if (score >= 50) return '미흡';
    return '부족';
  }

  /// 점수에 따른 색상 코드 (UI에서 사용)
  static String getScoreColor(double score) {
    if (score >= 90) return '#4CAF50'; // Green
    if (score >= 70) return '#8BC34A'; // Light Green
    if (score >= 50) return '#FFC107'; // Amber
    return '#F44336'; // Red
  }
}


