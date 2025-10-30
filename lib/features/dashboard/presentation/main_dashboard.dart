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
    final matchIndex = _tabs.indexWhere((tab) => location.startsWith(tab.path));
    return matchIndex >= 0 ? matchIndex : 0;
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
          if (index == currentIndex) return;
          context.go(_tabs[index].path);
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
