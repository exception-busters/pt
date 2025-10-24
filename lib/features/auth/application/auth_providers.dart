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
  Future<bool> signUp(String email, String password, {String? name}) async {
    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: {'name': name},
      );
      if (response.user != null) {
        print('회원가입 완료, user: ${response.user}');
      } else if (response.session != null) {
        print('회원가입 완료, 자동 로그인 세션 있음: ${response.session}');
      } else {
        print('회원가입 완료, 이메일 확인 필요: ${response}');
      }
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
