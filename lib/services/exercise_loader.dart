import 'package:flutter/services.dart';
import '../models/exercise_model.dart';

/// 운동 데이터 로더
class ExerciseLoader {
  static ExerciseReferenceData? _cachedData;

  /// JSON 파일에서 운동 데이터 로드
  static Future<ExerciseReferenceData> loadExercises() async {
    if (_cachedData != null) {
      return _cachedData!;
    }

    try {
      final String jsonString = await rootBundle.loadString('assets/exercise_reference.json');
      _cachedData = ExerciseReferenceData.fromJsonString(jsonString);
      print('운동 데이터 로드 완료: ${_cachedData!.exercises.length}개');
      return _cachedData!;
    } catch (e) {
      print('운동 데이터 로드 실패: $e');
      rethrow;
    }
  }

  /// 특정 운동 ID로 운동 찾기
  static Future<ExerciseModel?> getExerciseById(String exerciseId) async {
    final data = await loadExercises();
    try {
      return data.exercises.firstWhere(
        (exercise) => exercise.exerciseId == exerciseId,
      );
    } catch (e) {
      print('운동 ID $exerciseId를 찾을 수 없습니다');
      return null;
    }
  }

  /// 모든 운동 목록 가져오기
  static Future<List<ExerciseModel>> getAllExercises() async {
    final data = await loadExercises();
    return data.exercises;
  }

  /// 카테고리별 운동 필터링
  static Future<List<ExerciseModel>> getExercisesByCategory(String category) async {
    final data = await loadExercises();
    return data.exercises.where((exercise) => exercise.category == category).toList();
  }

  /// 캐시 초기화
  static void clearCache() {
    _cachedData = null;
  }
}

