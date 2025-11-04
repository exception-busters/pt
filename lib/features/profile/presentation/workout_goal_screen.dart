import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_application_1/color.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/models/workout_goal_model.dart';
import '../data/profile_data_service.dart';

class WorkoutGoalScreen extends ConsumerStatefulWidget {
  const WorkoutGoalScreen({super.key});

  @override
  ConsumerState<WorkoutGoalScreen> createState() => _WorkoutGoalScreenState();
}

class _WorkoutGoalScreenState extends ConsumerState<WorkoutGoalScreen> {
  String _selectedGoal = '체중감량';
  int _weeklyWorkoutDays = 3;
  int _dailyWorkoutMinutes = 30;
  String _selectedLevel = '초급';
  List<String> _selectedWorkoutTypes = ['유산소'];
  bool _isLoading = true;

  final List<String> _goals = ['체중감량', '근육증가', '체력향상', '건강유지'];
  final List<String> _levels = ['초급', '중급', '고급'];
  final List<String> _workoutTypes = ['유산소', '근력운동', '요가', '필라테스', '스트레칭'];

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  Future<void> _loadExistingData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final userData = await ProfileDataService.loadCompleteUserData(user.id);
      final workoutGoal = userData?['workout'] as WorkoutGoalModel?;
      
      if (workoutGoal != null && mounted) {
        setState(() {
          _selectedGoal = _getGoalStringFromType(workoutGoal.goalType);
          _selectedLevel = _getLevelStringFromType(workoutGoal.level);
          _weeklyWorkoutDays = workoutGoal.weeklyDays ?? 3;
          _dailyWorkoutMinutes = workoutGoal.dailyDurationMin ?? 30;
          _selectedWorkoutTypes = workoutGoal.preferredTypes ?? ['유산소'];
        });
      }
    } catch (e) {
      print('기존 운동 목표 로드 실패: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getGoalStringFromType(WorkoutGoalType? type) {
    switch (type) {
      case WorkoutGoalType.weightLoss:
        return '체중감량';
      case WorkoutGoalType.muscleGain:
        return '근육증가';
      case WorkoutGoalType.endurance:
        return '체력향상';
      case WorkoutGoalType.general:
      default:
        return '건강유지';
    }
  }

  String _getLevelStringFromType(WorkoutLevel? level) {
    switch (level) {
      case WorkoutLevel.beginner:
        return '초급';
      case WorkoutLevel.intermediate:
        return '중급';
      case WorkoutLevel.advanced:
        return '고급';
      default:
        return '초급';
    }
  }

  void _saveGoals() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('로그인이 필요합니다'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 화면 데이터를 모델로 변환
    final workoutGoal = WorkoutGoalModel(
      userId: user.id,
      goalType: _getGoalTypeFromString(_selectedGoal),
      level: _getLevelFromString(_selectedLevel),
      weeklyDays: _weeklyWorkoutDays,
      dailyDurationMin: _dailyWorkoutMinutes,
      preferredTypes: _selectedWorkoutTypes,
    );

    // 로딩 표시
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: mainButtonColor),
      ),
    );

    try {
      // 데이터베이스에 저장
      final success = await ProfileDataService.updateWorkoutGoal(workoutGoal);
      
      if (mounted) {
        Navigator.of(context).pop(); // 로딩 다이얼로그 닫기
        
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('운동 목표가 저장되었습니다'),
              backgroundColor: mainButtonColor,
            ),
          );
          context.pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('저장에 실패했습니다. 다시 시도해주세요.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
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

  WorkoutGoalType _getGoalTypeFromString(String goal) {
    switch (goal) {
      case '체중감량':
        return WorkoutGoalType.weightLoss;
      case '근육증가':
        return WorkoutGoalType.muscleGain;
      case '체력향상':
        return WorkoutGoalType.endurance;
      case '건강유지':
      default:
        return WorkoutGoalType.general;
    }
  }

  WorkoutLevel _getLevelFromString(String level) {
    switch (level) {
      case '초급':
        return WorkoutLevel.beginner;
      case '중급':
        return WorkoutLevel.intermediate;
      case '고급':
        return WorkoutLevel.advanced;
      default:
        return WorkoutLevel.beginner;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('운동 목표 설정'),
          backgroundColor: backgroundColor,
          foregroundColor: mainButtonColor,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: mainButtonColor),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('운동 목표 설정'),
        backgroundColor: backgroundColor,
        foregroundColor: mainButtonColor,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 운동 목표
              const Text(
                '운동 목표',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: mainButtonColor,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  children: _goals.map((goal) {
                    return RadioListTile<String>(
                      title: Text(goal),
                      value: goal,
                      groupValue: _selectedGoal,
                      activeColor: mainButtonColor,
                      onChanged: (value) {
                        setState(() {
                          _selectedGoal = value!;
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),
              
              // 운동 레벨
              const Text(
                '운동 레벨',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: mainButtonColor,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  children: _levels.map((level) {
                    return RadioListTile<String>(
                      title: Text(level),
                      subtitle: Text(_getLevelDescription(level)),
                      value: level,
                      groupValue: _selectedLevel,
                      activeColor: mainButtonColor,
                      onChanged: (value) {
                        setState(() {
                          _selectedLevel = value!;
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),
              
              // 주간 운동 일수
              const Text(
                '주간 운동 일수',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: mainButtonColor,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  children: [
                    Text(
                      '$_weeklyWorkoutDays일',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: mainButtonColor,
                      ),
                    ),
                    Slider(
                      value: _weeklyWorkoutDays.toDouble(),
                      min: 1,
                      max: 7,
                      divisions: 6,
                      activeColor: mainButtonColor,
                      onChanged: (value) {
                        setState(() {
                          _weeklyWorkoutDays = value.round();
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // 일일 운동 시간
              const Text(
                '일일 운동 시간',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: mainButtonColor,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  children: [
                    Text(
                      '$_dailyWorkoutMinutes분',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: mainButtonColor,
                      ),
                    ),
                    Slider(
                      value: _dailyWorkoutMinutes.toDouble(),
                      min: 15,
                      max: 120,
                      divisions: 21,
                      activeColor: mainButtonColor,
                      onChanged: (value) {
                        setState(() {
                          _dailyWorkoutMinutes = value.round();
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // 선호 운동 유형
              const Text(
                '선호 운동 유형',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: mainButtonColor,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  children: _workoutTypes.map((type) {
                    return CheckboxListTile(
                      title: Text(type),
                      value: _selectedWorkoutTypes.contains(type),
                      activeColor: mainButtonColor,
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            _selectedWorkoutTypes.add(type);
                          } else {
                            _selectedWorkoutTypes.remove(type);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 32),
              
              // 저장 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveGoals,
                  child: const Text(
                    '목표 저장하기',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getLevelDescription(String level) {
    switch (level) {
      case '초급':
        return '운동 경험이 적거나 처음 시작하는 분';
      case '중급':
        return '꾸준히 운동하고 있는 분';
      case '고급':
        return '운동 경험이 풍부하고 고강도 운동이 가능한 분';
      default:
        return '';
    }
  }
}