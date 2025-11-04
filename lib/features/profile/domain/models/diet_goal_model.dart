enum DietType { balanced, lowCarb, highProtein, vegetarian, vegan, keto }

class DietGoalModel {
  final String userId;
  final int? dailyCalorieTarget;
  final DietType? dietType;
  final int? mealsPerDay;
  final int? dailyWaterMl;
  final List<String>? dietaryRestrictions;

  const DietGoalModel({
    required this.userId,
    this.dailyCalorieTarget,
    this.dietType,
    this.mealsPerDay,
    this.dailyWaterMl,
    this.dietaryRestrictions,
  });

  factory DietGoalModel.fromJson(Map<String, dynamic> json) {
    return DietGoalModel(
      userId: json['user_id'] ?? '',
      dailyCalorieTarget: json['daily_calorie_target']?.toInt(),
      dietType: json['diet_type'] != null
          ? DietType.values.firstWhere(
              (d) => d.name == json['diet_type'],
              orElse: () => DietType.balanced,
            )
          : null,
      mealsPerDay: json['meals_per_day']?.toInt(),
      dailyWaterMl: json['daily_water_ml']?.toInt(),
      dietaryRestrictions: json['dietary_restrictions'] != null
          ? List<String>.from(json['dietary_restrictions'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'daily_calorie_target': dailyCalorieTarget,
      'diet_type': dietType?.name,
      'meals_per_day': mealsPerDay,
      'daily_water_ml': dailyWaterMl,
      'dietary_restrictions': dietaryRestrictions,
    };
  }

  DietGoalModel copyWith({
    String? userId,
    int? dailyCalorieTarget,
    DietType? dietType,
    int? mealsPerDay,
    int? dailyWaterMl,
    List<String>? dietaryRestrictions,
  }) {
    return DietGoalModel(
      userId: userId ?? this.userId,
      dailyCalorieTarget: dailyCalorieTarget ?? this.dailyCalorieTarget,
      dietType: dietType ?? this.dietType,
      mealsPerDay: mealsPerDay ?? this.mealsPerDay,
      dailyWaterMl: dailyWaterMl ?? this.dailyWaterMl,
      dietaryRestrictions: dietaryRestrictions ?? this.dietaryRestrictions,
    );
  }
}