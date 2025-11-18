import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_application_1/core/router/app_router.dart';
import 'package:flutter_application_1/color.dart';
import 'package:flutter_application_1/features/auth/application/auth_providers.dart';
import 'package:flutter_application_1/features/diet/application/diet_providers.dart';
import 'package:flutter_application_1/features/workout/application/workout_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://wkmnnzndtggrlrzjlncn.supabase.co', // Supabase URL 주소
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndrbW5uem5kdGdncmxyempsbmNuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjExODU1NDIsImV4cCI6MjA3Njc2MTU0Mn0.bd9pcs-4YDyL98YcKhBzq53u2CONtjUv7NdYEcDA-eU', // Supabase anon key
  );
  runApp(const ProviderScope(child: PTApp()));
}

class PTApp extends ConsumerWidget {
  const PTApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(_appWarmupProvider);

    return MaterialApp.router(
      title: 'PT 앱',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: mainButtonColor,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: backgroundColor,
        appBarTheme: const AppBarTheme(
          backgroundColor: backgroundColor,
          foregroundColor: mainButtonColor,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: mainButtonColor,
            foregroundColor: backgroundColor,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: mainButtonColor, width: 2),
          ),
          filled: true,
          fillColor: backgroundColor,
        ),
      ),
      routerConfig: ref.watch(goRouterProvider),
    );
  }
}

final _appWarmupProvider = Provider<void>((ref) {
  var hasPrefetchedDiet = false;
  var hasPrefetchedWorkout = false;

  Future<void> _prefetchDietPlan() async {
    final future = ref.read(todayDietPlanProvider.future);
    unawaited(
      future.catchError(
        (error, stack) => debugPrint('사전 식단 추천 로딩 실패: $error'),
      ),
    );
  }

  Future<void> _prefetchWorkoutRoutines() async {
    final future = ref.read(aiRecommendedRoutinesProvider.future);
    unawaited(
      future.catchError(
        (error, stack) => debugPrint('사전 운동 추천 로딩 실패: $error'),
      ),
    );
  }

  void _triggerPrefetch(AuthState state) {
    if (!state.isLoggedIn || state.isLoading) {
      if (!state.isLoggedIn) {
        hasPrefetchedDiet = false;
        hasPrefetchedWorkout = false;
      }
      return;
    }

    if (!hasPrefetchedDiet) {
      hasPrefetchedDiet = true;
      _prefetchDietPlan();
    }

    if (!hasPrefetchedWorkout) {
      hasPrefetchedWorkout = true;
      _prefetchWorkoutRoutines();
    }
  }

  ref.listen<AuthState>(
    authControllerProvider,
    (previous, next) => _triggerPrefetch(next),
    fireImmediately: true,
  );
});
