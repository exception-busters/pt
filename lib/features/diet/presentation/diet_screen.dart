import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _ManualMealSection(),
              const SizedBox(height: 32),
              planValue.when(
                loading: () => const _DietLoadingView(),
                error: (error, _) => _DietErrorView(
                  error: error,
                  onRetry: () => ref.invalidate(todayDietPlanProvider),
                ),
                data: (plan) => _DietRecommendationSection(plan: plan),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ManualMealSection extends StatelessWidget {
  const _ManualMealSection();

  static final List<_MealInputConfig> _meals = [
    _MealInputConfig(label: '아침', icon: Icons.wb_sunny_outlined, helpText: '예) 단백질 쉐이크, 고구마, 사과'),
    _MealInputConfig(label: '점심', icon: Icons.restaurant_menu_outlined, helpText: '예) 현미밥, 닭가슴살 구이, 샐러드'),
    _MealInputConfig(label: '저녁', icon: Icons.nightlight_round, helpText: '예) 채소 스무디, 삶은 계란'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '오늘의 식단 기록',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF4A6741),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          '아침, 점심, 저녁 식단을 직접 입력하고 아래의 AI 추천 식단을 참고해 적용할 수 있어요.',
          style: TextStyle(color: Color(0xFF6B7B6B)),
        ),
        const SizedBox(height: 20),
        for (final meal in _meals) ...[
          _MealInputCard(config: meal),
          const SizedBox(height: 16),
        ],
        OutlinedButton.icon(
          onPressed: () => context.go('/app/records'),
          icon: const Icon(Icons.analytics_outlined),
          label: const Text('식단 기록으로 이동'),
        ),
      ],
    );
  }
}

class _MealInputCard extends ConsumerWidget {
  const _MealInputCard({required this.config});

  final _MealInputConfig config;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dietData = ref.watch(dietControllerProvider);
    final mealData = dietData.mealByLabel(config.label);
    final components = mealData?.components ?? const <MealComponent>[];
    final nutrition = mealData?.nutrition ?? NutritionSummary.zero;
    final hasContent = components.isNotEmpty;

    final displayComponents = components.take(3).toList();
    final remainingCount = components.length - displayComponents.length;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(config.icon, color: const Color(0xFF4A6741)),
                  const SizedBox(width: 8),
                  Text(
                    config.label,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF4A6741),
                    ),
                  ),
                ],
              ),
              if (hasContent)
                Text(
                  mealData!.calories,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4A6741),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (hasContent)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final component in displayComponents)
                      Chip(
                        label: Text(
                          '${component.food.name} ${component.grams.toStringAsFixed(0)}g',
                          style: const TextStyle(fontSize: 12),
                        ),
                        backgroundColor: const Color(0xFFE8F5E8),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    if (remainingCount > 0)
                      Chip(
                        label: Text(
                          '+$remainingCount',
                          style: const TextStyle(fontSize: 12),
                        ),
                        backgroundColor: const Color(0xFFE8F5E8),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '단백질 ${nutrition.protein.toStringAsFixed(1)}g · 탄수화물 ${nutrition.carbs.toStringAsFixed(1)}g · 지방 ${nutrition.fat.toStringAsFixed(1)}g',
                  style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF6B7B6B)),
                ),
              ],
            )
          else
            Text(
              '등록된 식단이 없어요. 아래 버튼으로 음식 DB에서 검색해 ${config.helpText} 등을 추가해보세요.',
              style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF6B7B6B)),
            ),
          const SizedBox(height: 12),
          SizedBox(
            height: 36,
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openEditor(context, ref),
                    icon: const Icon(Icons.search, size: 18),
                    label: const Text(
                      '식품 검색',
                      style: TextStyle(fontSize: 13),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: '식단 비우기',
                  onPressed: hasContent ? () => _handleClear(context, ref) : null,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Future<void> _openEditor(BuildContext context, WidgetRef ref) async {
    final current = ref.read(dietControllerProvider).mealByLabel(config.label)?.components ?? const <MealComponent>[];
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _MealEditorSheet(
          mealLabel: config.label,
          initialComponents: current,
        ),
      ),
    );
  }

  void _handleClear(BuildContext context, WidgetRef ref) {
    FocusScope.of(context).unfocus();
    final messenger = ScaffoldMessenger.of(context);
    ref.read(dietControllerProvider.notifier).clearMeal(config.label);
    messenger.showSnackBar(
      SnackBar(
        content: Text('${config.label} 식단을 비웠어요.'),
      ),
    );
  }
}

class _DietRecommendationSection extends ConsumerWidget {
  const _DietRecommendationSection({required this.plan});

  final DietRecommendationResult plan;

  String _macroLine(double current, double target, String label) {
    return '$label ${current.toStringAsFixed(0)}g / ${target.toStringAsFixed(0)}g';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Column(
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
                'AI 추천 식단 요약',
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
        const Text(
          'AI 추천 식단',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF4A6741),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '아래 추천 항목을 원하는 끼니에 적용하거나, 섭취량(g)을 조정해 나만의 식단으로 바꿀 수 있어요.',
          style: TextStyle(color: Color(0xFF6B7B6B)),
        ),
        const SizedBox(height: 16),
        for (final meal in plan.meals) ...[
          _EditableMealCard(meal: meal),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}

class _EditableMealCard extends ConsumerStatefulWidget {
  const _EditableMealCard({required this.meal});

  final MealRecommendation meal;

  @override
  ConsumerState<_EditableMealCard> createState() => _EditableMealCardState();
}

class _EditableMealCardState extends ConsumerState<_EditableMealCard> {
  late List<_EditableMealItem> _items;
  late List<TextEditingController> _gramControllers;

  @override
  void initState() {
    super.initState();
    _items = widget.meal.items
        .map(
            (item) => _EditableMealItem(
              food: item.food,
              grams: item.grams,
            ),
          )
          .toList();
    _gramControllers = _items
        .map(
          (item) => TextEditingController(
            text: item.grams.toStringAsFixed(0),
          ),
        )
        .toList();
  }

  NutritionSummary get _totalNutrition {
    return _items.fold(
      NutritionSummary.zero,
      (previous, element) => previous + element.nutrition,
    );
  }

  void _resetToOriginal() {
    setState(() {
      _items = widget.meal.items
          .map(
            (item) => _EditableMealItem(
              food: item.food,
              grams: item.grams,
            ),
          )
          .toList();
      for (var i = 0; i < _gramControllers.length; i++) {
        _gramControllers[i].text = widget.meal.items[i].grams.toStringAsFixed(0);
      }
    });
  }

  @override
  void dispose() {
    for (final controller in _gramControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totals = _totalNutrition;

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.meal.label,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF4A6741),
                ),
              ),
              Text(
                '총 ${totals.calories.toStringAsFixed(0)} kcal',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF4A6741),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '단백질 ${totals.protein.toStringAsFixed(1)}g · 탄수화물 ${totals.carbs.toStringAsFixed(1)}g · 지방 ${totals.fat.toStringAsFixed(1)}g',
            style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF7A8B7A)),
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < _items.length; i++) ...[
            _EditableMealItemRow(
              item: _items[i],
              controller: _gramControllers[i],
              onChanged: (grams) {
                setState(() {
                  _items[i] = _items[i].copyWithGrams(grams);
                });
              },
            ),
            if (i != _items.length - 1) const Divider(height: 20),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _applyToManual(context),
                  icon: const Icon(Icons.check_circle_outline),
                  label: Text('${widget.meal.label}에 적용'),
                ),
              ),
              const SizedBox(width: 12),
              TextButton(
                onPressed: _resetToOriginal,
                child: const Text('추천 초기화'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _applyToManual(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final components = _items
        .map(
          (item) => MealComponent(food: item.food, grams: item.grams),
        )
        .toList();

    await ref.read(dietControllerProvider.notifier).saveMealComponents(
          widget.meal.label,
          components,
        );

    messenger.showSnackBar(
      SnackBar(
        content: Text('${widget.meal.label} 식단에 AI 추천을 적용했어요.'),
      ),
    );
  }
}

class _MealEditorSheet extends ConsumerStatefulWidget {
  const _MealEditorSheet({
    required this.mealLabel,
    required this.initialComponents,
  });

  final String mealLabel;
  final List<MealComponent> initialComponents;

  @override
  ConsumerState<_MealEditorSheet> createState() => _MealEditorSheetState();
}

class _MealEditorSheetState extends ConsumerState<_MealEditorSheet> {
  late List<MealComponent> _selected;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _selected = widget.initialComponents
        .map((item) => MealComponent(food: item.food, grams: item.grams))
        .toList();
    _searchController.addListener(_onQueryChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onQueryChanged);
    _searchController.dispose();
    super.dispose();
  }

  NutritionSummary get _total {
    return _selected.fold(
      NutritionSummary.zero,
      (previous, element) => previous + element.nutrition,
    );
  }

  @override
  Widget build(BuildContext context) {
    final foods = ref.watch(foodDatabaseProvider);

    final sheetHeight = MediaQuery.of(context).size.height * 0.85;

    return SafeArea(
      child: SizedBox(
        height: sheetHeight,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${widget.mealLabel} 식단 편집',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4A6741),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_selected.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ..._selected.map(
                        (item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.food.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      item.food.category,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF6B7B6B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${item.grams.toStringAsFixed(0)} g',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit, size: 18),
                                onPressed: () => _editComponent(context, item),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 18),
                                onPressed: () => _removeComponent(item),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '총 ${_total.calories.toStringAsFixed(0)} kcal · 단백질 ${_total.protein.toStringAsFixed(1)}g · 탄수화물 ${_total.carbs.toStringAsFixed(1)}g · 지방 ${_total.fat.toStringAsFixed(1)}g',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF4A6741)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: '음식명을 검색하세요',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: foods.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(
                    child: Text('음식 데이터를 불러오지 못했어요: $error'),
                  ),
                  data: (items) {
                    final filtered = _query.isEmpty
                        ? items.take(50).toList()
                        : items
                            .where((item) => item.name.contains(_query) || item.category.contains(_query))
                            .take(50)
                            .toList();
                    if (filtered.isEmpty) {
                      return const Center(
                        child: Text('검색 결과가 없어요. 다른 키워드를 입력해보세요.'),
                      );
                    }
                    return ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final food = filtered[index];
                        return ListTile(
                          title: Text(food.name),
                          subtitle: Text(
                            '${food.category} · ${food.calories.toStringAsFixed(0)} kcal / 100g',
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () => _addFood(context, food),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: _selected.isEmpty ? null : () => _save(context),
                      child: const Text('저장'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onQueryChanged() {
    setState(() {
      _query = _searchController.text.trim();
    });
  }

  Future<void> _addFood(BuildContext context, FoodItem food) async {
    final grams = await _pickGrams(context, initial: 100);
    if (grams == null) {
      return;
    }
    setState(() {
      final existingIndex = _selected.indexWhere((element) => element.food.code == food.code);
      final component = MealComponent(food: food, grams: grams);
      if (existingIndex >= 0) {
        _selected[existingIndex] = component;
      } else {
        _selected.add(component);
      }
    });
  }

  Future<void> _editComponent(BuildContext context, MealComponent component) async {
    final grams = await _pickGrams(context, initial: component.grams.toInt());
    if (grams == null) {
      return;
    }
    setState(() {
      final index = _selected.indexOf(component);
      if (index >= 0) {
        _selected[index] = component.copyWith(grams: grams);
      }
    });
  }

  void _removeComponent(MealComponent component) {
    setState(() {
      _selected.remove(component);
    });
  }

  Future<void> _save(BuildContext context) async {
    await ref.read(dietControllerProvider.notifier).saveMealComponents(
          widget.mealLabel,
          _selected,
        );
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.mealLabel} 식단을 저장했어요.'),
        ),
      );
    }
  }

  Future<double?> _pickGrams(BuildContext context, {int initial = 100}) async {
    final controller = TextEditingController(text: initial.toString());
    final result = await showDialog<double?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('섭취량 입력'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9]'))],
          decoration: const InputDecoration(
            suffixText: 'g',
            hintText: '섭취한 양을 입력하세요',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              final value = double.tryParse(controller.text.trim());
              Navigator.of(context).pop(value != null && value > 0 ? value : null);
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }
}

class _EditableMealItemRow extends StatelessWidget {
  const _EditableMealItemRow({
    required this.item,
    required this.controller,
    required this.onChanged,
  });

  final _EditableMealItem item;
  final TextEditingController controller;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
              const SizedBox(height: 8),
              Text(
                '단백질 ${item.nutrition.protein.toStringAsFixed(1)}g · 탄수화물 ${item.nutrition.carbs.toStringAsFixed(1)}g · 지방 ${item.nutrition.fat.toStringAsFixed(1)}g',
                style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF7A8B7A)),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: 96,
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9]'))],
            decoration: InputDecoration(
              labelText: '섭취량',
              suffixText: 'g',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onChanged: (value) {
              final grams = double.tryParse(value);
              if (grams == null) {
                return;
              }
              onChanged(grams);
            },
          ),
        ),
      ],
    );
  }
}

class _DietLoadingView extends StatelessWidget {
  const _DietLoadingView();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 160,
      child: Center(
        child: CircularProgressIndicator(),
      ),
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
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.restaurant_menu, size: 64, color: Color(0xFF9ACD32)),
        const SizedBox(height: 16),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, color: Color(0xFF4A6741)),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: onRetry,
          child: const Text('다시 시도'),
        ),
      ],
    );
  }
}

class _MealInputConfig {
  const _MealInputConfig({
    required this.label,
    required this.icon,
    required this.helpText,
  });

  final String label;
  final IconData icon;
  final String helpText;
}

class _EditableMealItem {
  _EditableMealItem({
    required this.food,
    required double grams,
  })  : grams = grams,
        nutrition = _nutritionFrom(food, grams);

  final FoodItem food;
  final double grams;
  final NutritionSummary nutrition;

  _EditableMealItem copyWithGrams(double grams) {
    final safeGrams = grams.clamp(0, 1000).toDouble();
    return _EditableMealItem(food: food, grams: safeGrams);
  }

  static NutritionSummary _nutritionFrom(FoodItem food, double grams) {
    final safeGrams = grams.clamp(0, 1000).toDouble();
    final ratio = safeGrams / 100;
    return NutritionSummary(
      calories: food.calories * ratio,
      protein: food.protein * ratio,
      carbs: food.carbs * ratio,
      fat: food.fat * ratio,
    );
  }
}
