class UserProfileModel {
  final String userId;
  final String email;
  final String role;
  final DateTime? createdAt;

  UserProfileModel({
    required this.userId,
    required this.email,
    required this.role,
    this.createdAt,
  });

  factory UserProfileModel.fromMap({
    required String userId,
    required Map<String, dynamic> map,
  }) {
    return UserProfileModel(
      userId: userId,
      email: (map["email"] ?? "").toString(),
      role: (map["role"] ?? "user").toString(),
      createdAt: map["createdAt"] is String
          ? DateTime.tryParse(map["createdAt"])
          : null,
    );
  }
}
