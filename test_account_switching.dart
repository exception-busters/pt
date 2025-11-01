// 계정 전환 테스트를 위한 임시 파일
// 이 파일은 테스트 후 삭제해도 됩니다.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Supabase 초기화
  await Supabase.initialize(
    url: 'https://wkmnnzndtggrlrzjlncn.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndrbW5uem5kdGdncmxyempsbmNuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjExODU1NDIsImV4cCI6MjA3Njc2MTU0Mn0.bd9pcs-4YDyL98YcKhBzq53u2CONtjUv7NdYEcDA-eU',
  );
  
  runApp(const ProviderScope(child: TestApp()));
}

class TestApp extends StatelessWidget {
  const TestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '계정 전환 테스트',
      home: const AccountSwitchTestScreen(),
    );
  }
}

class AccountSwitchTestScreen extends ConsumerStatefulWidget {
  const AccountSwitchTestScreen({super.key});

  @override
  ConsumerState<AccountSwitchTestScreen> createState() => _AccountSwitchTestScreenState();
}

class _AccountSwitchTestScreenState extends ConsumerState<AccountSwitchTestScreen> {
  String _currentUserInfo = '로그인되지 않음';
  String _localDataInfo = '로컬 데이터 없음';

  @override
  void initState() {
    super.initState();
    _updateUserInfo();
    _checkLocalData();
  }

  void _updateUserInfo() {
    final user = Supabase.instance.client.auth.currentUser;
    setState(() {
      if (user != null) {
        _currentUserInfo = '사용자 ID: ${user.id}\n이메일: ${user.email}';
      } else {
        _currentUserInfo = '로그인되지 않음';
      }
    });
  }

  Future<void> _checkLocalData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final user = Supabase.instance.client.auth.currentUser;
      
      if (user != null) {
        final onboardingKey = 'onboarding_completed_${user.id}';
        final profileImageKey = 'profile_image_${user.id}';
        final workoutKey = 'workout_routines_${user.id}';
        
        final onboardingCompleted = prefs.getBool(onboardingKey) ?? false;
        final hasProfileImage = prefs.getString(profileImageKey) != null;
        final hasWorkoutData = prefs.getString(workoutKey) != null;
        
        setState(() {
          _localDataInfo = '''
온보딩 완료: $onboardingCompleted
프로필 이미지: $hasProfileImage
워크아웃 데이터: $hasWorkoutData
사용자 키: ${user.id}
          ''';
        });
      } else {
        setState(() {
          _localDataInfo = '로그인되지 않음 - 로컬 데이터 확인 불가';
        });
      }
    } catch (e) {
      setState(() {
        _localDataInfo = '로컬 데이터 확인 오류: $e';
      });
    }
  }

  Future<void> _signOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
      _updateUserInfo();
      _checkLocalData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그아웃 완료')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('로그아웃 오류: $e')),
      );
    }
  }

  Future<void> _signIn(String email, String password) async {
    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.user != null) {
        _updateUserInfo();
        _checkLocalData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('로그인 완료')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('로그인 오류: $e')),
      );
    }
  }

  Future<void> _clearAllLocalData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      _checkLocalData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('모든 로컬 데이터 삭제 완료')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('로컬 데이터 삭제 오류: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('계정 전환 테스트'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('현재 사용자 정보:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(_currentUserInfo),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('로컬 데이터 상태:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(_localDataInfo),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: _signOut,
                  child: const Text('로그아웃'),
                ),
                ElevatedButton(
                  onPressed: () => _signIn('test1@example.com', 'password123'),
                  child: const Text('테스트 계정 1 로그인'),
                ),
                ElevatedButton(
                  onPressed: () => _signIn('test2@example.com', 'password123'),
                  child: const Text('테스트 계정 2 로그인'),
                ),
                ElevatedButton(
                  onPressed: _clearAllLocalData,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('모든 로컬 데이터 삭제'),
                ),
                ElevatedButton(
                  onPressed: () {
                    _updateUserInfo();
                    _checkLocalData();
                  },
                  child: const Text('새로고침'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}