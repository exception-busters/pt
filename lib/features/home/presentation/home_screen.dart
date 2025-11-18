import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_application_1/color.dart';
import 'package:flutter_application_1/features/profile/application/complete_profile_providers.dart';
import 'package:flutter_application_1/features/records/application/records_providers.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutGoal = ref.watch(workoutGoalModelProvider);
    final dietGoal = ref.watch(dietGoalModelProvider);
    final recordsHistoryAsync = ref.watch(recordsHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('홈'),
        backgroundColor: backgroundColor,
        foregroundColor: mainButtonColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('알림 기능은 추후 구현됩니다'),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: mainButtonColor,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '오늘도 화이팅! 💪',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '오늘의 운동과 식단을 확인해보세요',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                '오늘의 목표',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: mainButtonColor,
                ),
              ),
              const SizedBox(height: 16),
              _buildGoalSection(workoutGoal, dietGoal, recordsHistoryAsync),
              const SizedBox(height: 24),
              const Text(
                '빠른 액션',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: mainButtonColor,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildQuickActionCard(
                      title: '운동 시작',
                      icon: Icons.play_arrow,
                      color: mainButtonColor,
                      onTap: () => context.go('/app/workout'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildQuickActionCard(
                      title: '식단 기록',
                      icon: Icons.restaurant,
                      color: secondaryButtonColor,
                      onTap: () => context.go('/app/diet'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoalSection(
    dynamic workoutGoal,
    dynamic dietGoal,
    AsyncValue recordsHistoryAsync,
  ) {
    return recordsHistoryAsync.when(
      data: (recordsHistory) {
        // 오늘의 운동 목표 계산
        final dailyMinutes = workoutGoal?.dailyDurationMin ?? 30;

        // 오늘 날짜의 기록 가져오기
        final todayRecord = recordsHistory.recordFor(DateTime.now());

        // 오늘 운동한 시간 계산 (분)
        final todayWorkoutMinutes = todayRecord?.totalWorkoutMinutes ?? 0;

        final workoutProgress = dailyMinutes > 0
            ? ((todayWorkoutMinutes / dailyMinutes) * 100).clamp(0, 100).toInt()
            : 0;

        // 오늘의 칼로리 목표 계산
        final targetCalories = dietGoal?.dailyCalorieTarget ?? 2000;

        // 오늘 섭취한 칼로리
        final todayCalories = todayRecord?.totalDietCalories ?? 0;

        final calorieProgress = targetCalories > 0
            ? ((todayCalories / targetCalories) * 100).clamp(0, 100).toInt()
            : 0;

        return Row(
          children: [
            Expanded(
              child: _buildGoalCard(
                '운동',
                '$todayWorkoutMinutes / $dailyMinutes분',
                Icons.fitness_center,
                mainButtonColor,
                '$workoutProgress%',
                workoutProgress,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildGoalCard(
                '칼로리',
                '$todayCalories / ${targetCalories}kcal',
                Icons.local_fire_department,
                secondaryButtonColor,
                '$calorieProgress%',
                calorieProgress,
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => _buildDefaultGoals(),
    );
  }

  Widget _buildDefaultGoals() {
    return Row(
      children: [
        Expanded(
          child: _buildGoalCard(
            '운동',
            '목표 설정 필요',
            Icons.fitness_center,
            mainButtonColor,
            '0%',
            0,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildGoalCard(
            '칼로리',
            '목표 설정 필요',
            Icons.local_fire_department,
            secondaryButtonColor,
            '0%',
            0,
          ),
        ),
      ],
    );
  }

  Widget _buildGoalCard(String title, String value, IconData icon, Color color, String progress, int progressValue) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: mainButtonColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: mainButtonColor,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progressValue / 100,
              backgroundColor: borderColor,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '달성률: $progress',
            style: const TextStyle(
              fontSize: 12,
              color: subTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
