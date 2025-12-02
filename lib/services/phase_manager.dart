import '../models/exercise_model.dart';

/// 운동 단계(Phase) 관리자
class PhaseManager {
  final ExerciseModel exercise;
  int _currentPhaseIndex = 0;
  bool _isCompleted = false;

  // 점수 임계값
  static const double scoreThreshold = 70.0;

  PhaseManager(this.exercise);

  /// 현재 단계 가져오기
  MotionPhase get currentPhase => exercise.motionPhases[_currentPhaseIndex];

  /// 현재 단계 인덱스
  int get currentPhaseIndex => _currentPhaseIndex;

  /// 전체 단계 수
  int get totalPhases => exercise.motionPhases.length;

  /// 진행률 (0.0 ~ 1.0)
  double get progress => (_currentPhaseIndex + 1) / totalPhases;

  /// 운동 완료 여부
  bool get isCompleted => _isCompleted;

  /// 준비 완료 여부 (호환성 유지 - 항상 true)
  bool get isReady => true;

  /// 준비 시간 (호환성 유지)
  double get readyDuration => 0.0;

  /// 단계 업데이트 (매 프레임마다 호출)
  /// Returns: 단계가 변경되었으면 true
  bool update(
    Map<String, double> userAngles,
    double score, {
    double deltaTime = 0.1,
  }) {
    if (_isCompleted) return false;

    // 점수 충족 시 즉시 다음 페이즈로
    if (score >= scoreThreshold) {
      return _nextPhase();
    }

    return false;
  }

  /// 다음 단계로 이동
  bool _nextPhase() {
    if (_currentPhaseIndex < totalPhases - 1) {
      _currentPhaseIndex++;
      print('✓ 다음 단계: ${currentPhase.phaseName}');
      return true;
    }

    // 마지막 단계에서 점수 충족 시 완료
    if (_currentPhaseIndex == totalPhases - 1) {
      _isCompleted = true;
      print('🎉 운동 완료!');
      return true;
    }

    return false;
  }

  /// 단계 리셋
  void reset() {
    _currentPhaseIndex = 0;
    _isCompleted = false;
    print('운동 단계 리셋');
  }

  /// 조건 만족 여부
  bool get isConditionMet => false;

  /// 단계 정보 문자열
  String getPhaseStatus() {
    return '${_currentPhaseIndex + 1}/$totalPhases - ${currentPhase.phaseName}';
  }

  /// 단계 설명 가져오기
  String getPhaseDescription() {
    return currentPhase.description;
  }

  /// 현재 페이즈의 각도 기준 가져오기
  Map<String, KeyAngle> getCurrentPhaseAngles() {
    final phaseAngles = currentPhase.phaseAngles;
    if (phaseAngles != null && phaseAngles.isNotEmpty) {
      return phaseAngles;
    }
    return exercise.keyAngles;
  }

  /// 개발자 전용: 다음 단계로 강제 이동
  bool forceNextPhase() {
    return _nextPhase();
  }

  /// 점수 임계값 (디버그용)
  double get currentScoreThreshold => scoreThreshold;

  /// 디버그 정보 문자열
  String getDebugInfo(double currentScore) {
    final buffer = StringBuffer();
    buffer.writeln('📊 Phase ${_currentPhaseIndex + 1}/$totalPhases: ${currentPhase.phaseName}');
    buffer.writeln('🎯 점수: ${currentScore.toStringAsFixed(0)} (필요: $scoreThreshold)');

    if (_isCompleted) {
      buffer.writeln('🎉 운동 완료!');
    } else if (currentScore >= scoreThreshold) {
      buffer.writeln('✅ 통과!');
    } else {
      buffer.writeln('⚠️ 자세 교정 필요');
    }

    return buffer.toString().trim();
  }
}
