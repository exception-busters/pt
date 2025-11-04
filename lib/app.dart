import 'package:flutter/material.dart';
import 'screens/exercise_screen.dart';

/// 운동 자세 교정 앱의 메인 위젯
class ExerciseApp extends StatelessWidget {
  const ExerciseApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI 자세 교정',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const ExerciseScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

