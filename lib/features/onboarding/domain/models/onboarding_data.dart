enum Gender { male, female }

enum WorkoutGoal { weightLoss, muscleGain, fitnessImprovement, healthMaintenance }

enum WorkoutLevel { beginner, intermediate, advanced }

enum ExperienceDuration {
  lessThan6Months,    // 6개월 미만
  sixMonthsToYear,    // 6개월~1년
  oneToTwoYears,      // 1~2년
  moreThanTwoYears    // 2년 이상
}

enum DietGoal { weightLoss, muscleGain, healthMaintenance }

enum MealsPerDay { two, three, four, five }

class OnboardingData {
  final Gender? gender;
  final int? age;
  final double? weight;
  final double? height;
  final WorkoutGoal? workoutGoal;
  final WorkoutLevel? workoutLevel;
  final ExperienceDuration? experienceDuration;
  final DietGoal? dietGoal;
  final MealsPerDay? mealsPerDay;
  final int? targetCalories;

  const OnboardingData({
    this.gender,
    this.age,
    this.weight,
    this.height,
    this.workoutGoal,
    this.workoutLevel,
    this.experienceDuration,
    this.dietGoal,
    this.mealsPerDay,
    this.targetCalories,
  });

  OnboardingData copyWith({
    Gender? gender,
    int? age,
    double? weight,
    double? height,
    WorkoutGoal? workoutGoal,
    WorkoutLevel? workoutLevel,
    ExperienceDuration? experienceDuration,
    DietGoal? dietGoal,
    MealsPerDay? mealsPerDay,
    int? targetCalories,
  }) {
    return OnboardingData(
      gender: gender ?? this.gender,
      age: age ?? this.age,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      workoutGoal: workoutGoal ?? this.workoutGoal,
      workoutLevel: workoutLevel ?? this.workoutLevel,
      experienceDuration: experienceDuration ?? this.experienceDuration,
      dietGoal: dietGoal ?? this.dietGoal,
      mealsPerDay: mealsPerDay ?? this.mealsPerDay,
      targetCalories: targetCalories ?? this.targetCalories,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'gender': gender?.name,
      'age': age,
      'weight': weight,
      'height': height,
      'workout_goal': workoutGoal?.name,
      'workout_level': workoutLevel?.name,
      'experience_duration': experienceDuration?.name,
      'diet_goal': dietGoal?.name,
      'meals_per_day': mealsPerDay?.value,
      'target_calories': targetCalories,
    };
  }

  bool get isComplete {
    return gender != null &&
        age != null &&
        weight != null &&
        height != null &&
        workoutGoal != null &&
        workoutLevel != null &&
        experienceDuration != null &&
        dietGoal != null &&
        mealsPerDay != null;
  }
}

extension GenderExtension on Gender {
  String get displayName {
    switch (this) {
      case Gender.male:
        return '남성';
      case Gender.female:
        return '여성';
    }
  }
}

extension WorkoutGoalExtension on WorkoutGoal {
  String get displayName {
    switch (this) {
      case WorkoutGoal.weightLoss:
        return '다이어트';
      case WorkoutGoal.muscleGain:
        return '근력향상';
      case WorkoutGoal.fitnessImprovement:
        return '건강유지';
      case WorkoutGoal.healthMaintenance:
        return '건강유지';
    }
  }
}

extension WorkoutLevelExtension on WorkoutLevel {
  String get displayName {
    switch (this) {
      case WorkoutLevel.beginner:
        return '초급';
      case WorkoutLevel.intermediate:
        return '중급';
      case WorkoutLevel.advanced:
        return '고급';
    }
  }
}

extension ExperienceDurationExtension on ExperienceDuration {
  String get displayName {
    switch (this) {
      case ExperienceDuration.lessThan6Months:
        return '6개월 미만';
      case ExperienceDuration.sixMonthsToYear:
        return '6개월~1년';
      case ExperienceDuration.oneToTwoYears:
        return '1~2년';
      case ExperienceDuration.moreThanTwoYears:
        return '2년 이상';
    }
  }
}

extension DietGoalExtension on DietGoal {
  String get displayName {
    switch (this) {
      case DietGoal.weightLoss:
        return '체중 감량';
      case DietGoal.muscleGain:
        return '근육 증가';
      case DietGoal.healthMaintenance:
        return '건강 유지';
    }
  }
}

extension MealsPerDayExtension on MealsPerDay {
  String get displayName {
    switch (this) {
      case MealsPerDay.two:
        return '하루 2끼';
      case MealsPerDay.three:
        return '하루 3끼';
      case MealsPerDay.four:
        return '하루 4끼';
      case MealsPerDay.five:
        return '하루 5끼';
    }
  }

  int get value {
    switch (this) {
      case MealsPerDay.two:
        return 2;
      case MealsPerDay.three:
        return 3;
      case MealsPerDay.four:
        return 4;
      case MealsPerDay.five:
        return 5;
    }
  }
}
