import 'package:supabase_flutter/supabase_flutter.dart';

class UserService {
  final SupabaseClient _client = Supabase.instance.client;

  // 현재 사용자의 프로필 정보 가져오기
  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return null;

      final response = await _client
          .from('users')
          .select('user_id, email, nickname, join_date, profile_completed')
          .eq('user_id', user.id)
          .single();

      return response;
    } catch (e) {
      print('사용자 프로필 조회 오류: $e');
      return null;
    }
  }

  // 프로필 완성 여부 확인 (서버 기반)
  Future<bool> isProfileCompleted() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        print('🔍 UserService: 사용자가 로그인되지 않음');
        return false;
      }

      print('🔍 UserService: profile_completed 확인 시도 - user_id: ${user.id}');
      
      final response = await _client
          .from('users')
          .select('profile_completed')
          .eq('user_id', user.id)
          .single();

      final isCompleted = response['profile_completed'] ?? false;
      print('📊 UserService: profile_completed 결과 = $isCompleted');
      
      return isCompleted;
    } catch (e) {
      print('❌ UserService: 프로필 완성 여부 확인 오류: $e');
      // 오류 시 안전하게 false 반환 (온보딩 화면으로 이동)
      return false;
    }
  }

  // 프로필 완성 상태 업데이트
  Future<bool> markProfileAsCompleted() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return false;

      await _client
          .from('users')
          .update({'profile_completed': true})
          .eq('user_id', user.id);

      print('✅ 프로필 완성 상태 업데이트 완료');
      return true;
    } catch (e) {
      print('❌ 프로필 완성 상태 업데이트 오류: $e');
      return false;
    }
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