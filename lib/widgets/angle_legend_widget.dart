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

  /// 각도 키에 따른 색상 반환 (캐싱됨)
  /// 같은 의미의 angle은 동일한 색상 사용
  static final Map<String, Color> _angleColors = {
    // Body tilt (몸통 기울기)
    'left_body_tilt': Color(0xFF66BB6A),        // 밝은 녹색
    'right_body_tilt': Color(0xFFEC407A),       // 밝은 분홍
    
    // Elbow (팔꿈치)
    'left_elbow_angle': Color(0xFF42A5F5),      // 밝은 파랑
    'right_elbow_angle': Color(0xFFFF7043),     // 밝은 주황
    
    // Knee - 좌측 (무릎)
    'left_knee_angle': Color(0xFFAB47BC),       // 보라
    'knee_angle_left': Color(0xFFAB47BC),       // 보라 (left_knee_angle과 동일)
    
    // Knee - 우측
    'right_knee_angle': Color(0xFF26A69A),      // 청록
    'knee_angle_right': Color(0xFF26A69A),      // 청록 (right_knee_angle과 동일)
    
    // Knee - 전후 동작용
    'front_knee_angle': Color(0xFFFFCA28),      // 황금색
    'back_knee_angle': Color(0xFF9CCC65),       // 연두
    
    // Hip flexion (고관절 굴곡) - 좌측
    'left_hip_flexion': Color(0xFF7E57C2),      // 딥 퍼플
    'left_hip_angle': Color(0xFF7E57C2),        // 딥 퍼플 (left_hip_flexion과 동일)
    'hip_angle_left': Color(0xFF7E57C2),        // 딥 퍼플 (left_hip_flexion과 동일)
    
    // Hip flexion (고관절 굴곡) - 우측
    'right_hip_flexion': Color(0xFF03A9F4),     // 라이트 블루
    'right_hip_angle': Color(0xFF03A9F4),       // 라이트 블루 (right_hip_flexion과 동일)
    'hip_angle_right': Color(0xFF03A9F4),       // 라이트 블루 (right_hip_flexion과 동일)
    
    // Hip - 전후 동작용
    'front_hip_angle': Color(0xFFF06292),       // 연한 핑크
    'back_hip_angle': Color(0xFF4DD0E1),        // 시안
    
    // Shoulder (어깨)
    'left_shoulder_angle': Color(0xFFFF6E40),   // 딥 오렌지
    'right_shoulder_angle': Color(0xFF4DB6AC),  // 청록
    
    // Back & Torso (등/상체)
    'back_angle': Color(0xFF5C6BC0),            // 인디고
    'torso_forward_bend': Color(0xFFFFA726),    // 오렌지
  };

  Color _getAngleColor(String angleKey) {
    return _angleColors[angleKey] ?? Colors.grey.shade400;
  }
}

