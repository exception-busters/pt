import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_application_1/common/presentation/not_found_screen.dart';
import 'package:flutter_application_1/features/auth/application/auth_providers.dart';
import 'package:flutter_application_1/features/auth/presentation/login_screen.dart';
import 'package:flutter_application_1/features/auth/presentation/sign_up_screen.dart';
import 'package:flutter_application_1/features/dashboard/presentation/main_dashboard.dart';
import 'package:flutter_application_1/features/diet/presentation/diet_screen.dart';
import 'package:flutter_application_1/features/home/presentation/home_screen.dart';
import 'package:flutter_application_1/features/profile/presentation/profile_screen.dart';
import 'package:flutter_application_1/features/profile/presentation/edit_profile_screen.dart';
import 'package:flutter_application_1/features/profile/presentation/workout_goal_screen.dart';
import 'package:flutter_application_1/features/profile/presentation/diet_goal_screen.dart';
import 'package:flutter_application_1/features/profile/presentation/notification_settings_screen.dart';
import 'package:flutter_application_1/features/profile/presentation/help_screen.dart';
import 'package:flutter_application_1/features/profile/application/profile_providers.dart';
import 'package:flutter_application_1/features/profile/data/user_service.dart';
import 'package:flutter_application_1/features/records/presentation/records_detail_screen.dart';
import 'package:flutter_application_1/features/records/presentation/records_screen.dart';
import 'package:flutter_application_1/features/workout/presentation/workout_detail_screen.dart';
import 'package:flutter_application_1/features/workout/presentation/workout_screen.dart';
import 'package:flutter_application_1/features/workout/presentation/create_routine_screen.dart';
import 'package:flutter_application_1/features/workout/application/workout_providers.dart';
import 'package:flutter_application_1/features/onboarding/presentation/onboarding_screen.dart';
import 'package:flutter_application_1/features/onboarding/application/onboarding_providers.dart';
import 'package:go_router/go_router.dart';

class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription _sub;
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _sub = stream.asBroadcastStream().listen((_) => notifyListeners());
  }
  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

final goRouterProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.watch(authControllerProvider.notifier);
  final isLoggedIn = ref.watch(authControllerProvider);
  final defaultRoute = WidgetsBinding.instance.platformDispatcher.defaultRouteName;
  final initialLocation =
      (defaultRoute.isEmpty || defaultRoute == '/') ? '/app/home' : defaultRoute;

  return GoRouter(
    initialLocation: initialLocation,
    refreshListenable: GoRouterRefreshStream(authNotifier.stream),
    errorBuilder: (context, state) => NotFoundScreen(
      message: state.error?.toString() ?? '요청하신 페이지를 찾을 수 없어요.',
    ),
    redirect: (context, state) async {
      final goingToApp = state.matchedLocation.startsWith('/app');
      final goingToOnboarding = state.matchedLocation == '/onboarding';
      final loggingIn = state.matchedLocation == '/' || state.matchedLocation == '/login';
      final signingUp = state.matchedLocation == '/signup';

      print('🔍 라우터 리다이렉트 체크: 로그인상태=$isLoggedIn, 목적지=${state.matchedLocation}');

      // 로그인되지 않은 상태에서 앱 페이지 접근 시 로그인 페이지로
      if (!isLoggedIn && goingToApp) {
        print('🔍 라우터: 미로그인 상태에서 앱 접근 - 로그인 페이지로');
        authNotifier.setRedirect(state.uri.toString());
        return '/';
      }

      // 로그인된 상태에서 로그인/회원가입 페이지 접근 시
      if (isLoggedIn && (loggingIn || signingUp)) {
        print('🔍 라우터: 로그인 상태에서 로그인 페이지 접근 - profile_completed 확인');
        
        final stored = authNotifier.takeRedirect();
        if (stored != null && stored.isNotEmpty) {
          print('🔍 라우터: 저장된 리다이렉트 경로 사용: $stored');
          return stored;
        }
        
        // 직접 UserService를 사용하여 실시간으로 profile_completed 확인
        try {
          final userService = ref.read(userServiceProvider);
          final profileCompleted = await userService.isProfileCompleted();
          
          print('🔍 라우터: 실시간 profile_completed 확인 결과 = $profileCompleted');
          
          if (profileCompleted) {
            print('🔍 라우터: 프로필 완료됨 - 홈으로 이동');
            return '/app/home';
          } else {
            print('🔍 라우터: 프로필 미완료 - 온보딩으로 이동');
            return '/onboarding';
          }
        } catch (e) {
          print('❌ 라우터: profile_completed 확인 실패 - 안전하게 온보딩으로: $e');
          return '/onboarding';
        }
      }

      // 로그인된 상태에서 프로필이 완료되지 않았고 온보딩 페이지가 아닌 경우
      if (isLoggedIn && !goingToOnboarding && goingToApp) {
        print('🔍 라우터: 로그인 상태에서 앱 페이지 접근 - profile_completed 재확인');
        
        try {
          final userService = ref.read(userServiceProvider);
          final profileCompleted = await userService.isProfileCompleted();
          
          print('🔍 라우터: 앱 접근 시 profile_completed 확인 결과 = $profileCompleted');
          
          if (!profileCompleted) {
            print('🔍 라우터: 프로필 미완료 - 온보딩 페이지로 리다이렉트');
            return '/onboarding';
          }
          
          print('🔍 라우터: 프로필 완료됨 - 정상 진행');
          return null; // 프로필 완료 시 정상 진행
        } catch (e) {
          print('❌ 라우터: profile_completed 확인 실패 - 안전하게 온보딩으로: $e');
          return '/onboarding';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        name: 'login',
        builder: (context, state) => LoginScreen(
          redirectPath: state.uri.queryParameters['redirect'],
        ),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainDashboard(
          child: child,
          location: state.uri.toString(),
        ),
        routes: [
          GoRoute(
            path: '/app/home',
            name: 'home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/app/diet',
            name: 'diet',
            builder: (context, state) => const DietScreen(),
          ),
          GoRoute(
            path: '/app/workout',
            name: 'workout',
            builder: (context, state) => const WorkoutScreen(),
            routes: [
              GoRoute(
                path: 'detail/:id',
                name: 'workout-detail',
                builder: (context, state) => WorkoutDetailScreen(
                  workoutId: state.pathParameters['id']!,
                ),
              ),
              GoRoute(
                path: 'create-routine',
                name: 'create-routine',
                builder: (context, state) {
                  final extra = state.extra;
                  if (extra is WorkoutRoutine) {
                    return CreateRoutineScreen(editingRoutine: extra);
                  } else if (extra is Map<String, dynamic>) {
                    return CreateRoutineScreen(
                      editingRoutine: extra['editingRoutine'] as WorkoutRoutine?,
                      editingSupabaseRoutine: extra['editingSupabaseRoutine'],
                    );
                  } else {
                    return const CreateRoutineScreen();
                  }
                },
              ),
            ],
          ),
          GoRoute(
            path: '/app/records',
            name: 'records',
            builder: (context, state) => const RecordsScreen(),
            routes: [
              GoRoute(
                path: 'detail/:id',
                name: 'record-detail',
                builder: (context, state) => RecordsDetailScreen(
                  recordId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/app/profile',
            name: 'profile',
            builder: (context, state) => const ProfileScreen(),
            routes: [
              GoRoute(
                path: 'edit',
                name: 'edit-profile',
                builder: (context, state) => const EditProfileScreen(),
              ),
              GoRoute(
                path: 'workout-goal',
                name: 'workout-goal',
                builder: (context, state) => const WorkoutGoalScreen(),
              ),
              GoRoute(
                path: 'diet-goal',
                name: 'diet-goal',
                builder: (context, state) => const DietGoalScreen(),
              ),
              GoRoute(
                path: 'notifications',
                name: 'notifications',
                builder: (context, state) => const NotificationSettingsScreen(),
              ),
              GoRoute(
                path: 'help',
                name: 'help',
                builder: (context, state) => const HelpScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
