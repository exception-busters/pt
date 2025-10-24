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
    redirect: (context, state) {
      final goingToApp = state.matchedLocation.startsWith('/app');
      final loggingIn = state.matchedLocation == '/' || state.matchedLocation == '/login';
      final signingUp = state.matchedLocation == '/signup';

      if (!isLoggedIn && goingToApp) {
        authNotifier.setRedirect(state.uri.toString());
        return '/';
      }

      if (isLoggedIn && (loggingIn || signingUp)) {
        final stored = authNotifier.takeRedirect();
        if (stored != null && stored.isNotEmpty) {
          return stored;
        }
        return '/app/home';
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
