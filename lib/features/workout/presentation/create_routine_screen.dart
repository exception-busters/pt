import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_application_1/color.dart';
import 'package:flutter_application_1/features/workout/application/workout_providers.dart';
import 'package:go_router/go_router.dart';

class CreateRoutineScreen extends ConsumerStatefulWidget {
  final WorkoutRoutine? editingRoutine;
  final dynamic editingSupabaseRoutine; // Supabase 루틴 모델(SupabaseWorkoutRoutine)
  final String? initialRoutineName; // AI 루틴 등록용
  final List<Exercise>? initialExercises; // AI 루틴 등록용

  const CreateRoutineScreen({
    super.key,
    this.editingRoutine,
    this.editingSupabaseRoutine,
    this.initialRoutineName,
    this.initialExercises,
  });

  @override
  ConsumerState<CreateRoutineScreen> createState() =>
      _CreateRoutineScreenState();
}

class _CreateRoutineScreenState extends ConsumerState<CreateRoutineScreen> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  List<Exercise> _selectedExercises = [];

  @override
  void initState() {
    super.initState();
    if (widget.editingRoutine != null) {
      _nameController.text = widget.editingRoutine!.name;
      _selectedExercises = List.from(widget.editingRoutine!.exercises);
    } else if (widget.editingSupabaseRoutine != null) {
      _nameController.text = widget.editingSupabaseRoutine.title;
      // Supabase 루틴의 운동 정보를 Exercise 객체로 변환
      _selectedExercises = _convertSupabaseExercisesToExercises(widget.editingSupabaseRoutine);
    } else if (widget.initialRoutineName != null && widget.initialExercises != null) {
      // AI 루틴을 수정 후 등록하는 경우
      _nameController.text = widget.initialRoutineName!;
      _selectedExercises = List.from(widget.initialExercises!);
    }
  }

  List<Exercise> _convertSupabaseExercisesToExercises(dynamic supabaseRoutine) {
    final List<Exercise> exercises = [];
    
    print('📝 Supabase 루틴 편집 모드: ${supabaseRoutine.title}');
    
    if (supabaseRoutine.routineExercises != null && supabaseRoutine.routineExercises.isNotEmpty) {
      print('🔍 운동 데이터 변환 중: ${supabaseRoutine.routineExercises.length}개');
      
      for (final routineExercise in supabaseRoutine.routineExercises) {
        if (routineExercise != null && routineExercise['exercise'] != null) {
          final exerciseData = routineExercise['exercise'];
          final sets = routineExercise['sets'] as int?;
          final reps = routineExercise['reps'] as int?;
          final restSeconds = routineExercise['rest_time_sec'] as int?;
          final estimatedDuration = reps != null && sets != null
              ? sets * reps * 4
              : ((reps ?? 10) * 5).clamp(30, 180);

          final exercise = Exercise(
            id: exerciseData['exercise_id'].toString(),
            name: exerciseData['name'] ?? '운동명 없음',
            description: exerciseData['description'] ?? '운동 설명이 없습니다.',
            duration: estimatedDuration,
            category: exerciseData['body_part'] ?? '기타',
            sets: sets,
            reps: reps,
            restSeconds: restSeconds,
          );
          exercises.add(exercise);
          print('✅ 운동 변환 완료: ${exercise.name}');
        }
      }
    } else {
      print('💡 운동 데이터가 없어 빈 리스트로 시작합니다. 운동을 다시 선택해주세요.');
    }
    
    return exercises;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String _getScreenTitle() {
    if (widget.editingRoutine != null) {
      return '루틴 수정';
    } else if (widget.editingSupabaseRoutine != null) {
      return '루틴 수정';
    } else {
      return '새 루틴 추가';
    }
  }

  String _getSaveButtonText() {
    if (widget.editingRoutine != null) {
      return '루틴 수정하기';
    } else if (widget.editingSupabaseRoutine != null) {
      return '루틴 수정하기';
    } else {
      return '루틴 저장하기';
    }
  }

  Future<void> _addExercise(Exercise exercise) async {
    // 세트/횟수 설정 다이얼로그 표시
    final result = await showDialog<Map<String, int>>(
      context: context,
      builder: (context) => _ExerciseSettingsDialog(exercise: exercise),
    );

    if (result == null) return;

    // 설정된 값으로 운동 추가
    final updatedExercise = exercise.copyWith(
      sets: result['sets'],
      reps: result['reps'],
      restSeconds: result['rest'],
      duration: (result['sets']! * result['reps']! * 4) + (result['rest']! * (result['sets']! - 1)),
    );

    setState(() {
      _selectedExercises.add(updatedExercise);
    });
  }

  void _removeExercise(int index) {
    setState(() {
      _selectedExercises.removeAt(index);
    });
  }

  void _moveExercise(int oldIndex, int newIndex) {
    setState(() {
      // 드래그 제한: 리스트 범위를 벗어나지 않도록 제한
      if (newIndex > _selectedExercises.length) {
        newIndex = _selectedExercises.length;
      }
      if (newIndex < 0) {
        newIndex = 0;
      }
      
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      
      // 실제 이동 가능한 범위 내에서만 이동
      if (newIndex >= 0 && newIndex < _selectedExercises.length) {
        final exercise = _selectedExercises.removeAt(oldIndex);
        _selectedExercises.insert(newIndex, exercise);
      }
    });
  }

  Future<void> _saveRoutine() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedExercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('최소 하나의 운동을 선택해주세요'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 로딩 표시
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      if (widget.editingRoutine != null) {
        // 기존 로컬 저장 방식 (수정 기능)
        final routine = WorkoutRoutine(
          id: widget.editingRoutine!.id,
          name: _nameController.text,
          exercises: _selectedExercises,
          createdAt: widget.editingRoutine!.createdAt,
        );

        await ref
            .read(workoutRoutineControllerProvider.notifier)
            .updateRoutine(widget.editingRoutine!.id, routine);

        // 수정 후 provider 새로고침
        ref.invalidate(workoutRoutineControllerProvider);

        if (mounted) {
          Navigator.of(context).pop(); // 로딩 다이얼로그 닫기
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('루틴이 수정되었습니다'),
              backgroundColor: mainButtonColor,
            ),
          );
        }
      } else if (widget.editingSupabaseRoutine != null) {
        // Supabase 루틴 수정
        final success = await ref.read(supabaseRoutineNotifierProvider.notifier).updateRoutine(
          widget.editingSupabaseRoutine.routineId,
          _nameController.text,
          '사용자가 수정한 운동 루틴',
          _selectedExercises,
        );

        if (mounted) {
          Navigator.of(context).pop(); // 로딩 다이얼로그 닫기
          if (success) {
            // 수정 후 provider 새로고침 (루틴 목록 & 요일별 스케줄)
            ref.invalidate(supabaseRoutineNotifierProvider);
            ref.invalidate(routineSchedulesProvider);

            // provider 업데이트를 위한 짧은 대기
            await Future.delayed(const Duration(milliseconds: 100));

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('루틴이 수정되었습니다'),
                backgroundColor: mainButtonColor,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('루틴 수정에 실패했습니다. 다시 시도해주세요.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        // 새 루틴 생성 - Supabase 데이터베이스에 저장
        final success = await ref.read(supabaseRoutineNotifierProvider.notifier).createRoutine(
          _nameController.text,
          '사용자가 생성한 운동 루틴', // 기본 설명
          _selectedExercises,
        );
        
        if (mounted) {
          Navigator.of(context).pop(); // 로딩 다이얼로그 닫기
          if (success) {
            // 성공 시 provider 새로고침 (루틴 목록 & 요일별 스케줄)
            ref.invalidate(supabaseRoutineNotifierProvider);
            ref.invalidate(routineSchedulesProvider);

            // provider 업데이트를 위한 짧은 대기
            await Future.delayed(const Duration(milliseconds: 100));

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('새 루틴이 데이터베이스에 저장되었습니다'),
                backgroundColor: mainButtonColor,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('루틴 저장에 실패했습니다. 다시 시도해주세요.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }

      if (mounted) context.pop();
      
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // 로딩 다이얼로그 닫기
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalDuration =
    _selectedExercises.fold(0, (sum, e) => sum + e.duration);
    final minutes = totalDuration ~/ 60;
    final seconds = totalDuration % 60;

    return Scaffold(
      appBar: AppBar(
        title: Text(_getScreenTitle()),
        backgroundColor: backgroundColor,
        foregroundColor: mainButtonColor,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 루틴 이름 입력
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: '루틴 이름',
                    hintText: '예: 아침 운동, 하체 집중 등',
                    prefixIcon: Icon(Icons.fitness_center),
                  ),
                  validator: (value) =>
                  value == null || value.isEmpty ? '루틴 이름을 입력해주세요' : null,
                ),
              ),
            ),

            // 총 운동 시간 표시
            if (_selectedExercises.isNotEmpty)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: mainButtonColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: mainButtonColor.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer, color: mainButtonColor),
                    const SizedBox(width: 8),
                    Text(
                      '총 운동 시간: ${minutes > 0 ? '${minutes}분 ' : ''}${seconds}초',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: mainButtonColor,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            Expanded(
              child: Row(
                children: [
                  // 왼쪽: 운동 목록
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            '운동 선택',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: mainButtonColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Consumer(
                            builder: (context, ref, child) {
                              final exercisesAsync = ref.watch(databaseExercisesProvider);
                              
                              return exercisesAsync.when(
                                loading: () => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                                error: (error, stack) => Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.error, size: 48, color: Colors.red),
                                      const SizedBox(height: 16),
                                      Text('운동 목록을 불러올 수 없습니다\n$error'),
                                      const SizedBox(height: 16),
                                      ElevatedButton(
                                        onPressed: () => ref.refresh(databaseExercisesProvider),
                                        child: const Text('다시 시도'),
                                      ),
                                    ],
                                  ),
                                ),
                                data: (exercises) => ListView.builder(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  itemCount: exercises.length,
                                  itemBuilder: (context, index) {
                                    final exercise = exercises[index];
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      decoration: BoxDecoration(
                                        color: backgroundColor,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: borderColor),
                                      ),
                                      child: Column(
                                        children: [
                                          ListTile(
                                            title: Text(
                                              exercise.name,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w500,
                                                color: mainButtonColor,
                                              ),
                                            ),
                                            subtitle: Text(
                                              '${exercise.description}\n${exercise.category}',
                                              style: const TextStyle(color: subTextColor),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 16.0, vertical: 8),
                                            child: SizedBox(
                                              width: double.infinity,
                                              child: OutlinedButton.icon(
                                                onPressed: () => _addExercise(exercise),
                                                icon: const Icon(Icons.add, size: 16),
                                                label: const Text('추가'),
                                                style: OutlinedButton.styleFrom(
                                                  side: const BorderSide(
                                                      color: mainButtonColor),
                                                  foregroundColor: mainButtonColor,
                                                  padding: const EdgeInsets.symmetric(
                                                      vertical: 8),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 구분선
                  Container(
                    width: 1,
                    color: borderColor,
                    margin: const EdgeInsets.symmetric(vertical: 16),
                  ),

                  // 오른쪽 영역: 선택된 운동 목록(순서 재배열 리스트)
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding:
                          const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              const Text(
                                '내 루틴',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: mainButtonColor,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${_selectedExercises.length}개',
                                style: const TextStyle(
                                  color: subTextColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: _selectedExercises.isEmpty
                              ? const Center(
                            child: Text(
                              '운동을 선택해주세요',
                              style: TextStyle(
                                color: subTextColor,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          )
                              : Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 16),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: borderColor.withOpacity(0.3)),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: ReorderableListView.builder(
                                      padding: const EdgeInsets.all(8),
                                      itemCount: _selectedExercises.length,
                                      onReorder: _moveExercise,
                                      buildDefaultDragHandles: false,
                                      proxyDecorator: (child, index, animation) {
                                        return Material(
                                          color: Colors.transparent,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: mainButtonColor.withOpacity(0.15),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(
                                                color: mainButtonColor.withOpacity(0.5),
                                                width: 2,
                                              ),
                                            ),
                                            child: child,
                                          ),
                                        );
                                      },
                                      itemBuilder: (context, index) {
                                        final exercise = _selectedExercises[index];
                                        return Container(
                                          key: ValueKey(exercise.id + index.toString()),
                                          margin: const EdgeInsets.only(bottom: 8),
                                          decoration: BoxDecoration(
                                            color: mainButtonColor.withOpacity(0.05),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: mainButtonColor.withOpacity(0.2)),
                                          ),
                                          child: Column(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(12),
                                                child: Row(
                                                  children: [
                                                    // 순서 번호
                                                    Container(
                                                      width: 24,
                                                      height: 24,
                                                      decoration: BoxDecoration(
                                                        color: mainButtonColor,
                                                        borderRadius: BorderRadius.circular(12),
                                                      ),
                                                      child: Center(
                                                        child: Text(
                                                          '${index + 1}',
                                                          style: const TextStyle(
                                                            fontWeight: FontWeight.bold,
                                                            color: backgroundColor,
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    
                                                    // 운동 정보
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(
                                                            exercise.name,
                                                            style: const TextStyle(
                                                              fontWeight: FontWeight.w500,
                                                              color: mainButtonColor,
                                                              fontSize: 14,
                                                            ),
                                                          ),
                                                          const SizedBox(height: 2),
                                                          Text(
                                                        exercise.volumeSummary,
                                                            style: const TextStyle(
                                                              color: subTextColor,
                                                              fontSize: 12,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    
                                                    // 드래그 핸들
                                                    ReorderableDragStartListener(
                                                      index: index,
                                                      child: Container(
                                                        padding: const EdgeInsets.all(8),
                                                        child: const Icon(
                                                          Icons.drag_handle,
                                                          color: subTextColor,
                                                          size: 24,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              // 제거 버튼을 아래로 이동
                                              Padding(
                                                padding: const EdgeInsets.only(bottom: 8.0, left: 16.0, right: 16.0),
                                                child: SizedBox(
                                                  width: double.infinity,
                                                  child: OutlinedButton.icon(
                                                    onPressed: () => _removeExercise(index),
                                                    icon: const Icon(Icons.remove, size: 16),
                                                    label: const Text('제거'),
                                                    style: OutlinedButton.styleFrom(
                                                      side: const BorderSide(color: Colors.red),
                                                      foregroundColor: Colors.red,
                                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 저장 버튼
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveRoutine,
                  child: Text(
                    _getSaveButtonText(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExerciseSettingsDialog extends StatefulWidget {
  final Exercise exercise;

  const _ExerciseSettingsDialog({required this.exercise});

  @override
  State<_ExerciseSettingsDialog> createState() => _ExerciseSettingsDialogState();
}

class _ExerciseSettingsDialogState extends State<_ExerciseSettingsDialog> {
  late int _sets;
  late int _reps;
  late int _rest;

  @override
  void initState() {
    super.initState();
    _sets = widget.exercise.sets ?? 3;
    _reps = widget.exercise.reps ?? 12;
    _rest = widget.exercise.restSeconds ?? 60;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.exercise.name,
        style: const TextStyle(color: mainButtonColor),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 세트 수 설정
            Row(
              children: [
                const Expanded(
                  flex: 2,
                  child: Text(
                    '세트',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        onPressed: () {
                          if (_sets > 1) setState(() => _sets--);
                        },
                        icon: const Icon(Icons.remove_circle_outline),
                        color: mainButtonColor,
                      ),
                      Container(
                        width: 50,
                        alignment: Alignment.center,
                        child: Text(
                          '$_sets',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: mainButtonColor,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          if (_sets < 10) setState(() => _sets++);
                        },
                        icon: const Icon(Icons.add_circle_outline),
                        color: mainButtonColor,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(),

            // 횟수 설정
            Row(
              children: [
                const Expanded(
                  flex: 2,
                  child: Text(
                    '횟수',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        onPressed: () {
                          if (_reps > 1) setState(() => _reps--);
                        },
                        icon: const Icon(Icons.remove_circle_outline),
                        color: mainButtonColor,
                      ),
                      Container(
                        width: 50,
                        alignment: Alignment.center,
                        child: Text(
                          '$_reps',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: mainButtonColor,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          if (_reps < 50) setState(() => _reps++);
                        },
                        icon: const Icon(Icons.add_circle_outline),
                        color: mainButtonColor,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(),

            // 휴식 시간 설정
            Row(
              children: [
                const Expanded(
                  flex: 2,
                  child: Text(
                    '휴식(초)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        onPressed: () {
                          if (_rest > 10) setState(() => _rest -= 10);
                        },
                        icon: const Icon(Icons.remove_circle_outline),
                        color: mainButtonColor,
                      ),
                      Container(
                        width: 50,
                        alignment: Alignment.center,
                        child: Text(
                          '$_rest',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: mainButtonColor,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          if (_rest < 300) setState(() => _rest += 10);
                        },
                        icon: const Icon(Icons.add_circle_outline),
                        color: mainButtonColor,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop({
              'sets': _sets,
              'reps': _reps,
              'rest': _rest,
            });
          },
          child: const Text('추가'),
        ),
      ],
    );
  }
}
