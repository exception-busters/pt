import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_application_1/color.dart';
import 'package:flutter_application_1/features/profile/application/profile_providers.dart';
import 'package:flutter_application_1/features/onboarding/application/onboarding_providers.dart';
import 'package:go_router/go_router.dart';

class OnboardingDebugWidget extends ConsumerWidget {
  const OnboardingDebugWidget({super.key});

  Future<void> _resetOnboarding(WidgetRef ref) async {
    try {
      // 서버에서 profile_completed를 false로 업데이트
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await Supabase.instance.client
            .from('users')
            .update({'profile_completed': false})
            .eq('user_id', user.id);
        print('✅ 서버에서 profile_completed를 false로 업데이트');
      }
      
      // 로컬 캐시 삭제
      final prefs = await SharedPreferences.getInstance();
      if (user != null) {
        await prefs.remove('onboarding_completed_${user.id}');
        await prefs.remove('user_gender_${user.id}');
        await prefs.remove('user_age_${user.id}');
        await prefs.remove('user_weight_${user.id}');
        await prefs.remove('user_height_${user.id}');
        await prefs.remove('user_workout_goal_${user.id}');
        await prefs.remove('user_workout_level_${user.id}');
      }
      
      // 프로바이더 새로고침
      ref.invalidate(profileCompletedProvider);
      ref.invalidate(onboardingCompletedProvider);
      ref.invalidate(userProfileProvider);
      
      print('✅ 온보딩 데이터 리셋 완료 (서버 + 로컬)');
    } catch (e) {
      print('❌ 온보딩 데이터 리셋 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileCompleted = ref.watch(profileCompletedProvider);
    final user = Supabase.instance.client.auth.currentUser;
    
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
          const SizedBox(height: 8),
          
          // 현재 상태 표시 (간소화)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                const Text(
                  '상태: ',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                Expanded(
                  child: profileCompleted.when(
                    data: (completed) => Text(
                      completed ? '완료됨' : '미완료',
                      style: TextStyle(
                        color: completed ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    loading: () => const Text('로딩...', style: TextStyle(fontSize: 12)),
                    error: (error, _) => const Text('오류', style: TextStyle(color: Colors.red, fontSize: 12)),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 8),
          
          // 버튼들을 세로로 배치하여 overflow 방지
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        await _resetOnboarding(ref);
                        if (context.mounted) {
                          context.go('/onboarding');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: const Text('리셋', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        context.go('/onboarding');
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.orange),
                        foregroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: const Text('온보딩', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    ref.invalidate(profileCompletedProvider);
                    ref.invalidate(userProfileProvider);
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.blue),
                    foregroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: const Text('새로고침', style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}