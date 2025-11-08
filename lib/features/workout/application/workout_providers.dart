import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../data/supabase_workout_service.dart';
import '../domain/models/supabase_exercise.dart';
import '../domain/models/supabase_workout_routine.dart';
import '../domain/models/supabase_routine_exercise.dart';
import '../../auth/application/auth_providers.dart';
import '../../profile/application/complete_profile_providers.dart';
import '../../profile/domain/models/workout_goal_model.dart';
import '../../profile/domain/models/user_profile_model.dart';

const bool _enableWorkoutAi = bool.fromEnvironment(
  'ENABLE_WORKOUT_AI',
  defaultValue: true,
);

const String _openAiApiKey = String.fromEnvironment(
  'OPENAI_API_KEY',
  defaultValue: '',
);
const bool _hasOpenAiKey = _openAiApiKey != '';

const String _workoutRecommendationFunction = 'workout-recommendation';

class Exercise {
  final String id;
  final String name;
  final String description;
  final int duration; // 초 단위
  final String category;
  final int? sets;
  final int? reps;
  final int? restSeconds;

  Exercise({
    required this.id,
    required this.name,
    required this.description,
    required this.duration,
    required this.category,
    this.sets,
    this.reps,
    this.restSeconds,
  });

  /// 세트/횟수/휴식 정보를 사용자 친화적인 문자열로 반환
  String get volumeSummary {
    if (sets != null && reps != null) {
      final restPart = restSeconds != null ? ' • 휴식 ${restSeconds}초' : '';
      return '${sets}세트 × ${reps}회$restPart';
    }
    if (duration >= 60) {
      final minutes = duration ~/ 60;
      final seconds = duration % 60;
      return seconds > 0 ? '${minutes}분 ${seconds}초' : '${minutes}분';
    }
    return '${duration}초';
  }

  int get estimatedDurationSeconds {
    if (duration > 0) {
      return duration;
    }
    if (sets != null && reps != null) {
      final approxPerRepSec = 4; // 한 동작당 대략 4초
      final work = sets! * reps! * approxPerRepSec;
      final estimatedRest = restSeconds != null && sets! > 1
          ? restSeconds! * (sets! - 1)
          : 0;
      return work + estimatedRest;
    }
    return 0;
  }

  Exercise copyWith({
    String? id,
    String? name,
    String? description,
    int? duration,
    String? category,
    int? sets,
    int? reps,
    int? restSeconds,
  }) {
    return Exercise(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      duration: duration ?? this.duration,
      category: category ?? this.category,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      restSeconds: restSeconds ?? this.restSeconds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'duration': duration,
      'category': category,
      if (sets != null) 'sets': sets,
      if (reps != null) 'reps': reps,
      if (restSeconds != null) 'restSeconds': restSeconds,
    };
  }

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      duration: json['duration'],
      category: json['category'],
      sets: json['sets'],
      reps: json['reps'],
      restSeconds: json['restSeconds'],
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

  int get totalDuration => exercises.fold(0, (sum, exercise) => sum + exercise.estimatedDurationSeconds);

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
  WorkoutRoutineController(this._ref) : super([]) {
    _loadRoutines();
    
    // 인증 상태 변화 감지
    _ref.listen(authControllerProvider, (previous, next) {
      if (previous?.isLoggedIn == true && !next.isLoggedIn) {
        // 로그아웃 시 상태 초기화
        state = [];
      } else if (previous?.isLoggedIn == false && next.isLoggedIn) {
        // 로그인 시 해당 사용자의 루틴 로드
        _loadRoutines();
      }
    });
  }

  final Ref _ref;

  String _getUserRoutinesKey() {
    final user = Supabase.instance.client.auth.currentUser;
    return user != null ? 'workout_routines_${user.id}' : 'workout_routines_default';
  }

  // 하드코딩된 운동 목록 제거됨 - 이제 Exercise_list 테이블에서만 가져옴

  Future<void> _loadRoutines() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final routinesJson = prefs.getString(_getUserRoutinesKey());
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
      await prefs.setString(_getUserRoutinesKey(), routinesJson);
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
  (ref) => WorkoutRoutineController(ref),
);

class AIRecommendedRoutines {
  static final List<_RoutineTemplate> _templates = [
    _RoutineTemplate(
      id: 'ai_beginner',
      name: '🤖 AI 추천: 초보자 전신 운동',
      blocks: [
        _RoutineBlock(keyword: '스쿼트', sets: 3, reps: 12, restSeconds: 60),
        _RoutineBlock(keyword: '푸쉬업', sets: 3, reps: 10, restSeconds: 60),
        _RoutineBlock(keyword: '플랭크', sets: 3, reps: 40, estimatedDuration: 40, restSeconds: 45),
      ],
    ),
    _RoutineTemplate(
      id: 'ai_core',
      name: '🤖 AI 추천: 코어 강화 집중',
      blocks: [
        _RoutineBlock(keyword: '플랭크', sets: 4, reps: 45, estimatedDuration: 45, restSeconds: 30),
        _RoutineBlock(keyword: '데드버그', sets: 3, reps: 12, restSeconds: 45),
        _RoutineBlock(keyword: '버드독', sets: 3, reps: 16, restSeconds: 40),
      ],
    ),
    _RoutineTemplate(
      id: 'ai_lower',
      name: '🤖 AI 추천: 하체 근력 강화',
      blocks: [
        _RoutineBlock(keyword: '스쿼트', sets: 4, reps: 10, restSeconds: 70),
        _RoutineBlock(keyword: '런지', sets: 3, reps: 12, restSeconds: 60),
        _RoutineBlock(keyword: '데드리프트', sets: 3, reps: 10, restSeconds: 80),
      ],
    ),
    _RoutineTemplate(
      id: 'ai_hiit',
      name: '🤖 AI 추천: 고강도 인터벌',
      blocks: [
        _RoutineBlock(keyword: '버피', sets: 4, reps: 12, restSeconds: 45),
        _RoutineBlock(keyword: '마운틴 클라이머', sets: 4, reps: 30, restSeconds: 30),
        _RoutineBlock(keyword: '점프 스쿼트', sets: 4, reps: 15, restSeconds: 60),
      ],
    ),
  ];

  static List<WorkoutRoutine> getRecommendedRoutines(List<Exercise> availableExercises) {
    final now = DateTime.now();
    final catalog = availableExercises;

    return _templates.map((template) {
      final usedExerciseIds = <String>{};
      final exercises = template.blocks
          .map((block) => _materializeExercise(block, catalog, usedExerciseIds))
          .whereType<Exercise>()
          .toList();

      return WorkoutRoutine(
        id: template.id,
        name: template.name,
        exercises: exercises,
        createdAt: now,
      );
    }).where((routine) => routine.exercises.isNotEmpty).toList();
  }

  static Exercise? _materializeExercise(
    _RoutineBlock block,
    List<Exercise> catalog,
    Set<String> usedExerciseIds,
  ) {
    Exercise? base;
    try {
      base = catalog.firstWhere(
        (exercise) =>
            !usedExerciseIds.contains(exercise.id) &&
            exercise.name.contains(block.keyword),
      );
    } catch (_) {
      base = null;
    }

    base ??= _pickFallbackExercise(catalog, usedExerciseIds);

    if (base == null) {
      // 등록된 운동이 하나도 없으면 추천에서 제외
      return null;
    }

    usedExerciseIds.add(base.id);

    final duration = block.estimatedDuration ?? (block.sets * block.reps * 4);

    return base.copyWith(
      duration: duration,
      sets: block.sets,
      reps: block.reps,
      restSeconds: block.restSeconds,
    );
  }

  static Exercise? _pickFallbackExercise(
    List<Exercise> catalog,
    Set<String> usedExerciseIds,
  ) {
    if (catalog.isEmpty) return null;

    try {
      return catalog.firstWhere(
        (exercise) => !usedExerciseIds.contains(exercise.id),
      );
    } catch (_) {
      // 모든 운동을 이미 사용했다면 첫 번째 운동을 재사용
      return catalog.first;
    }
  }

  static List<WorkoutRoutine> getPersonalizedRoutines(String userLevel, List<Exercise> availableExercises) {
    final routines = getRecommendedRoutines(availableExercises);

    if (routines.isEmpty) return routines;

    switch (userLevel.toLowerCase()) {
      case '초급':
        return routines.take(2).toList();
      case '중급':
        return routines.skip(1).take(2).toList();
      case '고급':
        return routines.skip(2).take(2).toList();
      default:
        return routines.take(2).toList();
    }
  }
}

class _RoutineTemplate {
  final String id;
  final String name;
  final List<_RoutineBlock> blocks;

  const _RoutineTemplate({
    required this.id,
    required this.name,
    required this.blocks,
  });
}

class _RoutineBlock {
  final String keyword;
  final int sets;
  final int reps;
  final int? restSeconds;
  final int? estimatedDuration;

  const _RoutineBlock({
    required this.keyword,
    required this.sets,
    required this.reps,
    this.restSeconds,
    this.estimatedDuration,
  });
}

class MissingOpenAiKeyException implements Exception {
  const MissingOpenAiKeyException();

  @override
  String toString() => 'OPENAI_API_KEY가 설정되지 않아 OpenAI 추천을 사용할 수 없습니다.';
}

class OpenAiRoutineService {
  OpenAiRoutineService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const _defaultModel = 'gpt-4o-mini';
  static const _apiKey = _openAiApiKey;

  Future<List<WorkoutRoutine>> generateRoutines({
    required List<Exercise> availableExercises,
    int routineCount = 3,
    String goal = '전신 강화',
  }) async {
    if (_apiKey.isEmpty) {
      throw const MissingOpenAiKeyException();
    }

    final catalogSummary = availableExercises.take(20).map((exercise) {
      return {
        'id': exercise.id,
        'name': exercise.name,
        'category': exercise.category,
        'description': exercise.description,
      };
    }).toList();

    final requestBody = {
      'model': _defaultModel,
      'temperature': 0.4,
      'response_format': {
        'type': 'json_schema',
        'json_schema': {
          'name': 'routine_response',
          'schema': {
            'type': 'object',
            'properties': {
              'routines': {
                'type': 'array',
                'items': {
                  'type': 'object',
                  'properties': {
                    'id': {'type': 'string'},
                    'name': {'type': 'string'},
                    'blocks': {
                      'type': 'array',
                      'items': {
                        'type': 'object',
                        'properties': {
                          'exercise_id': {'type': 'string'},
                          'display_name': {'type': 'string'},
                          'sets': {'type': 'integer'},
                          'reps': {'type': 'integer'},
                          'rest_seconds': {'type': 'integer'},
                          'estimated_duration_sec': {'type': 'integer'},
                          'notes': {'type': 'string'},
                        },
                        'required': ['sets', 'reps'],
                      },
                      'minItems': 3,
                      'maxItems': 5,
                    },
                  },
                  'required': ['name', 'blocks'],
                },
                'minItems': routineCount,
                'maxItems': routineCount,
              },
            },
            'required': ['routines'],
          },
        },
      },
      'messages': [
        {
          'role': 'system',
          'content': '당신은 한국어로 답변하는 전문 피트니스 코치입니다. '
              '사용 가능한 운동 목록을 참고하여 세트/횟수 기반의 루틴을 JSON 형식으로만 반환하세요.',
        },
        {
          'role': 'user',
          'content': jsonEncode({
            'goal': goal,
            'routine_count': routineCount,
            'catalog': catalogSummary,
          }),
        },
      ],
    };

    final response = await _client.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: jsonEncode(requestBody),
    );

    if (response.statusCode >= 400) {
      throw Exception('OpenAI 응답 오류 (${response.statusCode}): ${response.body}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = decoded['choices'] as List<dynamic>?;
    if (choices == null || choices.isEmpty) {
      return [];
    }

    final content = choices.first['message']['content'];
    final routinesJson = _parseContent(content);
    return WorkoutRoutineMapper.fromJson(routinesJson, availableExercises);
  }

  Map<String, dynamic> _parseContent(dynamic content) {
    if (content is String) {
      return jsonDecode(content) as Map<String, dynamic>;
    }

    if (content is List) {
      final buffer = StringBuffer();
      for (final chunk in content) {
        if (chunk is Map<String, dynamic> && chunk['type'] == 'text') {
          buffer.write(chunk['text'] ?? '');
        }
      }
      return jsonDecode(buffer.toString()) as Map<String, dynamic>;
    }

    throw const FormatException('지원하지 않는 OpenAI 응답 형식입니다.');
  }

  void dispose() {
    _client.close();
  }
}

class WorkoutRoutineMapper {
  static List<WorkoutRoutine> fromJson(
    Map<String, dynamic> json,
    List<Exercise> catalogList,
  ) {
    final routines = json['routines'] as List<dynamic>? ?? [];
    final catalog = {for (final exercise in catalogList) exercise.id: exercise};

    return routines
        .map((routine) => _mapRoutine(routine, catalog))
        .whereType<WorkoutRoutine>()
        .toList();
  }

  static WorkoutRoutine? _mapRoutine(
    dynamic routineJson,
    Map<String, Exercise> catalog,
  ) {
    if (routineJson is! Map<String, dynamic>) return null;
    final blocks = routineJson['blocks'] as List<dynamic>?;
    if (blocks == null || blocks.isEmpty) return null;

    final exercises = blocks
        .map((block) => _mapBlock(block, catalog))
        .whereType<Exercise>()
        .toList();

    if (exercises.isEmpty) return null;

    final name = routineJson['name'] as String? ?? 'AI 루틴';
    final id = routineJson['id']?.toString() ??
        'openai_${name.hashCode}_${DateTime.now().millisecondsSinceEpoch}';

    return WorkoutRoutine(
      id: id,
      name: name,
      exercises: exercises,
      createdAt: DateTime.now(),
    );
  }

  static Exercise? _mapBlock(
    dynamic blockJson,
    Map<String, Exercise> catalog,
  ) {
    if (blockJson is! Map<String, dynamic>) return null;

    final exerciseId = blockJson['exercise_id']?.toString();
    final sets = (blockJson['sets'] as num?)?.toInt() ?? 3;
    final reps = (blockJson['reps'] as num?)?.toInt() ?? 12;
    final restSeconds = (blockJson['rest_seconds'] as num?)?.toInt();
    final duration = (blockJson['estimated_duration_sec'] as num?)?.toInt() ??
        (sets * reps * 4);
    final notes = blockJson['notes'] as String?;
    final displayName =
        blockJson['display_name'] as String? ?? blockJson['name'] as String?;

    Exercise? base = exerciseId != null ? catalog[exerciseId] : null;

    if (base == null && displayName != null) {
      base = _findExerciseByName(displayName, catalog);
    }

    if (base == null) {
      // 등록되지 않은 운동은 추천에서 제외
      return null;
    }

    return base.copyWith(
      duration: duration,
      description: notes ?? base.description,
      sets: sets,
      reps: reps,
      restSeconds: restSeconds,
    );
  }

  static Exercise? _findExerciseByName(
    String name,
    Map<String, Exercise> catalog,
  ) {
    final normalized = name.trim().toLowerCase();
    try {
      return catalog.values.firstWhere(
        (exercise) => exercise.name.toLowerCase().contains(normalized),
      );
    } catch (_) {
      return null;
    }
  }
}

final openAiRoutineServiceProvider = Provider<OpenAiRoutineService>((ref) {
  final service = OpenAiRoutineService();
  ref.onDispose(service.dispose);
  return service;
});

final aiRecommendedRoutinesProvider = FutureProvider<List<WorkoutRoutine>>((ref) async {
  final exercises = await ref.watch(databaseExercisesProvider.future);
  final workoutGoal = ref.watch(workoutGoalModelProvider);
  final userProfile = ref.watch(userProfileModelProvider);

  if (_enableWorkoutAi) {
    try {
      final routines = await _fetchWorkoutAiRoutines(
        exercises: exercises,
        workoutGoal: workoutGoal,
        userProfile: userProfile,
      );
      if (routines.isNotEmpty) {
        return routines;
      }
      print('⚠️ workout-recommendation에서 빈 루틴을 받았습니다. 로컬 템플릿으로 폴백합니다.');
    } catch (e) {
      print('Supabase Edge Function workout-recommendation 호출 실패: $e');
    }

    if (_hasOpenAiKey) {
      final openAiService = ref.watch(openAiRoutineServiceProvider);
      try {
        final routines = await openAiService.generateRoutines(
          availableExercises: exercises,
        );
        if (routines.isNotEmpty) {
          return routines;
        }
      } catch (e) {
        print('OpenAI 추천 루틴 생성 실패: $e');
      }
    } else {
      print('⚠️ OPENAI_API_KEY가 없어 OpenAI 백업을 건너뜁니다.');
    }
  } else {
    print('ℹ️ ENABLE_WORKOUT_AI=false 설정으로 AI 추천을 건너뜁니다.');
  }

  return AIRecommendedRoutines.getRecommendedRoutines(exercises);
});

Future<List<WorkoutRoutine>> _fetchWorkoutAiRoutines({
  required List<Exercise> exercises,
  WorkoutGoalModel? workoutGoal,
  UserProfileModel? userProfile,
}) async {
  final client = Supabase.instance.client;
  final payload = _buildWorkoutAiPayload(
    userId: client.auth.currentUser?.id,
    workoutGoal: workoutGoal,
    userProfile: userProfile,
    exercises: exercises,
  );
  print('🛰 workout-recommendation 호출 payload: ${jsonEncode(payload)}');

  final response = await client.functions.invoke(
    _workoutRecommendationFunction,
    body: payload,
  );
  print(
    '🛰 workout-recommendation 응답 status=${response.status} data=${response.data}',
  );

  final responseJson = _normalizeFunctionResponse(response.data);
  if (responseJson == null) {
    throw const FormatException('workout-recommendation 응답을 파싱할 수 없습니다.');
  }

  return WorkoutRoutineMapper.fromJson(responseJson, exercises);
}

Map<String, dynamic> _buildWorkoutAiPayload({
  required String? userId,
  WorkoutGoalModel? workoutGoal,
  UserProfileModel? userProfile,
  required List<Exercise> exercises,
}) {
  final userPayload = <String, dynamic>{};
  _putIfNotNull(userPayload, 'id', userId);

  final goalPayload = <String, dynamic>{};
  _putIfNotNull(goalPayload, 'goal_type', workoutGoal?.goalType?.name);
  _putIfNotNull(goalPayload, 'level', workoutGoal?.level?.name);
  _putIfNotNull(goalPayload, 'weekly_days', workoutGoal?.weeklyDays);
  _putIfNotNull(goalPayload, 'daily_minutes', workoutGoal?.dailyDurationMin);

  final preferencesPayload = <String, dynamic>{};
  _putIfNotNull(preferencesPayload, 'preferred_types', workoutGoal?.preferredTypes);

  final profilePayload = <String, dynamic>{};
  _putIfNotNull(profilePayload, 'gender', userProfile?.gender?.name);
  _putIfNotNull(profilePayload, 'age', userProfile?.age);
  _putIfNotNull(profilePayload, 'height_cm', userProfile?.height);
  _putIfNotNull(profilePayload, 'weight_kg', userProfile?.weight);

  final catalogPayload = _buildCatalogPayload(exercises);

  final payload = <String, dynamic>{
    'user': userPayload.isEmpty ? null : userPayload,
    'goal': goalPayload.isEmpty ? null : goalPayload,
    'preferences': preferencesPayload.isEmpty ? null : preferencesPayload,
    'profile': profilePayload.isEmpty ? null : profilePayload,
    'catalog': catalogPayload,
    'options': {
      'routine_count': 3,
      'language': 'ko',
      'source': 'app',
    },
  };

  payload.removeWhere((key, value) {
    if (value == null) return true;
    if (value is Map && value.isEmpty) return true;
    if (value is List && value.isEmpty) return true;
    return false;
  });

  return payload;
}

List<Map<String, dynamic>> _buildCatalogPayload(List<Exercise> exercises) {
  final catalog = <Map<String, dynamic>>[];
  for (final exercise in exercises) {
    final entry = <String, dynamic>{};
    final exerciseId = int.tryParse(exercise.id);
    _putIfNotNull(entry, 'exercise_id', exerciseId);
    _putIfNotNull(entry, 'name', exercise.name);
    _putIfNotNull(entry, 'category', exercise.category);
    _putIfNotNull(entry, 'description', exercise.description);
    _putIfNotNull(entry, 'estimated_duration_sec', exercise.estimatedDurationSeconds);

    if (entry.isNotEmpty) {
      catalog.add(entry);
    }
  }
  return catalog;
}

Map<String, dynamic>? _normalizeFunctionResponse(dynamic data) {
  Map<String, dynamic>? map;
  if (data is Map<String, dynamic>) {
    map = data;
  } else if (data is String && data.isNotEmpty) {
    final decoded = jsonDecode(data);
    if (decoded is Map<String, dynamic>) {
      map = decoded;
    }
  }

  if (map == null) {
    return null;
  }

  if (!map.containsKey('routines') && map['data'] is Map<String, dynamic>) {
    final nested = map['data'] as Map<String, dynamic>;
    if (nested.containsKey('routines')) {
      map = nested;
    }
  }

  return map;
}

void _putIfNotNull(Map<String, dynamic> target, String key, dynamic value) {
  if (value == null) return;
  if (value is Iterable && value.isEmpty) return;
  target[key] = value;
}

// Supabase 연동 프로바이더들
final supabaseWorkoutServiceProvider = Provider<SupabaseWorkoutService>((ref) => SupabaseWorkoutService());

// 데이터베이스에서 운동 목록을 가져오는 프로바이더 (Exercise_list 테이블 사용)
final databaseExercisesProvider = FutureProvider<List<Exercise>>((ref) async {
  final service = ref.read(supabaseWorkoutServiceProvider);
  try {
    final supabaseExercises = await service.getAllExercises();
    if (supabaseExercises.isEmpty) {
      print('⚠️ Exercise_list 테이블에 운동이 없습니다.');
      return [];
    }
    return supabaseExercises.map((supabaseExercise) => Exercise(
      id: supabaseExercise.exerciseId.toString(),
      name: supabaseExercise.name,
      description: supabaseExercise.description ?? '운동 설명이 없습니다.',
      duration: _getDurationByDifficulty(supabaseExercise.difficulty ?? '초급'),
      category: supabaseExercise.bodyPart,
    )).toList();
  } catch (e) {
    print('데이터베이스에서 운동 목록 가져오기 실패: $e');
    // 실패 시 빈 리스트 반환 (하드코딩된 목록 제거)
    return [];
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
  SupabaseRoutineNotifier(this._service, this._ref) : super(const AsyncValue.loading()) {
    loadRoutines();
    
    // 인증 상태 변화 감지
    _ref.listen(authControllerProvider, (previous, next) {
      if (previous?.isLoggedIn == true && !next.isLoggedIn) {
        // 로그아웃 시 상태 초기화
        state = const AsyncValue.data([]);
      } else if (previous?.isLoggedIn == false && next.isLoggedIn) {
        // 로그인 시 해당 사용자의 루틴 로드
        loadRoutines();
      }
    });
  }

  final SupabaseWorkoutService _service;
  final Ref _ref;

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
      
      // 1. 운동 ID 매핑 (Exercise_list에 있는 운동만 사용)
      final List<Map<String, dynamic>> exerciseData = [];
      
      for (int i = 0; i < exercises.length; i++) {
        final exercise = exercises[i];
        print('📝 운동 처리 중 (${i + 1}/${exercises.length}): ${exercise.name}');
        
        // Exercise_list에서 운동 확인
        SupabaseExercise? supabaseExercise = await _service.getExerciseByName(exercise.name);
        
        if (supabaseExercise == null) {
          // Exercise_list에 없는 운동은 사용할 수 없음
          throw Exception('운동 "${exercise.name}"이(가) Exercise_list에 없습니다. 현재 지원되는 운동만 루틴에 추가할 수 있습니다.');
        }
        
        print('✅ Exercise_list에서 운동 확인: ${supabaseExercise.name} (ID: ${supabaseExercise.exerciseId})');
        
        // 운동 데이터 추가
        exerciseData.add({
          'exercise_id': supabaseExercise.exerciseId!,
          'sets': exercise.sets ?? 3,
          'reps': exercise.reps ?? (exercise.duration ~/ 5).clamp(5, 20),
          'rest_time_sec': exercise.restSeconds ?? 60,
        });
      }

      print('📊 운동 데이터 준비 완료: ${exerciseData.length}개');

      // 2. 단순 삽입 방식을 사용해 루틴 생성
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
      
      // 1. 운동 ID 매핑 (Exercise_list에 있는 운동만 사용)
      final List<Map<String, dynamic>> exerciseData = [];
      
      for (int i = 0; i < exercises.length; i++) {
        final exercise = exercises[i];
        print('📝 운동 처리 중 (${i + 1}/${exercises.length}): ${exercise.name}');
        
        // Exercise_list에서 운동 확인
        SupabaseExercise? supabaseExercise = await _service.getExerciseByName(exercise.name);
        
        if (supabaseExercise == null) {
          // Exercise_list에 없는 운동은 사용할 수 없음
          throw Exception('운동 "${exercise.name}"이(가) Exercise_list에 없습니다. 현재 지원되는 운동만 루틴에 추가할 수 있습니다.');
        }
        
        print('✅ Exercise_list에서 운동 확인: ${supabaseExercise.name} (ID: ${supabaseExercise.exerciseId})');
        
        // 운동 데이터 추가
        exerciseData.add({
          'exercise_id': supabaseExercise.exerciseId!,
          'sets': exercise.sets ?? 3,
          'reps': exercise.reps ?? (exercise.duration ~/ 5).clamp(5, 20),
          'rest_time_sec': exercise.restSeconds ?? 60,
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
  return SupabaseRoutineNotifier(service, ref);
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
