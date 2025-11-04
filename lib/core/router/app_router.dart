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
import 'package:flutter_application_1/features/records/presentation/records_detail_screen.dart';
import 'package:flutter_application_1/features/records/presentation/records_screen.dart';
import 'package:flutter_application_1/features/workout/presentation/workout_detail_screen.dart';
import 'package:flutter_application_1/features/workout/presentation/workout_screen.dart';
import 'package:flutter_application_1/features/workout/presentation/create_routine_screen.dart';
import 'package:flutter_application_1/features/workout/application/workout_providers.dart';
import 'package:flutter_application_1/screens/exercise_screen.dart';
import 'package:flutter_application_1/features/onboarding/presentation/onboarding_screen.dart';
import 'package:flutter_application_1/features/profile/presentation/profile_settings_screen.dart';
import 'package:flutter_application_1/features/auth/presentation/auth_loading_screen.dart';
import 'package:go_router/go_router.dart';

class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription _sub;
  GoRouterRefreshStream(Stream<dynamic> stream) {
    // 중복 이벤트 방지를 위한 디바운싱
    _sub = stream.asBroadcastStream()
        .distinct() // 중복 이벤트 제거
        .listen((_) => notifyListeners());
  }
  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);
  final authNotifier = ref.read(authControllerProvider.notifier);
  
  final defaultRoute = WidgetsBinding.instance.platformDispatcher.defaultRouteName;
  final initialLocation =
      (defaultRoute.isEmpty || defaultRoute == '/') ? '/app/home' : defaultRoute;

  return GoRouter(
    initialLocation: initialLocation,
    refreshListenable: GoRouterRefreshStream(authNotifier.stream),
    errorBuilder: (context, state) => NotFoundScreen(
      message: state.error?.toString() ?? '요청하신 페이지를 찾을 수 없어요.',
    ),
    redirect: (context, state) {
      // 상태 추출 (한 번만)
      final isLoggedIn = authState.isLoggedIn;
      final profileCompleted = authState.profileCompleted;
      final isLoading = authState.isLoading;
      
      // 경로 분류 (한 번만)
      final location = state.matchedLocation;
      final goingToApp = location.startsWith('/app');
      final goingToAuth = location == '/' || location == '/login' || location == '/signup';
      final goingToOnboarding = location == '/onboarding';

      // 로딩 중이면 대기 (깜빡임 방지)
      if (isLoading) return null;

      // 미로그인 + 앱 접근 → 로그인
      if (!isLoggedIn && goingToApp) {
        authNotifier.setRedirect(state.uri.toString());
        return '/';
      }

      // 로그인됨 + 인증 페이지 접근 → 상태 기반 리다이렉트
      if (isLoggedIn && goingToAuth) {
        final stored = authNotifier.takeRedirect();
        if (stored?.isNotEmpty == true) return stored;
        
        if (profileCompleted == null) return null; // 상태 확인 중
        return profileCompleted ? '/app/home' : '/onboarding';
      }

      // 로그인됨 + 앱 접근 + 프로필 미완료 → 온보딩
      if (isLoggedIn && goingToApp && !goingToOnboarding) {
        if (profileCompleted == null) return null; // 상태 확인 중
        if (!profileCompleted) return '/onboarding';
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
      GoRoute(
        path: '/loading',
        name: 'loading',
        builder: (context, state) => const AuthLoadingScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainDashboard(
          child: child,
          location: state.matchedLocation,
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
              GoRoute(
                path: 'exercise',
                name: 'exercise',
                builder: (context, state) {
                  final extra = state.extra;
                  List<int>? exerciseIds;
                  if (extra is Map<String, dynamic>) {
                    exerciseIds = extra['exerciseIds'] as List<int>?;
                  }
                  return ExerciseScreen(exerciseIds: exerciseIds);
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
              GoRoute(
                path: 'settings',
                name: 'profile-settings',
                builder: (context, state) => const ProfileSettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
