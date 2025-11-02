import 'dart:async';

/// 메모리 캐시 서비스
/// 자주 사용되는 데이터를 메모리에 캐시하여 성능 최적화
class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  final Map<String, _CacheItem> _cache = {};
  final Map<String, Timer> _timers = {};

  /// 캐시에 데이터 저장
  void set<T>(String key, T value, {Duration? ttl}) {
    // 기존 타이머 취소
    _timers[key]?.cancel();
    
    // 캐시 저장
    _cache[key] = _CacheItem(value, DateTime.now());
    
    // TTL 설정 시 자동 삭제 타이머 설정
    if (ttl != null) {
      _timers[key] = Timer(ttl, () {
        _cache.remove(key);
        _timers.remove(key);
      });
    }
  }

  /// 캐시에서 데이터 조회
  T? get<T>(String key) {
    final item = _cache[key];
    if (item == null) return null;
    
    return item.value as T?;
  }

  /// 캐시에서 데이터 제거
  void remove(String key) {
    _timers[key]?.cancel();
    _timers.remove(key);
    _cache.remove(key);
  }

  /// 특정 패턴의 키들 제거
  void removePattern(String pattern) {
    final keysToRemove = _cache.keys.where((key) => key.contains(pattern)).toList();
    for (final key in keysToRemove) {
      remove(key);
    }
  }

  /// 전체 캐시 클리어
  void clear() {
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
    _cache.clear();
  }

  /// 캐시 크기 반환
  int get size => _cache.length;

  /// 캐시에 키가 존재하는지 확인
  bool containsKey(String key) => _cache.containsKey(key);
}

class _CacheItem {
  final dynamic value;
  final DateTime createdAt;

  _CacheItem(this.value, this.createdAt);
}