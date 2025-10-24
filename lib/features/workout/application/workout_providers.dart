import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

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