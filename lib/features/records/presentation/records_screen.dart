import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_application_1/color.dart';
import '../application/records_providers.dart';
import '../domain/records_models.dart';

class RecordsScreen extends ConsumerStatefulWidget {
  const RecordsScreen({super.key});

  @override
  ConsumerState<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends ConsumerState<RecordsScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = truncateToDate(DateTime.now());
  bool _showWorkout = true;
  bool _showDiet = true;

  @override
  Widget build(BuildContext context) {
    final recordsAsync = ref.watch(recordsHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('기록'),
        backgroundColor: backgroundColor,
        foregroundColor: mainButtonColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: '통계 보기',
            onPressed: () => context.push('/app/records/statistics'),
          ),
        ],
      ),
      body: SafeArea(
        child: recordsAsync.when(
          data: (history) => RefreshIndicator(
            onRefresh: () async {
              await ref.refresh(recordsHistoryProvider.future);
            },
            child: _RecordsBody(
              history: history,
              focusedDay: _focusedDay,
              selectedDay: _selectedDay,
              showWorkout: _showWorkout,
              showDiet: _showDiet,
              onDaySelected: (selected, focused) {
                setState(() {
                  _selectedDay = truncateToDate(selected);
                  _focusedDay = focused;
                });
              },
              onToggleWorkout: (value) {
                setState(() => _showWorkout = value);
              },
              onToggleDiet: (value) {
                setState(() => _showDiet = value);
              },
            ),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _RecordsError(
            message: error.toString(),
            onRetry: () => ref.invalidate(recordsHistoryProvider),
          ),
        ),
      ),
    );
  }
}

class _RecordsBody extends StatelessWidget {
  const _RecordsBody({
    required this.history,
    required this.focusedDay,
    required this.selectedDay,
    required this.showWorkout,
    required this.showDiet,
    required this.onDaySelected,
    required this.onToggleWorkout,
    required this.onToggleDiet,
  });

  final RecordsHistory history;
  final DateTime focusedDay;
  final DateTime selectedDay;
  final bool showWorkout;
  final bool showDiet;
  final void Function(DateTime selectedDay, DateTime focusedDay) onDaySelected;
  final ValueChanged<bool> onToggleWorkout;
  final ValueChanged<bool> onToggleDiet;

  static const _workoutColor = mainButtonColor;
  static const _dietColor = mainButtonColor;

  @override
  Widget build(BuildContext context) {
    final selectedRecord = history.recordFor(selectedDay);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _CalendarSection(
          history: history,
          focusedDay: focusedDay,
          selectedDay: selectedDay,
          showWorkout: showWorkout,
          showDiet: showDiet,
          onDaySelected: onDaySelected,
        ),
        const SizedBox(height: 16),
        _FilterChips(
          showWorkout: showWorkout,
          showDiet: showDiet,
          onToggleWorkout: onToggleWorkout,
          onToggleDiet: onToggleDiet,
        ),
        const SizedBox(height: 16),
        _SummaryCard(
          record: selectedRecord,
          day: selectedDay,
          showWorkout: showWorkout,
          showDiet: showDiet,
        ),
        const SizedBox(height: 16),
        if (showWorkout)
          _RecordSection(
            title: '운동 기록',
            emptyText: '선택한 날짜의 운동 기록이 없습니다.',
            children: selectedRecord?.workouts
                    .map(
                      (entry) => _WorkoutTile(
                        entry: entry,
                        color: _workoutColor,
                      ),
                    )
                    .toList() ??
                const [],
          ),
        if (showWorkout) const SizedBox(height: 12),
        if (showDiet)
          _RecordSection(
            title: '식단 기록',
            emptyText: '선택한 날짜의 식단 기록이 없습니다.',
            children: selectedRecord?.diets
                    .map(
                      (entry) => _DietTile(
                        entry: entry,
                        color: _dietColor,
                      ),
                    )
                    .toList() ??
                const [],
          ),
      ],
    );
  }
}

class _CalendarSection extends StatelessWidget {
  const _CalendarSection({
    required this.history,
    required this.focusedDay,
    required this.selectedDay,
    required this.showWorkout,
    required this.showDiet,
    required this.onDaySelected,
  });

  final RecordsHistory history;
  final DateTime focusedDay;
  final DateTime selectedDay;
  final bool showWorkout;
  final bool showDiet;
  final void Function(DateTime selectedDay, DateTime focusedDay) onDaySelected;

  static const _workoutColor = mainButtonColor;
  static const _dietColor = mainButtonColor;

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime.now().subtract(const Duration(days: 180));
    final lastDay = DateTime.now().add(const Duration(days: 30));

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: borderColor),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: TableCalendar<RecordEventType>(
          firstDay: firstDay,
          lastDay: lastDay,
          focusedDay: focusedDay,
          selectedDayPredicate: (day) => isSameDay(day, selectedDay),
          calendarFormat: CalendarFormat.month,
          startingDayOfWeek: StartingDayOfWeek.monday,
          headerStyle: const HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
          ),
          eventLoader: (day) {
            final record = history.recordFor(day);
            if (record == null) return const [];
            final events = <RecordEventType>[];
            if (showWorkout && record.hasWorkout) {
              events.add(RecordEventType.workout);
            }
            if (showDiet && record.hasDiet) {
              events.add(RecordEventType.diet);
            }
            return events;
          },
          calendarBuilders: CalendarBuilders<RecordEventType>(
            markerBuilder: (context, day, events) {
              if (events.isEmpty) return null;
              return Align(
                alignment: Alignment.bottomCenter,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: events
                      .take(3)
                      .map(
                        (event) => Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: event == RecordEventType.workout
                                ? _workoutColor
                                : _dietColor,
                          ),
                        ),
                      )
                      .toList(),
                ),
              );
            },
            todayBuilder: (context, day, focusedDay) => _buildDay(
              context,
              day,
              isToday: true,
              isSelected: isSameDay(day, selectedDay),
            ),
            selectedBuilder: (context, day, focusedDay) => _buildDay(
              context,
              day,
              isSelected: true,
            ),
          ),
          onDaySelected: onDaySelected,
        ),
      ),
    );
  }

  Widget _buildDay(
    BuildContext context,
    DateTime day, {
    bool isToday = false,
    bool isSelected = false,
  }) {
    final baseStyle = Theme.of(context).textTheme.bodyMedium!;
    final color = isSelected
        ? Colors.white
        : isToday
            ? mainButtonColor
            : baseStyle.color;
    return Container(
      margin: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: isSelected ? mainButtonColor : null,
        borderRadius: BorderRadius.circular(12),
        border: isToday && !isSelected
            ? Border.all(color: mainButtonColor, width: 1)
            : null,
      ),
      alignment: Alignment.center,
      child: Text(
        '${day.day}',
        style: baseStyle.copyWith(
          color: color,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        ),
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({
    required this.showWorkout,
    required this.showDiet,
    required this.onToggleWorkout,
    required this.onToggleDiet,
  });

  final bool showWorkout;
  final bool showDiet;
  final ValueChanged<bool> onToggleWorkout;
  final ValueChanged<bool> onToggleDiet;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      children: [
        FilterChip(
          selected: showWorkout,
          label: const Text('운동'),
          onSelected: onToggleWorkout,
          selectedColor: Colors.grey.shade200,
          checkmarkColor: mainButtonColor,
          labelStyle: const TextStyle(color: mainButtonColor),
          backgroundColor: Colors.white,
        ),
        FilterChip(
          selected: showDiet,
          label: const Text('식단'),
          onSelected: onToggleDiet,
          selectedColor: Colors.grey.shade200,
          checkmarkColor: mainButtonColor,
          labelStyle: const TextStyle(color: mainButtonColor),
          backgroundColor: Colors.white,
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.record,
    required this.day,
    required this.showWorkout,
    required this.showDiet,
  });

  final DailyRecord? record;
  final DateTime day;
  final bool showWorkout;
  final bool showDiet;

  @override
  Widget build(BuildContext context) {
    final workouts = showWorkout ? (record?.workouts.length ?? 0) : 0;
    final workoutMinutes = showWorkout ? (record?.totalWorkoutMinutes ?? 0) : 0;
    final diets = showDiet ? (record?.diets.length ?? 0) : 0;
    final dietCalories = showDiet ? (record?.totalDietCalories ?? 0) : 0;
    final carbs = showDiet ? (record?.totalCarbs ?? 0) : 0;
    final protein = showDiet ? (record?.totalProtein ?? 0) : 0;
    final fat = showDiet ? (record?.totalFat ?? 0) : 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: backgroundColor,
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _formatDate(day),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: mainButtonColor,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _SummaryStat(
                  label: '운동',
                  value: workouts > 0
                      ? '$workoutMinutes분 / ${workouts}회'
                      : '기록 없음',
                  icon: Icons.fitness_center,
                ),
              ),
              Expanded(
                child: _DietSummaryStat(
                  diets: diets,
                  calories: dietCalories,
                  carbs: carbs,
                  protein: protein,
                  fat: fat,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const weekDays = ['월', '화', '수', '목', '금', '토', '일'];
    final label = weekDays[date.weekday - 1];
    return '${date.month}월 ${date.day}일 ($label)';
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: subTextColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: subTextColor),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: mainButtonColor,
          ),
        ),
      ],
    );
  }
}

class _DietSummaryStat extends StatelessWidget {
  const _DietSummaryStat({
    required this.diets,
    required this.calories,
    required this.carbs,
    required this.protein,
    required this.fat,
  });

  final int diets;
  final int calories;
  final int carbs;
  final int protein;
  final int fat;

  @override
  Widget build(BuildContext context) {
    final hasMacros = carbs > 0 || protein > 0 || fat > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.restaurant, size: 16, color: subTextColor),
            const SizedBox(width: 4),
            const Text(
              '식단',
              style: TextStyle(fontSize: 12, color: subTextColor),
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (diets > 0) ...[
          Text(
            '$diets끼 · ${calories}kcal',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: mainButtonColor,
            ),
          ),
          if (hasMacros) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                _MacroChip(label: '탄', value: carbs, color: Colors.orange),
                _MacroChip(label: '단', value: protein, color: Colors.red),
                _MacroChip(label: '지', value: fat, color: Colors.blue),
              ],
            ),
          ],
        ] else
          const Text(
            '기록 없음',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: mainButtonColor,
            ),
          ),
      ],
    );
  }
}

class _MacroChip extends StatelessWidget {
  const _MacroChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3), width: 0.5),
      ),
      child: Text(
        '$label ${value}g',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _RecordSection extends StatelessWidget {
  const _RecordSection({
    required this.title,
    required this.emptyText,
    required this.children,
  });

  final String title;
  final String emptyText;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final hasContent = children.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: mainButtonColor,
          ),
        ),
        const SizedBox(height: 8),
        if (hasContent)
          ...children
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: Text(
              emptyText,
              style: const TextStyle(color: subTextColor),
            ),
          ),
      ],
    );
  }
}

class _WorkoutTile extends StatelessWidget {
  const _WorkoutTile({
    required this.entry,
    required this.color,
  });

  final WorkoutRecordEntry entry;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final durationText = entry.duration != null
        ? _formatDuration(entry.duration!)
        : '시간 정보 없음';
    final timeText = entry.startedAt != null
        ? '${entry.startedAt!.hour.toString().padLeft(2, '0')}:${entry.startedAt!.minute.toString().padLeft(2, '0')}'
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withOpacity(0.2)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showWorkoutDetailModal(context, entry),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: color.withOpacity(0.15),
            child: Icon(Icons.fitness_center, color: color),
          ),
          title: Text(
            entry.title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: mainButtonColor,
            ),
          ),
          subtitle: Text(
            timeText != null ? '$timeText · $durationText' : durationText,
            style: const TextStyle(color: subTextColor),
          ),
          trailing: entry.calories > 0
              ? Text(
                  '${entry.calories} kcal',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                )
              : null,
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours > 0) {
      return '${hours}시간 ${minutes}분';
    }
    return '${duration.inMinutes}분';
  }

  void _showWorkoutDetailModal(BuildContext context, WorkoutRecordEntry entry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _WorkoutDetailModal(entry: entry),
    );
  }
}

class _DietTile extends StatelessWidget {
  const _DietTile({
    required this.entry,
    required this.color,
  });

  final DietRecordEntry entry;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final hasMacros = entry.carbs > 0 || entry.protein > 0 || entry.fat > 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withOpacity(0.2)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          child: Icon(Icons.restaurant, color: color),
        ),
        title: Text(
          entry.mealLabel,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: mainButtonColor,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              entry.description,
              style: const TextStyle(color: subTextColor),
            ),
            if (hasMacros) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  _MacroChip(label: '탄', value: entry.carbs, color: Colors.orange),
                  _MacroChip(label: '단', value: entry.protein, color: Colors.red),
                  _MacroChip(label: '지', value: entry.fat, color: Colors.blue),
                ],
              ),
            ],
          ],
        ),
        trailing: entry.calories > 0
            ? Text(
                '${entry.calories} kcal',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              )
            : null,
      ),
    );
  }
}

class _WorkoutDetailModal extends StatelessWidget {
  const _WorkoutDetailModal({required this.entry});

  final WorkoutRecordEntry entry;

  @override
  Widget build(BuildContext context) {
    final durationText = entry.duration != null
        ? _formatDuration(entry.duration!)
        : '시간 정보 없음';
    final timeText = entry.startedAt != null
        ? '${entry.startedAt!.year}년 ${entry.startedAt!.month}월 ${entry.startedAt!.day}일 ${entry.startedAt!.hour.toString().padLeft(2, '0')}:${entry.startedAt!.minute.toString().padLeft(2, '0')}'
        : '시간 정보 없음';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        top: 16,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 드래그 핸들
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // 제목
            Row(
              children: [
                const Icon(
                  Icons.fitness_center,
                  color: mainButtonColor,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    entry.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: mainButtonColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // 시작 시간
            _DetailRow(
              icon: Icons.access_time,
              label: '시작 시간',
              value: timeText,
            ),
            const SizedBox(height: 16),
            // 운동 시간
            _DetailRow(
              icon: Icons.timer,
              label: '운동 시간',
              value: durationText,
            ),
            const SizedBox(height: 16),
            // 소모 칼로리
            _DetailRow(
              icon: Icons.local_fire_department,
              label: '소모 칼로리',
              value: entry.calories > 0 ? '${entry.calories} kcal' : '기록 없음',
            ),
            if (entry.completionMethod != null) ...[
              const SizedBox(height: 16),
              _DetailRow(
                icon: entry.completionMethod == 'manual'
                    ? Icons.edit_note
                    : Icons.phone_android,
                label: '완료 방법',
                value: entry.completionMethod == 'manual' ? '수동 완료' : '앱으로 진행',
              ),
            ],
            if (entry.perceivedIntensity != null) ...[
              const SizedBox(height: 16),
              _DetailRow(
                icon: Icons.trending_up,
                label: '운동 강도 (RPE)',
                value: '${entry.perceivedIntensity}/10',
                valueWidget: _buildRPEIndicator(entry.perceivedIntensity!),
              ),
            ],
            if (entry.manualNotes != null && entry.manualNotes!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _DetailRow(
                icon: Icons.notes,
                label: '메모',
                value: entry.manualNotes!,
                isMultiline: true,
              ),
            ],
            const SizedBox(height: 24),
            // 닫기 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: mainButtonColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '닫기',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours > 0) {
      return '${hours}시간 ${minutes}분';
    }
    return '${duration.inMinutes}분';
  }

  Widget _buildRPEIndicator(int rpe) {
    Color color;
    String label;

    if (rpe <= 2) {
      color = Colors.green;
      label = '매우 가벼움';
    } else if (rpe <= 4) {
      color = Colors.lightGreen;
      label = '가벼움';
    } else if (rpe <= 6) {
      color = Colors.orange;
      label = '보통';
    } else if (rpe <= 8) {
      color = Colors.deepOrange;
      label = '힘듦';
    } else {
      color = Colors.red;
      label = '매우 힘듦';
    }

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueWidget,
    this.isMultiline = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final Widget? valueWidget;
  final bool isMultiline;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment:
          isMultiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Icon(icon, color: mainButtonColor, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: subTextColor,
                ),
              ),
              const SizedBox(height: 4),
              if (valueWidget != null)
                valueWidget!
              else
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: mainButtonColor,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RecordsError extends StatelessWidget {
  const _RecordsError({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
            const SizedBox(height: 12),
            Text(
              '기록을 불러오지 못했습니다.\n$message',
              textAlign: TextAlign.center,
              style: const TextStyle(color: subTextColor),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onRetry,
              child: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }
}
