class UserModel {
  final int id;
  final String username;
  final String name;
  final int creditsRemaining;
  final int creditsUsed;

  UserModel({
    required this.id,
    required this.username,
    required this.name,
    required this.creditsRemaining,
    required this.creditsUsed,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      name: json['name'] ?? '',
      creditsRemaining: json['credits_remaining'] ?? 0,
      creditsUsed: json['credits_used'] ?? 0,
    );
  }
}
