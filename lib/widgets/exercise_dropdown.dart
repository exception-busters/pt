import 'package:flutter/material.dart';
import '../models/exercise_model.dart';

/// 운동 선택 드롭다운
class ExerciseDropdown extends StatelessWidget {
  final List<ExerciseModel> exercises;
  final ExerciseModel? selectedExercise;
  final ValueChanged<ExerciseModel?> onChanged;

  const ExerciseDropdown({
    Key? key,
    required this.exercises,
    required this.selectedExercise,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ExerciseModel>(
          value: selectedExercise,
          hint: const Text('운동을 선택하세요'),
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.blue),
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          items: exercises.map((exercise) {
            return DropdownMenuItem<ExerciseModel>(
              value: exercise,
              child: Row(
                children: [
                  Icon(
                    _getExerciseIcon(exercise.category),
                    color: Colors.blue,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          exercise.exerciseName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${exercise.category} · ${exercise.difficulty}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  IconData _getExerciseIcon(String category) {
    switch (category) {
      case '맨몸운동':
        return Icons.accessibility_new;
      case '바벨/덤벨':
        return Icons.fitness_center;
      case '기구':
        return Icons.settings;
      default:
        return Icons.sports_gymnastics;
    }
  }
}

