import 'dart:collection';

/// 각도 데이터 스무딩 서비스
/// 인간의 미세한 떨림을 보정하여 안정적인 각도 값을 제공
class AngleSmoother {
  final int _windowSize;
  final Map<String, Queue<double>> _angleBuffers = {};

  AngleSmoother({int windowSize = 7}) : _windowSize = windowSize;  // 기본값 증가 (5 -> 7)

  /// 각도 값을 스무딩 처리
  /// [angleKey]: 각도 식별자 (예: 'left_body_tilt')
  /// [angle]: 현재 측정된 각도 값
  /// 반환: 스무딩 처리된 각도 값
  double smoothAngle(String angleKey, double angle) {
    // 버퍼가 없으면 생성
    if (!_angleBuffers.containsKey(angleKey)) {
      _angleBuffers[angleKey] = Queue<double>();
    }

    final buffer = _angleBuffers[angleKey]!;

    // 새로운 각도 추가
    buffer.addLast(angle);

    // 윈도우 크기를 초과하면 오래된 값 제거
    if (buffer.length > _windowSize) {
      buffer.removeFirst();
    }

    // 이동 평균 계산
    if (buffer.isEmpty) {
      return angle;
    }

    double sum = 0;
    for (var value in buffer) {
      sum += value;
    }

    return sum / buffer.length;
  }

  /// 가중 이동 평균 (최근 값에 더 높은 가중치)
  /// 더 반응성이 좋은 스무딩
  double smoothAngleWeighted(String angleKey, double angle) {
    // 버퍼가 없으면 생성
    if (!_angleBuffers.containsKey(angleKey)) {
      _angleBuffers[angleKey] = Queue<double>();
    }

    final buffer = _angleBuffers[angleKey]!;

    // 새로운 각도 추가
    buffer.addLast(angle);

    // 윈도우 크기를 초과하면 오래된 값 제거
    if (buffer.length > _windowSize) {
      buffer.removeFirst();
    }

    if (buffer.isEmpty) {
      return angle;
    }

    // 가중치 생성 (최근 값일수록 높은 가중치)
    double weightedSum = 0;
    double totalWeight = 0;
    int index = 0;

    for (var value in buffer) {
      final weight = (index + 1).toDouble(); // 1, 2, 3, 4, 5
      weightedSum += value * weight;
      totalWeight += weight;
      index++;
    }

    return weightedSum / totalWeight;
  }

  /// 지수 이동 평균 (Exponential Moving Average)
  /// alpha가 클수록 최근 값에 더 민감
  double smoothAngleExponential(
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

  /// 미디안 필터 (이상치 제거에 효과적)
  double smoothAngleMedian(String angleKey, double angle) {
    // 버퍼가 없으면 생성
    if (!_angleBuffers.containsKey(angleKey)) {
      _angleBuffers[angleKey] = Queue<double>();
    }

    final buffer = _angleBuffers[angleKey]!;

    // 새로운 각도 추가
    buffer.addLast(angle);

    // 윈도우 크기를 초과하면 오래된 값 제거
    if (buffer.length > _windowSize) {
      buffer.removeFirst();
    }

    if (buffer.isEmpty) {
      return angle;
    }

    // 미디안 계산
    final sorted = List<double>.from(buffer)..sort();
    final middle = sorted.length ~/ 2;

    if (sorted.length % 2 == 0) {
      return (sorted[middle - 1] + sorted[middle]) / 2;
    } else {
      return sorted[middle];
    }
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
      return smoothAngleExponential(angleKey, angle, alpha: alpha);
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

  /// 현재 버퍼 상태 확인 (디버깅용)
  Map<String, List<double>> getBufferState() {
    return _angleBuffers.map(
      (key, queue) => MapEntry(key, List<double>.from(queue)),
    );
  }
}

/// 스무딩 타입 열거형
enum SmoothingType {
  /// 단순 이동 평균
  simple,

  /// 가중 이동 평균
  weighted,

  /// 지수 이동 평균
  exponential,

  /// 미디안 필터
  median,

  /// 적응형 필터
  adaptive,
}

/// 각도 스무더 팩토리
class AngleSmootherFactory {
  static double applySmoothing(
    AngleSmoother smoother,
    String angleKey,
    double angle,
    SmoothingType type, {
    double? alpha,
    double? threshold,
  }) {
    switch (type) {
      case SmoothingType.simple:
        return smoother.smoothAngle(angleKey, angle);

      case SmoothingType.weighted:
        return smoother.smoothAngleWeighted(angleKey, angle);

      case SmoothingType.exponential:
        return smoother.smoothAngleExponential(
          angleKey,
          angle,
          alpha: alpha ?? 0.3,
        );

      case SmoothingType.median:
        return smoother.smoothAngleMedian(angleKey, angle);

      case SmoothingType.adaptive:
        return smoother.smoothAngleAdaptive(
          angleKey,
          angle,
          threshold: threshold ?? 10.0,
        );
    }
  }
}

