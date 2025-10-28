import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

// 🚀 최적화 1: 비동기 데이터 스트림 관리
class PoseDataStream {
  static const String _baseUrl = 'http://10.0.2.2:5000';
  static const Duration _requestInterval = Duration(milliseconds: 500);
  
  final StreamController<Map<String, dynamic>> _poseController = 
      StreamController<Map<String, dynamic>>.broadcast();
  
  Timer? _timer;
  bool _isRunning = false;

  Stream<Map<String, dynamic>> get poseStream => _poseController.stream;

  Future<bool> startDetection() async {
    if (_isRunning) return true;
    
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/start'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        _isRunning = true;
        _startPeriodicFetch();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('서버 시작 오류: $e');
      return false;
    }
  }

  void _startPeriodicFetch() {
    _timer = Timer.periodic(_requestInterval, (_) async {
      if (!_isRunning) return;
      
      try {
        final response = await http.get(
          Uri.parse('$_baseUrl/pose'),
          headers: {'Content-Type': 'application/json'},
        );
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body) as Map<String, dynamic>;
          _poseController.add(data);
        }
      } catch (e) {
        debugPrint('포즈 데이터 가져오기 오류: $e');
      }
    });
  }

  Future<void> stopDetection() async {
    _isRunning = false;
    _timer?.cancel();
    
    try {
      await http.post(
        Uri.parse('$_baseUrl/stop'),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      debugPrint('서버 중지 오류: $e');
    }
  }

  void dispose() {
    _timer?.cancel();
    _poseController.close();
  }
}

// 🚀 최적화 2: Isolate를 사용한 백그라운드 처리
class PoseDataProcessor {
  static Future<Map<String, dynamic>> processPoseDataInIsolate(
    Map<String, dynamic> rawData,
  ) async {
    return await compute(_processPoseData, rawData);
  }

  static Map<String, dynamic> _processPoseData(Map<String, dynamic> rawData) {
    // 🚀 최적화: 데이터 검증 및 정규화를 Isolate에서 처리
    if (rawData['landmarks'] == null) {
      return {'landmarks': [], 'connections': []};
    }

    final landmarks = rawData['landmarks'] as List<dynamic>;
    final connections = rawData['connections'] as List<dynamic>?;

    // 🚀 최적화: 랜드마크 필터링 (가시성 임계값 적용)
    final filteredLandmarks = landmarks.where((landmark) {
      return landmark['visibility'] != null && landmark['visibility'] > 0.5;
    }).toList();

    return {
      'landmarks': filteredLandmarks,
      'connections': connections ?? [],
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
  }
}

// 🚀 최적화 3: 메모리 효율적인 데이터 캐싱
class PoseDataCache {
  static const int _maxCacheSize = 10;
  final List<Map<String, dynamic>> _cache = [];
  
  void addData(Map<String, dynamic> data) {
    _cache.add(data);
    
    // 🚀 최적화: 캐시 크기 제한으로 메모리 누수 방지
    if (_cache.length > _maxCacheSize) {
      _cache.removeAt(0);
    }
  }
  
  Map<String, dynamic>? getLatestData() {
    return _cache.isNotEmpty ? _cache.last : null;
  }
  
  List<Map<String, dynamic>> getRecentData(int count) {
    final startIndex = _cache.length - count;
    return startIndex >= 0 
        ? _cache.sublist(startIndex)
        : List.from(_cache);
  }
  
  void clear() {
    _cache.clear();
  }
}
