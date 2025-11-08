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

    final keys = prefs.getKeys().where((key) => key.startsWith(prefix)).toList();
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

      final calories = _extractCalories(mealJson);

      meals.add(
        DietRecordEntry(
          mealLabel: entry.value,
          description: description,
          calories: calories,
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

  int _extractCalories(Map<String, dynamic> mealJson) {
    final nutrition = mealJson['nutrition'];
    if (nutrition is Map<String, dynamic>) {
      final calories = nutrition['calories'];
      if (calories is num) {
        return calories.round();
      }
    }

    final caloriesText = mealJson['calories'];
    if (caloriesText is String) {
      final digits = RegExp(r'[0-9]+').stringMatch(caloriesText);
      if (digits != null) {
        return int.tryParse(digits) ?? 0;
      }
    }
    return 0;
  }
}
