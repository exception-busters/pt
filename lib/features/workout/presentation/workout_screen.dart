import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_application_1/color.dart';
import 'package:flutter_application_1/features/workout/application/workout_providers.dart';
import 'package:flutter_application_1/features/records/application/records_providers.dart';
import 'package:flutter_application_1/features/profile/application/complete_profile_providers.dart';
import 'package:flutter_application_1/features/workout/domain/models/supabase_routine_schedule.dart';
import 'package:flutter_application_1/features/workout/presentation/create_routine_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const List<String> _weekdayLabels = ['월', '화', '수', '목', '금', '토', '일'];

class WorkoutScreen extends ConsumerStatefulWidget {
  const WorkoutScreen({super.key});

  @override
  ConsumerState<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends ConsumerState<WorkoutScreen> {
  int _selectedWeekday = (DateTime.now().weekday - 1) % 7;

  void _selectWeekday(int day) {
    setState(() {
      _selectedWeekday = day;
    });
  }

  Future<void> _editRoutineSchedule(
    BuildContext context,
    dynamic routine,
    List<int> currentWeekdays,
  ) async {
    final routineId = routine.routineId as int?;
    if (routineId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('루틴 ID가 없어 요일을 저장할 수 없어요.')),
      );
      return;
    }

    final selectedDays = await showModalBottomSheet<Set<int>>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _RoutineScheduleSheet(
        routineTitle: routine.title as String,
        initialDays: currentWeekdays.toSet(),
      ),
    );

    if (selectedDays == null) return;

    try {
      await ref
          .read(supabaseWorkoutServiceProvider)
          .saveRoutineSchedule(routineId: routineId, weekdays: selectedDays);
      if (!context.mounted) return;
      ref.invalidate(routineSchedulesProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${routine.title} 요일 설정을 저장했어요.')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('요일 설정 저장에 실패했습니다: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _openManualCompletionSheet(
    BuildContext context,
    dynamic routine, {
    String? completionLabel,
    int? defaultDuration,
  }) async {
    final routineId = routine.routineId as int?;
    if (routineId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('루틴 ID가 없어 기록을 저장할 수 없어요.')),
      );
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _ManualCompletionSheet(
          routineId: routineId,
          routineTitle: routine.title as String,
        ),
      ),
    );
  }
  void _showSupabaseDeleteDialog(BuildContext context, routine) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supabase 루틴 삭제'),
        content: Text('${routine.title} 루틴을 데이터베이스에서 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              final success = await ref.read(supabaseRoutineNotifierProvider.notifier).deleteRoutine(routine.routineId);
              if (context.mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Supabase 루틴이 삭제되었습니다' : '루틴 삭제에 실패했습니다'),
                    backgroundColor: success ? Colors.blue : Colors.red,
                  ),
                );
              }
            },
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _startRoutine(BuildContext context, dynamic routine) {
    final List<int> exerciseIds = [];
    if (routine.routineExercises != null) {
      for (final routineExercise in routine.routineExercises!) {
        if (routineExercise != null && routineExercise['exercise'] != null) {
          final exerciseId = routineExercise['exercise']['exercise_id'];
          if (exerciseId != null) {
            exerciseIds.add(exerciseId as int);
          }
        }
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${routine.title} 루틴을 시작합니다'),
        backgroundColor: mainButtonColor,
        duration: const Duration(seconds: 1),
      ),
    );

    context.push('/app/workout/exercise', extra: {
      'exerciseIds': exerciseIds,
    });
  }

  Map<int, List<_ScheduledRoutineEntry>> _buildDayScheduleMap(
    List<dynamic> routines,
    Map<int, List<SupabaseRoutineSchedule>> scheduleMap,
  ) {
    final routineById = <int, dynamic>{};
    for (final routine in routines) {
      final id = routine.routineId as int?;
      if (id != null) {
        routineById[id] = routine;
      }
    }

    final result = <int, List<_ScheduledRoutineEntry>>{};
    scheduleMap.forEach((routineId, schedules) {
      final routine = routineById[routineId];
      if (routine == null) return;
      for (final schedule in schedules) {
        result.putIfAbsent(schedule.weekday, () => []).add(
              _ScheduledRoutineEntry(
                routine: routine,
                schedule: schedule,
              ),
            );
      }
    });

    for (final entries in result.values) {
      entries.sort(
        (a, b) => a.schedule.sortOrder.compareTo(b.schedule.sortOrder),
      );
    }

    for (var day = 0; day < _weekdayLabels.length; day++) {
      result.putIfAbsent(day, () => []);
    }

    return result;
  }

  Future<void> _handleAddRoutineToDay(
    BuildContext context,
    int weekday,
    List<dynamic> routines,
  ) async {
    // 루틴이 없어도 다이얼로그를 열어서 루틴 만들기 버튼을 보여줌
    final routine = await showModalBottomSheet<dynamic>(
      context: context,
      builder: (context) => _RoutinePickerSheet(routines: routines),
    );

    if (routine == null) return;
    final routineId = routine.routineId as int?;
    if (routineId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('루틴 정보를 불러오지 못했습니다. 다시 시도해주세요.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final success = await ref
        .read(supabaseWorkoutServiceProvider)
        .addRoutineToWeekday(routineId: routineId, weekday: weekday);

    if (!mounted) return;

    if (success) {
      ref.invalidate(routineSchedulesProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${routine.title}을(를) ${_weekdayLabels[weekday]}요일에 추가했어요.'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('요일 추가에 실패했습니다. 다시 시도해주세요.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleRemoveScheduleEntry(
    BuildContext context,
    int? scheduleId,
  ) async {
    if (scheduleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('삭제할 스케줄 정보를 찾을 수 없습니다.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final success = await ref
        .read(supabaseWorkoutServiceProvider)
        .removeRoutineSchedule(scheduleId);

    if (!mounted) return;

    if (success) {
      ref.invalidate(routineSchedulesProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('스케줄이 삭제되었습니다.'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('스케줄 삭제에 실패했습니다.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _openScheduleManager() async {
    final routines = ref.read(supabaseRoutineNotifierProvider).maybeWhen(
          data: (value) => value,
          orElse: () => const <dynamic>[],
        );

    final scheduleData =
        ref.read(routineSchedulesProvider).maybeWhen<Map<int, List<SupabaseRoutineSchedule>>>(
              data: (value) => value,
              orElse: () => const {},
            );

    Future<Map<int, List<_ScheduledRoutineEntry>>> reloadEntries() async {
      final latest = await ref.read(routineSchedulesProvider.future);
      return _buildDayScheduleMap(routines, latest);
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _ScheduleManagerSheet(
        routines: routines,
        initialEntries: _buildDayScheduleMap(routines, scheduleData),
        reloadEntries: reloadEntries,
        onAddRoutine: (routineId, weekday) async {
          final success = await ref
              .read(supabaseWorkoutServiceProvider)
              .addRoutineToWeekday(routineId: routineId, weekday: weekday);
          if (success) {
            ref.invalidate(routineSchedulesProvider);
          }
          return success;
        },
        onRemoveSchedule: (scheduleId) async {
          final success = await ref
              .read(supabaseWorkoutServiceProvider)
              .removeRoutineSchedule(scheduleId);
          if (success) {
            ref.invalidate(routineSchedulesProvider);
          }
          return success;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final supabaseRoutinesAsync = ref.watch(supabaseRoutineNotifierProvider);
    final routineSchedulesAsync = ref.watch(routineSchedulesProvider);
    final aiRecommendedRoutinesAsync = ref.watch(aiRecommendedRoutinesProvider);
    final supabaseRoutineList =
        supabaseRoutinesAsync.maybeWhen<List<dynamic>>(
      data: (data) => data,
      orElse: () => const <dynamic>[],
    );

    // 오늘의 운동 목표 및 진행 상황
    final workoutGoal = ref.watch(workoutGoalModelProvider);
    final recordsHistoryAsync = ref.watch(recordsHistoryProvider);
    final dailyGoalMinutes = workoutGoal?.dailyDurationMin ?? 30;

    return Scaffold(
      appBar: AppBar(
        title: const Text('운동'),
        backgroundColor: backgroundColor,
        foregroundColor: mainButtonColor,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
              recordsHistoryAsync.when(
                data: (recordsHistory) {
                  final todayRecord = recordsHistory.recordFor(DateTime.now());
                  final todayWorkoutMinutes = todayRecord?.totalWorkoutMinutes ?? 0;
                  final remaining = dailyGoalMinutes - todayWorkoutMinutes;
                  final isCompleted = todayWorkoutMinutes >= dailyGoalMinutes;

                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: mainButtonColor,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          '오늘의 운동',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$todayWorkoutMinutes분 / $dailyGoalMinutes분',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isCompleted
                              ? '목표 달성! 🎉'
                              : '$remaining분 더 운동하세요!',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  );
                },
                loading: () => Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: mainButtonColor,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Column(
                    children: [
                      Text(
                        '오늘의 운동',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white70,
                        ),
                      ),
                      SizedBox(height: 8),
                      CircularProgressIndicator(color: Colors.white),
                    ],
                  ),
                ),
                error: (_, __) => Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: mainButtonColor,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        '오늘의 운동',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '0분 / $dailyGoalMinutes분',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '내 루틴',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: mainButtonColor,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _openScheduleManager,
                    icon: const Icon(Icons.manage_history, size: 20),
                    label: const Text('루틴관리'),
                    style: TextButton.styleFrom(
                      foregroundColor: mainButtonColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: List.generate(_weekdayLabels.length, (index) {
                  final selected = _selectedWeekday == index;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: index == _weekdayLabels.length - 1 ? 0 : 8,
                      ),
                      child: GestureDetector(
                        onTap: () => _selectWeekday(index),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(
                              color: selected ? mainButtonColor : borderColor,
                              width: selected ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _weekdayLabels[index],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: selected ? mainButtonColor : Colors.black,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              routineSchedulesAsync.when(
                data: (scheduleMap) => _ScheduleSection(
                  daysToShow: [_selectedWeekday],
                  dayEntries: _buildDayScheduleMap(
                    supabaseRoutineList,
                    scheduleMap,
                  ),
                  onAddRoutine: (day) => _handleAddRoutineToDay(
                    context,
                    day,
                    supabaseRoutineList,
                  ),
                  onStartRoutine: (routine) =>
                      _startRoutine(context, routine),
                  onRemoveSchedule: (entry) =>
                      _handleRemoveScheduleEntry(
                    context,
                    entry.schedule.scheduleId,
                  ),
                ),
                loading: () => const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (error, _) => Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '요일별 루틴 정보를 불러오지 못했습니다.',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '$error',
                                style: const TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // AI 추천 루틴 섹션
                      const Divider(color: Colors.grey),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.auto_awesome, color: mainButtonColor, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'AI 추천 루틴',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: mainButtonColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: mainButtonColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Beta',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: mainButtonColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
              aiRecommendedRoutinesAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (error, stack) => Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: const Text(
                    'AI 추천 루틴을 불러올 수 없습니다',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
                data: (aiRecommendedRoutines) => Column(
                  children: aiRecommendedRoutines.map((routine) {
                    return _AIRecoRoutCard(
                      routine: routine,
                      onTap: () {
                        final exerciseIds = <int>[];
                        for (final exercise in routine.exercises) {
                          try {
                            exerciseIds.add(int.parse(exercise.id));
                          } catch (_) {
                            debugPrint('운동 ID 파싱 실패: ${exercise.id}');
                          }
                        }

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${routine.name} 루틴을 시작합니다'),
                            backgroundColor: mainButtonColor,
                            duration: const Duration(seconds: 1),
                          ),
                        );

                        context.push('/app/workout/exercise', extra: {
                          'exerciseIds': exerciseIds,
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkoutCard extends StatelessWidget {
  const _WorkoutCard({
    required this.title,
    required this.duration,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String duration;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: mainButtonColor,
                ),
              ),
            ),
            Text(
              duration,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SupabaseRoutineCard extends StatelessWidget {
  const _SupabaseRoutineCard({
    required this.routine,
    required this.onTap,
    required this.onDelete,
    required this.onManageSchedule,
    required this.onManualComplete,
    this.weekdays = const <int>[],
  });

  final dynamic routine; // SupabaseWorkoutRoutine
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onManageSchedule;
  final VoidCallback onManualComplete;
  final List<int> weekdays;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.fitness_center, color: Colors.grey),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        routine.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        routine.description ?? '설명 없음',
                        style: const TextStyle(
                          fontSize: 12,
                          color: subTextColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: ${routine.routineId}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: subTextColor,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.grey, size: 20),
                      onPressed: () {
                        context.push('/app/workout/create-routine', extra: {
                          'editingSupabaseRoutine': routine,
                        });
                      },
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                    IconButton(
                      icon: const Icon(Icons.play_arrow, color: mainButtonColor, size: 24),
                      onPressed: () {
                        onTap(); // 카드의 onTap 호출 (루틴 시작)
                      },
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                      onPressed: onDelete,
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (weekdays.isNotEmpty)
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: weekdays.map((weekday) {
                  final label = weekday >= 0 && weekday < _weekdayLabels.length
                      ? _weekdayLabels[weekday]
                      : '?';
                  return Chip(
                    label: Text(label),
                    labelStyle: const TextStyle(fontSize: 12),
                    backgroundColor: mainButtonColor.withOpacity(0.1),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                }).toList(),
              )
            else
              const Text(
                '요일이 아직 지정되지 않았어요.',
                style: TextStyle(fontSize: 12, color: subTextColor),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onManageSchedule,
                    icon: const Icon(Icons.calendar_month, size: 18),
                    label: const Text('요일 설정'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onManualComplete,
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text('수동 완료'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AIRecoRoutCard extends ConsumerWidget {
  const _AIRecoRoutCard({
    required this.routine,
    required this.onTap,
  });

  final WorkoutRoutine routine;
  final VoidCallback onTap;

  Future<void> _saveAsMyRoutine(BuildContext context, WidgetRef ref, {bool editFirst = false}) async {
    if (editFirst) {
      // 수정 후 등록: CreateRoutineScreen으로 이동
      final exercises = routine.exercises.map((e) => Exercise(
        id: e.id,
        name: e.name,
        description: e.description,
        duration: e.duration,
        category: e.category,
        sets: e.sets,
        reps: e.reps,
        restSeconds: e.restSeconds,
      )).toList();

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => CreateRoutineScreen(
            initialRoutineName: routine.name.replaceAll('🤖 AI 추천: ', ''),
            initialExercises: exercises,
          ),
        ),
      );
    } else {
      // 바로 등록
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('루틴 등록'),
          content: Text('${routine.name}을(를) 내 루틴으로 등록하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('등록'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      final exercises = routine.exercises.map((e) => Exercise(
        id: e.id,
        name: e.name,
        description: e.description,
        duration: e.duration,
        category: e.category,
        sets: e.sets,
        reps: e.reps,
        restSeconds: e.restSeconds,
      )).toList();

      final success = await ref.read(supabaseRoutineNotifierProvider.notifier).createRoutine(
            routine.name.replaceAll('🤖 AI 추천: ', ''),
            'AI가 추천한 운동 루틴',
            exercises,
          );

      if (!context.mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${routine.name}이(가) 내 루틴으로 등록되었습니다.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('루틴 등록에 실패했습니다.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: mainButtonColor.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: mainButtonColor.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: mainButtonColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.auto_awesome, color: mainButtonColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        routine.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: mainButtonColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${routine.exercises.length}개 운동 • ${routine.formattedDuration}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: subTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: onTap,
                  child: const Icon(
                    Icons.play_arrow,
                    color: mainButtonColor,
                    size: 24,
                  ),
                ),
              ],
            ),
            if (routine.exercises.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: routine.exercises.take(4).map((exercise) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: mainButtonColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          exercise.name,
                          style: const TextStyle(
                            fontSize: 11,
                            color: mainButtonColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          exercise.volumeSummary,
                          style: const TextStyle(
                            fontSize: 10,
                            color: mainButtonColor,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList()
                  ..addAll(routine.exercises.length > 4
                      ? [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: mainButtonColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '+${routine.exercises.length - 4}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: mainButtonColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ]
                      : []),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _saveAsMyRoutine(context, ref, editFirst: false),
                      icon: const Icon(Icons.add_circle_outline, size: 18),
                      label: const Text('바로 등록'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: mainButtonColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _saveAsMyRoutine(context, ref, editFirst: true),
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('수정 후 등록'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: mainButtonColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ScheduleSection extends StatelessWidget {
  const _ScheduleSection({
    required this.daysToShow,
    required this.dayEntries,
    required this.onAddRoutine,
    required this.onStartRoutine,
    required this.onRemoveSchedule,
  });

  final List<int> daysToShow;
  final Map<int, List<_ScheduledRoutineEntry>> dayEntries;
  final ValueSetter<int> onAddRoutine;
  final ValueSetter<dynamic> onStartRoutine;
  final ValueSetter<_ScheduledRoutineEntry> onRemoveSchedule;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: daysToShow.map((day) {
        final entries = dayEntries[day] ?? const <_ScheduledRoutineEntry>[];
        return _DayScheduleSection(
          weekday: day,
          entries: entries,
          onAdd: () => onAddRoutine(day),
          onStart: (routine) => onStartRoutine(routine),
          onRemove: (entry) => onRemoveSchedule(entry),
        );
      }).toList(),
    );
  }
}

class _ScheduleManagerSheet extends StatefulWidget {
  const _ScheduleManagerSheet({
    required this.routines,
    required this.initialEntries,
    required this.reloadEntries,
    required this.onAddRoutine,
    required this.onRemoveSchedule,
  });

  final List<dynamic> routines;
  final Map<int, List<_ScheduledRoutineEntry>> initialEntries;
  final Future<Map<int, List<_ScheduledRoutineEntry>>> Function()
      reloadEntries;
  final Future<bool> Function(int routineId, int weekday) onAddRoutine;
  final Future<bool> Function(int scheduleId) onRemoveSchedule;

  @override
  State<_ScheduleManagerSheet> createState() => _ScheduleManagerSheetState();
}

class _ScheduleManagerSheetState extends State<_ScheduleManagerSheet>
    with SingleTickerProviderStateMixin {
  late Map<int, List<_ScheduledRoutineEntry>> _entries;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _entries = widget.initialEntries.map(
      (key, value) => MapEntry(key, List.of(value)),
    );
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final refreshed = await widget.reloadEntries();
    setState(() {
      _entries = refreshed;
    });
  }

  Future<void> _removeEntry(_ScheduledRoutineEntry entry) async {
    final scheduleId = entry.schedule.scheduleId;
    if (scheduleId == null) {
      return;
    }
    final success = await widget.onRemoveSchedule(scheduleId);
    if (success) {
      await _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('스케줄을 삭제했습니다.')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('스케줄을 삭제하지 못했습니다. 다시 시도해주세요.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: SafeArea(
        child: Container(
          height: MediaQuery.of(context).size.height * 0.85,
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '루틴 관리',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: mainButtonColor,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TabBar(
                controller: _tabController,
                labelColor: mainButtonColor,
                unselectedLabelColor: subTextColor,
                indicatorColor: mainButtonColor,
                tabs: const [
                  Tab(text: '루틴 목록'),
                  Tab(text: '요일별 스케줄'),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _RoutineListTab(
                      routines: widget.routines,
                      entries: _entries,
                      onRefresh: _refresh,
                      onAddRoutine: widget.onAddRoutine,
                      onRemoveSchedule: widget.onRemoveSchedule,
                    ),
                    _WeeklyScheduleTab(
                      routines: widget.routines,
                      entries: _entries,
                      onAddRoutine: widget.onAddRoutine,
                      onRemoveEntry: _removeEntry,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DayScheduleSection extends StatelessWidget {
  const _DayScheduleSection({
    required this.weekday,
    required this.entries,
    required this.onAdd,
    required this.onStart,
    required this.onRemove,
  });

  final int weekday;
  final List<_ScheduledRoutineEntry> entries;
  final VoidCallback onAdd;
  final ValueSetter<dynamic> onStart;
  final ValueSetter<_ScheduledRoutineEntry> onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_weekdayLabels[weekday]}요일 루틴',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: mainButtonColor,
                ),
              ),
              OutlinedButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('루틴 추가'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (entries.isEmpty)
            const Text(
              '이 요일에 등록된 루틴이 없습니다.',
              style: TextStyle(color: subTextColor),
            )
          else
            Column(
              children: entries.map((entry) {
                final routine = entry.routine;
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(
                      routine.title ?? '루틴',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (routine.description != null)
                          Text(
                            routine.description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        if (entry.schedule.startTime != null)
                          Text(
                            '시작 시간: ${entry.schedule.startTime}',
                            style: const TextStyle(fontSize: 12),
                          ),
                      ],
                    ),
                    trailing: Wrap(
                      spacing: 4,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.flash_on, color: Colors.orange),
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              builder: (context) => _QuickCompleteSheet(routine: routine),
                            );
                          },
                          tooltip: '빠른 완료',
                        ),
                        IconButton(
                          icon: const Icon(Icons.play_arrow, color: mainButtonColor),
                          onPressed: () => onStart(routine),
                          tooltip: '시작',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => onRemove(entry),
                          tooltip: '삭제',
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

class _ScheduledRoutineEntry {
  const _ScheduledRoutineEntry({
    required this.routine,
    required this.schedule,
  });

  final dynamic routine;
  final SupabaseRoutineSchedule schedule;
}

class _RoutinePickerSheet extends StatelessWidget {
  const _RoutinePickerSheet({required this.routines});

  final List<dynamic> routines;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '루틴 선택',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: mainButtonColor,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const CreateRoutineScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add_circle_outline, size: 20),
                  label: const Text('새 루틴 만들기'),
                  style: TextButton.styleFrom(
                    foregroundColor: mainButtonColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (routines.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.fitness_center,
                      size: 64,
                      color: subTextColor,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '등록된 루틴이 없습니다.',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: subTextColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '새로운 루틴을 만들어 시작해보세요!',
                      style: TextStyle(
                        fontSize: 14,
                        color: subTextColor,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const CreateRoutineScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text('루틴 만들기'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: mainButtonColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              SizedBox(
                height: 360,
                child: ListView.separated(
                  itemCount: routines.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final routine = routines[index];
                    return ListTile(
                      title: Text(routine.title ?? '루틴'),
                      subtitle: routine.description != null
                          ? Text(
                              routine.description,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            )
                          : null,
                      onTap: () => Navigator.of(context).pop(routine),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RoutineScheduleSheet extends StatefulWidget {
  const _RoutineScheduleSheet({
    required this.routineTitle,
    required this.initialDays,
  });

  final String routineTitle;
  final Set<int> initialDays;

  @override
  State<_RoutineScheduleSheet> createState() => _RoutineScheduleSheetState();
}

class _RoutineScheduleSheetState extends State<_RoutineScheduleSheet> {
  late Set<int> _selectedDays;

  @override
  void initState() {
    super.initState();
    _selectedDays = {...widget.initialDays};
  }

  void _toggleDay(int day) {
    setState(() {
      if (_selectedDays.contains(day)) {
        _selectedDays.remove(day);
      } else {
        _selectedDays.add(day);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${widget.routineTitle} 요일 설정',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: mainButtonColor,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(_weekdayLabels.length, (index) {
                final selected = _selectedDays.contains(index);
                return FilterChip(
                  label: Text(_weekdayLabels[index]),
                  selected: selected,
                  onSelected: (_) => _toggleDay(index),
                  selectedColor: mainButtonColor.withOpacity(0.15),
                  checkmarkColor: mainButtonColor,
                );
              }),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                TextButton(
                  onPressed: () => setState(() => _selectedDays.clear()),
                  child: const Text('초기화'),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('취소'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(_selectedDays),
                  child: const Text('저장'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// 루틴 목록 탭 (전체 루틴 보기/삭제/요일 관리)
class _RoutineListTab extends ConsumerWidget {
  const _RoutineListTab({
    required this.routines,
    required this.entries,
    required this.onRefresh,
    required this.onAddRoutine,
    required this.onRemoveSchedule,
  });

  final List<dynamic> routines;
  final Map<int, List<_ScheduledRoutineEntry>> entries;
  final VoidCallback onRefresh;
  final Future<bool> Function(int routineId, int weekday) onAddRoutine;
  final Future<bool> Function(int scheduleId) onRemoveSchedule;

  List<int> _getWeekdaysForRoutine(int routineId) {
    final weekdays = <int>[];
    entries.forEach((weekday, entriesList) {
      for (final entry in entriesList) {
        if (entry.routine.routineId == routineId) {
          weekdays.add(weekday);
        }
      }
    });
    weekdays.sort();
    return weekdays;
  }

  Future<void> _deleteRoutine(BuildContext context, WidgetRef ref, dynamic routine) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('루틴 삭제'),
        content: Text('${routine.title} 루틴을 삭제하시겠습니까?\n\n관련된 요일 스케줄도 모두 삭제됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final success = await ref
        .read(supabaseRoutineNotifierProvider.notifier)
        .deleteRoutine(routine.routineId);

    if (!context.mounted) return;

    if (success) {
      onRefresh();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${routine.title} 루틴이 삭제되었습니다.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('루틴 삭제에 실패했습니다.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _manageWeekdays(BuildContext context, WidgetRef ref, dynamic routine) async {
    final routineId = routine.routineId as int;
    final currentWeekdays = _getWeekdaysForRoutine(routineId);

    final selectedDays = await showModalBottomSheet<Set<int>>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _RoutineScheduleSheet(
        routineTitle: routine.title as String,
        initialDays: currentWeekdays.toSet(),
      ),
    );

    if (selectedDays == null) return;

    try {
      await ref
          .read(supabaseWorkoutServiceProvider)
          .saveRoutineSchedule(routineId: routineId, weekdays: selectedDays);

      onRefresh();
      ref.invalidate(routineSchedulesProvider);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${routine.title} 요일 설정을 저장했습니다.')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('요일 설정 저장에 실패했습니다: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (routines.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.fitness_center, size: 64, color: subTextColor),
            const SizedBox(height: 16),
            const Text(
              '등록된 루틴이 없습니다.',
              style: TextStyle(fontSize: 16, color: subTextColor),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const CreateRoutineScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('루틴 만들기'),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 20),
      itemCount: routines.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final routine = routines[index];
        final routineId = routine.routineId as int?;
        if (routineId == null) return const SizedBox.shrink();

        final weekdays = _getWeekdaysForRoutine(routineId);

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            routine.title ?? '루틴',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: mainButtonColor,
                            ),
                          ),
                          if (routine.description != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              routine.description,
                              style: const TextStyle(
                                fontSize: 13,
                                color: subTextColor,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: () {
                        Navigator.of(context).pop();
                        context.push('/app/workout/create-routine', extra: {
                          'editingSupabaseRoutine': routine,
                        });
                      },
                      tooltip: '편집',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                      onPressed: () => _deleteRoutine(context, ref, routine),
                      tooltip: '삭제',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (weekdays.isNotEmpty)
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: weekdays.map((weekday) {
                      return Chip(
                        label: Text(_weekdayLabels[weekday]),
                        labelStyle: const TextStyle(fontSize: 12),
                        backgroundColor: mainButtonColor.withOpacity(0.1),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () async {
                          // 해당 요일의 스케줄 찾아서 삭제
                          final entryList = entries[weekday] ?? [];
                          final targetEntry = entryList.firstWhere(
                            (e) => e.routine.routineId == routineId,
                            orElse: () => _ScheduledRoutineEntry(
                              routine: routine,
                              schedule: SupabaseRoutineSchedule(
                                userId: '',
                                routineId: routineId,
                                weekday: weekday,
                              ),
                            ),
                          );

                          final scheduleId = targetEntry.schedule.scheduleId;
                          if (scheduleId != null) {
                            final success = await onRemoveSchedule(scheduleId);
                            if (success) {
                              onRefresh();
                            }
                          }
                        },
                      );
                    }).toList(),
                  )
                else
                  const Text(
                    '요일이 설정되지 않았습니다.',
                    style: TextStyle(fontSize: 12, color: subTextColor, fontStyle: FontStyle.italic),
                  ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _manageWeekdays(context, ref, routine),
                    icon: const Icon(Icons.calendar_month, size: 18),
                    label: const Text('요일 설정'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// 요일별 스케줄 탭 (기존 UI)
class _WeeklyScheduleTab extends StatefulWidget {
  const _WeeklyScheduleTab({
    required this.routines,
    required this.entries,
    required this.onAddRoutine,
    required this.onRemoveEntry,
  });

  final List<dynamic> routines;
  final Map<int, List<_ScheduledRoutineEntry>> entries;
  final Future<bool> Function(int routineId, int weekday) onAddRoutine;
  final Future<void> Function(_ScheduledRoutineEntry) onRemoveEntry;

  @override
  State<_WeeklyScheduleTab> createState() => _WeeklyScheduleTabState();
}

class _WeeklyScheduleTabState extends State<_WeeklyScheduleTab> {
  int? _selectedRoutineId;
  int? _selectedWeekday;
  bool _isSaving = false;

  Future<void> _submit() async {
    if (_selectedRoutineId == null || _selectedWeekday == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('루틴과 요일을 모두 선택해주세요.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final success = await widget.onAddRoutine(
      _selectedRoutineId!,
      _selectedWeekday!,
    );

    setState(() {
      _isSaving = false;
    });

    if (success) {
      final label = _weekdayLabels[_selectedWeekday!];
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$label 요일에 루틴이 추가되었습니다.'),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('루틴을 추가하지 못했습니다. 다시 시도해주세요.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final validRoutines = widget.routines
        .where((routine) => routine.routineId != null)
        .toList();

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<int>(
                value: _selectedRoutineId,
                decoration: const InputDecoration(
                  labelText: '루틴 선택',
                ),
                items: validRoutines.map((routine) {
                  return DropdownMenuItem<int>(
                    value: routine.routineId as int,
                    child: Text(routine.title ?? '루틴'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedRoutineId = value;
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<int>(
                value: _selectedWeekday,
                decoration: const InputDecoration(
                  labelText: '요일 선택',
                ),
                items: List.generate(
                  _weekdayLabels.length,
                  (index) => DropdownMenuItem<int>(
                    value: index,
                    child: Text(_weekdayLabels[index]),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _selectedWeekday = value;
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isSaving ? null : _submit,
            icon: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add),
            label: Text(_isSaving ? '추가 중...' : '선택한 요일에 루틴 추가'),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            itemCount: _weekdayLabels.length,
            itemBuilder: (context, weekday) {
              final entriesList = widget.entries[weekday] ?? const [];
              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _weekdayLabels[weekday],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: mainButtonColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (entriesList.isEmpty)
                      const Text(
                        '등록된 루틴이 없습니다.',
                        style: TextStyle(color: subTextColor),
                      )
                    else
                      Column(
                        children: entriesList.map((entry) {
                          final routine = entry.routine;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text(routine.title ?? '루틴'),
                              subtitle: routine.description != null
                                  ? Text(
                                      routine.description,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    )
                                  : null,
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                ),
                                onPressed: () => widget.onRemoveEntry(entry),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ManualCompletionSheet extends ConsumerStatefulWidget {
  const _ManualCompletionSheet({
    required this.routineId,
    required this.routineTitle,
  });

  final int routineId;
  final String routineTitle;

  @override
  ConsumerState<_ManualCompletionSheet> createState() =>
      _ManualCompletionSheetState();
}

class _ManualCompletionSheetState
    extends ConsumerState<_ManualCompletionSheet> {
  final TextEditingController _durationController =
      TextEditingController(text: '30');
  final TextEditingController _calorieController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  double _intensity = 5;
  bool _isSaving = false;

  @override
  void dispose() {
    _durationController.dispose();
    _calorieController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit(BuildContext context) async {
    final duration = int.tryParse(_durationController.text.trim()) ?? 0;
    if (duration <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('운동 시간(분)을 올바르게 입력해주세요.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final calories = int.tryParse(_calorieController.text.trim());
    final notes = _noteController.text.trim();
    final success = await ref.read(supabaseWorkoutServiceProvider).logManualCompletion(
          routineId: widget.routineId,
          durationMinutes: duration,
          totalCalories: calories,
          notes: notes.isEmpty ? null : notes,
          perceivedIntensity: _intensity.round(),
        );

    if (!mounted) return;

    setState(() {
      _isSaving = false;
    });

    if (success) {
      ref.invalidate(recordsHistoryProvider);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${widget.routineTitle} 완료 기록을 저장했어요.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('운동 기록 저장에 실패했습니다. 다시 시도해주세요.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${widget.routineTitle} 수동 완료',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: mainButtonColor,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _durationController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '운동 시간 (분)',
                hintText: '예: 30',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _calorieController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '소모 칼로리 (선택)',
                hintText: '예: 200',
              ),
            ),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      '인지 강도 (RPE)',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: mainButtonColor,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.help_outline, size: 18, color: mainButtonColor),
                      onPressed: () => _showRPEHelpDialog(context),
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(),
                      tooltip: 'RPE란?',
                    ),
                  ],
                ),
                Slider(
                  value: _intensity,
                  min: 1,
                  max: 10,
                  divisions: 9,
                  label: _intensity.round().toString(),
                  onChanged: (value) {
                    setState(() {
                      _intensity = value;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: '메모 (선택)',
                hintText: '오늘 운동 소감 또는 메모를 남겨보세요.',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _isSaving ? null : () => _submit(context),
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_circle_outline),
              label: Text(_isSaving ? '저장 중...' : '운동 완료로 기록'),
            ),
          ],
        ),
      ),
    );
  }
}

// 빠른 완료 선택 모달 (전체/일부)
class _QuickCompleteSheet extends StatelessWidget {
  const _QuickCompleteSheet({
    required this.routine,
  });

  final dynamic routine;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${routine.title} 완료하기',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: mainButtonColor,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              '어떻게 완료 처리하시겠습니까?',
              style: TextStyle(color: subTextColor),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (context) => Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom,
                    ),
                    child: _ManualCompletionSheet(
                      routineId: routine.routineId,
                      routineTitle: routine.title,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.done_all),
              label: const Text('전체 루틴 완료'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (context) => _PartialCompleteSheet(routine: routine),
                );
              },
              icon: const Icon(Icons.checklist),
              label: const Text('일부 운동만 선택'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                foregroundColor: mainButtonColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 일부 운동 선택 및 완료 처리 모달
class _PartialCompleteSheet extends ConsumerStatefulWidget {
  const _PartialCompleteSheet({required this.routine});

  final dynamic routine;

  @override
  ConsumerState<_PartialCompleteSheet> createState() =>
      _PartialCompleteSheetState();
}

class _PartialCompleteSheetState extends ConsumerState<_PartialCompleteSheet> {
  final Map<int, bool> _selectedExercises = {};
  final Map<int, Map<String, int>> _exerciseData = {};
  final TextEditingController _durationController = TextEditingController(text: '30');
  final TextEditingController _calorieController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  double _intensity = 5;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final routineExercises = widget.routine.routineExercises as List?;
    if (routineExercises != null) {
      for (int i = 0; i < routineExercises.length; i++) {
        final routineExercise = routineExercises[i];
        if (routineExercise != null) {
          _selectedExercises[i] = false;
          _exerciseData[i] = {
            'sets': routineExercise['sets'] ?? 3,
            'reps': routineExercise['reps'] ?? 10,
            'exercise_id': routineExercise['exercise_id'] ?? 0,
          };
        }
      }
    }
  }

  @override
  void dispose() {
    _durationController.dispose();
    _calorieController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final selectedCount = _selectedExercises.values.where((v) => v).length;
    if (selectedCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('최소 1개 이상의 운동을 선택해주세요.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final duration = int.tryParse(_durationController.text.trim()) ?? 0;
    if (duration <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('운동 시간(분)을 올바르게 입력해주세요.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final calories = int.tryParse(_calorieController.text.trim());
    final notes = _noteController.text.trim();

    // 선택된 운동 정보를 메모에 추가
    final selectedExerciseNames = <String>[];
    final routineExercises = widget.routine.routineExercises as List?;
    if (routineExercises != null) {
      _selectedExercises.forEach((index, selected) {
        if (selected && index < routineExercises.length) {
          final routineEx = routineExercises[index];
          if (routineEx != null && routineEx['exercise'] != null) {
            final exerciseName = routineEx['exercise']['name'] ?? '운동';
            final data = _exerciseData[index] ?? {};
            selectedExerciseNames.add(
              '$exerciseName (${data['sets']}세트 × ${data['reps']}회)',
            );
          }
        }
      });
    }

    final detailedNotes = [
      '일부 운동 완료:',
      ...selectedExerciseNames,
      if (notes.isNotEmpty) '\n메모: $notes',
    ].join('\n');

    final success = await ref.read(supabaseWorkoutServiceProvider).logManualCompletion(
          routineId: widget.routine.routineId,
          durationMinutes: duration,
          totalCalories: calories,
          notes: detailedNotes,
          perceivedIntensity: _intensity.round(),
        );

    if (!mounted) return;

    setState(() {
      _isSaving = false;
    });

    if (success) {
      ref.invalidate(recordsHistoryProvider);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.routine.title} 일부 완료 기록을 저장했어요.'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('운동 기록 저장에 실패했습니다. 다시 시도해주세요.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final routineExercises = widget.routine.routineExercises as List?;

    return SafeArea(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${widget.routine.title}\n운동 선택',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: mainButtonColor,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              '완료한 운동을 선택하세요',
              style: TextStyle(color: subTextColor),
            ),
            const SizedBox(height: 16),
            if (routineExercises == null || routineExercises.isEmpty)
              const Expanded(
                child: Center(
                  child: Text(
                    '이 루틴에는 운동이 없습니다.',
                    style: TextStyle(color: subTextColor),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: routineExercises.length,
                  itemBuilder: (context, index) {
                    final routineEx = routineExercises[index];
                    if (routineEx == null) return const SizedBox.shrink();

                    final exercise = routineEx['exercise'];
                    if (exercise == null) return const SizedBox.shrink();

                    final exerciseName = exercise['name'] ?? '운동 $index';
                    final data = _exerciseData[index] ?? {};
                    final sets = data['sets'] ?? 3;
                    final reps = data['reps'] ?? 10;
                    final isSelected = _selectedExercises[index] ?? false;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: CheckboxListTile(
                        value: isSelected,
                        onChanged: (value) {
                          setState(() {
                            _selectedExercises[index] = value ?? false;
                          });
                        },
                        title: Text(
                          exerciseName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '$sets세트 × $reps회',
                          style: const TextStyle(color: subTextColor),
                        ),
                        activeColor: mainButtonColor,
                      ),
                    );
                  },
                ),
              ),
            const Divider(height: 32),
            TextField(
              controller: _durationController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '총 운동 시간 (분)',
                hintText: '예: 30',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _calorieController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '소모 칼로리 (선택)',
                hintText: '예: 200',
              ),
            ),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      '인지 강도 (RPE)',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: mainButtonColor,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.help_outline, size: 18, color: mainButtonColor),
                      onPressed: () => _showRPEHelpDialog(context),
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(),
                      tooltip: 'RPE란?',
                    ),
                  ],
                ),
                Slider(
                  value: _intensity,
                  min: 1,
                  max: 10,
                  divisions: 9,
                  label: _intensity.round().toString(),
                  onChanged: (value) {
                    setState(() {
                      _intensity = value;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: '메모 (선택)',
                hintText: '오늘 운동 소감을 남겨보세요.',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _isSaving ? null : _submit,
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_circle_outline),
              label: Text(_isSaving ? '저장 중...' : '선택한 운동 완료로 기록'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// RPE 도움말 다이얼로그
void _showRPEHelpDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.info_outline, color: mainButtonColor),
          SizedBox(width: 8),
          Text('인지 강도 (RPE)란?'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'RPE (Rating of Perceived Exertion)는 운동 중 느낀 주관적인 강도를 1~10점으로 평가하는 척도입니다.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            _buildRPEItem('1-2', '매우 가벼움', '대화하기 아주 쉬움'),
            _buildRPEItem('3-4', '가벼움', '대화하기 쉬움'),
            _buildRPEItem('5-6', '보통', '대화 가능하지만 약간 숨참'),
            _buildRPEItem('7-8', '힘듦', '대화하기 어려움'),
            _buildRPEItem('9-10', '매우 힘듦', '거의 최대 강도, 대화 불가'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('확인'),
        ),
      ],
    ),
  );
}

Widget _buildRPEItem(String level, String name, String description) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: mainButtonColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            level,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: mainButtonColor,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 12,
                  color: subTextColor,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
