import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:flutter_application_1/features/auth/application/auth_providers.dart';
import 'package:flutter_application_1/features/diet/data/diet_ai_service.dart';
import 'package:flutter_application_1/features/diet/data/diet_profile_repository.dart';

class MealData {
  MealData({
    required this.food,
    required this.calories,
    List<MealComponent>? components,
    NutritionSummary? nutrition,
  })  : components = List.unmodifiable(components ?? const []),
        nutrition = nutrition ?? NutritionSummary.zero;

  final String food;
  final String calories;
  final List<MealComponent> components;
  final NutritionSummary nutrition;

  MealData copyWith({
    String? food,
    String? calories,
    List<MealComponent>? components,
    NutritionSummary? nutrition,
  }) {
    return MealData(
      food: food ?? this.food,
      calories: calories ?? this.calories,
      components: components ?? this.components,
      nutrition: nutrition ?? this.nutrition,
    );
  }
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
      if (breakfast!.components.isNotEmpty) {
        total += breakfast!.nutrition.calories.round();
      } else {
        total += int.tryParse(breakfast!.calories.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      }
    }
    if (lunch != null) {
      if (lunch!.components.isNotEmpty) {
        total += lunch!.nutrition.calories.round();
      } else {
        total += int.tryParse(lunch!.calories.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      }
    }
    if (dinner != null) {
      if (dinner!.components.isNotEmpty) {
        total += dinner!.nutrition.calories.round();
      } else {
        total += int.tryParse(dinner!.calories.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      }
    }
    return total;
  }

  MealData? mealByLabel(String mealType) {
    switch (mealType) {
      case '아침':
        return breakfast;
      case '점심':
        return lunch;
      case '저녁':
        return dinner;
      default:
        return null;
    }
  }
}

class DietController extends StateNotifier<DietData> {
  DietController(this._ref) : super(_getInitialData()) {
    _loadDietData();
    
    // 인증 상태 변화 감지
    _ref.listen(authControllerProvider, (previous, next) {
      if (previous?.isLoggedIn == true && !next.isLoggedIn) {
        // 로그아웃 시 상태 초기화
        state = _getInitialData();
      } else if (previous?.isLoggedIn == false && next.isLoggedIn) {
        // 로그인 시 해당 사용자의 다이어트 데이터 로드
        _loadDietData();
      }
    });
  }

  final Ref _ref;

  static DietData _getInitialData() {
    final today = DateTime.now();
    final dateString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    return DietData(date: dateString);
  }

  String _getUserDietKey() {
    final user = Supabase.instance.client.auth.currentUser;
    final today = DateTime.now();
    final dateString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    return user != null ? 'diet_data_${user.id}_$dateString' : 'diet_data_default_$dateString';
  }

  Future<void> _loadDietData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dietJson = prefs.getString(_getUserDietKey());
      if (dietJson == null) {
        return;
      }

      final decoded = jsonDecode(dietJson) as Map<String, dynamic>?;
      if (decoded == null) {
        return;
      }

      state = DietData(
        date: decoded['date'] as String? ?? state.date,
        breakfast: _mealFromJson(decoded['breakfast']),
        lunch: _mealFromJson(decoded['lunch']),
        dinner: _mealFromJson(decoded['dinner']),
      );
    } catch (error) {
      print('다이어트 데이터 로드 실패: $error');
    }
  }

  Future<void> _saveDietData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dietMap = <String, dynamic>{
        'date': state.date,
        'breakfast': _mealToJson(state.breakfast),
        'lunch': _mealToJson(state.lunch),
        'dinner': _mealToJson(state.dinner),
      };

      await prefs.setString(_getUserDietKey(), jsonEncode(dietMap));
    } catch (error) {
      print('다이어트 데이터 저장 실패: $error');
    }
  }

  MealData? _mealFromJson(dynamic value) {
    if (value is! Map<String, dynamic>) {
      return null;
    }

    final components = (value['components'] as List?)
            ?.map((item) => _mealComponentFromJson(item))
            .whereType<MealComponent>()
            .toList(growable: false) ??
        const <MealComponent>[];

    return MealData(
      food: value['food'] as String? ?? '',
      calories: value['calories'] as String? ?? '',
      components: components,
      nutrition: _nutritionFromJson(value['nutrition']),
    );
  }

  Map<String, dynamic>? _mealToJson(MealData? meal) {
    if (meal == null) {
      return null;
    }

    return <String, dynamic>{
      'food': meal.food,
      'calories': meal.calories,
      'components': meal.components
          .map((component) => _mealComponentToJson(component))
          .toList(growable: false),
      'nutrition': _nutritionToJson(meal.nutrition),
    };
  }

  MealComponent? _mealComponentFromJson(dynamic value) {
    if (value is! Map<String, dynamic>) {
      return null;
    }

    final foodMap = value['food'];
    if (foodMap is! Map<String, dynamic>) {
      return null;
    }

    final food = FoodItem(
      code: foodMap['code'] as String? ?? '',
      name: foodMap['name'] as String? ?? '이름 미확인',
      category: foodMap['category'] as String? ?? '기타',
      calories: (foodMap['calories'] as num?)?.toDouble() ?? 0,
      protein: (foodMap['protein'] as num?)?.toDouble() ?? 0,
      carbs: (foodMap['carbs'] as num?)?.toDouble() ?? 0,
      fat: (foodMap['fat'] as num?)?.toDouble() ?? 0,
      fiber: (foodMap['fiber'] as num?)?.toDouble() ?? 0,
      sodium: (foodMap['sodium'] as num?)?.toDouble() ?? 0,
    );

    final grams = (value['grams'] as num?)?.toDouble();
    if (grams == null) {
      return null;
    }

    return MealComponent(food: food, grams: grams);
  }

  Map<String, dynamic> _mealComponentToJson(MealComponent component) {
    return <String, dynamic>{
      'food': {
        'code': component.food.code,
        'name': component.food.name,
        'category': component.food.category,
        'calories': component.food.calories,
        'protein': component.food.protein,
        'carbs': component.food.carbs,
        'fat': component.food.fat,
        'fiber': component.food.fiber,
        'sodium': component.food.sodium,
      },
      'grams': component.grams,
    };
  }

  NutritionSummary _nutritionFromJson(dynamic value) {
    if (value is! Map<String, dynamic>) {
      return NutritionSummary.zero;
    }

    return NutritionSummary(
      calories: (value['calories'] as num?)?.toDouble() ?? 0,
      protein: (value['protein'] as num?)?.toDouble() ?? 0,
      carbs: (value['carbs'] as num?)?.toDouble() ?? 0,
      fat: (value['fat'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> _nutritionToJson(NutritionSummary nutrition) {
    return <String, dynamic>{
      'calories': nutrition.calories,
      'protein': nutrition.protein,
      'carbs': nutrition.carbs,
      'fat': nutrition.fat,
    };
  }

  Future<void> saveMeal(String mealType, {required String food, required String calories}) async {
    final trimmedFood = food.trim();
    final trimmedCalories = calories.trim();
    final mealData = trimmedFood.isEmpty && trimmedCalories.isEmpty
        ? null
        : MealData(
            food: trimmedFood,
            calories: trimmedCalories,
            components: const [],
            nutrition: NutritionSummary.zero,
          );

    _setMeal(mealType, mealData);
    await _syncMealToSupabase(mealType, mealData);
  }

  Future<void> saveMealComponents(String mealType, List<MealComponent> components) async {
    if (components.isEmpty) {
      _setMeal(mealType, null);
      await _syncMealToSupabase(mealType, null);
      return;
    }

    final normalized = components
        .map((item) => MealComponent(food: item.food, grams: item.grams))
        .toList(growable: false);

    final summary = normalized
        .map((item) => '${item.food.name} · ${item.grams.toStringAsFixed(0)} g')
        .join('\n');

    final totalNutrition = normalized.fold(
      NutritionSummary.zero,
      (previous, element) => previous + element.nutrition,
    );

    final mealData = MealData(
      food: summary,
      calories: '${totalNutrition.calories.toStringAsFixed(0)} kcal',
      components: normalized,
      nutrition: totalNutrition,
    );

    _setMeal(mealType, mealData);
    await _syncMealToSupabase(mealType, mealData);
  }

  Future<void> clearMeal(String mealType) async {
    _setMeal(mealType, null);
    await _syncMealToSupabase(mealType, null);
  }

  void _setMeal(String mealType, MealData? mealData) {
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
    
    // 데이터 저장
    _saveDietData();
  }

  void checkAndResetIfNewDay() {
    final now = DateTime.now();
    final today = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    
    if (state.date != today) {
      state = DietData(date: today);
      _saveDietData();
    }
  }

  MealData? getMealData(String mealType) {
    return state.mealByLabel(mealType);
  }

  Future<void> _syncMealToSupabase(String mealType, MealData? mealData) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return;
    }

    final client = Supabase.instance.client;
    final mealTime = _mealTimeForLabel(mealType);
    final mealTimeUtc = mealTime.toUtc().toIso8601String();

    try {
      await client
          .from('usermeal')
          .delete()
          .eq('user_id', user.id)
          .eq('meal_time', mealTimeUtc);

      if (mealData == null) {
        return;
      }

      final calories = mealData.nutrition.calories != 0
          ? mealData.nutrition.calories
          : _parseCalories(mealData.calories);

      await client.from('usermeal').insert({
        'user_id': user.id,
        'meal_time': mealTimeUtc,
        'quantity': calories,
        'food_id': null,
      });
    } catch (error) {
      print('usermeal 동기화 실패($mealType): $error');
    }
  }

  DateTime _mealTimeForLabel(String mealType) {
    final now = DateTime.now();
    final hour = switch (mealType) {
      '아침' => 8,
      '점심' => 13,
      '저녁' => 19,
      _ => now.hour,
    };
    return DateTime(now.year, now.month, now.day, hour, 0, 0, 0, 0);
  }

  double? _parseCalories(String value) {
    final digits = RegExp(r'([0-9]+(?:\.[0-9]+)?)').firstMatch(value);
    if (digits == null) {
      return null;
    }
    return double.tryParse(digits.group(1)!);
  }
}

final dietControllerProvider = StateNotifierProvider<DietController, DietData>(
  (ref) => DietController(ref),
);

// --- Today diet recommendation ------------------------------------------------

enum DietGoal { bulkUp, cut, maintain }

enum DietExperience { beginner, intermediate, advanced }

enum DietPreference { balanced, lowCarb, highProtein, vegetarian, vegan, keto }

class DietUserProfile {
  const DietUserProfile({
    required this.goal,
    required this.experience,
    required this.weightKg,
    required this.mealsPerDay,
    this.targetCalories,
    this.preference,
    this.dietaryRestrictions = const [],
  });

  final DietGoal goal;
  final DietExperience experience;
  final double weightKg;
  final int mealsPerDay;
  final double? targetCalories;
  final DietPreference? preference;
  final List<String> dietaryRestrictions;
}

class FoodItem {
  FoodItem({
    required this.code,
    required this.name,
    required this.category,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    required this.sodium,
  });

  final String code;
  final String name;
  final String category;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final double sodium;

  double get proteinDensity => calories <= 0 ? 0 : protein / calories;

  double get carbDensity => calories <= 0 ? 0 : carbs / calories;

  double get fatDensity => calories <= 0 ? 0 : fat / calories;

  bool get hasValidMacros => calories > 0 && (protein > 0 || carbs > 0 || fat > 0);

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      code: (json['식품코드'] as String?)?.trim() ?? '',
      name: (json['식품명'] as String?)?.trim() ?? '이름 미확인',
      category: (json['식품대분류명'] as String?)?.trim() ?? '기타',
      calories: _asDouble(json['에너지(kcal)']),
      protein: _asDouble(json['단백질(g)']),
      carbs: _asDouble(json['탄수화물(g)']),
      fat: _asDouble(json['지방(g)']),
      fiber: _asDouble(json['식이섬유(g)']),
      sodium: _asDouble(json['나트륨(mg)']),
    );
  }

  static double _asDouble(dynamic value) {
    if (value == null) {
      return 0;
    }
    if (value is num) {
      return value.toDouble();
    }
    if (value is String && value.trim().isNotEmpty) {
      return double.tryParse(value.trim()) ?? 0;
    }
    return 0;
  }
}

class NutritionSummary {
  const NutritionSummary({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  final double calories;
  final double protein;
  final double carbs;
  final double fat;

  static const zero = NutritionSummary(
    calories: 0,
    protein: 0,
    carbs: 0,
    fat: 0,
  );

  NutritionSummary operator +(NutritionSummary other) {
    return NutritionSummary(
      calories: calories + other.calories,
      protein: protein + other.protein,
      carbs: carbs + other.carbs,
      fat: fat + other.fat,
    );
  }
}

class MealComponent {
  MealComponent({
    required this.food,
    required double grams,
  }) : grams = grams.clamp(0, 1000).toDouble();

  final FoodItem food;
  final double grams;

  NutritionSummary get nutrition {
    final ratio = grams <= 0 ? 0 : grams / 100;
    return NutritionSummary(
      calories: food.calories * ratio,
      protein: food.protein * ratio,
      carbs: food.carbs * ratio,
      fat: food.fat * ratio,
    );
  }

  MealComponent copyWith({
    FoodItem? food,
    double? grams,
  }) {
    return MealComponent(
      food: food ?? this.food,
      grams: grams ?? this.grams,
    );
  }
}

class DailyTarget {
  const DailyTarget({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  final double calories;
  final double protein;
  final double carbs;
  final double fat;
}

class MealItemRecommendation {
  const MealItemRecommendation({
    required this.food,
    required this.grams,
    required this.nutrition,
  });

  final FoodItem food;
  final double grams;
  final NutritionSummary nutrition;
}

class MealRecommendation {
  const MealRecommendation({
    required this.label,
    required this.items,
    required this.nutrition,
  });

  final String label;
  final List<MealItemRecommendation> items;
  final NutritionSummary nutrition;
}

class DietRecommendationResult {
  const DietRecommendationResult({
    required this.profile,
    required this.target,
    required this.meals,
    required this.total,
    required this.summary,
  });

  final DietUserProfile profile;
  final DailyTarget target;
  final List<MealRecommendation> meals;
  final NutritionSummary total;
  final String summary;
}

class _MacroRatio {
  const _MacroRatio({
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  final double protein;
  final double carbs;
  final double fat;

  double get sum => protein + carbs + fat;
}

class _MealTemplate {
  const _MealTemplate({
    required this.label,
    required this.calorieShare,
    required this.carbWeight,
    required this.proteinWeight,
    required this.fatWeight,
  });

  final String label;
  final double calorieShare;
  final double carbWeight;
  final double proteinWeight;
  final double fatWeight;

  _MealTemplate copyWith({
    String? label,
    double? calorieShare,
    double? carbWeight,
    double? proteinWeight,
    double? fatWeight,
  }) {
    return _MealTemplate(
      label: label ?? this.label,
      calorieShare: calorieShare ?? this.calorieShare,
      carbWeight: carbWeight ?? this.carbWeight,
      proteinWeight: proteinWeight ?? this.proteinWeight,
      fatWeight: fatWeight ?? this.fatWeight,
    );
  }
}

class DietRecommendationEngine {
  DietRecommendationEngine({
    required this.foods,
    required this.profile,
  });

  final List<FoodItem> foods;
  final DietUserProfile profile;

  DietRecommendationResult generate() {
    final target = _buildDailyTarget();
    final selector = _FoodSelector(foods: foods, goal: profile.goal);
    final baseTemplates = _goalMealTemplates[profile.goal] ?? _goalMealTemplates[DietGoal.maintain]!;
    final templates = _resolveTemplatesForMeals(baseTemplates, profile.mealsPerDay);

    final usedCodes = <String>{};
    final meals = <MealRecommendation>[];
    var total = NutritionSummary.zero;

    for (final template in templates) {
      final mealCalories = target.calories * template.calorieShare;
      final items = <MealItemRecommendation>[];

      double remaining = mealCalories;

      if (template.carbWeight > 0) {
        final food = selector.pickCarb(usedCodes);
        if (food != null) {
          final item = _buildMealItem(food, mealCalories * template.carbWeight);
          if (item.nutrition.calories > 0) {
            items.add(item);
            usedCodes.add(food.code);
            total = total + item.nutrition;
            remaining -= item.nutrition.calories;
          }
        }
      }

      if (template.proteinWeight > 0) {
        final food = selector.pickProtein(usedCodes);
        if (food != null) {
          final item = _buildMealItem(food, mealCalories * template.proteinWeight);
          if (item.nutrition.calories > 0) {
            items.add(item);
            usedCodes.add(food.code);
            total = total + item.nutrition;
            remaining -= item.nutrition.calories;
          }
        }
      }

      if (template.fatWeight > 0 && remaining > 50) {
        final food = selector.pickFat(usedCodes);
        if (food != null) {
          final item = _buildMealItem(food, mealCalories * template.fatWeight, maxGrams: 60);
          if (item.nutrition.calories > 0) {
            items.add(item);
            usedCodes.add(food.code);
            total = total + item.nutrition;
          }
        }
      }

      final mealNutrition = items.fold<NutritionSummary>(
        NutritionSummary.zero,
        (acc, item) => acc + item.nutrition,
      );

      meals.add(
        MealRecommendation(
          label: template.label,
          items: items,
          nutrition: mealNutrition,
        ),
      );
    }

    final summary = _buildSummary(target, total);

    return DietRecommendationResult(
      profile: profile,
      target: target,
      meals: meals,
      total: total,
      summary: summary,
    );
  }

  List<_MealTemplate> _resolveTemplatesForMeals(List<_MealTemplate> base, int desiredMeals) {
    final clampedMeals = desiredMeals.clamp(1, 6).toInt();
    if (clampedMeals <= 0) {
      return base;
    }
    if (clampedMeals == base.length) {
      return base;
    }
    if (clampedMeals < base.length) {
      final trimmed = base.take(clampedMeals).toList();
      final totalShare = trimmed.fold<double>(0, (sum, template) => sum + template.calorieShare);
      if (totalShare <= 0) {
        final evenShare = 1 / clampedMeals;
        return trimmed
            .map((template) => template.copyWith(calorieShare: evenShare))
            .toList();
      }
      return trimmed
          .map((template) => template.copyWith(calorieShare: template.calorieShare / totalShare))
          .toList();
    }

    final perMealShare = 1 / clampedMeals;
    final snackTemplate = _MealTemplate(
      label: '간식',
      calorieShare: perMealShare,
      carbWeight: 0.4,
      proteinWeight: 0.35,
      fatWeight: 0.25,
    );

    final result = <_MealTemplate>[];
    for (int i = 0; i < clampedMeals; i++) {
      if (i < base.length) {
        result.add(base[i].copyWith(calorieShare: perMealShare));
      } else {
        result.add(
          snackTemplate.copyWith(
            label: '간식 ${i - base.length + 1}',
            calorieShare: perMealShare,
          ),
        );
      }
    }
    return result;
  }

  DailyTarget _buildDailyTarget() {
    final calories = profile.targetCalories ??
        _estimateCaloriesFromWeight(profile) ??
        _fallbackCalories(profile);

    final ratio = _macroRatios[profile.goal] ?? const _MacroRatio(protein: 0.3, carbs: 0.4, fat: 0.3);

    final normalized = ratio.sum == 0 ? const _MacroRatio(protein: 0.3, carbs: 0.4, fat: 0.3) : ratio;

    final protein = calories * normalized.protein / 4;
    final carbs = calories * normalized.carbs / 4;
    final fat = calories * normalized.fat / 9;

    return DailyTarget(
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
    );
  }

  double? _estimateCaloriesFromWeight(DietUserProfile profile) {
    if (profile.weightKg <= 0) {
      return null;
    }
    final perKg = _goalCaloriesPerKg[profile.goal];
    if (perKg == null) {
      return null;
    }
    final adjustment = _experienceCalorieAdjustment[profile.experience] ?? 0;
    return profile.weightKg * perKg + adjustment;
  }

  double _fallbackCalories(DietUserProfile profile) {
    final calorieMap = _goalCalories[profile.goal] ?? _goalCalories[DietGoal.maintain]!;
    return (calorieMap[profile.experience] ?? calorieMap.values.first).toDouble();
  }

  String _buildSummary(DailyTarget target, NutritionSummary actual) {
    String diff(double actualValue, double targetValue, String unit) {
      final delta = actualValue - targetValue;
      if (delta.abs() < 1) {
        return '(목표와 유사)';
      }
      final sign = delta > 0 ? '+' : '';
      return '(${sign}${delta.round()}$unit)';
    }

    final calorieDiff = diff(actual.calories, target.calories, 'kcal');
    final proteinDiff = diff(actual.protein, target.protein, 'g');
    final carbDiff = diff(actual.carbs, target.carbs, 'g');
    final fatDiff = diff(actual.fat, target.fat, 'g');

    return '칼로리 ${actual.calories.round()}kcal $calorieDiff · '
        '단백질 ${actual.protein.round()}g $proteinDiff · '
        '탄수화물 ${actual.carbs.round()}g $carbDiff · '
        '지방 ${actual.fat.round()}g $fatDiff';
  }

  MealItemRecommendation _buildMealItem(
    FoodItem food,
    double targetCalories, {
    double? maxGrams,
  }) {
    if (targetCalories <= 0 || food.calories <= 0) {
      return MealItemRecommendation(
        food: food,
        grams: 0,
        nutrition: NutritionSummary.zero,
      );
    }

    var grams = (targetCalories / food.calories) * 100;
    if (maxGrams != null) {
      grams = min(grams, maxGrams);
    }
    grams = max(grams, 30);

    final ratio = grams / 100;

    return MealItemRecommendation(
      food: food,
      grams: grams,
      nutrition: NutritionSummary(
        calories: food.calories * ratio,
        protein: food.protein * ratio,
        carbs: food.carbs * ratio,
        fat: food.fat * ratio,
      ),
    );
  }
}

class _FoodSelector {
  _FoodSelector({
    required this.foods,
    required this.goal,
  }) {
    proteinFoods = foods
        .where((item) => item.protein >= 10 && item.calories > 0)
        .toList()
      ..sort((a, b) => b.proteinDensity.compareTo(a.proteinDensity));

    carbFoods = foods
        .where((item) => item.carbs >= 15 && item.calories > 0)
        .toList()
      ..sort((a, b) {
        final cmp = b.carbDensity.compareTo(a.carbDensity);
        if (cmp != 0) {
          return cmp;
        }
        return a.calories.compareTo(b.calories);
      });

    fatFoods = foods
        .where((item) => item.fat >= 8 && item.calories > 0)
        .toList()
      ..sort((a, b) => b.fatDensity.compareTo(a.fatDensity));

    // Fallback if lists are too small
    if (proteinFoods.length < 5) {
      proteinFoods = foods.where((item) => item.protein > 0).toList()
        ..sort((a, b) => b.protein.compareTo(a.protein));
    }
    if (carbFoods.length < 5) {
      carbFoods = foods.where((item) => item.carbs > 0).toList()
        ..sort((a, b) => b.carbs.compareTo(a.carbs));
    }
    if (fatFoods.length < 3) {
      fatFoods = foods.where((item) => item.fat > 0).toList()
        ..sort((a, b) => b.fat.compareTo(a.fat));
    }
  }

  final List<FoodItem> foods;
  final DietGoal goal;

  late List<FoodItem> proteinFoods;
  late List<FoodItem> carbFoods;
  late List<FoodItem> fatFoods;

  FoodItem? pickProtein(Set<String> used) {
    return _pickNext(proteinFoods, used);
  }

  FoodItem? pickCarb(Set<String> used) {
    if (goal == DietGoal.cut) {
      final lowSugar = carbFoods.where((item) => item.carbs <= 35).toList();
      if (lowSugar.length >= 3) {
        final picked = _pickNext(lowSugar, used);
        if (picked != null) {
          return picked;
        }
      }
    }
    return _pickNext(carbFoods, used);
  }

  FoodItem? pickFat(Set<String> used) {
    return _pickNext(fatFoods, used);
  }

  FoodItem? _pickNext(List<FoodItem> source, Set<String> used) {
    for (final item in source) {
      if (item.code.isEmpty || used.contains(item.code)) {
        continue;
      }
      return item;
    }
    return null;
  }
}

const Map<DietGoal, Map<DietExperience, int>> _goalCalories = {
  DietGoal.bulkUp: {
    DietExperience.beginner: 2600,
    DietExperience.intermediate: 2900,
    DietExperience.advanced: 3200,
  },
  DietGoal.cut: {
    DietExperience.beginner: 1900,
    DietExperience.intermediate: 1750,
    DietExperience.advanced: 1650,
  },
  DietGoal.maintain: {
    DietExperience.beginner: 2200,
    DietExperience.intermediate: 2300,
    DietExperience.advanced: 2400,
  },
};

const Map<DietGoal, _MacroRatio> _macroRatios = {
  DietGoal.bulkUp: _MacroRatio(protein: 0.3, carbs: 0.45, fat: 0.25),
  DietGoal.cut: _MacroRatio(protein: 0.35, carbs: 0.3, fat: 0.35),
  DietGoal.maintain: _MacroRatio(protein: 0.3, carbs: 0.4, fat: 0.3),
};

const Map<DietGoal, double> _goalCaloriesPerKg = {
  DietGoal.bulkUp: 34,
  DietGoal.cut: 25,
  DietGoal.maintain: 30,
};

const Map<DietExperience, double> _experienceCalorieAdjustment = {
  DietExperience.beginner: -100,
  DietExperience.intermediate: 0,
  DietExperience.advanced: 150,
};

const Map<DietGoal, List<_MealTemplate>> _goalMealTemplates = {
  DietGoal.bulkUp: [
    _MealTemplate(label: '아침', calorieShare: 0.32, carbWeight: 0.5, proteinWeight: 0.35, fatWeight: 0.15),
    _MealTemplate(label: '점심', calorieShare: 0.38, carbWeight: 0.45, proteinWeight: 0.4, fatWeight: 0.15),
    _MealTemplate(label: '저녁', calorieShare: 0.3, carbWeight: 0.4, proteinWeight: 0.4, fatWeight: 0.2),
  ],
  DietGoal.cut: [
    _MealTemplate(label: '아침', calorieShare: 0.3, carbWeight: 0.35, proteinWeight: 0.45, fatWeight: 0.2),
    _MealTemplate(label: '점심', calorieShare: 0.4, carbWeight: 0.3, proteinWeight: 0.5, fatWeight: 0.2),
    _MealTemplate(label: '저녁', calorieShare: 0.3, carbWeight: 0.25, proteinWeight: 0.5, fatWeight: 0.25),
  ],
  DietGoal.maintain: [
    _MealTemplate(label: '아침', calorieShare: 0.3, carbWeight: 0.4, proteinWeight: 0.4, fatWeight: 0.2),
    _MealTemplate(label: '점심', calorieShare: 0.4, carbWeight: 0.4, proteinWeight: 0.4, fatWeight: 0.2),
    _MealTemplate(label: '저녁', calorieShare: 0.3, carbWeight: 0.35, proteinWeight: 0.4, fatWeight: 0.25),
  ],
};

final dietProfileRepositoryProvider = Provider<DietProfileRepository>((ref) {
  return DietProfileRepository(Supabase.instance.client);
});

final dietAIServiceProvider = Provider<DietAIService>((ref) {
  return DietAIService(Supabase.instance.client);
});

final dietUserProfileProvider = FutureProvider<DietUserProfile>((ref) async {
  final repository = ref.watch(dietProfileRepositoryProvider);

  try {
    final snapshot = await repository.fetchUserSnapshot();
    return DietUserProfile(
      goal: _mapDietGoal(snapshot.goalType),
      experience: _mapDietExperience(snapshot.levelValue, snapshot.levelLabel),
      weightKg: snapshot.weightKg ?? 70,
      mealsPerDay: snapshot.mealsPerDay ?? 3,
      targetCalories: snapshot.targetCalories,
      preference: _mapDietPreference(snapshot.dietType),
      dietaryRestrictions: snapshot.dietaryRestrictions,
    );
  } on DietProfileRepositoryException catch (error) {
    throw DietRecommendationException(error.message);
  } catch (error) {
    throw DietRecommendationException('사용자 식단 정보를 불러오지 못했습니다: $error');
  }
});

DietGoal _mapDietGoal(String? raw) {
  final value = raw?.toLowerCase().trim();
  switch (value) {
    case 'weight_loss':
    case 'fat_loss':
    case 'cut':
    case 'diet_cut':
    case 'diet':
    case 'dieting':
    case 'lowcarb':
    case 'low_carb':
    case 'keto':
    case 'ketogenic':
    case '다이어트':
    case '체중감량':
      return DietGoal.cut;
    case 'muscle_gain':
    case 'bulk':
    case 'bulk_up':
    case 'highprotein':
    case 'high_protein':
    case '단백질강화':
    case '근육증가':
      return DietGoal.bulkUp;
    case 'maintain':
    case 'maintenance':
    case 'health':
    case 'balanced':
    case 'vegetarian':
    case 'vegan':
    case 'plantbased':
    case 'plant_based':
    case '일반':
    case '균형':
    case 'maintain_weight':
    case '건강유지':
    default:
      return DietGoal.maintain;
  }
}

DietPreference? _mapDietPreference(String? raw) {
  final value = raw?.toLowerCase().trim();
  switch (value) {
    case null:
    case '':
      return null;
    case 'balanced':
    case 'general':
    case 'maintain':
    case 'default':
      return DietPreference.balanced;
    case 'lowcarb':
    case 'low_carb':
    case '저탄수화물':
    case '로우카브':
      return DietPreference.lowCarb;
    case 'highprotein':
    case 'high_protein':
    case '고단백':
      return DietPreference.highProtein;
    case 'vegetarian':
    case 'vegetarianism':
    case '채식':
    case '채식주의':
    case 'veg':
    case 'veggie':
      return DietPreference.vegetarian;
    case 'vegan':
    case 'plant_based':
    case 'plant-based':
    case 'plantbased':
    case '플랜트베이스드':
    case '비건':
      return DietPreference.vegan;
    case 'keto':
    case 'ketogenic':
    case '케토':
      return DietPreference.keto;
    default:
      return null;
  }
}

DietExperience _mapDietExperience(int? levelValue, String? levelLabel) {
  final label = levelLabel?.toLowerCase().trim();
  if (label != null && label.isNotEmpty) {
    if (label.contains('초급') || label.contains('beginner')) {
      return DietExperience.beginner;
    }
    if (label.contains('중급') || label.contains('intermediate')) {
      return DietExperience.intermediate;
    }
    if (label.contains('고급') || label.contains('advanced')) {
      return DietExperience.advanced;
    }
  }

  if (levelValue != null) {
    if (levelValue <= 1) {
      return DietExperience.beginner;
    }
    if (levelValue == 2) {
      return DietExperience.intermediate;
    }
    if (levelValue >= 3) {
      return DietExperience.advanced;
    }
  }

  return DietExperience.beginner;
}

final foodDatabaseProvider = FutureProvider<List<FoodItem>>((ref) async {
  final raw = await rootBundle.loadString('assets/data/foods.json');
  final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
  final foods = decoded
      .map((item) => FoodItem.fromJson(item as Map<String, dynamic>))
      .where((item) => item.hasValidMacros)
      .toList();
  return foods;
});

final todayDietPlanProvider = FutureProvider<DietRecommendationResult>((ref) async {
  final foods = await ref.watch(foodDatabaseProvider.future);
  if (foods.isEmpty) {
    throw const DietRecommendationException('사용 가능한 음식 데이터가 없습니다.');
  }

  final profile = await ref.watch(dietUserProfileProvider.future);

  final aiService = ref.watch(dietAIServiceProvider);
  final aiPlan = await aiService.fetchRecommendation(profile: profile);
  if (aiPlan != null && aiPlan.meals.isNotEmpty) {
    return aiPlan;
  }

  try {
    final engine = DietRecommendationEngine(
      foods: foods,
      profile: profile,
    );
    return engine.generate();
  } catch (error) {
    throw DietRecommendationException('식단 추천 생성에 실패했습니다: $error');
  }
});
