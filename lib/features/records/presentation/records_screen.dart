import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

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

  static const _workoutColor = Color(0xFF4CAF50);
  static const _dietColor = Color(0xFFFF7043);

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

  static const _workoutColor = Color(0xFF4CAF50);
  static const _dietColor = Color(0xFFFF7043);

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
          selectedColor: Colors.green.shade100,
          checkmarkColor: mainButtonColor,
        ),
        FilterChip(
          selected: showDiet,
          label: const Text('식단'),
          onSelected: onToggleDiet,
          selectedColor: Colors.orange.shade100,
          checkmarkColor: mainButtonColor,
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
                child: _SummaryStat(
                  label: '식단',
                  value: diets > 0 ? '${diets}끼 · ${dietCalories}kcal' : '기록 없음',
                  icon: Icons.restaurant,
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
        subtitle: Text(
          entry.description,
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
