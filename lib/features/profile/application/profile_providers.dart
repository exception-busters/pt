import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/user_service.dart';
import '../../auth/application/auth_providers.dart';
import '../../common/mixins/auth_state_mixin.dart';

class ProfileImageController extends StateNotifier<String?> with AuthStateMixin<String?> {
  ProfileImageController(Ref ref) : super(null) {
    // 공통 인증 상태 리스너 초기화
    initAuthListener(
      ref,
      onLogout: () => state = null,
      onLogin: _loadProfileImage,
    );
    
    _loadProfileImage();
  }

  String _getProfileImageKey() {
    // 현재 사용자 ID를 기반으로 키 생성
    final user = Supabase.instance.client.auth.currentUser;
    return user != null ? 'profile_image_${user.id}' : 'profile_image_default';
  }

  Future<void> _loadProfileImage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final imagePath = prefs.getString(_getProfileImageKey());
      if (imagePath != null && File(imagePath).existsSync()) {
        state = imagePath;
      } else {
        state = null;
      }
    } catch (e) {
      state = null;
    }
  }

  Future<void> updateProfileImage(String imagePath) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_getProfileImageKey(), imagePath);
      state = imagePath;
    } catch (e) {
      // 에러 처리
    }
  }

  Future<void> removeProfileImage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_getProfileImageKey());
      state = null;
    } catch (e) {
      // 에러 처리
    }
  }

  // 로그아웃 시 호출되는 메서드
  void clearProfileImage() {
    state = null;
  }
}

final profileImageControllerProvider = StateNotifierProvider<ProfileImageController, String?>(
  (ref) => ProfileImageController(ref),
);

// 사용자 서비스 프로바이더
final userServiceProvider = Provider<UserService>((ref) => UserService());

// 사용자 프로필 정보 프로바이더
final userProfileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final userService = ref.read(userServiceProvider);
  return await userService.getCurrentUserProfile();
});

// 프로필 완성 여부 확인 프로바이더 (AuthController 상태 사용)
// 더 이상 DB를 직접 조회하지 않고 AuthController의 상태를 사용

// 사용자 프로필 컨트롤러
class UserProfileController extends StateNotifier<AsyncValue<Map<String, dynamic>?>> with AuthStateMixin<AsyncValue<Map<String, dynamic>?>> {
  UserProfileController(this._userService, Ref ref) : super(const AsyncValue.loading()) {
    // 공통 인증 상태 리스너 초기화
    initAuthListener(
      ref,
      onLogout: () => state = const AsyncValue.data(null),
      onLogin: loadUserProfile,
    );
    
    loadUserProfile();
  }

  final UserService _userService;

  Future<void> loadUserProfile() async {
    try {
      state = const AsyncValue.loading();
      final profile = await _userService.getCurrentUserProfile();
      state = AsyncValue.data(profile);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<bool> updateNickname(String nickname) async {
    try {
      final success = await _userService.updateNickname(nickname);
      if (success) {
        await loadUserProfile(); // 프로필 새로고침
      }
      return success;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateUserProfile({String? nickname, String? email}) async {
    try {
      final success = await _userService.updateUserProfile(
        nickname: nickname,
        email: email,
      );
      if (success) {
        await loadUserProfile(); // 프로필 새로고침
      }
      return success;
    } catch (e) {
      return false;
    }
  }
}

final userProfileControllerProvider = StateNotifierProvider<UserProfileController, AsyncValue<Map<String, dynamic>?>>((ref) {
  final userService = ref.read(userServiceProvider);
  return UserProfileController(userService, ref);
});