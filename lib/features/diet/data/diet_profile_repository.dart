import 'package:postgrest/postgrest.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Stores raw diet-related preferences fetched from Supabase.
class DietProfileSnapshot {
  const DietProfileSnapshot({
    required this.goalType,
    required this.targetCalories,
    required this.levelValue,
    required this.levelLabel,
    required this.weightKg,
    required this.mealsPerDay,
    this.dietType,
    this.dietaryRestrictions = const [],
  });

  final String? goalType;
  final double? targetCalories;
  final int? levelValue;
  final String? levelLabel;
  final double? weightKg;
  final int? mealsPerDay;
  final String? dietType;
  final List<String> dietaryRestrictions;
}

class DietProfileRepositoryException implements Exception {
  const DietProfileRepositoryException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => 'DietProfileRepositoryException: $message';
}

class DietProfileRepository {
  DietProfileRepository(this._client);

  final SupabaseClient _client;
  static const List<String> _workoutGoalTableCandidates = [
    'exercisegoal',
    'workoutgoal',
  ];
  static String? _resolvedWorkoutGoalTable;

  Future<DietProfileSnapshot> fetchUserSnapshot() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const DietProfileRepositoryException('로그인이 필요합니다.');
    }

    final userId = user.id;
    final profile = await _loadUserProfile(userId);
    final workoutGoal = await _loadWorkoutGoal(userId);
    final dietGoal = await _loadDietGoal(userId);

    var mealsPerDay = dietGoal.mealsPerDay ?? profile.mealsPerDay;
    if (mealsPerDay == null) {
      mealsPerDay = (await _estimateMealsPerDay(userId)).mealsPerDay;
    }
    mealsPerDay ??= 3;

    final resolvedGoalType = dietGoal.goalType ?? workoutGoal.goalType ?? profile.goalType;
    final dietType = dietGoal.dietType ?? dietGoal.goalType;
    final restrictions = dietGoal.dietaryRestrictions ?? const <String>[];

    return DietProfileSnapshot(
      goalType: resolvedGoalType,
      targetCalories: dietGoal.targetCalories ?? profile.targetCalories,
      levelValue: workoutGoal.levelValue ?? profile.levelValue,
      levelLabel: workoutGoal.levelLabel ?? profile.levelLabel,
      weightKg: profile.weightKg,
      mealsPerDay: mealsPerDay,
      dietType: dietType,
      dietaryRestrictions: restrictions,
    );
  }

  Future<_PartialSnapshot> _loadUserProfile(String userId) async {
    try {
      final result = await _client
          .from('userprofile')
          .select('weight')
          .eq('user_id', userId)
          .maybeSingle() as Map<String, dynamic>?;

      if (result == null) {
        return const _PartialSnapshot();
      }

      return _PartialSnapshot(
        weightKg: _asDouble(result['weight']),
      );
    } on PostgrestException catch (error) {
      throw DietProfileRepositoryException(
        '사용자 프로필을 불러오지 못했습니다.',
        cause: error,
      );
    } catch (error) {
      throw DietProfileRepositoryException(
        '사용자 프로필을 읽는 중 알 수 없는 오류가 발생했습니다.',
        cause: error,
      );
    }
  }

  Future<_PartialSnapshot> _loadWorkoutGoal(String userId) async {
    try {
      final workoutTable = await _getWorkoutGoalTable();
      final result = await _client
          .from(workoutTable)
          .select('goal_type, level')
          .eq('user_id', userId)
          .maybeSingle() as Map<String, dynamic>?;

      if (result == null) {
        return const _PartialSnapshot();
      }

      final rawLevel = _asString(result['level']);
      return _PartialSnapshot(
        goalType: _asString(result['goal_type']),
        levelValue: _mapLevelToValue(rawLevel),
        levelLabel: _mapLevelToLabel(rawLevel),
      );
    } on PostgrestException catch (error) {
      if (error.code == 'PGRST116') {
        return const _PartialSnapshot();
      }
      throw DietProfileRepositoryException(
        '운동 목표 정보를 불러오지 못했습니다.',
        cause: error,
      );
    } catch (error) {
      throw DietProfileRepositoryException(
        '운동 목표 정보를 읽는 중 알 수 없는 오류가 발생했습니다.',
        cause: error,
      );
    }
  }

  Future<_PartialSnapshot> _loadDietGoal(String userId) async {
    try {
      final result = await _client
          .from('dietgoal')
          .select('diet_type, daily_calorie_target, meals_per_day, created_at')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle() as Map<String, dynamic>?;

      if (result == null) {
        return const _PartialSnapshot();
      }

      return _PartialSnapshot(
        goalType: _asString(result['diet_type']),
        targetCalories: _asDouble(result['daily_calorie_target']),
        mealsPerDay: _asInt(result['meals_per_day']),
        dietType: _asString(result['diet_type']),
        dietaryRestrictions: _asStringList(result['dietary_restrictions']),
      );
    } on PostgrestException catch (error) {
      // 목표 정보가 없는 경우는 허용하고, 다른 오류만 보고한다.
      if (error.code == 'PGRST116') {
        return const _PartialSnapshot();
      }
      throw DietProfileRepositoryException(
        '식단 목표 정보를 불러오지 못했습니다.',
        cause: error,
      );
    } catch (error) {
      throw DietProfileRepositoryException(
        '식단 목표 정보를 읽는 중 알 수 없는 오류가 발생했습니다.',
        cause: error,
      );
    }
  }

  Future<String> _getWorkoutGoalTable() async {
    if (_resolvedWorkoutGoalTable != null) {
      return _resolvedWorkoutGoalTable!;
    }

    for (final table in _workoutGoalTableCandidates) {
      try {
        await _client.from(table).select('user_id').limit(1);
        _resolvedWorkoutGoalTable = table;
        return table;
      } on PostgrestException catch (error) {
        final code = error.code ?? '';
        final message = (error.message ?? '').toLowerCase();
        if (code == '42P01' || message.contains('does not exist') || message.contains('relation')) {
          continue;
        }
        rethrow;
      }
    }

    _resolvedWorkoutGoalTable = _workoutGoalTableCandidates.last;
    return _resolvedWorkoutGoalTable!;
  }

  Future<_PartialSnapshot> _estimateMealsPerDay(String userId) async {
    final since = DateTime.now().subtract(const Duration(days: 7));
    try {
      final result = await _client
          .from('usermeal')
          .select('meal_time')
          .eq('user_id', userId)
          .gte('meal_time', since.toIso8601String()) as List<dynamic>;

      if (result.isEmpty) {
        return const _PartialSnapshot(mealsPerDay: 3);
      }

      final mealsByDay = <DateTime, int>{};
      for (final rawRow in result) {
        if (rawRow is! Map<String, dynamic>) {
          continue;
        }
        final row = rawRow;
        final raw = row['meal_time'];
        final mealTime = _asDateTime(raw);
        if (mealTime == null) {
          continue;
        }
        final day = DateTime(mealTime.year, mealTime.month, mealTime.day);
        mealsByDay.update(day, (value) => value + 1, ifAbsent: () => 1);
      }

      if (mealsByDay.isEmpty) {
        return const _PartialSnapshot();
      }

      final totalMeals = mealsByDay.values.fold<int>(0, (sum, value) => sum + value);
      final averageMeals = totalMeals / mealsByDay.length;
      final rounded = averageMeals.clamp(1, 6).round();

      return _PartialSnapshot(mealsPerDay: rounded);
    } on PostgrestException catch (error) {
      // 식단 기록이 없으면 빈 배열을 반환하므로 여기까지 오지 않는다.
      throw DietProfileRepositoryException(
        '식단 기록을 불러오지 못했습니다.',
        cause: error,
      );
    } catch (error) {
      return const _PartialSnapshot(mealsPerDay: 3);
    }
  }
}

class _PartialSnapshot {
  const _PartialSnapshot({
    this.goalType,
    this.targetCalories,
    this.levelValue,
    this.levelLabel,
    this.weightKg,
    this.mealsPerDay,
    this.dietType,
    this.dietaryRestrictions,
  });

  final String? goalType;
  final double? targetCalories;
  final int? levelValue;
  final String? levelLabel;
  final double? weightKg;
  final int? mealsPerDay;
  final String? dietType;
  final List<String>? dietaryRestrictions;
}

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) {
    return int.tryParse(value);
  }
  return null;
}

double? _asDouble(dynamic value) {
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is num) return value.toDouble();
  if (value is String) {
    return double.tryParse(value);
  }
  return null;
}

String? _asString(dynamic value) {
  if (value == null) return null;
  if (value is String) return value.trim().isEmpty ? null : value.trim();
  return value.toString();
}

List<String>? _asStringList(dynamic value) {
  if (value == null) return null;
  if (value is List) {
    final results = <String>[];
    for (final item in value) {
      final text = _asString(item);
      if (text != null && text.isNotEmpty) {
        results.add(text);
      }
    }
    return results.isEmpty ? null : results;
  }
  if (value is String && value.trim().isNotEmpty) {
    return value
        .split(',')
        .map((entry) => entry.trim())
        .where((entry) => entry.isNotEmpty)
        .toList(growable: false);
  }
  return null;
}

DateTime? _asDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value.toLocal();
  if (value is String) {
    return DateTime.tryParse(value)?.toLocal();
  }
  return null;
}

int? _mapLevelToValue(String? raw) {
  switch (raw) {
    case 'beginner':
      return 1;
    case 'intermediate':
      return 2;
    case 'advanced':
      return 3;
    default:
      return null;
  }
}

String? _mapLevelToLabel(String? raw) {
  switch (raw) {
    case 'beginner':
      return '초급';
    case 'intermediate':
      return '중급';
    case 'advanced':
      return '고급';
    default:
      return null;
  }
}
