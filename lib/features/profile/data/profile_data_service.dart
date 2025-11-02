import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/models/user_model.dart';
import '../domain/models/user_profile_model.dart';
import '../domain/models/workout_goal_model.dart';
import '../domain/models/diet_goal_model.dart';
import '../../common/services/cache_service.dart';

class ProfileDataService {
  static final SupabaseClient _client = Supabase.instance.client;
  static final CacheService _cache = CacheService();

  /// 전체 프로필 데이터 저장 (온보딩 또는 수정 시)
  static Future<bool> saveCompleteProfile({
    required String userId,
    UserProfileModel? userProfile,
    WorkoutGoalModel? workoutGoal,
    DietGoalModel? dietGoal,
    String? nickname,
  }) async {
    try {
      print('🚀 프로필 데이터 저장 시작: $userId');

      // 1. UserProfile 저장
      if (userProfile != null) {
        await _client
            .from('userprofile')
            .upsert(
              userProfile.toJson(),
              onConflict: 'user_id',
            );
        print('✅ UserProfile 저장 완료');
      }

      // 2. WorkoutGoal 저장
      if (workoutGoal != null) {
        await _client
            .from('workoutgoal')
            .upsert(
              workoutGoal.toJson(),
              onConflict: 'user_id',
            );
        print('✅ WorkoutGoal 저장 완료');
      }

      // 3. DietGoal 저장
      if (dietGoal != null) {
        await _client
            .from('dietgoal')
            .upsert(
              dietGoal.toJson(),
              onConflict: 'user_id',
            );
        print('✅ DietGoal 저장 완료');
      }

      // 4. Users 테이블 업데이트 (nickname, profile_completed)
      final updateData = <String, dynamic>{
        'profile_completed': true,
      };
      if (nickname != null) {
        updateData['nickname'] = nickname;
      }

      await _client
          .from('users')
          .update(updateData)
          .eq('user_id', userId);
      print('✅ Users 테이블 업데이트 완료');

      // 5. 캐시 무효화
      _clearUserCache(userId);

      print('🎉 전체 프로필 저장 완료: $userId');
      return true;
    } catch (e) {
      print('❌ 프로필 저장 실패: $e');
      return false;
    }
  }

  /// 로그인 시 전체 사용자 데이터 로드
  static Future<Map<String, dynamic>?> loadCompleteUserData(String userId) async {
    try {
      print('📥 사용자 데이터 로드 시작: $userId');

      // 캐시 확인
      final cacheKey = 'complete_user_data_$userId';
      final cached = _cache.get<Map<String, dynamic>>(cacheKey);
      if (cached != null) {
        print('📦 캐시에서 완전한 사용자 데이터 반환');
        return cached;
      }

      // 안전한 데이터 조회 (중복 데이터 처리)
      Map<String, dynamic>? userData;
      Map<String, dynamic>? profileData;
      Map<String, dynamic>? workoutData;
      Map<String, dynamic>? dietData;

      try {
        userData = await _client.from('users').select().eq('user_id', userId).maybeSingle();
      } catch (e) {
        print('❌ Users 데이터 조회 실패: $e');
      }

      try {
        final workoutResults = await _client.from('workoutgoal').select().eq('user_id', userId);
        workoutData = workoutResults.isNotEmpty ? workoutResults.first : null;
      } catch (e) {
        print('❌ WorkoutGoal 데이터 조회 실패: $e');
      }

      try {
        final dietResults = await _client.from('dietgoal').select().eq('user_id', userId);
        dietData = dietResults.isNotEmpty ? dietResults.first : null;
      } catch (e) {
        print('❌ DietGoal 데이터 조회 실패: $e');
      }

      try {
        final profileResults = await _client.from('userprofile').select().eq('user_id', userId);
        profileData = profileResults.isNotEmpty ? profileResults.first : null;
      } catch (e) {
        print('❌ UserProfile 데이터 조회 실패: $e');
      }

      if (userData == null) {
        print('❌ 사용자 데이터를 찾을 수 없음: $userId');
        return null;
      }

      // 모델 객체로 변환
      final result = {
        'user': UserModel.fromJson(userData),
        'profile': profileData != null ? UserProfileModel.fromJson(profileData) : null,
        'workout': workoutData != null ? WorkoutGoalModel.fromJson(workoutData) : null,
        'diet': dietData != null ? DietGoalModel.fromJson(dietData) : null,
      };

      // 캐시에 저장 (10분 TTL)
      _cache.set(cacheKey, result, ttl: const Duration(minutes: 10));

      print('✅ 사용자 데이터 로드 완료');
      print('📊 User: ${result['user'] != null ? '✓' : '✗'}');
      print('📊 Profile: ${result['profile'] != null ? '✓' : '✗'}');
      print('📊 Workout: ${result['workout'] != null ? '✓' : '✗'}');
      print('📊 Diet: ${result['diet'] != null ? '✓' : '✗'}');

      return result;
    } catch (e) {
      print('❌ 사용자 데이터 로드 실패: $e');
      return null;
    }
  }

  /// 개별 프로필 데이터 업데이트
  static Future<bool> updateUserProfile(UserProfileModel profile) async {
    try {
      await _client
          .from('userprofile')
          .upsert(
            profile.toJson(),
            onConflict: 'user_id',
          );
      _clearUserCache(profile.userId);
      print('✅ UserProfile 업데이트 완료 (user_id: ${profile.userId})');
      return true;
    } catch (e) {
      print('❌ UserProfile 업데이트 실패: $e');
      return false;
    }
  }

  /// 개별 운동 목표 업데이트
  static Future<bool> updateWorkoutGoal(WorkoutGoalModel workoutGoal) async {
    try {
      // 1. 기존 데이터 확인
      final existing = await _client
          .from('workoutgoal')
          .select()
          .eq('user_id', workoutGoal.userId);

      if (existing.isNotEmpty) {
        // 2. 기존 데이터가 있으면 업데이트
        await _client
            .from('workoutgoal')
            .update(workoutGoal.toJson())
            .eq('user_id', workoutGoal.userId);
        print('✅ WorkoutGoal 업데이트 완료 (user_id: ${workoutGoal.userId})');
      } else {
        // 3. 기존 데이터가 없으면 삽입
        await _client
            .from('workoutgoal')
            .insert(workoutGoal.toJson());
        print('✅ WorkoutGoal 삽입 완료 (user_id: ${workoutGoal.userId})');
      }

      _clearUserCache(workoutGoal.userId);
      return true;
    } catch (e) {
      print('❌ WorkoutGoal 업데이트 실패: $e');
      return false;
    }
  }

  /// 개별 식단 목표 업데이트
  static Future<bool> updateDietGoal(DietGoalModel dietGoal) async {
    try {
      // 1. 기존 데이터 확인
      final existing = await _client
          .from('dietgoal')
          .select()
          .eq('user_id', dietGoal.userId);

      if (existing.isNotEmpty) {
        // 2. 기존 데이터가 있으면 업데이트
        await _client
            .from('dietgoal')
            .update(dietGoal.toJson())
            .eq('user_id', dietGoal.userId);
        print('✅ DietGoal 업데이트 완료 (user_id: ${dietGoal.userId})');
      } else {
        // 3. 기존 데이터가 없으면 삽입
        await _client
            .from('dietgoal')
            .insert(dietGoal.toJson());
        print('✅ DietGoal 삽입 완료 (user_id: ${dietGoal.userId})');
      }

      _clearUserCache(dietGoal.userId);
      return true;
    } catch (e) {
      print('❌ DietGoal 업데이트 실패: $e');
      return false;
    }
  }

  /// 닉네임 업데이트
  static Future<bool> updateNickname(String userId, String nickname) async {
    try {
      await _client
          .from('users')
          .update({'nickname': nickname})
          .eq('user_id', userId);
      _clearUserCache(userId);
      print('✅ 닉네임 업데이트 완료: $nickname');
      return true;
    } catch (e) {
      print('❌ 닉네임 업데이트 실패: $e');
      return false;
    }
  }

  /// 사용자별 캐시 정리
  static void _clearUserCache(String userId) {
    _cache.removePattern(userId);
  }

  /// 전체 캐시 정리
  static void clearAllCache() {
    _cache.clear();
  }
}