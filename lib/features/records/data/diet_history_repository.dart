import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/records_models.dart';

class DietHistoryRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Supabase usermeal 테이블에서 식단 기록 가져오기
  Future<List<DailyRecord>> _loadFromSupabase({
    required String userId,
    required int daysBack,
  }) async {
    try {
      final cutoff = DateTime.now().subtract(Duration(days: daysBack));

      print('📡 [Diet] Supabase에서 식단 기록 가져오기 시작 - user_id: $userId');

      final response = await _supabase
          .from('usermeal')
          .select()
          .eq('user_id', userId)
          .gte('meal_date', cutoff.toIso8601String())
          .order('meal_date', ascending: false);

      print('📡 [Diet] Supabase 응답: ${response.length}개 기록');

      // 날짜별로 그룹화
      final Map<String, List<Map<String, dynamic>>> groupedByDate = {};
      for (final meal in response) {
        final dateStr = meal['meal_date'] as String;
        final date = DateTime.parse(dateStr);
        final dateKey = truncateToDate(date).toIso8601String().split('T')[0];

        groupedByDate.putIfAbsent(dateKey, () => []).add(meal);
      }

      // DailyRecord로 변환
      final records = <DailyRecord>[];
      for (final entry in groupedByDate.entries) {
        final date = DateTime.parse(entry.key);
        final meals = entry.value.map((mealData) {
          return DietRecordEntry(
            mealLabel: _getMealLabel(mealData['meal_type'] as String),
            description: _buildDescriptionFromSupabase(mealData),
            calories: (mealData['calories'] as num?)?.round() ?? 0,
            carbs: (mealData['carbs'] as num?)?.round() ?? 0,
            protein: (mealData['protein'] as num?)?.round() ?? 0,
            fat: (mealData['fat'] as num?)?.round() ?? 0,
          );
        }).toList();

        if (meals.isNotEmpty) {
          records.add(DailyRecord(
            date: truncateToDate(date),
            diets: meals,
          ));
        }
      }

      print('✅ [Diet] Supabase에서 ${records.length}일치 식단 기록 로드 완료');
      return records;
    } catch (e) {
      print('❌ [Diet] Supabase 식단 기록 로드 실패: $e');
      return const [];
    }
  }

  String _getMealLabel(String mealType) {
    switch (mealType) {
      case 'breakfast':
        return '아침';
      case 'lunch':
        return '점심';
      case 'dinner':
        return '저녁';
      default:
        return mealType;
    }
  }

  String _buildDescriptionFromSupabase(Map<String, dynamic> mealData) {
    final components = mealData['components'];
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
    return mealData['meal_type'] as String? ?? '';
  }

  Future<List<DailyRecord>> loadRecentDietRecords({
    int daysBack = 60,
  }) async {
    final userId = _supabase.auth.currentUser?.id;

    if (userId == null) {
      print('⚠️ [Diet] 사용자가 로그인되지 않았습니다');
      return const [];
    }

    print('🔍 [Diet] 식단 데이터 로드 - user_id: $userId');

    // ⭐ 1. Supabase에서 먼저 데이터 가져오기 (새 기기 대응)
    final supabaseRecords = await _loadFromSupabase(
      userId: userId,
      daysBack: daysBack,
    );

    // 2. 로컬 캐시에서도 데이터 가져오기 (백업용)
    final localRecords = await _loadFromLocal(
      userId: userId,
      daysBack: daysBack,
    );

    // 3. 두 소스 병합 (Supabase 우선, 중복 제거)
    final mergedMap = <String, DailyRecord>{};

    // Supabase 데이터 먼저 추가
    for (final record in supabaseRecords) {
      final key = record.date.toIso8601String().split('T')[0];
      mergedMap[key] = record;
    }

    // 로컬 데이터는 Supabase에 없는 것만 추가
    for (final record in localRecords) {
      final key = record.date.toIso8601String().split('T')[0];
      if (!mergedMap.containsKey(key)) {
        mergedMap[key] = record;
      }
    }

    final mergedRecords = mergedMap.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    print('✅ [Diet] 총 ${mergedRecords.length}일치 식단 기록 로드 완료 (Supabase: ${supabaseRecords.length}, 로컬: ${localRecords.length})');

    return mergedRecords;
  }

  /// 로컬 캐시에서 식단 기록 가져오기
  Future<List<DailyRecord>> _loadFromLocal({
    required String userId,
    required int daysBack,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final prefix = 'diet_data_${userId}_';

    print('💾 [Diet] 로컬 캐시에서 식단 기록 가져오기');

    final keys = prefs.getKeys().where((key) => key.startsWith(prefix)).toList();
    print('💾 [Diet] 찾은 식단 키 개수: ${keys.length}');

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
        print('💾 [Diet] 로컬 식단 기록 파싱 실패 ($key): $error');
      }
    }

    records.sort((a, b) => b.date.compareTo(a.date));
    print('💾 [Diet] 로컬에서 ${records.length}일치 식단 기록 로드 완료');
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
