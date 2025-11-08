import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_application_1/color.dart';
import 'package:flutter_application_1/features/workout/application/workout_providers.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WorkoutScreen extends ConsumerWidget {
  const WorkoutScreen({super.key});



  void _showSupabaseDeleteDialog(BuildContext context, WidgetRef ref, routine) {
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final supabaseRoutinesAsync = ref.watch(supabaseRoutineNotifierProvider);
    final aiRecommendedRoutinesAsync = ref.watch(aiRecommendedRoutinesProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('운동'),
        backgroundColor: backgroundColor,
        foregroundColor: mainButtonColor,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
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
                    Text(
                      '30분 / 45분',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '15분 더 운동하세요!',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '운동 루틴',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: mainButtonColor,
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => context.push('/app/workout/create-routine'),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('새 루틴 추가'),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: mainButtonColor),
                      foregroundColor: mainButtonColor,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children: [
                    // 데이터베이스 루틴 섹션
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '내 루틴',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: mainButtonColor,
                                ),
                              ),
                            ],
                          ),
                        ),


                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Supabase 루틴 목록
                    supabaseRoutinesAsync.when(
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
                        child: Column(
                          children: [
                            const Icon(Icons.error, color: Colors.red, size: 32),
                            const SizedBox(height: 8),
                            Text(
                              '루틴을 불러올 수 없습니다\n$error',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.red),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () => ref.refresh(supabaseRoutineNotifierProvider),
                              child: const Text('다시 시도'),
                            ),
                          ],
                        ),
                      ),
                      data: (supabaseRoutines) => supabaseRoutines.isEmpty
                          ? Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: backgroundColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: borderColor),
                              ),
                              child: Consumer(
                                builder: (context, ref, child) {
                                  final currentUser = Supabase.instance.client.auth.currentUser;
                                  
                                  if (currentUser == null) {
                                    return Column(
                                      children: [
                                        const Icon(Icons.person_off, size: 48, color: Colors.red),
                                        const SizedBox(height: 16),
                                        const Text(
                                          '로그인이 필요합니다',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.red,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        const Text(
                                          '루틴을 저장하고 관리하려면 로그인해주세요.',
                                          style: TextStyle(color: subTextColor),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    );
                                  }
                                  
                                  return Column(
                                    children: [
                                      const Icon(Icons.fitness_center, size: 48, color: subTextColor),
                                      const SizedBox(height: 16),
                                      const Text(
                                        '아직 생성된 루틴이 없습니다',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: subTextColor,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        '새 루틴을 추가해서 운동을 시작해보세요!',
                                        style: TextStyle(color: subTextColor),
                                      ),
                                      const SizedBox(height: 16),
                                      ElevatedButton.icon(
                                        onPressed: () => context.push('/app/workout/create-routine'),
                                        icon: const Icon(Icons.add),
                                        label: const Text('첫 루틴 만들기'),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            )
                          : Column(
                              children: supabaseRoutines.map((routine) => _SupabaseRoutineCard(
                                routine: routine,
                                onTap: () {
                                  // 루틴의 exercise_id 리스트 추출
                                  List<int> exerciseIds = [];
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
                                  
                                  // 메시지 표시
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('${routine.title} 루틴을 시작합니다'),
                                      backgroundColor: mainButtonColor,
                                      duration: const Duration(seconds: 1),
                                    ),
                                  );
                                  
                                  // ExerciseScreen으로 이동
                                  context.push('/app/workout/exercise', extra: {
                                    'exerciseIds': exerciseIds,
                                  });
                                },
                                onDelete: () => _showSupabaseDeleteDialog(context, ref, routine),
                              )).toList(),
                            ),
                    ),


                    
                    // AI 추천 루틴 섹션
                    const SizedBox(height: 16),
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
                    
                    // AI 추천 루틴 목록
                    aiRecommendedRoutinesAsync.when(
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (error, stack) => Container(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'AI 추천 루틴을 불러올 수 없습니다',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                      data: (aiRecommendedRoutines) => Column(
                        children: aiRecommendedRoutines.map((routine) => _AIRecoRoutCard(
                          routine: routine,
                          onTap: () {
                            // AI 추천 루틴의 exercise_id 리스트 추출
                            List<int> exerciseIds = [];
                            for (final exercise in routine.exercises) {
                              // Exercise 모델에서 id를 추출 (문자열을 정수로 변환)
                              try {
                                final exerciseId = int.parse(exercise.id);
                                exerciseIds.add(exerciseId);
                              } catch (e) {
                                print('운동 ID 파싱 실패: ${exercise.id}');
                              }
                            }
                            
                            // 메시지 표시
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${routine.name} 루틴을 시작합니다'),
                                backgroundColor: mainButtonColor,
                                duration: const Duration(seconds: 1),
                              ),
                            );
                            
                            // ExerciseScreen으로 이동
                            context.push('/app/workout/exercise', extra: {
                              'exerciseIds': exerciseIds,
                            });
                          },
                        )).toList(),
                      ),
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
  });

  final routine; // SupabaseWorkoutRoutine
  final VoidCallback onTap;
  final VoidCallback onDelete;

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
          ],
        ),
      ),
    );
  }
}

class _AIRecoRoutCard extends StatelessWidget {
  const _AIRecoRoutCard({
    required this.routine,
    required this.onTap,
  });

  final WorkoutRoutine routine;
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
            ],
          ],
        ),
      ),
    );
  }
}
