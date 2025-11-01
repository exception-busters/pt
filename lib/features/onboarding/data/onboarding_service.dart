import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/models/onboarding_data.dart';

class OnboardingService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<bool> saveUserProfile(OnboardingData data) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        print('❌ 사용자가 로그인되지 않았습니다.');
        return false;
      }

      print('💾 온보딩 데이터 저장 시작: ${currentUser.id}');
      print('📊 저장할 데이터: ${data.toJson()}');

      // 1. public_users 테이블에 온보딩 데이터 저장/업데이트
      try {
        // 먼저 기존 데이터가 있는지 확인
        final existingData = await _supabase
            .from('public_users')
            .select('id')
            .eq('id', currentUser.id)
            .maybeSingle();

        final profileData = {
          'id': currentUser.id,
          'gender': data.gender?.name,
          'age': data.age,
          'weight': data.weight,
          'height': data.height,
          'workout_goal': data.workoutGoal?.name,
          'workout_level': data.workoutLevel?.name,
          'updated_at': DateTime.now().toIso8601String(),
        };

        if (existingData != null) {
          // 기존 데이터 업데이트
          print('🔄 기존 프로필 데이터 업데이트');
          await _supabase
              .from('public_users')
              .update(profileData)
              .eq('id', currentUser.id);
        } else {
          // 새 데이터 삽입
          print('➕ 새 프로필 데이터 삽입');
          profileData['created_at'] = DateTime.now().toIso8601String();
          await _supabase
              .from('public_users')
              .insert(profileData);
        }
        
        print('✅ public_users 테이블에 온보딩 데이터 저장 완료');
      } catch (e) {
        print('❌ public_users 테이블 저장 실패: $e');
        // public_users 저장 실패해도 계속 진행 (profile_completed는 업데이트)
      }

      // 2. users 테이블의 profile_completed를 true로 업데이트 (온보딩 완료 표시)
      print('🔄 users 테이블 profile_completed 업데이트 시도: user_id = ${currentUser.id}');
      
      final updateResult = await _supabase
          .from('users')
          .update({'profile_completed': true})
          .eq('user_id', currentUser.id)
          .select();

      print('📊 users 테이블 업데이트 결과: $updateResult');
      print('✅ 온보딩 완료! profile_completed = true로 업데이트 완료');
      return true;
    } catch (e) {
      print('❌ 온보딩 데이터 저장 실패: $e');
      return false;
    }
  }

  Future<OnboardingData?> getUserProfile() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        return null;
      }

      final response = await _supabase
          .from('public_users')
          .select()
          .eq('id', currentUser.id)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return OnboardingData(
        gender: response['gender'] != null 
            ? Gender.values.firstWhere((g) => g.name == response['gender'])
            : null,
        age: response['age'],
        weight: response['weight']?.toDouble(),
        height: response['height']?.toDouble(),
        workoutGoal: response['workout_goal'] != null
            ? WorkoutGoal.values.firstWhere((g) => g.name == response['workout_goal'])
            : null,
        workoutLevel: response['workout_level'] != null
            ? WorkoutLevel.values.firstWhere((l) => l.name == response['workout_level'])
            : null,
      );
    } catch (e) {
      print('❌ 사용자 프로필 조회 실패: $e');
      return null;
    }
  }

  Future<bool> isOnboardingCompleted() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        return false;
      }

      // 서버 기반 검증: users 테이블의 profile_completed 확인
      print('🔍 users 테이블에서 profile_completed 조회 시도: user_id = ${currentUser.id}');
      
      final response = await _supabase
          .from('users')
          .select('profile_completed')
          .eq('user_id', currentUser.id)
          .maybeSingle();

      print('📊 조회 결과 전체: $response');
      final isCompleted = response?['profile_completed'] ?? false;
      print('🔍 서버 기반 온보딩 완료 상태: $isCompleted (사용자: ${currentUser.id})');
      
      return isCompleted;
    } catch (e) {
      print('❌ 온보딩 완료 상태 확인 실패: $e');
      // 오류 시 안전하게 false 반환 (온보딩 화면으로 이동)
      return false;
    }
  }
}