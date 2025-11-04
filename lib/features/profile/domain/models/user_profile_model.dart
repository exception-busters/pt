enum Gender { male, female }

class UserProfileModel {
  final String userId;
  final Gender? gender;
  final int? age;
  final double? height;
  final double? weight;

  const UserProfileModel({
    required this.userId,
    this.gender,
    this.age,
    this.height,
    this.weight,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      userId: json['user_id'] ?? '',
      gender: json['gender'] != null 
          ? Gender.values.firstWhere(
              (g) => g.name == json['gender'],
              orElse: () => Gender.male,
            )
          : null,
      age: json['age']?.toInt(),
      height: json['height']?.toDouble(),
      weight: json['weight']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'gender': gender?.name,
      'age': age,
      'height': height,
      'weight': weight,
    };
  }

  UserProfileModel copyWith({
    String? userId,
    Gender? gender,
    int? age,
    double? height,
    double? weight,
  }) {
    return UserProfileModel(
      userId: userId ?? this.userId,
      gender: gender ?? this.gender,
      age: age ?? this.age,
      height: height ?? this.height,
      weight: weight ?? this.weight,
    );
  }
}