import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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