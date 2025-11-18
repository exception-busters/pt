import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/color.dart';

/// 운동 시작 전 가이드라인 화면
class ExerciseGuideDialog extends StatefulWidget {
  final VoidCallback onComplete;

  static const String _prefKey = 'exercise_guide_dont_show';

  const ExerciseGuideDialog({
    Key? key,
    required this.onComplete,
  }) : super(key: key);

  @override
  State<ExerciseGuideDialog> createState() => _ExerciseGuideDialogState();

  /// 가이드를 다시 표시해야 하는지 확인
  static Future<bool> shouldShowGuide() async {
    final prefs = await SharedPreferences.getInstance();
    final dontShow = prefs.getBool(_prefKey) ?? false;
    return !dontShow;
  }

  /// 가이드 설정 초기화 (테스트용)
  static Future<void> resetGuide() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKey);
    print('✅ 운동 가이드 설정 초기화됨');
  }
}

class _ExerciseGuideDialogState extends State<ExerciseGuideDialog> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _dontShowAgain = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _onComplete() async {
    if (_dontShowAgain) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(ExerciseGuideDialog._prefKey, true);
      print('✅ 운동 가이드 "다시 보지 않기" 설정 저장됨');
    }
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: backgroundColor,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.75,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 진행 표시기
            Row(
              children: List.generate(4, (index) {
                return Expanded(
                  child: Container(
                    height: 4,
                    margin: EdgeInsets.only(right: index < 3 ? 8 : 0),
                    decoration: BoxDecoration(
                      color: index <= _currentPage ? mainButtonColor : borderColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),

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
                  _buildPage1(), // 카메라 거리
                  _buildPage2(), // 복장
                  _buildPage3(), // 조명 및 각도
                  _buildPage4(), // 완료
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 하단 버튼 및 체크박스
            if (_currentPage == 3) ...[
              // 마지막 페이지: 다시 보지 않기 체크박스
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: _dontShowAgain,
                        onChanged: (value) {
                          setState(() {
                            _dontShowAgain = value ?? false;
                          });
                        },
                        activeColor: mainButtonColor,
                      ),
                      const Text(
                        '다시 보지 않기',
                        style: TextStyle(
                          fontSize: 14,
                          color: subTextColor,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: _onComplete,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: mainButtonColor,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      '시작하기',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              // 다음 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: mainButtonColor,
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
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPage1() {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.videocam,
            size: 80,
            color: mainButtonColor,
          ),
          const SizedBox(height: 24),
          const Text(
            '카메라와의 적정 거리',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: mainButtonColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            '전신이 잘 보이도록 카메라와\n1.5~2m 거리를 유지하세요',
            style: TextStyle(
              fontSize: 16,
              color: subTextColor,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: mainButtonColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: mainButtonColor.withValues(alpha: 0.3)),
            ),
            child: const Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.check_circle, color: mainButtonColor, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '머리부터 발끝까지 전부 보여야 합니다',
                        style: TextStyle(fontSize: 14, color: mainButtonColor),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.check_circle, color: mainButtonColor, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '너무 가까우면 정확한 측정이 어렵습니다',
                        style: TextStyle(fontSize: 14, color: mainButtonColor),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.check_circle, color: mainButtonColor, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '좌우로 충분한 공간을 확보하세요',
                        style: TextStyle(fontSize: 14, color: mainButtonColor),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage2() {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.checkroom,
            size: 80,
            color: mainButtonColor,
          ),
          const SizedBox(height: 24),
          const Text(
            '추천하는 복장',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: mainButtonColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            '몸의 움직임이 잘 보이는\n복장을 착용하세요',
            style: TextStyle(
              fontSize: 16,
              color: subTextColor,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '✅ 추천',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '• 몸에 딱 맞는 운동복\n• 민소매 또는 반팔\n• 반바지 또는 레깅스',
                  style: TextStyle(fontSize: 14, color: mainButtonColor),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '❌ 피해야 할 것',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '• 헐렁한 옷\n• 두꺼운 겉옷\n• 관절을 가리는 긴 옷',
                  style: TextStyle(fontSize: 14, color: mainButtonColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage3() {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.lightbulb,
            size: 80,
            color: mainButtonColor,
          ),
          const SizedBox(height: 24),
          const Text(
            '조명 및 카메라 각도',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: mainButtonColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            '밝은 조명과 올바른 각도로\n정확한 자세 측정이 가능합니다',
            style: TextStyle(
              fontSize: 16,
              color: subTextColor,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: mainButtonColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: mainButtonColor.withValues(alpha: 0.3)),
            ),
            child: const Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.wb_sunny, color: mainButtonColor, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '충분히 밝은 조명을 사용하세요',
                        style: TextStyle(fontSize: 14, color: mainButtonColor),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.camera, color: mainButtonColor, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '카메라는 가슴 높이에 수평으로 설치',
                        style: TextStyle(fontSize: 14, color: mainButtonColor),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.settings_backup_restore, color: mainButtonColor, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '삼각대 사용을 강력히 추천합니다',
                        style: TextStyle(fontSize: 14, color: mainButtonColor),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.contrast, color: mainButtonColor, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '역광을 피하고 정면 조명을 사용하세요',
                        style: TextStyle(fontSize: 14, color: mainButtonColor),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage4() {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.fitness_center,
            size: 80,
            color: mainButtonColor,
          ),
          const SizedBox(height: 24),
          const Text(
            '준비 완료!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: mainButtonColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            '이제 가이드 영상을 보시고\n정확한 자세로 운동을 시작하세요',
            style: TextStyle(
              fontSize: 16,
              color: subTextColor,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: mainButtonColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: mainButtonColor.withValues(alpha: 0.3)),
            ),
            child: const Column(
              children: [
                Text(
                  '💡 팁',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: mainButtonColor,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  '• 운동 전 충분한 스트레칭\n• 물을 미리 준비하세요\n• 운동 공간을 확보하세요\n• 집중력을 유지하세요',
                  style: TextStyle(
                    fontSize: 14,
                    color: mainButtonColor,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
