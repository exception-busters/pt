import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/models/onboarding_data.dart';
import '../data/onboarding_service.dart';

class OnboardingNotifier extends StateNotifier<OnboardingData> {
  OnboardingNotifier() : super(const OnboardingData());

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

  Future<void> saveOnboardingData() async {
    try {
      // Supabase에 사용자 프로필 저장
      final onboardingService = OnboardingService();
      final success = await onboardingService.saveUserProfile(state);
      
      if (success) {
        // 로컬 저장소에도 저장
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('onboarding_completed', true);
        
        // 사용자 데이터 저장
        if (state.gender != null) {
          await prefs.setString('user_gender', state.gender!.name);
        }
        if (state.age != null) {
          await prefs.setInt('user_age', state.age!);
        }
        if (state.weight != null) {
          await prefs.setDouble('user_weight', state.weight!);
        }
        if (state.height != null) {
          await prefs.setDouble('user_height', state.height!);
        }
        if (state.workoutGoal != null) {
          await prefs.setString('user_workout_goal', state.workoutGoal!.name);
        }
        if (state.workoutLevel != null) {
          await prefs.setString('user_workout_level', state.workoutLevel!.name);
        }
        
        print('✅ 온보딩 데이터 저장 완료 (Supabase + 로컬)');
      } else {
        throw Exception('Supabase 저장 실패');
      }
    } catch (e) {
      print('❌ 온보딩 데이터 저장 실패: $e');
      // Supabase 저장 실패 시 로컬만 저장
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('onboarding_completed', true);
        print('⚠️ 로컬 저장소에만 저장됨');
      } catch (localError) {
        print('❌ 로컬 저장도 실패: $localError');
        rethrow;
      }
    }
  }

  void reset() {
    state = const OnboardingData();
  }
}

final onboardingProvider = StateNotifierProvider<OnboardingNotifier, OnboardingData>((ref) {
  return OnboardingNotifier();
});

// 온보딩 완료 상태 확인 Provider
final onboardingCompletedProvider = FutureProvider<bool>((ref) async {
  try {
    // 먼저 Supabase에서 확인
    final onboardingService = OnboardingService();
    final supabaseCompleted = await onboardingService.isOnboardingCompleted();
    
    if (supabaseCompleted) {
      return true;
    }
    
    // Supabase에서 확인되지 않으면 로컬 저장소 확인
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('onboarding_completed') ?? false;
  } catch (e) {
    print('❌ 온보딩 완료 상태 확인 실패: $e');
    return false;
  }
});

// 온보딩 서비스 Provider
final onboardingServiceProvider = Provider<OnboardingService>((ref) => OnboardingService());