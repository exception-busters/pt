import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_application_1/color.dart';
import 'package:flutter_application_1/widgets/error_widget.dart';
import '../application/statistics_providers.dart';
import '../domain/statistics_models.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  Future<void> _generateMockData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('목업 데이터 생성'),
        content: const Text('지난 4주간의 운동 및 식단 데이터를 생성합니다.\n계속하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('생성'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // BuildContext를 명확하게 캡처
    final scaffoldContext = context;

    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;

      if (userId == null) {
        throw Exception('로그인이 필요합니다');
      }

      // 로딩 다이얼로그 표시
      showDialog(
        context: scaffoldContext,
        barrierDismissible: false,
        builder: (dialogContext) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('목업 데이터 생성 중...'),
                ],
              ),
            ),
          ),
        ),
      );

      // ⭐ 기존 목업 데이터 삭제 (지난 28일)
      final cutoffDate = DateTime.now().subtract(const Duration(days: 28));
      final cutoffStr = DateFormat('yyyy-MM-dd').format(cutoffDate);

      // routine_record에서 is_user_reported=true인 기록 삭제
      await client
          .from('routine_record')
          .delete()
          .eq('user_id', userId)
          .eq('is_user_reported', true)
          .gte('end_time', cutoffStr);

      // meal_record 삭제 (관련 meal_component는 cascade로 자동 삭제됨)
      await client
          .from('meal_record')
          .delete()
          .eq('user_id', userId)
          .gte('meal_date', cutoffStr);

      // nutritionsummary 삭제
      await client
          .from('nutritionsummary')
          .delete()
          .eq('user_id', userId)
          .gte('date', cutoffStr);

      print('🗑️ [Mock Data] 기존 목업 데이터 삭제 완료');

      final now = DateTime.now();
      final random = Random();

      // 1. 운동 기록 생성 (이번 주 월요일부터 지난 4주간)
      // 이번 주 월요일 계산
      final thisWeekMonday = now.subtract(Duration(days: now.weekday - 1));

      for (var week = 0; week < 4; week++) {
        final workoutsThisWeek = 3 + random.nextInt(3); // 3-5회
        for (var i = 0; i < workoutsThisWeek; i++) {
          // 각 주의 랜덤한 날짜 선택 (이번 주 포함)
          final weekStartDate = thisWeekMonday.subtract(Duration(days: week * 7));
          final dayOffset = random.nextInt(7); // 0-6 (월-일)
          final sessionDate = weekStartDate.add(Duration(days: dayOffset));

          // 미래 날짜는 건너뛰기
          if (sessionDate.isAfter(now)) continue;

          final startTime = sessionDate.subtract(Duration(hours: 1)); // 1시간 전 시작

          await client.from('routine_record').insert({
            'user_id': userId,
            'routine_id': null, // 루틴 없이 직접 기록
            'start_time': startTime.toIso8601String(),
            'end_time': sessionDate.toIso8601String(),
            'total_calories': 200 + random.nextInt(300), // 200-500 kcal
            'perceived_intensity': 5 + random.nextInt(5), // 5-9
            'session_status': 'completed',
            'is_user_reported': true,
          });
        }
      }

      // 2. 식단 기록 생성 (오늘 포함 지난 28일간, 매일)
      for (var day = 0; day <= 27; day++) {
        final date = now.subtract(Duration(days: day));
        final dateStr = DateFormat('yyyy-MM-dd').format(date);

        var dayTotalCalories = 0.0;
        var dayTotalCarbs = 0.0;
        var dayTotalProtein = 0.0;
        var dayTotalFat = 0.0;

        // 각 날짜에 2-3개의 식사 기록 생성
        final mealTypes = ['breakfast', 'lunch', 'dinner'];
        final mealsToday = 2 + random.nextInt(2); // 2-3개

        for (var mealIdx = 0; mealIdx < mealsToday; mealIdx++) {
          final calories = (400 + random.nextInt(400)).toDouble(); // 400-800 kcal
          final carbs = (50 + random.nextInt(50)).toDouble(); // 50-100g
          final protein = (20 + random.nextInt(30)).toDouble(); // 20-50g
          final fat = (15 + random.nextInt(20)).toDouble(); // 15-35g

          // meal_record 테이블에 삽입하고 ID 가져오기
          final mealRecordResponse = await client.from('meal_record').insert({
            'user_id': userId,
            'meal_date': dateStr,
            'meal_type': mealTypes[mealIdx],
            'calories': calories,
            'carbs': carbs,
            'protein': protein,
            'fat': fat,
          }).select('meal_record_id').single();

          final mealRecordId = mealRecordResponse['meal_record_id'] as int;

          // meal_component 테이블에 음식 구성요소 추가 (2-3개)
          final sampleFoods = [
            ['밥', 200.0, 300.0, 60.0, 8.0, 1.0],
            ['닭가슴살', 100.0, 110.0, 0.0, 23.0, 1.0],
            ['계란', 50.0, 70.0, 1.0, 6.0, 5.0],
            ['김치', 50.0, 15.0, 2.0, 1.0, 0.5],
            ['브로콜리', 100.0, 35.0, 7.0, 3.0, 0.5],
            ['고구마', 150.0, 130.0, 30.0, 2.0, 0.2],
          ];

          final numFoods = 2 + random.nextInt(2); // 2-3개 음식
          for (var f = 0; f < numFoods; f++) {
            final food = sampleFoods[random.nextInt(sampleFoods.length)];
            await client.from('meal_component').insert({
              'meal_record_id': mealRecordId,
              'food_code': 'MOCK${random.nextInt(1000)}',
              'food_name': food[0],
              'food_category': '일반',
              'grams': food[1],
              'calories': food[2],
              'carbs': food[3],
              'protein': food[4],
              'fat': food[5],
            });
          }

          dayTotalCalories += calories;
          dayTotalCarbs += carbs;
          dayTotalProtein += protein;
          dayTotalFat += fat;
        }

        // nutritionsummary 테이블에 일일 요약 삽입
        await client.from('nutritionsummary').insert({
          'user_id': userId,
          'date': dateStr,
          'total_calories': dayTotalCalories,
          'total_carbs': dayTotalCarbs,
          'total_protein': dayTotalProtein,
          'total_fat': dayTotalFat,
        });
      }

      // Provider 새로고침
      ref.invalidate(weeklyWorkoutStatsProviderFamily);
      ref.invalidate(monthlyWorkoutStatsProviderFamily);
      ref.invalidate(weeklyDietStatsProviderFamily);
      ref.invalidate(monthlyDietStatsProviderFamily);

      if (mounted) {
        Navigator.of(scaffoldContext, rootNavigator: true).pop(); // 로딩 다이얼로그 닫기

        ScaffoldMessenger.of(scaffoldContext).showSnackBar(
          const SnackBar(
            content: Text('목업 데이터가 생성되었습니다!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(scaffoldContext, rootNavigator: true).pop(); // 로딩 다이얼로그 닫기
        ScaffoldMessenger.of(scaffoldContext).showSnackBar(
          SnackBar(
            content: Text('오류 발생: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('통계'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'generate_mock') {
                _generateMockData();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'generate_mock',
                child: Row(
                  children: [
                    Icon(Icons.data_object, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('목업 데이터 생성'),
                  ],
                ),
              ),
            ],
          ),
        ],
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
                  label: '일평균',
                  value: '${stats.averageWorkoutsPerDay.toStringAsFixed(1)}회',
                  icon: Icons.today,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(
                  label: '소모 칼로리',
                  value: '${stats.totalCaloriesBurned}kcal',
                  icon: Icons.local_fire_department,
                  color: Colors.deepOrange,
                ),
                _StatItem(
                  label: '평균 강도',
                  value: '${stats.averageIntensity.toStringAsFixed(1)}',
                  icon: Icons.speed,
                  color: Colors.red,
                ),
                _StatItem(
                  label: '운동당 칼로리',
                  value: '${stats.averageCaloriesPerWorkout}kcal',
                  icon: Icons.bolt,
                  color: Colors.orange,
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
    final carbs = stats.averageNutrients['carbs'] ?? 0.0;
    final protein = stats.averageNutrients['protein'] ?? 0.0;
    final fat = stats.averageNutrients['fat'] ?? 0.0;

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
              '영양소 평균 (탄단지)',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(
                  label: '탄수화물',
                  value: '${carbs.toStringAsFixed(1)}g',
                  icon: Icons.grain,
                  color: Colors.brown,
                ),
                _StatItem(
                  label: '단백질',
                  value: '${protein.toStringAsFixed(1)}g',
                  icon: Icons.egg,
                  color: Colors.red[300],
                ),
                _StatItem(
                  label: '지방',
                  value: '${fat.toStringAsFixed(1)}g',
                  icon: Icons.water_drop,
                  color: Colors.yellow[700],
                ),
              ],
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
                  label: '하루 평균 식사',
                  value: '${stats.averageMealsPerDay.toStringAsFixed(1)}회',
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
        final dateLabel = '${summary.date.month}/${summary.date.day}';

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
              '$dateLabel(${weekDays[index]})',
              style: const TextStyle(
                fontSize: 10,
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
        final dateLabel = '${summary.date.month}/${summary.date.day}';

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
              '$dateLabel(${weekDays[index]})',
              style: const TextStyle(
                fontSize: 10,
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
