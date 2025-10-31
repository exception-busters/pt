import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_application_1/features/diet/application/diet_providers.dart';

class DietScreen extends ConsumerWidget {
  const DietScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planValue = ref.watch(todayDietPlanProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('식단'),
        backgroundColor: const Color(0xFFE8F5E8),
        foregroundColor: const Color(0xFF4A6741),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '다른 추천 받기',
            onPressed: () => ref.invalidate(todayDietPlanProvider),
          ),
        ],
      ),
      body: SafeArea(
        child: planValue.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _DietErrorView(
            error: error,
            onRetry: () => ref.invalidate(todayDietPlanProvider),
          ),
          data: (plan) => _DietPlanView(plan: plan),
        ),
      ),
    );
  }
}

class _DietPlanView extends StatelessWidget {
  const _DietPlanView({required this.plan});

  final DietRecommendationResult plan;

  String _macroLine(double current, double target, String label) {
    return '$label ${current.toStringAsFixed(0)}g / ${target.toStringAsFixed(0)}g';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '오늘의 식단 추천',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  plan.summary,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '총 ${plan.total.calories.toStringAsFixed(0)} kcal',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '목표 ${plan.target.calories.toStringAsFixed(0)} kcal',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _macroLine(plan.total.protein, plan.target.protein, '단백질'),
                            style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
                          ),
                          Text(
                            _macroLine(plan.total.carbs, plan.target.carbs, '탄수화물'),
                            style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
                          ),
                          Text(
                            _macroLine(plan.total.fat, plan.target.fat, '지방'),
                            style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => context.go('/app/records'),
            icon: const Icon(Icons.analytics_outlined),
            label: const Text('식단 기록으로 이동'),
          ),
          const SizedBox(height: 24),
          for (final meal in plan.meals) ...[
            _MealCard(meal: meal),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}

class _MealCard extends StatelessWidget {
  const _MealCard({required this.meal});

  final MealRecommendation meal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            meal.label,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF4A6741),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '총 ${meal.nutrition.calories.toStringAsFixed(0)} kcal · '
            '단백질 ${meal.nutrition.protein.toStringAsFixed(1)}g · '
            '탄수화물 ${meal.nutrition.carbs.toStringAsFixed(1)}g · '
            '지방 ${meal.nutrition.fat.toStringAsFixed(1)}g',
            style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF7A8B7A)),
          ),
          const SizedBox(height: 16),
          for (final item in meal.items) ...[
            _MealItemRow(item: item),
            if (item != meal.items.last) const Divider(height: 20),
          ],
        ],
      ),
    );
  }
}

class _MealItemRow extends StatelessWidget {
  const _MealItemRow({required this.item});

  final MealItemRecommendation item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nutrition = item.nutrition;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.food.name,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.food.category,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF8C9A8C),
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${item.grams.toStringAsFixed(0)} g',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${nutrition.calories.toStringAsFixed(0)} kcal',
              style: theme.textTheme.bodySmall,
            ),
            Text(
              'P ${nutrition.protein.toStringAsFixed(1)}g · '
              'C ${nutrition.carbs.toStringAsFixed(1)}g · '
              'F ${nutrition.fat.toStringAsFixed(1)}g',
              style: theme.textTheme.bodySmall?.copyWith(
                color: const Color(0xFF8C9A8C),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DietErrorView extends StatelessWidget {
  const _DietErrorView({required this.error, required this.onRetry});

  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final e = error;
    final message = e is DietRecommendationException
        ? e.message ?? '식단 추천 오류가 발생했습니다.'
        : '식단 추천을 불러오는 중 오류가 발생했습니다.';

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.restaurant_menu, size: 64, color: Color(0xFF9ACD32)),
        const SizedBox(height: 24),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, color: Color(0xFF4A6741)),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: onRetry,
          child: const Text('다시 시도'),
        ),
      ],
    );
  }
}
