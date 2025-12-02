import 'dart:convert';

/// 운동 데이터 모델
class ExerciseModel {
  final String exerciseId;
  final String exerciseCode;
  final String exerciseName;
  final String category;
  final String posture;
  final String difficulty;
  final String description;
  final List<String> keyJoints;
  final Map<String, KeyAngle> keyAngles;
  final List<MotionPhase> motionPhases;
  final List<FeedbackRule> feedbackRules;
  final List<String> commonMistakes;

  ExerciseModel({
    required this.exerciseId,
    required this.exerciseCode,
    required this.exerciseName,
    required this.category,
    required this.posture,
    required this.difficulty,
    required this.description,
    required this.keyJoints,
    required this.keyAngles,
    required this.motionPhases,
    required this.feedbackRules,
    required this.commonMistakes,
  });

  factory ExerciseModel.fromJson(Map<String, dynamic> json) {
    return ExerciseModel(
      exerciseId: json['exercise_id'] as String,
      exerciseCode: json['exercise_code'] as String,
      exerciseName: json['exercise_name'] as String,
      category: json['category'] as String,
      posture: json['posture'] as String,
      difficulty: json['difficulty'] as String,
      description: json['description'] as String,
      keyJoints: List<String>.from(json['key_joints'] as List),
      keyAngles: (json['key_angles'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, KeyAngle.fromJson(value as Map<String, dynamic>)),
      ),
      motionPhases: (json['motion_phases'] as List)
          .map((phase) => MotionPhase.fromJson(phase as Map<String, dynamic>))
          .toList(),
      feedbackRules: (json['feedback_rules'] as List)
          .map((rule) => FeedbackRule.fromJson(rule as Map<String, dynamic>))
          .toList(),
      commonMistakes: List<String>.from(json['common_mistakes'] as List),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exercise_id': exerciseId,
      'exercise_code': exerciseCode,
      'exercise_name': exerciseName,
      'category': category,
      'posture': posture,
      'difficulty': difficulty,
      'description': description,
      'key_joints': keyJoints,
      'key_angles': keyAngles.map((key, value) => MapEntry(key, value.toJson())),
      'motion_phases': motionPhases.map((phase) => phase.toJson()).toList(),
      'feedback_rules': feedbackRules.map((rule) => rule.toJson()).toList(),
      'common_mistakes': commonMistakes,
    };
  }
}

/// 주요 각도 정보
class KeyAngle {
  final String name;
  final List<String> points;
  final double idealMean;
  final List<double> idealRange;
  final double tolerance;
  final double weight;

  KeyAngle({
    required this.name,
    required this.points,
    required this.idealMean,
    required this.idealRange,
    required this.tolerance,
    required this.weight,
  });

  factory KeyAngle.fromJson(Map<String, dynamic> json) {
    return KeyAngle(
      name: json['name'] as String,
      points: List<String>.from(json['points'] as List),
      idealMean: (json['ideal_mean'] as num).toDouble(),
      idealRange: (json['ideal_range'] as List).map((e) => (e as num).toDouble()).toList(),
      tolerance: (json['tolerance'] as num).toDouble(),
      weight: (json['weight'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'points': points,
      'ideal_mean': idealMean,
      'ideal_range': idealRange,
      'tolerance': tolerance,
      'weight': weight,
    };
  }
}

/// 동작 단계 정보
class MotionPhase {
  final int phaseId;
  final String phaseName;
  final String description;
  final double durationSec;
  final List<String> keyChecks;
  final Map<String, KeyAngle>? phaseAngles; // 페이즈별 각도 기준 (없으면 기본 key_angles 사용)

  MotionPhase({
    required this.phaseId,
    required this.phaseName,
    required this.description,
    required this.durationSec,
    required this.keyChecks,
    this.phaseAngles,
  });

  factory MotionPhase.fromJson(Map<String, dynamic> json) {
    return MotionPhase(
      phaseId: json['phase_id'] as int,
      phaseName: json['phase_name'] as String,
      description: json['description'] as String,
      durationSec: (json['duration_sec'] as num).toDouble(),
      keyChecks: List<String>.from(json['key_checks'] as List),
      phaseAngles: json['phase_angles'] != null
          ? (json['phase_angles'] as Map<String, dynamic>).map(
              (key, value) => MapEntry(key, KeyAngle.fromJson(value as Map<String, dynamic>)),
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'phase_id': phaseId,
      'phase_name': phaseName,
      'description': description,
      'duration_sec': durationSec,
      'key_checks': keyChecks,
      if (phaseAngles != null)
        'phase_angles': phaseAngles!.map((key, value) => MapEntry(key, value.toJson())),
    };
  }
}

/// 피드백 규칙
class FeedbackRule {
  final String condition;
  final String feedback;
  final String severity;

  FeedbackRule({
    required this.condition,
    required this.feedback,
    required this.severity,
  });

  factory FeedbackRule.fromJson(Map<String, dynamic> json) {
    return FeedbackRule(
      condition: json['condition'] as String,
      feedback: json['feedback'] as String,
      severity: json['severity'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'condition': condition,
      'feedback': feedback,
      'severity': severity,
    };
  }
}

/// 운동 참조 데이터
class ExerciseReferenceData {
  final String version;
  final String lastUpdated;
  final List<ExerciseModel> exercises;

  ExerciseReferenceData({
    required this.version,
    required this.lastUpdated,
    required this.exercises,
  });

  factory ExerciseReferenceData.fromJson(Map<String, dynamic> json) {
    return ExerciseReferenceData(
      version: json['version'] as String,
      lastUpdated: json['last_updated'] as String,
      exercises: (json['exercises'] as List)
          .map((exercise) => ExerciseModel.fromJson(exercise as Map<String, dynamic>))
          .toList(),
    );
  }

  factory ExerciseReferenceData.fromJsonString(String jsonString) {
    final Map<String, dynamic> json = jsonDecode(jsonString);
    return ExerciseReferenceData.fromJson(json);
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'last_updated': lastUpdated,
      'exercises': exercises.map((exercise) => exercise.toJson()).toList(),
    };
  }
}


