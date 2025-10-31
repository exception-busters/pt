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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompleted ? Colors.green : Colors.blue,
          width: 2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 단계 정보
          Row(
            children: [
              Icon(
                isCompleted ? Icons.check_circle : Icons.fitness_center,
                color: isCompleted ? Colors.green : Colors.blue,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      manager.getPhaseStatus(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isCompleted 
                          ? '🎉 운동 완료!' 
                          : manager.getPhaseDescription(),
                      style: TextStyle(
                        color: isCompleted ? Colors.green[300] : Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // 전체 진행률
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: manager.progress,
                  backgroundColor: Colors.white24,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isCompleted ? Colors.green : Colors.blue,
                  ),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${(manager.progress * 100).toInt()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // 현재 단계 타이머
          if (!isCompleted) ...[
            // 준비 단계
            if (!manager.isReady) ...[
              Row(
                children: [
                  Icon(
                    manager.isConditionMet ? Icons.timer : Icons.warning_amber,
                    color: manager.isConditionMet ? Colors.blue : Colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '준비: 자세를 ${PhaseManager.readyTimeRequired.toStringAsFixed(0)}초 유지하세요 (${manager.readyDuration.toStringAsFixed(1)}초)',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: manager.readyProgress,
                backgroundColor: Colors.white24,
                valueColor: AlwaysStoppedAnimation<Color>(
                  manager.isConditionMet ? Colors.blue : Colors.orange,
                ),
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),
            ]
            // 운동 단계
            else ...[
              Row(
                children: [
                  Icon(
                    manager.isConditionMet ? Icons.check_circle_outline : Icons.hourglass_empty,
                    color: manager.isConditionMet ? Colors.green : Colors.amber,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '운동 중: ${manager.phaseHoldDuration.toStringAsFixed(1)}초 / ${manager.phaseRequiredDuration.toStringAsFixed(1)}초',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: manager.phaseProgress,
                backgroundColor: Colors.white24,
                valueColor: AlwaysStoppedAnimation<Color>(
                  manager.isConditionMet ? Colors.green : Colors.amber,
                ),
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),
            ],
          ],
          
          // 완료 메시지
          if (isCompleted) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.celebration, color: Colors.green, size: 20),
                  SizedBox(width: 8),
                  Text(
                    '훌륭합니다! 운동을 완료했습니다!',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(manager.totalPhases, (index) {
          final isCompleted = index < manager.currentPhaseIndex;
          final isCurrent = index == manager.currentPhaseIndex;
          
          return Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted
                      ? Colors.green
                      : isCurrent
                          ? Colors.blue
                          : Colors.white24,
                  border: Border.all(
                    color: isCurrent ? Colors.white : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(Icons.check, color: Colors.white, size: 18)
                      : Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: isCurrent ? Colors.white : Colors.white54,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              if (index < manager.totalPhases - 1)
                Container(
                  width: 24,
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

