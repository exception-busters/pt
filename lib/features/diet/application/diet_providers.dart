import 'package:flutter_riverpod/flutter_riverpod.dart';

class MealData {
  final String food;
  final String calories;

  MealData({required this.food, required this.calories});
}

class DietRecommendationException implements Exception {
  const DietRecommendationException([this.message]);

  final String? message;

  @override
  String toString() => message ?? 'DietRecommendationException';
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

final dietRecommendationProvider = Provider<String>((ref) {
  final dietData = ref.watch(dietControllerProvider);
  final total = dietData.totalCalories;
  const goal = 1800;
  final remaining = goal - total;

  if (total == 0) {
    return '첫 식단을 기록해보세요!';
  }
  if (remaining > 0) {
    return '목표까지 ${remaining}kcal 남았습니다. 균형 잡힌 식사를 이어가세요.';
  }
  if (remaining.abs() <= 100) {
    return '거의 목표를 달성했어요! 가벼운 간식으로 마무리해도 좋아요.';
  }
  throw const DietRecommendationException('칼로리가 목표보다 많이 초과했어요. 내일은 조금 조절해 볼까요?');
});
