class UserModel {
  final String userId;
  final String email;
  final String nickname;
  final String? profileImage;
  final bool profileCompleted;

  const UserModel({
    required this.userId,
    required this.email,
    required this.nickname,
    this.profileImage,
    required this.profileCompleted,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['user_id'] ?? '',
      email: json['email'] ?? '',
      nickname: json['nickname'] ?? '',
      profileImage: json['profile_image'],
      profileCompleted: json['profile_completed'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'email': email,
      'nickname': nickname,
      'profile_image': profileImage,
      'profile_completed': profileCompleted,
    };
  }

  UserModel copyWith({
    String? userId,
    String? email,
    String? nickname,
    String? profileImage,
    bool? profileCompleted,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      nickname: nickname ?? this.nickname,
      profileImage: profileImage ?? this.profileImage,
      profileCompleted: profileCompleted ?? this.profileCompleted,
    );
  }
}