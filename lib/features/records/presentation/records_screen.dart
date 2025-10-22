import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RecordsScreen extends StatelessWidget {
  const RecordsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('기록'),
        backgroundColor: const Color(0xFFE8F5E8),
        foregroundColor: const Color(0xFF4A6741),
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
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF9800), Color(0xFFF57C00)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Column(
                  children: [
                    Text(
                      '이번 주 목표 달성률',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white70,
                      ),
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
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: const [
                  Expanded(
                    child: _StatCard('운동 시간', '150분', Icons.timer, Color(0xFF4CAF50)),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: _StatCard('소모 칼로리', '2,400kcal', Icons.local_fire_department, Color(0xFFFF5722)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: const [
                  Expanded(
                    child: _StatCard('체중 변화', '-1.2kg', Icons.trending_down, Color(0xFF2196F3)),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: _StatCard('운동 일수', '4일', Icons.calendar_today, Color(0xFF9C27B0)),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                '최근 기록',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4A6741),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children: [
                    _RecordCard(
                      date: '어제',
                      record: '운동 45분 완료',
                      icon: Icons.check_circle,
                      color: const Color(0xFF4CAF50),
                      onTap: () => context.go('/app/records/detail/yesterday'),
                    ),
                    _RecordCard(
                      date: '2일 전',
                      record: '식단 목표 달성',
                      icon: Icons.check_circle,
                      color: const Color(0xFF4CAF50),
                      onTap: () => context.go('/app/records/detail/two-days-ago'),
                    ),
                    _RecordCard(
                      date: '3일 전',
                      record: '운동 30분 완료',
                      icon: Icons.check_circle,
                      color: const Color(0xFF4CAF50),
                      onTap: () => context.go('/app/records/detail/three-days-ago'),
                    ),
                    _RecordCard(
                      date: '4일 전',
                      record: '목표 미달성',
                      icon: Icons.cancel,
                      color: const Color(0xFFFF5722),
                      onTap: () => context.go('/app/records/detail/four-days-ago'),
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

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard(this.title, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B8B6B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordCard extends StatelessWidget {
  const _RecordCard({
    required this.date,
    required this.record,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String date;
  final String record;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
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
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B8B6B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    record,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4A6741),
                    ),
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
