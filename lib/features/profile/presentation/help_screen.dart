import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_application_1/color.dart';
import 'package:go_router/go_router.dart';

class HelpScreen extends ConsumerWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('도움말'),
        backgroundColor: backgroundColor,
        foregroundColor: mainButtonColor,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 자주 묻는 질문
              const Text(
                '자주 묻는 질문',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: mainButtonColor,
                ),
              ),
              const SizedBox(height: 16),
              
              _buildFAQItem(
                '앱 사용법을 알고 싶어요',
                '홈 화면에서 각 메뉴를 탭하여 운동, 식단, 기록을 관리할 수 있습니다. 프로필에서 개인 목표를 설정하고 알림을 받을 수 있습니다.',
              ),
              
              _buildFAQItem(
                '운동 기록은 어떻게 하나요?',
                '운동 탭에서 원하는 운동을 선택하고 시작 버튼을 누르세요. 운동이 끝나면 자동으로 기록됩니다.',
              ),
              
              _buildFAQItem(
                '식단 기록은 어떻게 하나요?',
                '식단 탭에서 각 식사 시간별로 음식과 칼로리를 입력할 수 있습니다. 추가 버튼을 눌러 새로운 식단을 등록하세요.',
              ),
              
              _buildFAQItem(
                '목표 설정은 어디서 하나요?',
                '프로필 탭에서 "운동 목표 설정"과 "식단 목표 설정"을 통해 개인 맞춤 목표를 설정할 수 있습니다.',
              ),
              
              _buildFAQItem(
                '알림을 받고 싶지 않아요',
                '프로필 > 알림 설정에서 원하는 알림만 선택적으로 켜고 끌 수 있습니다.',
              ),
              
              _buildFAQItem(
                '데이터가 사라졌어요',
                '앱 데이터는 자정을 기준으로 초기화됩니다. 중요한 기록은 기록 탭에서 확인할 수 있습니다.',
              ),
              
              const SizedBox(height: 32),
              
              // 연락처 정보
              const Text(
                '문의하기',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: mainButtonColor,
                ),
              ),
              const SizedBox(height: 16),
              
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  children: [
                    _buildContactItem(
                      Icons.email_outlined,
                      '이메일',
                      'support@ptapp.com',
                      () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('이메일 앱이 열립니다'),
                            backgroundColor: mainButtonColor,
                          ),
                        );
                      },
                    ),
                    const Divider(),
                    _buildContactItem(
                      Icons.phone_outlined,
                      '전화',
                      '1588-1234',
                      () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('전화 앱이 열립니다'),
                            backgroundColor: mainButtonColor,
                          ),
                        );
                      },
                    ),
                    const Divider(),
                    _buildContactItem(
                      Icons.chat_outlined,
                      '카카오톡',
                      '@ptapp',
                      () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('카카오톡이 열립니다'),
                            backgroundColor: mainButtonColor,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // 앱 정보
              const Text(
                '앱 정보',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: mainButtonColor,
                ),
              ),
              const SizedBox(height: 16),
              
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  children: [
                    _buildInfoItem('앱 버전', '1.0.0'),
                    const Divider(),
                    _buildInfoItem('개발사', 'PT App Company'),
                    const Divider(),
                    _buildInfoItem('업데이트', '2024.01.15'),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // 약관 및 정책
              const Text(
                '약관 및 정책',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: mainButtonColor,
                ),
              ),
              const SizedBox(height: 16),
              
              _buildPolicyItem('이용약관', () {
                _showPolicyDialog(context, '이용약관', '이용약관 내용이 여기에 표시됩니다.');
              }),
              
              _buildPolicyItem('개인정보처리방침', () {
                _showPolicyDialog(context, '개인정보처리방침', '개인정보처리방침 내용이 여기에 표시됩니다.');
              }),
              
              _buildPolicyItem('오픈소스 라이선스', () {
                _showPolicyDialog(context, '오픈소스 라이선스', '사용된 오픈소스 라이브러리 정보가 여기에 표시됩니다.');
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            color: mainButtonColor,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              answer,
              style: const TextStyle(
                color: subTextColor,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: mainButtonColor),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          color: mainButtonColor,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: subTextColor),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: subTextColor),
      onTap: onTap,
    );
  }

  Widget _buildInfoItem(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: mainButtonColor,
            ),
          ),
          Text(
            value,
            style: const TextStyle(color: subTextColor),
          ),
        ],
      ),
    );
  }

  Widget _buildPolicyItem(String title, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            color: mainButtonColor,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: subTextColor),
        onTap: onTap,
      ),
    );
  }

  void _showPolicyDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Text(content),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
}