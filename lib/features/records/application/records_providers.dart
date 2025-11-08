import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../workout/application/workout_providers.dart';
import '../../workout/data/supabase_workout_service.dart';
import '../data/diet_history_repository.dart';
import '../domain/records_models.dart';

final dietHistoryRepositoryProvider = Provider<DietHistoryRepository>((ref) {
  return DietHistoryRepository();
});

final recordsHistoryProvider = FutureProvider<RecordsHistory>((ref) async {
  final dietRepository = ref.watch(dietHistoryRepositoryProvider);
  final supabaseService = ref.read(supabaseWorkoutServiceProvider);

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
