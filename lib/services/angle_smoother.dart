import 'dart:collection';

/// 각도 데이터 스무딩 서비스
/// 인간의 미세한 떨림을 보정하여 안정적인 각도 값을 제공
class AngleSmoother {
  final int _windowSize;
  final Map<String, Queue<double>> _angleBuffers = {};

  AngleSmoother({int windowSize = 7}) : _windowSize = windowSize;  // 기본값 증가 (5 -> 7)

  /// 지수 이동 평균 (Exponential Moving Average) - 내부 전용
  /// alpha가 클수록 최근 값에 더 민감
  double _smoothAngleExponential(
    String angleKey,
    double angle, {
    double alpha = 0.3,
  }) {
    if (!_angleBuffers.containsKey(angleKey) ||
        _angleBuffers[angleKey]!.isEmpty) {
      _angleBuffers[angleKey] = Queue<double>()..add(angle);
      return angle;
    }

    final lastSmoothed = _angleBuffers[angleKey]!.last;
    final smoothed = alpha * angle + (1 - alpha) * lastSmoothed;

    // 최대 1개의 값만 유지 (EMA는 이전 평균값만 필요)
    _angleBuffers[angleKey]!.clear();
    _angleBuffers[angleKey]!.add(smoothed);

    return smoothed;
  }

  /// 적응형 필터 (변화가 클 때는 빠르게 반응, 작을 때는 스무딩)
  double smoothAngleAdaptive(
    String angleKey,
    double angle, {
    double threshold = 5.0,  // 임계값 낮춤 (10.0 -> 5.0)
  }) {
    // 버퍼가 없으면 생성
    if (!_angleBuffers.containsKey(angleKey)) {
      _angleBuffers[angleKey] = Queue<double>();
    }

    final buffer = _angleBuffers[angleKey]!;

    // 이전 값이 있으면 변화량 계산
    if (buffer.isNotEmpty) {
      final lastValue = buffer.last;
      final change = (angle - lastValue).abs();

      // 변화가 크면 즉시 반응 (alpha = 0.6) - 0.7에서 낮춤
      // 변화가 작으면 스무딩 (alpha = 0.15) - 0.2에서 낮춤
      final alpha = change > threshold ? 0.6 : 0.15;
      return _smoothAngleExponential(angleKey, angle, alpha: alpha);
    }

    // 첫 값은 그대로 반환
    buffer.add(angle);
    return angle;
  }

  /// 특정 각도의 버퍼 초기화
  void reset(String angleKey) {
    _angleBuffers.remove(angleKey);
  }

  /// 모든 버퍼 초기화
  void resetAll() {
    _angleBuffers.clear();
  }
}

