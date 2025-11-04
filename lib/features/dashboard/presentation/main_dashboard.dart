import 'package:flutter/material.dart';
import 'package:flutter_application_1/color.dart';
import 'package:go_router/go_router.dart';

class MainDashboard extends StatelessWidget {
  const MainDashboard({super.key, required this.child, required this.location});

  final Widget child;
  final String location;

  static const _tabs = [
    _TabItem(path: '/app/home', icon: Icons.home, label: '홈'),
    _TabItem(path: '/app/diet', icon: Icons.restaurant, label: '식단'),
    _TabItem(path: '/app/workout', icon: Icons.fitness_center, label: '운동'),
    _TabItem(path: '/app/records', icon: Icons.analytics, label: '기록'),
    _TabItem(path: '/app/profile', icon: Icons.person, label: '프로필'),
  ];

  int _locationToIndex() {
    // 정확한 경로 매칭: 하위 경로도 고려
    final currentPath = location.split('?').first; // 쿼리 파라미터 제거
    
    for (int i = 0; i < _tabs.length; i++) {
      final tab = _tabs[i];
      // 정확히 일치하거나 하위 경로인 경우
      if (currentPath == tab.path || currentPath.startsWith('${tab.path}/')) {
        return i;
      }
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _locationToIndex();

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: currentIndex,
        onTap: (index) {
          final targetPath = _tabs[index].path;
          final currentPath = location.split('?').first; // 쿼리 파라미터 제거
          
          // 현재 경로와 같으면 무시
          if (currentPath == targetPath || currentPath.startsWith('$targetPath/')) {
            return;
          }
          
          // 하위 경로에서 탭 전환 시 루트 경로로 이동
          try {
            context.go(targetPath);
          } catch (e) {
            // 네비게이션 오류 시 fallback
            debugPrint('탭 전환 오류: $e');
          }
        },
        backgroundColor: backgroundColor,
        selectedItemColor: mainButtonColor,
        unselectedItemColor: subTextColor,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
        ),
        items: _tabs
            .map(
              (tab) => BottomNavigationBarItem(
                icon: Icon(tab.icon),
                label: tab.label,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _TabItem {
  const _TabItem({required this.path, required this.icon, required this.label});
  final String path;
  final IconData icon;
  final String label;
}
