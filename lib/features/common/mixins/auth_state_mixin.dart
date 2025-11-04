import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/application/auth_providers.dart';

/// 인증 상태 변화를 감지하는 공통 믹스인
/// 모든 StateNotifier에서 중복되는 인증 상태 리스닝 로직을 통합
mixin AuthStateMixin<T> on StateNotifier<T> {
  late final Ref _ref;
  AuthState? _cachedAuthState;
  
  /// 믹스인 초기화 - StateNotifier 생성자에서 호출
  void initAuthListener(Ref ref, {
    required VoidCallback onLogout,
    required VoidCallback onLogin,
  }) {
    _ref = ref;
    _cachedAuthState = ref.read(authControllerProvider);
    
    // 인증 상태 변화 감지 (한 번만 설정)
    _ref.listen(authControllerProvider, (previous, next) {
      _cachedAuthState = next; // 캐시 업데이트
      
      // 로그아웃 감지
      if (previous?.isLoggedIn == true && !next.isLoggedIn) {
        onLogout();
      }
      // 로그인 감지  
      else if (previous?.isLoggedIn == false && next.isLoggedIn) {
        onLogin();
      }
    });
  }
  
  /// 현재 로그인 상태 확인 (캐시된 값 사용)
  bool get isLoggedIn => _cachedAuthState?.isLoggedIn ?? false;
  
  /// 현재 프로필 완료 상태 확인 (캐시된 값 사용)
  bool? get profileCompleted => _cachedAuthState?.profileCompleted;
  
  /// 인증 상태 전체 반환 (캐시된 값 사용)
  AuthState? get authState => _cachedAuthState;
}