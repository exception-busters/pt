import 'package:flutter/material.dart';
import '../services/phase_manager.dart';

/// 운동 단계 진행 표시 위젯
class PhaseProgressWidget extends StatelessWidget {
  final PhaseManager? phaseManager;

  const PhaseProgressWidget({
    Key? key,
    required this.phaseManager,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (phaseManager == null) {
      return const SizedBox.shrink();
    }

    final manager = phaseManager!;
    final isCompleted = manager.isCompleted;

    // 간소화된 진행도 UI (최소 크기)
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 단계 번호
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCompleted ? Colors.green : Colors.blue,
            ),
            child: Center(
              child: Text(
                '${manager.currentPhaseIndex + 1}/${manager.totalPhases}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // 진행률 바 (간소화)
          SizedBox(
            width: 60,
            child: LinearProgressIndicator(
              value: manager.progress,
              backgroundColor: Colors.white24,
              valueColor: AlwaysStoppedAnimation<Color>(
                isCompleted ? Colors.green : Colors.blue,
              ),
              minHeight: 4,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
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

