import '../models/exercise_model.dart';

/// 운동 단계(Phase) 관리자
class PhaseManager {
  final ExerciseModel exercise;
  int _currentPhaseIndex = 0;
  double _phaseHoldDuration = 0.0; // 현재 단계 유지 시간 (초)
  double _readyDuration = 0.0; // 준비 시간 (2초 타이머)
  bool _isReady = false; // 준비 완료 여부

  // 점수 기반 타이머 (더 높은 점수 필요)
  double _scoreBasedTimer = 0.0; // 점수 기반 타이머
  static const double scoreThreshold = 80.0; // 점수 임계값 (65점 → 80점으로 상향)
  static const double scoreTimerRequired = 1.5; // 점수 기반 타이머 필요 시간 (초)

  static const double readyTimeRequired = 2.0; // 준비에 필요한 시간 (2초)

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
  bool get isCompleted =>
      _currentPhaseIndex >= totalPhases - 1 &&
      _phaseHoldDuration >= currentPhase.durationSec;

  /// 현재 단계의 유지 시간
  double get phaseHoldDuration => _phaseHoldDuration;

  /// 준비 시간
  double get readyDuration => _readyDuration;

  /// 준비 완료 여부
  bool get isReady => _isReady;

  /// 현재 단계의 요구 시간
  double get phaseRequiredDuration => currentPhase.durationSec;

  /// 단계 진행률 (0.0 ~ 1.0) - 준비 완료 후의 진행률
  double get phaseProgress => _isReady
      ? (_phaseHoldDuration / currentPhase.durationSec).clamp(0.0, 1.0)
      : 0.0;

  /// 준비 진행률 (0.0 ~ 1.0)
  double get readyProgress =>
      (_readyDuration / readyTimeRequired).clamp(0.0, 1.0);

  /// 단계 업데이트 (매 프레임마다 호출)
  /// - userAngles: 사용자의 현재 각도 (사용 안 함, 호환성 유지)
  /// - score: 현재 점수
  /// - deltaTime: 경과 시간 (초, 일반적으로 프레임 간격)
  ///
  /// Returns: 단계가 변경되었으면 true
  bool update(
    Map<String, double> userAngles,
    double score, {
    double deltaTime = 0.1,
  }) {
    if (isCompleted) return false;

    // 점수 기반 타이머 체크 (65점 이상 1.5초 유지) - 우선순위 1
    if (score >= scoreThreshold) {
      _scoreBasedTimer += deltaTime;

      // 1.5초 유지되면 다음 단계로
      if (_scoreBasedTimer >= scoreTimerRequired) {
        // 다음 단계로 진행 (2초 준비 타이머 리셋)
        _scoreBasedTimer = 0.0;
        return _nextPhase();
      }
    } else {
      // 65점 미만이면 타이머 리셋
      _scoreBasedTimer = 0.0;
    }

    // 점수 기반 타이머가 작동 중이면 다른 타이머는 작동하지 않음
    if (_scoreBasedTimer > 0) {
      return false; // 점수 기반 타이머 대기 중
    }

    // 점수가 65점 미만이면 다음 단계로 진행 불가 (모든 타이머 중단)
    if (score < scoreThreshold) {
      // 점수 미만일 때는 운동 타이머도 진행하지 않음
      return false;
    }

    // 준비 완료 후 2초 타이머 작동 (65점 이상일 때만)
    if (!_isReady) {
      _readyDuration += deltaTime;

      // 2초 준비 완료
      if (_readyDuration >= readyTimeRequired) {
        _isReady = true;
        print('✓ 준비 완료! 운동 시작: ${currentPhase.phaseName}');
      }
    }
    // 준비 완료 후 운동 타이머 증가 (65점 이상일 때만)
    else {
      _phaseHoldDuration += deltaTime;

      // 운동 시간 완료 시 다음 단계로 전환은 점수 기반 타이머로만 가능
      // (운동 타이머로는 다음 단계로 넘어가지 않음)
    }

    return false;
  }

  /// 다음 단계로 이동
  bool _nextPhase() {
    if (_currentPhaseIndex < totalPhases - 1) {
      _currentPhaseIndex++;
      _phaseHoldDuration = 0.0;
      _readyDuration = 0.0; // 2초 준비 타이머 리셋
      _scoreBasedTimer = 0.0; // 점수 기반 타이머 리셋
      _isReady = false; // 준비 상태 리셋 (다음 단계에서 2초 타이머 시작)
      print('✓ 단계 완료! 다음 단계: ${currentPhase.phaseName}');
      return true;
    }

    // 마지막 단계 완료
    if (_currentPhaseIndex == totalPhases - 1) {
      print('🎉 운동 완료!');
    }

    return false;
  }

  /// 단계 리셋
  void reset() {
    _currentPhaseIndex = 0;
    _phaseHoldDuration = 0.0;
    _readyDuration = 0.0;
    _scoreBasedTimer = 0.0;
    _isReady = false;
    print('운동 단계 리셋');
  }

  /// 조건 만족 여부 (점수 기반 타이머 진행 중)
  bool get isConditionMet => _scoreBasedTimer > 0;

  /// 단계 정보 문자열
  String getPhaseStatus() {
    return '${_currentPhaseIndex + 1}/$totalPhases - ${currentPhase.phaseName}';
  }

  /// 단계 설명 가져오기
  String getPhaseDescription() {
    return currentPhase.description;
  }
}
