import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/application/auth_providers.dart';
import '../../workout/application/workout_providers.dart';
import '../../workout/data/supabase_workout_service.dart';
import '../data/diet_history_repository.dart';
import '../domain/records_models.dart';

final dietHistoryRepositoryProvider = Provider<DietHistoryRepository>((ref) {
  return DietHistoryRepository();
});

final recordsHistoryProvider = FutureProvider.autoDispose<RecordsHistory>((ref) async {
  // Auth 상태를 watch하여 로그인/로그아웃 시 자동으로 새로고침
  final authState = ref.watch(authControllerProvider);

  final dietRepository = ref.watch(dietHistoryRepositoryProvider);
  final supabaseService = ref.read(supabaseWorkoutServiceProvider);

  // 현재 user_id와 이메일 로그 출력
  final currentUser = Supabase.instance.client.auth.currentUser;
  print('🔍 [Records] 현재 로그인 계정: ${currentUser?.email}');
  print('🔍 [Records] 현재 user_id: ${currentUser?.id}');
  print('🔍 [Records] Auth 상태: isLoggedIn=${authState.isLoggedIn}');

  final history = RecordsHistory();

  final dietRecords = await dietRepository.loadRecentDietRecords();
  for (final record in dietRecords) {
    history.upsertRecord(record);
  }

  final workoutSessions =
      await supabaseService.getRecentCompletedSessions(daysBack: 90);
  for (final log in workoutSessions) {
    final session = log.session;
    final start = session.startTime;
    final end = session.endTime ?? session.startTime;
    final duration =
        end.isAfter(start) ? end.difference(start) : const Duration();

    final entry = WorkoutRecordEntry(
      sessionId: session.sessionId,
      title: log.routineTitle ?? '운동 세션',
      duration: duration.inSeconds > 0 ? duration : null,
      calories: session.totalCalories,
      startedAt: start,
      completionMethod: session.completionMethod,
      manualNotes: session.manualNotes,
      perceivedIntensity: session.perceivedIntensity,
      isUserReported: session.isUserReported,
    );

    history.upsertRecord(
      DailyRecord(
        date: truncateToDate(start),
        workouts: [entry],
      ),
    );
  }

  return history;
});
