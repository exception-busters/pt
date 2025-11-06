import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../application/diet_providers.dart';

/// Calls the Supabase Edge Function to generate an AI based diet plan.
class DietAIService {
  DietAIService(this._client);

  final SupabaseClient _client;

  Future<DietRecommendationResult?> fetchRecommendation({
    required DietUserProfile profile,
  }) async {
    try {
      debugPrint('[DietAI] invoking diet-recommendation edge function');
      final response = await _client.functions.invoke(
        'diet-recommendation',
        body: _buildRequestPayload(profile),
      );

      debugPrint('[DietAI] function status: ${response.status}');
      debugPrint('[DietAI] function data: ${response.data}');

      final dynamic data = response.data;
      if (data is! Map<String, dynamic>) {
        debugPrint('[DietAI] unexpected response shape');
        return null;
      }

      if (data['error'] != null) {
        debugPrint('[DietAI] function returned error: ${data['error']}');
        return null;
      }

      final dynamic planData = data['plan'];
      final Map<String, dynamic>? planJson = _parsePlan(planData);
      if (planJson == null) {
        debugPrint('[DietAI] could not parse plan from response');
        return null;
      }

      return _mapPlanToResult(planJson, profile);
    } catch (error) {
      debugPrint('[DietAI] invoke failed: $error');
      return null;
    }
  }

  Map<String, dynamic> _buildRequestPayload(DietUserProfile profile) {
    return {
      'profile': {
        'goal': profile.goal.name,
        'experience': profile.experience.name,
        'weightKg': profile.weightKg,
        'mealsPerDay': profile.mealsPerDay,
        'targetCalories': profile.targetCalories,
      },
      'dietGoal': {
        'goal': profile.goal.name,
        'experience': profile.experience.name,
      },
    };
  }

  Map<String, dynamic>? _parsePlan(dynamic planData) {
    if (planData is Map<String, dynamic>) {
      return planData;
    }
    if (planData is String && planData.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(planData);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
      } catch (error) {
        debugPrint('[DietAI] json decode failed: $error');
        return null;
      }
    }
    return null;
  }

  DietRecommendationResult _mapPlanToResult(
    Map<String, dynamic> plan,
    DietUserProfile profile,
  ) {
    final summary = plan['summary'] as String? ?? 'AI 추천 식단입니다.';
    final mealsData = plan['meals'];

    final meals = <MealRecommendation>[];
    if (mealsData is List) {
      for (var i = 0; i < mealsData.length; i++) {
        final mealEntry = mealsData[i];
        if (mealEntry is! Map<String, dynamic>) continue;

        final label = mealEntry['label'] as String? ?? '끼니 ${i + 1}';
        final items = _parseMealItems(mealEntry['items'], label, i);
        final mealNutrition = items.fold<NutritionSummary>(
          NutritionSummary.zero,
          (prev, item) => prev + item.nutrition,
        );

        meals.add(
          MealRecommendation(
            label: label,
            items: items,
            nutrition: mealNutrition,
          ),
        );
      }
    }

    final total = meals.fold<NutritionSummary>(
      NutritionSummary.zero,
      (prev, meal) => prev + meal.nutrition,
    );

    final targetCalories = _toDouble(plan['totalCalories']) ?? total.calories;
    final target = DailyTarget(
      calories: targetCalories,
      protein: total.protein,
      carbs: total.carbs,
      fat: total.fat,
    );

    return DietRecommendationResult(
      profile: profile,
      target: target,
      meals: meals,
      total: total,
      summary: summary,
    );
  }

  List<MealItemRecommendation> _parseMealItems(
    dynamic rawItems,
    String label,
    int mealIndex,
  ) {
    final results = <MealItemRecommendation>[];

    if (rawItems is! List) {
      return results;
    }

    for (var j = 0; j < rawItems.length; j++) {
      final item = rawItems[j];
      if (item is! Map<String, dynamic>) continue;

      final name = (item['food'] as String?)?.trim();
      if (name == null || name.isEmpty) continue;

      final grams = _toDouble(item['grams']) ?? 0;
      final calories = _toDouble(item['calories']) ?? 0;
      final protein = _toDouble(item['protein']) ?? 0;
      final carbs = _toDouble(item['carbs']) ?? 0;
      final fat = _toDouble(item['fat']) ?? 0;
      final fiber = _toDouble(item['fiber']) ?? 0;
      final sodium = _toDouble(item['sodium']) ?? 0;

      final caloriesPer100 = _perHundred(grams, calories);
      final proteinPer100 = _perHundred(grams, protein);
      final carbsPer100 = _perHundred(grams, carbs);
      final fatPer100 = _perHundred(grams, fat);
      final fiberPer100 = _perHundred(grams, fiber);
      final sodiumPer100 = _perHundred(grams, sodium);

      final food = FoodItem(
        code: 'ai_${mealIndex}_$j',
        name: name,
        category: (item['category'] as String?) ?? 'AI 추천',
        calories: caloriesPer100,
        protein: proteinPer100,
        carbs: carbsPer100,
        fat: fatPer100,
        fiber: fiberPer100,
        sodium: sodiumPer100,
      );

      final nutrition = NutritionSummary(
        calories: calories,
        protein: protein,
        carbs: carbs,
        fat: fat,
      );

      results.add(
        MealItemRecommendation(
          food: food,
          grams: grams > 0 ? grams : 100,
          nutrition: nutrition,
        ),
      );
    }

    return results;
  }

  double? _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  double _perHundred(double grams, double value) {
    if (grams <= 0) {
      return value;
    }
    return value / grams * 100;
  }
}
