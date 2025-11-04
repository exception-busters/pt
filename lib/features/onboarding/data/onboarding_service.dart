import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/models/onboarding_data.dart' as onboarding;
import '../../common/data/supabase_service.dart';
import '../../profile/domain/models/user_profile_model.dart' as profile;
import '../../profile/domain/models/workout_goal_model.dart' as workout;
import '../../profile/data/profile_data_service.dart';

class OnboardingService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<bool> saveUserProfile(onboarding.OnboardingData data) async {
    try {
      final currentUser = SupabaseService.currentUser;
      if (currentUser == null) {
        print('❌ 사용자가 로그인되지 않았습니다.');
        return false;
      }

      print('💾 온보딩 데이터 저장 시작: ${currentUser.id}');
      print('📊 저장할 데이터: ${data.toJson()}');

      // OnboardingData를 새로운 모델 구조로 변환
      final userProfile = profile.UserProfileModel(
        userId: currentUser.id,
        gender: data.gender != null 
            ? (data.gender == onboarding.Gender.male ? profile.Gender.male : profile.Gender.female)
            : null,
        age: data.age,
        height: data.height,
        weight: data.weight,
      );

      final workoutGoal = workout.WorkoutGoalModel(
        userId: currentUser.id,
        goalType: data.workoutGoal != null 
            ? _mapWorkoutGoal(data.workoutGoal!)
            : null,
        level: data.workoutLevel != null 
            ? _mapWorkoutLevel(data.workoutLevel!)
            : null,
        weeklyDays: 3, // 기본값
        dailyDurationMin: 30, // 기본값
        preferredTypes: ['general'], // 기본값
      );

      // 새로운 ProfileDataService를 사용하여 저장
      final success = await ProfileDataService.saveCompleteProfile(
        userId: currentUser.id,
        userProfile: userProfile,
        workoutGoal: workoutGoal,
        // dietGoal은 온보딩에서 설정하지 않으므로 null
      );

      if (success) {
        // 기존 public_users 테이블에도 저장 (호환성 유지)
        await _saveToPublicUsers(currentUser.id, data);
        print('✅ 온보딩 데이터 저장 완료');
        return true;
      } else {
        print('❌ 온보딩 데이터 저장 실패');
        return false;
      }
    } catch (e) {
      print('❌ 온보딩 데이터 저장 실패: $e');
      return false;
    }
  }

  Future<void> _saveToPublicUsers(String userId, onboarding.OnboardingData data) async {
    try {
      // 먼저 기존 데이터가 있는지 확인
      final existingData = await _supabase
          .from('public_users')
          .select('id')
          .eq('id', userId)
          .maybeSingle();

      final profileData = {
        'id': userId,
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
            .eq('id', userId);
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
  }

  Future<onboarding.OnboardingData?> getUserProfile() async {
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

      return onboarding.OnboardingData(
        gender: response['gender'] != null 
            ? onboarding.Gender.values.firstWhere((g) => g.name == response['gender'])
            : null,
        age: response['age'],
        weight: response['weight']?.toDouble(),
        height: response['height']?.toDouble(),
        workoutGoal: response['workout_goal'] != null
            ? onboarding.WorkoutGoal.values.firstWhere((g) => g.name == response['workout_goal'])
            : null,
        workoutLevel: response['workout_level'] != null
            ? onboarding.WorkoutLevel.values.firstWhere((l) => l.name == response['workout_level'])
            : null,
      );
    } catch (e) {
      print('❌ 사용자 프로필 조회 실패: $e');
      return null;
    }
  }

  Future<bool> isOnboardingCompleted() async {
    final currentUser = SupabaseService.currentUser;
    if (currentUser == null) return false;

    return await SupabaseService.isProfileCompleted(currentUser.id);
  }

  // 온보딩 WorkoutGoal을 새로운 WorkoutGoalType으로 매핑
  workout.WorkoutGoalType _mapWorkoutGoal(onboarding.WorkoutGoal goal) {
    switch (goal) {
      case onboarding.WorkoutGoal.weightLoss:
        return workout.WorkoutGoalType.weightLoss;
      case onboarding.WorkoutGoal.muscleGain:
        return workout.WorkoutGoalType.muscleGain;
      case onboarding.WorkoutGoal.fitnessImprovement:
        return workout.WorkoutGoalType.general;
      case onboarding.WorkoutGoal.healthMaintenance:
        return workout.WorkoutGoalType.general;
    }
  }

  // 온보딩 WorkoutLevel을 새로운 WorkoutLevel로 매핑
  workout.WorkoutLevel _mapWorkoutLevel(onboarding.WorkoutLevel level) {
    switch (level) {
      case onboarding.WorkoutLevel.beginner:
        return workout.WorkoutLevel.beginner;
      case onboarding.WorkoutLevel.intermediate:
        return workout.WorkoutLevel.intermediate;
      case onboarding.WorkoutLevel.advanced:
        return workout.WorkoutLevel.advanced;
    }
  }

  // 새로운 WorkoutGoalType을 온보딩 WorkoutGoal로 매핑 (역방향)
  onboarding.WorkoutGoal _mapToOnboardingWorkoutGoal(workout.WorkoutGoalType goalType) {
    switch (goalType) {
      case workout.WorkoutGoalType.weightLoss:
        return onboarding.WorkoutGoal.weightLoss;
      case workout.WorkoutGoalType.muscleGain:
        return onboarding.WorkoutGoal.muscleGain;
      case workout.WorkoutGoalType.general:
      case workout.WorkoutGoalType.endurance:
      case workout.WorkoutGoalType.strength:
        return onboarding.WorkoutGoal.healthMaintenance;
      default:
        return onboarding.WorkoutGoal.healthMaintenance;
    }
  }

  // 새로운 WorkoutLevel을 온보딩 WorkoutLevel로 매핑 (역방향)
  onboarding.WorkoutLevel _mapToOnboardingWorkoutLevel(workout.WorkoutLevel level) {
    switch (level) {
      case workout.WorkoutLevel.beginner:
        return onboarding.WorkoutLevel.beginner;
      case workout.WorkoutLevel.intermediate:
        return onboarding.WorkoutLevel.intermediate;
      case workout.WorkoutLevel.advanced:
        return onboarding.WorkoutLevel.advanced;
    }
  }
}
