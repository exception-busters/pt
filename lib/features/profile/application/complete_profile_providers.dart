import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/user_model.dart';
import '../domain/models/user_profile_model.dart';
import '../domain/models/workout_goal_model.dart';
import '../domain/models/diet_goal_model.dart';
import '../data/profile_data_service.dart';
import '../../auth/application/auth_providers.dart';
import '../../common/mixins/auth_state_mixin.dart';

/// 완전한 사용자 데이터 상태
class CompleteUserData {
  final UserModel? user;
  final UserProfileModel? profile;
  final WorkoutGoalModel? workout;
  final DietGoalModel? diet;
  final bool isLoading;
  final String? error;

  const CompleteUserData({
    this.user,
    this.profile,
    this.workout,
    this.diet,
    this.isLoading = false,
    this.error,
  });

  CompleteUserData copyWith({
    UserModel? user,
    UserProfileModel? profile,
    WorkoutGoalModel? workout,
    DietGoalModel? diet,
    bool? isLoading,
    String? error,
  }) {
    return CompleteUserData(
      user: user ?? this.user,
      profile: profile ?? this.profile,
      workout: workout ?? this.workout,
      diet: diet ?? this.diet,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  bool get hasCompleteProfile => 
      user != null && profile != null && workout != null && diet != null;
}

/// 완전한 사용자 데이터 컨트롤러
class CompleteUserDataController extends StateNotifier<CompleteUserData> 
    with AuthStateMixin<CompleteUserData> {
  
  CompleteUserDataController(Ref ref) : super(const CompleteUserData()) {
    initAuthListener(
      ref,
      onLogout: _clearData,
      onLogin: loadUserData,
    );
  }

  /// 사용자 데이터 로드
  Future<void> loadUserData() async {
    if (!isLoggedIn) return;

    final userId = authState?.isLoggedIn == true 
        ? SupabaseService.currentUser?.id 
        : null;
    
    if (userId == null) return;

    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final data = await ProfileDataService.loadCompleteUserData(userId);
      
      if (data != null) {
        state = CompleteUserData(
          user: data['user'] as UserModel?,
          profile: data['profile'] as UserProfileModel?,
          workout: data['workout'] as WorkoutGoalModel?,
          diet: data['diet'] as DietGoalModel?,
          isLoading: false,
        );
        print('✅ 완전한 사용자 데이터 로드 완료');
      } else {
        state = state.copyWith(
          isLoading: false,
          error: '사용자 데이터를 불러올 수 없습니다.',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      print('❌ 사용자 데이터 로드 실패: $e');
    }
  }

  /// 완전한 프로필 저장
  Future<bool> saveCompleteProfile({
    UserProfileModel? userProfile,
    WorkoutGoalModel? workoutGoal,
    DietGoalModel? dietGoal,
    String? nickname,
  }) async {
    if (!isLoggedIn) return false;

    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return false;

    try {
      state = state.copyWith(isLoading: true, error: null);

      final success = await ProfileDataService.saveCompleteProfile(
        userId: userId,
        userProfile: userProfile,
        workoutGoal: workoutGoal,
        dietGoal: dietGoal,
        nickname: nickname,
      );

      if (success) {
        // 저장 후 데이터 새로고침
        await loadUserData();
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: '프로필 저장에 실패했습니다.',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      print('❌ 프로필 저장 실패: $e');
      return false;
    }
  }

  /// 개별 프로필 업데이트
  Future<bool> updateUserProfile(UserProfileModel profile) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final success = await ProfileDataService.updateUserProfile(profile);
      
      if (success) {
        state = state.copyWith(
          profile: profile,
          isLoading: false,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: '프로필 업데이트에 실패했습니다.',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// 개별 운동 목표 업데이트
  Future<bool> updateWorkoutGoal(WorkoutGoalModel workoutGoal) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final success = await ProfileDataService.updateWorkoutGoal(workoutGoal);
      
      if (success) {
        state = state.copyWith(
          workout: workoutGoal,
          isLoading: false,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: '운동 목표 업데이트에 실패했습니다.',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// 개별 식단 목표 업데이트
  Future<bool> updateDietGoal(DietGoalModel dietGoal) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final success = await ProfileDataService.updateDietGoal(dietGoal);
      
      if (success) {
        state = state.copyWith(
          diet: dietGoal,
          isLoading: false,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: '식단 목표 업데이트에 실패했습니다.',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// 닉네임 업데이트
  Future<bool> updateNickname(String nickname) async {
    if (!isLoggedIn || state.user == null) return false;

    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final success = await ProfileDataService.updateNickname(
        state.user!.userId,
        nickname,
      );
      
      if (success) {
        state = state.copyWith(
          user: state.user!.copyWith(nickname: nickname),
          isLoading: false,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: '닉네임 업데이트에 실패했습니다.',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// 로그아웃 시 데이터 정리
  void _clearData() {
    state = const CompleteUserData();
  }

  /// 에러 상태 클리어
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// 완전한 사용자 데이터 프로바이더
final completeUserDataProvider = StateNotifierProvider<CompleteUserDataController, CompleteUserData>(
  (ref) => CompleteUserDataController(ref),
);

/// 편의를 위한 개별 프로바이더들
final userModelProvider = Provider<UserModel?>((ref) {
  return ref.watch(completeUserDataProvider).user;
});

final userProfileModelProvider = Provider<UserProfileModel?>((ref) {
  return ref.watch(completeUserDataProvider).profile;
});

final workoutGoalModelProvider = Provider<WorkoutGoalModel?>((ref) {
  return ref.watch(completeUserDataProvider).workout;
});

final dietGoalModelProvider = Provider<DietGoalModel?>((ref) {
  return ref.watch(completeUserDataProvider).diet;
});

final profileLoadingProvider = Provider<bool>((ref) {
  return ref.watch(completeUserDataProvider).isLoading;
});

final profileErrorProvider = Provider<String?>((ref) {
  return ref.watch(completeUserDataProvider).error;
});