class SupabaseRoutineExercise {
  final int? routineExId;
  final int routineId;
  final int exerciseId;
  final int sets;
  final int reps;
  final int restTimeSec;

  const SupabaseRoutineExercise({
    this.routineExId,
    required this.routineId,
    required this.exerciseId,
    required this.sets,
    required this.reps,
    this.restTimeSec = 60,
  });

  factory SupabaseRoutineExercise.fromJson(Map<String, dynamic> json) {
    return SupabaseRoutineExercise(
      routineExId: json['routine_ex_id'] as int?,
      routineId: json['routine_id'] as int,
      exerciseId: json['exercise_id'] as int,
      sets: json['sets'] as int,
      reps: json['reps'] as int,
      restTimeSec: json['rest_time_sec'] as int? ?? 60,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (routineExId != null) 'routine_ex_id': routineExId,
      'routine_id': routineId,
      'exercise_id': exerciseId,
      'sets': sets,
      'reps': reps,
      'rest_time_sec': restTimeSec,
    };
  }

  // Insert용(routine_ex_id 제외)
  Map<String, dynamic> toInsertJson() {
    return {
      'routine_id': routineId,
      'exercise_id': exerciseId,
      'sets': sets,
      'reps': reps,
      'rest_time_sec': restTimeSec,
    };
  }

  @override
  String toString() {
    return 'SupabaseRoutineExercise(routineExId: $routineExId, routineId: $routineId, exerciseId: $exerciseId, sets: $sets, reps: $reps)';
  }
}
