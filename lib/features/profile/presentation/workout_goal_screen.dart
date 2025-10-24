import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_application_1/color.dart';
import 'package:go_router/go_router.dart';

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

  final List<String> _goals = ['체중감량', '근육증가', '체력향상', '건강유지'];
  final List<String> _levels = ['초급', '중급', '고급'];
  final List<String> _workoutTypes = ['유산소', '근력운동', '요가', '필라테스', '스트레칭'];

  void _saveGoals() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('운동 목표가 저장되었습니다'),
        backgroundColor: mainButtonColor,
      ),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('운동 목표 설정'),
        backgroundColor: backgroundColor,
        foregroundColor: mainButtonColor,
        actions: [
          TextButton(
            onPressed: _saveGoals,
            child: const Text(
              '저장',
              style: TextStyle(
                color: mainButtonColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
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