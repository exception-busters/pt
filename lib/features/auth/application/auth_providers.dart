import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
        
        // public.users 테이블에 사용자 정보 저장
        try {
          await Supabase.instance.client.from('users').insert({
            'user_id': response.user!.id,
            'email': email,
            'nickname': nickname ?? '사용자',
            'join_date': DateTime.now().toIso8601String(),
          });
          print('public.users 테이블에 사용자 정보 저장 완료');
        } catch (e) {
          print('public.users 테이블 저장 오류: $e');
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

  void signOut() async {
    await Supabase.instance.client.auth.signOut();
    state = false;
    _controller.add(false);
    _pendingRedirect = null;
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
