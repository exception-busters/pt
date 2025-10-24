import 'package:flutter_riverpod/flutter_riverpod.dart';

class MealData {
  final String food;
  final String calories;

  MealData({required this.food, required this.calories});
}

class DietData {
  final String date;
  final MealData? breakfast;
  final MealData? lunch;
  final MealData? dinner;

  DietData({
    required this.date,
    this.breakfast,
    this.lunch,
    this.dinner,
  });

  DietData copyWith({
    String? date,
    MealData? breakfast,
    MealData? lunch,
    MealData? dinner,
  }) {
    return DietData(
      date: date ?? this.date,
      breakfast: breakfast ?? this.breakfast,
      lunch: lunch ?? this.lunch,
      dinner: dinner ?? this.dinner,
    );
  }

  int get totalCalories {
    int total = 0;
    if (breakfast != null) {
      total += int.tryParse(breakfast!.calories.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    }
    if (lunch != null) {
      total += int.tryParse(lunch!.calories.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    }
    if (dinner != null) {
      total += int.tryParse(dinner!.calories.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    }
    return total;
  }
}

class DietController extends StateNotifier<DietData> {
  DietController() : super(_getInitialData());

  static DietData _getInitialData() {
    final today = DateTime.now();
    final dateString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    return DietData(date: dateString);
  }

  void updateMeal(String mealType, String food, String calories) {
    final mealData = MealData(food: food, calories: calories);
    
    switch (mealType) {
      case '아침':
        state = state.copyWith(breakfast: mealData);
        break;
      case '점심':
        state = state.copyWith(lunch: mealData);
        break;
      case '저녁':
        state = state.copyWith(dinner: mealData);
        break;
    }
  }

  void checkAndResetIfNewDay() {
    final now = DateTime.now();
    final today = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    
    if (state.date != today) {
      state = DietData(date: today);
    }
  }

  MealData? getMealData(String mealType) {
    switch (mealType) {
      case '아침':
        return state.breakfast;
      case '점심':
        return state.lunch;
      case '저녁':
        return state.dinner;
      default:
        return null;
    }
  }
}

final dietControllerProvider = StateNotifierProvider<DietController, DietData>(
  (ref) => DietController(),
);