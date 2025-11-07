import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/features/profile/application/profile_providers.dart';
import 'package:flutter_application_1/features/auth/application/auth_providers.dart';
import 'package:flutter_application_1/features/common/data/supabase_service.dart';
import 'package:go_router/go_router.dart';

class OnboardingDebugWidget extends ConsumerWidget {
  const OnboardingDebugWidget({super.key});

  Future<void> _resetOnboarding(WidgetRef ref) async {
    try {
      // 서버에서 profile_completed를 false로 업데이트
      final user = SupabaseService.currentUser;
      if (user != null) {
        await SupabaseService.updateProfileCompleted(user.id, false);
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
      
      // AuthController 상태 업데이트 및 프로바이더 새로고침
      ref.read(authControllerProvider.notifier).updateProfileCompleted(false);
      ref.invalidate(userProfileProvider);
      
      print('✅ 온보딩 데이터 리셋 완료 (서버 + 로컬)');
    } catch (e) {
      print('❌ 온보딩 데이터 리셋 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 필요한 상태만 선택적으로 watch
    final profileCompleted = ref.watch(authControllerProvider.select((state) => state.profileCompleted));
    
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
                  child: Text(
                    profileCompleted == null 
                        ? '확인 중...' 
                        : (profileCompleted ? '완료됨' : '미완료'),
                    style: TextStyle(
                      color: profileCompleted == null 
                          ? Colors.orange 
                          : (profileCompleted ? Colors.green : Colors.red),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 8),
          
          // 버튼을 세로로 배치해 오버플로우를 방지
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
                    ref.invalidate(userProfileProvider);
                    // AuthController는 이미 최신 상태를 유지하므로 새로고침 불필요
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
