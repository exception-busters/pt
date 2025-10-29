class SupabaseWorkoutRecord {
  final int? recordId;
  final int sessionId;
  final int exerciseId;
  final int setNum;
  final int repsDone;
  final DateTime startTime;
  final DateTime? endTime;
  final int caloriesBurned;

  const SupabaseWorkoutRecord({
    this.recordId,
    required this.sessionId,
    required this.exerciseId,
    required this.setNum,
    required this.repsDone,
    required this.startTime,
    this.endTime,
    this.caloriesBurned = 0,
  });

  factory SupabaseWorkoutRecord.fromJson(Map<String, dynamic> json) {
    return SupabaseWorkoutRecord(
      recordId: json['record_id'] as int?,
      sessionId: json['session_id'] as int,
      exerciseId: json['exercise_id'] as int,
      setNum: json['set_num'] as int,
      repsDone: json['reps_done'] as int,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: json['end_time'] != null 
          ? DateTime.parse(json['end_time'] as String)
          : null,
      caloriesBurned: json['calories_burned'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (recordId != null) 'record_id': recordId,
      'session_id': sessionId,
      'exercise_id': exerciseId,
      'set_num': setNum,
      'reps_done': repsDone,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'calories_burned': caloriesBurned,
    };
  }

  // Insert용 (record_id 제외)
  Map<String, dynamic> toInsertJson() {
    return {
      'session_id': sessionId,
      'exercise_id': exerciseId,
      'set_num': setNum,
      'reps_done': repsDone,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'calories_burned': caloriesBurned,
    };
  }

  @override
  String toString() {
    return 'SupabaseWorkoutRecord(recordId: $recordId, sessionId: $sessionId, exerciseId: $exerciseId, setNum: $setNum, reps: $repsDone)';
  }
}