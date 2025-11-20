import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_application_1/color.dart';
import 'package:flutter_application_1/widgets/error_widget.dart';
import '../application/statistics_providers.dart';
import '../domain/statistics_models.dart';
import 'package:intl/intl.dart';

class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedWeekStart = DateTime.now();
  DateTime _selectedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // 주의 시작일 계산 (월요일)
    final now = DateTime.now();
    _selectedWeekStart = now.subtract(Duration(days: now.weekday - 1));
    _selectedMonth = DateTime(now.year, now.month, 1);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _previousWeek() {
    setState(() {
      _selectedWeekStart = _selectedWeekStart.subtract(const Duration(days: 7));
    });
  }

  void _nextWeek() {
    setState(() {
      _selectedWeekStart = _selectedWeekStart.add(const Duration(days: 7));
    });
  }

  void _previousMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);
    });
  }

  bool _isCurrentWeek() {
    final now = DateTime.now();
    final currentWeekStart = now.subtract(Duration(days: now.weekday - 1));
    return _selectedWeekStart.year == currentWeekStart.year &&
           _selectedWeekStart.month == currentWeekStart.month &&
           _selectedWeekStart.day == currentWeekStart.day;
  }

  bool _isCurrentMonth() {
    final now = DateTime.now();
    return _selectedMonth.year == now.year && _selectedMonth.month == now.month;
  }

  Future<void> _selectWeek() async {
    final picked = await showDialog<DateTime>(
      context: context,
      builder: (context) => _WeekPickerDialog(
        initialWeekStart: _selectedWeekStart,
      ),
    );

    if (picked != null) {
      setState(() {
        _selectedWeekStart = picked;
      });
    }
  }

  Future<void> _selectMonth() async {
    final picked = await showDialog<DateTime>(
      context: context,
      builder: (context) => _MonthYearPickerDialog(
        initialDate: _selectedMonth,
      ),
    );

    if (picked != null) {
      setState(() {
        _selectedMonth = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('통계'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '주간'),
            Tab(text: '월간'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _WeeklyStatsView(
            weekStart: _selectedWeekStart,
            onPrevious: _previousWeek,
            onNext: _nextWeek,
            onSelectWeek: _selectWeek,
            isCurrentWeek: _isCurrentWeek(),
          ),
          _MonthlyStatsView(
            month: _selectedMonth,
            onPrevious: _previousMonth,
            onNext: _nextMonth,
            onSelectMonth: _selectMonth,
            isCurrentMonth: _isCurrentMonth(),
          ),
        ],
      ),
    );
  }
}

class _WeeklyStatsView extends ConsumerWidget {
  final DateTime weekStart;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onSelectWeek;
  final bool isCurrentWeek;

  const _WeeklyStatsView({
    required this.weekStart,
    required this.onPrevious,
    required this.onNext,
    required this.onSelectWeek,
    required this.isCurrentWeek,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weekEnd = weekStart.add(const Duration(days: 7));
    final workoutStats = ref.watch(weeklyWorkoutStatsProviderFamily(weekStart));
    final dietStats = ref.watch(weeklyDietStatsProviderFamily(weekStart));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(weeklyWorkoutStatsProviderFamily(weekStart));
        ref.invalidate(weeklyDietStatsProviderFamily(weekStart));
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 날짜 선택기
            Container(
              padding: const EdgeInsets.all(16),
              color: backgroundColor,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: onPrevious,
                  ),
                  GestureDetector(
                    onTap: onSelectWeek,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${DateFormat('M월 d일').format(weekStart)} - ${DateFormat('M월 d일').format(weekEnd.subtract(const Duration(days: 1)))}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: mainButtonColor,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.calendar_today,
                          size: 18,
                          color: mainButtonColor,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.chevron_right,
                      color: isCurrentWeek ? Colors.grey : mainButtonColor,
                    ),
                    onPressed: isCurrentWeek ? null : onNext,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '이번 주 운동',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: mainButtonColor,
                ),
              ),
            ),
            const SizedBox(height: 12),

            workoutStats.when(
              data: (stats) {
                if (stats.totalWorkouts == 0) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.fitness_center, size: 48, color: subTextColor),
                              SizedBox(height: 12),
                              Text(
                                '이번 주 운동 기록이 없습니다',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: subTextColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }
                return _WorkoutStatsCard(stats: stats);
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, stack) => InlineErrorWidget(
                message: '운동 기록이 부족합니다',
                onRetry: () => ref.invalidate(weeklyWorkoutStatsProviderFamily(weekStart)),
              ),
            ),

            const SizedBox(height: 24),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '이번 주 식단',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: mainButtonColor,
                ),
              ),
            ),
            const SizedBox(height: 12),

            dietStats.when(
              data: (stats) {
                if (stats.totalMeals == 0) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.restaurant, size: 48, color: subTextColor),
                              SizedBox(height: 12),
                              Text(
                                '이번 주 식단 기록이 없습니다',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: subTextColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }
                return _DietStatsCard(stats: stats);
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, stack) => InlineErrorWidget(
                message: '식단 기록이 부족합니다',
                onRetry: () => ref.invalidate(weeklyDietStatsProviderFamily(weekStart)),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _MonthlyStatsView extends ConsumerWidget {
  final DateTime month;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onSelectMonth;
  final bool isCurrentMonth;

  const _MonthlyStatsView({
    required this.month,
    required this.onPrevious,
    required this.onNext,
    required this.onSelectMonth,
    required this.isCurrentMonth,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutStats = ref.watch(monthlyWorkoutStatsProviderFamily(month));
    final dietStats = ref.watch(monthlyDietStatsProviderFamily(month));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(monthlyWorkoutStatsProviderFamily(month));
        ref.invalidate(monthlyDietStatsProviderFamily(month));
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 날짜 선택기
            Container(
              padding: const EdgeInsets.all(16),
              color: backgroundColor,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: onPrevious,
                  ),
                  GestureDetector(
                    onTap: onSelectMonth,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          DateFormat('yyyy년 M월').format(month),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: mainButtonColor,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.calendar_month,
                          size: 18,
                          color: mainButtonColor,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.chevron_right,
                      color: isCurrentMonth ? Colors.grey : mainButtonColor,
                    ),
                    onPressed: isCurrentMonth ? null : onNext,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '이번 달 운동',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: mainButtonColor,
                ),
              ),
            ),
            const SizedBox(height: 12),

            workoutStats.when(
              data: (stats) {
                if (stats.totalWorkouts == 0) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.fitness_center, size: 48, color: subTextColor),
                              SizedBox(height: 12),
                              Text(
                                '이번 달 운동 기록이 없습니다',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: subTextColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }
                return _MonthlyWorkoutStatsCard(stats: stats);
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, stack) => InlineErrorWidget(
                message: '운동 기록이 부족합니다',
                onRetry: () => ref.invalidate(monthlyWorkoutStatsProviderFamily(month)),
              ),
            ),

            const SizedBox(height: 24),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '이번 달 식단',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: mainButtonColor,
                ),
              ),
            ),
            const SizedBox(height: 12),

            dietStats.when(
              data: (stats) {
                if (stats.totalMeals == 0) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.restaurant, size: 48, color: subTextColor),
                              SizedBox(height: 12),
                              Text(
                                '이번 달 식단 기록이 없습니다',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: subTextColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }
                return _MonthlyDietStatsCard(stats: stats);
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, stack) => InlineErrorWidget(
                message: '식단 기록이 부족합니다',
                onRetry: () => ref.invalidate(monthlyDietStatsProviderFamily(month)),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _WorkoutStatsCard extends StatelessWidget {
  final WeeklyWorkoutStats stats;

  const _WorkoutStatsCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(
                  label: '총 운동',
                  value: '${stats.totalWorkouts}회',
                  icon: Icons.fitness_center,
                ),
                _StatItem(
                  label: '총 시간',
                  value: '${stats.totalMinutes}분',
                  icon: Icons.schedule,
                ),
                _StatItem(
                  label: '완료율',
                  value: '${stats.completionRate.toStringAsFixed(0)}%',
                  icon: Icons.check_circle,
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              '일별 운동',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            _DailyWorkoutChart(dailySummaries: stats.dailySummaries),
          ],
        ),
      ),
    );
  }
}

class _DietStatsCard extends StatelessWidget {
  final WeeklyDietStats stats;

  const _DietStatsCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final achievementColor = stats.isOnTrack ? Colors.green : Colors.orange;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(
                  label: '평균 칼로리',
                  value: '${stats.averageCalories.toStringAsFixed(0)}',
                  icon: Icons.local_fire_department,
                ),
                _StatItem(
                  label: '목표 칼로리',
                  value: '${stats.targetCalories.toStringAsFixed(0)}',
                  icon: Icons.flag,
                ),
                _StatItem(
                  label: '달성률',
                  value: '${stats.calorieAchievementRate.toStringAsFixed(0)}%',
                  icon: Icons.trending_up,
                  color: achievementColor,
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: stats.calorieAchievementRate / 100,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(achievementColor),
            ),
            const SizedBox(height: 8),
            Text(
              stats.isOnTrack ? '목표를 잘 달성하고 있어요!' : '목표에 맞춰 조절이 필요해요',
              style: TextStyle(
                fontSize: 12,
                color: achievementColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '일별 식단',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            _DailyDietChart(dailySummaries: stats.dailySummaries),
          ],
        ),
      ),
    );
  }
}

class _MonthlyWorkoutStatsCard extends StatelessWidget {
  final MonthlyWorkoutStats stats;

  const _MonthlyWorkoutStatsCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(
                  label: '총 운동',
                  value: '${stats.totalWorkouts}회',
                  icon: Icons.fitness_center,
                ),
                _StatItem(
                  label: '주평균',
                  value: '${stats.averageWorkoutsPerWeek.toStringAsFixed(1)}회',
                  icon: Icons.calendar_today,
                ),
                _StatItem(
                  label: '완료율',
                  value: '${stats.completionRate.toStringAsFixed(0)}%',
                  icon: Icons.check_circle,
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              '주별 운동 횟수',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            _WeeklyWorkoutChart(weeklySummaries: stats.weeklySummaries),
          ],
        ),
      ),
    );
  }
}

class _MonthlyDietStatsCard extends StatelessWidget {
  final MonthlyDietStats stats;

  const _MonthlyDietStatsCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final achievementColor =
        stats.calorieAchievementRate >= 90 && stats.calorieAchievementRate <= 110
            ? Colors.green
            : Colors.orange;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(
                  label: '평균 칼로리',
                  value: '${stats.averageCalories.toStringAsFixed(0)}',
                  icon: Icons.local_fire_department,
                ),
                _StatItem(
                  label: '달성률',
                  value: '${stats.calorieAchievementRate.toStringAsFixed(0)}%',
                  icon: Icons.trending_up,
                  color: achievementColor,
                ),
                _StatItem(
                  label: '총 식사',
                  value: '${stats.totalMeals}회',
                  icon: Icons.restaurant,
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              '주별 평균 칼로리',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            _WeeklyDietChart(weeklySummaries: stats.weeklySummaries),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color ?? mainButtonColor, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color ?? mainButtonColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: subTextColor,
          ),
        ),
      ],
    );
  }
}

class _DailyWorkoutChart extends StatelessWidget {
  final List<DailyWorkoutSummary> dailySummaries;

  const _DailyWorkoutChart({required this.dailySummaries});

  @override
  Widget build(BuildContext context) {
    final weekDays = ['월', '화', '수', '목', '금', '토', '일'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(7, (index) {
        final summary = dailySummaries[index];
        final hasWorkout = summary.hasWorkout;

        return Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: hasWorkout ? mainButtonColor : Colors.grey[300],
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  hasWorkout ? '${summary.workoutCount}' : '-',
                  style: TextStyle(
                    color: hasWorkout ? Colors.white : Colors.grey[600],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              weekDays[index],
              style: const TextStyle(
                fontSize: 12,
                color: subTextColor,
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _DailyDietChart extends StatelessWidget {
  final List<DailyDietSummary> dailySummaries;

  const _DailyDietChart({required this.dailySummaries});

  @override
  Widget build(BuildContext context) {
    final weekDays = ['월', '화', '수', '목', '금', '토', '일'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(7, (index) {
        final summary = dailySummaries[index];
        final hasMeals = summary.hasMeals;

        return Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: hasMeals ? mainButtonColor : Colors.grey[300],
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  hasMeals ? '${summary.mealCount}' : '-',
                  style: TextStyle(
                    color: hasMeals ? Colors.white : Colors.grey[600],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              weekDays[index],
              style: const TextStyle(
                fontSize: 12,
                color: subTextColor,
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _WeeklyWorkoutChart extends StatelessWidget {
  final List<WeeklyWorkoutSummary> weeklySummaries;

  const _WeeklyWorkoutChart({required this.weeklySummaries});

  @override
  Widget build(BuildContext context) {
    final maxCount = weeklySummaries.fold<int>(0, (max, s) => s.workoutCount > max ? s.workoutCount : max);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(weeklySummaries.length, (index) {
        final summary = weeklySummaries[index];
        final height = maxCount > 0 ? (summary.workoutCount / maxCount * 80) : 0.0;

        return Column(
          children: [
            Text(
              '${summary.workoutCount}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: mainButtonColor,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 30,
              height: height.clamp(20, 80),
              decoration: BoxDecoration(
                color: mainButtonColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${summary.weekNumber}주',
              style: const TextStyle(
                fontSize: 12,
                color: subTextColor,
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _WeeklyDietChart extends StatelessWidget {
  final List<WeeklyDietSummary> weeklySummaries;

  const _WeeklyDietChart({required this.weeklySummaries});

  @override
  Widget build(BuildContext context) {
    final maxCalories = weeklySummaries.fold<double>(0, (max, s) => s.averageCalories > max ? s.averageCalories : max);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(weeklySummaries.length, (index) {
        final summary = weeklySummaries[index];
        final height = maxCalories > 0 ? (summary.averageCalories / maxCalories * 80) : 0.0;

        return Column(
          children: [
            Text(
              '${summary.averageCalories.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: mainButtonColor,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 30,
              height: height.clamp(20, 80),
              decoration: BoxDecoration(
                color: mainButtonColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${summary.weekNumber}주',
              style: const TextStyle(
                fontSize: 12,
                color: subTextColor,
              ),
            ),
          ],
        );
      }),
    );
  }
}

// 주 선택 다이얼로그
class _WeekPickerDialog extends StatefulWidget {
  final DateTime initialWeekStart;

  const _WeekPickerDialog({required this.initialWeekStart});

  @override
  State<_WeekPickerDialog> createState() => _WeekPickerDialogState();
}

class _WeekPickerDialogState extends State<_WeekPickerDialog> {
  late int _selectedYear;
  late int _selectedMonth;
  DateTime? _selectedWeekStart;

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialWeekStart.year;
    _selectedMonth = widget.initialWeekStart.month;
    _selectedWeekStart = widget.initialWeekStart;
  }

  List<DateTime> _getWeeksInMonth(int year, int month) {
    final firstDay = DateTime(year, month, 1);
    final lastDay = DateTime(year, month + 1, 0);
    final weeks = <DateTime>[];

    // 첫 주의 월요일 찾기
    var currentMonday = firstDay.subtract(Duration(days: firstDay.weekday - 1));

    // 해당 월의 모든 주 찾기
    while (currentMonday.isBefore(lastDay) ||
           (currentMonday.year == year && currentMonday.month == month)) {
      weeks.add(currentMonday);
      currentMonday = currentMonday.add(const Duration(days: 7));

      // 다음 주가 다음 달로 넘어가면서 이번 달 날짜가 하나도 없으면 중단
      final weekEnd = currentMonday.add(const Duration(days: 6));
      if (currentMonday.isAfter(lastDay) && weekEnd.month != month) {
        break;
      }
    }

    return weeks;
  }

  String _formatWeekRange(DateTime weekStart) {
    final weekEnd = weekStart.add(const Duration(days: 6));
    return '${DateFormat('M/d').format(weekStart)} - ${DateFormat('M/d').format(weekEnd)}';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final currentWeekStart = now.subtract(Duration(days: now.weekday - 1));

    final years = List.generate(
      now.year - 2020 + 1,
      (index) => 2020 + index,
    ).reversed.toList();

    final weeks = _getWeeksInMonth(_selectedYear, _selectedMonth);

    return AlertDialog(
      title: const Text('주 선택'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 연도 선택
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _selectedYear,
                    decoration: const InputDecoration(
                      labelText: '연도',
                      border: OutlineInputBorder(),
                    ),
                    items: years.map((year) {
                      return DropdownMenuItem(
                        value: year,
                        child: Text('$year년'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedYear = value;
                          // 선택한 연도/월이 미래인 경우 현재 월로 조정
                          if (_selectedYear == now.year && _selectedMonth > now.month) {
                            _selectedMonth = now.month;
                          }
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                // 월 선택
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _selectedMonth,
                    decoration: const InputDecoration(
                      labelText: '월',
                      border: OutlineInputBorder(),
                    ),
                    items: List.generate(12, (index) {
                      final month = index + 1;
                      final isFuture = _selectedYear == now.year && month > now.month;
                      return DropdownMenuItem(
                        value: month,
                        enabled: !isFuture,
                        child: Text(
                          '$month월',
                          style: TextStyle(
                            color: isFuture ? Colors.grey : Colors.black,
                          ),
                        ),
                      );
                    }),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedMonth = value;
                          _selectedWeekStart = null; // 월이 바뀌면 선택 초기화
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // 주 선택 리스트
            const Text(
              '주 선택',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: mainButtonColor,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 300,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: weeks.length,
                itemBuilder: (context, index) {
                  final weekStart = weeks[index];
                  final weekEnd = weekStart.add(const Duration(days: 6));
                  final isSelected = _selectedWeekStart != null &&
                      weekStart.year == _selectedWeekStart!.year &&
                      weekStart.month == _selectedWeekStart!.month &&
                      weekStart.day == _selectedWeekStart!.day;
                  final isFuture = weekStart.isAfter(currentWeekStart);

                  return Card(
                    color: isFuture
                        ? Colors.grey[200]
                        : (isSelected ? mainButtonColor.withOpacity(0.1) : Colors.white),
                    child: ListTile(
                      enabled: !isFuture,
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isFuture
                              ? Colors.grey[300]
                              : (isSelected ? mainButtonColor : Colors.grey[300]),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        _formatWeekRange(weekStart),
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isFuture ? Colors.grey : Colors.black,
                        ),
                      ),
                      subtitle: Text(
                        '${weekStart.year}년 ${weekStart.month}월',
                        style: TextStyle(
                          fontSize: 12,
                          color: isFuture ? Colors.grey[400] : subTextColor,
                        ),
                      ),
                      selected: isSelected,
                      selectedTileColor: mainButtonColor.withOpacity(0.1),
                      onTap: isFuture
                          ? null
                          : () {
                              setState(() {
                                _selectedWeekStart = weekStart;
                              });
                            },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: _selectedWeekStart == null
              ? null
              : () {
                  Navigator.of(context).pop(_selectedWeekStart);
                },
          child: const Text('확인'),
        ),
      ],
    );
  }
}

// 연도/월 선택 다이얼로그
class _MonthYearPickerDialog extends StatefulWidget {
  final DateTime initialDate;

  const _MonthYearPickerDialog({required this.initialDate});

  @override
  State<_MonthYearPickerDialog> createState() => _MonthYearPickerDialogState();
}

class _MonthYearPickerDialogState extends State<_MonthYearPickerDialog> {
  late int _selectedYear;
  late int _selectedMonth;

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialDate.year;
    _selectedMonth = widget.initialDate.month;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final years = List.generate(
      now.year - 2020 + 1,
      (index) => 2020 + index,
    ).reversed.toList();

    final months = [
      '1월', '2월', '3월', '4월', '5월', '6월',
      '7월', '8월', '9월', '10월', '11월', '12월'
    ];

    return AlertDialog(
      title: const Text('월 선택'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 연도 선택 드롭다운
            DropdownButtonFormField<int>(
              value: _selectedYear,
              decoration: const InputDecoration(
                labelText: '연도',
                border: OutlineInputBorder(),
              ),
              items: years.map((year) {
                return DropdownMenuItem(
                  value: year,
                  child: Text('$year년'),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedYear = value;
                    // 선택한 연도/월이 미래인 경우 현재 월로 조정
                    if (_selectedYear == now.year && _selectedMonth > now.month) {
                      _selectedMonth = now.month;
                    }
                  });
                }
              },
            ),
            const SizedBox(height: 20),
            // 월 선택 그리드
            const Text(
              '월',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: mainButtonColor,
              ),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 2.5,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: 12,
              itemBuilder: (context, index) {
                final month = index + 1;
                final isSelected = month == _selectedMonth;
                final isFuture = _selectedYear == now.year && month > now.month;

                return InkWell(
                  onTap: isFuture
                      ? null
                      : () {
                          setState(() {
                            _selectedMonth = month;
                          });
                        },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isFuture
                          ? Colors.grey[200]
                          : (isSelected ? mainButtonColor : Colors.white),
                      border: Border.all(
                        color: isSelected ? mainButtonColor : borderColor,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        months[index],
                        style: TextStyle(
                          color: isFuture
                              ? Colors.grey[400]
                              : (isSelected ? Colors.white : Colors.black),
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop(
              DateTime(_selectedYear, _selectedMonth, 1),
            );
          },
          child: const Text('확인'),
        ),
      ],
    );
  }
}
