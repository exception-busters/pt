class SupabaseWorkoutSession {
  final int? sessionId;
  final String userId;
  final int? routineId;
  final DateTime startTime;
  final DateTime? endTime;
  final int totalCalories;
  final String sessionStatus;

  const SupabaseWorkoutSession({
    this.sessionId,
    required this.userId,
    this.routineId,
    required this.startTime,
    this.endTime,
    this.totalCalories = 0,
    this.sessionStatus = 'in_progress',
  });

  factory SupabaseWorkoutSession.fromJson(Map<String, dynamic> json) {
    return SupabaseWorkoutSession(
      sessionId: json['session_id'] as int?,
      userId: json['user_id'] as String,
      routineId: json['routine_id'] as int?,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: json['end_time'] != null 
          ? DateTime.parse(json['end_time'] as String)
          : null,
      totalCalories: json['total_calories'] as int? ?? 0,
      sessionStatus: json['session_status'] as String? ?? 'in_progress',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (sessionId != null) 'session_id': sessionId,
      'user_id': userId,
      'routine_id': routineId,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'total_calories': totalCalories,
      'session_status': sessionStatus,
    };
  }

  // Insert용 (session_id 제외)
  Map<String, dynamic> toInsertJson() {
    return {
      'user_id': userId,
      'routine_id': routineId,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'total_calories': totalCalories,
      'session_status': sessionStatus,
    };
  }

  @override
  String toString() {
    return 'SupabaseWorkoutSession(sessionId: $sessionId, userId: $userId, status: $sessionStatus)';
  }
}