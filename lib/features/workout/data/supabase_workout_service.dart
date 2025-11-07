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
          .from('exercise')
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
          .from('routine')
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
          .from('routine_exercise')
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
          .from('workoutsession')
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
          .from('workoutrecords')
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

  // 사용자 루틴 조회 (운동 정보 포함) - 현재 로그인한 사용자만
  Future<List<SupabaseWorkoutRoutine>> getUserRoutines() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        print('❌ 사용자가 로그인되지 않았습니다.');
        throw Exception('사용자가 로그인되지 않았습니다.');
      }

      print('🔍 사용자 루틴 조회 시작: ${currentUser.id}');

      // 현재 로그인한 사용자의 루틴만 조회
      final response = await _supabase
          .from('routine')
          .select('''
            *,
            routine_exercise (
              *,
              exercise (
                *
              )
            )
          ''')
          .eq('user_id', currentUser.id) // 현재 사용자 ID로 필터링
          .order('created_at', ascending: false);
      
      print('✅ 루틴 조회 성공: ${response.length}개 루틴 발견 (사용자: ${currentUser.id})');
      
      // 추가 보안: 응답 데이터에서도 사용자 ID 확인
      final filteredRoutines = (response as List)
          .where((json) => json['user_id'] == currentUser.id)
          .map((json) => SupabaseWorkoutRoutine.fromJson(json))
          .toList();
      
      print('🔒 보안 필터링 완료: ${filteredRoutines.length}개 루틴 반환');
      
      return filteredRoutines;
    } catch (e) {
      print('❌ 사용자 루틴 조회 실패: $e');
      return [];
    }
  }

  // 모든 운동 조회 (exercise 테이블 사용)
  Future<List<SupabaseExercise>> getAllExercises() async {
    try {
      print('🔍 exercise 테이블 조회 시작...');
      
      final response = await _supabase
          .from('exercise')
          .select()
          .order('exercise_id', ascending: true);
      
      print('✅ 조회 성공: ${response.length}개 운동 발견');
      
      return (response as List)
          .map((json) => SupabaseExercise.fromJson(json))
          .toList();
    } catch (e, stackTrace) {
      print('❌ 모든 운동 조회 실패: $e');
      print('스택 트레이스: $stackTrace');
      
      // 테이블이 없는 경우 안내
      if (e.toString().contains('exercise') || e.toString().contains('PGRST205')) {
        print('⚠️ exercise 테이블을 찾을 수 없습니다. Supabase 스키마 캐시를 새로고침해야 할 수 있습니다.');
        print('💡 Supabase 대시보드 > API > Settings > Schema Cache에서 새로고침하거나, 몇 분 후 다시 시도해주세요.');
      }
      
      return [];
    }
  }

  // exercise 테이블에서 운동 조회 (새로운 메서드)
  Future<List<Map<String, dynamic>>> getExerciseList() async {
    try {
      final response = await _supabase
          .from('exercise')
          .select()
          .order('exercise_id', ascending: true);
      
      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      print('❌ exercise 조회 실패: $e');
      return [];
    }
  }

  // exercise의 id로 운동 조회
  Future<SupabaseExercise?> getExerciseByListId(int exerciseId) async {
    try {
      final response = await _supabase
          .from('exercise')
          .select()
          .eq('exercise_id', exerciseId)
          .maybeSingle();
      
      if (response != null) {
        return SupabaseExercise.fromJson(response);
      }
      return null;
    } catch (e) {
      print('❌ exercise ID $exerciseId 조회 실패: $e');
      return null;
    }
  }

  // 운동 이름으로 검색 (exercise 테이블 사용)
  Future<SupabaseExercise?> getExerciseByName(String name) async {
    try {
      final response = await _supabase
          .from('exercise')
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

  // 단순 INSERT를 사용한 루틴 생성 메서드
  Future<SupabaseWorkoutRoutine?> createCompleteRoutine({
    required String title,
    String? description,
    required List<Map<String, dynamic>> exercises, // {exercise_id, sets, reps, rest_time_sec}
  }) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('사용자가 로그인되지 않았습니다.');
      }

      print('🚀 루틴 생성 시작: $title');
      print('👤 사용자 ID: ${currentUser.id}');
      print('📋 운동 데이터: $exercises');

      // 1단계: WorkoutRoutine 테이블에 INSERT하고 routine_id 가져오기
      final routineData = {
        'user_id': currentUser.id,
        'title': title,
        'description': description ?? '',
      };

      print('📝 루틴 데이터 삽입 중...');
      final routineResponse = await _supabase
          .from('routine')
          .insert(routineData)
          .select()
          .single();

      print('✅ 루틴 삽입 성공: $routineResponse');
      
      final insertedRoutine = SupabaseWorkoutRoutine.fromJson(routineResponse);
      final routineId = insertedRoutine.routineId!;
      
      print('🎯 생성된 routine_id: $routineId');

      // 2단계: RoutineExercise 테이블에 각 운동 INSERT
      print('📋 운동 데이터 삽입 시작 (${exercises.length}개)...');
      
      for (int i = 0; i < exercises.length; i++) {
        final exercise = exercises[i];
        
        final routineExerciseData = {
          'routine_id': routineId,
          'exercise_id': exercise['exercise_id'],
          'sets': exercise['sets'],
          'reps': exercise['reps'],
          'rest_time_sec': exercise['rest_time_sec'] ?? 60,
        };

        print('📝 운동 ${i + 1}/${exercises.length} 삽입 중: $routineExerciseData');
        
        final exerciseResponse = await _supabase
            .from('routine_exercise')
            .insert(routineExerciseData)
            .select()
            .single();
            
        print('✅ 운동 삽입 성공: $exerciseResponse');
      }

      print('🎉 루틴 생성 완료: ${insertedRoutine.title} (ID: $routineId)');
      return insertedRoutine;

    } catch (e) {
      print('❌ 루틴 생성 실패: $e');
      
      // 에러 타입별 상세 로깅
      if (e.toString().contains('duplicate key')) {
        print('💡 중복 키 에러 - 이미 존재하는 데이터');
      } else if (e.toString().contains('foreign key')) {
        print('💡 외래키 제약 위반 - 참조하는 데이터가 존재하지 않음');
      } else if (e.toString().contains('not-null')) {
        print('💡 필수 필드 누락');
      } else if (e.toString().contains('permission')) {
        print('💡 권한 부족 - RLS 정책 확인 필요');
      }
      
      return null;
    }
  }

  // 단순한 루틴 생성 메서드 (개별 INSERT 방식)
  Future<SupabaseWorkoutRoutine?> createRoutineSimple({
    required String title,
    String? description,
    required List<Map<String, dynamic>> exercises,
  }) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('사용자가 로그인되지 않았습니다.');
      }

      print('🔄 단순 INSERT 방식으로 루틴 생성: $title');

      // 1단계: WorkoutRoutine INSERT
      final routineData = {
        'user_id': currentUser.id,
        'title': title,
        'description': description ?? '',
      };

      final routineResponse = await _supabase
          .from('routine')
          .insert(routineData)
          .select()
          .single();

      final insertedRoutine = SupabaseWorkoutRoutine.fromJson(routineResponse);
      final routineId = insertedRoutine.routineId!;

      print('✅ 루틴 생성 성공: ID $routineId');

      // 2단계: RoutineExercise INSERT (각각 개별적으로)
      for (int i = 0; i < exercises.length; i++) {
        final exercise = exercises[i];
        
        try {
          final routineExerciseData = {
            'routine_id': routineId,
            'exercise_id': exercise['exercise_id'],
            'sets': exercise['sets'] ?? 3,
            'reps': exercise['reps'] ?? 10,
            'rest_time_sec': exercise['rest_time_sec'] ?? 60,
          };

          await _supabase
              .from('routine_exercise')
              .insert(routineExerciseData);

          print('✅ 운동 ${i + 1} 추가 성공');
        } catch (e) {
          print('⚠️ 운동 ${i + 1} 추가 실패: $e');
          // 개별 운동 실패는 전체를 중단하지 않음
        }
      }

      print('✅ 단순 루틴 생성 완료: $title');
      return insertedRoutine;
    } catch (e) {
      print('❌ 단순 루틴 생성 실패: $e');
      return null;
    }
  }

  // 루틴 업데이트 (현재 사용자의 루틴만)
  Future<bool> updateRoutine({
    required int routineId,
    required String title,
    String? description,
    required List<Map<String, dynamic>> exercises,
  }) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        print('❌ 사용자가 로그인되지 않았습니다.');
        throw Exception('사용자가 로그인되지 않았습니다.');
      }

      print('🔄 루틴 업데이트 시작: ID $routineId (사용자: ${currentUser.id})');

      // 현재 사용자의 루틴인지 먼저 확인
      final routineCheck = await _supabase
          .from('routine')
          .select('user_id')
          .eq('routine_id', routineId)
          .eq('user_id', currentUser.id)
          .maybeSingle();

      if (routineCheck == null) {
        print('❌ 업데이트 권한 없음: 루틴 ID $routineId는 현재 사용자의 루틴이 아닙니다.');
        throw Exception('업데이트 권한이 없습니다.');
      }

      // 1단계: WorkoutRoutine 업데이트
      await _supabase
          .from('routine')
          .update({
            'title': title,
            'description': description ?? '',
          })
          .eq('routine_id', routineId)
          .eq('user_id', currentUser.id);

      print('✅ 루틴 기본 정보 업데이트 완료');

      // 2단계: 기존 RoutineExercise 삭제
      await _supabase
          .from('routine_exercise')
          .delete()
          .eq('routine_id', routineId);

      print('✅ 기존 운동 목록 삭제 완료');

      // 3단계: 새로운 RoutineExercise 추가
      for (int i = 0; i < exercises.length; i++) {
        final exercise = exercises[i];
        
        try {
          final routineExerciseData = {
            'routine_id': routineId,
            'exercise_id': exercise['exercise_id'],
            'sets': exercise['sets'] ?? 3,
            'reps': exercise['reps'] ?? 10,
            'rest_time_sec': exercise['rest_time_sec'] ?? 60,
          };

          await _supabase
              .from('routine_exercise')
              .insert(routineExerciseData);

          print('✅ 운동 ${i + 1} 추가 성공');
        } catch (e) {
          print('⚠️ 운동 ${i + 1} 추가 실패: $e');
        }
      }

      print('✅ 루틴 업데이트 완료: ID $routineId');
      return true;
    } catch (e) {
      print('❌ 루틴 업데이트 실패: $e');
      return false;
    }
  }

  // 루틴 삭제 (현재 사용자의 루틴만)
  Future<bool> deleteRoutine(int routineId) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        print('❌ 사용자가 로그인되지 않았습니다.');
        throw Exception('사용자가 로그인되지 않았습니다.');
      }

      print('🗑️ 루틴 삭제 시작: ID $routineId (사용자: ${currentUser.id})');

      // 현재 사용자의 루틴인지 먼저 확인
      final routineCheck = await _supabase
          .from('routine')
          .select('user_id')
          .eq('routine_id', routineId)
          .eq('user_id', currentUser.id) // 현재 사용자의 루틴인지 확인
          .maybeSingle();

      if (routineCheck == null) {
        print('❌ 삭제 권한 없음: 루틴 ID $routineId는 현재 사용자의 루틴이 아닙니다.');
        throw Exception('삭제 권한이 없습니다.');
      }

      // 현재 사용자의 루틴만 삭제
      await _supabase
          .from('routine')
          .delete()
          .eq('routine_id', routineId)
          .eq('user_id', currentUser.id); // 이중 보안

      print('✅ 루틴 삭제 성공: ID $routineId');
      return true;
    } catch (e) {
      print('❌ 루틴 삭제 실패: $e');
      return false;
    }
  }

  // 간단한 테스트 루틴 생성
  Future<SupabaseWorkoutRoutine?> createTestRoutine() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('사용자가 로그인되지 않았습니다.');
      }

      print('🧪 테스트 루틴 생성 시작...');

      // 1. 기존 운동 ID 확인 (푸시업)
      final pushupExercise = await getExerciseByName('푸시업');
      if (pushupExercise == null) {
        print('❌ 푸시업 운동을 찾을 수 없습니다.');
        return null;
      }

      // 2. 테스트 루틴 생성
      final testTitle = '테스트 루틴 ${DateTime.now().millisecondsSinceEpoch}';
      
      final routineData = {
        'user_id': currentUser.id,
        'title': testTitle,
        'description': '자동 생성된 테스트 루틴',
      };

      final routineResponse = await _supabase
          .from('routine')
          .insert(routineData)
          .select()
          .single();

      final insertedRoutine = SupabaseWorkoutRoutine.fromJson(routineResponse);
      print('✅ 테스트 루틴 생성: ${insertedRoutine.routineId}');

      // 3. 테스트 운동 추가
      final exerciseData = {
        'routine_id': insertedRoutine.routineId!,
        'exercise_id': pushupExercise.exerciseId!,
        'sets': 3,
        'reps': 10,
        'rest_time_sec': 60,
      };

      await _supabase
          .from('routine_exercise')
          .insert(exerciseData);

      print('✅ 테스트 운동 추가 완료');
      return insertedRoutine;

    } catch (e) {
      print('❌ 테스트 루틴 생성 실패: $e');
      return null;
    }
  }

  // 데이터베이스 연결 테스트
  Future<bool> testConnection() async {
    try {
      print('🔍 데이터베이스 연결 테스트 시작...');
      
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        print('❌ 사용자가 로그인되지 않았습니다.');
        return false;
      }
      
      print('✅ 사용자 인증 확인: ${currentUser.id}');
      
      // 간단한 쿼리로 연결 테스트
      await _supabase
          .from('exercise')
          .select('count')
          .limit(1);
      
      print('✅ 데이터베이스 연결 성공');
      print('📊 exercise 테이블 접근 가능');
      
      return true;
    } catch (e) {
      print('❌ 데이터베이스 연결 실패: $e');
      return false;
    }
  }

  // 유틸리티 메서드들
  Future<bool> _checkRoutineExists(int routineId) async {
    try {
      final response = await _supabase
          .from('routine')
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
          .from('exercise')
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
          .from('workoutsession')
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