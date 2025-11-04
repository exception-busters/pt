import 'package:flutter/material.dart';
import '../models/exercise_model.dart';

/// 각도별 색상 범례 위젯
class AngleLegendWidget extends StatelessWidget {
  final ExerciseModel? exercise;

  const AngleLegendWidget({
    Key? key,
    this.exercise,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (exercise == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.palette,
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                '측정 각도',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...exercise!.keyAngles.entries.map<Widget>((entry) {
            final angleKey = entry.key;
            final angleInfo = entry.value;
            final color = _getAngleColor(angleKey);

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 색상 인디케이터
                  Container(
                    width: 24,
                    height: 3,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 각도 이름
                  Flexible(
                    child: Text(
                      angleInfo.name,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  /// 각도 키에 따른 색상 반환
  /// 같은 angle key는 어떤 운동에서든 동일한 색상 사용
  Color _getAngleColor(String angleKey) {
    final angleColors = {
      // Body tilt
      'left_body_tilt': Colors.green.shade400,
      'right_body_tilt': Colors.pink.shade400,
      
      // Elbow
      'left_elbow_angle': Colors.blue.shade400,
      'right_elbow_angle': Colors.orange.shade400,
      
      // Knee (일반)
      'left_knee_angle': Colors.purple.shade400,
      'right_knee_angle': Colors.teal.shade400,
      'front_knee_angle': Colors.amber.shade600,
      'back_knee_angle': Colors.lightGreen.shade400,
      'knee_angle_left': Colors.cyan.shade400,
      'knee_angle_right': Colors.lime.shade400,
      
      // Hip flexion
      'left_hip_flexion': Colors.lime.shade400,
      'right_hip_flexion': Colors.deepOrange.shade400,
      
      // Hip (일반)
      'left_hip_angle': Colors.deepPurple.shade400,
      'right_hip_angle': Colors.lightBlue.shade400,
      'front_hip_angle': Colors.pink.shade300,
      'back_hip_angle': Colors.cyan.shade300,
      'hip_angle_left': Colors.yellow.shade600,
      'hip_angle_right': Colors.red.shade400,
      
      // Shoulder
      'left_shoulder_angle': Colors.deepOrange.shade300,
      'right_shoulder_angle': Colors.teal.shade300,
      
      // Back & Torso
      'back_angle': Colors.indigo.shade400,
      'torso_forward_bend': Colors.amber.shade400,
    };

    return angleColors[angleKey] ?? Colors.grey.shade400;
  }
}

