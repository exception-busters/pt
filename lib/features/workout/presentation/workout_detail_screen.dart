import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class WorkoutDetailScreen extends StatelessWidget {
  const WorkoutDetailScreen({super.key, required this.workoutId});

  final String workoutId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('운동 상세 - $workoutId'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '운동 ID: $workoutId',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              '이 화면은 딥링크 또는 공유를 통해 바로 열 수 있는 운동 세션 상세 예시입니다.\n실제 구현 시, 서버에서 세션 데이터를 받아 자세 피드백, 반복 수, 영상 등을 표시하도록 확장하세요.',
            ),
            const Spacer(),
            Align(
              alignment: Alignment.bottomRight,
              child: OutlinedButton.icon(
                onPressed: () => context.go('/app/workout'),
                icon: const Icon(Icons.fitness_center),
                label: const Text('운동 목록으로'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

