import 'package:flutter/material.dart';
import 'dart:async';

// 🚀 최적화 9: 안전한 위젯 생명주기 관리
mixin SafeWidgetLifecycle<T extends StatefulWidget> on State<T> {
  bool _isDisposed = false;
  final List<StreamSubscription> _subscriptions = [];
  final List<Timer> _timers = [];

  // 🚀 최적화: 안전한 setState (dispose 후 호출 방지)
  void safeSetState(VoidCallback fn) {
    if (!_isDisposed && mounted) {
      setState(fn);
    }
  }

  // 🚀 최적화: 안전한 구독 등록
  void registerSubscription(StreamSubscription subscription) {
    if (!_isDisposed) {
      _subscriptions.add(subscription);
    } else {
      subscription.cancel();
    }
  }

  // 🚀 최적화: 안전한 타이머 등록
  void registerTimer(Timer timer) {
    if (!_isDisposed) {
      _timers.add(timer);
    } else {
      timer.cancel();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    
    // 🚀 최적화: 모든 구독 해제
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();

    // 🚀 최적화: 모든 타이머 해제
    for (final timer in _timers) {
      timer.cancel();
    }
    _timers.clear();

    super.dispose();
  }
}

// 🚀 최적화 10: 메모리 효율적인 위젯 빌더
class OptimizedWidgetBuilder {
  // 🚀 최적화: 조건부 위젯 빌딩
  static Widget conditional({
    required bool condition,
    required Widget Function() builder,
    Widget? fallback,
  }) {
    return condition ? builder() : (fallback ?? const SizedBox.shrink());
  }

  // 🚀 최적화: 지연 로딩 위젯
  static Widget lazy({
    required Future<Widget> Function() futureBuilder,
    Widget? loadingWidget,
    Widget? errorWidget,
  }) {
    return FutureBuilder<Widget>(
      future: futureBuilder(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return loadingWidget ?? const CircularProgressIndicator();
        }
        
        if (snapshot.hasError) {
          return errorWidget ?? Text('Error: ${snapshot.error}');
        }
        
        return snapshot.data ?? const SizedBox.shrink();
      },
    );
  }

  // 🚀 최적화: 메모리 효율적인 리스트 빌더
  static Widget optimizedList({
    required int itemCount,
    required Widget Function(BuildContext, int) itemBuilder,
    ScrollController? controller,
    EdgeInsetsGeometry? padding,
  }) {
    return ListView.builder(
      controller: controller,
      padding: padding,
      itemCount: itemCount,
      itemBuilder: itemBuilder,
      // 🚀 최적화: 뷰포트 외부 위젯 재사용
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: true,
      addSemanticIndexes: false,
    );
  }
}

// 🚀 최적화 11: 이미지 메모리 관리
class ImageMemoryManager {
  static const int _maxCacheSize = 50;
  static final Map<String, Image> _imageCache = {};

  static Image? getCachedImage(String key) {
    return _imageCache[key];
  }

  static void cacheImage(String key, Image image) {
    if (_imageCache.length >= _maxCacheSize) {
      // 🚀 최적화: LRU 방식으로 오래된 이미지 제거
      final oldestKey = _imageCache.keys.first;
      _imageCache.remove(oldestKey);
    }
    _imageCache[key] = image;
  }

  static void clearCache() {
    _imageCache.clear();
  }

  static int get cacheSize => _imageCache.length;
}

// 🚀 최적화 12: 디버그 정보 수집
class PerformanceMonitor {
  static final List<PerformanceMetric> _metrics = [];
  static const int _maxMetrics = 100;

  static void recordMetric(String name, Duration duration) {
    _metrics.add(PerformanceMetric(name, duration, DateTime.now()));
    
    if (_metrics.length > _maxMetrics) {
      _metrics.removeAt(0);
    }
  }

  static List<PerformanceMetric> getMetrics() {
    return List.from(_metrics);
  }

  static void clearMetrics() {
    _metrics.clear();
  }

  static Duration getAverageDuration(String name) {
    final relevantMetrics = _metrics.where((m) => m.name == name).toList();
    if (relevantMetrics.isEmpty) return Duration.zero;
    
    final totalDuration = relevantMetrics.fold<Duration>(
      Duration.zero,
      (sum, metric) => sum + metric.duration,
    );
    
    return Duration(
      microseconds: totalDuration.inMicroseconds ~/ relevantMetrics.length,
    );
  }
}

class PerformanceMetric {
  final String name;
  final Duration duration;
  final DateTime timestamp;

  PerformanceMetric(this.name, this.duration, this.timestamp);
}

