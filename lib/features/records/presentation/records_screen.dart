import 'package:flutter/material.dart';
import 'package:flutter_application_1/color.dart';
import 'package:go_router/go_router.dart';

class RecordsScreen extends StatelessWidget {
  const RecordsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('기록'),
        backgroundColor: backgroundColor,
        foregroundColor: mainButtonColor,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              // 이번 주 목표 달성률
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: mainButtonColor,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Column(
                  children: [
                    Text(
                      '이번 주 목표 달성률',
                      style: TextStyle(fontSize: 18, color: Colors.white70),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '75%',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '5일 중 4일 달성',
                      style: TextStyle(fontSize: 14, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 통계 카드
              Row(
                children: const [
                  Expanded(
                    child: _StatCard(
                      '운동 시간',
                      '150분',
                      Icons.timer,
                      mainButtonColor,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: _StatCard(
                      '소모 칼로리',
                      '2,400kcal',
                      Icons.local_fire_department,
                      secondaryButtonColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: const [
                  Expanded(
                    child: _StatCard(
                      '체중 변화',
                      '-1.2kg',
                      Icons.trending_down,
                      secondaryButtonColor,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: _StatCard(
                      '운동 일수',
                      '4일',
                      Icons.calendar_today,
                      mainButtonColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 최근 기록 제목
              const Text(
                '최근 기록',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: mainButtonColor,
                ),
              ),
              const SizedBox(height: 16),

              // 최근 기록 리스트
              Column(
                children: [
                  _RecordCard(
                    date: '어제',
                    record: '운동 45분 완료',
                    icon: Icons.check_circle,
                    color: mainButtonColor,
                    onTap: () => context.go('/app/records/detail/yesterday'),
                  ),
                  _RecordCard(
                    date: '2일 전',
                    record: '식단 목표 달성',
                    icon: Icons.check_circle,
                    color: mainButtonColor,
                    onTap: () => context.go('/app/records/detail/two-days-ago'),
                  ),
                  _RecordCard(
                    date: '3일 전',
                    record: '운동 30분 완료',
                    icon: Icons.check_circle,
                    color: mainButtonColor,
                    onTap: () => context.go('/app/records/detail/three-days-ago'),
                  ),
                  _RecordCard(
                    date: '4일 전',
                    record: '목표 미달성',
                    icon: Icons.cancel,
                    color: secondaryButtonColor,
                    onTap: () => context.go('/app/records/detail/four-days-ago'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard(this.title, this.value, this.icon, this.color, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: subTextColor),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}

class _RecordCard extends StatelessWidget {
  final String date;
  final String record;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _RecordCard({
    required this.date,
    required this.record,
    required this.icon,
    required this.color,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    date,
                    style: const TextStyle(fontSize: 14, color: subTextColor),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    record,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: mainButtonColor),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
