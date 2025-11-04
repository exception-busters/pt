import 'package:flutter/material.dart';
import '../services/phase_manager.dart';

/// 운동 단계 진행 표시 위젯
class PhaseProgressWidget extends StatelessWidget {
  final PhaseManager? phaseManager;
  final int? currentExerciseIndex; // 현재 운동 인덱스 (전체 루틴 진행도용)
  final int? totalExercises; // 전체 운동 개수 (전체 루틴 진행도용)

  const PhaseProgressWidget({
    Key? key,
    required this.phaseManager,
    this.currentExerciseIndex,
    this.totalExercises,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (phaseManager == null) {
      return const SizedBox.shrink();
    }

    final manager = phaseManager!;
    final isCompleted = manager.isCompleted;
    
    // 전체 루틴 진행도 계산 (루틴이 있는 경우만)
    final double? routineProgress = (currentExerciseIndex != null && totalExercises != null && totalExercises! > 0)
        ? (currentExerciseIndex! + 1) / totalExercises!
        : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // 좌측: 현재 운동 진행도 (50%)
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 운동 아이콘
                Icon(
                  isCompleted ? Icons.check_circle : Icons.fitness_center,
                  color: isCompleted ? Colors.green : Colors.blue,
                  size: 16,
                ),
                const SizedBox(width: 8),
                // 진행률 바
                Expanded(
                  child: LinearProgressIndicator(
                    value: manager.progress,
                    backgroundColor: Colors.white24,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isCompleted ? Colors.green : Colors.blue,
                    ),
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 8),
                // 진행도 텍스트
                Text(
                  '${(manager.progress * 100).toInt()}%',
                  style: TextStyle(
                    color: isCompleted ? Colors.green : Colors.blue,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          // 구분선 (루틴이 있는 경우만)
          if (routineProgress != null) ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              width: 1,
              height: 30,
              color: Colors.white24,
            ),
            // 우측: 전체 루틴 진행도 (50%)
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 루틴 아이콘
                  const Icon(
                    Icons.list_alt,
                    color: Colors.orange,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  // 진행률 바
                  Expanded(
                    child: LinearProgressIndicator(
                      value: routineProgress,
                      backgroundColor: Colors.white24,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 진행도 텍스트
                  Text(
                    '${(routineProgress * 100).toInt()}%',
                    style: const TextStyle(
                      color: Colors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  // 운동 번호 표시
                  Text(
                    '(${currentExerciseIndex! + 1}/$totalExercises)',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 단계별 스텝 인디케이터
class PhaseStepIndicator extends StatelessWidget {
  final PhaseManager? phaseManager;

  const PhaseStepIndicator({
    Key? key,
    required this.phaseManager,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (phaseManager == null) {
      return const SizedBox.shrink();
    }

    final manager = phaseManager!;

    // 간소화된 스텝 인디케이터 (더 작게)
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(manager.totalPhases, (index) {
          final isCompleted = index < manager.currentPhaseIndex;
          final isCurrent = index == manager.currentPhaseIndex;
          
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted
                      ? Colors.green
                      : isCurrent
                          ? Colors.blue
                          : Colors.white24,
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(Icons.check, color: Colors.white, size: 12)
                      : Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: isCurrent ? Colors.white : Colors.white54,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              if (index < manager.totalPhases - 1)
                Container(
                  width: 12,
                  height: 2,
                  color: isCompleted ? Colors.green : Colors.white24,
                ),
            ],
          );
        }),
      ),
    );
  }
}

