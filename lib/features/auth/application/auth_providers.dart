import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthController extends StateNotifier<bool> {
  AuthController() : super(false);

  final _controller = StreamController<bool>.broadcast();
  String? _pendingRedirect;

  Stream<bool> get stream => _controller.stream;

  void setRedirect(String path) {
    _pendingRedirect = path;
  }

  String? peekRedirect() => _pendingRedirect;

  String? takeRedirect() {
    final value = _pendingRedirect;
    _pendingRedirect = null;
    return value;
  }
  Future<bool> signUp(String email, String password, {String? nickname}) async {
    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: {'display_name': nickname},
      );
      
      if (response.user != null) {
        print('회원가입 완료, user: ${response.user}');
        
        // Users 테이블에 사용자 정보 저장 (profile_completed는 기본값 false)
        try {
          await Supabase.instance.client.from('users').insert({
            'user_id': response.user!.id,
            'email': email,
            'nickname': nickname ?? '사용자',
            'join_date': DateTime.now().toIso8601String(),
            'profile_completed': false, // 명시적으로 false 설정
          });
          print('✅ users 테이블에 사용자 정보 저장 완료 (profile_completed: false)');
        } catch (e) {
          print('❌ users 테이블 저장 오류: $e');
          // 트리거가 있다면 이미 저장되었을 수 있으므로 에러를 무시하고 계속 진행
        }
        
        state = true;
        _controller.add(true);
        return true;
      } else if (response.session != null) {
        print('회원가입 완료, 자동 로그인 세션 있음: ${response.session}');
        state = true;
        _controller.add(true);
        return true;
      } else {
        print('회원가입 완료, 이메일 확인 필요: ${response}');
        state = false;
        _controller.add(false);
        return false;
      }
    } catch (e) {
      print('SignUp Error: $e');
      state = false;
      _controller.add(false);
      return false;
    }
  }

  Future<bool> signIn(String email, String password) async {
    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        print('✅ 로그인 성공: ${response.user!.id}');
        
        // 로그인 후 users 테이블에 사용자 데이터가 있는지 확인하고 없으면 생성
        await _ensureUserExistsInDatabase(response.user!);
        
        // 로그인 후 profile_completed 상태 확인 및 출력
        await _checkAndPrintProfileStatus(response.user!);
        
        // 상태 업데이트 (이것이 라우터의 리다이렉트를 트리거함)
        state = true;
        _controller.add(true);
        return true;
      } else {
        state = false;
        _controller.add(false);
        return false;
      }
    } catch (e) {
      print('SignIn Error: $e');
      state = false;
      _controller.add(false);
      return false;
    }
  }

  // 로그인 시 users 테이블에 사용자 데이터가 있는지 확인하고 없으면 생성
  Future<void> _ensureUserExistsInDatabase(User user) async {
    try {
      print('🔍 users 테이블에서 사용자 확인: ${user.id}');
      
      // 사용자가 users 테이블에 있는지 확인
      final existingUser = await Supabase.instance.client
          .from('users')
          .select('user_id')
          .eq('user_id', user.id)
          .maybeSingle();

      if (existingUser == null) {
        print('⚠️ users 테이블에 사용자 없음 - 새로 생성');
        
        // 사용자가 없으면 생성
        await Supabase.instance.client.from('users').insert({
          'user_id': user.id,
          'email': user.email ?? '',
          'nickname': user.userMetadata?['display_name'] ?? '사용자',
          'join_date': DateTime.now().toIso8601String(),
          'profile_completed': false,
        });
        
        print('✅ users 테이블에 사용자 생성 완료 (profile_completed: false)');
      } else {
        print('✅ users 테이블에 사용자 존재 확인');
      }
    } catch (e) {
      print('❌ users 테이블 사용자 확인/생성 실패: $e');
    }
  }

  // 로그인 후 profile_completed 상태 확인 및 콘솔 출력
  Future<void> _checkAndPrintProfileStatus(User user) async {
    try {
      print('🔍 profile_completed 상태 확인 중...');
      
      final response = await Supabase.instance.client
          .from('users')
          .select('profile_completed, nickname, email')
          .eq('user_id', user.id)
          .single();

      final profileCompleted = response['profile_completed'] ?? false;
      final nickname = response['nickname'] ?? '사용자';
      final email = response['email'] ?? '';

      print('📊 ===== 로그인 사용자 프로필 상태 =====');
      print('👤 사용자 ID: ${user.id}');
      print('📧 이메일: $email');
      print('🏷️ 닉네임: $nickname');
      print('✅ 프로필 완성 여부: $profileCompleted');
      print('=====================================');
      
    } catch (e) {
      print('❌ profile_completed 상태 확인 실패: $e');
    }
  }

  void signOut() async {
    try {
      // 현재 사용자 정보 저장 (로그아웃 전)
      final currentUser = Supabase.instance.client.auth.currentUser;
      
      // Supabase 로그아웃
      await Supabase.instance.client.auth.signOut();
      
      // 상태 업데이트
      state = false;
      _controller.add(false);
      _pendingRedirect = null;
      
      // 사용자별 로컬 데이터 정리 (선택적)
      if (currentUser != null) {
        await _clearUserSpecificData(currentUser.id);
      }
      
      print('✅ 로그아웃 완료');
    } catch (e) {
      print('❌ 로그아웃 중 오류: $e');
      // 오류가 있어도 상태는 업데이트
      state = false;
      _controller.add(false);
      _pendingRedirect = null;
    }
  }

  Future<void> _clearUserSpecificData(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 사용자별 프로필 이미지 키 삭제
      await prefs.remove('profile_image_$userId');
      
      // 필요시 다른 사용자별 데이터도 정리 가능
      // 온보딩 데이터는 OnboardingNotifier에서 처리됨
      
      print('✅ 사용자별 로컬 데이터 정리 완료');
    } catch (e) {
      print('❌ 사용자별 데이터 정리 실패: $e');
    }
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, bool>(
  (ref) => AuthController(),
);
