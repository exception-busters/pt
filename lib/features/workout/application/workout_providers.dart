import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import '../data/supabase_workout_service.dart';
import '../domain/models/supabase_exercise.dart';
import '../domain/models/supabase_workout_routine.dart';
import '../domain/models/supabase_routine_exercise.dart';

class Exercise {
  final String id;
  final String name;
  final String description;
  final int duration; // 초 단위
  final String category;

  Exercise({
    required this.id,
    required this.name,
    required this.description,
    required this.duration,
    required this.category,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'duration': duration,
      'category': category,
    };
  }

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      duration: json['duration'],
      category: json['category'],
    );
  }
}

class WorkoutRoutine {
  final String id;
  final String name;
  final List<Exercise> exercises;
  final DateTime createdAt;

  WorkoutRoutine({
    required this.id,
    required this.name,
    required this.exercises,
    required this.createdAt,
  });

  int get totalDuration => exercises.fold(0, (sum, exercise) => sum + exercise.duration);

  String get formattedDuration {
    final minutes = totalDuration ~/ 60;
    final seconds = totalDuration % 60;
    if (minutes > 0) {
      return '${minutes}분 ${seconds}초';
    } else {
      return '${seconds}초';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'exercises': exercises.map((e) => e.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory WorkoutRoutine.fromJson(Map<String, dynamic> json) {
    return WorkoutRoutine(
      id: json['id'],
      name: json['name'],
      exercises: (json['exercises'] as List)
          .map((e) => Exercise.fromJson(e))
          .toList(),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  WorkoutRoutine copyWith({
    String? id,
    String? name,
    List<Exercise>? exercises,
    DateTime? createdAt,
  }) {
    return WorkoutRoutine(
      id: id ?? this.id,
      name: name ?? this.name,
      exercises: exercises ?? this.exercises,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class WorkoutRoutineController extends StateNotifier<List<WorkoutRoutine>> {
  WorkoutRoutineController() : super([]) {
    _loadRoutines();
  }

  static const String _routinesKey = 'workout_routines';

  // 기본 운동 목록
  static final List<Exercise> availableExercises = [
    Exercise(
      id: 'plank',
      name: '플랭크',
      description: '코어 근육을 강화하는 운동',
      duration: 60,
      category: '코어',
    ),
    Exercise(
      id: 'squat',
      name: '스쿼트',
      description: '하체 근육을 강화하는 운동',
      duration: 45,
      category: '하체',
    ),
    Exercise(
      id: 'lunge',
      name: '런지',
      description: '하체와 균형감각을 기르는 운동',
      duration: 60,
      category: '하체',
    ),
    Exercise(
      id: 'pushup',
      name: '팔굽혀펴기',
      description: '상체 근육을 강화하는 운동',
      duration: 45,
      category: '상체',
    ),
    Exercise(
      id: 'burpee',
      name: '버피',
      description: '전신 운동으로 체력 향상',
      duration: 60,
      category: '전신',
    ),
    Exercise(
      id: 'jumping_jack',
      name: '점핑잭',
      description: '유산소 운동으로 심박수 증가',
      duration: 30,
      category: '유산소',
    ),
    Exercise(
      id: 'mountain_climber',
      name: '마운틴 클라이머',
      description: '코어와 유산소를 동시에',
      duration: 45,
      category: '전신',
    ),
    Exercise(
      id: 'wall_sit',
      name: '벽 스쿼트',
      description: '하체 지구력을 기르는 운동',
      duration: 60,
      category: '하체',
    ),
    Exercise(
      id: 'high_knees',
      name: '하이니',
      description: '무릎을 높이 올리는 유산소 운동',
      duration: 30,
      category: '유산소',
    ),
    Exercise(
      id: 'crunches',
      name: '크런치',
      description: '복근을 강화하는 운동',
      duration: 45,
      category: '코어',
    ),
  ];

  Future<void> _loadRoutines() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final routinesJson = prefs.getString(_routinesKey);
      if (routinesJson != null) {
        final List<dynamic> routinesList = json.decode(routinesJson);
        state = routinesList.map((json) => WorkoutRoutine.fromJson(json)).toList();
      }
    } catch (e) {
      // 에러 발생 시 빈 리스트 유지
    }
  }

  Future<void> _saveRoutines() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final routinesJson = json.encode(state.map((routine) => routine.toJson()).toList());
      await prefs.setString(_routinesKey, routinesJson);
    } catch (e) {
      // 에러 처리
    }
  }

  Future<void> addRoutine(WorkoutRoutine routine) async {
    state = [...state, routine];
    await _saveRoutines();
  }

  Future<void> updateRoutine(String id, WorkoutRoutine updatedRoutine) async {
    state = state.map((routine) {
      return routine.id == id ? updatedRoutine : routine;
    }).toList();
    await _saveRoutines();
  }

  Future<void> deleteRoutine(String id) async {
    state = state.where((routine) => routine.id != id).toList();
    await _saveRoutines();
  }
}

final workoutRoutineControllerProvider = StateNotifierProvider<WorkoutRoutineController, List<WorkoutRoutine>>(
  (ref) => WorkoutRoutineController(),
);

// AI 추천 루틴 생성기
class AIRecommendedRoutines {
  static List<WorkoutRoutine> getRecommendedRoutines(List<Exercise> availableExercises) {
    final now = DateTime.now();
    
    // 운동 이름으로 찾는 헬퍼 함수
    Exercise? findExerciseByName(String name) {
      try {
        return availableExercises.firstWhere((e) => e.name.contains(name));
      } catch (e) {
        return null;
      }
    }
    
    return [
      // 초보자용 루틴
      WorkoutRoutine(
        id: 'ai_beginner',
        name: '🤖 AI 추천: 초보자 전신 운동',
        exercises: [
          findExerciseByName('스쿼트'),
          findExerciseByName('푸쉬업'),
          findExerciseByName('플랭크'),
        ].where((e) => e != null).cast<Exercise>().toList(),
        createdAt: now,
      ),
      
      // 코어 집중 루틴
      WorkoutRoutine(
        id: 'ai_core',
        name: '🤖 AI 추천: 코어 강화 집중',
        exercises: [
          findExerciseByName('플랭크'),
          findExerciseByName('데드리프트'),
        ].where((e) => e != null).cast<Exercise>().toList(),
        createdAt: now,
      ),
      
      // 하체 집중 루틴
      WorkoutRoutine(
        id: 'ai_lower',
        name: '🤖 AI 추천: 하체 근력 강화',
        exercises: [
          findExerciseByName('스쿼트'),
          findExerciseByName('런지'),
          findExerciseByName('데드리프트'),
        ].where((e) => e != null).cast<Exercise>().toList(),
        createdAt: now,
      ),
      
      // 고강도 루틴
      WorkoutRoutine(
        id: 'ai_hiit',
        name: '🤖 AI 추천: 고강도 인터벌',
        exercises: availableExercises.take(3).toList(), // 처음 3개 운동 사용
        createdAt: now,
      ),
    ];
  }
  
  // 사용자 레벨에 따른 추천 루틴 (추후 프로필 연동 가능)
  static List<WorkoutRoutine> getPersonalizedRoutines(String userLevel, List<Exercise> availableExercises) {
    final allRoutines = getRecommendedRoutines(availableExercises);
    
    switch (userLevel.toLowerCase()) {
      case '초급':
        return [allRoutines[0], allRoutines[1]]; // 초보자, 코어
      case '중급':
        return [allRoutines[1], allRoutines[2]]; // 코어, 하체
      case '고급':
        return [allRoutines[2], allRoutines[3]]; // 하체, 고강도
      default:
        return allRoutines.take(2).toList(); // 기본적으로 처음 2개
    }
  }
}

final aiRecommendedRoutinesProvider = FutureProvider<List<WorkoutRoutine>>((ref) async {
  final exercisesAsync = await ref.watch(databaseExercisesProvider.future);
  return AIRecommendedRoutines.getRecommendedRoutines(exercisesAsync);
});

// Supabase 연동 프로바이더들
final supabaseWorkoutServiceProvider = Provider<SupabaseWorkoutService>((ref) => SupabaseWorkoutService());

// 데이터베이스에서 운동 목록을 가져오는 프로바이더
final databaseExercisesProvider = FutureProvider<List<Exercise>>((ref) async {
  final service = ref.read(supabaseWorkoutServiceProvider);
  try {
    final supabaseExercises = await service.getAllExercises();
    return supabaseExercises.map((supabaseExercise) => Exercise(
      id: supabaseExercise.exerciseId.toString(),
      name: supabaseExercise.name,
      description: supabaseExercise.description ?? '운동 설명이 없습니다.',
      duration: _getDurationByDifficulty(supabaseExercise.difficulty ?? '초급'),
      category: supabaseExercise.bodyPart,
    )).toList();
  } catch (e) {
    print('데이터베이스에서 운동 목록 가져오기 실패: $e');
    // 실패 시 하드코딩된 운동 목록 반환
    return WorkoutRoutineController.availableExercises;
  }
});

// 난이도에 따른 기본 운동 시간 설정
int _getDurationByDifficulty(String difficulty) {
  switch (difficulty) {
    case '초급':
      return 30;
    case '중급':
    case '중간':
      return 45;
    case '고급':
      return 60;
    default:
      return 45;
  }
}

// 루틴 생성 상태를 관리하는 클래스
class RoutineCreationState {
  final bool isCreating;
  final String? currentStep;
  final double progress;
  final String? error;

  const RoutineCreationState({
    this.isCreating = false,
    this.currentStep,
    this.progress = 0.0,
    this.error,
  });

  RoutineCreationState copyWith({
    bool? isCreating,
    String? currentStep,
    double? progress,
    String? error,
  }) {
    return RoutineCreationState(
      isCreating: isCreating ?? this.isCreating,
      currentStep: currentStep ?? this.currentStep,
      progress: progress ?? this.progress,
      error: error ?? this.error,
    );
  }
}

// Supabase 루틴 관리 NotifierProvider
class SupabaseRoutineNotifier extends StateNotifier<AsyncValue<List<SupabaseWorkoutRoutine>>> {
  SupabaseRoutineNotifier(this._service) : super(const AsyncValue.loading()) {
    loadRoutines();
  }

  final SupabaseWorkoutService _service;

  Future<void> loadRoutines() async {
    try {
      state = const AsyncValue.loading();
      final routines = await _service.getUserRoutines();
      state = AsyncValue.data(routines);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<bool> createRoutine(String title, String? description, List<Exercise> exercises) async {
    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('사용자가 로그인되지 않았습니다.');
      }

      print('🚀 루틴 생성 시작: $title (운동 ${exercises.length}개)');
      
      // 1. 운동 ID 매핑 (기존 운동 확인 및 새 운동 생성)
      final List<Map<String, dynamic>> exerciseData = [];
      
      for (int i = 0; i < exercises.length; i++) {
        final exercise = exercises[i];
        print('📝 운동 처리 중 (${i + 1}/${exercises.length}): ${exercise.name}');
        
        // 기존 운동이 있는지 확인
        SupabaseExercise? supabaseExercise = await _service.getExerciseByName(exercise.name);
        
        if (supabaseExercise == null) {
          // 새 운동 생성
          final newExercise = SupabaseExercise(
            name: exercise.name,
            bodyPart: exercise.category,
            description: exercise.description,
            difficulty: '초급', // 기본값
          );
          
          supabaseExercise = await _service.insertExercise(newExercise);
          if (supabaseExercise == null) {
            throw Exception('운동 생성 실패: ${exercise.name}');
          }
          print('✅ 새 운동 생성: ${supabaseExercise.name} (ID: ${supabaseExercise.exerciseId})');
        } else {
          print('✅ 기존 운동 사용: ${supabaseExercise.name} (ID: ${supabaseExercise.exerciseId})');
        }
        
        // 운동 데이터 추가
        exerciseData.add({
          'exercise_id': supabaseExercise.exerciseId!,
          'sets': 3, // 기본값
          'reps': (exercise.duration ~/ 5).clamp(5, 20), // duration 기반 reps 계산 (5-20 범위)
          'rest_time_sec': 60, // 기본값
        });
      }

      print('📊 운동 데이터 준비 완료: ${exerciseData.length}개');

      // 2. 단순 INSERT를 사용한 루틴 생성
      final insertedRoutine = await _service.createCompleteRoutine(
        title: title,
        description: description ?? '사용자가 생성한 운동 루틴',
        exercises: exerciseData,
      );

      if (insertedRoutine != null) {
        print('🎉 루틴 생성 완료: ${insertedRoutine.title} (ID: ${insertedRoutine.routineId})');
        
        // 3. 루틴 목록 새로고침
        await loadRoutines();
        return true;
      } else {
        throw Exception('루틴 생성 실패');
      }
      
    } catch (e) {
      print('❌ 루틴 생성 실패: $e');
      return false;
    }
  }

  Future<bool> updateRoutine(int routineId, String title, String? description, List<Exercise> exercises) async {
    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('사용자가 로그인되지 않았습니다.');
      }

      print('🔄 루틴 업데이트 시작: $title (운동 ${exercises.length}개)');
      
      // 1. 운동 ID 매핑 (기존 운동 확인 및 새 운동 생성)
      final List<Map<String, dynamic>> exerciseData = [];
      
      for (int i = 0; i < exercises.length; i++) {
        final exercise = exercises[i];
        print('📝 운동 처리 중 (${i + 1}/${exercises.length}): ${exercise.name}');
        
        // 기존 운동이 있는지 확인
        SupabaseExercise? supabaseExercise = await _service.getExerciseByName(exercise.name);
        
        if (supabaseExercise == null) {
          // 새 운동 생성
          final newExercise = SupabaseExercise(
            name: exercise.name,
            bodyPart: exercise.category,
            description: exercise.description,
            difficulty: '초급', // 기본값
          );
          
          supabaseExercise = await _service.insertExercise(newExercise);
          if (supabaseExercise == null) {
            throw Exception('운동 생성 실패: ${exercise.name}');
          }
          print('✅ 새 운동 생성: ${supabaseExercise.name} (ID: ${supabaseExercise.exerciseId})');
        } else {
          print('✅ 기존 운동 사용: ${supabaseExercise.name} (ID: ${supabaseExercise.exerciseId})');
        }
        
        // 운동 데이터 추가
        exerciseData.add({
          'exercise_id': supabaseExercise.exerciseId!,
          'sets': 3, // 기본값
          'reps': (exercise.duration ~/ 5).clamp(5, 20), // duration 기반 reps 계산 (5-20 범위)
          'rest_time_sec': 60, // 기본값
        });
      }

      print('📊 운동 데이터 준비 완료: ${exerciseData.length}개');

      // 2. 루틴 업데이트
      final success = await _service.updateRoutine(
        routineId: routineId,
        title: title,
        description: description ?? '사용자가 수정한 운동 루틴',
        exercises: exerciseData,
      );

      if (success) {
        print('🎉 루틴 업데이트 완료: $title (ID: $routineId)');
        
        // 3. 루틴 목록 새로고침
        await loadRoutines();
        return true;
      } else {
        throw Exception('루틴 업데이트 실패');
      }
      
    } catch (e) {
      print('❌ 루틴 업데이트 실패: $e');
      return false;
    }
  }

  Future<bool> deleteRoutine(int routineId) async {
    try {
      await _service.deleteRoutine(routineId);
      await loadRoutines();
      return true;
    } catch (e) {
      print('❌ 루틴 삭제 실패: $e');
      return false;
    }
  }
}

final supabaseRoutineNotifierProvider = StateNotifierProvider<SupabaseRoutineNotifier, AsyncValue<List<SupabaseWorkoutRoutine>>>((ref) {
  final service = ref.read(supabaseWorkoutServiceProvider);
  return SupabaseRoutineNotifier(service);
});

// 루틴 생성 상태 관리 프로바이더
class RoutineCreationNotifier extends StateNotifier<RoutineCreationState> {
  RoutineCreationNotifier() : super(const RoutineCreationState());

  void startCreation() {
    state = state.copyWith(
      isCreating: true,
      currentStep: '루틴 생성 준비 중...',
      progress: 0.1,
      error: null,
    );
  }

  void updateProgress(String step, double progress) {
    state = state.copyWith(
      currentStep: step,
      progress: progress,
    );
  }

  void completeCreation() {
    state = state.copyWith(
      isCreating: false,
      currentStep: '루틴 생성 완료!',
      progress: 1.0,
    );
    
    // 2초 후 상태 초기화
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        state = const RoutineCreationState();
      }
    });
  }

  void setError(String error) {
    state = state.copyWith(
      isCreating: false,
      error: error,
      progress: 0.0,
    );
  }

  void reset() {
    state = const RoutineCreationState();
  }
}

final routineCreationNotifierProvider = StateNotifierProvider<RoutineCreationNotifier, RoutineCreationState>((ref) {
  return RoutineCreationNotifier();
});