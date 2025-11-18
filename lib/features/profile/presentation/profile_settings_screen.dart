import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_application_1/color.dart';
import '../application/complete_profile_providers.dart';
import '../domain/models/user_profile_model.dart';
import '../domain/models/workout_goal_model.dart';
import '../domain/models/diet_goal_model.dart';
import '../../common/widgets/profile_loading_overlay.dart';
import '../../workout/application/workout_providers.dart'
    show aiRecommendedRoutinesProvider;
import '../../diet/application/diet_providers.dart'
    show todayDietPlanProvider;

class ProfileSettingsScreen extends ConsumerStatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  ConsumerState<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends ConsumerState<ProfileSettingsScreen> {
  final _nicknameController = TextEditingController();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _calorieController = TextEditingController();
  
  Gender? _selectedGender;
  WorkoutGoalType? _selectedWorkoutGoal;
  WorkoutLevel? _selectedWorkoutLevel;
  DietType? _selectedDietType;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
    });
  }

  void _loadUserData() {
    final userData = ref.read(completeUserDataProvider);
    
    if (userData.user != null) {
      _nicknameController.text = userData.user!.nickname;
    }
    
    if (userData.profile != null) {
      final profile = userData.profile!;
      _selectedGender = profile.gender;
      _ageController.text = profile.age?.toString() ?? '';
      _heightController.text = profile.height?.toString() ?? '';
      _weightController.text = profile.weight?.toString() ?? '';
    }
    
    if (userData.workout != null) {
      final workout = userData.workout!;
      _selectedWorkoutGoal = _normalizeWorkoutGoal(workout.goalType);
      _selectedWorkoutLevel = workout.level;
    }
    
    if (userData.diet != null) {
      final diet = userData.diet!;
      _selectedDietType = diet.dietType;
      _calorieController.text = diet.dailyCalorieTarget?.toString() ?? '';
    }
  }

  Future<void> _saveProfile() async {
    if (!_validateForm()) return;

    final controller = ref.read(completeUserDataProvider.notifier);
    final currentData = ref.read(completeUserDataProvider);
    var workoutGoalUpdated = false;
    var dietGoalUpdated = false;

    // 닉네임 업데이트
    if (_nicknameController.text.isNotEmpty && 
        _nicknameController.text != currentData.user?.nickname) {
      await controller.updateNickname(_nicknameController.text);
    }

    // 프로필 업데이트
    if (currentData.user != null) {
      final updatedProfile = UserProfileModel(
        userId: currentData.user!.userId,
        gender: _selectedGender,
        age: int.tryParse(_ageController.text),
        height: double.tryParse(_heightController.text),
        weight: double.tryParse(_weightController.text),
      );
      await controller.updateUserProfile(updatedProfile);
    }

    // 운동 목표 업데이트
    if (currentData.user != null && 
        (_selectedWorkoutGoal != null || _selectedWorkoutLevel != null)) {
      final updatedWorkout = WorkoutGoalModel(
        userId: currentData.user!.userId,
        goalType: _selectedWorkoutGoal,
        level: _selectedWorkoutLevel,
        weeklyDays: currentData.workout?.weeklyDays ?? 3,
        dailyDurationMin: currentData.workout?.dailyDurationMin ?? 30,
        preferredTypes: currentData.workout?.preferredTypes ?? ['general'],
      );
      workoutGoalUpdated = await controller.updateWorkoutGoal(updatedWorkout);
    }

    // 식단 목표 업데이트
    if (currentData.user != null && 
        (_selectedDietType != null || _calorieController.text.isNotEmpty)) {
      final updatedDiet = DietGoalModel(
        userId: currentData.user!.userId,
        dailyCalorieTarget: int.tryParse(_calorieController.text),
        dietType: _selectedDietType,
        mealsPerDay: currentData.diet?.mealsPerDay ?? 3,
        dailyWaterMl: currentData.diet?.dailyWaterMl ?? 2000,
        dietaryRestrictions: currentData.diet?.dietaryRestrictions ?? [],
      );
      dietGoalUpdated = await controller.updateDietGoal(updatedDiet);
    }

    if (workoutGoalUpdated) {
      ref.invalidate(aiRecommendedRoutinesProvider);
    }
    if (dietGoalUpdated) {
      ref.invalidate(todayDietPlanProvider);
    }

    // 성공 메시지 표시
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ 프로필이 저장되었습니다.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  bool _validateForm() {
    if (_nicknameController.text.isEmpty) {
      _showError('닉네임을 입력해주세요.');
      return false;
    }
    return true;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ProfileLoadingOverlay(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('프로필 설정'),
          backgroundColor: backgroundColor,
          actions: [
            TextButton(
              onPressed: _saveProfile,
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
        backgroundColor: backgroundColor,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 기본 정보
              _buildSectionTitle('기본 정보'),
              _buildTextField('닉네임', _nicknameController),
              const SizedBox(height: 16),
              
              // 성별 선택
              _buildGenderSelector(),
              const SizedBox(height: 24),
              
              // 신체 정보
              _buildSectionTitle('신체 정보'),
              Row(
                children: [
                  Expanded(child: _buildTextField('나이', _ageController, keyboardType: TextInputType.number)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField('키 (cm)', _heightController, keyboardType: TextInputType.number)),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField('몸무게 (kg)', _weightController, keyboardType: TextInputType.number),
              const SizedBox(height: 24),
              
              // 운동 목표
              _buildSectionTitle('운동 목표'),
              _buildWorkoutGoalSelector(),
              const SizedBox(height: 16),
              _buildWorkoutLevelSelector(),
              const SizedBox(height: 24),
              
              // 식단 목표
              _buildSectionTitle('식단 목표'),
              _buildDietTypeSelector(),
              const SizedBox(height: 16),
              _buildTextField('일일 칼로리 목표', _calorieController, keyboardType: TextInputType.number),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: mainButtonColor,
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: mainButtonColor),
        ),
      ),
    );
  }

  Widget _buildGenderSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('성별', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: RadioListTile<Gender>(
                title: const Text('남성'),
                value: Gender.male,
                groupValue: _selectedGender,
                onChanged: (value) => setState(() => _selectedGender = value),
                activeColor: mainButtonColor,
              ),
            ),
            Expanded(
              child: RadioListTile<Gender>(
                title: const Text('여성'),
                value: Gender.female,
                groupValue: _selectedGender,
                onChanged: (value) => setState(() => _selectedGender = value),
                activeColor: mainButtonColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWorkoutGoalSelector() {
    return DropdownButtonFormField<WorkoutGoalType>(
      value: _selectedWorkoutGoal,
      decoration: const InputDecoration(
        labelText: '운동 목표',
        border: OutlineInputBorder(),
      ),
      items: const [
        WorkoutGoalType.weightLoss,
        WorkoutGoalType.muscleGain,
        WorkoutGoalType.general,
      ].map((goal) {
        return DropdownMenuItem(
          value: goal,
          child: Text(_getWorkoutGoalDisplayName(goal)),
        );
      }).toList(),
      onChanged: (value) => setState(() => _selectedWorkoutGoal = value),
    );
  }

  Widget _buildWorkoutLevelSelector() {
    return DropdownButtonFormField<WorkoutLevel>(
      value: _selectedWorkoutLevel,
      decoration: const InputDecoration(
        labelText: '운동 수준',
        border: OutlineInputBorder(),
      ),
      items: WorkoutLevel.values.map((level) {
        return DropdownMenuItem(
          value: level,
          child: Text(_getWorkoutLevelDisplayName(level)),
        );
      }).toList(),
      onChanged: (value) => setState(() => _selectedWorkoutLevel = value),
    );
  }

  Widget _buildDietTypeSelector() {
    return DropdownButtonFormField<DietType>(
      value: _selectedDietType,
      decoration: const InputDecoration(
        labelText: '식단 유형',
        border: OutlineInputBorder(),
      ),
      items: DietType.values.map((type) {
        return DropdownMenuItem(
          value: type,
          child: Text(_getDietTypeDisplayName(type)),
        );
      }).toList(),
      onChanged: (value) => setState(() => _selectedDietType = value),
    );
  }

  String _getWorkoutGoalDisplayName(WorkoutGoalType goal) {
    switch (goal) {
      case WorkoutGoalType.weightLoss:
        return '다이어트';
      case WorkoutGoalType.muscleGain:
        return '근력향상';
      case WorkoutGoalType.endurance:
        return '건강유지';
      case WorkoutGoalType.strength:
        return '건강유지';
      case WorkoutGoalType.general:
        return '건강유지';
    }
  }

  WorkoutGoalType? _normalizeWorkoutGoal(WorkoutGoalType? goal) {
    switch (goal) {
      case WorkoutGoalType.weightLoss:
      case WorkoutGoalType.muscleGain:
        return goal;
      case WorkoutGoalType.general:
      case WorkoutGoalType.endurance:
      case WorkoutGoalType.strength:
        return WorkoutGoalType.general;
      default:
        return null;
    }
  }

  String _getWorkoutLevelDisplayName(WorkoutLevel level) {
    switch (level) {
      case WorkoutLevel.beginner:
        return '초급';
      case WorkoutLevel.intermediate:
        return '중급';
      case WorkoutLevel.advanced:
        return '고급';
    }
  }

  String _getDietTypeDisplayName(DietType type) {
    switch (type) {
      case DietType.balanced:
        return '균형 잡힌 식단';
      case DietType.lowCarb:
        return '저탄수화물';
      case DietType.highProtein:
        return '고단백';
      case DietType.vegetarian:
        return '채식주의';
      case DietType.vegan:
        return '비건';
      case DietType.keto:
        return '케토';
    }
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _calorieController.dispose();
    super.dispose();
  }
}
