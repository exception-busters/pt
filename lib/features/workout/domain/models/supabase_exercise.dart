class SupabaseExercise {
  final int? exerciseId;
  final String name;
  final String bodyPart;
  final String? description;
  final String? difficulty;
  final String? videoUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const SupabaseExercise({
    this.exerciseId,
    required this.name,
    required this.bodyPart,
    this.description,
    this.difficulty,
    this.videoUrl,
    this.createdAt,
    this.updatedAt,
  });

  factory SupabaseExercise.fromJson(Map<String, dynamic> json) {
    return SupabaseExercise(
      exerciseId: json['exercise_id'] as int?,
      name: json['name'] as String,
      bodyPart: json['body_part'] as String,
      description: json['description'] as String?,
      difficulty: json['difficulty'] as String?,
      videoUrl: json['video_url'] as String?,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (exerciseId != null) 'exercise_id': exerciseId,
      'name': name,
      'body_part': bodyPart,
      'description': description,
      'difficulty': difficulty,
      'video_url': videoUrl,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  // Insert용 (exercise_id 제외)
  Map<String, dynamic> toInsertJson() {
    return {
      'name': name,
      'body_part': bodyPart,
      'description': description,
      'difficulty': difficulty,
      'video_url': videoUrl,
    };
  }

  @override
  String toString() {
    return 'SupabaseExercise(exerciseId: $exerciseId, name: $name, bodyPart: $bodyPart)';
  }
}