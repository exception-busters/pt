import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_application_1/features/diet/application/diet_providers.dart';

class DietScreen extends ConsumerWidget {
  const DietScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String? message;
    Object? error;
    try {
      message = ref.watch(dietRecommendationProvider);
    } catch (e) {
      error = e;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('식단'),
        backgroundColor: const Color(0xFFE8F5E8),
        foregroundColor: const Color(0xFF4A6741),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '다른 추천 받기',
            onPressed: () {
              // 간단히 화면을 재빌드하도록 컨트롤러의 날짜 체크를 수행
              ref.read(dietControllerProvider.notifier).checkAndResetIfNewDay();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Builder(
            builder: (_) {
              if (error != null) {
                return _DietErrorView(
                  error: error,
                  onRetry: () {
                    // 재시도: 상태를 건드려 재평가 유도
                    ref.read(dietControllerProvider.notifier).checkAndResetIfNewDay();
                  },
                );
              }

              final dietData = ref.watch(dietControllerProvider);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dietData.date,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          '오늘의 식단 요약',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          message ?? '추천을 계산 중...',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: () => context.go('/app/records'),
                    icon: const Icon(Icons.analytics_outlined),
                    label: const Text('식단 기록으로 이동'),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _DietErrorView extends StatelessWidget {
  const _DietErrorView({required this.error, required this.onRetry});

  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final e = error;
    final message = e is DietRecommendationException
        ? e.message ?? '식단 추천 오류가 발생했습니다.'
        : '식단 추천을 불러오는 중 오류가 발생했습니다.';

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.restaurant_menu, size: 64, color: Color(0xFF9ACD32)),
        const SizedBox(height: 24),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, color: Color(0xFF4A6741)),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: onRetry,
          child: const Text('다시 시도'),
        ),
      ],
    );
  }
}
