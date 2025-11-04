enum Gender { male, female }

enum WorkoutGoal { weightLoss, muscleGain, fitnessImprovement, healthMaintenance }

enum WorkoutLevel { beginner, intermediate, advanced }

class OnboardingData {
  final Gender? gender;
  final int? age;
  final double? weight;
  final double? height;
  final WorkoutGoal? workoutGoal;
  final WorkoutLevel? workoutLevel;

  const OnboardingData({
    this.gender,
    this.age,
    this.weight,
    this.height,
    this.workoutGoal,
    this.workoutLevel,
  });

  OnboardingData copyWith({
    Gender? gender,
    int? age,
    double? weight,
    double? height,
    WorkoutGoal? workoutGoal,
    WorkoutLevel? workoutLevel,
  }) {
    return OnboardingData(
      gender: gender ?? this.gender,
      age: age ?? this.age,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      workoutGoal: workoutGoal ?? this.workoutGoal,
      workoutLevel: workoutLevel ?? this.workoutLevel,
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
    };
  }

  bool get isComplete {
    return gender != null &&
        age != null &&
        weight != null &&
        height != null &&
        workoutGoal != null &&
        workoutLevel != null;
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
