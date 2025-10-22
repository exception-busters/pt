import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RecordsDetailScreen extends StatelessWidget {
  const RecordsDetailScreen({super.key, required this.recordId});

  final String recordId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('기록 상세 - $recordId'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '기록 ID: $recordId',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              '운동 및 식단 기록 세부 정보를 표시하는 화면 예시입니다.\n향후 통계 그래프, 피드백, 세부 로그 등을 연결해 사용자 경험을 강화하세요.',
            ),
            const Spacer(),
            Align(
              alignment: Alignment.bottomRight,
              child: OutlinedButton.icon(
                onPressed: () => context.go('/app/records'),
                icon: const Icon(Icons.analytics),
                label: const Text('기록 목록으로'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

