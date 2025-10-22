import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  Future<bool> signIn(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 800));
    const validEmail = 'test@example.com';
    const validPassword = '123456';
    final ok = (email == validEmail && password == validPassword);
    if (ok) {
      state = true;
      _controller.add(true);
    }
    return ok;
  }

  void signOut() {
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
