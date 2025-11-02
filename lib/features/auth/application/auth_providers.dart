import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../common/data/supabase_service.dart';

class AuthState {
  final bool isLoggedIn;
  final bool? profileCompleted; // null = 미확인, true/false = 확인됨
  final bool isLoading;

  const AuthState({
    required this.isLoggedIn,
    this.profileCompleted,
    this.isLoading = false,
  });

  AuthState copyWith({
    bool? isLoggedIn,
    bool? profileCompleted,
    bool? isLoading,
  }) {
    return AuthState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      profileCompleted: profileCompleted ?? this.profileCompleted,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  AuthController() : super(const AuthState(isLoggedIn: false));

  final _controller = StreamController<AuthState>.broadcast();
  String? _pendingRedirect;

  Stream<AuthState> get stream => _controller.stream;

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
          await SupabaseService.createUser(
            userId: response.user!.id,
            email: email,
            nickname: nickname,
            profileCompleted: false,
          );
        } catch (e) {
          print('❌ users 테이블 저장 오류: $e');
          // 트리거가 있다면 이미 저장되었을 수 있으므로 에러를 무시하고 계속 진행
        }
        
        // 회원가입 시에는 profile_completed가 false임을 명시적으로 설정
        state = const AuthState(
          isLoggedIn: true,
          profileCompleted: false,
          isLoading: false,
        );
        _controller.add(state);
        return true;
      } else if (response.session != null) {
        print('회원가입 완료, 자동 로그인 세션 있음: ${response.session}');
        state = const AuthState(
          isLoggedIn: true,
          profileCompleted: false,
          isLoading: false,
        );
        _controller.add(state);
        return true;
      } else {
        print('회원가입 완료, 이메일 확인 필요: ${response}');
        state = const AuthState(isLoggedIn: false, isLoading: false);
        _controller.add(state);
        return false;
      }
    } catch (e) {
      print('SignUp Error: $e');
      state = const AuthState(isLoggedIn: false, isLoading: false);
      _controller.add(state);
      return false;
    }
  }

  Future<bool> signIn(String email, String password) async {
    try {
      // 로딩 상태 시작
      state = state.copyWith(isLoading: true);
      _controller.add(state);

      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        print('✅ 로그인 성공: ${response.user!.id}');
        
        // 1. 사용자 존재 확인 및 생성 (비동기)
        await _ensureUserExistsInDatabase(response.user!);
        
        // 2. profile_completed 상태를 1회만 조회하여 상태에 저장
        final profileCompleted = await _loadProfileCompletedStatus(response.user!);
        
        // 3. 최종 상태 업데이트 (로그인 완료 + profile_completed 정보 포함)
        state = AuthState(
          isLoggedIn: true,
          profileCompleted: profileCompleted,
          isLoading: false,
        );
        _controller.add(state);
        
        print('🎉 로그인 완료! profile_completed: $profileCompleted');
        return true;
      } else {
        state = const AuthState(isLoggedIn: false, isLoading: false);
        _controller.add(state);
        return false;
      }
    } catch (e) {
      print('SignIn Error: $e');
      state = const AuthState(isLoggedIn: false, isLoading: false);
      _controller.add(state);
      return false;
    }
  }

  // profile_completed 상태를 1회만 조회하여 반환
  Future<bool> _loadProfileCompletedStatus(User user) async {
    try {
      print('🔍 profile_completed 상태 1회 조회 중...');
      
      final userInfo = await SupabaseService.getUserInfo(user.id);
      
      if (userInfo != null) {
        final profileCompleted = userInfo['profile_completed'] ?? false;
        final nickname = userInfo['nickname'] ?? '사용자';
        final email = userInfo['email'] ?? '';

        print('📊 ===== 로그인 사용자 프로필 상태 =====');
        print('👤 사용자 ID: ${user.id}');
        print('📧 이메일: $email');
        print('🏷️ 닉네임: $nickname');
        print('✅ 프로필 완성 여부: $profileCompleted');
        print('=====================================');
        
        return profileCompleted;
      }
      
      return false;
    } catch (e) {
      print('❌ profile_completed 상태 확인 실패: $e');
      return false;
    }
  }

  // 로그인 시 users 테이블에 사용자 데이터가 있는지 확인하고 없으면 생성
  Future<void> _ensureUserExistsInDatabase(User user) async {
    try {
      print('🔍 users 테이블에서 사용자 확인: ${user.id}');
      
      final userExists = await SupabaseService.userExists(user.id);
      
      if (!userExists) {
        print('⚠️ users 테이블에 사용자 없음 - 새로 생성');
        
        await SupabaseService.createUser(
          userId: user.id,
          email: user.email ?? '',
          nickname: user.userMetadata?['display_name'] ?? '사용자',
          profileCompleted: false,
        );
      } else {
        print('✅ users 테이블에 사용자 존재 확인');
      }
    } catch (e) {
      print('❌ users 테이블 사용자 확인/생성 실패: $e');
    }
  }



  void signOut() async {
    try {
      // 현재 사용자 정보 저장 (로그아웃 전)
      final currentUser = Supabase.instance.client.auth.currentUser;
      
      // Supabase 로그아웃
      await Supabase.instance.client.auth.signOut();
      
      // 상태 초기화
      state = const AuthState(isLoggedIn: false);
      _controller.add(state);
      _pendingRedirect = null;
      
      // 사용자별 데이터 정리
      if (currentUser != null) {
        await _clearUserSpecificData(currentUser.id);
        // 캐시 정리
        SupabaseService.clearUserCache(currentUser.id);
      }
      
      print('✅ 로그아웃 완료 (캐시 정리됨)');
    } catch (e) {
      print('❌ 로그아웃 중 오류: $e');
      // 오류가 있어도 상태는 업데이트
      state = const AuthState(isLoggedIn: false);
      _controller.add(state);
      _pendingRedirect = null;
    }
  }

  // profile_completed 상태 업데이트 (온보딩 완료 시 호출)
  void updateProfileCompleted(bool completed) {
    if (state.isLoggedIn) {
      state = state.copyWith(profileCompleted: completed);
      _controller.add(state);
      print('✅ AuthController: profile_completed 상태 업데이트 = $completed');
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

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) => AuthController(),
);

// 편의를 위한 개별 프로바이더들 (필요시에만 사용)
final isLoggedInProvider = Provider<bool>((ref) => ref.watch(authControllerProvider).isLoggedIn);
final profileCompletedProvider = Provider<bool?>((ref) => ref.watch(authControllerProvider).profileCompleted);
final authLoadingProvider = Provider<bool>((ref) => ref.watch(authControllerProvider).isLoading);
