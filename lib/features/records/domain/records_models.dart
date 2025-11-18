enum RecordEventType { workout, diet }

DateTime truncateToDate(DateTime date) =>
    DateTime(date.year, date.month, date.day);

class DailyRecord {
  const DailyRecord({
    required this.date,
    this.workouts = const [],
    this.diets = const [],
  });

  final DateTime date;
  final List<WorkoutRecordEntry> workouts;
  final List<DietRecordEntry> diets;

  bool get hasWorkout => workouts.isNotEmpty;
  bool get hasDiet => diets.isNotEmpty;
  bool get isEmpty => !hasWorkout && !hasDiet;

  List<RecordEventType> get eventTypes {
    final events = <RecordEventType>[];
    if (hasWorkout) {
      events.add(RecordEventType.workout);
    }
    if (hasDiet) {
      events.add(RecordEventType.diet);
    }
    return events;
  }

  int get totalWorkoutMinutes {
    return workouts.fold(
      0,
      (sum, item) => sum + (item.duration?.inMinutes ?? 0),
    );
  }

  int get totalDietCalories {
    return diets.fold(0, (sum, item) => sum + item.calories);
  }

  int get totalCarbs {
    return diets.fold(0, (sum, item) => sum + item.carbs);
  }

  int get totalProtein {
    return diets.fold(0, (sum, item) => sum + item.protein);
  }

  int get totalFat {
    return diets.fold(0, (sum, item) => sum + item.fat);
  }

  DailyRecord merge(DailyRecord other) {
    assert(truncateToDate(date) == truncateToDate(other.date));
    return DailyRecord(
      date: truncateToDate(date),
      workouts: [...workouts, ...other.workouts],
      diets: [...diets, ...other.diets],
    );
  }
}

class WorkoutRecordEntry {
  const WorkoutRecordEntry({
    required this.title,
    this.sessionId,
    this.duration,
    this.calories = 0,
    this.startedAt,
    this.completionMethod,
    this.manualNotes,
    this.perceivedIntensity,
    this.isUserReported,
  });

  final int? sessionId;
  final String title;
  final Duration? duration;
  final int calories;
  final DateTime? startedAt;
  final String? completionMethod;  // 'app' or 'manual'
  final String? manualNotes;       // 메모
  final int? perceivedIntensity;   // RPE 1-10
  final bool? isUserReported;      // 사용자 직접 입력 여부
}

class DietRecordEntry {
  const DietRecordEntry({
    required this.mealLabel,
    required this.description,
    this.calories = 0,
    this.carbs = 0,      // 탄수화물 (g)
    this.protein = 0,    // 단백질 (g)
    this.fat = 0,        // 지방 (g)
  });

  final String mealLabel;
  final String description;
  final int calories;
  final int carbs;     // 탄수화물 (g)
  final int protein;   // 단백질 (g)
  final int fat;       // 지방 (g)
}

class RecordsHistory {
  RecordsHistory({Map<DateTime, DailyRecord>? records})
      : _records = records ?? <DateTime, DailyRecord>{};

  final Map<DateTime, DailyRecord> _records;

  Map<DateTime, DailyRecord> get records => _records;

  DailyRecord? recordFor(DateTime date) => _records[truncateToDate(date)];

  Iterable<DateTime> get availableDays => _records.keys;

  void upsertRecord(DailyRecord record) {
    final key = truncateToDate(record.date);
    if (_records.containsKey(key)) {
      _records[key] = _records[key]!.merge(record);
    } else {
      _records[key] = record;
    }
  }

  bool get isEmpty => _records.isEmpty;
}
