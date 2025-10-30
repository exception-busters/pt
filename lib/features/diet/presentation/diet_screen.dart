import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_application_1/color.dart';
import '../application/diet_providers.dart';

class DietScreen extends ConsumerStatefulWidget {
  const DietScreen({super.key});

  @override
  ConsumerState<DietScreen> createState() => _DietScreenState();
}

class _DietScreenState extends ConsumerState<DietScreen> {
  @override
  void initState() {
    super.initState();
    // 화면 진입 시 날짜 체크
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dietControllerProvider.notifier).checkAndResetIfNewDay();
    });
  }

  void _showMealDialog(String mealType) {
    final dietController = ref.read(dietControllerProvider.notifier);
    final currentMeal = dietController.getMealData(mealType);
    
    final foodController = TextEditingController(text: currentMeal?.food ?? '');
    final caloriesController = TextEditingController(text: currentMeal?.calories.replaceAll('kcal', '') ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$mealType 식단 ${currentMeal != null ? '수정' : '추가'}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: foodController,
              decoration: const InputDecoration(
                labelText: '음식명',
                hintText: '예: 계란후라이, 토스트',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: caloriesController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '칼로리',
                hintText: '예: 350',
                suffixText: 'kcal',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              if (foodController.text.isNotEmpty && caloriesController.text.isNotEmpty) {
                dietController.updateMeal(
                  mealType,
                  foodController.text,
                  '${caloriesController.text}kcal',
                );
                Navigator.of(context).pop();
              }
            },
            child: Text(currentMeal != null ? '수정' : '추가'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dietData = ref.watch(dietControllerProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('식단'),
        backgroundColor: backgroundColor,
        foregroundColor: mainButtonColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('식단 추가 기능은 추후 구현됩니다'),
                  backgroundColor: mainButtonColor,
                ),
              );
            },
          ),
        ],
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
                child: Column(
                  children: [
                    const Text(
                      '오늘의 칼로리',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${dietData.totalCalories} / 1,800 kcal',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '목표까지 ${1800 - dietData.totalCalories}kcal 남음',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                '식단 기록',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: mainButtonColor,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children: [
                    _MealCard(
                      meal: '아침',
                      mealData: dietData.breakfast,
                      icon: Icons.wb_sunny,
                      onButtonPressed: () => _showMealDialog('아침'),
                    ),
                    _MealCard(
                      meal: '점심',
                      mealData: dietData.lunch,
                      icon: Icons.wb_sunny_outlined,
                      onButtonPressed: () => _showMealDialog('점심'),
                    ),
                    _MealCard(
                      meal: '저녁',
                      mealData: dietData.dinner,
                      icon: Icons.nightlight_round,
                      onButtonPressed: () => _showMealDialog('저녁'),
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

class _MealCard extends StatelessWidget {
  final String meal;
  final MealData? mealData;
  final IconData icon;
  final VoidCallback onButtonPressed;
  
  const _MealCard({
    required this.meal,
    required this.mealData,
    required this.icon,
    required this.onButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    final hasData = mealData != null;
    
    return Container(
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
              color: mainButtonColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: mainButtonColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meal,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: mainButtonColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasData ? mealData!.food : '식단을 추가해주세요',
                  style: TextStyle(
                    fontSize: 14,
                    color: hasData ? subTextColor : subTextColor.withOpacity(0.6),
                    fontStyle: hasData ? FontStyle.normal : FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          if (hasData) ...[
            Text(
              mealData!.calories,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: mainButtonColor,
              ),
            ),
            const SizedBox(width: 12),
          ],
          OutlinedButton(
            onPressed: onButtonPressed,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: mainButtonColor),
              foregroundColor: mainButtonColor,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: const Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              hasData ? '수정' : '추가',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

