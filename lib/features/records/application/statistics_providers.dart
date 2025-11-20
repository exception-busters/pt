import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/statistics_models.dart';
import '../../auth/application/auth_providers.dart';
import '../../profile/application/complete_profile_providers.dart';

/// 주간 운동 통계 Provider (날짜 선택 가능)
final weeklyWorkoutStatsProviderFamily = FutureProvider.autoDispose.family<WeeklyWorkoutStats, DateTime>((ref, weekStart) async {
  final authState = ref.watch(authControllerProvider);
  if (!authState.isLoggedIn) {
    throw Exception('로그인이 필요합니다');
  }

  final weekStartMidnight = DateTime(weekStart.year, weekStart.month, weekStart.day);
  final weekEnd = weekStartMidnight.add(const Duration(days: 7));

  return _calculateWeeklyWorkoutStats(weekStartMidnight, weekEnd);
});

/// 월간 운동 통계 Provider (날짜 선택 가능)
final monthlyWorkoutStatsProviderFamily = FutureProvider.autoDispose.family<MonthlyWorkoutStats, DateTime>((ref, month) async {
  final authState = ref.watch(authControllerProvider);
  if (!authState.isLoggedIn) {
    throw Exception('로그인이 필요합니다');
  }

  final monthStart = DateTime(month.year, month.month, 1);
  final monthEnd = DateTime(month.year, month.month + 1, 1);

  return _calculateMonthlyWorkoutStats(monthStart, monthEnd);
});

/// 주간 식단 통계 Provider (날짜 선택 가능)
final weeklyDietStatsProviderFamily = FutureProvider.autoDispose.family<WeeklyDietStats, DateTime>((ref, weekStart) async {
  final authState = ref.watch(authControllerProvider);
  if (!authState.isLoggedIn) {
    throw Exception('로그인이 필요합니다');
  }

  final dietGoal = ref.watch(dietGoalModelProvider);
  final targetCalories = dietGoal?.dailyCalorieTarget ?? 2000;

  final weekStartMidnight = DateTime(weekStart.year, weekStart.month, weekStart.day);
  final weekEnd = weekStartMidnight.add(const Duration(days: 7));

  return _calculateWeeklyDietStats(weekStartMidnight, weekEnd, targetCalories.toDouble());
});

/// 월간 식단 통계 Provider (날짜 선택 가능)
final monthlyDietStatsProviderFamily = FutureProvider.autoDispose.family<MonthlyDietStats, DateTime>((ref, month) async {
  final authState = ref.watch(authControllerProvider);
  if (!authState.isLoggedIn) {
    throw Exception('로그인이 필요합니다');
  }

  final dietGoal = ref.watch(dietGoalModelProvider);
  final targetCalories = dietGoal?.dailyCalorieTarget ?? 2000;

  final monthStart = DateTime(month.year, month.month, 1);
  final monthEnd = DateTime(month.year, month.month + 1, 1);

  return _calculateMonthlyDietStats(monthStart, monthEnd, targetCalories.toDouble());
});

// ==================== 내부 계산 함수 ====================

Future<WeeklyWorkoutStats> _calculateWeeklyWorkoutStats(
  DateTime weekStart,
  DateTime weekEnd,
) async {
  final client = Supabase.instance.client;
  final userId = client.auth.currentUser?.id;

  if (userId == null) {
    throw Exception('사용자 정보가 없습니다');
  }

  try {
    // workout_records 조회
    final records = await client
        .from('workout_records')
        .select('*, routines(*)')
        .eq('user_id', userId)
        .gte('completed_at', weekStart.toIso8601String())
        .lt('completed_at', weekEnd.toIso8601String())
        .order('completed_at');

    final totalWorkouts = records.length;
    var totalMinutes = 0;
    final exercisesByBodyPart = <String, int>{};

    // 일별 요약 초기화
    final dailySummaries = <DailyWorkoutSummary>[];
    for (var i = 0; i < 7; i++) {
      final date = weekStart.add(Duration(days: i));
      dailySummaries.add(DailyWorkoutSummary(
        date: date,
        workoutCount: 0,
        totalMinutes: 0,
        hasWorkout: false,
      ));
    }

    // 기록 처리
    for (final record in records) {
      // 운동 시간 계산 (추정: 세트당 3분)
      final routine = record['routines'];
      if (routine != null) {
        final exercises = routine['routine_exercise'] as List?;
        if (exercises != null) {
          for (final ex in exercises) {
            final sets = ex['sets'] as int? ?? 3;
            totalMinutes += sets * 3;
          }
        }
      }

      // 일별 요약 업데이트
      final completedAt = DateTime.parse(record['completed_at'] as String);
      final dayIndex = completedAt.difference(weekStart).inDays;
      if (dayIndex >= 0 && dayIndex < 7) {
        dailySummaries[dayIndex] = DailyWorkoutSummary(
          date: dailySummaries[dayIndex].date,
          workoutCount: dailySummaries[dayIndex].workoutCount + 1,
          totalMinutes: dailySummaries[dayIndex].totalMinutes + 30, // 추정
          hasWorkout: true,
        );
      }
    }

    return WeeklyWorkoutStats(
      weekStart: weekStart,
      weekEnd: weekEnd,
      totalWorkouts: totalWorkouts,
      totalMinutes: totalMinutes,
      completedRoutines: totalWorkouts,
      totalRoutines: totalWorkouts,
      exercisesByBodyPart: exercisesByBodyPart,
      dailySummaries: dailySummaries,
    );
  } catch (e) {
    print('주간 운동 통계 계산 실패: $e');
    rethrow;
  }
}

Future<MonthlyWorkoutStats> _calculateMonthlyWorkoutStats(
  DateTime monthStart,
  DateTime monthEnd,
) async {
  final client = Supabase.instance.client;
  final userId = client.auth.currentUser?.id;

  if (userId == null) {
    throw Exception('사용자 정보가 없습니다');
  }

  try {
    final records = await client
        .from('workout_records')
        .select('*')
        .eq('user_id', userId)
        .gte('completed_at', monthStart.toIso8601String())
        .lt('completed_at', monthEnd.toIso8601String())
        .order('completed_at');

    final totalWorkouts = records.length;
    final exercisesByBodyPart = <String, int>{};
    final exercisesByDifficulty = <String, int>{};

    // 주별 요약 계산
    final weeklySummaries = <WeeklyWorkoutSummary>[];
    var currentWeekStart = monthStart;
    var weekNumber = 1;

    while (currentWeekStart.isBefore(monthEnd)) {
      final currentWeekEnd = currentWeekStart.add(const Duration(days: 7));
      final weekEndCapped = currentWeekEnd.isAfter(monthEnd) ? monthEnd : currentWeekEnd;

      final weekRecords = records.where((record) {
        final completedAt = DateTime.parse(record['completed_at'] as String);
        return completedAt.isAfter(currentWeekStart.subtract(const Duration(seconds: 1))) &&
               completedAt.isBefore(weekEndCapped);
      }).toList();

      weeklySummaries.add(WeeklyWorkoutSummary(
        weekNumber: weekNumber,
        workoutCount: weekRecords.length,
        totalMinutes: weekRecords.length * 45, // 추정
      ));

      currentWeekStart = currentWeekEnd;
      weekNumber++;
    }

    return MonthlyWorkoutStats(
      monthStart: monthStart,
      monthEnd: monthEnd,
      totalWorkouts: totalWorkouts,
      totalMinutes: totalWorkouts * 45, // 추정
      completedRoutines: totalWorkouts,
      totalRoutines: totalWorkouts,
      exercisesByBodyPart: exercisesByBodyPart,
      weeklySummaries: weeklySummaries,
      exercisesByDifficulty: exercisesByDifficulty,
    );
  } catch (e) {
    print('월간 운동 통계 계산 실패: $e');
    rethrow;
  }
}

Future<WeeklyDietStats> _calculateWeeklyDietStats(
  DateTime weekStart,
  DateTime weekEnd,
  double targetCalories,
) async {
  final client = Supabase.instance.client;
  final userId = client.auth.currentUser?.id;

  if (userId == null) {
    throw Exception('사용자 정보가 없습니다');
  }

  try {
    // nutrition_summary 조회
    final summaries = await client
        .from('nutritionsummary')
        .select('*')
        .eq('user_id', userId)
        .gte('date', weekStart.toIso8601String().split('T')[0])
        .lt('date', weekEnd.toIso8601String().split('T')[0]);

    var totalCalories = 0.0;
    var mealCount = 0;
    final dailySummaries = <DailyDietSummary>[];

    // 일별 요약 초기화
    for (var i = 0; i < 7; i++) {
      final date = weekStart.add(Duration(days: i));
      dailySummaries.add(DailyDietSummary(
        date: date,
        mealCount: 0,
        totalCalories: 0,
        hasMeals: false,
      ));
    }

    for (final summary in summaries) {
      final calories = (summary['total_calories'] as num?)?.toDouble() ?? 0;
      final meals = (summary['total_meals'] as int?) ?? 0;
      totalCalories += calories;
      mealCount += meals;

      final date = DateTime.parse(summary['date'] as String);
      final dayIndex = date.difference(weekStart).inDays;
      if (dayIndex >= 0 && dayIndex < 7) {
        dailySummaries[dayIndex] = DailyDietSummary(
          date: date,
          mealCount: meals,
          totalCalories: calories,
          hasMeals: meals > 0,
        );
      }
    }

    final averageCalories = summaries.isEmpty ? 0.0 : totalCalories / 7;

    return WeeklyDietStats(
      weekStart: weekStart,
      weekEnd: weekEnd,
      totalMeals: mealCount,
      averageCalories: averageCalories,
      targetCalories: targetCalories,
      averageNutrients: {},
      dailySummaries: dailySummaries,
    );
  } catch (e) {
    print('주간 식단 통계 계산 실패: $e');
    rethrow;
  }
}

Future<MonthlyDietStats> _calculateMonthlyDietStats(
  DateTime monthStart,
  DateTime monthEnd,
  double targetCalories,
) async {
  final client = Supabase.instance.client;
  final userId = client.auth.currentUser?.id;

  if (userId == null) {
    throw Exception('사용자 정보가 없습니다');
  }

  try {
    final summaries = await client
        .from('nutritionsummary')
        .select('*')
        .eq('user_id', userId)
        .gte('date', monthStart.toIso8601String().split('T')[0])
        .lt('date', monthEnd.toIso8601String().split('T')[0])
        .order('date');

    var totalCalories = 0.0;
    var mealCount = 0;

    // 주별 요약 계산
    final weeklySummaries = <WeeklyDietSummary>[];
    var currentWeekStart = monthStart;
    var weekNumber = 1;

    while (currentWeekStart.isBefore(monthEnd)) {
      final currentWeekEnd = currentWeekStart.add(const Duration(days: 7));
      final weekEndCapped = currentWeekEnd.isAfter(monthEnd) ? monthEnd : currentWeekEnd;

      final weekSummaries = summaries.where((summary) {
        final date = DateTime.parse(summary['date'] as String);
        return date.isAfter(currentWeekStart.subtract(const Duration(seconds: 1))) &&
               date.isBefore(weekEndCapped);
      }).toList();

      var weekCalories = 0.0;
      var weekMeals = 0;
      for (final summary in weekSummaries) {
        weekCalories += (summary['total_calories'] as num?)?.toDouble() ?? 0;
        weekMeals += (summary['total_meals'] as int?) ?? 0;
      }

      final weekDays = weekSummaries.length > 0 ? weekSummaries.length : 1;
      weeklySummaries.add(WeeklyDietSummary(
        weekNumber: weekNumber,
        averageCalories: weekCalories / weekDays,
        mealCount: weekMeals,
      ));

      currentWeekStart = currentWeekEnd;
      weekNumber++;
    }

    for (final summary in summaries) {
      totalCalories += (summary['total_calories'] as num?)?.toDouble() ?? 0;
      mealCount += (summary['total_meals'] as int?) ?? 0;
    }

    final daysInMonth = monthEnd.difference(monthStart).inDays;
    final averageCalories = daysInMonth == 0 ? 0.0 : totalCalories / daysInMonth;

    return MonthlyDietStats(
      monthStart: monthStart,
      monthEnd: monthEnd,
      totalMeals: mealCount,
      averageCalories: averageCalories,
      targetCalories: targetCalories,
      averageNutrients: {},
      weeklySummaries: weeklySummaries,
    );
  } catch (e) {
    print('월간 식단 통계 계산 실패: $e');
    rethrow;
  }
}
