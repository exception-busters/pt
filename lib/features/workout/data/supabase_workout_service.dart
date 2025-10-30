import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/models/supabase_exercise.dart';
import '../domain/models/supabase_workout_routine.dart';
import '../domain/models/supabase_routine_exercise.dart';
import '../domain/models/supabase_workout_session.dart';
import '../domain/models/supabase_workout_record.dart';

class SupabaseWorkoutService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // 1. Exercise 테이블 데이터 삽입
  Future<SupabaseExercise?> insertExercise(SupabaseExercise exercise) async {
    try {
      print('🏋️ Exercise 삽입 시작: ${exercise.name} (${exercise.bodyPart})');
      
      final response = await _supabase
          .from('Exercise')
          .insert(exercise.toInsertJson())
          .select()
          .single();
      
      final insertedExercise = SupabaseExercise.fromJson(response);
      print('✅ Exercise 삽입 성공! ID: ${insertedExercise.exerciseId}, 이름: ${insertedExercise.name}');
      
      return insertedExercise;
    } catch (e) {
      print('❌ Exercise 삽입 실패: $e');
      print('📋 삽입 시도한 데이터: ${exercise.toInsertJson()}');
      return null;
    }
  }

  // 2. WorkoutRoutine 테이블 데이터 삽입
  Future<SupabaseWorkoutRoutine?> insertWorkoutRoutine(SupabaseWorkoutRoutine routine) async {
    try {
      print('📝 WorkoutRoutine 삽입 시작: ${routine.title} (사용자: ${routine.userId})');
      
      // 사용자 인증 확인
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        print('❌ 사용자가 인증되지 않았습니다.');
        return null;
      }
      
      final response = await _supabase
          .from('WorkoutRoutine')
          .insert(routine.toInsertJson())
          .select()
          .single();
      
      final insertedRoutine = SupabaseWorkoutRoutine.fromJson(response);
      print('✅ WorkoutRoutine 삽입 성공! ID: ${insertedRoutine.routineId}, 제목: ${insertedRoutine.title}');
      
      return insertedRoutine;
    } catch (e) {
      print('❌ WorkoutRoutine 삽입 실패: $e');
      print('📋 삽입 시도한 데이터: ${routine.toInsertJson()}');
      return null;
    }
  }

  // 3. RoutineExercise 테이블 데이터 삽입
  Future<SupabaseRoutineExercise?> insertRoutineExercise(SupabaseRoutineExercise routineExercise) async {
    try {
      print('🔗 RoutineExercise 삽입 시작: 루틴ID ${routineExercise.routineId}, 운동ID ${routineExercise.exerciseId}');
      
      // 외래키 유효성 검사
      final routineExists = await _checkRoutineExists(routineExercise.routineId);
      if (!routineExists) {
        print('❌ 루틴 ID ${routineExercise.routineId}가 존재하지 않습니다.');
        return null;
      }
      
      final exerciseExists = await _checkExerciseExists(routineExercise.exerciseId);
      if (!exerciseExists) {
        print('❌ 운동 ID ${routineExercise.exerciseId}가 존재하지 않습니다.');
        return null;
      }
      
      // sets, reps 유효성 검사
      if (routineExercise.sets <= 0 || routineExercise.reps <= 0) {
        print('❌ 세트 수와 반복 횟수는 0보다 커야 합니다. (세트: ${routineExercise.sets}, 반복: ${routineExercise.reps})');
        return null;
      }
      
      final response = await _supabase
          .from('RoutineExercise')
          .insert(routineExercise.toInsertJson())
          .select()
          .single();
      
      final insertedRoutineExercise = SupabaseRoutineExercise.fromJson(response);
      print('✅ RoutineExercise 삽입 성공! ID: ${insertedRoutineExercise.routineExId}, ${insertedRoutineExercise.sets}세트 x ${insertedRoutineExercise.reps}회');
      
      return insertedRoutineExercise;
    } catch (e) {
      print('❌ RoutineExercise 삽입 실패: $e');
      print('📋 삽입 시도한 데이터: ${routineExercise.toInsertJson()}');
      return null;
    }
  }

  // 4. WorkoutSession 테이블 데이터 삽입
  Future<SupabaseWorkoutSession?> insertWorkoutSession(SupabaseWorkoutSession session) async {
    try {
      print('🏃‍♂️ WorkoutSession 삽입 시작: 사용자 ${session.userId}, 상태: ${session.sessionStatus}');
      
      // 사용자 인증 확인
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        print('❌ 사용자가 인증되지 않았습니다.');
        return null;
      }
      
      // 루틴 ID가 제공된 경우 유효성 검사
      if (session.routineId != null) {
        final routineExists = await _checkRoutineExists(session.routineId!);
        if (!routineExists) {
          print('❌ 루틴 ID ${session.routineId}가 존재하지 않습니다.');
          return null;
        }
      }
      
      final response = await _supabase
          .from('WorkoutSession')
          .insert(session.toInsertJson())
          .select()
          .single();
      
      final insertedSession = SupabaseWorkoutSession.fromJson(response);
      print('✅ WorkoutSession 삽입 성공! ID: ${insertedSession.sessionId}, 시작시간: ${insertedSession.startTime}');
      
      return insertedSession;
    } catch (e) {
      print('❌ WorkoutSession 삽입 실패: $e');
      print('📋 삽입 시도한 데이터: ${session.toInsertJson()}');
      return null;
    }
  }

  // 5. WorkoutRecords 테이블 데이터 삽입
  Future<SupabaseWorkoutRecord?> insertWorkoutRecord(SupabaseWorkoutRecord record) async {
    try {
      print('📊 WorkoutRecord 삽입 시작: 세션ID ${record.sessionId}, 운동ID ${record.exerciseId}, ${record.setNum}세트');
      
      // 외래키 유효성 검사
      final sessionExists = await _checkSessionExists(record.sessionId);
      if (!sessionExists) {
        print('❌ 세션 ID ${record.sessionId}가 존재하지 않습니다.');
        return null;
      }
      
      final exerciseExists = await _checkExerciseExists(record.exerciseId);
      if (!exerciseExists) {
        print('❌ 운동 ID ${record.exerciseId}가 존재하지 않습니다.');
        return null;
      }
      
      // reps_done 유효성 검사
      if (record.repsDone < 0) {
        print('❌ 수행한 반복 횟수는 음수일 수 없습니다: ${record.repsDone}');
        return null;
      }
      
      final response = await _supabase
          .from('WorkoutRecords')
          .insert(record.toInsertJson())
          .select()
          .single();
      
      final insertedRecord = SupabaseWorkoutRecord.fromJson(response);
      print('✅ WorkoutRecord 삽입 성공! ID: ${insertedRecord.recordId}, ${insertedRecord.setNum}세트 - ${insertedRecord.repsDone}회');
      
      return insertedRecord;
    } catch (e) {
      print('❌ WorkoutRecord 삽입 실패: $e');
      print('📋 삽입 시도한 데이터: ${record.toInsertJson()}');
      return null;
    }
  }

  // 순차적 데이터 삽입 (외래키 제약조건 고려)
  Future<Map<String, dynamic>> insertCompleteWorkoutData({
    required List<SupabaseExercise> exercises,
    required SupabaseWorkoutRoutine routine,
    required List<SupabaseRoutineExercise> routineExercises,
    required SupabaseWorkoutSession session,
    required List<SupabaseWorkoutRecord> records,
  }) async {
    print('🚀 완전한 운동 데이터 삽입 시작...');
    print('📊 삽입할 데이터: 운동 ${exercises.length}개, 루틴 1개, 루틴운동 ${routineExercises.length}개, 세션 1개, 기록 ${records.length}개');
    
    final result = <String, dynamic>{
      'success': false,
      'insertedExercises': <SupabaseExercise>[],
      'insertedRoutine': null,
      'insertedRoutineExercises': <SupabaseRoutineExercise>[],
      'insertedSession': null,
      'insertedRecords': <SupabaseWorkoutRecord>[],
      'errors': <String>[],
    };

    try {
      // 1단계: Exercise 삽입
      print('\n1️⃣ Exercise 테이블 삽입 단계');
      for (final exercise in exercises) {
        final insertedExercise = await insertExercise(exercise);
        if (insertedExercise != null) {
          result['insertedExercises'].add(insertedExercise);
        } else {
          result['errors'].add('Exercise 삽입 실패: ${exercise.name}');
          print('⚠️ Exercise 삽입 실패로 인해 전체 프로세스를 중단합니다.');
          return result;
        }
      }

      // 2단계: WorkoutRoutine 삽입
      print('\n2️⃣ WorkoutRoutine 테이블 삽입 단계');
      final insertedRoutine = await insertWorkoutRoutine(routine);
      if (insertedRoutine != null) {
        result['insertedRoutine'] = insertedRoutine;
      } else {
        result['errors'].add('WorkoutRoutine 삽입 실패: ${routine.title}');
        print('⚠️ WorkoutRoutine 삽입 실패로 인해 전체 프로세스를 중단합니다.');
        return result;
      }

      // 3단계: RoutineExercise 삽입 (삽입된 routine_id와 exercise_id 사용)
      print('\n3️⃣ RoutineExercise 테이블 삽입 단계');
      for (int i = 0; i < routineExercises.length; i++) {
        final routineExercise = routineExercises[i];
        final updatedRoutineExercise = SupabaseRoutineExercise(
          routineId: insertedRoutine.routineId!,
          exerciseId: result['insertedExercises'][i].exerciseId!,
          sets: routineExercise.sets,
          reps: routineExercise.reps,
          restTimeSec: routineExercise.restTimeSec,
        );
        
        final insertedRoutineExercise = await insertRoutineExercise(updatedRoutineExercise);
        if (insertedRoutineExercise != null) {
          result['insertedRoutineExercises'].add(insertedRoutineExercise);
        } else {
          result['errors'].add('RoutineExercise 삽입 실패: 루틴ID ${updatedRoutineExercise.routineId}, 운동ID ${updatedRoutineExercise.exerciseId}');
          print('⚠️ RoutineExercise 삽입 실패로 인해 전체 프로세스를 중단합니다.');
          return result;
        }
      }

      // 4단계: WorkoutSession 삽입 (삽입된 routine_id 사용)
      print('\n4️⃣ WorkoutSession 테이블 삽입 단계');
      final updatedSession = SupabaseWorkoutSession(
        userId: session.userId,
        routineId: insertedRoutine.routineId,
        startTime: session.startTime,
        endTime: session.endTime,
        totalCalories: session.totalCalories,
        sessionStatus: session.sessionStatus,
      );
      
      final insertedSession = await insertWorkoutSession(updatedSession);
      if (insertedSession != null) {
        result['insertedSession'] = insertedSession;
      } else {
        result['errors'].add('WorkoutSession 삽입 실패');
        print('⚠️ WorkoutSession 삽입 실패로 인해 전체 프로세스를 중단합니다.');
        return result;
      }

      // 5단계: WorkoutRecords 삽입 (삽입된 session_id와 exercise_id 사용)
      print('\n5️⃣ WorkoutRecords 테이블 삽입 단계');
      for (int i = 0; i < records.length; i++) {
        final record = records[i];
        final updatedRecord = SupabaseWorkoutRecord(
          sessionId: insertedSession.sessionId!,
          exerciseId: result['insertedExercises'][i % result['insertedExercises'].length].exerciseId!,
          setNum: record.setNum,
          repsDone: record.repsDone,
          startTime: record.startTime,
          endTime: record.endTime,
          caloriesBurned: record.caloriesBurned,
        );
        
        final insertedRecord = await insertWorkoutRecord(updatedRecord);
        if (insertedRecord != null) {
          result['insertedRecords'].add(insertedRecord);
        } else {
          result['errors'].add('WorkoutRecord 삽입 실패: 세션ID ${updatedRecord.sessionId}, 운동ID ${updatedRecord.exerciseId}');
          print('⚠️ WorkoutRecord 삽입 실패가 발생했지만 계속 진행합니다.');
        }
      }

      result['success'] = true;
      print('\n🎉 모든 데이터 삽입이 성공적으로 완료되었습니다!');
      print('📈 최종 결과:');
      print('   - 삽입된 운동: ${result['insertedExercises'].length}개');
      print('   - 삽입된 루틴: ${result['insertedRoutine'] != null ? 1 : 0}개');
      print('   - 삽입된 루틴운동: ${result['insertedRoutineExercises'].length}개');
      print('   - 삽입된 세션: ${result['insertedSession'] != null ? 1 : 0}개');
      print('   - 삽입된 기록: ${result['insertedRecords'].length}개');
      
    } catch (e) {
      result['errors'].add('전체 프로세스 오류: $e');
      print('💥 전체 데이터 삽입 프로세스에서 예상치 못한 오류가 발생했습니다: $e');
    }

    return result;
  }

  // 사용자 루틴 조회
  Future<List<SupabaseWorkoutRoutine>> getUserRoutines() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) throw Exception('사용자가 로그인되지 않았습니다.');

      final response = await _supabase
          .from('WorkoutRoutine')
          .select()
          .eq('user_id', currentUser.id)
          .order('created_at', ascending: false);
      
      return (response as List)
          .map((json) => SupabaseWorkoutRoutine.fromJson(json))
          .toList();
    } catch (e) {
      print('❌ 사용자 루틴 조회 실패: $e');
      return [];
    }
  }

  // 운동 이름으로 검색
  Future<SupabaseExercise?> getExerciseByName(String name) async {
    try {
      final response = await _supabase
          .from('Exercise')
          .select()
          .eq('name', name)
          .maybeSingle();
      
      if (response != null) {
        return SupabaseExercise.fromJson(response);
      }
      return null;
    } catch (e) {
      print('❌ 운동 이름 검색 실패: $e');
      return null;
    }
  }

  // 루틴 삭제
  Future<void> deleteRoutine(int routineId) async {
    try {
      await _supabase
          .from('WorkoutRoutine')
          .delete()
          .eq('routine_id', routineId);
      print('✅ 루틴 삭제 성공: ID $routineId');
    } catch (e) {
      print('❌ 루틴 삭제 실패: $e');
      throw Exception('루틴 삭제에 실패했습니다: $e');
    }
  }

  // 유틸리티 메서드들
  Future<bool> _checkRoutineExists(int routineId) async {
    try {
      final response = await _supabase
          .from('WorkoutRoutine')
          .select('routine_id')
          .eq('routine_id', routineId)
          .maybeSingle();
      return response != null;
    } catch (e) {
      print('루틴 존재 확인 오류: $e');
      return false;
    }
  }

  Future<bool> _checkExerciseExists(int exerciseId) async {
    try {
      final response = await _supabase
          .from('Exercise')
          .select('exercise_id')
          .eq('exercise_id', exerciseId)
          .maybeSingle();
      return response != null;
    } catch (e) {
      print('운동 존재 확인 오류: $e');
      return false;
    }
  }

  Future<bool> _checkSessionExists(int sessionId) async {
    try {
      final response = await _supabase
          .from('WorkoutSession')
          .select('session_id')
          .eq('session_id', sessionId)
          .maybeSingle();
      return response != null;
    } catch (e) {
      print('세션 존재 확인 오류: $e');
      return false;
    }
  }
}