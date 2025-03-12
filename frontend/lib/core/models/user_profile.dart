class UserProfile {
  final String id;
  final String username;
  final String email;
  final String sessionId;
  final String? phoneNumber;
  final String? nickname;

  UserProfile({
    required this.id,
    required this.username,
    required this.email,
    required this.sessionId,
    this.phoneNumber,
    this.nickname,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json["id"],
      username: json["username"],
      email: json["email"],
      sessionId: json["session_id"],
      phoneNumber: json["phone_number"],
      nickname: json["nickname"],
    );
  }
}
