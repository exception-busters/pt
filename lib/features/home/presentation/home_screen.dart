import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_application_1/color.dart';
import 'package:flutter_application_1/features/profile/application/complete_profile_providers.dart';
import 'package:flutter_application_1/features/records/application/records_providers.dart';
import 'package:flutter_application_1/features/records/application/statistics_providers.dart';
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
                '이번 주 요약',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: mainButtonColor,
                ),
              ),
              const SizedBox(height: 16),
              _buildWeeklySummary(ref, context),
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

  Widget _buildWeeklySummary(WidgetRef ref, BuildContext context) {
    // 이번 주 월요일 계산 (자정으로 정규화하여 동일한 DateTime 객체 보장)
    final now = DateTime.now();
    final weekStart = DateTime(
      now.year,
      now.month,
      now.day - (now.weekday - 1),
    );

    final workoutStatsAsync = ref.watch(weeklyWorkoutStatsProviderFamily(weekStart));
    final dietStatsAsync = ref.watch(weeklyDietStatsProviderFamily(weekStart));

    // 둘 다 로딩 중
    if (workoutStatsAsync.isLoading || dietStatsAsync.isLoading) {
      return _buildWeeklySummaryLoading();
    }

    // 에러 체크
    if (workoutStatsAsync.hasError || dietStatsAsync.hasError) {
      print('홈 화면 통계 에러: workout=${workoutStatsAsync.error}, diet=${dietStatsAsync.error}');
      return _buildWeeklySummaryError();
    }

    // 데이터 확인
    final workoutStats = workoutStatsAsync.value;
    final dietStats = dietStatsAsync.value;

    if (workoutStats == null || dietStats == null) {
      return _buildWeeklySummaryLoading();
    }

    return Column(
      children: [
        // 운동 통계 카드
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [mainButtonColor.withOpacity(0.1), mainButtonColor.withOpacity(0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: mainButtonColor.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: mainButtonColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.fitness_center, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    '운동',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: mainButtonColor,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => context.go('/app/records'),
                    icon: const Icon(Icons.arrow_forward, size: 16),
                    label: const Text('자세히'),
                    style: TextButton.styleFrom(
                      foregroundColor: mainButtonColor,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatColumn(
                    '${workoutStats.totalWorkouts}회',
                    '운동 횟수',
                    Icons.event_available,
                    mainButtonColor,
                  ),
                  _buildStatColumn(
                    '${(workoutStats.totalMinutes / 60).toStringAsFixed(1)}시간',
                    '총 시간',
                    Icons.timer,
                    mainButtonColor,
                  ),
                  _buildStatColumn(
                    '${workoutStats.totalCaloriesBurned}kcal',
                    '소모 칼로리',
                    Icons.local_fire_department,
                    Colors.orange,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // 일별 운동 미니 차트
              _buildMiniWorkoutChart(workoutStats.dailySummaries),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // 식단 통계 카드
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [secondaryButtonColor.withOpacity(0.1), secondaryButtonColor.withOpacity(0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: secondaryButtonColor.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: secondaryButtonColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.restaurant, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    '식단',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: secondaryButtonColor,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => context.go('/app/records'),
                    icon: const Icon(Icons.arrow_forward, size: 16),
                    label: const Text('자세히'),
                    style: TextButton.styleFrom(
                      foregroundColor: secondaryButtonColor,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatColumn(
                    '${dietStats.averageCalories.toStringAsFixed(0)}kcal',
                    '평균 칼로리',
                    Icons.local_fire_department,
                    secondaryButtonColor,
                  ),
                  _buildStatColumn(
                    '${dietStats.calorieAchievementRate.toStringAsFixed(0)}%',
                    '목표 달성률',
                    Icons.trending_up,
                    dietStats.isOnTrack ? Colors.green : Colors.orange,
                  ),
                  _buildStatColumn(
                    '${dietStats.totalMeals}회',
                    '총 식사',
                    Icons.restaurant_menu,
                    secondaryButtonColor,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // 일별 식단 미니 차트
              _buildMiniDietChart(dietStats.dailySummaries),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatColumn(String value, String label, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: subTextColor,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildMiniWorkoutChart(List dailySummaries) {
    final weekDays = ['월', '화', '수', '목', '금', '토', '일'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '일별 운동',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: subTextColor,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(7, (index) {
            final summary = dailySummaries[index];
            final hasWorkout = summary.hasWorkout;
            final height = hasWorkout ? 40.0 : 20.0;

            return Column(
              children: [
                Container(
                  width: 32,
                  height: height,
                  decoration: BoxDecoration(
                    color: hasWorkout ? mainButtonColor : Colors.grey[300],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: hasWorkout
                      ? Center(
                          child: Text(
                            '${summary.workoutCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 4),
                Text(
                  weekDays[index],
                  style: TextStyle(
                    fontSize: 10,
                    color: hasWorkout ? mainButtonColor : subTextColor,
                    fontWeight: hasWorkout ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }

  Widget _buildMiniDietChart(List dailySummaries) {
    final weekDays = ['월', '화', '수', '목', '금', '토', '일'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '일별 식사',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: subTextColor,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(7, (index) {
            final summary = dailySummaries[index];
            final hasMeals = summary.hasMeals;
            final height = hasMeals ? (summary.mealCount * 13.0).clamp(20.0, 40.0) : 20.0;

            return Column(
              children: [
                Container(
                  width: 32,
                  height: height,
                  decoration: BoxDecoration(
                    color: hasMeals ? secondaryButtonColor : Colors.grey[300],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: hasMeals
                      ? Center(
                          child: Text(
                            '${summary.mealCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 4),
                Text(
                  weekDays[index],
                  style: TextStyle(
                    fontSize: 10,
                    color: hasMeals ? secondaryButtonColor : subTextColor,
                    fontWeight: hasMeals ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }

  Widget _buildWeeklySummaryLoading() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: borderColor),
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildWeeklySummaryError() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: borderColor),
      ),
      child: const Column(
        children: [
          Icon(Icons.error_outline, color: subTextColor, size: 40),
          SizedBox(height: 12),
          Text(
            '이번 주 통계를 불러올 수 없습니다',
            style: TextStyle(
              color: subTextColor,
              fontSize: 14,
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
