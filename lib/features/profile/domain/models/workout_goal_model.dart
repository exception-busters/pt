enum WorkoutGoalType { weightLoss, muscleGain, endurance, strength, general }
enum WorkoutLevel { beginner, intermediate, advanced }
enum ExperienceDuration {
  lessThan6Months,    // 6개월 미만
  sixMonthsToYear,    // 6개월-1년
  oneToTwoYears,      // 1-2년
  moreThanTwoYears    // 2년 이상
}

class WorkoutGoalModel {
  final String userId;
  final WorkoutGoalType? goalType;
  final WorkoutLevel? level;
  final ExperienceDuration? experienceDuration;
  final int? weeklyDays;
  final int? dailyDurationMin;
  final List<String>? preferredTypes;

  const WorkoutGoalModel({
    required this.userId,
    this.goalType,
    this.level,
    this.experienceDuration,
    this.weeklyDays,
    this.dailyDurationMin,
    this.preferredTypes,
  });

  factory WorkoutGoalModel.fromJson(Map<String, dynamic> json) {
    return WorkoutGoalModel(
      userId: json['user_id'] ?? '',
      goalType: json['goal_type'] != null
          ? WorkoutGoalType.values.firstWhere(
              (g) => g.name == json['goal_type'],
              orElse: () => WorkoutGoalType.general,
            )
          : null,
      level: json['level'] != null
          ? WorkoutLevel.values.firstWhere(
              (l) => l.name == json['level'],
              orElse: () => WorkoutLevel.beginner,
            )
          : null,
      experienceDuration: json['experience_duration'] != null
          ? ExperienceDuration.values.firstWhere(
              (e) => e.name == json['experience_duration'],
              orElse: () => ExperienceDuration.lessThan6Months,
            )
          : null,
      weeklyDays: json['weekly_days']?.toInt(),
      dailyDurationMin: json['daily_duration_min']?.toInt(),
      preferredTypes: json['preferred_types'] != null
          ? List<String>.from(json['preferred_types'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'goal_type': goalType?.name,
      'level': level?.name,
      'experience_duration': experienceDuration?.name,
      'weekly_days': weeklyDays,
      'daily_duration_min': dailyDurationMin,
      'preferred_types': preferredTypes,
    };
  }

  WorkoutGoalModel copyWith({
    String? userId,
    WorkoutGoalType? goalType,
    WorkoutLevel? level,
    ExperienceDuration? experienceDuration,
    int? weeklyDays,
    int? dailyDurationMin,
    List<String>? preferredTypes,
  }) {
    return WorkoutGoalModel(
      userId: userId ?? this.userId,
      goalType: goalType ?? this.goalType,
      level: level ?? this.level,
      experienceDuration: experienceDuration ?? this.experienceDuration,
      weeklyDays: weeklyDays ?? this.weeklyDays,
      dailyDurationMin: dailyDurationMin ?? this.dailyDurationMin,
      preferredTypes: preferredTypes ?? this.preferredTypes,
    );
  }
}