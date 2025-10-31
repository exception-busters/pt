import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/user_service.dart';

class ProfileImageController extends StateNotifier<String?> {
  ProfileImageController() : super(null) {
    _loadProfileImage();
  }

  static const String _profileImageKey = 'profile_image_path';

  Future<void> _loadProfileImage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final imagePath = prefs.getString(_profileImageKey);
      if (imagePath != null && File(imagePath).existsSync()) {
        state = imagePath;
      }
    } catch (e) {
      // 에러 발생 시 기본값 유지
    }
  }

  Future<void> updateProfileImage(String imagePath) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_profileImageKey, imagePath);
      state = imagePath;
    } catch (e) {
      // 에러 처리
    }
  }

  Future<void> removeProfileImage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_profileImageKey);
      state = null;
    } catch (e) {
      // 에러 처리
    }
  }
}

final profileImageControllerProvider = StateNotifierProvider<ProfileImageController, String?>(
  (ref) => ProfileImageController(),
);

// 사용자 서비스 프로바이더
final userServiceProvider = Provider<UserService>((ref) => UserService());

// 사용자 프로필 정보 프로바이더
final userProfileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final userService = ref.read(userServiceProvider);
  return await userService.getCurrentUserProfile();
});

// 사용자 프로필 컨트롤러
class UserProfileController extends StateNotifier<AsyncValue<Map<String, dynamic>?>> {
  UserProfileController(this._userService) : super(const AsyncValue.loading()) {
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
  return UserProfileController(userService);
});