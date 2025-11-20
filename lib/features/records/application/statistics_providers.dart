import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/statistics_models.dart';
import '../../auth/application/auth_providers.dart';
import '../../profile/application/complete_profile_providers.dart';

/// 주간 운동 통계 Provider (날짜 선택 가능)
final weeklyWorkoutStatsProviderFamily = FutureProvider.autoDispose.family<WeeklyWorkoutStats, DateTime>((ref, weekStart) async {
  print('📊 [Stats] 주간 운동 통계 Provider 호출: $weekStart');

  final authState = ref.read(authControllerProvider);
  print('📊 [Stats] Auth 상태: ${authState.isLoggedIn}');

  if (!authState.isLoggedIn) {
    print('❌ [Stats] 로그인 안됨');
    throw Exception('로그인이 필요합니다');
  }

  final weekStartMidnight = DateTime(weekStart.year, weekStart.month, weekStart.day);
  final weekEnd = weekStartMidnight.add(const Duration(days: 7));

  print('📊 [Stats] 주간 운동 통계 계산 시작: $weekStartMidnight ~ $weekEnd');
  return _calculateWeeklyWorkoutStats(weekStartMidnight, weekEnd);
});

/// 월간 운동 통계 Provider (날짜 선택 가능)
final monthlyWorkoutStatsProviderFamily = FutureProvider.autoDispose.family<MonthlyWorkoutStats, DateTime>((ref, month) async {
  final authState = ref.read(authControllerProvider);
  if (!authState.isLoggedIn) {
    throw Exception('로그인이 필요합니다');
  }

  final monthStart = DateTime(month.year, month.month, 1);
  final monthEnd = DateTime(month.year, month.month + 1, 1);

  return _calculateMonthlyWorkoutStats(monthStart, monthEnd);
});

/// 주간 식단 통계 Provider (날짜 선택 가능)
final weeklyDietStatsProviderFamily = FutureProvider.autoDispose.family<WeeklyDietStats, DateTime>((ref, weekStart) async {
  print('📊 [Stats] 주간 식단 통계 Provider 호출: $weekStart');

  final authState = ref.read(authControllerProvider);
  print('📊 [Stats] Diet Auth 상태: ${authState.isLoggedIn}');

  if (!authState.isLoggedIn) {
    print('❌ [Stats] Diet 로그인 안됨');
    throw Exception('로그인이 필요합니다');
  }

  final dietGoal = ref.read(dietGoalModelProvider);
  final targetCalories = dietGoal?.dailyCalorieTarget ?? 2000;
  print('📊 [Stats] 목표 칼로리: $targetCalories');

  final weekStartMidnight = DateTime(weekStart.year, weekStart.month, weekStart.day);
  final weekEnd = weekStartMidnight.add(const Duration(days: 7));

  print('📊 [Stats] 주간 식단 통계 계산 시작: $weekStartMidnight ~ $weekEnd');
  return _calculateWeeklyDietStats(weekStartMidnight, weekEnd, targetCalories.toDouble());
});

/// 월간 식단 통계 Provider (날짜 선택 가능)
final monthlyDietStatsProviderFamily = FutureProvider.autoDispose.family<MonthlyDietStats, DateTime>((ref, month) async {
  final authState = ref.read(authControllerProvider);
  if (!authState.isLoggedIn) {
    throw Exception('로그인이 필요합니다');
  }

  final dietGoal = ref.read(dietGoalModelProvider);
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
  print('📊 [Stats] _calculateWeeklyWorkoutStats 시작');

  final client = Supabase.instance.client;
  final userId = client.auth.currentUser?.id;

  print('📊 [Stats] userId: $userId');

  if (userId == null) {
    print('❌ [Stats] userId가 null');
    throw Exception('사용자 정보가 없습니다');
  }

  try {
    print('📊 [Stats] routine_record 조회 중...');
    // routine_record 조회 (완료된 세션만)
    final records = await client
        .from('routine_record')
        .select('*, routine(*)')
        .eq('user_id', userId)
        .eq('session_status', 'completed')
        .gte('end_time', weekStart.toIso8601String())
        .lt('end_time', weekEnd.toIso8601String())
        .order('end_time');

    print('📊 [Stats] 조회된 운동 기록: ${records.length}개');

    final totalWorkouts = records.length;
    var totalMinutes = 0;
    var totalCaloriesBurned = 0;
    var totalIntensity = 0.0;
    var intensityCount = 0;
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
      // 운동 시간 계산
      var sessionMinutes = 0;
      final routine = record['routine'];
      if (routine != null) {
        // 루틴이 있으면 세트 기반 계산 (세트당 3분)
        final exercises = routine['routine_exercise'] as List?;
        if (exercises != null) {
          for (final ex in exercises) {
            final sets = ex['sets'] as int? ?? 3;
            sessionMinutes += sets * 3;
          }
        }
      } else {
        // 루틴이 없으면 칼로리 기반 추정 (100kcal당 10분)
        final calories = record['total_calories'] as num?;
        if (calories != null) {
          sessionMinutes = (calories / 100 * 10).round();
        } else {
          // 칼로리도 없으면 기본 45분
          sessionMinutes = 45;
        }
      }
      totalMinutes += sessionMinutes;

      // 소모 칼로리 및 인지 강도 추가
      final calories = record['total_calories'] as int?;
      if (calories != null) {
        totalCaloriesBurned += calories;
      }

      final intensity = record['perceived_intensity'] as int?;
      if (intensity != null) {
        totalIntensity += intensity.toDouble();
        intensityCount++;
      }

      // 일별 요약 업데이트
      final endTime = record['end_time'] != null
          ? DateTime.parse(record['end_time'] as String)
          : null;
      if (endTime == null) continue;
      final dayIndex = endTime.difference(weekStart).inDays;
      if (dayIndex >= 0 && dayIndex < 7) {
        dailySummaries[dayIndex] = DailyWorkoutSummary(
          date: dailySummaries[dayIndex].date,
          workoutCount: dailySummaries[dayIndex].workoutCount + 1,
          totalMinutes: dailySummaries[dayIndex].totalMinutes + sessionMinutes,
          hasWorkout: true,
        );
      }
    }

    final averageIntensity = intensityCount > 0 ? totalIntensity / intensityCount : 0.0;

    print('📊 [Stats] 주간 운동 통계 계산 완료 - 총 ${totalWorkouts}회, ${totalMinutes}분, ${totalCaloriesBurned}kcal');

    return WeeklyWorkoutStats(
      weekStart: weekStart,
      weekEnd: weekEnd,
      totalWorkouts: totalWorkouts,
      totalMinutes: totalMinutes,
      completedRoutines: totalWorkouts,
      totalRoutines: totalWorkouts,
      exercisesByBodyPart: exercisesByBodyPart,
      dailySummaries: dailySummaries,
      totalCaloriesBurned: totalCaloriesBurned,
      averageIntensity: averageIntensity,
    );
  } catch (e) {
    print('❌ [Stats] 주간 운동 통계 계산 실패: $e');
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
        .from('routine_record')
        .select('*')
        .eq('user_id', userId)
        .eq('session_status', 'completed')
        .gte('end_time', monthStart.toIso8601String())
        .lt('end_time', monthEnd.toIso8601String())
        .order('end_time');

    final totalWorkouts = records.length;
    var totalCaloriesBurned = 0;
    var totalIntensity = 0.0;
    var intensityCount = 0;
    final exercisesByBodyPart = <String, int>{};
    final exercisesByDifficulty = <String, int>{};

    // 칼로리와 인지 강도 계산
    for (final record in records) {
      final calories = record['total_calories'] as int?;
      if (calories != null) {
        totalCaloriesBurned += calories;
      }

      final intensity = record['perceived_intensity'] as int?;
      if (intensity != null) {
        totalIntensity += intensity.toDouble();
        intensityCount++;
      }
    }

    final averageIntensity = intensityCount > 0 ? totalIntensity / intensityCount : 0.0;

    // 주별 요약 계산
    final weeklySummaries = <WeeklyWorkoutSummary>[];
    var currentWeekStart = monthStart;
    var weekNumber = 1;

    while (currentWeekStart.isBefore(monthEnd)) {
      final currentWeekEnd = currentWeekStart.add(const Duration(days: 7));
      final weekEndCapped = currentWeekEnd.isAfter(monthEnd) ? monthEnd : currentWeekEnd;

      final weekRecords = records.where((record) {
        final endTime = record['end_time'] != null
            ? DateTime.parse(record['end_time'] as String)
            : null;
        if (endTime == null) return false;
        return endTime.isAfter(currentWeekStart.subtract(const Duration(seconds: 1))) &&
               endTime.isBefore(weekEndCapped);
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
      totalCaloriesBurned: totalCaloriesBurned,
      averageIntensity: averageIntensity,
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

    // meal_record 조회 (끼니 수 계산용)
    final mealRecords = await client
        .from('meal_record')
        .select('meal_date')
        .eq('user_id', userId)
        .gte('meal_date', weekStart.toIso8601String().split('T')[0])
        .lt('meal_date', weekEnd.toIso8601String().split('T')[0]);

    var totalCalories = 0.0;
    var totalCarbs = 0.0;
    var totalProtein = 0.0;
    var totalFat = 0.0;
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

    // 날짜별 끼니 수 계산
    final Map<String, int> mealCountsByDate = {};
    for (final meal in mealRecords) {
      final dateStr = meal['meal_date'] as String;
      mealCountsByDate[dateStr] = (mealCountsByDate[dateStr] ?? 0) + 1;
    }

    for (final summary in summaries) {
      final calories = (summary['total_calories'] as num?)?.toDouble() ?? 0;
      final carbs = (summary['total_carbs'] as num?)?.toDouble() ?? 0;
      final protein = (summary['total_protein'] as num?)?.toDouble() ?? 0;
      final fat = (summary['total_fat'] as num?)?.toDouble() ?? 0;

      totalCalories += calories;
      totalCarbs += carbs;
      totalProtein += protein;
      totalFat += fat;

      final date = DateTime.parse(summary['date'] as String);
      final dateStr = summary['date'] as String;
      final dayIndex = date.difference(weekStart).inDays;
      if (dayIndex >= 0 && dayIndex < 7) {
        final mealsThisDay = mealCountsByDate[dateStr] ?? 0;
        dailySummaries[dayIndex] = DailyDietSummary(
          date: date,
          mealCount: mealsThisDay,
          totalCalories: calories,
          hasMeals: mealsThisDay > 0,
        );
      }
    }

    final totalMeals = mealCountsByDate.values.fold(0, (sum, count) => sum + count);

    final averageCalories = summaries.isEmpty ? 0.0 : totalCalories / 7;
    final averageCarbs = summaries.isEmpty ? 0.0 : totalCarbs / 7;
    final averageProtein = summaries.isEmpty ? 0.0 : totalProtein / 7;
    final averageFat = summaries.isEmpty ? 0.0 : totalFat / 7;

    return WeeklyDietStats(
      weekStart: weekStart,
      weekEnd: weekEnd,
      totalMeals: totalMeals,
      averageCalories: averageCalories,
      targetCalories: targetCalories,
      averageNutrients: {
        'carbs': averageCarbs,
        'protein': averageProtein,
        'fat': averageFat,
      },
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

    // meal_record 조회 (끼니 수 계산용)
    final mealRecords = await client
        .from('meal_record')
        .select('meal_date')
        .eq('user_id', userId)
        .gte('meal_date', monthStart.toIso8601String().split('T')[0])
        .lt('meal_date', monthEnd.toIso8601String().split('T')[0]);

    // 날짜별 끼니 수 계산
    final Map<String, int> mealCountsByDate = {};
    for (final meal in mealRecords) {
      final dateStr = meal['meal_date'] as String;
      mealCountsByDate[dateStr] = (mealCountsByDate[dateStr] ?? 0) + 1;
    }

    var totalCalories = 0.0;
    var totalCarbs = 0.0;
    var totalProtein = 0.0;
    var totalFat = 0.0;

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
        final dateStr = summary['date'] as String;
        weekMeals += mealCountsByDate[dateStr] ?? 0;
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
      totalCarbs += (summary['total_carbs'] as num?)?.toDouble() ?? 0;
      totalProtein += (summary['total_protein'] as num?)?.toDouble() ?? 0;
      totalFat += (summary['total_fat'] as num?)?.toDouble() ?? 0;
    }

    final totalMeals = mealCountsByDate.values.fold(0, (sum, count) => sum + count);

    final daysInMonth = monthEnd.difference(monthStart).inDays;
    final averageCalories = daysInMonth == 0 ? 0.0 : totalCalories / daysInMonth;
    final averageCarbs = daysInMonth == 0 ? 0.0 : totalCarbs / daysInMonth;
    final averageProtein = daysInMonth == 0 ? 0.0 : totalProtein / daysInMonth;
    final averageFat = daysInMonth == 0 ? 0.0 : totalFat / daysInMonth;

    return MonthlyDietStats(
      monthStart: monthStart,
      monthEnd: monthEnd,
      totalMeals: totalMeals,
      averageCalories: averageCalories,
      targetCalories: targetCalories,
      averageNutrients: {
        'carbs': averageCarbs,
        'protein': averageProtein,
        'fat': averageFat,
      },
      weeklySummaries: weeklySummaries,
    );
  } catch (e) {
    print('월간 식단 통계 계산 실패: $e');
    rethrow;
  }
}
