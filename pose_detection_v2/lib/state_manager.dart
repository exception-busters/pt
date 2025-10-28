import 'package:flutter/material.dart';
import 'dart:async';

// 🚀 최적화 6: 상태 관리 개선 - ValueNotifier 사용
class PoseDetectionState extends ChangeNotifier {
  // 🚀 최적화: 개별 상태 변수로 세분화
  final ValueNotifier<bool> _isInitialized = ValueNotifier(false);
  final ValueNotifier<bool> _isServerRunning = ValueNotifier(false);
  final ValueNotifier<String> _serverStatus = ValueNotifier("연결 중...");
  final ValueNotifier<Map<String, dynamic>?> _poseData = ValueNotifier(null);
  final ValueNotifier<int> _poseCount = ValueNotifier(0);

  // Getters
  bool get isInitialized => _isInitialized.value;
  bool get isServerRunning => _isServerRunning.value;
  String get serverStatus => _serverStatus.value;
  Map<String, dynamic>? get poseData => _poseData.value;
  int get poseCount => _poseCount.value;

  // ValueNotifier 접근자
  ValueNotifier<bool> get isInitializedNotifier => _isInitialized;
  ValueNotifier<bool> get isServerRunningNotifier => _isServerRunning;
  ValueNotifier<String> get serverStatusNotifier => _serverStatus;
  ValueNotifier<Map<String, dynamic>?> get poseDataNotifier => _poseData;
  ValueNotifier<int> get poseCountNotifier => _poseCount;

  // 🚀 최적화: 상태 업데이트 메서드들
  void setInitialized(bool value) {
    if (_isInitialized.value != value) {
      _isInitialized.value = value;
      notifyListeners();
    }
  }

  void setServerRunning(bool value) {
    if (_isServerRunning.value != value) {
      _isServerRunning.value = value;
      notifyListeners();
    }
  }

  void setServerStatus(String status) {
    if (_serverStatus.value != status) {
      _serverStatus.value = status;
      notifyListeners();
    }
  }

  void setPoseData(Map<String, dynamic>? data) {
    _poseData.value = data;
    _poseCount.value = data?['landmarks']?.length ?? 0;
    notifyListeners();
  }

  @override
  void dispose() {
    // 🚀 최적화: 메모리 누수 방지를 위한 리소스 해제
    _isInitialized.dispose();
    _isServerRunning.dispose();
    _serverStatus.dispose();
    _poseData.dispose();
    _poseCount.dispose();
    super.dispose();
  }
}

// 🚀 최적화 7: 리소스 관리 클래스
class ResourceManager {
  static final List<StreamSubscription> _subscriptions = [];
  static final List<Timer> _timers = [];
  static final List<ChangeNotifier> _notifiers = [];

  // 🚀 최적화: 리소스 등록 및 자동 해제
  static void registerSubscription(StreamSubscription subscription) {
    _subscriptions.add(subscription);
  }

  static void registerTimer(Timer timer) {
    _timers.add(timer);
  }

  static void registerNotifier(ChangeNotifier notifier) {
    _notifiers.add(notifier);
  }

  // 🚀 최적화: 모든 리소스 일괄 해제
  static void disposeAll() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();

    for (final timer in _timers) {
      timer.cancel();
    }
    _timers.clear();

    for (final notifier in _notifiers) {
      notifier.dispose();
    }
    _notifiers.clear();
  }

  // 🚀 최적화: 개별 리소스 해제
  static void disposeSubscription(StreamSubscription subscription) {
    subscription.cancel();
    _subscriptions.remove(subscription);
  }

  static void disposeTimer(Timer timer) {
    timer.cancel();
    _timers.remove(timer);
  }

  static void disposeNotifier(ChangeNotifier notifier) {
    notifier.dispose();
    _notifiers.remove(notifier);
  }
}

// 🚀 최적화 8: 메모리 모니터링
class MemoryMonitor {
  static const int _maxMemoryUsageMB = 100;
  static int _currentMemoryUsageMB = 0;

  static void updateMemoryUsage(int usageMB) {
    _currentMemoryUsageMB = usageMB;
    
    if (_currentMemoryUsageMB > _maxMemoryUsageMB) {
      _triggerMemoryCleanup();
    }
  }

  static void _triggerMemoryCleanup() {
    // 🚀 최적화: 메모리 사용량이 임계값을 초과하면 정리 작업 수행
    debugPrint('메모리 사용량 초과: ${_currentMemoryUsageMB}MB');
    
    // 가비지 컬렉션 강제 실행
    // 실제 구현에서는 더 구체적인 정리 작업 수행
  }

  static int get currentUsage => _currentMemoryUsageMB;
  static bool get isMemoryHigh => _currentMemoryUsageMB > _maxMemoryUsageMB;
}
