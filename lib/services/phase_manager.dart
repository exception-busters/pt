import '../models/exercise_model.dart';

/// 운동 단계(Phase) 관리자
class PhaseManager {
  final ExerciseModel exercise;
  int _currentPhaseIndex = 0;
  double _phaseHoldDuration = 0.0; // 현재 단계 유지 시간 (초)
  double _readyDuration = 0.0; // 준비 시간 (자세 유지 시간)
  bool _isPhaseConditionMet = false;
  bool _isReady = false; // 준비 완료 여부
  
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
  bool get isCompleted => _currentPhaseIndex >= totalPhases - 1 && _phaseHoldDuration >= currentPhase.durationSec;

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
  double get readyProgress => (_readyDuration / readyTimeRequired).clamp(0.0, 1.0);

  /// 단계 업데이트 (매 프레임마다 호출)
  /// - userAngles: 사용자의 현재 각도
  /// - score: 현재 점수
  /// - deltaTime: 경과 시간 (초, 일반적으로 프레임 간격)
  /// 
  /// Returns: 단계가 변경되었으면 true
  bool update(Map<String, double> userAngles, double score, {double deltaTime = 0.1}) {
    if (isCompleted) return false;

    // 1. 현재 단계의 조건 체크
    final conditionMet = _checkPhaseCondition(userAngles, score);
    
    _isPhaseConditionMet = conditionMet;
    
    if (conditionMet) {
      // 2-1. 준비 단계: 2초 동안 자세 유지
      if (!_isReady) {
        _readyDuration += deltaTime;
        
        // 준비 완료 (2초 유지)
        if (_readyDuration >= readyTimeRequired) {
          _isReady = true;
          print('✓ 준비 완료! 운동 시작: ${currentPhase.phaseName}');
        }
      } 
      // 2-2. 운동 단계: 실제 운동 타이머 증가
      else {
        _phaseHoldDuration += deltaTime;
      }
    } else {
      // 조건 불만족 시
      if (!_isReady) {
        // 준비 중이면 준비 타이머 감소
        _readyDuration = (_readyDuration - deltaTime * 0.5).clamp(0.0, double.infinity);
      } else {
        // 운동 중이면 운동 타이머 천천히 감소
        _phaseHoldDuration = (_phaseHoldDuration - deltaTime * 0.3).clamp(0.0, double.infinity);
      }
    }
    
    // 3. 준비 완료 후 요구 시간을 채웠으면 다음 단계로
    if (_isReady && _phaseHoldDuration >= currentPhase.durationSec) {
      return _nextPhase();
    }
    
    return false;
  }

  /// 다음 단계로 이동
  bool _nextPhase() {
    if (_currentPhaseIndex < totalPhases - 1) {
      _currentPhaseIndex++;
      _phaseHoldDuration = 0.0;
      _readyDuration = 0.0;
      _isPhaseConditionMet = false;
      _isReady = false;
      print('✓ 단계 완료! 다음 단계: ${currentPhase.phaseName}');
      return true;
    }
    
    // 마지막 단계 완료
    if (_currentPhaseIndex == totalPhases - 1) {
      print('🎉 운동 완료!');
    }
    
    return false;
  }

  /// 단계 조건 체크 (현실적인 기준)
  bool _checkPhaseCondition(Map<String, double> userAngles, double score) {
    final phase = currentPhase;
    
    // 기본 조건: 점수가 70점 이상이면 자세가 올바름 (현실적)
    if (score < 70) return false;

    // 무릎 체크 (선택적, 너무 엄격하지 않게)
    if (!_checkKneesStable(userAngles)) {
      // 무릎이 약간 구부러져도 점수가 높으면 통과
      if (score < 75) return false;
    }

    // 단계별 특정 조건 체크
    switch (phase.phaseId) {
      case 1: // 시작 자세
        return _checkStartPose(userAngles);
      
      case 2: // 좌측 굽히기
        return _checkLeftBend(userAngles);
      
      case 3: // 중앙 복귀
        return _checkCenterReturn(userAngles);
      
      case 4: // 우측 굽히기
        return _checkRightBend(userAngles);
      
      case 5: // 완료
        return _checkStartPose(userAngles); // 다시 시작 자세
      
      default:
        return score >= 70; // 기본: 점수만 체크
    }
  }

  /// 무릎 안정성 체크 (양쪽 무릎이 대체로 펴져 있어야 함)
  bool _checkKneesStable(Map<String, double> userAngles) {
    final leftKnee = userAngles['left_knee_angle'];
    final rightKnee = userAngles['right_knee_angle'];
    
    // 양쪽 무릎 모두 165도 이상 (자연스럽게 펴진 상태)
    if (leftKnee != null && rightKnee != null) {
      return leftKnee >= 165 && rightKnee >= 165;
    }
    
    return false;
  }

  /// 시작 자세 체크 (서 있는 중립 자세) - 현실적인 기준
  bool _checkStartPose(Map<String, double> userAngles) {
    final leftTilt = userAngles['left_body_tilt'];
    final rightTilt = userAngles['right_body_tilt'];
    
    if (leftTilt == null || rightTilt == null) return false;
    
    // 1. 좌우 상체 기울기가 165도 이상 (자연스럽게 곧게 선 상태)
    final avgTilt = (leftTilt + rightTilt) / 2;
    if (avgTilt < 165) return false;
    
    // 2. 좌우 기울기 차이가 10도 이내 (균형있게)
    if ((leftTilt - rightTilt).abs() > 10) return false;
    
    return true;
  }

  /// 좌측 굽히기 체크 - 현실적인 기준
  bool _checkLeftBend(Map<String, double> userAngles) {
    final leftTilt = userAngles['left_body_tilt'];
    final rightTilt = userAngles['right_body_tilt'];
    
    if (leftTilt == null || rightTilt == null) return false;
    
    // 1. 좌측 기울기가 140~170도 (적절한 기울기)
    if (leftTilt < 140 || leftTilt > 170) return false;
    
    // 2. 우측은 비교적 직선 유지 (165도 이상)
    if (rightTilt < 165) return false;
    
    // 3. 좌우 기울기 차이가 있어야 함 (최소 8도 이상)
    if ((rightTilt - leftTilt) < 8) return false;
    
    return true;
  }

  /// 중앙 복귀 체크
  bool _checkCenterReturn(Map<String, double> userAngles) {
    return _checkStartPose(userAngles);
  }

  /// 우측 굽히기 체크 - 현실적인 기준
  bool _checkRightBend(Map<String, double> userAngles) {
    final leftTilt = userAngles['left_body_tilt'];
    final rightTilt = userAngles['right_body_tilt'];
    
    if (leftTilt == null || rightTilt == null) return false;
    
    // 1. 우측 기울기가 140~170도 (적절한 기울기)
    if (rightTilt < 140 || rightTilt > 170) return false;
    
    // 2. 좌측은 비교적 직선 유지 (165도 이상)
    if (leftTilt < 165) return false;
    
    // 3. 좌우 기울기 차이가 있어야 함 (최소 8도 이상)
    if ((leftTilt - rightTilt) < 8) return false;
    
    return true;
  }

  /// 단계 리셋
  void reset() {
    _currentPhaseIndex = 0;
    _phaseHoldDuration = 0.0;
    _readyDuration = 0.0;
    _isPhaseConditionMet = false;
    _isReady = false;
    print('운동 단계 리셋');
  }

  /// 조건 만족 여부
  bool get isConditionMet => _isPhaseConditionMet;

  /// 단계 정보 문자열
  String getPhaseStatus() {
    return '${_currentPhaseIndex + 1}/${totalPhases} - ${currentPhase.phaseName}';
  }

  /// 단계 설명 가져오기
  String getPhaseDescription() {
    return currentPhase.description;
  }
}

