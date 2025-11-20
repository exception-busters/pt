/// 주간 운동 통계
class WeeklyWorkoutStats {
  final DateTime weekStart;
  final DateTime weekEnd;
  final int totalWorkouts;
  final int totalMinutes;
  final int completedRoutines;
  final int totalRoutines;
  final Map<String, int> exercisesByBodyPart;
  final List<DailyWorkoutSummary> dailySummaries;
  final int totalCaloriesBurned;
  final double averageIntensity;

  WeeklyWorkoutStats({
    required this.weekStart,
    required this.weekEnd,
    required this.totalWorkouts,
    required this.totalMinutes,
    required this.completedRoutines,
    required this.totalRoutines,
    required this.exercisesByBodyPart,
    required this.dailySummaries,
    this.totalCaloriesBurned = 0,
    this.averageIntensity = 0.0,
  });

  double get completionRate {
    if (totalRoutines == 0) return 0.0;
    return (completedRoutines / totalRoutines) * 100;
  }

  int get averageMinutesPerDay {
    if (totalWorkouts == 0) return 0;
    return totalMinutes ~/ 7;
  }

  double get averageWorkoutsPerDay {
    return totalWorkouts / 7.0;
  }

  int get averageCaloriesPerWorkout {
    if (totalWorkouts == 0) return 0;
    return totalCaloriesBurned ~/ totalWorkouts;
  }
}

/// 일별 운동 요약
class DailyWorkoutSummary {
  final DateTime date;
  final int workoutCount;
  final int totalMinutes;
  final bool hasWorkout;

  DailyWorkoutSummary({
    required this.date,
    required this.workoutCount,
    required this.totalMinutes,
    required this.hasWorkout,
  });
}

/// 월간 운동 통계
class MonthlyWorkoutStats {
  final DateTime monthStart;
  final DateTime monthEnd;
  final int totalWorkouts;
  final int totalMinutes;
  final int completedRoutines;
  final int totalRoutines;
  final Map<String, int> exercisesByBodyPart;
  final List<WeeklyWorkoutSummary> weeklySummaries;
  final Map<String, int> exercisesByDifficulty;
  final int totalCaloriesBurned;
  final double averageIntensity;

  MonthlyWorkoutStats({
    required this.monthStart,
    required this.monthEnd,
    required this.totalWorkouts,
    required this.totalMinutes,
    required this.completedRoutines,
    required this.totalRoutines,
    required this.exercisesByBodyPart,
    required this.weeklySummaries,
    required this.exercisesByDifficulty,
    this.totalCaloriesBurned = 0,
    this.averageIntensity = 0.0,
  });

  double get completionRate {
    if (totalRoutines == 0) return 0.0;
    return (completedRoutines / totalRoutines) * 100;
  }

  double get averageWorkoutsPerWeek {
    // 월의 실제 주 수 계산
    final weeks = (monthEnd.difference(monthStart).inDays / 7).ceil();
    if (weeks == 0) return 0.0;
    return totalWorkouts / weeks;
  }

  double get averageWorkoutsPerDay {
    final days = monthEnd.difference(monthStart).inDays;
    if (days == 0) return 0.0;
    return totalWorkouts / days;
  }

  int get averageCaloriesPerWorkout {
    if (totalWorkouts == 0) return 0;
    return totalCaloriesBurned ~/ totalWorkouts;
  }
}

/// 주별 운동 요약 (월간 통계용)
class WeeklyWorkoutSummary {
  final int weekNumber;
  final int workoutCount;
  final int totalMinutes;

  WeeklyWorkoutSummary({
    required this.weekNumber,
    required this.workoutCount,
    required this.totalMinutes,
  });
}

/// 주간 식단 통계
class WeeklyDietStats {
  final DateTime weekStart;
  final DateTime weekEnd;
  final int totalMeals;
  final double averageCalories;
  final double targetCalories;
  final Map<String, double> averageNutrients;
  final List<DailyDietSummary> dailySummaries;

  WeeklyDietStats({
    required this.weekStart,
    required this.weekEnd,
    required this.totalMeals,
    required this.averageCalories,
    required this.targetCalories,
    required this.averageNutrients,
    required this.dailySummaries,
  });

  double get calorieAchievementRate {
    if (targetCalories == 0) return 0.0;
    return (averageCalories / targetCalories) * 100;
  }

  bool get isOnTrack {
    final rate = calorieAchievementRate;
    return rate >= 90 && rate <= 110;
  }
}

/// 일별 식단 요약
class DailyDietSummary {
  final DateTime date;
  final int mealCount;
  final double totalCalories;
  final bool hasMeals;

  DailyDietSummary({
    required this.date,
    required this.mealCount,
    required this.totalCalories,
    required this.hasMeals,
  });
}

/// 월간 식단 통계
class MonthlyDietStats {
  final DateTime monthStart;
  final DateTime monthEnd;
  final int totalMeals;
  final double averageCalories;
  final double targetCalories;
  final Map<String, double> averageNutrients;
  final List<WeeklyDietSummary> weeklySummaries;

  MonthlyDietStats({
    required this.monthStart,
    required this.monthEnd,
    required this.totalMeals,
    required this.averageCalories,
    required this.targetCalories,
    required this.averageNutrients,
    required this.weeklySummaries,
  });

  double get calorieAchievementRate {
    if (targetCalories == 0) return 0.0;
    return (averageCalories / targetCalories) * 100;
  }

  double get averageMealsPerDay {
    final days = monthEnd.difference(monthStart).inDays;
    if (days == 0) return 0.0;
    return totalMeals / days;
  }
}

/// 주별 식단 요약 (월간 통계용)
class WeeklyDietSummary {
  final int weekNumber;
  final double averageCalories;
  final int mealCount;

  WeeklyDietSummary({
    required this.weekNumber,
    required this.averageCalories,
    required this.mealCount,
  });
}
