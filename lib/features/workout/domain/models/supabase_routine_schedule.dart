class SupabaseRoutineSchedule {
  final int? scheduleId;
  final String userId;
  final int routineId;
  final int weekday; // 0=월, 6=일
  final String? startTime; // HH:MM:SS 형식
  final int sortOrder;
  final bool isActive;
  final String? note;

  const SupabaseRoutineSchedule({
    this.scheduleId,
    required this.userId,
    required this.routineId,
    required this.weekday,
    this.startTime,
    this.sortOrder = 0,
    this.isActive = true,
    this.note,
  });

  factory SupabaseRoutineSchedule.fromJson(Map<String, dynamic> json) {
    return SupabaseRoutineSchedule(
      scheduleId: json['schedule_id'] as int?,
      userId: json['user_id'] as String,
      routineId: json['routine_id'] as int,
      weekday: json['weekday'] as int,
      startTime: json['start_time'] as String?,
      sortOrder: json['sort_order'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      note: json['note'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (scheduleId != null) 'schedule_id': scheduleId,
      'user_id': userId,
      'routine_id': routineId,
      'weekday': weekday,
      'start_time': startTime,
      'sort_order': sortOrder,
      'is_active': isActive,
      'note': note,
    };
  }
}
