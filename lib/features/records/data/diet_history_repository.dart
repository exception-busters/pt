import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/records_models.dart';

class DietHistoryRepository {
  Future<List<DailyRecord>> loadRecentDietRecords({
    int daysBack = 60,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = Supabase.instance.client.auth.currentUser?.id;
    final prefix =
        userId != null ? 'diet_data_${userId}_' : 'diet_data_default_';

    print('🔍 [Diet] 식단 데이터 로드 - user_id: $userId');
    print('🔍 [Diet] SharedPreferences prefix: $prefix');

    final keys = prefs.getKeys().where((key) => key.startsWith(prefix)).toList();
    print('🔍 [Diet] 찾은 식단 키 개수: ${keys.length}');
    if (keys.isNotEmpty) {
      print('🔍 [Diet] 식단 키 목록: ${keys.take(3).join(", ")}...');
    }
    if (keys.isEmpty) {
      return const [];
    }

    final cutoff = DateTime.now().subtract(Duration(days: daysBack));
    final records = <DailyRecord>[];

    for (final key in keys) {
      final raw = prefs.getString(key);
      if (raw == null || raw.isEmpty) continue;

      try {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        final dateString =
            decoded['date'] as String? ?? key.replaceFirst(prefix, '');
        final date = DateTime.tryParse(dateString);
        if (date == null) continue;
        if (date.isBefore(cutoff)) continue;

        final meals = _parseMeals(decoded);
        if (meals.isEmpty) continue;

        records.add(
          DailyRecord(
            date: truncateToDate(date),
            diets: meals,
          ),
        );
      } catch (error) {
        print('식단 기록 파싱 실패 ($key): $error');
      }
    }

    records.sort((a, b) => b.date.compareTo(a.date));
    return records;
  }

  List<DietRecordEntry> _parseMeals(Map<String, dynamic> json) {
    final meals = <DietRecordEntry>[];
    const mealKeys = {
      'breakfast': '아침',
      'lunch': '점심',
      'dinner': '저녁',
    };

    for (final entry in mealKeys.entries) {
      final mealJson = json[entry.key];
      if (mealJson is! Map<String, dynamic>) continue;

      final description = _buildDescription(mealJson);
      if (description.isEmpty) continue;

      final nutrition = _extractNutrition(mealJson);

      meals.add(
        DietRecordEntry(
          mealLabel: entry.value,
          description: description,
          calories: nutrition['calories'] ?? 0,
          carbs: nutrition['carbs'] ?? 0,
          protein: nutrition['protein'] ?? 0,
          fat: nutrition['fat'] ?? 0,
        ),
      );
    }

    return meals;
  }

  String _buildDescription(Map<String, dynamic> mealJson) {
    final components = mealJson['components'];
    if (components is List && components.isNotEmpty) {
      final items = components
          .whereType<Map<String, dynamic>>()
          .map((item) {
        final food = item['food'] as Map<String, dynamic>? ?? const {};
        final name = (food['name'] as String?)?.trim();
        final grams = (item['grams'] as num?)?.toDouble();
        if (name == null || name.isEmpty) return null;
        final gramsText = grams != null ? '${grams.toStringAsFixed(0)}g' : '';
        return gramsText.isEmpty ? name : '$name $gramsText';
      }).whereType<String>().toList();

      if (items.isNotEmpty) {
        return items.join(', ');
      }
    }

    final foodText = (mealJson['food'] as String?)?.trim();
    if (foodText != null && foodText.isNotEmpty) {
      return foodText;
    }
    return '';
  }

  Map<String, int> _extractNutrition(Map<String, dynamic> mealJson) {
    final result = {
      'calories': 0,
      'carbs': 0,
      'protein': 0,
      'fat': 0,
    };

    final nutrition = mealJson['nutrition'];
    if (nutrition is Map<String, dynamic>) {
      // 칼로리 추출
      final calories = nutrition['calories'];
      if (calories is num) {
        result['calories'] = calories.round();
      }

      // 탄수화물 추출
      final carbs = nutrition['carbs'] ?? nutrition['carbohydrates'];
      if (carbs is num) {
        result['carbs'] = carbs.round();
      }

      // 단백질 추출
      final protein = nutrition['protein'];
      if (protein is num) {
        result['protein'] = protein.round();
      }

      // 지방 추출
      final fat = nutrition['fat'];
      if (fat is num) {
        result['fat'] = fat.round();
      }

      return result;
    }

    // nutrition 객체가 없을 경우 calories만 추출 시도
    final caloriesText = mealJson['calories'];
    if (caloriesText is String) {
      final digits = RegExp(r'[0-9]+').stringMatch(caloriesText);
      if (digits != null) {
        result['calories'] = int.tryParse(digits) ?? 0;
      }
    } else if (caloriesText is num) {
      result['calories'] = caloriesText.round();
    }

    return result;
  }

  int _extractCalories(Map<String, dynamic> mealJson) {
    final nutrition = _extractNutrition(mealJson);
    return nutrition['calories'] ?? 0;
  }
}
