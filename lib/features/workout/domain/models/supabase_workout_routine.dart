class SupabaseWorkoutRoutine {
  final int? routineId;
  final String userId;
  final String title;
  final String? description;
  final DateTime? createdAt;

  const SupabaseWorkoutRoutine({
    this.routineId,
    required this.userId,
    required this.title,
    this.description,
    this.createdAt,
  });

  factory SupabaseWorkoutRoutine.fromJson(Map<String, dynamic> json) {
    return SupabaseWorkoutRoutine(
      routineId: json['routine_id'] as int?,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (routineId != null) 'routine_id': routineId,
      'user_id': userId,
      'title': title,
      'description': description,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  // Insert용 (routine_id 제외)
  Map<String, dynamic> toInsertJson() {
    return {
      'user_id': userId,
      'title': title,
      'description': description,
    };
  }

  @override
  String toString() {
    return 'SupabaseWorkoutRoutine(routineId: $routineId, title: $title, userId: $userId)';
  }
}