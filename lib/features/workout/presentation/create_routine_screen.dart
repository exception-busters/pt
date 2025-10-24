import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_application_1/color.dart';
import 'package:flutter_application_1/features/workout/application/workout_providers.dart';
import 'package:go_router/go_router.dart';

class CreateRoutineScreen extends ConsumerStatefulWidget {
  final WorkoutRoutine? editingRoutine;
  
  const CreateRoutineScreen({super.key, this.editingRoutine});

  @override
  ConsumerState<CreateRoutineScreen> createState() => _CreateRoutineScreenState();
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
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _addExercise(Exercise exercise) {
    setState(() {
      _selectedExercises.add(exercise);
    });
  }

  void _removeExercise(int index) {
    setState(() {
      _selectedExercises.removeAt(index);
    });
  }

  void _moveExercise(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final exercise = _selectedExercises.removeAt(oldIndex);
      _selectedExercises.insert(newIndex, exercise);
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

    final routine = WorkoutRoutine(
      id: widget.editingRoutine?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text,
      exercises: _selectedExercises,
      createdAt: widget.editingRoutine?.createdAt ?? DateTime.now(),
    );

    if (widget.editingRoutine != null) {
      await ref.read(workoutRoutineControllerProvider.notifier).updateRoutine(
        widget.editingRoutine!.id,
        routine,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('루틴이 수정되었습니다'),
            backgroundColor: mainButtonColor,
          ),
        );
      }
    } else {
      await ref.read(workoutRoutineControllerProvider.notifier).addRoutine(routine);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('새 루틴이 저장되었습니다'),
            backgroundColor: mainButtonColor,
          ),
        );
      }
    }

    if (mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalDuration = _selectedExercises.fold(0, (sum, exercise) => sum + exercise.duration);
    final minutes = totalDuration ~/ 60;
    final seconds = totalDuration % 60;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.editingRoutine != null ? '루틴 수정' : '새 루틴 추가'),
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
                  // 운동 목록 (왼쪽)
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
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: WorkoutRoutineController.availableExercises.length,
                            itemBuilder: (context, index) {
                              final exercise = WorkoutRoutineController.availableExercises[index];
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
                                        '${exercise.description}\n${exercise.duration}초 • ${exercise.category}',
                                        style: const TextStyle(color: subTextColor),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 8.0, left: 16.0, right: 16.0),
                                      child: SizedBox(
                                        width: double.infinity,
                                        child: OutlinedButton.icon(
                                          onPressed: () => _addExercise(exercise),
                                          icon: const Icon(Icons.add, size: 16),
                                          label: const Text('추가'),
                                          style: OutlinedButton.styleFrom(
                                            side: const BorderSide(color: mainButtonColor),
                                            foregroundColor: mainButtonColor,
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
                      ],
                    ),
                  ),

                  // 구분선
                  Container(
                    width: 1,
                    color: borderColor,
                    margin: const EdgeInsets.symmetric(vertical: 16),
                  ),

                  // 선택된 운동 목록 (오른쪽)
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
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
                              : ReorderableListView.builder(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  itemCount: _selectedExercises.length,
                                  onReorder: _moveExercise,
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
                                          ListTile(
                                            leading: Text(
                                              '${index + 1}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: mainButtonColor,
                                              ),
                                            ),
                                            title: Text(
                                              exercise.name,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w500,
                                                color: mainButtonColor,
                                              ),
                                            ),
                                            subtitle: Text(
                                              '${exercise.duration}초',
                                              style: const TextStyle(color: subTextColor),
                                            ),
                                            trailing: const Icon(Icons.drag_handle, color: subTextColor, size: 16),
                                          ),
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
                    widget.editingRoutine != null ? '루틴 수정하기' : '루틴 저장하기',
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