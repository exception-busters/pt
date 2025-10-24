import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_application_1/color.dart';
import 'package:go_router/go_router.dart';

class DietGoalScreen extends ConsumerStatefulWidget {
  const DietGoalScreen({super.key});

  @override
  ConsumerState<DietGoalScreen> createState() => _DietGoalScreenState();
}

class _DietGoalScreenState extends ConsumerState<DietGoalScreen> {
  int _dailyCalorieGoal = 1800;
  String _selectedDietType = '균형잡힌 식단';
  int _mealsPerDay = 3;
  double _waterGoal = 2.0;
  List<String> _dietaryRestrictions = [];

  final List<String> _dietTypes = [
    '균형잡힌 식단',
    '저탄수화물',
    '고단백질',
    '저지방',
    '케토',
    '비건',
    '지중해식',
  ];

  final List<String> _restrictions = [
    '유제품 제한',
    '글루텐 프리',
    '견과류 알레르기',
    '해산물 알레르기',
    '당뇨 관리',
    '고혈압 관리',
  ];

  void _saveDietGoals() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('식단 목표가 저장되었습니다'),
        backgroundColor: mainButtonColor,
      ),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('식단 목표 설정'),
        backgroundColor: backgroundColor,
        foregroundColor: mainButtonColor,
        actions: [
          TextButton(
            onPressed: _saveDietGoals,
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
              // 일일 칼로리 목표
              const Text(
                '일일 칼로리 목표',
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
                      '$_dailyCalorieGoal kcal',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: mainButtonColor,
                      ),
                    ),
                    Slider(
                      value: _dailyCalorieGoal.toDouble(),
                      min: 1200,
                      max: 3000,
                      divisions: 36,
                      activeColor: mainButtonColor,
                      onChanged: (value) {
                        setState(() {
                          _dailyCalorieGoal = (value / 50).round() * 50;
                        });
                      },
                    ),
                    const Text(
                      '권장: 성인 남성 2000-2500kcal, 성인 여성 1500-2000kcal',
                      style: TextStyle(
                        fontSize: 12,
                        color: subTextColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // 식단 유형
              const Text(
                '식단 유형',
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
                  children: _dietTypes.map((type) {
                    return RadioListTile<String>(
                      title: Text(type),
                      subtitle: Text(_getDietTypeDescription(type)),
                      value: type,
                      groupValue: _selectedDietType,
                      activeColor: mainButtonColor,
                      onChanged: (value) {
                        setState(() {
                          _selectedDietType = value!;
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),
              
              // 하루 식사 횟수
              const Text(
                '하루 식사 횟수',
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
                      '$_mealsPerDay회',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: mainButtonColor,
                      ),
                    ),
                    Slider(
                      value: _mealsPerDay.toDouble(),
                      min: 3,
                      max: 6,
                      divisions: 3,
                      activeColor: mainButtonColor,
                      onChanged: (value) {
                        setState(() {
                          _mealsPerDay = value.round();
                        });
                      },
                    ),
                    Text(
                      _getMealDescription(_mealsPerDay),
                      style: const TextStyle(
                        fontSize: 12,
                        color: subTextColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // 일일 수분 섭취 목표
              const Text(
                '일일 수분 섭취 목표',
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
                      '${_waterGoal.toStringAsFixed(1)}L',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: mainButtonColor,
                      ),
                    ),
                    Slider(
                      value: _waterGoal,
                      min: 1.0,
                      max: 4.0,
                      divisions: 30,
                      activeColor: mainButtonColor,
                      onChanged: (value) {
                        setState(() {
                          _waterGoal = (value * 10).round() / 10;
                        });
                      },
                    ),
                    const Text(
                      '권장: 성인 기준 하루 2-3L',
                      style: TextStyle(
                        fontSize: 12,
                        color: subTextColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // 식이 제한사항
              const Text(
                '식이 제한사항',
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
                  children: _restrictions.map((restriction) {
                    return CheckboxListTile(
                      title: Text(restriction),
                      value: _dietaryRestrictions.contains(restriction),
                      activeColor: mainButtonColor,
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            _dietaryRestrictions.add(restriction);
                          } else {
                            _dietaryRestrictions.remove(restriction);
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
                  onPressed: _saveDietGoals,
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

  String _getDietTypeDescription(String type) {
    switch (type) {
      case '균형잡힌 식단':
        return '탄수화물, 단백질, 지방을 균형있게 섭취';
      case '저탄수화물':
        return '탄수화물 섭취를 제한하는 식단';
      case '고단백질':
        return '단백질 비중을 높인 식단';
      case '저지방':
        return '지방 섭취를 제한하는 식단';
      case '케토':
        return '극저탄수화물, 고지방 식단';
      case '비건':
        return '동물성 식품을 배제한 식단';
      case '지중해식':
        return '올리브오일, 생선, 채소 중심의 식단';
      default:
        return '';
    }
  }

  String _getMealDescription(int meals) {
    switch (meals) {
      case 3:
        return '아침, 점심, 저녁';
      case 4:
        return '아침, 점심, 저녁 + 간식 1회';
      case 5:
        return '아침, 점심, 저녁 + 간식 2회';
      case 6:
        return '소량씩 자주 먹기 (6회)';
      default:
        return '';
    }
  }
}