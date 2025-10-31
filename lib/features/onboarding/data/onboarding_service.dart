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

      print('💾 사용자 프로필 저장 시작: ${currentUser.id}');

      // public_users 테이블에 사용자 정보 업데이트
      final profileData = {
        'gender': data.gender?.name,
        'age': data.age,
        'weight': data.weight,
        'height': data.height,
        'workout_goal': data.workoutGoal?.name,
        'workout_level': data.workoutLevel?.name,
        'onboarding_completed': true,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _supabase
          .from('public_users')
          .upsert({
            'id': currentUser.id,
            ...profileData,
          });

      print('✅ 사용자 프로필 저장 완료');
      return true;
    } catch (e) {
      print('❌ 사용자 프로필 저장 실패: $e');
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

      final response = await _supabase
          .from('public_users')
          .select('onboarding_completed')
          .eq('id', currentUser.id)
          .maybeSingle();

      return response?['onboarding_completed'] ?? false;
    } catch (e) {
      print('❌ 온보딩 완료 상태 확인 실패: $e');
      return false;
    }
  }
}