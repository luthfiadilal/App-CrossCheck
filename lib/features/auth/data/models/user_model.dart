class UserModel {
  final String userId;
  final String name;
  final String email;
  final String role;
  final String? token;

  UserModel({
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
    this.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['user_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      token: json['token'],
    );
  }
}
