import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/models/onboarding_data.dart';
import '../data/onboarding_service.dart';
import '../../auth/application/auth_providers.dart';
import '../../common/mixins/auth_state_mixin.dart';

class OnboardingNotifier extends StateNotifier<OnboardingData> with AuthStateMixin<OnboardingData> {
  OnboardingNotifier(Ref ref) : super(const OnboardingData()) {
    // 공통 인증 상태 리스너 초기화
    initAuthListener(
      ref,
      onLogout: () {
        reset();
        _clearUserSpecificData();
      },
      onLogin: _loadUserData,
    );
  }

  String _getUserDataKey(String key) {
    final user = Supabase.instance.client.auth.currentUser;
    return user != null ? '${key}_${user.id}' : '${key}_default';
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final genderStr = prefs.getString(_getUserDataKey('user_gender'));
      final age = prefs.getInt(_getUserDataKey('user_age'));
      final weight = prefs.getDouble(_getUserDataKey('user_weight'));
      final height = prefs.getDouble(_getUserDataKey('user_height'));
      final workoutGoalStr = prefs.getString(_getUserDataKey('user_workout_goal'));
      final workoutLevelStr = prefs.getString(_getUserDataKey('user_workout_level'));
      final experienceDurationStr = prefs.getString(_getUserDataKey('user_experience_duration'));

      final workoutGoal = workoutGoalStr != null
          ? WorkoutGoal.values.firstWhere(
              (g) => g.name == workoutGoalStr,
              orElse: () => WorkoutGoal.weightLoss,
            )
          : null;

      state = OnboardingData(
        gender: genderStr != null ? Gender.values.firstWhere((g) => g.name == genderStr, orElse: () => Gender.male) : null,
        age: age,
        weight: weight,
        height: height,
        workoutGoal: workoutGoal == WorkoutGoal.fitnessImprovement ? WorkoutGoal.healthMaintenance : workoutGoal,
        workoutLevel: workoutLevelStr != null ? WorkoutLevel.values.firstWhere((l) => l.name == workoutLevelStr, orElse: () => WorkoutLevel.beginner) : null,
        experienceDuration: experienceDurationStr != null ? ExperienceDuration.values.firstWhere((e) => e.name == experienceDurationStr, orElse: () => ExperienceDuration.lessThan6Months) : null,
      );
    } catch (e) {
      print('사용자 데이터 로드 실패: $e');
    }
  }

  Future<void> _clearUserSpecificData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await prefs.remove('onboarding_completed_${user.id}');
        await prefs.remove(_getUserDataKey('user_gender'));
        await prefs.remove(_getUserDataKey('user_age'));
        await prefs.remove(_getUserDataKey('user_weight'));
        await prefs.remove(_getUserDataKey('user_height'));
        await prefs.remove(_getUserDataKey('user_workout_goal'));
        await prefs.remove(_getUserDataKey('user_workout_level'));
        await prefs.remove(_getUserDataKey('user_experience_duration'));
      }
    } catch (e) {
      print('사용자별 데이터 삭제 실패: $e');
    }
  }

  void updateGender(Gender gender) {
    state = state.copyWith(gender: gender);
  }

  void updateAge(int age) {
    state = state.copyWith(age: age);
  }

  void updateWeight(double weight) {
    state = state.copyWith(weight: weight);
  }

  void updateHeight(double height) {
    state = state.copyWith(height: height);
  }

  void updateWorkoutGoal(WorkoutGoal goal) {
    state = state.copyWith(workoutGoal: goal);
  }

  void updateWorkoutLevel(WorkoutLevel level) {
    state = state.copyWith(workoutLevel: level);
  }

  void updateExperienceDuration(ExperienceDuration duration) {
    state = state.copyWith(experienceDuration: duration);
  }

  Future<void> saveOnboardingData() async {
    try {
      print('🚀 온보딩 데이터 저장 시작...');
      
      // 1. Supabase에 사용자 프로필 저장 및 profile_completed 업데이트
      final onboardingService = OnboardingService();
      final success = await onboardingService.saveUserProfile(state);
      
      if (success) {
        print('✅ 서버에 온보딩 데이터 저장 및 profile_completed 업데이트 완료');
        
        // 2. 로컬 저장소에도 사용자별로 저장 (캐시 목적)
        final prefs = await SharedPreferences.getInstance();
        final user = Supabase.instance.client.auth.currentUser;
        if (user != null) {
          await prefs.setBool('onboarding_completed_${user.id}', true);
          
          // 사용자별 데이터 저장
          if (state.gender != null) {
            await prefs.setString(_getUserDataKey('user_gender'), state.gender!.name);
          }
          if (state.age != null) {
            await prefs.setInt(_getUserDataKey('user_age'), state.age!);
          }
          if (state.weight != null) {
            await prefs.setDouble(_getUserDataKey('user_weight'), state.weight!);
          }
          if (state.height != null) {
            await prefs.setDouble(_getUserDataKey('user_height'), state.height!);
          }
          if (state.workoutGoal != null) {
            await prefs.setString(_getUserDataKey('user_workout_goal'), state.workoutGoal!.name);
          }
          if (state.workoutLevel != null) {
            await prefs.setString(_getUserDataKey('user_workout_level'), state.workoutLevel!.name);
          }
          if (state.experienceDuration != null) {
            await prefs.setString(_getUserDataKey('user_experience_duration'), state.experienceDuration!.name);
          }

          print('✅ 로컬 캐시에도 저장 완료');
        }
        
        print('🎉 온보딩 완료! 서버 profile_completed = true로 업데이트됨');
      } else {
        throw Exception('서버 저장 실패');
      }
    } catch (e) {
      print('❌ 온보딩 데이터 저장 실패: $e');
      
      // 서버 저장 실패 시에도 로컬에는 저장하지 않음 (서버 상태와 동기화 유지)
      // 사용자가 다시 온보딩을 완료하도록 유도
      rethrow;
    }
  }

  void reset() {
    state = const OnboardingData();
  }
}

final onboardingProvider = StateNotifierProvider<OnboardingNotifier, OnboardingData>((ref) {
  return OnboardingNotifier(ref);
});

// 온보딩 완료 상태는 이제 AuthController에서 직접 관리
// 중복 제거: onboardingCompletedProvider 삭제하고 authControllerProvider.profileCompleted 사용

// 온보딩 서비스 Provider
final onboardingServiceProvider = Provider<OnboardingService>((ref) => OnboardingService());
