import 'package:supabase_flutter/supabase_flutter.dart';
import '../../common/data/supabase_service.dart';

class UserService {
  final SupabaseClient _client = Supabase.instance.client;

  // 현재 사용자의 프로필 정보 가져오기
  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    final user = SupabaseService.currentUser;
    if (user == null) return null;

    return await SupabaseService.getUserInfo(user.id);
  }

  // 프로필 완성 여부 확인 (서버 기반)
  Future<bool> isProfileCompleted() async {
    final user = SupabaseService.currentUser;
    if (user == null) {
      print('🔍 UserService: 사용자가 로그인되지 않음');
      return false;
    }

    return await SupabaseService.isProfileCompleted(user.id);
  }

  // 프로필 완성 상태 업데이트
  Future<bool> markProfileAsCompleted() async {
    final user = SupabaseService.currentUser;
    if (user == null) return false;

    return await SupabaseService.updateProfileCompleted(user.id, true);
  }

  // 닉네임 업데이트
  Future<bool> updateNickname(String nickname) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return false;

      await _client
          .from('users')
          .update({'nickname': nickname})
          .eq('user_id', user.id);

      // auth.users의 display_name도 함께 업데이트
      await _client.auth.updateUser(
        UserAttributes(data: {'display_name': nickname}),
      );

      return true;
    } catch (e) {
      print('닉네임 업데이트 오류: $e');
      return false;
    }
  }

  // 사용자 정보 업데이트
  Future<bool> updateUserProfile({
    String? nickname,
    String? email,
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return false;

      final updateData = <String, dynamic>{};
      if (nickname != null) updateData['nickname'] = nickname;
      if (email != null) updateData['email'] = email;

      if (updateData.isNotEmpty) {
        await _client
            .from('users')
            .update(updateData)
            .eq('user_id', user.id);

        // auth.users의 메타데이터도 업데이트
        if (nickname != null) {
          await _client.auth.updateUser(
            UserAttributes(data: {'display_name': nickname}),
          );
        }
      }

      return true;
    } catch (e) {
      print('사용자 정보 업데이트 오류: $e');
      return false;
    }
  }
}