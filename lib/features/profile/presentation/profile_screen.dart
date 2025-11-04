import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_application_1/color.dart';
import 'package:flutter_application_1/features/profile/application/profile_providers.dart';
import 'package:flutter_application_1/features/profile/application/complete_profile_providers.dart';
import 'package:flutter_application_1/features/profile/domain/models/workout_goal_model.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_application_1/features/auth/application/auth_providers.dart';


class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileImagePath = ref.watch(profileImageControllerProvider);
    final userProfileAsync = ref.watch(userProfileControllerProvider);
    final completeData = ref.watch(completeUserDataProvider);

    final authState = ref.watch(authControllerProvider);
    if (authState.isLoggedIn &&
        !completeData.isLoading &&
        completeData.workout == null &&
        completeData.profile == null &&
        completeData.user == null) {
      ref.read(completeUserDataProvider.notifier).loadUserData();
    }
    
    return userProfileAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(
          title: const Text('프로필'),
          backgroundColor: backgroundColor,
          foregroundColor: mainButtonColor,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('프로필을 불러올 수 없습니다\n$error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(userProfileControllerProvider),
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      ),
      data: (userProfile) => _buildProfileScreen(
        context,
        ref,
        profileImagePath,
        userProfile,
        completeData,
      ),
    );
  }

  Widget _buildProfileScreen(
    BuildContext context,
    WidgetRef ref,
    String? profileImagePath,
    Map<String, dynamic>? userProfile,
    CompleteUserData completeData,
  ) {
    final displayName = userProfile?['nickname'] ?? '사용자';
    final email = userProfile?['email'] ?? '';
    final joinDate = userProfile?['join_date'] != null 
        ? DateTime.parse(userProfile!['join_date']).toLocal()
        : null;

    final workoutGoal = completeData.workout;
    final goalText = _mapGoalLabel(workoutGoal?.goalType);
    final weeklyText = _mapWeeklyPlan(workoutGoal?.weeklyDays);
    final durationText = _mapDuration(workoutGoal?.dailyDurationMin);
    return Scaffold(
      appBar: AppBar(
        title: const Text('프로필'),
        backgroundColor: backgroundColor,
        foregroundColor: mainButtonColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(userProfileControllerProvider),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('설정 기능은 추후 구현됩니다'),
                  backgroundColor: mainButtonColor,
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: mainButtonColor,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white,
                      backgroundImage: profileImagePath != null && File(profileImagePath).existsSync()
                          ? FileImage(File(profileImagePath))
                          : null,
                      child: profileImagePath == null || !File(profileImagePath).existsSync()
                          ? const Icon(
                              Icons.person,
                              size: 50,
                              color: mainButtonColor,
                            )
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      email,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      joinDate != null 
                          ? '가입일: ${joinDate.year}.${joinDate.month.toString().padLeft(2, '0')}.${joinDate.day.toString().padLeft(2, '0')}'
                          : 'PT 회원',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildProfileStat('목표', goalText),
                        _buildProfileStat('주간 계획', weeklyText),
                        _buildProfileStat('운동 시간', durationText),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildProfileMenu('개인정보 수정', Icons.edit, () {
                context.push('/app/profile/edit');
              }),
              _buildProfileMenu('운동 목표 설정', Icons.flag, () {
                context.push('/app/profile/workout-goal');
              }),
              _buildProfileMenu('식단 목표 설정', Icons.restaurant_menu, () {
                context.push('/app/profile/diet-goal');
              }),
              _buildProfileMenu('알림 설정', Icons.notifications, () {
                context.push('/app/profile/notifications');
              }),
              _buildProfileMenu('도움말', Icons.help, () {
                context.push('/app/profile/help');
              }),
              _buildProfileMenu('로그아웃', Icons.logout, () {
                ref.read(authControllerProvider.notifier).signOut();
                context.go('/');
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileMenu(String title, IconData icon, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: ListTile(
        leading: Icon(icon, color: mainButtonColor),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: mainButtonColor,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: subTextColor),
        onTap: onTap,
      ),
    );
  }

  String _mapGoalLabel(WorkoutGoalType? goalType) {
    switch (goalType) {
      case WorkoutGoalType.weightLoss:
        return '다이어트';
      case WorkoutGoalType.muscleGain:
        return '근력향상';
      case WorkoutGoalType.general:
      case WorkoutGoalType.endurance:
      case WorkoutGoalType.strength:
        return '건강유지';
      default:
        return '설정 필요';
    }
  }

  String _mapWeeklyPlan(int? weeklyDays) {
    if (weeklyDays == null || weeklyDays <= 0) {
      return '설정 필요';
    }
    return '주 $weeklyDays회';
  }

  String _mapDuration(int? dailyMinutes) {
    if (dailyMinutes == null || dailyMinutes <= 0) {
      return '설정 필요';
    }
    return '회당 ${dailyMinutes}분';
  }
}
