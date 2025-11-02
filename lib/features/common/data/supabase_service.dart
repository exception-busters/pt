import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/cache_service.dart';

/// 공통 Supabase 서비스 클래스
/// 중복된 데이터베이스 조회 로직을 통합 관리하고 캐싱으로 성능 최적화
class SupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;
  static final CacheService _cache = CacheService();

  /// 현재 로그인된 사용자 반환
  static User? get currentUser => _client.auth.currentUser;

  /// users 테이블에서 사용자 정보 조회 (캐싱 적용)
  static Future<Map<String, dynamic>?> getUserInfo(String userId) async {
    final cacheKey = 'user_info_$userId';
    
    // 캐시에서 먼저 확인
    final cached = _cache.get<Map<String, dynamic>>(cacheKey);
    if (cached != null) {
      print('📦 캐시에서 사용자 정보 반환: $userId');
      return cached;
    }
    
    try {
      final response = await _client
          .from('users')
          .select('user_id, email, nickname, join_date, profile_completed')
          .eq('user_id', userId)
          .maybeSingle();
      
      // 캐시에 저장 (5분 TTL)
      if (response != null) {
        _cache.set(cacheKey, response, ttl: const Duration(minutes: 5));
        print('💾 사용자 정보 캐시에 저장: $userId');
      }
      
      return response;
    } catch (e) {
      print('❌ 사용자 정보 조회 실패: $e');
      return null;
    }
  }

  /// profile_completed 상태만 조회 (최적화된 쿼리)
  static Future<bool> isProfileCompleted(String userId) async {
    try {
      print('🔍 profile_completed 확인: user_id = $userId');
      
      final response = await _client
          .from('users')
          .select('profile_completed')
          .eq('user_id', userId)
          .single();

      final isCompleted = response['profile_completed'] ?? false;
      print('📊 profile_completed 결과: $isCompleted');
      
      return isCompleted;
    } catch (e) {
      print('❌ profile_completed 확인 실패: $e');
      return false;
    }
  }

  /// profile_completed 상태 업데이트 (캐시 무효화)
  static Future<bool> updateProfileCompleted(String userId, bool completed) async {
    try {
      await _client
          .from('users')
          .update({'profile_completed': completed})
          .eq('user_id', userId);

      // 관련 캐시 무효화
      _cache.remove('user_info_$userId');
      _cache.remove('profile_completed_$userId');
      
      print('✅ profile_completed 업데이트 완료: $completed (캐시 무효화됨)');
      return true;
    } catch (e) {
      print('❌ profile_completed 업데이트 실패: $e');
      return false;
    }
  }

  /// 사용자가 users 테이블에 존재하는지 확인
  static Future<bool> userExists(String userId) async {
    try {
      final response = await _client
          .from('users')
          .select('user_id')
          .eq('user_id', userId)
          .maybeSingle();
      
      return response != null;
    } catch (e) {
      print('❌ 사용자 존재 확인 실패: $e');
      return false;
    }
  }

  /// 새 사용자를 users 테이블에 생성 (캐시 무효화)
  static Future<bool> createUser({
    required String userId,
    required String email,
    String? nickname,
    bool profileCompleted = false,
  }) async {
    try {
      await _client.from('users').insert({
        'user_id': userId,
        'email': email,
        'nickname': nickname ?? '사용자',
        'join_date': DateTime.now().toIso8601String(),
        'profile_completed': profileCompleted,
      });
      
      // 관련 캐시 무효화 (새 사용자이므로 기존 캐시가 있을 수 있음)
      _cache.remove('user_info_$userId');
      _cache.remove('profile_completed_$userId');
      _cache.remove('user_exists_$userId');
      
      print('✅ 새 사용자 생성 완료: $userId');
      return true;
    } catch (e) {
      print('❌ 사용자 생성 실패: $e');
      return false;
    }
  }

  /// 사용자 로그아웃 시 캐시 정리
  static void clearUserCache(String userId) {
    _cache.removePattern(userId);
    print('🧹 사용자 캐시 정리 완료: $userId');
  }

  /// 전체 캐시 정리
  static void clearAllCache() {
    _cache.clear();
    print('🧹 전체 캐시 정리 완료');
  }
}