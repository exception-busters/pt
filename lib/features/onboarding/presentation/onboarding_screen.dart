import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_application_1/color.dart';
import 'package:flutter_application_1/features/onboarding/application/onboarding_providers.dart';
import 'package:flutter_application_1/features/onboarding/domain/models/onboarding_data.dart';
import 'package:flutter_application_1/features/onboarding/presentation/widgets/number_picker_widget.dart';
import 'package:flutter_application_1/features/profile/application/profile_providers.dart';
import 'package:flutter_application_1/features/profile/application/complete_profile_providers.dart';
import 'package:flutter_application_1/features/auth/application/auth_providers.dart';
import 'package:go_router/go_router.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 5) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // 진행 표시기
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: List.generate(6, (index) {
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: EdgeInsets.only(
                        right: index < 5 ? 8 : 0,
                      ),
                      decoration: BoxDecoration(
                        color: index <= _currentPage ? mainButtonColor : borderColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),
            
            // 페이지 내용
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                children: [
                  _WelcomeScreen(onNext: _nextPage),
                  _GenderSelectionScreen(onNext: _nextPage),
                  _PersonalInfoScreen(onNext: _nextPage),
                  _DietPreferencesScreen(onNext: _nextPage),
                  _WorkoutPreferencesScreen(onNext: _nextPage),
                  _CompletionScreen(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 1. 환영 화면
class _WelcomeScreen extends ConsumerWidget {
  final VoidCallback onNext;

  const _WelcomeScreen({required this.onNext});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.fitness_center,
            size: 80,
            color: mainButtonColor,
          ),
          const SizedBox(height: 32),
          const Text(
            'PT앱을 처음 사용해보시나요?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: mainButtonColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            '지금부터 님에게 딱 맞는 목표 추천을 위한\n기본 정보를 등록할게요!',
            style: TextStyle(
              fontSize: 16,
              color: subTextColor,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onNext,
              child: const Text(
                '시작하기',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 2. 성별 선택 화면
class _GenderSelectionScreen extends ConsumerWidget {
  final VoidCallback onNext;

  const _GenderSelectionScreen({required this.onNext});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboardingData = ref.watch(onboardingProvider);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const SizedBox(height: 40),
          const Text(
            '성별을 선택해주세요',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: mainButtonColor,
            ),
          ),
          const SizedBox(height: 48),
          
          Row(
            children: [
              // 남성 선택
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    ref.read(onboardingProvider.notifier).updateGender(Gender.male);
                    Future.delayed(const Duration(milliseconds: 200), onNext);
                  },
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: onboardingData.gender == Gender.male 
                          ? Colors.blue.withOpacity(0.1) 
                          : backgroundColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: onboardingData.gender == Gender.male 
                            ? Colors.blue 
                            : borderColor,
                        width: onboardingData.gender == Gender.male ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.male,
                          size: 80,
                          color: onboardingData.gender == Gender.male 
                              ? Colors.blue 
                              : Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '남성',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: onboardingData.gender == Gender.male 
                                ? Colors.blue 
                                : subTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 16),
              
              // 여성 선택
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    ref.read(onboardingProvider.notifier).updateGender(Gender.female);
                    Future.delayed(const Duration(milliseconds: 200), onNext);
                  },
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: onboardingData.gender == Gender.female 
                          ? Colors.pink.withOpacity(0.1) 
                          : backgroundColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: onboardingData.gender == Gender.female 
                            ? Colors.pink 
                            : borderColor,
                        width: onboardingData.gender == Gender.female ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.female,
                          size: 80,
                          color: onboardingData.gender == Gender.female 
                              ? Colors.pink 
                              : Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '여성',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: onboardingData.gender == Gender.female 
                                ? Colors.pink 
                                : subTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// 3. 개인정보 입력 화면
class _PersonalInfoScreen extends ConsumerStatefulWidget {
  final VoidCallback onNext;

  const _PersonalInfoScreen({required this.onNext});

  @override
  ConsumerState<_PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends ConsumerState<_PersonalInfoScreen> {
  int age = 25;
  int weight = 70;
  int height = 170;

  @override
  void initState() {
    super.initState();
    // 초기값을 provider에 자동으로 저장
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final onboardingData = ref.read(onboardingProvider);
      if (onboardingData.age == null) {
        ref.read(onboardingProvider.notifier).updateAge(age);
      }
      if (onboardingData.weight == null) {
        ref.read(onboardingProvider.notifier).updateWeight(weight.toDouble());
      }
      if (onboardingData.height == null) {
        ref.read(onboardingProvider.notifier).updateHeight(height.toDouble());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final onboardingData = ref.watch(onboardingProvider);

    final bool canProceed = onboardingData.age != null &&
                           onboardingData.weight != null &&
                           onboardingData.height != null;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const SizedBox(height: 20),
          const Text(
            '정보를 입력해주세요',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: mainButtonColor,
            ),
          ),
          const SizedBox(height: 24),
          
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  NumberPickerWidget(
                    label: '만 나이',
                    unit: '세',
                    minValue: 15,
                    maxValue: 80,
                    initialValue: age,
                    onChanged: (value) {
                      setState(() {
                        age = value;
                      });
                      ref.read(onboardingProvider.notifier).updateAge(value);
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  NumberPickerWidget(
                    label: '몸무게',
                    unit: 'kg',
                    minValue: 30,
                    maxValue: 150,
                    initialValue: weight,
                    onChanged: (value) {
                      setState(() {
                        weight = value;
                      });
                      ref.read(onboardingProvider.notifier).updateWeight(value.toDouble());
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  NumberPickerWidget(
                    label: '키',
                    unit: 'cm',
                    minValue: 140,
                    maxValue: 220,
                    initialValue: height,
                    onChanged: (value) {
                      setState(() {
                        height = value;
                      });
                      ref.read(onboardingProvider.notifier).updateHeight(value.toDouble());
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: canProceed ? widget.onNext : null,
              child: const Text(
                '다음',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// 4. 식단 목표 선택 화면
class _DietPreferencesScreen extends ConsumerWidget {
  final VoidCallback onNext;

  const _DietPreferencesScreen({required this.onNext});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboardingData = ref.watch(onboardingProvider);

    final bool canProceed = onboardingData.dietGoal != null &&
                           onboardingData.mealsPerDay != null;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const SizedBox(height: 40),
          const Text(
            '식단 목표를 선택해주세요',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: mainButtonColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            '목표에 맞는 식단을 AI가 추천해드립니다',
            style: TextStyle(
              fontSize: 16,
              color: subTextColor,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 식단 목표 선택
                  const Text(
                    '식단 목표',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: mainButtonColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...DietGoal.values.map((goal) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: RadioListTile<DietGoal>(
                        title: Text(
                          goal.displayName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        value: goal,
                        groupValue: onboardingData.dietGoal,
                        onChanged: (value) {
                          if (value != null) {
                            ref.read(onboardingProvider.notifier).updateDietGoal(value);
                          }
                        },
                        activeColor: mainButtonColor,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color: onboardingData.dietGoal == goal
                                ? mainButtonColor
                                : borderColor,
                          ),
                        ),
                        tileColor: onboardingData.dietGoal == goal
                            ? mainButtonColor.withOpacity(0.1)
                            : Colors.transparent,
                      ),
                    );
                  }),

                  const SizedBox(height: 32),

                  // 하루 식사 횟수 선택
                  const Text(
                    '하루 식사 횟수',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: mainButtonColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...MealsPerDay.values.map((meals) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: RadioListTile<MealsPerDay>(
                        title: Text(
                          meals.displayName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        value: meals,
                        groupValue: onboardingData.mealsPerDay,
                        onChanged: (value) {
                          if (value != null) {
                            ref.read(onboardingProvider.notifier).updateMealsPerDay(value);
                          }
                        },
                        activeColor: mainButtonColor,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color: onboardingData.mealsPerDay == meals
                                ? mainButtonColor
                                : borderColor,
                          ),
                        ),
                        tileColor: onboardingData.mealsPerDay == meals
                            ? mainButtonColor.withOpacity(0.1)
                            : Colors.transparent,
                      ),
                    );
                  }),

                  const SizedBox(height: 32),

                  // 목표 칼로리 (선택사항)
                  const Text(
                    '목표 칼로리 (선택사항)',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: mainButtonColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '입력하지 않으면 체중과 목표를 기반으로 자동 계산됩니다',
                    style: TextStyle(
                      fontSize: 14,
                      color: subTextColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: '예) 2000',
                      suffixText: 'kcal',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (value) {
                      final calories = int.tryParse(value);
                      if (calories != null) {
                        ref.read(onboardingProvider.notifier).updateTargetCalories(calories);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: canProceed ? onNext : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                '다음',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 5. 운동 목적 및 수준 선택 화면
class _WorkoutPreferencesScreen extends ConsumerWidget {
  final VoidCallback onNext;

  const _WorkoutPreferencesScreen({required this.onNext});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboardingData = ref.watch(onboardingProvider);

    final bool canProceed = onboardingData.workoutGoal != null &&
                           onboardingData.workoutLevel != null &&
                           onboardingData.experienceDuration != null;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const SizedBox(height: 40),
          const Text(
            '운동 목적과 수준을 선택해주세요',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: mainButtonColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 운동 목적
                  const Text(
                    '운동 목적',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: mainButtonColor,
                    ),
                  ),
                  const SizedBox(height: 16),

                  ...const [
                    WorkoutGoal.weightLoss,
                    WorkoutGoal.muscleGain,
                    WorkoutGoal.healthMaintenance,
                  ].map((goal) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: RadioListTile<WorkoutGoal>(
                        title: Text(
                          goal.displayName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        value: goal,
                        groupValue: onboardingData.workoutGoal,
                        onChanged: (value) {
                          if (value != null) {
                            ref.read(onboardingProvider.notifier).updateWorkoutGoal(value);
                          }
                        },
                        activeColor: mainButtonColor,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color: onboardingData.workoutGoal == goal 
                                ? mainButtonColor 
                                : borderColor,
                          ),
                        ),
                        tileColor: onboardingData.workoutGoal == goal 
                            ? mainButtonColor.withOpacity(0.1) 
                            : backgroundColor,
                      ),
                    );
                  }).toList(),
                  
                  const SizedBox(height: 32),
                  
                  // 운동 수준
                  const Text(
                    '운동 수준',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: mainButtonColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  ...WorkoutLevel.values.map((level) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: RadioListTile<WorkoutLevel>(
                        title: Text(
                          level.displayName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        value: level,
                        groupValue: onboardingData.workoutLevel,
                        onChanged: (value) {
                          if (value != null) {
                            ref.read(onboardingProvider.notifier).updateWorkoutLevel(value);
                          }
                        },
                        activeColor: mainButtonColor,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color: onboardingData.workoutLevel == level 
                                ? mainButtonColor 
                                : borderColor,
                          ),
                        ),
                        tileColor: onboardingData.workoutLevel == level 
                            ? mainButtonColor.withOpacity(0.1) 
                            : backgroundColor,
                      ),
                    );
                  }).toList(),

                  const SizedBox(height: 32),

                  // 운동 경험 기간
                  const Text(
                    '운동 경험 기간',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: mainButtonColor,
                    ),
                  ),
                  const SizedBox(height: 16),

                  ...ExperienceDuration.values.map((duration) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: RadioListTile<ExperienceDuration>(
                        title: Text(
                          duration.displayName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        value: duration,
                        groupValue: onboardingData.experienceDuration,
                        onChanged: (value) {
                          if (value != null) {
                            ref.read(onboardingProvider.notifier).updateExperienceDuration(value);
                          }
                        },
                        activeColor: mainButtonColor,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color: onboardingData.experienceDuration == duration
                                ? mainButtonColor
                                : borderColor,
                          ),
                        ),
                        tileColor: onboardingData.experienceDuration == duration
                            ? mainButtonColor.withOpacity(0.1)
                            : backgroundColor,
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: canProceed ? onNext : null,
              child: const Text(
                '완료',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 6. 완료 화면
class _CompletionScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.check_circle,
            size: 100,
            color: Colors.green,
          ),
          const SizedBox(height: 32),
          const Text(
            '모든 정보의 등록이 완료되었어요',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: mainButtonColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            '지금부터 PT앱과 함께 운동해요!',
            style: TextStyle(
              fontSize: 16,
              color: subTextColor,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                // ⭐ 사용자 로그인 상태 확인 (중요!)
                final authState = ref.read(authControllerProvider);
                if (!authState.isLoggedIn) {
                  print('❌ 사용자가 로그인되지 않았습니다. 로그인 페이지로 이동합니다.');

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('로그인이 필요합니다. 다시 로그인해주세요.'),
                        backgroundColor: Colors.red,
                        duration: Duration(seconds: 3),
                      ),
                    );

                    // 로그인 페이지로 이동
                    context.go('/');
                  }
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
                  // 온보딩 데이터 저장 (서버에 profile_completed = true 업데이트 포함)
                  await ref.read(onboardingProvider.notifier).saveOnboardingData();

                  // AuthController의 상태 즉시 업데이트 (DB 재조회 없이)
                  ref.read(authControllerProvider.notifier).updateProfileCompleted(true);

                  // ⭐ 프로필 데이터 즉시 새로고침 (운동 목표, 식단 목표 등)
                  await ref.read(completeUserDataProvider.notifier).loadUserData();

                  // 관련 프로바이더들 새로고침 (서버 상태 동기화)
                  ref.invalidate(userProfileProvider);
                  ref.invalidate(userProfileControllerProvider);

                  print('🎉 온보딩 완료! 서버 상태 업데이트 및 프로필 데이터 새로고침 완료');

                  if (context.mounted) {
                    // 로딩 다이얼로그 닫기
                    Navigator.of(context).pop();

                    // 온보딩 화면을 완전히 제거하고 홈 화면으로 이동
                    context.go('/app/home');
                  }
                } catch (e) {
                  print('❌ 온보딩 저장 실패: $e');
                  
                  if (context.mounted) {
                    // 로딩 다이얼로그 닫기
                    Navigator.of(context).pop();
                    
                    // 에러 메시지 표시
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('저장 중 오류가 발생했습니다. 다시 시도해주세요.\n오류: $e'),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 5),
                      ),
                    );
                  }
                }
              },
              child: const Text(
                '확인',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
