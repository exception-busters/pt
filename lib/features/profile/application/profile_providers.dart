import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/user_service.dart';
import '../../auth/application/auth_providers.dart';

class ProfileImageController extends StateNotifier<String?> {
  ProfileImageController(this._ref) : super(null) {
    _loadProfileImage();
    
    // 인증 상태 변화 감지
    _ref.listen(authControllerProvider, (previous, next) {
      if (!next) {
        // 로그아웃 시 상태 초기화
        state = null;
      } else if (previous == false && next == true) {
        // 로그인 시 프로필 이미지 다시 로드
        _loadProfileImage();
      }
    });
  }

  final Ref _ref;

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

// 프로필 완성 여부 확인 프로바이더 (서버 기반)
final profileCompletedProvider = FutureProvider<bool>((ref) async {
  final userService = ref.read(userServiceProvider);
  return await userService.isProfileCompleted();
});

// 사용자 프로필 컨트롤러
class UserProfileController extends StateNotifier<AsyncValue<Map<String, dynamic>?>> {
  UserProfileController(this._userService, this._ref) : super(const AsyncValue.loading()) {
    loadUserProfile();
    
    // 인증 상태 변화 감지
    _ref.listen(authControllerProvider, (previous, next) {
      if (!next) {
        // 로그아웃 시 상태 초기화
        state = const AsyncValue.data(null);
      } else if (previous == false && next == true) {
        // 로그인 시 프로필 다시 로드
        loadUserProfile();
      }
    });
  }

  final UserService _userService;
  final Ref _ref;

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