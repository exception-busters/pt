import '../models/exercise_model.dart';
import 'exercise_loader.dart';
import '../features/workout/domain/models/supabase_exercise.dart';

/// exercise 테이블과 exercise_reference.json을 매핑하는 유틸리티
class ExerciseMapper {
  /// exercise 테이블의 exercise_id를 exercise_reference.json의 exercise_id로 변환
  /// 1 → "001", 2 → "002", 3 → "003"
  static String exerciseIdToReferenceId(int exerciseId) {
    return exerciseId.toString().padLeft(3, '0');
  }

  /// exercise_reference.json의 exercise_id를 exercise 테이블의 exercise_id로 변환
  /// "001" → 1, "002" → 2, "003" → 3
  static int? referenceIdToExerciseId(String referenceId) {
    try {
      return int.parse(referenceId);
    } catch (e) {
      return null;
    }
  }

  /// exercise 테이블의 exercise_id로 exercise_reference.json에서 운동 데이터 로드
  /// 루틴 실행 시 사용
  static Future<ExerciseModel?> loadExerciseFromExerciseId(int exerciseId) async {
    final referenceId = exerciseIdToReferenceId(exerciseId);
    return await ExerciseLoader.getExerciseById(referenceId);
  }

  /// SupabaseExercise의 id로 exercise_reference.json에서 운동 데이터 로드
  static Future<ExerciseModel?> loadExerciseFromSupabaseExercise(SupabaseExercise supabaseExercise) async {
    if (supabaseExercise.exerciseId == null) {
      return null;
    }
    return await loadExerciseFromExerciseId(supabaseExercise.exerciseId!);
  }

  /// exercise 테이블의 이름으로 exercise_reference.json에서 운동 찾기
  static Future<ExerciseModel?> loadExerciseByName(String name) async {
    // exercise 테이블의 이름과 exercise_reference.json의 exercise_name을 매칭
    final allExercises = await ExerciseLoader.getAllExercises();
    try {
      return allExercises.firstWhere(
        (exercise) => exercise.exerciseName == name,
      );
    } catch (e) {
      print('운동 이름 "$name"을 찾을 수 없습니다');
      return null;
    }
  }
}

