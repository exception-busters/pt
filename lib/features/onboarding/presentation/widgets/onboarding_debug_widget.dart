import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/color.dart';
import 'package:go_router/go_router.dart';

class OnboardingDebugWidget extends ConsumerWidget {
  const OnboardingDebugWidget({super.key});

  Future<void> _resetOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('onboarding_completed');
      await prefs.remove('user_gender');
      await prefs.remove('user_age');
      await prefs.remove('user_weight');
      await prefs.remove('user_height');
      await prefs.remove('user_workout_goal');
      await prefs.remove('user_workout_level');
      print('✅ 온보딩 데이터 리셋 완료');
    } catch (e) {
      print('❌ 온보딩 데이터 리셋 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '🔧 개발자 도구',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '온보딩을 다시 테스트하려면 아래 버튼을 눌러주세요.',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ElevatedButton(
                onPressed: () async {
                  await _resetOnboarding();
                  if (context.mounted) {
                    context.go('/onboarding');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                child: const Text('온보딩 리셋'),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: () {
                  context.go('/onboarding');
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.orange),
                  foregroundColor: Colors.orange,
                ),
                child: const Text('온보딩 보기'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}